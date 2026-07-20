-- fragment_gateway.lua (EE2-2313, Phase 1)
--
-- Web-Fragments gateway. Serves the reframing contract for a Wippy view.page
-- rendered as a web-fragment, on the routes /@fragment/{id}/{path...}.
--
-- The `web-fragments` client (reframed) hits the SAME url three ways,
-- distinguished by the `Sec-Fetch-Dest` request header:
--   * "iframe"          -> the hidden realm iframe's `src` load. Return the tiny
--                          reframed stub document (scripts execute in this realm).
--   * "empty"/"document"-> reframed's `fetch()` of the fragment. Return the
--                          view.page's app HTML, transformed for the fragment realm.
--   * anything else      -> a relative asset request. Proxy it to the page's base_url.
--
-- HTML transform for the document (mirrors the host's client-side processWebPage):
--   * inject <base href={page base_url}> so the app's relative assets resolve;
--   * MERGE the Web Host import map ({fe_facade_url}/import-map.json) into the
--     app's import map (host wins) so bare specifiers like `@wippy-fe/proxy`,
--     `vue`, ... resolve, and move it FIRST in <head> (import maps must precede
--     module scripts);
--   * inject the fragment proxy bundle <script> (served from fe_facade_url, the
--     Web Host origin — NOT the app backend) right after the import map so `$W`/
--     `__WIPPY_APP_API__` exist before the app's module runs.
--
-- Auth is NOT injected here (client-held): the fragment proxy performs the
-- GetConfig/SetConfig handshake with the host to obtain config incl. auth.

local http = require("http")
local http_client = require("http_client")
local registry = require("registry")
local json = require("json")
local page_registry = require("page_registry")

local REFRAMED_STUB = "<!doctype html><title>Web Fragments: reframed</title>"

-- fe_facade_url (Web Host bundle origin: :5173 dev / CDN prod). Read the facade
-- requirement the same way the facade's own config handler does.
local function facade_base(): string
    local entry = registry.get("wippy.facade:fe_facade_url")
    local base = ""
    if entry and entry.data then
        base = entry.data.default or ""
    end
    return (base:gsub("/+$", ""))
end

-- Fetch the Web Host's canonical import map ({fe_facade_url}/import-map.json).
-- Memoized per fbase: the map is deploy-stable, so the original synchronous GET
-- on EVERY fragment mount (once per stub request) was pure overhead. Only
-- successful, non-empty results are cached — a failed fetch falls through and is
-- retried on the next mount rather than pinning the miss for the worker's life.
local _imports_cache: {[string]: {[string]: any}} = {}
local function fetch_host_imports(fbase: string): {[string]: any}
    if fbase == "" then
        return {}
    end
    local cached = _imports_cache[fbase]
    if cached ~= nil then
        return cached
    end
    local resp, err = http_client.get(fbase .. "/import-map.json", { timeout = 10 })
    if err or not resp or (resp.status_code or 0) ~= 200 or not resp.body then
        return {}
    end
    local decoded = json.decode(resp.body)
    if type(decoded) == "table" and type(decoded.imports) == "table" then
        local imports = decoded.imports :: {[string]: any}
        _imports_cache[fbase] = imports
        return imports
    end
    return {}
end

-- Extract the app's <script type="importmap">, merge the host imports over it
-- (host wins), and return (html_without_importmap, merged_importmap_json).
local function extract_and_merge_importmap(html: string, host_imports: {[string]: any}): (string, string)
    local app_imports: {[string]: any} = {}
    local s, e = html:find('<script%s+type="importmap"%s*>.-</script>')
    if s then
        local block = html:sub(s, e)
        local body = block:match('>%s*(.-)%s*</script>')
        if body then
            local decoded = json.decode(body)
            if type(decoded) == "table" and type(decoded.imports) == "table" then
                app_imports = decoded.imports :: {[string]: any}
            end
        end
        html = html:sub(1, s - 1) .. html:sub(e + 1)
    end
    for k, v in pairs(host_imports) do
        app_imports[k] = v
    end
    local merged = json.encode({ imports = app_imports }) or '{"imports":{}}'
    return html, merged
end

-- The reframed client streams the fragment body into the <web-fragment> shadow
-- root and re-executes scripts in the realm iframe via writable-dom. The only
-- server-side transform the realm needs is renaming <html>/<head>/<body> ->
-- <wf-html>/<wf-head>/<wf-body> (they are not the realm's real document
-- elements). We deliberately do NOT strip the doctype or neutralize
-- scripts/preload links: reframed's writable-dom handles script activation in
-- the realm, and both passes proved unnecessary in practice (the app boots and
-- re-executes correctly without them).
local function prefix_wf(html: string): string
    html = html:gsub("<(/?)[hH][tT][mM][lL]([%s>])", "<%1wf-html%2")
    html = html:gsub("<(/?)[hH][eE][aA][dD]([%s>])", "<%1wf-head%2")
    html = html:gsub("<(/?)[bB][oO][dD][yY]([%s>])", "<%1wf-body%2")
    return html
end

-- Realm stub (Sec-Fetch-Dest: iframe) — the reframed realm iframe's document.
-- The app's scripts are executed IN THIS REALM by reframed, so the import map
-- (bare-specifier resolution) and the fragment proxy bundle (sets up $W /
-- __WIPPY_APP_API__ before the app runs) live HERE, not in the streamed content.
-- The host import map ({fe_facade_url}/import-map.json) already carries the
-- shared vendors + @wippy-fe/* the apps externalize.
local function build_stub(fbase: string): string
    local imports = fetch_host_imports(fbase)
    local map = json.encode({ imports = imports }) or '{"imports":{}}'
    -- The canonical injector's `scripts` array is [loading.js, proxy.js, chat.js].
    -- For a fragment the applicable subset is loading.js + the reframed-realm proxy:
    --   * loading.js (classic) registers <wippy-loading>/<wippy-error> (used by the
    --     app's initial shell + error states);
    --   * proxy-fragment.js (module) is our realm adapter, replacing srcdoc proxy.js.
    -- chat.js (registers <wippy-chat>) is DELIBERATELY omitted: app-main uses the
    -- HOST's chat (right panel) via a host command, not an embedded <wippy-chat>, and
    -- eagerly loading the heavy chat bundle into every realm destabilises boot. A
    -- fragment that embeds chat directly would opt in per-page (future meta flag).
    return REFRAMED_STUB
        .. '<script type="importmap">' .. map .. '</script>'
        .. '<script src="' .. fbase .. '/@wippy-fe/loading.js"></script>'
        .. '<script type="module" src="' .. fbase .. '/@wippy-fe/proxy-fragment.js"></script>'
end

-- Fragment document (Sec-Fetch-Dest: empty) — streamed into the <web-fragment>
-- shadow by reframeWithFetch; scripts run via writable-dom in the realm. Apply
-- ONLY the reference's prefixHtmlHeadBody, PLUS: drop the app's own
-- <script type="importmap"> (a streamed import map errors — the map is in the
-- realm stub now), and inject <base> so the app's relative assets resolve.
-- Host CSS <link>s the child app INHERITS (theme-config tokens+fonts, iframe base,
-- tailwind utilities + PrimeVue, markdown). Injected SERVER-SIDE into the app
-- <head> so the streamed document already carries them — like the app's own
-- style-*.css. This is DETERMINISTIC: reframed streams these in, nothing wipes
-- them, so the client proxy needs no rAF re-injection loop. Asset names are the
-- Web Host build's stable, non-hashed outputs (vite assetFileNames [name].[ext]).
local function host_css_links(fbase: string): string
    local base = fbase .. "/@wippy-fe/assets/"
    return '<link rel="stylesheet" data-role="wippy-host-styles-theme-config" href="' .. base .. 'theme-config.css">'
        .. '<link rel="stylesheet" data-role="wippy-host-styles-iframe" href="' .. base .. 'iframe.css">'
        .. '<link rel="stylesheet" data-role="wippy-host-styles-primevue" href="' .. base .. 'tailwind.css">'
        .. '<link rel="stylesheet" data-role="wippy-host-styles-markdown" href="' .. base .. 'data-content.css">'
end

local function transform_document(html: string, base_url: string, fbase: string): string
    html = html:gsub('<script%s+type="importmap"%s*>.-</script>', '', 1)
    -- Remove the @wippy/scripts dev-proxy placeholder. It shows "Accept config to
    -- continue loading" and waits for the host to swap in the real proxy + config
    -- (what addAppConfigToDocument does for srcdoc). Our real proxy is in the realm
    -- stub, so drop the placeholder or it hijacks the render.
    html = html:gsub('<script[^>]-data%-role="@wippy/scripts"[^>]->%s*</script>', '', 1)
    -- Rewrite relative asset URLs (href/src="./x") to ABSOLUTE base_url. A <base>
    -- in the REFLECTED shadow is NOT honored, so relative <link rel=stylesheet> /
    -- <img> URLs would resolve against the host page origin (404 → unstyled app).
    -- Module scripts still work (reframed runs them in the realm at the gateway
    -- path), but static links/images need an absolute href here.
    html = html:gsub('href="%./', 'href="' .. base_url)
    html = html:gsub('src="%./', 'src="' .. base_url)
    -- Inject host CSS at the START of <head> (base first, app CSS layers on top).
    if fbase and fbase ~= "" then
        local links = host_css_links(fbase)
        html = html:gsub('(<[hH][eE][aA][dD][^>]*>)', function(h: string): string
            return h .. links
        end, 1)
    end
    return prefix_wf(html)
end

local function handler()
    local req = http.request()
    local res = http.response()
    if not req or not res then
        return nil, "Failed to get HTTP context"
    end

    local sfd = req:header("Sec-Fetch-Dest") or ""

    -- 1) Realm iframe src load -> reframed stub (carries import map + proxy).
    -- The stub has NO page and runs NO can_access check — it depends only on
    -- fbase + the deploy-stable host import map, so it is safe to cache in a
    -- SHARED cache. This is the per-mount hot path; caching it removes the
    -- import-map GET + response build from every fragment boot.
    if sfd == "iframe" then
        res:set_header("Vary", "sec-fetch-dest")
        res:set_header("Cache-Control", "public, max-age=300")
        res:set_content_type("text/html")
        res:set_status(http.STATUS.OK)
        res:write(build_stub(facade_base()))
        return
    end

    local page_id = req:param("id")
    if not page_id or page_id == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write("Missing fragment id")
        return
    end

    local page, page_err = page_registry.get(page_id)
    if page_err or not page then
        res:set_status(http.STATUS.NOT_FOUND)
        res:write("Fragment page not found")
        return
    end
    if not page_registry.can_access(page) then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:write("Access denied")
        return
    end

    local base_url = page_registry.resolve_base_url(page)
    if not base_url or base_url == "" then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write("Fragment base URL unresolved")
        return
    end

    -- Derive the subpath from the full request path — the router does not surface
    -- the {path...} wildcard via param(). Match on the "/@fragment/{id}/" prefix.
    -- Empty subpath = the document; a non-empty subpath = an asset request.
    local full_path = req:path() or ""
    local marker = "/@fragment/" .. page_id .. "/"
    local subpath = ""
    local mi = full_path:find(marker, 1, true)
    if mi then
        subpath = full_path:sub(mi + #marker)
    end

    -- 2) Bare fragment path -> the app HTML document, transformed for the realm.
    -- Discriminate on subpath, NOT Sec-Fetch-Dest: realm module fetches can arrive
    -- with an empty/absent Sec-Fetch-Dest, and must still be proxied as assets.
    if subpath == "" then
        local entry = page.entry_point or "index.html"
        local app_url = base_url .. entry
        local resp, err = http_client.get(app_url, { timeout = 20 })
        if err or not resp or (resp.status_code or 500) >= 400 then
            res:set_status(http.STATUS.BAD_GATEWAY)
            res:write("Fragment document fetch failed: " .. tostring(err or (resp and resp.status_code))
                .. " (url: " .. tostring(app_url) .. ")")
            return
        end
        local html = transform_document(resp.body or "", base_url, facade_base())
        res:set_header("Vary", "sec-fetch-dest")
        -- PRIVATE, not public: the document is access-gated per user via
        -- can_access above. Its CONTENT carries no per-user data (auth is
        -- client-held, never injected here), but a SHARED cache would serve the
        -- 200 to users who would have failed can_access. private = browser-only
        -- caching, which speeds repeat navigation without the cross-user leak.
        -- Public/immutable caching is a future win gated on a per-page `public`
        -- flag that authorizes shared caching.
        res:set_header("Cache-Control", "private, max-age=60")
        res:set_content_type("text/html")
        res:set_status(http.STATUS.OK)
        res:write(html)
        return
    end

    -- 3) Asset -> proxy to the page's real asset base_url + subpath.
    local asset_url = base_url .. subpath
    local resp, err = http_client.get(asset_url, { timeout = 20 })
    if err or not resp then
        res:set_status(http.STATUS.BAD_GATEWAY)
        res:write("Fragment asset fetch failed: " .. tostring(err))
        return
    end
    local headers = resp.headers or {}
    local ct = headers["Content-Type"] or headers["content-type"]
    if ct then
        res:set_content_type(ct)
    end
    -- Cache only successful asset responses, and PRIVATE for the same
    -- access-gating reason as the document (see above). Assets are the app's
    -- static build outputs, so a longer browser TTL is safe.
    if (resp.status_code or 200) < 400 then
        res:set_header("Cache-Control", "private, max-age=300")
    end
    res:set_status(resp.status_code or http.STATUS.OK)
    res:write(resp.body or "")
end

return { handler = handler }
