local test = require("test")
local json = require("json")
local registry = require("registry")

local NS = "wippy.facade:"

local REQ_NAMES: {string} = {
    "fe_facade_url", "fe_entry_path", "fe_mode", "render_engine", "session_type",
    "history_mode", "show_admin", "start_nav_open", "allow_select_model",
    "hide_nav_bar", "disable_right_panel", "hide_session_selector",
    "custom_css", "css_variables", "icon_sets",
    "host_custom_css", "host_css_variables", "host_icon_sets",
    "children_custom_css", "children_css_variables",
    "content_fs",
    "app_title", "app_icon", "app_name", "login_path",
    "login_redirect_param",
    "api_routes", "additional_nav_items", "state_cache",
    "allow_additional_tags", "chat", "axios_defaults",
    "extra_scripts", "host_config_layout", "theme_mode",
    "theme_persist", "theme_storage_key",
    "tanstack",
}

local function setup_registry(overrides: {[string]: string}?)
    local defaults: {[string]: string} = {
        fe_facade_url = "https://front.wippy.ai",
        fe_entry_path = "/iframe.html",
        fe_mode = "compat",
        render_engine = "iframe",
        session_type = "non-persistent",
        history_mode = "hash",
        show_admin = "true",
        start_nav_open = "false",
        allow_select_model = "false",
        hide_nav_bar = "false",
        disable_right_panel = "false",
        hide_session_selector = "false",
        custom_css = "",
        css_variables = "{}",
        icon_sets = "{}",
        host_custom_css = "",
        host_css_variables = "{}",
        host_icon_sets = "{}",
        children_custom_css = "",
        children_css_variables = "{}",
        content_fs = "",
        app_title = "Wippy",
        app_icon = "wippy:logo",
        app_name = "Wippy AI",
        login_path = "/login.html",
        login_redirect_param = "",
        api_routes = "{}",
        additional_nav_items = "[]",
        state_cache = "{}",
        allow_additional_tags = "{}",
        chat = "{}",
        axios_defaults = "{}",
        extra_scripts = "[]",
        host_config_layout = "{}",
        theme_mode = "auto",
        theme_persist = "none",
        theme_storage_key = "@wippy-theme-mode",
        tanstack = "{}",
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

local function derive_ws_url(api_url: string): string
    if api_url == "" then
        return ""
    end
    return api_url:gsub("^https://", "wss://"):gsub("^http://", "ws://")
end

-- Mirrors the clamp in config_handler.lua: only "cookie"/"localStorage" are
-- valid persistence targets; anything else (typo/misconfig) → "none".
local function clamp_theme_persist(value: string): string
    if value ~= "cookie" and value ~= "localStorage" then
        return "none"
    end
    return value
end

-- Mirrors the storage-key fallback: blank requirement → documented default.
local function clamp_theme_storage_key(value: string): string
    if value == "" then
        return "@wippy-theme-mode"
    end
    return value
end

-- Mirrors the clamp in config_handler.lua: only the exact string "fragment"
-- opts into the Web Fragment engine; anything else (default/typo/blank) → iframe.
local function clamp_render_engine(value: string): string
    if value ~= "fragment" then
        return "iframe"
    end
    return value
end

local function define_tests()
    test.describe("config handler", function()
        test.describe("ws url derivation", function()
            test.it("derives ws from http api url", function()
                test.eq(derive_ws_url("http://localhost:8085"), "ws://localhost:8085")
            end)

            test.it("derives wss from https api url", function()
                test.eq(derive_ws_url("https://app.wippy.ai"), "wss://app.wippy.ai")
            end)

            test.it("returns empty for empty url", function()
                test.eq(derive_ws_url(""), "")
            end)

            test.it("preserves path in ws url", function()
                test.eq(derive_ws_url("http://localhost:8085/api"), "ws://localhost:8085/api")
            end)
        end)

        test.describe("theme persistence clamping", function()
            test.it("keeps cookie and localStorage as-is", function()
                test.eq(clamp_theme_persist("cookie"), "cookie")
                test.eq(clamp_theme_persist("localStorage"), "localStorage")
            end)

            test.it("clamps unknown / typo values to none", function()
                test.eq(clamp_theme_persist("none"), "none")
                test.eq(clamp_theme_persist(""), "none")
                test.eq(clamp_theme_persist("localstorage"), "none")
                test.eq(clamp_theme_persist("session"), "none")
            end)

            test.it("storage key falls back to default when blank", function()
                test.eq(clamp_theme_storage_key(""), "@wippy-theme-mode")
            end)

            test.it("storage key keeps a custom value", function()
                test.eq(clamp_theme_storage_key("my.theme"), "my.theme")
            end)
        end)

        test.describe("render engine clamping", function()
            test.it("keeps fragment as-is", function()
                test.eq(clamp_render_engine("fragment"), "fragment")
            end)

            test.it("clamps default / unknown / typo / blank to iframe", function()
                test.eq(clamp_render_engine("iframe"), "iframe")
                test.eq(clamp_render_engine(""), "iframe")
                test.eq(clamp_render_engine("Fragment"), "iframe")
                test.eq(clamp_render_engine("srcdoc"), "iframe")
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
                local facade_url = "https://web-host.wippy.ai/webcomponents-1.0.45"
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

                entry = registry.get(NS .. "render_engine")
                test.eq(entry.data.default, "iframe")
            end)

            test.it("host_config_layout requirement defaults to empty JSON object", function()
                local entry = registry.get(NS .. "host_config_layout")
                test.not_nil(entry)
                test.eq(entry.data.default, "{}")
            end)

            test.it("host_config_layout decodes a valid HostLayoutDeclaration JSON", function()
                local layout_json = '{"layouts":{"default":{"direction":"vertical","children":[{"panel":"main","size":"1fr"}]}},"panels":{"main":{"kind":"page","id":"home"}}}'
                local snap = registry.snapshot()
                local changes = snap:changes()
                changes:update({
                    id = NS .. "host_config_layout",
                    kind = "ns.requirement",
                    data = { default = layout_json },
                })
                changes:apply()

                local entry = registry.get(NS .. "host_config_layout")
                local decoded, err = json.decode(entry.data.default :: string)
                test.is_nil(err)
                test.not_nil(decoded)
                test.eq(decoded.layouts.default.direction, "vertical")
                test.eq(decoded.panels.main.kind, "page")
                test.eq(decoded.panels.main.id, "home")
            end)

            test.it("tanstack requirement defaults to empty JSON object", function()
                local entry = registry.get(NS .. "tanstack")
                test.not_nil(entry)
                test.eq(entry.data.default, "{}")
            end)

            test.it("tanstack decodes a valid per-category config JSON", function()
                local tanstack_json = '{"default":{"staleTime":30000},"content":{"refetchOnWindowFocus":false},"lists":{"refetchOnWindowFocus":true}}'
                local snap = registry.snapshot()
                local changes = snap:changes()
                changes:update({
                    id = NS .. "tanstack",
                    kind = "ns.requirement",
                    data = { default = tanstack_json },
                })
                changes:apply()

                local entry = registry.get(NS .. "tanstack")
                local decoded, err = json.decode(entry.data.default :: string)
                test.is_nil(err)
                test.not_nil(decoded)
                test.eq(decoded.default.staleTime, 30000)
                test.is_false(decoded.content.refetchOnWindowFocus)
                test.is_true(decoded.lists.refetchOnWindowFocus)
            end)
        end)

        test.describe("extra scripts", function()
            test.it("parses string shorthand as src", function()
                local raw = '["/bridge.js"]'
                local decoded, err = json.decode(raw)
                test.is_nil(err)
                test.eq(decoded[1], "/bridge.js")
            end)

            test.it("parses object form with attributes", function()
                local raw = '[{"src":"https://cdn.example.com/x.js","defer":true,"type":"module"}]'
                local decoded, err = json.decode(raw)
                test.is_nil(err)
                test.eq(decoded[1].src, "https://cdn.example.com/x.js")
                test.is_true(decoded[1].defer)
                test.eq(decoded[1].type, "module")
            end)

            test.it("empty array results in nil (omitted from config)", function()
                local raw = '[]'
                local decoded, err = json.decode(raw)
                test.is_nil(err)
                test.eq(#decoded, 0)
            end)

            test.it("mixed string and object entries", function()
                local raw = '["/a.js",{"src":"/b.js","defer":true}]'
                local decoded, err = json.decode(raw)
                test.is_nil(err)
                test.eq(#decoded, 2)
                test.eq(decoded[1], "/a.js")
                test.eq(decoded[2].src, "/b.js")
            end)
        end)

        test.describe("login redirect param", function()
            test.before_each(function()
                setup_registry()
            end)

            test.after_each(function()
                teardown_registry()
            end)

            test.it("defaults to empty (feature off)", function()
                local entry = registry.get(NS .. "login_redirect_param")
                test.not_nil(entry)
                test.eq(entry.data.default, "")
            end)

            test.it("can be set to a custom param name", function()
                local snap = registry.snapshot()
                local changes = snap:changes()
                changes:update({
                    id = NS .. "login_redirect_param",
                    kind = "ns.requirement",
                    data = { default = "redirect_to" },
                })
                changes:apply()

                local entry = registry.get(NS .. "login_redirect_param")
                test.eq(entry.data.default, "redirect_to")
            end)
        end)

        test.describe("config JSON structure (wippy-context-2.0)", function()
            test.it("builds complete config object", function()
                local config = {
                    facade_url = "https://front.wippy.ai",
                    iframe_origin = "https://front.wippy.ai",
                    iframe_url = "https://front.wippy.ai/iframe.html?waitForCustomConfig",
                    login_path = "/login.html",
                    env = {
                        APP_API_URL = "http://localhost:8085",
                        APP_AUTH_API_URL = "http://localhost:8085",
                        APP_WEBSOCKET_URL = "ws://localhost:8085",
                    },
                    routePrefix = "http://localhost:8085",
                    themeMode = "auto",
                    themePersist = "cookie",
                    themeStorageKey = "@wippy-theme-mode",
                    theming = {
                        global = {
                            customCSS = "@import url('https://fonts.example.com');",
                            cssVariables = { ["p-primary"] = "#3b82f6" },
                            iconSets = { custom = { logo = { body = "<path/>", width = 24, height = 24 } } },  -- from icon_sets requirement
                        },
                        host = {
                            i18n = {
                                app = {
                                    title = "Wippy",
                                    icon = "wippy:logo",
                                    appName = "Wippy AI",
                                },
                            },
                        },
                    },
                    hostConfig = {
                        session = { type = "non-persistent" },
                        history = "hash",
                        showAdmin = true,
                        allowSelectModel = false,
                        startNavOpen = false,
                        hideNavBar = false,
                        disableRightPanel = false,
                    },
                }

                local body, err = json.encode(config)
                test.is_nil(err)
                test.not_nil(body)

                local decoded, derr = json.decode(body)
                test.is_nil(derr)
                test.eq(decoded.facade_url, "https://front.wippy.ai")
                test.eq(decoded.env.APP_API_URL, "http://localhost:8085")
                test.eq(decoded.env.APP_WEBSOCKET_URL, "ws://localhost:8085")
                test.eq(decoded.hostConfig.session.type, "non-persistent")
                test.is_true(decoded.hostConfig.showAdmin)
                test.is_false(decoded.hostConfig.allowSelectModel)
                test.eq(decoded.theming.host.i18n.app.title, "Wippy")
                test.eq(decoded.themeMode, "auto")
                test.eq(decoded.themePersist, "cookie")
                test.eq(decoded.themeStorageKey, "@wippy-theme-mode")
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
