local time = require("time")

-- Per-turn context is host state: the host renders the note once when a user
-- turn arrives, persists it as a positional note after that turn and replays
-- it unchanged on every later request, so the provider prefix stays stable.
local turn_context = {}

local WEEKDAYS = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" }
local MONTHS = { "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December" }
local GUIDANCE = "Use this temporal context when relevant to your responses."

-- Returns the time note for agent_options.turn_context.time at the instant now,
-- or nil when the agent declares no time context.
function turn_context.render(agent_options: table?, now: any): (string?, string?)
    local config = agent_options and agent_options.turn_context
    local time_config = type(config) == "table" and config.time or nil
    if type(time_config) ~= "table" then
        return nil, nil
    end

    local timezone = time_config.timezone == nil and "UTC" or time_config.timezone
    if type(timezone) ~= "string" or timezone == "" then
        return nil, "turn context timezone must be a non-empty string"
    end
    local format = time_config.format
    if format ~= nil and (type(format) ~= "string" or format == "") then
        return nil, "turn context format must be a non-empty string when given"
    end
    local location, location_err = time.load_location(timezone)
    if location_err or not location then
        return nil, "turn context timezone " .. timezone .. " cannot be loaded: " .. tostring(location_err)
    end
    local local_time = now:in_location(location)

    local moment = format and local_time:format(format) or string.format("%s, %s %d, %d at %02d:%02d %s",
        WEEKDAYS[local_time:weekday() + 1], MONTHS[local_time:month()], local_time:day(), local_time:year(),
        local_time:hour(), local_time:minute(), timezone)
    return "The current date and time is " .. moment .. ". " .. GUIDANCE, nil
end

return turn_context
