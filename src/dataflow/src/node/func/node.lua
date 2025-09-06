-- Error codes
local ERROR_MISSING_FUNC_ID = "MISSING_FUNC_ID"
local ERROR_NO_INPUT_DATA = "NO_INPUT_DATA"
local ERROR_FUNCTION_CANCELED = "FUNCTION_CANCELED"
local ERROR_FUNCTION_EXECUTION_FAILED = "FUNCTION_EXECUTION_FAILED"

local func = {}

-- Exposed dependencies for testing
func._deps = {
    node = require("node"),
    funcs = require("funcs")
}

local function run(args)
    local n, err = func._deps.node.new(args)
    if err then
        error(err)
    end

    -- Get function configuration from node config
    local config = n:config()
    local func_id = config.func_id
    if not func_id or func_id == "" then
        return n:fail({
            code = ERROR_MISSING_FUNC_ID,
            message = "Function ID not specified in node configuration"
        }, "Missing func_id in node config")
    end

    -- Get inputs and process them intelligently
    local inputs = n:inputs()
    local input_data = nil

    if next(inputs) == nil then
        -- No inputs at all
        input_data = nil
    elseif inputs.default then
        -- Use "default" key if present (highest priority)
        input_data = inputs.default.content
    elseif inputs[""] then
        -- Use empty string key as root/default input (second priority)
        input_data = inputs[""].content
    else
        -- Count available inputs
        local input_count = 0
        for _ in pairs(inputs) do
            input_count = input_count + 1
        end

        if input_count == 1 then
            -- Single input - use it directly (preserves original behavior)
            for _, input in pairs(inputs) do
                input_data = input.content
                break
            end
        else
            -- Multiple inputs - merge them into a keyed object
            input_data = {}
            for key, input in pairs(inputs) do
                input_data[key] = input.content
            end
        end
    end

    if input_data == nil then
        return n:fail({
            code = ERROR_NO_INPUT_DATA,
            message = "No input data provided for function node"
        }, "Function node requires input data")
    end

    -- Create function executor
    local executor = func._deps.funcs.new()

    -- Add context if specified in config
    if config.context then
        executor = executor:with_context(config.context)
    end

    -- Execute function asynchronously (for cancellation support)
    local command = executor:async(func_id, input_data)
    local response_channel = command:response()
    local events_channel = process.events()

    -- Wait for either function result or cancellation
    local result = channel.select({
        response_channel:case_receive(),
        events_channel:case_receive()
    })

    if result.channel == events_channel then
        -- Received a system event
        local event = result.value
        if event.kind == process.event.CANCEL then
            -- Cancel the function execution
            command:cancel()
            return n:fail({
                code = ERROR_FUNCTION_CANCELED,
                message = "Function execution was canceled by system event"
            }, "Function execution was canceled")
        end
    end

    -- Handle function completion
    if command:is_canceled() then
        return n:fail({
            code = ERROR_FUNCTION_CANCELED,
            message = "Function execution was canceled"
        }, "Function execution was canceled")
    end

    -- Get final result
    local payload, result_err = command:result()

    if result_err then
        return n:fail({
            code = ERROR_FUNCTION_EXECUTION_FAILED,
            message = result_err
        }, "Function execution failed: " .. result_err)
    end

    local function_result = payload:data()
    return n:complete(function_result, "Function executed successfully")
end

func.run = run
return func