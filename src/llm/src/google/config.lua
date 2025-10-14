local base64 = require("base64")
local env = require("env")
local json = require("json")
local store = require("store")

local config = {}

config.OAUTH2_TOKEN_CACHE_KEY = "google_oauth2_token"
config.DEFAULT_CACHE_ID = "app:cache"
config.CLIENT_CONTRACT_ID = "wippy.llm.google:client_contract"

local function get_credentials()
    local credentials = env.get("GOOGLE_CREDENTIALS")
    if not credentials or credentials == "" then
        error("Google credentials are missing. Please set the `GOOGLE_CREDENTIALS` environment variable.")
    end
    local decoded = base64.decode(credentials)
    if not decoded or decoded == "" then
        error("Failed to decode Google credentials from base64.")
    end

    local parsed, err = json.decode(decoded)
    if err then
        error("Failed to parse Google credentials JSON: " .. err)
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
    local store_instance, err = store.get(env.get("APP_CACHE") or config.DEFAULT_CACHE_ID)
    if err then
        return nil, "Failed to access cache store: " .. err
    end

    return store_instance:get(config.OAUTH2_TOKEN_CACHE_KEY)
end

function config.get_project_id()
    return get_credentials().project_id
end

function config.get_vertex_base_url(project_id, location)
    location = location or config.get_vertex_location()
    project_id = project_id or config.get_project_id()

    local prefix_location = location == "global" and "" or location .. "-"
    if not project_id or project_id == "" then
        return nil, "Google `project_id` is missing"
    end
    if not location or location == "" then
        return nil, "Vertex AI `location` is missing"
    end

    return string.format(env.get("VERTEX_AI_BASE_URL"), prefix_location, project_id, location)
end

function config.get_vertex_location()
    return env.get("VERTEX_AI_LOCATION")
end

function config.get_vertex_timeout()
    local timeout = env.get("VERTEX_AI_TIMEOUT")

    return (timeout and tonumber(timeout)) or 600
end

function config.get_generative_ai_base_url()
    return env.get("GEN_AI_API_BASE_URL")
end

function config.get_generative_ai_timeout()
    return env.get("GEN_AI_TIMEOUT")
end

return config
