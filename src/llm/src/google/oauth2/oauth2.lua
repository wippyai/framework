local http = require("http_client")
local time = require("time")
local crypto = require("crypto")
local config = require("google_config")
local json = require("json")
local store = require("store")
local env = require("env")
local transport = require("transport")

local oauth2 = {}

local GRANT_TYPE = "urn:ietf:params:oauth:grant-type:jwt-bearer"
local SCOPE = "https://www.googleapis.com/auth/cloud-platform"
local TIMEOUT = 300

function oauth2.get_token()
    local time_now = time.now()

    local signature, err = crypto.jwt.encode({
        iss = config.get_client_email(),
        scope = SCOPE,
        aud = config.get_token_uri(),
        exp = time_now:unix() + 3600,
        iat = time_now:unix(),
        _header = {
            alg = "RS256",
            typ = "JWT",
            kid = config.get_private_key_id()
        }
    }, tostring(config.get_private_key()), "RS256")

    if err then
        return nil, "Failed to sign JWT: " .. tostring(err)
    end

    local response, err = transport.dispatch(http, "POST", tostring(config.get_token_uri()), {
        headers = {
            ["Content-Type"] = "application/json"
        },
        body = json.encode({
            grant_type = GRANT_TYPE,
            assertion = signature
        }),
        timeout = TIMEOUT
    }, config.get_deadline_at())

    if err then
        return nil, "Failed to retrieve OAuth2 token: " .. tostring(err)
    end

    return json.decode(response.body or "")
end

-- Both request-time cache misses and the background refresher use this path.
-- The unidentified legacy cache entry is never an authentication fallback.
function oauth2.refresh_token()
    local key, key_err = config.get_oauth2_cache_key()
    if not key then return nil, key_err end
    local response, token_err = oauth2.get_token()
    if token_err then return nil, token_err end
    if type(response) ~= "table" then return nil, "Google OAuth2 response contains no valid access token" end
    local expires_in = response.expires_in == nil and 3600 or tonumber(response.expires_in)
    if type(response.access_token) ~= "string" or response.access_token == ""
        or not expires_in or expires_in <= 0 or expires_in ~= expires_in or expires_in == math.huge then
        return nil, "Google OAuth2 response contains no valid access token"
    end
    local instance, store_err = store.get(env.get("APP_CACHE") or config.DEFAULT_CACHE_ID)
    if store_err then return nil, "Failed to access cache store: " .. tostring(store_err) end
    local token = {access_token = response.access_token, expires_at = time.now():unix() + expires_in - 300}
    local _, write_err = instance:set(key, token, expires_in)
    instance:release()
    if write_err then return nil, "Failed to store token in cache: " .. tostring(write_err) end
    return token, nil
end

return oauth2
