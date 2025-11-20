local time = require("time")
local store = require("store")
local oauth2 = require("google_oauth2")
local env = require("env")
local config = require("google_config")

local REFRESH_INTERVAL = "50m"

local function refresh_token()
    local time_now = time.now()

    local store_instance, err = store.get(env.get("APP_CACHE") or config.DEFAULT_CACHE_ID)
    if err then
        print("Failed to access cache store: " .. tostring(err))
        return
    end

    local response, err = oauth2.get_token()
    if err then
        print("Failed to refresh token: " .. tostring(err))
        store_instance:release()
        return
    end

    local token = {
        access_token = response.access_token,
        expires_at = (time_now:unix() + response.expires_in) - 300 -- Subtract 5 minutes to be safe
    }

    local _, err = store_instance:set(config.OAUTH2_TOKEN_CACHE_KEY, token, response.expires_in)
    if err then
        print("Failed to store token in cache: " .. tostring(err))
        store_instance:release()
        return
    end

    store_instance:release()

    print("Token refreshed, next refresh in 50 minutes")
end

-- Process to refresh tokens periodically
local function run(args)
    if not config.has_credentials() then
        print("Google credentials are missing, Google OAuth2 token refresher will not start.")
        return { status = "completed" }
    end

    local running = true

    local ticker = time.ticker(REFRESH_INTERVAL)
    local ticker_channel = ticker:channel()

    local events = process.events()

    refresh_token()

    while running do
        local result = channel.select({
            ticker_channel:case_receive(),
            events:case_receive()
        })

        if result.channel == ticker_channel then
            refresh_token()
        elseif result.channel == events then
            local event = result.value
            if event.kind == process.event.CANCEL then
                print("Received cancellation, shutting down")
                running = false
            end
        end
    end

    ticker:stop()

    return { status = "completed" }
end

return { run = run }
