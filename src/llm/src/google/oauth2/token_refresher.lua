local time = require("time")
local oauth2 = require("google_oauth2")
local config = require("google_config")

local REFRESH_INTERVAL = "50m"

local function refresh_token()
    local _, err = oauth2.refresh_token()
    if err then
        print("Failed to refresh token: " .. tostring(err))
        return
    end

    print("Token refreshed, next refresh in 50 minutes")
end

-- Process to refresh tokens periodically
local function run(args)
    local events = process.events()

    if not config.has_credentials() then
        print("Google credentials are missing, Google OAuth2 token refresher will not start.")
        while true do
            local result = channel.select({
                events:case_receive()
            })

            if not result.ok then
                break
            end

            if result.value and result.value.kind == process.event.CANCEL then
                break
            end
        end
        return { status = "completed" }
    end

    local running = true

    local ticker = time.ticker(REFRESH_INTERVAL)
    local ticker_channel = ticker:channel()

    refresh_token()

    while running do
        local result = channel.select({
            ticker_channel:case_receive(),
            events:case_receive()
        })

        if not result.ok then
            break
        end

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
