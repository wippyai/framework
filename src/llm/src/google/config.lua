local base64 = require("base64")
local env = require("env")
local json = require("json")
local store = require("store")
local ctx = require("ctx")

local config = {
    _env = env,
    _ctx = ctx,
    _store = store,
}

config.OAUTH2_TOKEN_CACHE_KEY = "google_oauth2_token"
config.DEFAULT_CACHE_ID = "app:cache"
config.CLIENT_CONTRACT_ID = "wippy.llm.google:client_contract"

local function get_value(key, default_env_var)
    local safe_ctx_get = function (ctx_key)
        local success, v = pcall(function() return config._ctx.get(ctx_key) end)

        return success and v or nil
    end

    -- Check for direct value first
    local ctx_value = safe_ctx_get(key)
    if ctx_value and ctx_value ~= "" then
        return ctx_value
    end

    -- Check for env variable reference
    local env_key_value = safe_ctx_get(key .. "_env")
    if env_key_value and env_key_value ~= "" then
        local env_value = config._env.get(env_key_value)
        if env_value and env_value ~= "" then
            return env_value
        end
    end

    -- Use default env variable
    local env_value = config._env.get(default_env_var)
    if env_value and env_value ~= "" then
        return env_value
    end

    return nil
end

local function get_credentials()
    local credentials = get_value("google_credentials", "GOOGLE_CREDENTIALS")
    if not credentials then
        error("Google credentials are missing. Please set the `GOOGLE_CREDENTIALS` environment variable.")
    end
    local decoded = base64.decode(credentials)
    if not decoded or decoded == "" then
        error("Failed to decode Google credentials from base64.")
    end

    local parsed, err = json.decode(decoded)
    if err then
        error("Failed to parse Google credentials JSON: " .. tostring(err))
    end

    return parsed
end

function config.has_credentials()
    return pcall(get_credentials)
end

function config.get_token_uri()
    return get_credentials().token_uri
end

function config.get_client_email()
    return get_credentials().client_email
end

function config.get_private_key_id()
    return get_credentials().private_key_id
end

function config.get_private_key()
    return get_credentials().private_key
end

function config.get_oauth2_token()
    local store_instance, err = config._store.get(config._env.get("APP_CACHE") or config.DEFAULT_CACHE_ID)
    if err then
        return nil, "Failed to access cache store: " .. tostring(err)
    end

    return store_instance:get(config.OAUTH2_TOKEN_CACHE_KEY)
end

function config.get_gemini_api_key()
    return get_value("api_key", "GEMINI_API_KEY")
end

function config.get_project_id()
    return get_credentials().project_id
end

function config.get_vertex_base_url(location)
    location = location or config.get_vertex_location()

    local prefix_location = location == "global" and "" or location .. "-"

    return string.format(get_value("base_url", "VERTEX_AI_BASE_URL"), prefix_location)
end

function config.get_vertex_location()
    return get_value("location", "VERTEX_AI_LOCATION")
end

function config.get_vertex_timeout()
    local timeout = get_value("timeout", "VERTEX_AI_TIMEOUT")

    return (timeout and tonumber(timeout)) or 600
end

function config.get_generative_ai_base_url()
    return get_value("base_url", "GEN_AI_API_BASE_URL")
end

function config.get_generative_ai_timeout()
    return get_value("timeout", "GEN_AI_TIMEOUT")
end

return config
