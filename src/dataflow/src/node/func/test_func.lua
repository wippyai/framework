local time = require("time")

local function run(input_data)
    if not input_data then
        return nil, "input data is required"
    end

    local message = "Hello from test function"
    local delay_ms = 100
    local should_fail = false
    local branches_processed = nil

    -- Handle single input
    if type(input_data) == "table" and not input_data.from_b and not input_data.from_c then
        message = input_data.message or message
        delay_ms = input_data.delay_ms or delay_ms
        should_fail = input_data.should_fail or should_fail
    -- Handle diamond merge (multiple inputs)
    elseif type(input_data) == "table" and (input_data.from_b or input_data.from_c) then
        -- This is Node D receiving from both B and C
        local branch_b = input_data.from_b
        local branch_c = input_data.from_c

        if branch_b and branch_c then
            message = branch_b.message or branch_c.message or message
            branches_processed = {
                branch_b_timestamp = branch_b.timestamp,
                branch_c_timestamp = branch_c.timestamp,
                branch_b_processed_by = branch_b.processed_by,
                branch_c_processed_by = branch_c.processed_by
            }
        end
    elseif type(input_data) == "string" then
        message = input_data
    end

    if delay_ms > 0 then
        time.sleep(delay_ms .. "ms")
    end

    if should_fail then
        return nil, "Intentional semantic failure"
    end

    local output = {
        message = message,
        timestamp = time.now():format(time.RFC3339NANO),
        delay_applied = delay_ms,
        input_echo = input_data,
        processed_by = "test_function",
        success = true
    }

    -- Add diamond-specific info if this was a merge
    if branches_processed then
        output.diamond_merge = branches_processed
        output.diamond_pattern = true
    end

    return output
end

return { run = run }