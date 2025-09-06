local ctx = require("ctx")

local function run(numbers)
    local config = ctx.all() or {}

    if config.should_fail then
        return nil, "Test failure in calculate_stats"
    end

    if type(numbers) ~= "table" or #numbers == 0 then
        return { count = 0, sum = 0, average = 0 }
    end

    local sum = 0
    local count = #numbers

    for _, num in ipairs(numbers) do
        sum = sum + (tonumber(num) or 0)
    end

    local stats = {
        count = count,
        sum = sum,
        average = count > 0 and sum / count or 0,
        calculated_by = "calculate_stats"
    }

    if config.include_min_max then
        local min = numbers[1] or 0
        local max = numbers[1] or 0
        for _, num in ipairs(numbers) do
            local n = tonumber(num) or 0
            if n < min then min = n end
            if n > max then max = n end
        end
        stats.min = min
        stats.max = max
    end

    return stats
end

return { run = run }