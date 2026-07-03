local http = require("http")
local json = require("json")
local env = require("env")
local theming = require("theming_helpers")

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

local function non_empty_map_or_nil(m: any): {[string]: any}?
    if not m or type(m) ~= "table" or next(m) == nil then
        return nil
    end
    return m :: {[string]: any}
end

local function non_empty_array_or_nil(a: any): {any}?
    if not a or type(a) ~= "table" or #a == 0 then
        return nil
    end
    return a :: {any}
end

local function handler()
    local res = http.response()
    if not res then
        return nil, "no HTTP context"
    end

    -- Optional view-config resolver (wippy.facade:resolver): when an application
    -- binds one, its overrides replace matching requirement values below; with no
    -- binding this is {} and every read falls back to the static ns.requirement.
    local overrides = theming.resolve_overrides()

    local function get_req(name: string): string
        return theming.requirement(name, overrides)
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

    -- Build a theming scope from requirement name prefixes. file_sys is optional:
    -- when set, "fs://path" values are resolved to file content.
    local function build_theming_scope(css_req: string, vars_req: string, icon_sets_req: string?, file_sys: any): {[string]: any}?
        local custom_css = non_empty_or_nil(theming.resolve_css(get_req(css_req), file_sys))
        local css_vars = non_empty_map_or_nil(theming.resolve_json(get_req(vars_req), file_sys) :: {[string]: any})
        -- icon_sets are always inline JSON blobs; fs:// refs are not expected here
        local icon_sets = icon_sets_req and non_empty_map_or_nil(get_req_json_any(icon_sets_req)) or nil
        if not custom_css and not css_vars and not icon_sets then
            return nil
        end
        return {
            customCSS = custom_css,
            cssVariables = css_vars,
            iconSets = icon_sets,
        }
    end

    local facade_url = get_req("fe_facade_url")
    local entry_path = get_req("fe_entry_path")
    local fe_mode = get_req("fe_mode")

    -- Normalize mode: anything other than "managed" falls back to compat.
    if fe_mode ~= "managed" then
        fe_mode = "compat"
    end

    -- Module filename loaded by index.html. `compat` keeps the historical
    -- module.js (full Wippy host chrome); `managed` loads managed-layout.js
    -- (declarative multi-panel host via hostConfig.layout).
    local module_file = fe_mode == "managed" and "/managed-layout.js" or "/module.js"

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

    -- Optional filesystem for resolving file:// references in CSS/JSON requirements.
    local file_sys = theming.get_fs(get_req("content_fs"))

    -- Theming: three scopes (global, host, children)
    local global_scope = build_theming_scope("custom_css", "css_variables", "icon_sets", file_sys)
    local host_scope = build_theming_scope("host_custom_css", "host_css_variables", "host_icon_sets", file_sys)
    local children_scope: {[string]: any}? = nil

    -- Children scope has no icons — only CSS
    local children_css = non_empty_or_nil(theming.resolve_css(get_req("children_custom_css"), file_sys))
    local children_vars = non_empty_map_or_nil(theming.resolve_json(get_req("children_css_variables"), file_sys) :: {[string]: any})
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

    local host_config: {[string]: any} = {
        session = { type = non_empty_or_nil(get_req("session_type")) },
        history = non_empty_or_nil(get_req("history_mode")),
        showAdmin = get_req("show_admin") ~= "false",
        allowSelectModel = get_req("allow_select_model") == "true",
        startNavOpen = get_req("start_nav_open") == "true",
        hideNavBar = get_req("hide_nav_bar") == "true",
        disableRightPanel = get_req("disable_right_panel") == "true",
        hideSessionSelector = get_req("hide_session_selector") == "true",
    }

    local api_routes = non_empty_map_or_nil(get_req_json_any("api_routes"))

    local additional_nav = non_empty_map_or_nil(get_req_json_any("additional_nav_items"))
    if additional_nav then
        host_config.additionalNavItems = additional_nav
    end

    local state_cache = non_empty_map_or_nil(get_req_json_any("state_cache"))
    if state_cache then
        host_config.stateCache = state_cache
    end

    local additional_tags = non_empty_map_or_nil(get_req_json_any("allow_additional_tags"))
    if additional_tags then
        host_config.allowAdditionalTags = additional_tags
    end

    local chat_config = non_empty_map_or_nil(get_req_json_any("chat"))
    if chat_config then
        host_config.chat = chat_config
    end

    -- Managed-layout HostLayoutDeclaration. Only attached when fe_mode is
    -- "managed" — compat mode ignores it. Empty/missing decode skips
    -- the field so the host falls back to its other configuration paths
    -- (URL `?layout=` param, parent SetConfig postMessage handshake).
    if fe_mode == "managed" then
        local layout = non_empty_map_or_nil(get_req_json_any("host_config_layout"))
        if layout then
            host_config.layout = layout
        end
    end

    local axios_defaults = non_empty_map_or_nil(get_req_json_any("axios_defaults"))
    local extra_scripts = non_empty_array_or_nil(get_req_json_any("extra_scripts"))
    -- TanStack Query defaults: { default?, content?, lists? }. Passed through
    -- verbatim; the host validates/whitelists the option keys client-side.
    local tanstack = non_empty_map_or_nil(get_req_json_any("tanstack"))

    -- Clamp theme_mode to the valid enum; anything else (typo/misconfig) → auto,
    -- so a bad value can't ship a silently-ignored class to the client.
    local theme_mode = get_req("theme_mode")
    if theme_mode ~= "light" and theme_mode ~= "dark" and theme_mode ~= "auto" then
        theme_mode = "auto"
    end

    -- Persistence of the chosen theme mode. Clamp to the valid enum (bad value →
    -- "none" = no persistence). theme_storage_key falls back to the documented
    -- default so a blank requirement still produces a usable key.
    local theme_persist = get_req("theme_persist")
    if theme_persist ~= "cookie" and theme_persist ~= "localStorage" then
        theme_persist = "none"
    end
    local theme_storage_key = get_req("theme_storage_key")
    if theme_storage_key == "" then
        theme_storage_key = "@wippy-theme-mode"
    end

    local config = {
        facade_url = facade_url,
        iframe_origin = iframe_origin,
        iframe_url = iframe_url,
        login_path = get_req("login_path"),
        login_redirect_param = non_empty_or_nil(get_req("login_redirect_param")),
        mode = fe_mode,
        module_file = module_file,

        env = {
            APP_API_URL = api_url,
            APP_AUTH_API_URL = api_url,
            APP_WEBSOCKET_URL = ws_url,
        },
        routePrefix = non_empty_or_nil(api_url),
        themeMode = theme_mode,
        themePersist = theme_persist,
        themeStorageKey = theme_storage_key,
        apiRoutes = api_routes,
        axiosDefaults = axios_defaults,
        tanstack = tanstack,
        extraScripts = extra_scripts,
        theming = {
            global = global_scope,
            host = host_scope,
            children = children_scope,
        },
        hostConfig = host_config,
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
