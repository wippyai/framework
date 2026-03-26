local http = require("http")
local registry = require("registry")
local json = require("json")
local env = require("env")

local NS = "wippy.facade:"

local function get_req(name: string): string
    local entry, err = registry.get(NS .. name)
    if entry and entry.data then
        return entry.data.default or ""
    end
    return ""
end

local function get_req_json(name: string): {[string]: string}
    local raw = get_req(name)
    if raw == "" then
        return {}
    end
    local val, err = json.decode(raw)
    if err then
        return {}
    end
    return (val :: {[string]: string}) or {}
end

local function get_req_json_any(name: string): {[string]: any}
    local raw = get_req(name)
    if raw == "" then
        return {}
    end
    local val, err = json.decode(raw)
    if err then
        return {}
    end
    return (val :: {[string]: any}) or {}
end

local function derive_ws_url(api_url: string): string
    if api_url == "" then
        return ""
    end
    return api_url:gsub("^https://", "wss://"):gsub("^http://", "ws://")
end

local function non_empty_or_nil(s: string): string?
    if s == "" then
        return nil
    end
    return s
end

local function non_empty_map_or_nil(m: {[string]: any}): {[string]: any}?
    if next(m) == nil then
        return nil
    end
    return m
end

-- Build a theming scope from requirement name prefixes.
-- Each scope can have: customCSS, cssVariables, iconSets.
local function build_theming_scope(css_req: string, vars_req: string, icon_sets_req: string?): {[string]: any}?
    local customCSS = non_empty_or_nil(get_req(css_req))
    local cssVariables = non_empty_map_or_nil(get_req_json(vars_req))
    local iconSets = icon_sets_req and non_empty_map_or_nil(get_req_json_any(icon_sets_req)) or nil

    if not customCSS and not cssVariables and not iconSets then
        return nil
    end
    return {
        customCSS = customCSS,
        cssVariables = cssVariables,
        iconSets = iconSets,
    }
end

local function handler()
    local res = http.response()
    if not res then
        return nil, "no HTTP context"
    end

    local facade_url = get_req("fe_facade_url")
    local entry_path = get_req("fe_entry_path")

    local iframe_origin: string? = ""
    if facade_url ~= "" then
        iframe_origin = facade_url:match("^(https?://[^/]+)")
    end

    local iframe_url = ""
    if facade_url ~= "" then
        iframe_url = facade_url .. entry_path .. "?waitForCustomConfig"
    end

    local api_url = env.get("PUBLIC_API_URL") or ""
    local ws_url = derive_ws_url(api_url)

    -- Theming: three scopes (global, host, children)
    local global_scope = build_theming_scope("custom_css", "css_variables", "icon_sets")
    local host_scope = build_theming_scope("host_custom_css", "host_css_variables", "host_icon_sets")
    local children_scope: {[string]: any}? = nil

    -- Children scope has no icons — only CSS
    local children_css = non_empty_or_nil(get_req("children_custom_css"))
    local children_vars = non_empty_map_or_nil(get_req_json("children_css_variables"))
    if children_css or children_vars then
        children_scope = {
            customCSS = children_css,
            cssVariables = children_vars,
        }
    end

    -- Host theming also carries i18n
    if not host_scope then
        host_scope = {}
    end
    host_scope.i18n = {
        app = {
            title = get_req("app_title"),
            icon = get_req("app_icon"),
            appName = get_req("app_name"),
        },
    }

    -- hostConfig
    local hostConfig: {[string]: any} = {
        session = { type = non_empty_or_nil(get_req("session_type")) },
        history = non_empty_or_nil(get_req("history_mode")),
        showAdmin = get_req("show_admin") ~= "false",
        allowSelectModel = get_req("allow_select_model") == "true",
        startNavOpen = get_req("start_nav_open") == "true",
        hideNavBar = get_req("hide_nav_bar") == "true",
        disableRightPanel = get_req("disable_right_panel") == "true",
        hideSessionSelector = get_req("hide_session_selector") == "true",
    }

    -- Optional JSON hostConfig fields
    local api_routes = non_empty_map_or_nil(get_req_json_any("api_routes"))
    if api_routes then
        hostConfig.apiRoutes = api_routes
    end

    local additional_nav = non_empty_map_or_nil(get_req_json_any("additional_nav_items"))
    if additional_nav then
        hostConfig.additionalNavItems = additional_nav
    end

    local state_cache = non_empty_map_or_nil(get_req_json_any("state_cache"))
    if state_cache then
        hostConfig.stateCache = state_cache
    end

    local additional_tags = non_empty_map_or_nil(get_req_json_any("allow_additional_tags"))
    if additional_tags then
        hostConfig.allowAdditionalTags = additional_tags
    end

    local chat_config = non_empty_map_or_nil(get_req_json_any("chat"))
    if chat_config then
        hostConfig.chat = chat_config
    end

    -- axiosDefaults (optional, top-level)
    local axios_defaults = non_empty_map_or_nil(get_req_json_any("axios_defaults"))

    local config = {
        facade_url = facade_url,
        iframe_origin = iframe_origin,
        iframe_url = iframe_url,
        login_path = get_req("login_path"),

        -- AppConfig fields (wippy-context-2.0)
        env = {
            APP_API_URL = api_url,
            APP_AUTH_API_URL = api_url,
            APP_WEBSOCKET_URL = ws_url,
        },
        routePrefix = non_empty_or_nil(api_url),
        axiosDefaults = axios_defaults,
        theming = {
            global = global_scope,
            host = host_scope,
            children = children_scope,
        },
        hostConfig = hostConfig,
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
