-- fragment_gateway.lua (EE2-2313, Phase 1)
--
-- Minimal Web-Fragments gateway. Serves the reframing contract for a Wippy
-- view.page rendered as a web-fragment, on the routes /frag/{id}/{path...}.
--
-- The `web-fragments` client (reframed) hits the SAME url three ways,
-- distinguished by the `Sec-Fetch-Dest` request header:
--   * "iframe"          -> the hidden realm iframe's `src` load. Return the tiny
--                          reframed stub document (scripts execute in this realm).
--   * "empty"/"document"-> reframed's `fetch()` of the fragment. Return the
--                          view.page's app HTML with the fragment proxy + <base>
--                          injected, so its scripts (moved into the realm) boot
--                          the Wippy API.
--   * anything else      -> a relative asset request (script/style/img). Proxy it
--                          through to the page's real asset base_url.
--
-- Auth is deliberately NOT injected here (the token is client-held): the injected
-- fragment proxy performs the GetConfig/SetConfig handshake with the host over
-- its same-origin channel to obtain the full config (incl. auth). This handler is
-- auth-agnostic and only needs public registry access.
--
-- render.lua is untouched; this is a delivery-mode wrapper over the same page.

local http = require("http")
local http_client = require("http_client")
local page_registry = require("page_registry")

-- The exact stub the reference gateway returns for the reframed realm iframe.
local REFRAMED_STUB = "<!doctype html><title>Web Fragments: reframed</title>"

-- Resolve the absolute URL of the fragment proxy bundle (served by the Web Host,
-- same origin as the reframed realm). Derived from the request Origin/Referer so
-- it works in both the dev split (host :5173 via proxy) and same-origin prod.
local function resolve_proxy_url(req)
    local origin = req:header("Origin")
    if not origin or origin == "" then
        local referer = req:header("Referer") or ""
        origin = referer:match("^(https?://[^/]+)") or ""
    end
    return (origin or "") .. "/@wippy-fe/proxy-fragment.js"
end

-- Inject <base href> (so the app's relative assets resolve to the real page
-- base, proxied back through /frag/{id}/...) and the fragment proxy <script>
-- (absolute URL, unaffected by <base>) as the FIRST scripts in <head>.
local function inject(html, base_url, proxy_url)
    local base_tag = string.format('<base href="%s">', base_url)
    local proxy_tag = string.format('<script type="module" src="%s"></script>', proxy_url)
    local head_inject = base_tag .. proxy_tag

    -- Insert right after the opening <head ...> tag (case-insensitive). Fall back
    -- to prepending if the document has no <head>.
    local s, e = html:find("<head[^>]*>")
    if s then
        return html:sub(1, e) .. head_inject .. html:sub(e + 1)
    end
    return head_inject .. html
end

local function handler()
    local req = http.request()
    local res = http.response()
    if not req or not res then
        return nil, "Failed to get HTTP context"
    end

    local sfd = req:header("Sec-Fetch-Dest") or ""

    -- 1) Realm iframe src load -> reframed stub.
    if sfd == "iframe" then
        res:set_header("Vary", "sec-fetch-dest")
        res:set_content_type("text/html")
        res:set_status(http.STATUS.OK)
        res:write(REFRAMED_STUB)
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

    -- 2) Document/soft-nav fetch -> the app HTML with proxy + <base> injected.
    if sfd == "empty" or sfd == "document" or sfd == "" then
        local entry = page.entry_point or "index.html"
        local app_url = base_url .. entry
        local resp, err = http_client.get(app_url, { timeout = 20 })
        if err or not resp or (resp.status_code or 500) >= 400 then
            res:set_status(http.STATUS.BAD_GATEWAY)
            res:write("Fragment document fetch failed: " .. tostring(err or (resp and resp.status_code)))
            return
        end
        local proxy_url = resolve_proxy_url(req)
        local html = inject(resp.body or "", base_url, proxy_url)
        res:set_header("Vary", "sec-fetch-dest")
        res:set_content_type("text/html")
        res:set_status(http.STATUS.OK)
        res:write(html)
        return
    end

    -- 3) Asset -> proxy to the page's real asset base_url + subpath.
    local subpath = req:param("path") or ""
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
    res:set_status(resp.status_code or http.STATUS.OK)
    res:write(resp.body or "")
end

return { handler = handler }
