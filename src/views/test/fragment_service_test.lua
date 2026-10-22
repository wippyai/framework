local test = require("test")
local json = require("json")
local fragment_service = require("fragment_service")

local HOST = "https://host.test/webcomponents-1.0.66"
local IMPORT_MAP_URL = HOST .. "/import-map.json"
local HELPER_URL = HOST .. "/@wippy-fe/import-map-bootstrap.js"
local BASE = "http://app.test/app/demo/"
local PAGE_HTML = '<html><head><script type="importmap">{"imports":{"p":"./p.js"}}</script></head>'
    .. '<body><img src="i.png"></body></html>'

local function contains(text, part)
    return text:find(part, 1, true) ~= nil
end

local function make_response()
    local response = { headers = {}, status = nil, content_type = nil, body = "" }
    function response:set_header(name, value) self.headers[name] = value end
    function response:set_content_type(value) self.content_type = value end
    function response:set_status(value) self.status = value end
    function response:write(value) self.body = self.body .. value end
    return response
end

local function request(id, path, dest)
    return {
        param = function(_, name)
            if name == "id" then
                return id
            end
            return nil
        end,
        path = function()
            return path
        end,
        header = function(_, name)
            if name == "Sec-Fetch-Dest" then
                return dest
            end
            return nil
        end,
    }
end

-- A fake runtime: pages, a clock, and HTTP responses by URL (404 by default).
local function world()
    local w = {
        now = 1000,
        calls = {},
        meta_calls = 0,
        access = true,
        base_url = BASE,
        facade = HOST .. "//",
        pages = { demo = { id = "app:demo", entry_point = "app.html" } },
        responses = {
            [IMPORT_MAP_URL] = { status_code = 200, body = '{"imports":{"vue":"https://host.test/vue.js"}}' },
            [HELPER_URL] = { status_code = 200, body = "window.WippyImportMapBootstrap = {};" },
            [BASE .. "app.html"] = { status_code = 200, body = PAGE_HTML },
        },
    }
    w.deps = {
        get_page = function(id)
            local page = w.pages[id]
            if not page then
                return nil, "not found"
            end
            return page, nil
        end,
        can_access = function()
            return w.access
        end,
        resolve_base_url = function()
            return w.base_url
        end,
        page_meta = function()
            w.meta_calls = w.meta_calls + 1
            return w.meta, w.meta_err
        end,
        facade_url = function()
            return w.facade
        end,
        http_get = function(url)
            table.insert(w.calls, url)
            local r = w.responses[url]
            if not r then
                return { status_code = 404, body = "not found", headers = {} }, nil
            end
            if r.err then
                return nil, r.err
            end
            return r, nil
        end,
        decode_json = json.decode,
        now = function()
            return w.now
        end,
        log = function() end,
    }
    fragment_service.reset_caches()
    return w
end

local function serve(w, path, dest)
    local res = make_response()
    fragment_service.serve(request("demo", path or "/@fragment/demo/", dest), res, w.deps)
    return res
end

local function calls_to(w, url)
    local n = 0
    for _, u in ipairs(w.calls) do
        if u == url then
            n = n + 1
        end
    end
    return n
end

local function define_tests()
    test.describe("fragment service access", function()
        test.it("checks the id, the page and access before every branch", function()
            local w = world()
            local res = make_response()
            fragment_service.serve(request("", "/@fragment//", "iframe"), res, w.deps)
            test.eq(res.status, 400)
            test.eq(res.headers["Cache-Control"], "no-store")

            res = make_response()
            fragment_service.serve(request("nope", "/@fragment/nope/", "iframe"), res, w.deps)
            test.eq(res.status, 404)

            w.access = false
            test.eq(serve(w, nil, "iframe").status, 401)
            test.eq(serve(w, "/@fragment/demo/x.js").status, 401)
            test.eq(#w.calls, 0)
        end)

        test.it("refuses a page base URL that is not absolute http(s)", function()
            local w = world()
            w.base_url = "/app/demo/"
            local res = serve(w)
            test.eq(res.status, 500)
            test.eq(#w.calls, 0)
        end)
    end)

    test.describe("fragment service stub", function()
        test.it("serves the bootstrap stub with the page map and the HTML directory", function()
            local w = world()
            w.pages.demo.entry_point = "dist/app.html"
            w.responses[BASE .. "dist/app.html"] = { status_code = 200, body = PAGE_HTML }
            local res = serve(w, nil, "iframe")
            test.eq(res.status, 200)
            test.eq(res.headers["Cache-Control"], "private, max-age=60")
            test.eq(contains(res.body, '<script type="application/json" id="wippy-fragment-bootstrap">'), true)
            test.eq(contains(res.body, '"pageBase":"http://app.test/app/demo/dist/"'), true)
            test.eq(contains(res.body, '\\"p\\":\\"./p.js\\"'), true)
            test.eq(contains(res.body, HOST .. "/@wippy-fe/import-map-bootstrap.js"), true)
            test.eq(calls_to(w, BASE .. "dist/app.html"), 1)
        end)

        test.it("serves the static Host map when the Host has no helper", function()
            local w = world()
            w.responses[HELPER_URL] = nil
            local res = serve(w, nil, "iframe")
            test.eq(res.status, 200)
            test.eq(contains(res.body, '<script type="importmap">{"imports":{"vue":"https://host.test/vue.js"}}</script>'), true)
            test.eq(contains(res.body, "import-map-bootstrap.js"), false)
            test.eq(calls_to(w, BASE .. "app.html"), 0)
        end)

        test.it("treats an HTML fallback page as no helper", function()
            local w = world()
            w.responses[HELPER_URL] = { status_code = 200, body = "<!doctype html><title>App</title>" }
            local res = serve(w, nil, "iframe")
            test.eq(contains(res.body, '<script type="importmap">'), true)
        end)

        test.it("answers 503 without caching when the helper check fails, then recovers", function()
            local w = world()
            w.responses[HELPER_URL] = { err = "timeout" }
            local res = serve(w, nil, "iframe")
            test.eq(res.status, 503)
            test.eq(res.headers["Cache-Control"], "no-store")
            w.responses[HELPER_URL] = { status_code = 502, body = "bad gateway" }
            test.eq(serve(w, nil, "iframe").status, 503)
            w.responses[HELPER_URL] = { status_code = 200, body = "WippyImportMapBootstrap" }
            res = serve(w, nil, "iframe")
            test.eq(res.status, 200)
            test.eq(contains(res.body, "import-map-bootstrap.js"), true)
        end)

        test.it("answers 503 when the Host map is empty or missing", function()
            local w = world()
            w.responses[IMPORT_MAP_URL] = { status_code = 200, body = '{"imports":{}}' }
            local res = serve(w, nil, "iframe")
            test.eq(res.status, 503)
            test.eq(res.headers["Cache-Control"], "no-store")
            test.eq(calls_to(w, HELPER_URL), 0)
            w.facade = nil
            test.eq(serve(w, nil, "iframe").status, 503)
        end)

        test.it("answers 502 without internal URLs when the page fetch fails", function()
            local w = world()
            w.responses[BASE .. "app.html"] = { status_code = 500, body = "boom" }
            local res = serve(w, nil, "iframe")
            test.eq(res.status, 502)
            test.eq(res.headers["Cache-Control"], "no-store")
            test.eq(contains(res.body, "app.test"), false)
        end)

        test.it("expires cached Host answers", function()
            local w = world()
            serve(w, nil, "iframe")
            serve(w, nil, "iframe")
            test.eq(calls_to(w, IMPORT_MAP_URL), 1)
            test.eq(calls_to(w, HELPER_URL), 1)
            w.now = w.now + 61
            serve(w, nil, "iframe")
            test.eq(calls_to(w, IMPORT_MAP_URL), 2)
            test.eq(calls_to(w, HELPER_URL), 2)
        end)

        test.it("asks again soon after a Host had no helper", function()
            local w = world()
            w.responses[HELPER_URL] = { status_code = 403, body = "denied" }
            serve(w, nil, "iframe")
            w.now = w.now + 10
            serve(w, nil, "iframe")
            test.eq(calls_to(w, HELPER_URL), 1)
            w.responses[HELPER_URL] = { status_code = 200, body = "WippyImportMapBootstrap" }
            w.now = w.now + 6
            local res = serve(w, nil, "iframe")
            test.eq(calls_to(w, HELPER_URL), 2)
            test.eq(contains(res.body, "import-map-bootstrap.js"), true)
        end)

        test.it("uses the bundled wippy.path when the page has no entry_point", function()
            local w = world()
            w.pages.demo.entry_point = nil
            w.meta = { wippy = { path = "dist/index.html" } }
            w.responses[BASE .. "dist/index.html"] = { status_code = 200, body = PAGE_HTML }
            test.eq(serve(w).status, 200)
            serve(w)
            test.eq(w.meta_calls, 1)
            test.eq(calls_to(w, BASE .. "dist/index.html"), 2)

            w = world()
            w.pages.demo.entry_point = nil
            w.meta_err = "wippy-meta fetch failed"
            w.responses[BASE .. "index.html"] = { status_code = 200, body = PAGE_HTML }
            test.eq(serve(w).status, 200)
            serve(w)
            test.eq(w.meta_calls, 2)
        end)
    end)

    test.describe("fragment service document and assets", function()
        test.it("serves the transformed document privately", function()
            local w = world()
            local res = serve(w, nil, "empty")
            test.eq(res.status, 200)
            test.eq(res.content_type, "text/html")
            test.eq(res.headers["Cache-Control"], "private, max-age=60")
            test.eq(res.headers.Vary, "sec-fetch-dest")
            test.eq(res.headers["X-Content-Type-Options"], "nosniff")
            test.eq(contains(res.body, 'src="http://app.test/app/demo/i.png"'), true)
            test.eq(contains(res.body, HOST .. "/@wippy-fe/assets/theme-config.css"), true)
            test.eq(contains(res.body, "importmap"), false)
            test.eq(calls_to(w, HELPER_URL), 0)
        end)

        test.it("escapes the Host URL in the style links", function()
            local w = world()
            w.facade = 'https://host.test/a&b"c'
            local res = serve(w, nil, "empty")
            test.eq(res.status, 200)
            test.eq(contains(res.body, 'href="https://host.test/a&amp;b&quot;c/@wippy-fe/assets/theme-config.css"'), true)
            test.eq(contains(res.body, 'a&b"c'), false)
        end)

        test.it("proxies assets from the HTML directory", function()
            local w = world()
            w.pages.demo.entry_point = "dist/app.html"
            w.responses[BASE .. "dist/assets/x.js"] = {
                status_code = 200, body = "export {}", headers = { ["Content-Type"] = "text/javascript" },
            }
            local res = serve(w, "/@fragment/demo/assets/x.js")
            test.eq(res.status, 200)
            test.eq(res.body, "export {}")
            test.eq(res.content_type, "text/javascript")
            test.eq(res.headers["Cache-Control"], "private, max-age=300")
            res = serve(w, "/@fragment/demo/assets/missing.js")
            test.eq(res.status, 404)
            test.eq(res.headers["Cache-Control"], "no-store")
        end)

        test.it("serves an asset, not the stub, for an iframe request below the fragment URL", function()
            local w = world()
            w.responses[BASE .. "frame.html"] = { status_code = 200, body = "<p>frame</p>", headers = {} }
            local res = serve(w, "/@fragment/demo/frame.html", "iframe")
            test.eq(res.body, "<p>frame</p>")
            test.eq(calls_to(w, IMPORT_MAP_URL), 0)
        end)

        test.it("rejects asset paths that leave the page directory", function()
            local w = world()
            local bad = {
                "../x", "a/../../x", "%2e%2e/x", "a/%2E%2E/x", ".%2e/x", "a%5c..%5cx", "a\\x",
                "x%00", "%2e/x", "a/./b", "a/%3f.js", "a/%23.js", "a/..",
            }
            for _, subpath in ipairs(bad) do
                local res = serve(w, "/@fragment/demo/" .. subpath)
                test.eq(res.status, 400)
            end
            test.eq(#w.calls, 0)
            for _, subpath in ipairs({ "a..b/c.js", ".../x", ".well-known/x", "a%20b.js" }) do
                test.eq(fragment_service.safe_subpath(subpath), true)
            end
        end)
    end)
end

local run_cases = test.run_cases(define_tests)

local function run(options: any): any
    return run_cases(options)
end

return { run = run }
