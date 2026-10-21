-- fragment_gateway.lua (EE2-2313)
--
-- Web-Fragments gateway. Serves the reframing contract for a Wippy view.page
-- rendered as a web-fragment, on the routes /@fragment/{id}/{path...}.
--
-- The `web-fragments` client (reframed) hits the SAME url three ways,
-- distinguished by the `Sec-Fetch-Dest` request header:
--   * "iframe"          -> the hidden realm iframe's `src` load. Return the realm
--                          stub (fragment_bootstrap), which registers the import
--                          map before the realm's load event starts the stream.
--   * "empty"/"document"-> reframed's `fetch()` of the fragment. Return the
--                          view.page's app HTML, transformed for the fragment realm.
--   * anything else      -> a relative asset request. Proxy it to the page's base_url.
--
-- HTML is read with fragment_html's tokenizer and edited by byte range; nothing
-- here pattern-matches HTML. Auth is NOT injected here (client-held): the
-- fragment proxy performs the GetConfig/SetConfig handshake with the host.

local http = require("http")
local http_client = require("http_client")
local registry = require("registry")
local json = require("json")
local page_registry = require("page_registry")
local fragment_bootstrap = require("fragment_bootstrap")
local fragment_html = require("fragment_html")

-- fe_facade_url (Web Host bundle origin: :5173 dev / CDN prod). Read the facade
-- requirement the same way the facade's own config handler does.
local function facade_base(): string
    local entry = registry.get("wippy.facade:fe_facade_url")
    local base = ""
    if entry and entry.data then
        base = entry.data.default or ""
    end
    while base:sub(-1) == "/" do
        base = base:sub(1, -2)
    end
    return base
end

-- Fetch the Web Host's canonical import map ({fe_facade_url}/import-map.json).
-- Only successful, non-empty results are memoized, so a failed or empty fetch
-- is retried on the next mount.
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
    if type(decoded) == "table" and fragment_bootstrap.has_host_imports(decoded.imports) then
        local imports = decoded.imports :: {[string]: any}
        _imports_cache[fbase] = imports
        return imports
    end
    return {}
end

-- Whether the Web Host serves the import-map bootstrap helper (Host 1.0.63+).
-- Decided by asking the Host for the file, not by reading a version out of the
-- URL. Only a positive answer is memoized: each pool worker keeps its own cache,
-- and a remembered 4xx (a CDN path answers 403 until it is deployed) would keep
-- that worker on the static map after the Host appears. A miss falls back to
-- the static map and is asked again on the next mount.
local _bootstrap_cache: {[string]: boolean} = {}
local function host_has_bootstrap(fbase: string): boolean
    if fbase == "" then
        return false
    end
    if _bootstrap_cache[fbase] then
        return true
    end
    local resp, err = http_client.get(fbase .. "/@wippy-fe/import-map-bootstrap.js", { timeout = 10 })
    if err or not resp then
        return false
    end
    local present = (resp.status_code or 0) == 200 and resp.body ~= nil and resp.body ~= ""
    if present then
        _bootstrap_cache[fbase] = true
    end
    return present
end

-- Host CSS <link>s the child app INHERITS (theme-config tokens+fonts, iframe base,
-- tailwind utilities + PrimeVue, markdown). Injected SERVER-SIDE at the start of
-- the app <head> so the streamed document already carries them. Asset names are
-- the Web Host build's stable, non-hashed outputs (vite assetFileNames [name].[ext]).
local function host_css_links(fbase: string): string
    local base = fbase .. "/@wippy-fe/assets/"
    return '<link rel="stylesheet" data-role="wippy-host-styles-theme-config" href="' .. base .. 'theme-config.css">'
        .. '<link rel="stylesheet" data-role="wippy-host-styles-iframe" href="' .. base .. 'iframe.css">'
        .. '<link rel="stylesheet" data-role="wippy-host-styles-primevue" href="' .. base .. 'tailwind.css">'
        .. '<link rel="stylesheet" data-role="wippy-host-styles-markdown" href="' .. base .. 'data-content.css">'
end

-- The page's app HTML, or nil and a reason.
local function fetch_page_html(page, base_url: string)
    local entry = page.entry_point or "index.html"
    local app_url = base_url .. entry
    local resp, err = http_client.get(app_url, { timeout = 20 })
    if err or not resp or (resp.status_code or 500) >= 400 then
        return nil, "Fragment document fetch failed: " .. tostring(err or (resp and resp.status_code))
            .. " (url: " .. tostring(app_url) .. ")"
    end
    return resp.body or "", nil
end

local function fail(res, status, message)
    res:set_header("Cache-Control", "no-store")
    res:set_content_type("text/plain")
    res:set_status(status)
    res:write(message)
end

local function handler()
    local req = http.request()
    local res = http.response()
    if not req or not res then
        return nil, "Failed to get HTTP context"
    end

    local sfd = req:header("Sec-Fetch-Dest") or ""

    local page_id = req:param("id")
    if not page_id or page_id == "" then
        fail(res, http.STATUS.BAD_REQUEST, "Missing fragment id")
        return
    end

    local page, page_err = page_registry.get(page_id)
    if page_err or not page then
        fail(res, http.STATUS.NOT_FOUND, "Fragment page not found")
        return
    end
    if not page_registry.can_access(page) then
        fail(res, http.STATUS.UNAUTHORIZED, "Access denied")
        return
    end

    local base_url = page_registry.resolve_base_url(page)
    if not base_url or base_url == "" then
        fail(res, http.STATUS.INTERNAL_ERROR, "Fragment base URL unresolved")
        return
    end

    -- 1) Realm iframe src load -> the realm stub (import map + proxy).
    if sfd == "iframe" then
        local fbase = facade_base()
        local imports = fetch_host_imports(fbase)
        local bootstrap = fragment_bootstrap.has_host_imports(imports) and host_has_bootstrap(fbase)
        local page_map = nil
        if bootstrap then
            local html, fetch_err = fetch_page_html(page, base_url)
            if not html then
                fail(res, http.STATUS.BAD_GATEWAY, fetch_err or "Fragment document fetch failed")
                return
            end
            page_map = fragment_html.page_import_map(html)
        end
        fragment_bootstrap.respond_iframe(res, fbase, imports, {
            bootstrap = bootstrap,
            page_map = page_map,
            page_base = base_url,
        })
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
        local html, fetch_err = fetch_page_html(page, base_url)
        if not html then
            fail(res, http.STATUS.BAD_GATEWAY, fetch_err or "Fragment document fetch failed")
            return
        end
        local fbase = facade_base()
        local ok, transformed = pcall(fragment_html.transform_document, html, {
            base_url = base_url,
            head_prepend = fbase ~= "" and host_css_links(fbase) or nil,
        })
        if not ok then
            fail(res, http.STATUS.INTERNAL_ERROR, "Fragment document transform failed: " .. tostring(transformed))
            return
        end
        res:set_header("Vary", "sec-fetch-dest")
        -- PRIVATE, not public: the document is access-gated per user via
        -- can_access above. A SHARED cache would serve the 200 to users who
        -- would have failed can_access.
        res:set_header("Cache-Control", "private, max-age=60")
        res:set_content_type("text/html")
        res:set_status(http.STATUS.OK)
        res:write(transformed)
        return
    end

    -- 3) Asset -> proxy to the page's real asset base_url + subpath.
    local asset_url = base_url .. subpath
    local resp, err = http_client.get(asset_url, { timeout = 20 })
    if err or not resp then
        fail(res, http.STATUS.BAD_GATEWAY, "Fragment asset fetch failed: " .. tostring(err))
        return
    end
    local headers = resp.headers or {}
    local ct = headers["Content-Type"] or headers["content-type"]
    if ct then
        res:set_content_type(ct)
    end
    -- Cache only successful asset responses, and PRIVATE for the same
    -- access-gating reason as the document (see above).
    if (resp.status_code or 200) < 400 then
        res:set_header("Cache-Control", "private, max-age=300")
    end
    res:set_status(resp.status_code or http.STATUS.OK)
    res:write(resp.body or "")
end

return { handler = handler }
