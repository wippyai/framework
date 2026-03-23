local time = require("time")
local store = require("store")
local env = require("env")
local credentials = require("bedrock_credentials")

local REFRESH_INTERVAL = "5h"
local EXPIRY_BUFFER = 900 -- 15 minutes before expiration

local function refresh_credentials()
    local store_instance, err = store.get(env.get("APP_CACHE") or credentials.DEFAULT_CACHE_ID)
    if err then
        print("Failed to access cache store: " .. tostring(err))
        return
    end

    local creds, fetch_err = credentials.fetch_container_credentials()
    if fetch_err then
        print("Failed to refresh AWS credentials: " .. tostring(fetch_err))
        store_instance:release()
        return
    end

    local ttl = 21600 -- 6 hours default
    if creds.expiration and type(creds.expiration) == "number" then
        local now = time.now()
        local remaining = (creds.expiration :: number) - now:unix()
        if remaining <= 0 then
            print("Fetched credentials are already expired, skipping cache")
            store_instance:release()
            return
        end
        -- Cache with 5-minute safety buffer before actual expiration
        ttl = remaining - 300
        if ttl < 60 then ttl = 60 end
    end

    local _, set_err = store_instance:set(credentials.CACHE_KEY, creds, ttl)
    if set_err then
        print("Failed to store credentials in cache: " .. tostring(set_err))
        store_instance:release()
        return
    end

    store_instance:release()
    print("AWS credentials refreshed, next refresh in 5 hours")
end

local function run(args)
    if not credentials.has_container_endpoint() then
        print("No container credentials endpoint, AWS credential refresher will not start.")
        local events = process.events()
        while true do
            local result = channel.select({
                events:case_receive()
            })
            if result.value and result.value.kind == process.event.CANCEL then
                break
            end
        end
        return { status = "completed" }
    end

    local running = true

    local ticker = time.ticker(REFRESH_INTERVAL)
    local ticker_channel = ticker:channel()
    local events = process.events()

    refresh_credentials()

    while running do
        local result = channel.select({
            ticker_channel:case_receive(),
            events:case_receive()
        })

        if result.channel == ticker_channel then
            refresh_credentials()
        elseif result.channel == events then
            local event = result.value
            if event.kind == process.event.CANCEL then
                print("AWS credential refresher shutting down")
                running = false
            end
        end
    end

    ticker:stop()

    return { status = "completed" }
end

return { run = run }
