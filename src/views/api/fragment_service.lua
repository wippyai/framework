-- fragment_service.lua (EE2-2313)
--
-- Request handling for the Web-Fragments gateway (fragment_gateway.lua) on
-- /@fragment/{id}/{path...}. It uses no runtime modules: the caller passes
-- them in `deps`, so tests can drive every branch with fakes.
--
--   deps.get_page(id)             -> page, err
--   deps.can_access(page)         -> boolean
--   deps.resolve_base_url(page)   -> absolute base URL ending in "/"
--   deps.page_meta(page)          -> bundled wippy-meta table or nil, err
--   deps.facade_url()             -> fe_facade_url value (Web Host bundle URL)
--   deps.http_get(url, options)   -> { status_code, body, headers }, err
--   deps.decode_json(text)        -> value, err
--   deps.now()                    -> seconds
--   deps.log(message, fields)
--
-- The `web-fragments` client (reframed) requests the bare fragment URL two
-- ways, told apart by `Sec-Fetch-Dest`:
--   * "iframe": the hidden realm iframe's `src`. Answer with the realm stub
--     (fragment_bootstrap), which registers the import map before the realm's
--     load event starts the stream.
--   * anything else: reframed's `fetch()` of the page. Answer with the page's
--     HTML, transformed for the realm (fragment_html).
-- Any other path below the fragment URL is an asset request, proxied from the
-- page's HTML directory.
local fragment_bootstrap = require("fragment_bootstrap")
local fragment_html = require("fragment_html")

local OK, BAD_REQUEST, UNAUTHORIZED, NOT_FOUND = 200, 400, 401, 404
local INTERNAL_ERROR, BAD_GATEWAY, UNAVAILABLE = 500, 502, 503

-- Each gateway pool worker has its own Lua state and therefore its own copy of
-- these caches. Entries expire so that every worker follows the Host and the
-- page within a minute. A "no helper" answer expires sooner, because a CDN path
-- answers 403 until the Host is deployed there.
local HOST_IMPORTS_TTL = 60
local BOOTSTRAP_PRESENT_TTL = 60
local BOOTSTRAP_ABSENT_TTL = 15
local ENTRY_TTL = 60

local caches = { imports = {}, bootstrap = {}, entry = {} }

local function cache_get(bucket, key, now)
    local item = caches[bucket][key]
    if item and item.expires > now then
        return item.value
    end
    caches[bucket][key] = nil
    return nil
end

local function cache_put(bucket, key, value, ttl, now)
    caches[bucket][key] = { value = value, expires = now + ttl }
end

local function reset_caches()
    caches = { imports = {}, bootstrap = {}, entry = {} }
end

local function fail(res, status, message)
    res:set_header("Cache-Control", "no-store")
    res:set_content_type("text/plain")
    res:set_status(status)
    res:write(message)
end

local function starts_with(text, prefix)
    return text:sub(1, #prefix) == prefix
end

-- The Web Host bundle URL without trailing slashes, or "".
local function facade_base(raw)
    local base = type(raw) == "string" and raw or ""
    while base:sub(-1) == "/" do
        base = base:sub(1, -2)
    end
    return base
end

-- The Web Host's import map ({fe_facade_url}/import-map.json). Only a
-- non-empty map is cached, so a failed or empty fetch is retried.
local function host_imports(fbase, deps, now)
    if fbase == "" then
        return {}
    end
    local cached = cache_get("imports", fbase, now)
    if cached then
        return cached
    end
    local resp, err = deps.http_get(fbase .. "/import-map.json", { timeout = 10 })
    if err or not resp or resp.status_code ~= 200 or not resp.body then
        deps.log("fragment gateway: Web Host import map fetch failed", {
            status = resp and resp.status_code, error = err and tostring(err),
        })
        return {}
    end
    local decoded = deps.decode_json(resp.body)
    if type(decoded) == "table" and fragment_bootstrap.has_host_imports(decoded.imports) then
        cache_put("imports", fbase, decoded.imports, HOST_IMPORTS_TTL, now)
        return decoded.imports
    end
    return {}
end

-- Whether the Web Host serves the import-map bootstrap helper (Host 1.0.63+):
-- "present", "absent" (a 4xx, or a 200 that is not the helper, such as an
-- HTML fallback page), or "unknown" (a transport error or a 5xx). Decided by
-- asking the Host for the file.
local function bootstrap_state(fbase, deps, now)
    if fbase == "" then
        return "absent"
    end
    local cached = cache_get("bootstrap", fbase, now)
    if cached then
        return cached
    end
    local resp, err = deps.http_get(fbase .. "/@wippy-fe/import-map-bootstrap.js", { timeout = 10 })
    if err or not resp then
        deps.log("fragment gateway: Web Host bootstrap check failed", { error = tostring(err) })
        return "unknown"
    end
    local status = resp.status_code or 0
    local state
    if status == 200 then
        local body = resp.body or ""
        state = body:find("WippyImportMapBootstrap", 1, true) and "present" or "absent"
    elseif status >= 400 and status < 500 then
        state = "absent"
    else
        deps.log("fragment gateway: Web Host bootstrap check failed", { status = status })
        return "unknown"
    end
    cache_put("bootstrap", fbase, state, state == "present" and BOOTSTRAP_PRESENT_TTL or BOOTSTRAP_ABSENT_TTL, now)
    return state
end

-- The page's HTML entry, chosen as the Host does: the YAML `entry_point`, else
-- the bundled `wippy.path`, else index.html.
local function page_entry(page, deps, now)
    if type(page.entry_point) == "string" and page.entry_point ~= "" then
        return page.entry_point
    end
    local key = tostring(page.id)
    local cached = cache_get("entry", key, now)
    if cached then
        return cached
    end
    local meta, err = deps.page_meta(page)
    local wippy = type(meta) == "table" and meta.wippy or nil
    local path = type(wippy) == "table" and wippy.path or nil
    local entry = (type(path) == "string" and path ~= "") and path or "index.html"
    if not err then
        cache_put("entry", key, entry, ENTRY_TTL, now)
    end
    return entry
end

-- The URL up to and including the last "/" of its path.
local function directory_of(url)
    local cut = #url + 1
    for k = 1, #url do
        local c = url:byte(k)
        if c == 63 or c == 35 then -- '?' '#'
            cut = k
            break
        end
    end
    for k = cut - 1, 1, -1 do
        if url:byte(k) == 47 then
            return url:sub(1, k)
        end
    end
    return url
end

-- The page's HTML URL and its directory. The directory is the base the Host's
-- iframe engine gives the page, so the document's URLs, its import maps and
-- relative asset requests resolve against it.
local function page_location(page, base_url, deps, now)
    local entry = page_entry(page, deps, now)
    local entry_url = fragment_html.resolve_url(base_url, entry) or entry
    return entry_url, directory_of(entry_url)
end

local function fetch_page_html(entry_url, deps)
    local resp, err = deps.http_get(entry_url, { timeout = 20 })
    if err or not resp or (resp.status_code or 500) >= 400 then
        deps.log("fragment gateway: page HTML fetch failed", {
            url = entry_url, status = resp and resp.status_code, error = err and tostring(err),
        })
        return nil
    end
    return resp.body or ""
end

local function hex_value(c)
    if c >= 48 and c <= 57 then
        return c - 48
    end
    if c >= 65 and c <= 70 then
        return c - 55
    end
    if c >= 97 and c <= 102 then
        return c - 87
    end
    return nil
end

-- An asset subpath that stays below the page directory: after decoding
-- percent-escapes it has no `.` or `..` segment, no `\`, no `?` or `#`, and no
-- control byte.
local function safe_subpath(subpath)
    local bytes = {}
    local k, n = 1, #subpath
    while k <= n do
        local c = subpath:byte(k)
        if c == 37 and k + 2 <= n then -- '%'
            local hi, lo = hex_value(subpath:byte(k + 1)), hex_value(subpath:byte(k + 2))
            if hi and lo then
                c = hi * 16 + lo
                k = k + 2
            end
        end
        if c < 32 or c == 127 or c == 92 or c == 63 or c == 35 then
            return false
        end
        bytes[#bytes + 1] = c
        k = k + 1
    end
    local length, dots_only = 0, true
    for i = 1, #bytes + 1 do
        local c = bytes[i]
        if c == nil or c == 47 then -- end or '/'
            if dots_only and (length == 1 or length == 2) then
                return false
            end
            length, dots_only = 0, true
        else
            length = length + 1
            if c ~= 46 then -- '.'
                dots_only = false
            end
        end
    end
    return true
end

-- Host CSS <link>s the child app inherits (theme-config tokens and fonts,
-- iframe base, Tailwind utilities with PrimeVue, markdown), inserted at the
-- start of the page <head> so the streamed document already carries them. The
-- asset names are the Web Host build's stable, unhashed outputs.
local function host_css_links(fbase)
    local base = fragment_bootstrap.attr_url(fbase .. "/@wippy-fe/assets/")
    return '<link rel="stylesheet" data-role="wippy-host-styles-theme-config" href="' .. base .. 'theme-config.css">'
        .. '<link rel="stylesheet" data-role="wippy-host-styles-iframe" href="' .. base .. 'iframe.css">'
        .. '<link rel="stylesheet" data-role="wippy-host-styles-primevue" href="' .. base .. 'tailwind.css">'
        .. '<link rel="stylesheet" data-role="wippy-host-styles-markdown" href="' .. base .. 'data-content.css">'
end

local function serve_stub(res, page, base_url, deps, now)
    local fbase = facade_base(deps.facade_url())
    local imports = host_imports(fbase, deps, now)
    if not fragment_bootstrap.has_host_imports(imports) then
        fragment_bootstrap.respond_iframe(res, fbase, imports, nil)
        return
    end
    local state = bootstrap_state(fbase, deps, now)
    if state == "unknown" then
        fail(res, UNAVAILABLE, "Web Host bootstrap check failed")
        return
    end
    local options = { bootstrap = state == "present" }
    if options.bootstrap then
        local entry_url, doc_base = page_location(page, base_url, deps, now)
        local html = fetch_page_html(entry_url, deps)
        if not html then
            fail(res, BAD_GATEWAY, "Fragment page fetch failed")
            return
        end
        local ok, page_map = pcall(fragment_html.page_import_map, html)
        if not ok then
            deps.log("fragment gateway: page import map read failed", { error = tostring(page_map) })
            fail(res, INTERNAL_ERROR, "Fragment page could not be read")
            return
        end
        options.page_map = page_map
        options.page_base = doc_base
    end
    fragment_bootstrap.respond_iframe(res, fbase, imports, options)
end

local function serve_document(res, page, base_url, deps, now)
    local entry_url, doc_base = page_location(page, base_url, deps, now)
    local html = fetch_page_html(entry_url, deps)
    if not html then
        fail(res, BAD_GATEWAY, "Fragment page fetch failed")
        return
    end
    local fbase = facade_base(deps.facade_url())
    local ok, transformed = pcall(fragment_html.transform_document, html, {
        base_url = doc_base,
        head_prepend = fbase ~= "" and host_css_links(fbase) or nil,
    })
    if not ok then
        deps.log("fragment gateway: document transform failed", { error = tostring(transformed) })
        fail(res, INTERNAL_ERROR, "Fragment page could not be transformed")
        return
    end
    res:set_header("Vary", "sec-fetch-dest")
    -- Private: the document is access-gated per user, so a shared cache must
    -- not serve it to users who would fail can_access.
    res:set_header("Cache-Control", "private, max-age=60")
    res:set_header("X-Content-Type-Options", "nosniff")
    res:set_content_type("text/html")
    res:set_status(OK)
    res:write(transformed)
end

local function serve_asset(res, page, base_url, subpath, deps, now)
    if not safe_subpath(subpath) then
        fail(res, BAD_REQUEST, "Invalid fragment asset path")
        return
    end
    local _, doc_base = page_location(page, base_url, deps, now)
    local resp, err = deps.http_get(doc_base .. subpath, { timeout = 20 })
    if err or not resp then
        deps.log("fragment gateway: asset fetch failed", { url = doc_base .. subpath, error = tostring(err) })
        fail(res, BAD_GATEWAY, "Fragment asset fetch failed")
        return
    end
    local headers = resp.headers or {}
    local content_type = headers["Content-Type"] or headers["content-type"]
    if content_type then
        res:set_content_type(content_type)
    end
    local status = resp.status_code or OK
    -- Private for the same access-gating reason as the document; failures are
    -- not cached.
    res:set_header("Cache-Control", status < 400 and "private, max-age=300" or "no-store")
    res:set_header("X-Content-Type-Options", "nosniff")
    res:set_status(status)
    res:write(resp.body or "")
end

--- Handle one gateway request. `req` provides header(name), param(name) and
--- path(); `res` provides set_header, set_content_type, set_status and write.
local function serve(req, res, deps)
    local now = deps.now()
    local page_id = req:param("id")
    if not page_id or page_id == "" then
        fail(res, BAD_REQUEST, "Missing fragment id")
        return
    end
    local page, page_err = deps.get_page(page_id)
    if page_err or not page then
        fail(res, NOT_FOUND, "Fragment page not found")
        return
    end
    if not deps.can_access(page) then
        fail(res, UNAUTHORIZED, "Access denied")
        return
    end
    local base_url = deps.resolve_base_url(page)
    if type(base_url) ~= "string" or not (starts_with(base_url, "http://") or starts_with(base_url, "https://")) then
        deps.log("fragment gateway: page base URL is not absolute", { page = page_id, base_url = tostring(base_url) })
        fail(res, INTERNAL_ERROR, "Fragment base URL unresolved")
        return
    end

    -- The subpath comes from the request path; the router does not expose the
    -- {path...} wildcard through param().
    local full_path = req:path() or ""
    local marker = "/@fragment/" .. page_id .. "/"
    local subpath = ""
    local at = full_path:find(marker, 1, true)
    if at then
        subpath = full_path:sub(at + #marker)
    end

    if subpath ~= "" then
        serve_asset(res, page, base_url, subpath, deps, now)
    elseif (req:header("Sec-Fetch-Dest") or "") == "iframe" then
        serve_stub(res, page, base_url, deps, now)
    else
        serve_document(res, page, base_url, deps, now)
    end
end

return {
    serve = serve,
    reset_caches = reset_caches,
    safe_subpath = safe_subpath,
    directory_of = directory_of,
}
