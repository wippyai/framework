local http = require("http_client")
local time = require("time")
local crypto = require("crypto")
local config = require("google_config")
local json = require("json")

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
    }, config.get_private_key(), "RS256")

    if err then
        return nil, "Failed to sign JWT: " .. tostring(err)
    end

    local response, err = http.post(config.get_token_uri(), {
        headers = {
            ["Content-Type"] = "application/json"
        },
        body = json.encode({
            grant_type = GRANT_TYPE,
            assertion = signature
        }),
        timeout = TIMEOUT
    })

    if err then
        return nil, "Failed to retrieve OAuth2 token: " .. tostring(err)
    end

    return json.decode(response.body)
end

return oauth2
