local json = require("json")
local tools = require("tools")
local funcs = require("funcs")

-- Function status constants
local FUNC_STATUS = {
    PENDING = "pending",
    SUCCESS = "success",
    ERROR = "error"
}

-- Strategy constants
local STRATEGY = {
    SEQUENTIAL = "sequential",
    PARALLEL = "parallel"
}

-- Tool Caller class
local tool_caller = {}
tool_caller.__index = tool_caller

-- Constructor
function tool_caller.new()
    local self = setmetatable({}, tool_caller)
    self.executor = funcs.new()
    self.strategy = STRATEGY.SEQUENTIAL -- Default strategy
    return self
end

-- Set execution strategy
function tool_caller:set_strategy(strategy)
    if strategy == STRATEGY.PARALLEL or strategy == STRATEGY.SEQUENTIAL then
        self.strategy = strategy
    end
    return self
end

-- Validate tool calls and return enriched data
function tool_caller:validate(tool_calls)
    -- Check if there are any tool calls
    if not tool_calls or #tool_calls == 0 then
        return {}, nil
    end

    local validated_tools = {}
    local has_exclusive = false
    local exclusive_tool = nil

    -- First pass: check for exclusive tools and get metadata
    for _, tool_call in ipairs(tool_calls) do
        local tool_name = tool_call.name
        local arguments = tool_call.arguments
        local registry_id = tool_call.registry_id
        -- Use the original call ID from LLM instead of generating new UUID
        local function_call_id = tool_call.id

        -- Get tool schema with metadata
        local schema, err = tools.get_tool_schema(registry_id)
        if err then
            -- Add to validated tools with error
            validated_tools[function_call_id] = {
                call_id = function_call_id,
                name = tool_name,
                args = arguments,
                registry_id = registry_id,
                meta = {},
                error = "Failed to get tool schema: " .. tostring(err),
                valid = false
            }
            goto continue
        end

        local meta = schema and schema.meta or {}

        -- Check if this is an exclusive tool
        if meta.exclusive then
            if has_exclusive then
                -- Multiple exclusive tools found - error
                return {}, "Multiple exclusive tools found, cannot process"
            end

            has_exclusive = true
            exclusive_tool = function_call_id
        end

        -- Add to validated tools
        validated_tools[function_call_id] = {
            call_id = function_call_id,
            name = tool_name,
            args = arguments,
            registry_id = registry_id,
            meta = meta,
            context = tool_call.context, -- Preserve tool context
            valid = true
        }

        ::continue::
    end

    -- Second pass: if we have an exclusive tool, only keep that one
    if has_exclusive and #tool_calls > 1 then
        local exclusive_data = validated_tools[exclusive_tool]
        local result = {}
        result[exclusive_tool] = exclusive_data

        -- Return only the exclusive tool and a message about the others being skipped
        return result, "Exclusive tool found, other tools skipped"
    end

    return validated_tools, nil
end

-- Execute a single tool call
local function execute_single_tool(executor, call_id, tool_call, context)
    local registry_id = tool_call.registry_id
    local args = tool_call.args
    local tool_context = tool_call.context or {}

    if type(args) == "string" then
        local parsed_args, err = json.decode(args)
        if err then
            return {
                result = nil,
                error = "Failed to parse arguments: " .. tostring(err),
                tool_call = tool_call
            }
        end
        args = parsed_args
    end

    -- Merge tool context with session context (session context has priority)
    local merged_context = {}
    for k, v in pairs(tool_context) do
        merged_context[k] = v
    end
    for k, v in pairs(context or {}) do
        merged_context[k] = v
    end

    -- Set call_id in context for tool execution
    merged_context.call_id = call_id

    -- Execute the tool
    local ctx_executor = executor:with_context(merged_context)
    local result, err = ctx_executor:call(registry_id, args)

    return {
        result = result,
        error = err,
        tool_call = tool_call
    }
end

-- Execute tools sequentially
local function execute_sequential(self, context, validated_tools)
    local results = {}

    -- Handle nil or empty validated_tools
    if not validated_tools then
        return results
    end

    for call_id, tool_call in pairs(validated_tools) do
        if not tool_call.valid then
            results[call_id] = {
                error = tool_call.error,
                tool_call = tool_call
            }
            goto continue
        end

        local exec_result = execute_single_tool(self.executor, call_id, tool_call, context)
        results[call_id] = exec_result

        ::continue::
    end

    return results
end

-- Execute tools in parallel
local function execute_parallel(self, context, validated_tools)
    local results = {}
    local commands = {}

    -- Start all valid tools
    for call_id, tool_call in pairs(validated_tools) do
        if not tool_call.valid then
            results[call_id] = {
                error = tool_call.error,
                tool_call = tool_call
            }
            goto continue
        end

        local registry_id = tool_call.registry_id
        local args = tool_call.args
        local tool_context = tool_call.context or {}

        if type(args) == "string" then
            local parsed_args, err = json.decode(args)
            if err then
                results[call_id] = {
                    error = "Failed to parse arguments: " .. tostring(err),
                    tool_call = tool_call
                }
                goto continue
            end
            args = parsed_args
        end

        -- Merge contexts (session has priority)
        local merged_context = {}
        for k, v in pairs(tool_context) do
            merged_context[k] = v
        end
        for k, v in pairs(context or {}) do
            merged_context[k] = v
        end
        merged_context.call_id = call_id

        -- Start async execution
        local ctx_executor = self.executor:with_context(merged_context)
        local command = ctx_executor:async(registry_id, args)

        commands[call_id] = {
            command = command,
            tool_call = tool_call
        }

        ::continue::
    end

    -- Wait for all commands to complete
    for call_id, cmd_info in pairs(commands) do
        local command = cmd_info.command
        local tool_call = cmd_info.tool_call

        -- Wait for completion
        local response_channel = command:response()
        local payload_wrapper, ok = response_channel:receive()

        if ok and not command:is_canceled() then
            local payload, err = command:result()
            if err then
                results[call_id] = {
                    result = nil,
                    error = err,
                    tool_call = tool_call
                }
            else
                local result = payload and payload:data() or nil
                results[call_id] = {
                    result = result,
                    error = nil,
                    tool_call = tool_call
                }
            end
        else
            local _, err = command:result()
            results[call_id] = {
                result = nil,
                error = "Tool execution failed or was canceled: " .. tostring(err),
                tool_call = tool_call
            }
        end
    end

    return results
end

-- Execute validated tools
function tool_caller:execute(context, validated_tools)
    -- Handle nil validated_tools
    if not validated_tools then
        validated_tools = {}
    end

    if self.strategy == STRATEGY.PARALLEL then
        return execute_parallel(self, context, validated_tools)
    else
        return execute_sequential(self, context, validated_tools)
    end
end

-- Export constants
tool_caller.FUNC_STATUS = FUNC_STATUS
tool_caller.STRATEGY = STRATEGY

return tool_caller
