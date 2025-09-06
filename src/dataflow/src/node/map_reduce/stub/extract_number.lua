local ctx = require("ctx")

local function run(data)
    local config = ctx.all() or {}

    if config.should_fail then
        return nil, "Test failure in extract_number"
    end

    if type(data) == "number" then
        return data
    end

    if type(data) == "table" then
        local field = config.field or "value"

        -- Try direct field access first
        if data[field] ~= nil then
            return tonumber(data[field]) or 0
        end

        -- Try input_echo field (from test_func output)
        if data.input_echo and type(data.input_echo) == "table" and data.input_echo[field] ~= nil then
            return tonumber(data.input_echo[field]) or 0
        end

        -- Try accessing nested structure
        if data.processed_by and data.input_echo then
            local input_data = data.input_echo
            if type(input_data) == "table" and input_data[field] ~= nil then
                return tonumber(input_data[field]) or 0
            end
        end

        return 0
    end

    return 0
end

return { run = run }