local prompt = require("prompt")
local llm = require("llm")
local contract = require("contract")
local funcs = require("funcs")

---@class UnifiedTool
---@field name string Canonical tool name
---@field description string Tool description
---@field schema table Tool JSON schema
---@field registry_id string|nil Registry ID (nil for inline tools)
---@field context table Tool context with agent_id
---@field agent_id string|nil Agent ID (present for delegate tools)

---@class CompiledAgentSpec
---@field id string Agent unique identifier
---@field name string Agent display name
---@field description string Agent description
---@field model? string LLM model identifier
---@field max_tokens? number Maximum completion tokens
---@field temperature? number Sampling temperature (0-1)
---@field thinking_effort? number Thinking effort (0-100)
---@field prompt string Compiled system prompt
---@field tools table<string, UnifiedTool> Unified tools (keyed by canonical names)
---@field memory string[] Memory items
---@field memory_contract table Memory contract configuration
---@field prompt_funcs table[] Trait prompt functions
---@field step_funcs table[] Trait step functions

---@class TokenUsage
---@field prompt number Prompt tokens used
---@field completion number Completion tokens used
---@field thinking number Thinking tokens used
---@field total number Total tokens used

---@class AgentRunner
---@field id string Agent ID
---@field name string Agent name
---@field description string Agent description
---@field model string LLM model
---@field max_tokens number Maximum tokens
---@field temperature number Temperature
---@field thinking_effort number Thinking effort
---@field tools table<string, UnifiedTool> Unified tools (keyed by canonical names)
---@field memory string[] Memory items
---@field memory_contract table Memory contract configuration
---@field system_prompt string Compiled prompt
---@field system_message table System message
---@field prompt_funcs table[] Trait prompt functions
---@field step_funcs table[] Trait step functions
---@field total_tokens TokenUsage Token usage statistics

local agent = {}

local AGENT_CONFIG = {
    defaults = {
        model = "",
        max_tokens = 512,
        temperature = 0,
        thinking_effort = 0
    },
    memory = {
        contract_id = "wippy.agent:memory",
        recall_prompt = "Relevant context from your memory:\n\n%s",
        defaults = {
            max_messages = 20,
            max_actions = 8,
            message_types = { prompt.ROLE.USER, prompt.ROLE.ASSISTANT, prompt.ROLE.FUNCTION_RESULT, prompt.ROLE.DEVELOPER },
            scan_limit = 50,
            max_items = 3,
            max_length = 1000,
            enabled = true,
            min_conversation_length = 2,
            recall_cooldown = 1
        }
    }
}

agent._llm = nil
agent._prompt = nil
agent._contract = nil
agent._funcs = nil

local function get_llm()
    return agent._llm or llm
end

local function get_prompt()
    return agent._prompt or prompt
end

local function get_contract()
    return agent._contract or contract
end

local function get_funcs()
    return agent._funcs or funcs
end

local function merge_agent_and_context(agent_ctx, delegate_ctx)
    local merged = {}
    for k, v in pairs(agent_ctx or {}) do
        merged[k] = v
    end
    for k, v in pairs(delegate_ctx or {}) do
        merged[k] = v
    end
    return merged
end

local function execute_prompt_functions(self, runtime_context)
    if not self.prompt_funcs or #self.prompt_funcs == 0 then
        return ""
    end

    local prompt_parts = {}
    local funcs_module = get_funcs()

    for _, prompt_func in ipairs(self.prompt_funcs) do
        local merged_context = {}
        for k, v in pairs(prompt_func.context or {}) do
            merged_context[k] = v
        end
        for k, v in pairs(runtime_context or {}) do
            merged_context[k] = v
        end
        merged_context.agent_id = self.id

        local executor = funcs_module.new()
        local prompt_text, err = executor:with_context(merged_context):call(prompt_func.func_id)

        if not err and prompt_text and prompt_text ~= "" then
            table.insert(prompt_parts, prompt_text)
        end

        if err then
            print(err)
        end
    end

    return table.concat(prompt_parts, "\n\n")
end

local function extract_memory_ids_from_messages(messages, scan_limit)
    if not messages or #messages == 0 then
        return {}
    end

    local memory_ids = {}
    local count = 0
    local limit = scan_limit or AGENT_CONFIG.memory.defaults.scan_limit

    for i = #messages, 1, -1 do
        if count >= limit then
            break
        end

        local message = messages[i]
        if message.metadata and message.metadata.memory_ids then
            for _, memory_id in ipairs(message.metadata.memory_ids) do
                table.insert(memory_ids, memory_id)
            end
        end
        count = count + 1
    end

    return memory_ids
end

local function extract_recent_actions(messages, max_actions, message_types)
    if not messages or #messages == 0 then
        return {}
    end

    local actions = {}
    local types = message_types or AGENT_CONFIG.memory.defaults.message_types
    local limit = max_actions or AGENT_CONFIG.memory.defaults.max_actions

    local type_lookup = {}
    for _, msg_type in ipairs(types) do
        type_lookup[msg_type] = true
    end

    for i = #messages, 1, -1 do
        if #actions >= limit then
            break
        end

        local message = messages[i]
        if message.role and type_lookup[message.role] then
            if message.role == prompt.ROLE.USER and message.content and message.content[1] then
                table.insert(actions, 1, "user: " .. message.content[1].text)
            elseif message.role == prompt.ROLE.ASSISTANT and message.content and message.content[1] then
                table.insert(actions, 1, "assistant: " .. message.content[1].text)
            elseif message.role == prompt.ROLE.FUNCTION_RESULT and message.name then
                local content = message.content and message.content[1] and message.content[1].text or "nil"
                table.insert(actions, 1, "tool: " .. message.name .. " -> " .. content)
            elseif message.role == prompt.ROLE.DEVELOPER and message.content and message.content[1] then
                if not (message.metadata and message.metadata.memory_ids) then
                    local content = message.content[1].text
                    table.insert(actions, 1, "system: " .. content)
                end
            end
        end
    end

    return actions
end

local function should_recall_memory(messages, options, runtime_options)
    if runtime_options and runtime_options.disable_memory_recall then
        return false
    end

    if not (options.enabled or AGENT_CONFIG.memory.defaults.enabled) then
        return false
    end

    local min_length = options.min_conversation_length or AGENT_CONFIG.memory.defaults.min_conversation_length
    if #messages < min_length then
        return false
    end

    local cooldown = options.recall_cooldown or AGENT_CONFIG.memory.defaults.recall_cooldown
    local messages_since_recall = 0

    for i = #messages, 1, -1 do
        local message = messages[i]
        if message.metadata and message.metadata.memory_ids then
            break
        end
        messages_since_recall = messages_since_recall + 1
    end

    return messages_since_recall >= cooldown
end

local function get_memory_options(memory_contract)
    local options = {}

    for key, value in pairs(AGENT_CONFIG.memory.defaults) do
        options[key] = value
    end

    if memory_contract and memory_contract.options then
        for key, value in pairs(memory_contract.options) do
            options[key] = value
        end
    end

    return options
end

local function get_memory_contract(self, runtime_context)
    if not self.memory_contract or not self.memory_contract.implementation_id then
        return nil, "No memory contract configured for this agent"
    end

    local contract_module = get_contract()

    local memory_contract_def, err = contract_module.get(AGENT_CONFIG.memory.contract_id)
    if err then
        return nil, "Failed to get memory contract: " .. tostring(err)
    end

    local merged_context = {}
    if self.memory_contract.context then
        for key, value in pairs(self.memory_contract.context) do
            merged_context[key] = value
        end
    end

    if runtime_context then
        for key, value in pairs(runtime_context) do
            merged_context[key] = value
        end
    end

    merged_context.agent_id = self.id

    local memory_instance, err = memory_contract_def:open(self.memory_contract.implementation_id, merged_context)
    if err then
        return nil, "Failed to open memory implementation: " .. tostring(err)
    end

    return memory_instance
end

local function perform_memory_recall(self, prompt_builder, runtime_options)
    if not self.memory_contract or not self.memory_contract.implementation_id then
        return nil, nil
    end

    if runtime_options and runtime_options.disable_memory_recall then
        return nil, nil
    end

    local messages = prompt_builder:get_messages()
    local options = get_memory_options(self.memory_contract)

    if not should_recall_memory(messages, options, runtime_options) then
        return nil, nil
    end

    local context = runtime_options and runtime_options.context or {}
    local memory_contract, err = get_memory_contract(self, context)
    if err then
        return nil, nil
    end

    local prompt_memory_ids = extract_memory_ids_from_messages(messages, options.scan_limit)
    local recent_actions = extract_recent_actions(messages, options.max_actions, options.message_types)

    local all_previous_memory_ids = table.create(#prompt_memory_ids + 10, 0)
    for _, id in ipairs(prompt_memory_ids) do
        table.insert(all_previous_memory_ids, id)
    end

    if runtime_options and runtime_options.previous_memory_ids then
        for _, id in ipairs(runtime_options.previous_memory_ids) do
            table.insert(all_previous_memory_ids, id)
        end
    end

    local recall_result, err = memory_contract:recall({
        recent_actions = recent_actions,
        previous_memories = all_previous_memory_ids,
        constraints = {
            max_items = options.max_items,
            max_length = options.max_length
        }
    })

    if err or not recall_result or not recall_result.memories or #recall_result.memories == 0 then
        return nil, nil
    end

    local memory_parts = table.create(#recall_result.memories, 0)
    local memory_ids = table.create(#recall_result.memories, 0)

    for _, memory in ipairs(recall_result.memories) do
        table.insert(memory_parts, "- " .. memory.content)
        table.insert(memory_ids, memory.id)
    end

    local memory_text = table.concat(memory_parts, "\n")

    return memory_text, memory_ids
end

local function extract_tool_schemas_for_llm(tools)
    -- Count tools with schemas first for proper sizing
    local schema_count = 0
    for _, tool_info in pairs(tools) do
        if tool_info.schema then
            schema_count = schema_count + 1
        end
    end

    local tool_schemas = table.create(schema_count, 0)

    -- Get sorted canonical names for consistent ordering
    local names = table.create(schema_count, 0)
    for canonical_name, tool_info in pairs(tools) do
        if tool_info.schema then
            table.insert(names, canonical_name)
        end
    end
    table.sort(names)

    -- Process in sorted order
    for _, canonical_name in ipairs(names) do
        local tool_info = tools[canonical_name]
        table.insert(tool_schemas, {
            name = canonical_name,
            description = tool_info.description,
            schema = tool_info.schema,
            registry_id = tool_info.registry_id,
            meta = tool_info.meta or {}
        })
    end

    return tool_schemas
end

local function has_tools_with_schemas(tools)
    for _, tool_info in pairs(tools) do
        if tool_info.schema then
            return true
        end
    end
    return false
end

---@param compiled_spec CompiledAgentSpec
---@return AgentRunner|nil runner, string|nil error
function agent.new(compiled_spec)
    if not compiled_spec then
        return nil, "Compiled spec is required"
    end

    ---@type AgentRunner
    local runner = {
        id = compiled_spec.id,
        name = compiled_spec.name,
        description = compiled_spec.description,
        model = compiled_spec.model or AGENT_CONFIG.defaults.model,
        max_tokens = compiled_spec.max_tokens or AGENT_CONFIG.defaults.max_tokens,
        temperature = compiled_spec.temperature or AGENT_CONFIG.defaults.temperature,
        thinking_effort = compiled_spec.thinking_effort or AGENT_CONFIG.defaults.thinking_effort,
        tools = compiled_spec.tools or {},
        memory = compiled_spec.memory or {},
        memory_contract = compiled_spec.memory_contract,
        system_prompt = compiled_spec.prompt or "",
        prompt_funcs = compiled_spec.prompt_funcs or {},
        step_funcs = compiled_spec.step_funcs or {},
        total_tokens = {
            prompt = 0,
            completion = 0,
            thinking = 0,
            total = 0
        }
    }

    if runner.memory and #runner.memory > 0 then
        runner.system_prompt = runner.system_prompt .. "\n\n## Your memory contains:"
        for _, memory_item in ipairs(runner.memory) do
            runner.system_prompt = runner.system_prompt .. "\n- " .. memory_item
        end
    end

    runner.system_message = {
        role = prompt.ROLE.SYSTEM,
        content = runner.system_prompt
    }

    setmetatable(runner, { __index = agent })
    return runner
end

---@param self AgentRunner
---@param prompt_builder PromptBuilder Prompt builder with conversation
---@param runtime_options? table Optional runtime options including stream_target and context
---@return table|nil result, string|nil error
function agent:step(prompt_builder, runtime_options)
    runtime_options = runtime_options or {}
    local llm_instance = get_llm()

    local dynamic_prompt = execute_prompt_functions(self, runtime_options.context)
    local complete_system_prompt = self.system_prompt
    if dynamic_prompt and dynamic_prompt ~= "" then
        complete_system_prompt = complete_system_prompt .. "\n\n" .. dynamic_prompt
    end

    local memory_text, memory_ids = perform_memory_recall(self, prompt_builder, runtime_options)
    local memory_prompt = nil

    if memory_text and memory_ids then
        local formatted_memory = string.format(AGENT_CONFIG.memory.recall_prompt, memory_text)
        memory_prompt = {
            role = prompt.ROLE.DEVELOPER,
            content = { prompt.text(formatted_memory) },
            metadata = { memory_ids = memory_ids }
        }
    end

    local options = {
        model = self.model,
        max_tokens = self.max_tokens,
        temperature = self.temperature
    }

    if has_tools_with_schemas(self.tools) then
        options.tools = extract_tool_schemas_for_llm(self.tools)
    end

    if self.thinking_effort and self.thinking_effort > 0 then
        options.thinking_effort = self.thinking_effort
    end

    if runtime_options.tool_call ~= nil then
        options.tool_choice = runtime_options.tool_call
    end

    -- Get ongoing conversation messages (no clone needed)
    local conversation_messages = prompt_builder:get_messages()
    local final_message_count = 2 + #conversation_messages + (memory_prompt and 1 or 0)
    local final_messages = table.create(final_message_count, 0)

    -- Prepend system message with cache marker
    local system_message = {
        role = prompt.ROLE.SYSTEM,
        content = { prompt.text(complete_system_prompt) }
    }
    table.insert(final_messages, system_message)
    table.insert(final_messages, { role = prompt.ROLE.CACHE_MARKER, marker_id = self.id })

    -- Add ongoing conversation
    for _, msg in ipairs(conversation_messages) do
        table.insert(final_messages, msg)
    end

    -- Append memory recall after conversation
    if memory_prompt then
        table.insert(final_messages, memory_prompt)
    end

    if runtime_options.stream_target then
        options.stream = runtime_options.stream_target
    end

    --if has_tools_with_schemas(self.tools) then
    --    options.tools = extract_tool_schemas_for_llm(self.tools)
    --
    --    -- DEBUG: Print tools being sent to LLM
    --    print("=== TOOLS SENT TO LLM ===")
    --    for i, tool in ipairs(options.tools) do
    --        print(string.format("Tool %d: %s", i, tool.name))
    --        print("  Description:", tool.description or "nil")
    --        print("  Registry ID:", tool.registry_id or "nil")
    --        if tool.meta then
    --            local meta_keys = {}
    --            for k, _ in pairs(tool.meta) do
    --                table.insert(meta_keys, k)
    --            end
    --            print("  Meta keys:", table.concat(meta_keys, ", "))
    --            print("  Meta content:", json.encode(tool.meta))
    --        else
    --            print("  Meta: nil")
    --        end
    --        print("  Schema present:", tool.schema and "yes" or "no")
    --        print("---")
    --    end
    --    print("=== END TOOLS DEBUG ===")
    --end


    local result, err = llm_instance.generate(final_messages, options)
    if err then
        return nil, err
    end

    local response = {
        result = result.content or result.result,
        tokens = result.tokens,
        finish_reason = result.finish_reason,
        metadata = result.metadata
    }

    if memory_ids then
        response.memory_recall = {
            memory_ids = memory_ids,
            count = #memory_ids
        }
    end

    if memory_prompt then
        response.memory_prompt = memory_prompt
    end

    if result.tool_calls then
        for _, tool_call in ipairs(result.tool_calls) do
            local tool_info = self.tools[tool_call.name]
            if tool_info and tool_info.context then
                tool_call.context = tool_info.context
                tool_call.registry_id = tool_info.registry_id
            end
        end
        response.tool_calls = result.tool_calls
    end

    if result.tokens then
        self.total_tokens.prompt = self.total_tokens.prompt + (result.tokens.prompt_tokens or 0)
        self.total_tokens.completion = self.total_tokens.completion + (result.tokens.completion_tokens or 0)
        self.total_tokens.thinking = self.total_tokens.thinking + (result.tokens.thinking_tokens or 0)
        self.total_tokens.total = self.total_tokens.prompt + self.total_tokens.completion + self.total_tokens.thinking
    end

    if response.tool_calls and #response.tool_calls > 0 then
        local delegate_calls = {}
        local remaining_tool_calls = {}

        for _, tool_call in ipairs(response.tool_calls) do
            local tool_info = self.tools[tool_call.name]
            if tool_info and tool_info.agent_id then
                local delegate_call = {
                    id = tool_call.id,
                    name = tool_call.name,
                    arguments = tool_call.arguments,
                    registry_id = tool_call.registry_id,
                    context = tool_call.context,
                    agent_id = tool_info.agent_id
                }

                local agent_base_context = runtime_options.context or {}
                local merged_context = merge_agent_and_context(agent_base_context, tool_info.context)

                merged_context.from_agent_id = self.id
                merged_context.to_agent_id = tool_info.agent_id

                delegate_call.context = merged_context

                table.insert(delegate_calls, delegate_call)
            else
                table.insert(remaining_tool_calls, tool_call)
            end
        end

        if #delegate_calls > 0 then
            response.delegate_calls = delegate_calls
        end

        response.tool_calls = #remaining_tool_calls > 0 and remaining_tool_calls or nil
    end

    return response
end

---@param self AgentRunner
---@return table stats
function agent:get_stats()
    return {
        id = self.id,
        name = self.name,
        total_tokens = self.total_tokens
    }
end

return agent
