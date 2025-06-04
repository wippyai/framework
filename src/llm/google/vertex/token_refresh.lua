local time = require("time")
local json = require("json")
local base64 = require("base64")
local crypto = require("crypto")
local http = require("http_client")
local env = require("env")
local store = require("store")

-- Process to refresh tokens periodically
local function run(args)
    -- Initialize state
    local running = true
    local refresh_interval = "50m" -- 50 minutes

    local function refresh_token()
        local time_now = time.now()

        local storeObj, err = store.get("app:cache")

        local private_key_id = env.get("VERTEX_AI_PRIVATE_KEY_ID")
        local client_email = env.get("VERTEX_AI_CLIENT_EMAIL")
        local private_key = env.get("VERTEX_AI_PRIVATE_KEY")

        if not private_key_id or not client_email or not private_key or
            private_key_id == "" or client_email == "" or private_key == "" then
            print("Missing required environment variables")
            storeObj:release()
            return
        end

        private_key = base64.decode(private_key)

        local signature, sign_err = crypto.jwt.encode({
            iss = client_email,
            scope = "https://www.googleapis.com/auth/cloud-platform",
            aud = "https://oauth2.googleapis.com/token",
            exp = time_now:unix() + 3600,
            iat = time_now:unix(),
            _header = {
                alg = "RS256",
                typ = "JWT",
                kid = private_key_id
            }
        }, private_key, "RS256")

        if sign_err then
            print("Failed to sign JWT: " .. sign_err)
            storeObj:release()
            return
        end

        local url = "https://oauth2.googleapis.com/token"
        local headers = {
            ["Content-Type"] = "application/json"
        }

        local response, err = http.post(url, {
            headers = headers,
            body = json.encode({
                grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer",
                assertion = signature
            }),
            timeout = 300
        })

        if err then
            print("Failed to retrieve OAuth2 token: " .. tostring(err))
            storeObj:release()
            return
        end

        local response_body = json.decode(response.body)

        local token = {
            access_token = response_body.access_token,
            expires_at = (time_now:unix() + response_body.expires_in) - 300 -- Subtract 5 minutes to be safe
        }

        -- Store the token in the cache with TTL
        local success, err = storeObj:set("vertex_oauth_token", token, response_body.expires_in)
        if err then
            print("Failed to store token in cache: " .. err)
        else
            print("Token successfully refreshed and stored")
        end

        -- Release the store when done
        storeObj:release()
    end

    -- Create a ticker for the refresh interval
    local ticker = time.ticker(refresh_interval)
    local ticker_channel = ticker:channel()

    -- Get the events channel to listen for cancellation
    local events = process.events()

    -- Call refresh_token initially
    refresh_token()
    print("Token refreshed, next refresh in 50 minutes")

    -- Main loop
    while running do
        -- Wait for either ticker or cancellation event
        local result = channel.select({
            ticker_channel:case_receive(),
            events:case_receive()
        })

        if result.channel == ticker_channel then
            -- Time to refresh the token
            refresh_token()
            print("Token refreshed, next refresh in 50 minutes")
        elseif result.channel == events then
            -- Check if it's a cancellation event
            local event = result.value
            if event.kind == process.event.CANCEL then
                print("Received cancellation, shutting down")
                running = false
            end
        end
    end

    -- Clean up
    ticker:stop()

    return { status = "completed" }
end

return { run = run }
