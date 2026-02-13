local http = require("http")
local registry = require("registry")
local json = require("json")
local env = require("env")

type AppIdentity = {
    title: string,
    icon: string,
    appName: string,
}

type FeatureFlags = {
    session_type: string,
    history_mode: string,
    show_admin: boolean,
    allow_select_model: boolean,
    start_nav_open: boolean,
    hide_nav_bar: boolean,
    disable_right_panel: boolean,
}

type Customization = {
    custom_css: string,
    css_variables: {[string]: string},
    i18n: { app: AppIdentity },
    icons: {[string]: string},
}

type FacadeConfig = {
    facade_url: string,
    iframe_origin: string,
    iframe_url: string,
    api_url: string,
    ws_url: string,
    feature: FeatureFlags,
    customization: Customization,
    login_path: string,
}

local NS = "wippy.facade:"

local function get_req(name: string): string
    local entry, err = registry.get(NS .. name)
    if entry and entry.data then
        return entry.data.default or ""
    end
    return ""
end

local function derive_ws_url(api_url: string): string
    if api_url == "" then
        return ""
    end
    return api_url:gsub("^https://", "wss://"):gsub("^http://", "ws://")
end

local function handler()
    local res = http.response()
    if not res then
        return nil, "no HTTP context"
    end

    local facade_url = get_req("fe_facade_url")
    local entry_path = get_req("fe_entry_path")

    local iframe_origin = ""
    if facade_url ~= "" then
        iframe_origin = facade_url:match("^(https?://[^/]+)")
    end

    local iframe_url = ""
    if facade_url ~= "" then
        iframe_url = facade_url .. entry_path .. "?waitForCustomConfig"
    end

    local api_url_env = get_req("api_url_env")
    local api_url = ""
    local ws_url = ""
    if api_url_env ~= "" then
        api_url = env.get(api_url_env) or ""
        ws_url = derive_ws_url(api_url)
    end

    local config: FacadeConfig = {
        facade_url = facade_url,
        iframe_origin = iframe_origin,
        iframe_url = iframe_url,
        api_url = api_url,
        ws_url = ws_url,
        feature = {
            session_type = get_req("session_type"),
            history_mode = get_req("history_mode"),
            show_admin = get_req("show_admin") ~= "false",
            allow_select_model = get_req("allow_select_model") == "true",
            start_nav_open = get_req("start_nav_open") == "true",
            hide_nav_bar = get_req("hide_nav_bar") == "true",
            disable_right_panel = get_req("disable_right_panel") == "true",
        },
        customization = {
            custom_css = get_req("custom_css"),
            css_variables = {},
            i18n = {
                app = {
                    title = get_req("app_title"),
                    icon = get_req("app_icon"),
                    appName = get_req("app_name"),
                },
            },
            icons = {},
        },
        login_path = get_req("login_path"),
    }

    local body, err = json.encode(config)
    if err then
        res:set_status(http.STATUS.INTERNAL_SERVER_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write('{"error":"failed to encode config"}')
        return nil, err
    end

    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    res:write(body)
end

return { handler = handler }
