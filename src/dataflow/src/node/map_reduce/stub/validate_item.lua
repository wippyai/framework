local ctx = require("ctx")

local function run(iteration_result)
    if not iteration_result then
        return false, "No iteration result provided for validation"
    end

    -- Get configuration from context
    local config, err = ctx.all()
    if err then
        config = {}
    end

    local should_fail = config.should_fail or false
    local validation_mode = config.validation_mode or "basic"
    local min_value = config.min_value or 0
    local required_fields = config.required_fields or {}

    if should_fail then
        return nil, "Intentional test failure in validate_item"
    end

    if validation_mode == "value_check" then
        -- Value-based validation - check original input data in input_echo
        local value = nil
        if type(iteration_result) == "table" then
            -- First try to get value from input_echo (for processed results)
            if iteration_result.input_echo and iteration_result.input_echo.value then
                value = iteration_result.input_echo.value
            -- Fallback to direct value field
            elseif iteration_result.value then
                value = iteration_result.value
            -- Fallback to score field
            elseif iteration_result.score then
                value = iteration_result.score
            else
                value = 0
            end
        elseif type(iteration_result) == "number" then
            value = iteration_result
        else
            return false -- Filter out non-numeric, non-table items
        end

        if value < min_value then
            return false -- Filter out items below minimum value
        end

    elseif validation_mode == "strict" then
        -- Strict validation - require table with specific fields
        if type(iteration_result) ~= "table" then
            return false -- Filter out non-tables
        end

        -- Check required fields
        for _, field in ipairs(required_fields) do
            if iteration_result[field] == nil then
                return false -- Filter out items missing required fields
            end
        end

        -- Check success status
        if iteration_result.success == false then
            return false -- Filter out failed items
        end

    elseif validation_mode == "basic" then
        -- Basic validation - just check for nil and empty
        if iteration_result == nil or iteration_result == "" then
            return false
        end

        if type(iteration_result) == "table" and next(iteration_result) == nil then
            return false -- Filter out empty tables
        end

    elseif validation_mode == "allow_all" then
        -- Allow everything through
        return true
    end

    -- Default: item passes validation
    return true
end

return { run = run }