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

        test.it("serves the bootstrap stub privately with both maps in one inert JSON payload", function()
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

            local payload = json_island(html, "wippy-fragment-bootstrap")
            test.eq(contains(payload, "<"), false)
            test.eq(contains(payload, "\\u003c/script"), true)
            test.eq(contains(payload, "\\u2028"), true)
            test.eq(contains(payload, "\\u2029"), true)
            test.eq(contains(payload, '"hostMap":{"imports":{'), true)
            -- The page map stays raw text, so the browser reports a malformed map.
            test.eq(contains(payload, '"pageMapText":' .. fragment_bootstrap.inline_json('{"imports":{"page":"./p.js","x":"</script><!--"}}')), true)
            for _, island in ipairs({ "wippy-host-import-map", "wippy-page-import-map", "wippy-page-base" }) do
                test.eq(contains(html, island), false)
            end
            -- No static module script: the register script loads the proxy.
            test.eq(contains(html, '<script type="module"'), false)
            test.eq(contains(payload, '"proxyUrl":' .. fragment_bootstrap.inline_json(FBASE .. "/@wippy-fe/proxy-fragment.js")), true)
        end)

        test.it("leaves out the page map and base URL when the page has none", function()
            local payload = json_island(fragment_bootstrap.build_stub(FBASE, { vue = "v" }, { bootstrap = true }), "wippy-fragment-bootstrap")
            test.eq(contains(payload, '"hostMap":'), true)
            test.eq(contains(payload, "pageMapText"), false)
            test.eq(contains(payload, "pageBase"), false)
        end)

        test.it("registers at the page URL through a temporary base, with the maps as written", function()
            local base = "http://app.test/app/demo/</script>"
            local html = fragment_bootstrap.build_stub(FBASE, { vue = "v" }, { bootstrap = true, page_base = base })
            test.eq(contains(json_island(html, "wippy-fragment-bootstrap"), '"pageBase":' .. fragment_bootstrap.inline_json(base)), true)
            local script = register_script(html)
            test.eq(contains(script, "registerAtPageBase(bootstrap, pageMap, hostMap, configured.map, pageBase)"), true)
            test.eq(contains(script, 'base.setAttribute("href", pageBase)'), true)
            test.eq(contains(script, "} finally {"), true)
            test.eq(contains(script, "head.removeChild(base);"), true)
            -- No address is rewritten before the Host validates it.
            test.eq(contains(script, "new URL("), false)
        end)

        test.it("rejects the ready promise on failure and falls back without the helper", function()
            local script = register_script(fragment_bootstrap.build_stub(FBASE, { vue = "v" }, { bootstrap = true }))
            test.eq(contains(script, "var failed = Promise.reject(error);"), true)
            test.eq(contains(script, "physicalWindow.__WIPPY_IMPORT_MAP_READY__ = failed;"), true)
            test.eq(contains(script, 'fallback.setAttribute("type", "importmap");'), true)
        end)

        test.it("answers 500 without caching when the stub cannot be encoded", function()
            local response = make_response()
            local cyclic = {}
            cyclic.self = cyclic
            local served = fragment_bootstrap.respond_iframe(response, FBASE, { vue = cyclic }, { bootstrap = true })
            test.eq(served, false)
            test.eq(response.status, 500)
            test.eq(response.headers["Cache-Control"], "no-store")
        end)

        test.it("registers synchronously, then loads the proxy, reading the Host config from ancestors", function()
            local html = fragment_bootstrap.build_stub(FBASE, { vue = "v" }, { bootstrap = true })
            local loading_at = at(html, 'src="' .. FBASE .. '/@wippy-fe/loading.js"')
            -- A plain classic script: no async, defer or type, so it runs before the register script.
            local helper_at = at(html, '<script src="' .. FBASE .. '/@wippy-fe/import-map-bootstrap.js"></script>')
            local register_at = at(html, "registerAtPageBase(bootstrap, pageMap, hostMap, configured.map, pageBase);")
            test.eq(loading_at ~= nil and helper_at ~= nil and register_at ~= nil, true)
            test.eq(loading_at < helper_at and helper_at < register_at, true)

            local script = register_script(html)
            -- The proxy loads after a successful registration and after the Host-map
            -- fallback, and not in the failure branch.
            local proxy_after_register = at(script, "registerAtPageBase(bootstrap, pageMap, hostMap, configured.map, pageBase);")
            local proxy_load = script:find("loadProxy(payload.proxyUrl);", proxy_after_register, true)
            local failure_at = at(script, "} catch (error) {")
            test.eq(proxy_load ~= nil and failure_at ~= nil and proxy_load < failure_at, true)
            test.eq(script:find("loadProxy(", failure_at, true), nil)
            test.eq(contains(script, "fallback.textContent = JSON.stringify(hostMap);"), true)
            for _, async_marker in ipairs({ "await", "async", "waitForConfig", "postMessage", ".then(", "setTimeout" }) do
                test.eq(contains(script, async_marker), false)
            end
            test.eq(contains(script, "current.__WIPPY_APP_CONFIG__"), true)
            test.eq(contains(script, 'hasOwn.call(config, "importMap")'), true)
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
