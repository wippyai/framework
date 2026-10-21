local test = require("test")
local fragment_bootstrap = require("fragment_bootstrap")

local FBASE = "https://host.example/webcomponents-1.0.66"

local function make_response()
    local response = { headers = {}, status = nil, content_type = nil, body = "" }
    function response:set_header(name, value) self.headers[name] = value end
    function response:set_content_type(value) self.content_type = value end
    function response:set_status(value) self.status = value end
    function response:write(value) self.body = self.body .. value end
    return response
end

local function contains(text, part)
    return text:find(part, 1, true) ~= nil
end

local function at(text, part)
    return text:find(part, 1, true)
end

-- Text between `<script ... id="<id>">` and the next `</script>`.
local function json_island(html, id)
    local open = '<script type="application/json" id="' .. id .. '">'
    local s = at(html, open)
    if not s then
        return nil
    end
    local from = s + #open
    local close = html:find("</script>", from, true)
    if not close then
        return nil
    end
    return html:sub(from, close - 1)
end

-- The inline classic script that holds `readConfiguredImportMap`.
local function register_script(html)
    local marker = at(html, "readConfiguredImportMap")
    if not marker then
        return ""
    end
    local open = nil
    local pos = 1
    while true do
        local found = html:find("<script>", pos, true)
        if not found or found > marker then
            break
        end
        open = found
        pos = found + 1
    end
    local close = html:find("</script>", marker, true)
    if not open or not close then
        return ""
    end
    return html:sub(open, close)
end

local function define_tests()
    test.describe("fragment gateway bootstrap", function()
        test.it("returns an uncached unavailable response for an empty or missing host map", function()
            for _, imports in ipairs({ {}, false }) do
                local response = make_response()
                local served = fragment_bootstrap.respond_iframe(response, FBASE, imports or nil, { bootstrap = true })
                test.eq(served, false)
                test.eq(response.status, 503)
                test.eq(response.headers["Cache-Control"], "no-store")
                test.eq(response.content_type, "text/plain")
                test.eq(response.body, "Web Host import map is unavailable")
            end
        end)

        test.it("keeps the static Host map when the Host has no import-map bootstrap", function()
            local html = fragment_bootstrap.build_stub(FBASE, { vue = "https://host.example/vendor/vue.js" }, { bootstrap = false })
            test.eq(at(html, '<!doctype html><title>Web Fragments: reframed</title>'), 1)
            test.eq(contains(html, '<script type="importmap">{"imports":{"vue":"https://host.example/vendor/vue.js"}}</script>'), true)
            test.eq(contains(html, 'src="' .. FBASE .. '/@wippy-fe/loading.js"'), true)
            test.eq(contains(html, '<script type="module" src="' .. FBASE .. '/@wippy-fe/proxy-fragment.js"></script>'), true)
            test.eq(contains(html, "import-map-bootstrap.js"), false)
            test.eq(contains(html, "register("), false)
        end)

        test.it("serves the bootstrap stub privately with both maps as inert JSON", function()
            local response = make_response()
            local served = fragment_bootstrap.respond_iframe(response, FBASE, {
                vue = "https://host.example/vendor/vue.js",
                dangerous = "https://host.example/</script>" .. "\226\128\168" .. "x" .. "\226\128\169",
            }, { bootstrap = true, page_map = '{"imports":{"page":"./p.js","x":"</script><!--"}}' })
            test.eq(served, true)
            test.eq(response.status, 200)
            test.eq(response.headers["Cache-Control"], "private, max-age=60")
            test.eq(response.headers.Vary, "sec-fetch-dest")
            test.eq(response.content_type, "text/html")
            local html = response.body
            test.eq(at(html, '<!doctype html><title>Web Fragments: reframed</title>'), 1)
            test.eq(contains(html, '<script type="importmap">'), false)

            local host = json_island(html, "wippy-host-import-map")
            test.eq(contains(host, "<"), false)
            test.eq(contains(host, "\\u003c/script"), true)
            test.eq(contains(host, "\\u2028"), true)
            test.eq(contains(host, "\\u2029"), true)

            local page = json_island(html, "wippy-page-import-map")
            test.eq(page, fragment_bootstrap.inline_json('{"imports":{"page":"./p.js","x":"</script><!--"}}'))
            test.eq(contains(page, "<"), false)
            test.eq(page:sub(1, 1), '"')
        end)

        test.it("embeds null when the page has no import map or base URL", function()
            local html = fragment_bootstrap.build_stub(FBASE, { vue = "v" }, { bootstrap = true })
            test.eq(json_island(html, "wippy-page-import-map"), "null")
            test.eq(json_island(html, "wippy-page-base"), "null")
        end)

        test.it("resolves the page map against the page URL, not the realm URL", function()
            local base = "http://app.test/app/demo/</script>"
            local html = fragment_bootstrap.build_stub(FBASE, { vue = "v" }, { bootstrap = true, page_base = base })
            test.eq(json_island(html, "wippy-page-base"), fragment_bootstrap.inline_json(base))
            local script = register_script(html)
            test.eq(contains(script, "bootstrap.register(resolvePageMap(pageMap, pageBase), hostMap, configured.map, pageBase)"), true)
            test.eq(contains(script, 'physicalGetElementById("wippy-page-base")'), true)
            test.eq(contains(script, "new URL(value, base).href"), true)
            test.eq(contains(script, "Object.create(null)"), true)
        end)

        test.it("registers synchronously before the proxy, reading the Host config from ancestors", function()
            local html = fragment_bootstrap.build_stub(FBASE, { vue = "v" }, { bootstrap = true })
            local loading_at = at(html, 'src="' .. FBASE .. '/@wippy-fe/loading.js"')
            local helper_at = at(html, 'src="' .. FBASE .. '/@wippy-fe/import-map-bootstrap.js"')
            local register_at = at(html, "bootstrap.register(resolvePageMap(pageMap, pageBase), hostMap, configured.map, pageBase)")
            local proxy_at = at(html, '<script type="module" src="' .. FBASE .. '/@wippy-fe/proxy-fragment.js"></script>')
            test.eq(loading_at ~= nil and helper_at ~= nil and register_at ~= nil and proxy_at ~= nil, true)
            test.eq(loading_at < helper_at and helper_at < register_at and register_at < proxy_at, true)

            local script = register_script(html)
            for _, async_marker in ipairs({ "await", "async", "waitForConfig", "postMessage", ".then(", "setTimeout" }) do
                test.eq(contains(script, async_marker), false)
            end
            test.eq(contains(script, "current.__WIPPY_APP_CONFIG__"), true)
            test.eq(contains(script, 'Object.prototype.hasOwnProperty.call(config, "importMap")'), true)
            test.eq(contains(script, "next = current.parent"), true)
            test.eq(contains(script, "Failed to parse page import map: "), true)
            test.eq(contains(script, 'alert.setAttribute("role", "alert")'), true)
        end)

        test.it("escapes the Host URL inside attributes", function()
            local html = fragment_bootstrap.build_stub('https://host.example/a&b"c', { vue = "v" }, { bootstrap = true })
            test.eq(contains(html, 'src="https://host.example/a&amp;b&quot;c/@wippy-fe/import-map-bootstrap.js"'), true)
            test.eq(contains(html, 'a&b"c'), false)
        end)
    end)
end

local run_cases = test.run_cases(define_tests)

local function run(options: any): any
    return run_cases(options)
end

return { run = run }
