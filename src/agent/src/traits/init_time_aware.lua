local time = require("time")
local ctx = require("ctx")

type TimeAwareResult = {
    prompt: string,
}

local function execute(base_prompt: string?): TimeAwareResult
    local timezone = ctx.get("timezone") or "UTC"
    local interval_minutes = ctx.get("time_interval") or 15

    local current_time = time.now()

    if timezone ~= "UTC" then
        local loc, err = time.load_location(tostring(timezone))
        if not err and loc then
            current_time = current_time:in_location(loc)
        end
    end

    local year = current_time:year()
    local month = current_time:month()
    local day = current_time:day()
    local hour = current_time:hour()
    local minute = current_time:minute()
    local weekday = current_time:weekday()

    local rounded_minute = math.floor(minute / interval_minutes) * interval_minutes

    local weekdays = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" }
    local weekday_name = weekdays[weekday + 1]

    local months = { "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December" }
    local month_name = months[month]

    local full_prompt = string.format(
        "The current date and time is %s, %s %d, %d at %02d:%02d %s. Use this temporal context when relevant to your responses.",
        weekday_name, month_name, day, year, hour, rounded_minute, timezone)

    return {
        prompt = full_prompt
    }
end

return { execute = execute }
