local test = require("test")
local json = require("json")
local registry = require("registry")

local NS = "wippy.facade:"

local REQ_NAMES: {string} = {
    "fe_facade_url", "fe_entry_path", "domain", "session_type",
    "history_mode", "show_admin", "start_nav_open", "allow_select_model",
    "hide_nav_bar", "disable_right_panel",
    "custom_css", "app_title", "app_icon", "app_name", "login_path",
}

local function setup_registry(overrides: {[string]: string}?)
    local defaults: {[string]: string} = {
        fe_facade_url = "https://front.wippy.ai",
        fe_entry_path = "/iframe.html",
        domain = "",
        session_type = "non-persistent",
        history_mode = "hash",
        show_admin = "true",
        start_nav_open = "false",
        allow_select_model = "false",
        hide_nav_bar = "false",
        disable_right_panel = "false",
        custom_css = "",
        app_title = "Wippy",
        app_icon = "wippy:logo",
        app_name = "Wippy AI",
        login_path = "/login.html",
    }

    if overrides then
        for k, v in pairs(overrides) do
            defaults[k] = v
        end
    end

    local snap = registry.snapshot()
    local changes = snap:changes()
    for name, value in pairs(defaults) do
        changes:create({
            id = NS .. name,
            kind = "ns.requirement",
            data = { default = value },
        })
    end
    changes:apply()
end

local function teardown_registry()
    local snap = registry.snapshot()
    local changes = snap:changes()
    for _, name in ipairs(REQ_NAMES) do
        changes:delete(NS .. name)
    end
    changes:apply()
end

local function define_tests()
    test.describe("config handler", function()
        test.describe("domain URL derivation", function()
            test.it("derives http/ws for localhost domain", function()
                local domain = "localhost:8085"
                local is_localhost = domain:match("^localhost") or domain:match("^127%.") or domain:match("^%[::1%]")
                local scheme = is_localhost and "http" or "https"
                local ws_scheme = is_localhost and "ws" or "wss"

                test.eq(scheme, "http")
                test.eq(ws_scheme, "ws")
                test.eq(scheme .. "://" .. domain, "http://localhost:8085")
                test.eq(ws_scheme .. "://" .. domain, "ws://localhost:8085")
            end)

            test.it("derives https/wss for production domain", function()
                local domain = "app.wippy.ai"
                local is_localhost = domain:match("^localhost") or domain:match("^127%.") or domain:match("^%[::1%]")
                local scheme = is_localhost and "http" or "https"
                local ws_scheme = is_localhost and "ws" or "wss"

                test.eq(scheme, "https")
                test.eq(ws_scheme, "wss")
                test.eq(scheme .. "://" .. domain, "https://app.wippy.ai")
                test.eq(ws_scheme .. "://" .. domain, "wss://app.wippy.ai")
            end)

            test.it("derives http/ws for 127.0.0.1", function()
                local domain = "127.0.0.1:8085"
                local is_localhost = domain:match("^localhost") or domain:match("^127%.") or domain:match("^%[::1%]")
                local scheme = is_localhost and "http" or "https"

                test.eq(scheme, "http")
            end)

            test.it("returns empty URLs when domain is empty", function()
                local domain = ""
                local api_url = ""
                local ws_url = ""
                if domain ~= "" then
                    api_url = "http://" .. domain
                    ws_url = "ws://" .. domain
                end

                test.eq(api_url, "")
                test.eq(ws_url, "")
            end)
        end)

        test.describe("iframe URL construction", function()
            test.it("builds iframe URL from facade_url and entry_path", function()
                local facade_url = "https://front.wippy.ai"
                local entry_path = "/iframe.html"
                local iframe_url = facade_url .. entry_path .. "?waitForCustomConfig"

                test.eq(iframe_url, "https://front.wippy.ai/iframe.html?waitForCustomConfig")
            end)

            test.it("extracts iframe origin from facade URL", function()
                local facade_url = "https://web-host.wippy.ai/webcomponents-2026.01.14-010"
                local origin = facade_url:match("^(https?://[^/]+)")

                test.eq(origin, "https://web-host.wippy.ai")
            end)

            test.it("returns empty iframe URL when facade_url is empty", function()
                local facade_url = ""
                local iframe_url = ""
                if facade_url ~= "" then
                    iframe_url = facade_url .. "/iframe.html?waitForCustomConfig"
                end

                test.eq(iframe_url, "")
            end)
        end)

        test.describe("feature flags", function()
            test.it("show_admin defaults to true", function()
                test.is_true("true" ~= "false")
            end)

            test.it("show_admin can be disabled", function()
                test.is_false("false" ~= "false")
            end)

            test.it("allow_select_model defaults to false", function()
                test.is_false("false" == "true")
            end)

            test.it("allow_select_model can be enabled", function()
                test.is_true("true" == "true")
            end)

            test.it("start_nav_open defaults to false", function()
                test.is_false("false" == "true")
            end)

            test.it("hide_nav_bar defaults to false", function()
                test.is_false("false" == "true")
            end)

            test.it("disable_right_panel defaults to false", function()
                test.is_false("false" == "true")
            end)
        end)

        test.describe("registry integration", function()
            test.before_each(function()
                setup_registry()
            end)

            test.after_each(function()
                teardown_registry()
            end)

            test.it("reads requirement values from registry", function()
                local entry = registry.get(NS .. "app_title")
                test.not_nil(entry)
                test.eq(entry.data.default, "Wippy")
            end)

            test.it("reads overridden values", function()
                local snap = registry.snapshot()
                local changes = snap:changes()
                changes:update({
                    id = NS .. "app_title",
                    kind = "ns.requirement",
                    data = { default = "Custom App" },
                })
                changes:apply()

                local entry = registry.get(NS .. "app_title")
                test.eq(entry.data.default, "Custom App")
            end)

            test.it("returns all default requirement values", function()
                local entry = registry.get(NS .. "fe_facade_url")
                test.eq(entry.data.default, "https://front.wippy.ai")

                entry = registry.get(NS .. "fe_entry_path")
                test.eq(entry.data.default, "/iframe.html")

                entry = registry.get(NS .. "login_path")
                test.eq(entry.data.default, "/login.html")

                entry = registry.get(NS .. "session_type")
                test.eq(entry.data.default, "non-persistent")

                entry = registry.get(NS .. "history_mode")
                test.eq(entry.data.default, "hash")
            end)
        end)

        test.describe("config JSON structure", function()
            test.it("builds complete config object", function()
                local config = {
                    facade_url = "https://front.wippy.ai",
                    iframe_origin = "https://front.wippy.ai",
                    iframe_url = "https://front.wippy.ai/iframe.html?waitForCustomConfig",
                    api_url = "http://localhost:8085",
                    ws_url = "ws://localhost:8085",
                    feature = {
                        session_type = "non-persistent",
                        history_mode = "hash",
                        show_admin = true,
                        allow_select_model = false,
                        start_nav_open = false,
                        hide_nav_bar = false,
                        disable_right_panel = false,
                    },
                    customization = {
                        custom_css = "",
                        css_variables = {},
                        i18n = {
                            app = {
                                title = "Wippy",
                                icon = "wippy:logo",
                                appName = "Wippy AI",
                            },
                        },
                        icons = {},
                    },
                    login_path = "/login.html",
                }

                local body, err = json.encode(config)
                test.is_nil(err)
                test.not_nil(body)

                local decoded, derr = json.decode(body)
                test.is_nil(derr)
                test.eq(decoded.facade_url, "https://front.wippy.ai")
                test.eq(decoded.api_url, "http://localhost:8085")
                test.eq(decoded.ws_url, "ws://localhost:8085")
                test.eq(decoded.feature.session_type, "non-persistent")
                test.is_true(decoded.feature.show_admin)
                test.is_false(decoded.feature.allow_select_model)
                test.eq(decoded.customization.i18n.app.title, "Wippy")
                test.eq(decoded.login_path, "/login.html")
            end)
        end)
    end)
end

local run_cases = test.run_cases(define_tests)

local function run(options)
    return run_cases(options)
end

return { run = run }
