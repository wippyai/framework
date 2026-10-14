local test = require("test")
local fragment_bootstrap = require("fragment_bootstrap")

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

local function define_tests()
    test.describe("fragment gateway bootstrap", function()
        test.it("returns an uncached unavailable response for an empty host map", function()
            local response = make_response()
            local served = fragment_bootstrap.respond_iframe(response, "https://host.example/webcomponents-1.0.63", {})
            test.eq(served, false)
            test.eq(response.status, 503)
            test.eq(response.headers["Cache-Control"], "no-store")
            test.eq(response.content_type, "text/plain")
            test.eq(response.body, "Web Host import map is unavailable")
        end)

        test.it("keeps the 1.0.62 default fragment startup without requesting the new helper", function()
            local response = make_response()
            local served = fragment_bootstrap.respond_iframe(response, "https://host.example/webcomponents-1.0.62", {
                vue = "https://host.example/vendor/vue.js",
            })
            test.eq(served, true)
            test.eq(contains(response.body, '<script type="importmap">'), true)
            test.eq(contains(response.body, 'src="https://host.example/webcomponents-1.0.62/@wippy-fe/loading.js"'), true)
            test.eq(contains(response.body, 'src="https://host.example/webcomponents-1.0.62/@wippy-fe/import-map-bootstrap.js"'), false)
            test.eq(contains(response.body, "waitForConfig"), false)
            test.eq(contains(response.body, 'src="https://host.example/webcomponents-1.0.62/@wippy-fe/proxy-fragment.js"'), true)
        end)

        test.it("serves an escaped inert map and registers before proxy/API readiness", function()
            local response = make_response()
            local imports = {
                vue = "https://host.example/vendor/vue.js",
                dangerous = "https://host.example/</script>" .. "\226\128\168" .. "x" .. "\226\128\169",
            }
            local served = fragment_bootstrap.respond_iframe(response, "https://host.example/webcomponents-1.0.63", imports)
            test.eq(served, true)
            test.eq(response.status, 200)
            test.eq(response.headers["Cache-Control"], "public, max-age=300")
            test.eq(response.headers.Vary, "sec-fetch-dest")
            test.eq(response.content_type, "text/html")
            local html = response.body
            test.eq(contains(html, '<script type="importmap">'), false)
            test.eq(contains(html, '<script type="application/json" id="wippy-host-import-map">'), true)
            test.eq(contains(html, "\\u003c/script\\u003e"), true)
            test.eq(contains(html, "\\u2028"), true)
            test.eq(contains(html, "\\u2029"), true)
            test.eq(contains(html, 'src="https://host.example/webcomponents-1.0.63/@wippy-fe/loading.js"'), true)
            test.eq(contains(html, 'src="https://host.example/webcomponents-1.0.63/@wippy-fe/import-map-bootstrap.js"'), true)
            test.eq(contains(html, "physicalWindow.WippyImportMapBootstrap"), true)
            test.eq(contains(html, "waitForConfig({ waitForParent: true, waitForNestedInjection: true })"), true)
            test.eq(contains(html, "bootstrap.register(undefined, hostMap, config.importMap, physicalBase)"), true)
            test.eq(contains(html, "const physicalWindow = window; const physicalDocument = window.document"), true)
            test.eq(contains(html, "const physicalRoot = physicalDocument.documentElement; const physicalBody = physicalDocument.body"), true)
            test.eq(contains(html, "physicalCreateElement = physicalDocument.createElement.bind(physicalDocument)"), true)
            test.eq(contains(html, "physicalTarget.appendChild.bind(physicalTarget)"), true)
            test.eq(contains(html, "throw error;"), true)
            test.eq(contains(html, "await import(\"https://host.example/webcomponents-1.0.63/@wippy-fe/proxy-fragment.js\")"), true)
            test.eq(contains(html, "await physicalWindow.getWippyApi()"), true)
            test.eq(contains(html, "window.__WIPPY_IMPORT_MAP_READY__"), true)
            test.eq(contains(html, 'alert.setAttribute("role", "alert")'), true)
            local helper_at = html:find("src=\"https://host.example/webcomponents-1.0.63/@wippy-fe/import-map-bootstrap.js\"", 1, true)
            local wait_at = html:find("waitForConfig", 1, true)
            local register_at = html:find("bootstrap.register", 1, true)
            local proxy_at = html:find("await import", 1, true)
            local api_at = html:find("await physicalWindow.getWippyApi", 1, true)
            local append_at = html:find("physicalAppend =", 1, true)
            test.eq(helper_at < append_at and append_at < wait_at and wait_at < register_at and register_at < proxy_at and proxy_at < api_at, true)

            local valid_response = make_response()
            local valid_served = fragment_bootstrap.respond_iframe(valid_response, "https://host.example/webcomponents-1.0.63", {
                vue = "https://host.example/vendor/vue.js",
                app_entry = "https://host.example/apps/entry.js",
            })
            test.eq(valid_served, true)
        end)
    end)
end

local run_cases = test.run_cases(define_tests)

local function run(options: any): any
    return run_cases(options)
end

return { run = run }
