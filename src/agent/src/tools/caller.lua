local json = require("json")
local tools = require("tools")
local funcs = require("funcs")
local contract = require("contract")

type ToolCall = {
    id: string,
    name: string,
    arguments: string | table,
    registry_id: string,
    context: table?,
    provider_metadata: table?,
}

type ValidatedTool = {
    call_id: string,
    name: string,
    args: string | table,
    registry_id: string,
    meta: table,
    context: table?,
    error: string?,
    valid: boolean,
}

type ToolExecResult = {
    result: any?,
    error: string?,
    tool_call: ValidatedTool,
}

type ToolWrapperPhase = string

type ToolWrapperSpec = {
    id: string?,
    trait_id: string?,
    phases: {ToolWrapperPhase},
    binding: string,
    context: table?,
    options: table?,
    priority: number?,
    strict: boolean?,
    order: number?,
}

type ToolWrapperHostRef = {
    kind: string,
    session_id: string?,
    dataflow_id: string?,
    node_id: string?,
    run_id: string?,
    iteration: number?,
}

type ToolWrapperAgentRef = {
    id: string?,
    model: string?,
}

type ToolWrapperOutcome = {
    state: string,
    reason: string,
}

type ToolWrapperExecutionContext = {
    host: ToolWrapperHostRef?,
    agent: ToolWrapperAgentRef?,
    outcome: ToolWrapperOutcome?,
    run_context: any?,
}

type ToolWrapperApplyRequest = {
    phase: ToolWrapperPhase,
    host: ToolWrapperHostRef?,
    agent: ToolWrapperAgentRef?,
    tool_calls: {ToolCall},
    tool_results: {[string]: ToolExecResult}?,
    outcome: ToolWrapperOutcome?,
    options: table,
    run_context: any?,
}

type ToolWrapperObservation = {
    level: string,
    code: string,
    content: any,
    metadata: table?,
}

type ToolWrapperApplyResponse = {
    skipped: boolean?,
    tool_calls: {ToolCall}?,
    observations: {ToolWrapperObservation}?,
    metadata: table?,
}

type ToolWrapperError = {
    wrapper_id: string?,
    trait_id: string?,
    phase: ToolWrapperPhase,
    error: string,
    strict: boolean,
}

type ToolWrapperMetadata = {
    wrapper_id: string?,
    trait_id: string?,
    phase: ToolWrapperPhase,
    metadata: table,
}

local FUNC_STATUS = {
    PENDING = "pending",
    SUCCESS = "success",
    ERROR = "error"
}

local STRATEGY = {
    SEQUENTIAL = "sequential",
    PARALLEL = "parallel"
}

local BEFORE_EXECUTE: ToolWrapperPhase = "before_execute"
local AFTER_EXECUTE: ToolWrapperPhase = "after_execute"

local PHASE = {
    BEFORE_EXECUTE = BEFORE_EXECUTE,
    AFTER_EXECUTE = AFTER_EXECUTE
}

local OUTCOME_STATE = {
    CONTINUES = "continues",
    COMPLETED = "completed",
    FAILED = "failed",
    COMPACTED = "compacted",
    DELEGATED = "delegated"
}

local OUTCOME_REASON = {
    TOOL_RESULTS_RECORDED = "tool_results_recorded",
    TOOL_EXECUTION_FAILED = "tool_execution_failed",
    EXIT_TOOL_COMPLETED = "exit_tool_completed",
    DELEGATION_REQUESTED = "delegation_requested",
    NO_TOOLS_REQUIRED = "no_tools_required",
    MAX_ITERATIONS_REACHED = "max_iterations_reached",
    CONTEXT_LIMIT_REACHED = "context_limit_reached",
    HOST_FAILED = "host_failed"
}

local tool_caller = {}
tool_caller.__index = tool_caller

tool_caller._json = nil
tool_caller._tools = nil
tool_caller._funcs = nil
tool_caller._contract = nil

local function get_json(): any
    return tool_caller._json or json
end

local function get_tools(): any
    return tool_caller._tools or tools
end

local function get_funcs(): any
    return tool_caller._funcs or funcs
end

local function get_contract(): any
    return tool_caller._contract or contract
end

function tool_caller.new(): any
    local self = setmetatable({}, tool_caller)
    self.executor = get_funcs().new()
    self.strategy = STRATEGY.SEQUENTIAL -- Default strategy
    self.tool_wrappers = {}
    self.wrapper_context = {}
    self.wrapper_observations = {}
    self.wrapper_metadata = {}
    self.wrapper_errors = {}
    self.last_tool_calls = {}
    return self
end

function tool_caller:set_strategy(strategy: string): any
    if strategy == STRATEGY.PARALLEL or strategy == STRATEGY.SEQUENTIAL then
        self.strategy = strategy
    end
    return self
end

local function normalize_tool_wrappers(wrappers: {ToolWrapperSpec}?): {ToolWrapperSpec}
    local normalized: {ToolWrapperSpec} = {}
    for _, wrapper in ipairs(wrappers or {}) do
        if type(wrapper) == "table" then
            normalized[#normalized + 1] = wrapper
        end
    end
    table.sort(normalized, function(a, b)
        local ap = a.priority or 100
        local bp = b.priority or 100
        if ap == bp then
            return (a.order or 0) < (b.order or 0)
        end
        return ap < bp
    end)
    return normalized :: {ToolWrapperSpec}
end

function tool_caller:set_tool_wrappers(wrappers: {ToolWrapperSpec}?): any
    self.tool_wrappers = normalize_tool_wrappers(wrappers)
    return self
end

function tool_caller:set_wrapper_context(context: ToolWrapperExecutionContext?): any
    self.wrapper_context = context or {}
    return self
end

function tool_caller:get_wrapper_observations(): {ToolWrapperObservation}
    return self.wrapper_observations or {}
end

function tool_caller:get_wrapper_errors(): {ToolWrapperError}
    return self.wrapper_errors or {}
end

function tool_caller:get_wrapper_metadata(): {ToolWrapperMetadata}
    return self.wrapper_metadata or {}
end

function tool_caller:get_last_tool_calls(): {ToolCall}
    return self.last_tool_calls or {}
end

local function reset_wrapper_diagnostics(self: any)
    self.wrapper_observations = {}
    self.wrapper_metadata = {}
    self.wrapper_errors = {}
end

local function wrapper_supports_phase(wrapper: ToolWrapperSpec, phase: ToolWrapperPhase): boolean
    for _, wrapper_phase in ipairs(wrapper.phases or {}) do
        if wrapper_phase == phase then
            return true
        end
    end
    return false
end

local function infer_outcome(results: {[string]: ToolExecResult}?): ToolWrapperOutcome
    for _, result in pairs(results or {}) do
        if result and result.error then
            return {
                state = OUTCOME_STATE.CONTINUES,
                reason = OUTCOME_REASON.TOOL_EXECUTION_FAILED
            }
        end
    end

    return {
        state = OUTCOME_STATE.CONTINUES,
        reason = OUTCOME_REASON.TOOL_RESULTS_RECORDED
    }
end

local function copy_payload(payload: ToolWrapperApplyRequest?): ToolWrapperApplyRequest
    local out = {}
    for k, v in pairs(payload or {}) do
        out[k] = v
    end
    return out :: ToolWrapperApplyRequest
end

local function call_contract_wrapper(wrapper: ToolWrapperSpec, payload: ToolWrapperApplyRequest): (ToolWrapperApplyResponse?, string?)
    local binding = wrapper.binding
    if type(binding) ~= "string" or binding == "" then
        return nil, "tool wrapper binding is required"
    end

    local contract_def, contract_err = get_contract().get("wippy.agent:tool_wrapper")
    if contract_err or not contract_def then
        return nil, "failed to load tool_wrapper contract: " .. tostring(contract_err or "not found")
    end

    local opener = contract_def
    if opener.with_context then
        opener = opener:with_context(wrapper.context or {})
    end

    local instance, open_err = opener:open(tostring(binding))
    if open_err or not instance then
        return nil, "failed to open tool_wrapper binding: " .. tostring(open_err or "no instance")
    end

    local result, apply_err = instance:apply(payload)
    if apply_err then
        return nil, tostring(apply_err)
    end
    return (type(result) == "table" and result or {}) :: ToolWrapperApplyResponse, nil
end

local function call_wrapper(self: any, wrapper: ToolWrapperSpec, payload: ToolWrapperApplyRequest): (ToolWrapperApplyResponse?, string?)
    return call_contract_wrapper(wrapper, payload)
end

local function record_wrapper_result(self: any, wrapper: ToolWrapperSpec, phase: ToolWrapperPhase, result: ToolWrapperApplyResponse?)
    if type(result) ~= "table" then
        return
    end

    for _, observation in ipairs(result.observations or {}) do
        self.wrapper_observations[#self.wrapper_observations + 1] = observation
    end

    if result.metadata ~= nil then
        self.wrapper_metadata[#self.wrapper_metadata + 1] = {
            wrapper_id = wrapper.id,
            trait_id = wrapper.trait_id,
            phase = phase,
            metadata = result.metadata,
        }
    end
end

local function record_wrapper_error(self: any, wrapper: ToolWrapperSpec, phase: ToolWrapperPhase, err: string)
    self.wrapper_errors[#self.wrapper_errors + 1] = {
        wrapper_id = wrapper.id,
        trait_id = wrapper.trait_id,
        phase = phase,
        error = tostring(err),
        strict = wrapper.strict == true,
    }
end

function tool_caller:apply_tool_wrappers(phase: ToolWrapperPhase, payload: ToolWrapperApplyRequest?): (ToolWrapperApplyRequest, string?)
    local current_payload: ToolWrapperApplyRequest = copy_payload(payload)
    current_payload.phase = phase
    current_payload.host = current_payload.host or self.wrapper_context.host
    current_payload.agent = current_payload.agent or self.wrapper_context.agent or {}
    current_payload.run_context = current_payload.run_context or self.wrapper_context.run_context
    current_payload.tool_calls = current_payload.tool_calls or {}
    current_payload.options = current_payload.options or {}

    local wrappers: {ToolWrapperSpec} = self.tool_wrappers or {}
    if #wrappers == 0 then
        return current_payload, nil
    end

    if type(current_payload.host) ~= "table" or type(current_payload.host.kind) ~= "string" or current_payload.host.kind == "" then
        return current_payload, "tool wrapper host is required"
    end

    if phase == PHASE.AFTER_EXECUTE and current_payload.outcome == nil then
        current_payload.outcome = self.wrapper_context.outcome or infer_outcome(current_payload.tool_results)
    end

    for _, wrapper in ipairs(wrappers) do
        if wrapper_supports_phase(wrapper, phase) then
            current_payload.options = wrapper.options or {}

            local result, err = call_wrapper(self, wrapper, current_payload :: ToolWrapperApplyRequest)
            if err then
                record_wrapper_error(self, wrapper, phase, err)
                if wrapper.strict == true and phase == PHASE.BEFORE_EXECUTE then
                    return current_payload :: ToolWrapperApplyRequest, err
                end
                goto continue
            end

            record_wrapper_result(self, wrapper, phase, result)
            if phase == PHASE.BEFORE_EXECUTE and result and type(result.tool_calls) == "table" then
                current_payload.tool_calls = result.tool_calls
            end
        end

        ::continue::
    end

    return current_payload :: ToolWrapperApplyRequest, nil
end

function tool_caller:validate(tool_calls: {ToolCall}?): (any, string?)
    -- Check if there are any tool calls
    if not tool_calls or #tool_calls == 0 then
        return {}, nil
    end

    reset_wrapper_diagnostics(self)

    local before_payload: ToolWrapperApplyRequest = {
        phase = BEFORE_EXECUTE :: ToolWrapperPhase,
        host = self.wrapper_context.host,
        agent = self.wrapper_context.agent,
        tool_calls = tool_calls,
        options = {},
    }
    local wrapped_payload, wrapper_err = self:apply_tool_wrappers(BEFORE_EXECUTE, before_payload)
    if wrapper_err then
        return nil, "Tool wrapper failed: " .. tostring(wrapper_err)
    end

    tool_calls = wrapped_payload.tool_calls or tool_calls
    self.last_tool_calls = tool_calls

    local validated_tools: {[string]: any} = {}
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
        local schema, err = get_tools().get_tool_schema(registry_id)
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
            provider_metadata = tool_call.provider_metadata,
            valid = true
        }

        ::continue::
    end

    -- Second pass: if we have an exclusive tool, only keep that one
    if has_exclusive and #tool_calls > 1 then
        local exclusive_data = (validated_tools :: any)[exclusive_tool]
        local result = {}
        result[exclusive_tool] = exclusive_data

        -- Return only the exclusive tool and a message about the others being skipped
        return result, "Exclusive tool found, other tools skipped"
    end

    return validated_tools, nil
end

local function execute_single_tool(executor: any, call_id: string, tool_call: any, context: table?): any
    local registry_id = tool_call.registry_id
    local args = tool_call.args
    local tool_context = tool_call.context or {}

    if type(args) == "string" then
        local parsed_args, err = get_json().decode(args)
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
    local result, err = ctx_executor:call(tostring(registry_id), args)

    return {
        result = result,
        error = err,
        tool_call = tool_call
    }
end

local function execute_sequential(self: any, context: any, validated_tools: any): any
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

        local exec_result = execute_single_tool(self.executor, tostring(call_id), tool_call, context as {}?)
        results[call_id] = exec_result

        ::continue::
    end

    return results
end

local function execute_parallel(self: any, context: table?, validated_tools: any): any
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
            local parsed_args, err = get_json().decode(args)
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
        local command = ctx_executor:async(tostring(registry_id), args)

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

function tool_caller:execute(context: any, validated_tools: any): any
    -- Handle nil validated_tools
    if not validated_tools then
        validated_tools = {}
    end

    local results
    if self.strategy == STRATEGY.PARALLEL then
        results = execute_parallel(self :: any, context as table?, validated_tools)
    else
        results = execute_sequential(self :: any, context, validated_tools)
    end

    local after_payload: ToolWrapperApplyRequest = {
        phase = AFTER_EXECUTE :: ToolWrapperPhase,
        host = self.wrapper_context.host,
        agent = self.wrapper_context.agent,
        tool_calls = self.last_tool_calls or {},
        tool_results = results :: {[string]: ToolExecResult},
        outcome = self.wrapper_context.outcome or infer_outcome(results),
        options = {},
    }
    self:apply_tool_wrappers(AFTER_EXECUTE, after_payload)

    return results
end

-- Export constants
tool_caller.FUNC_STATUS = FUNC_STATUS
tool_caller.STRATEGY = STRATEGY
tool_caller.PHASE = PHASE
tool_caller.OUTCOME_STATE = OUTCOME_STATE
tool_caller.OUTCOME_REASON = OUTCOME_REASON

return tool_caller
