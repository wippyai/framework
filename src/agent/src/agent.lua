local prompt = require("prompt")
local llm = require("llm")
local contract = require("contract")
local funcs = require("funcs")
local output = require("output")
local hash = require("hash")
local canonical = require("canonical")

type UnifiedTool = {
    name: string,
    description: string,
    schema: table,
    registry_id: string?,
    context: table,
    agent_id: string?,
    meta: table?,
}

type CompiledAgentSpec = {
    id: string,
    name: string,
    description: string,
    model: string?,
    max_tokens: number?,
    temperature: number?,
    thinking_effort: number?,
    prompt: string,
    tools: {[string]: UnifiedTool},
    memory: {string},
    memory_contract: table?,
    agent_options: table?,
    prompt_funcs: {table},
    step_funcs: {table},
    tool_wrappers: {table},
    bindings: {[string]: {table}}?,
}

type TokenUsage = {
    prompt: number,
    completion: number,
    thinking: number,
    total: number,
}

type AgentRunner = {
    id: string,
    name: string,
    description: string,
    model: string,
    max_tokens: number,
    temperature: number?,
    thinking_effort: number,
    tools: {[string]: UnifiedTool},
    memory: {string},
    memory_contract: table?,
    agent_options: table,
    system_prompt: string,
    system_message: table,
    prompt_funcs: {table},
    step_funcs: {table},
    tool_wrappers: {table},
    bindings: {[string]: {table}},
    total_tokens: TokenUsage,
}

local agent = {}

local AGENT_CONFIG = {
    defaults = {
        model = "",
        max_tokens = 512,
        thinking_effort = 0
    },
    memory = {
        contract_id = "wippy.agent:memory",
        recall_prompt = "Background context from memory (not a user message or a new request). "
            .. "Use it to support the current user request; it does not replace that request.\n\n%s",
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

local function get_llm(): any
    return agent._llm or llm
end

local function get_prompt(): any
    return agent._prompt or prompt
end

local function get_contract(): any
    return agent._contract or contract
end

local function get_funcs(): any
    return agent._funcs or funcs
end

local function merge_agent_and_context(agent_ctx: any, delegate_ctx: any): any
    local merged = {}
    for k, v in pairs(agent_ctx or {}) do
        merged[k] = v
    end
    for k, v in pairs(delegate_ctx or {}) do
        merged[k] = v
    end
    return merged
end

-- A prompt function's text is part of the system prompt, so a failure fails
-- the step: sending the prompt without it would change the prefix.
local function execute_prompt_functions(self: any, runtime_context: any): (string?, any)
    if not self.prompt_funcs or #self.prompt_funcs == 0 then
        return "", nil
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
        local prompt_text, err = executor:with_context(merged_context):call(tostring(prompt_func.func_id))
        if err then
            return nil, errors.new({
                message = "prompt function " .. tostring(prompt_func.func_id) .. " failed: " .. tostring(err),
                kind = err:kind(),
                retryable = err:retryable(),
                details = err:details(),
            })
        end

        if prompt_text and prompt_text ~= "" then
            table.insert(prompt_parts, prompt_text)
        end
    end

    return table.concat(prompt_parts, "\n\n"), nil
end

local function extract_memory_ids_from_messages(messages: any, scan_limit: any): any
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

local function part_text(message: any): string
    local part = message and message.content and message.content[1]
    if not part then
        return "nil"
    end
    if type(part.text) == "string" then
        return part.text
    end
    if part.type == "image" then
        return "[image]"
    end
    if part.type == "document" then
        return "[document]"
    end
    return "[non-text content]"
end

local function extract_recent_actions(messages: any, max_actions: any, message_types: any): any
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
                table.insert(actions, 1, "user: " .. part_text(message))
            elseif message.role == prompt.ROLE.ASSISTANT and message.content and message.content[1] then
                table.insert(actions, 1, "assistant: " .. part_text(message))
            elseif message.role == prompt.ROLE.FUNCTION_RESULT and message.name then
                table.insert(actions, 1, "tool: " .. message.name .. " -> " .. part_text(message))
            elseif message.role == prompt.ROLE.DEVELOPER and message.content and message.content[1] then
                if not (message.metadata and message.metadata.memory_ids) then
                    table.insert(actions, 1, "system: " .. part_text(message))
                end
            end
        end
    end

    return actions
end

local function should_recall_memory(messages: any, options: any, runtime_options: table?): boolean
    if runtime_options and runtime_options.disable_memory_recall then
        return false
    end

    if options.enabled == false then
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

local function get_memory_options(memory_contract: any): any
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

local function get_memory_contract(self: any, runtime_context: any): (any?, string?)
    if not self.memory_contract or not self.memory_contract.implementation_id then
        return nil, "No memory contract configured for this agent"
    end

    local contract_module = get_contract()

    local memory_contract_def, err = contract_module.get(AGENT_CONFIG.memory.contract_id)
    if err or not memory_contract_def then
        return nil, "Failed to get memory contract: " .. tostring(err or "not found")
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

    local memory_instance, open_err = memory_contract_def:open(tostring(self.memory_contract.implementation_id), merged_context)
    if open_err or not memory_instance then
        return nil, "Failed to open memory implementation: " .. tostring(open_err or "no instance")
    end

    return memory_instance
end

type MemoryRecall = {
    text: string,
    ids: {string},
}

-- Returns nil, nil when recall is skipped or finds nothing; an error means the
-- configured provider could not be consulted or answered malformed data.
local function perform_memory_recall(self: any, prompt_builder: any, runtime_options: any): (MemoryRecall?, string?)
    if not self.memory_contract or not self.memory_contract.implementation_id then
        return nil, nil
    end

    if runtime_options and runtime_options.disable_memory_recall then
        return nil, nil
    end

    -- The recall note is sent at the conversation tail, so it is part of the
    -- prefix every later request replays. Only a host that persists the
    -- returned context notes at that position keeps the prefix stable.
    if not (runtime_options and runtime_options.persist_context_notes == true) then
        return nil, nil
    end

    local messages = prompt_builder:get_messages()
    local options = get_memory_options(self.memory_contract)

    if not should_recall_memory(messages, options, runtime_options) then
        return nil, nil
    end

    local ro = runtime_options :: any
    local context = ro and ro.context or {}
    local memory_contract, open_err = get_memory_contract(self, context)
    if open_err then
        return nil, open_err
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

    local recall_result, recall_err = memory_contract:recall({
        recent_actions = recent_actions,
        previous_memories = all_previous_memory_ids,
        constraints = {
            max_items = options.max_items,
            max_length = options.max_length
        }
    })

    if recall_err then
        return nil, "Memory recall failed: " .. tostring(recall_err)
    end
    if type(recall_result) ~= "table" then
        return nil, "Memory recall returned no result"
    end
    local memories = recall_result.memories
    if type(memories) ~= "table" then
        return nil, "Memory recall result has no memories list"
    end
    if #memories == 0 then
        return nil, nil
    end

    local memory_parts = table.create(#memories, 0)
    local memory_ids = table.create(#memories, 0)

    for index, memory in ipairs(memories) do
        if type(memory) ~= "table" or type(memory.id) ~= "string" or memory.id == ""
            or type(memory.content) ~= "string" then
            return nil, "Memory recall returned a malformed memory at index " .. tostring(index)
        end
        table.insert(memory_parts, "- " .. memory.content)
        table.insert(memory_ids, memory.id)
    end

    return { text = table.concat(memory_parts, "\n"), ids = memory_ids }, nil
end

local function extract_tool_schemas_for_llm(tools: any): {table}
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

local function has_tools_with_schemas(tools: any): boolean
    for _, tool_info in pairs(tools) do
        if tool_info.schema then
            return true
        end
    end
    return false
end

-- What providers bind cached prefixes and thinking blocks to, as drivers send
-- it: the system text (the compiled prompt plus conversation system messages,
-- which Claude and Bedrock hoist into the top-level system) and each tool's
-- name, description, schema and native definition. Registry ids and registry
-- metadata never reach the provider. The model is left out: providers drop
-- blocks a different model cannot read on their own.
local function prefix_projection(messages: {any}, tools: {any}?): table
    local system = {}
    for _, message in ipairs(messages) do
        if message.role == prompt.ROLE.SYSTEM and not prompt.is_positional_note(message) then
            if type(message.content) == "string" then
                table.insert(system, message.content)
            elseif type(message.content) == "table" then
                for _, part in ipairs(message.content) do
                    table.insert(system, part.type == "text" and part.text or part)
                end
            end
        end
    end
    local projected_tools = {}
    for _, tool in ipairs(tools or {}) do
        table.insert(projected_tools, {
            name = tool.name,
            description = tool.description,
            schema = tool.schema,
            native = type(tool.meta) == "table" and tool.meta.claude or nil,
        })
    end
    return { system = system, tools = projected_tools }
end

local function route_pin(current: any, metadata: any): any?
    if current ~= nil then
        return current
    end
    if type(metadata) ~= "table" or type(metadata.route) ~= "table" then
        return nil
    end
    local fallbacks = metadata.fallbacks
    if type(fallbacks) ~= "table" or #fallbacks == 0 then
        return nil
    end
    return {
        model = metadata.route.model,
        provider_id = metadata.route.provider_id,
        provider_model = metadata.route.provider_model
    }
end

function agent.new(compiled_spec: any): (any, string?)
    if not compiled_spec then
        return nil, "Compiled spec is required"
    end

    local runner = {
        id = compiled_spec.id,
        name = compiled_spec.name,
        description = compiled_spec.description,
        model = compiled_spec.model or AGENT_CONFIG.defaults.model,
        max_tokens = compiled_spec.max_tokens or AGENT_CONFIG.defaults.max_tokens,
        -- Left nil when the spec omits it: Claude 4.7+ and Opus/Sonnet 5 reject
        -- temperature, top_p and top_k outright, and a value the author never
        -- asked for is not ours to invent.
        temperature = compiled_spec.temperature,
        thinking_effort = compiled_spec.thinking_effort or AGENT_CONFIG.defaults.thinking_effort,
        tools = compiled_spec.tools or {},
        memory = compiled_spec.memory or {},
        memory_contract = compiled_spec.memory_contract,
        agent_options = compiled_spec.agent_options or {},
        system_prompt = compiled_spec.prompt or "",
        prompt_funcs = compiled_spec.prompt_funcs or {},
        step_funcs = compiled_spec.step_funcs or {},
        tool_wrappers = compiled_spec.tool_wrappers or {},
        bindings = compiled_spec.bindings or {},
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

function agent:step(prompt_builder: any, runtime_options: any): (table?, string?, table?)
    runtime_options = runtime_options or {}
    local llm_instance = get_llm()

    local dynamic_prompt, prompt_err = execute_prompt_functions(self, runtime_options.context)
    if prompt_err then
        return nil, prompt_err
    end
    local complete_system_prompt = self.system_prompt
    if dynamic_prompt and dynamic_prompt ~= "" then
        complete_system_prompt = complete_system_prompt .. "\n\n" .. dynamic_prompt
    end

    local recall, memory_recall_error = perform_memory_recall(self, prompt_builder, runtime_options)
    local memory_ids = recall and recall.ids
    local memory_prompt = nil

    if recall then
        local formatted_memory = string.format(tostring(AGENT_CONFIG.memory.recall_prompt), recall.text)
        memory_prompt = {
            role = prompt.ROLE.DEVELOPER,
            content = { prompt.text(formatted_memory) },
            metadata = { memory_ids = memory_ids, preserve_position = true }
        }
    end

    local options = {
        context_id = runtime_options.context_id,
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

    -- A caller that enforces tool use itself may let a forced tool_call be sent
    -- as "auto" to a model that cannot be forced (see the provider's model_profile).
    if runtime_options.tool_call_fallback ~= nil then
        options.tool_choice_fallback = runtime_options.tool_call_fallback
    end

    if runtime_options.route ~= nil then
        options.route = runtime_options.route
    end

    local system_message = {
        role = prompt.ROLE.SYSTEM,
        content = { prompt.text(complete_system_prompt) }
    }
    local function build_messages(conversation_messages)
        -- Get ongoing conversation messages (no clone needed)
        local final_message_count = 2 + #conversation_messages + (memory_prompt and 1 or 0)
        local final_messages = table.create(final_message_count, 0)

        -- Prepend system message with cache marker
        table.insert(final_messages, system_message)
        table.insert(final_messages, { role = prompt.ROLE.CACHE_MARKER, marker_id = self.id })

        -- Rolling cache breakpoint on the conversation tail. With only the system marker, every
        -- tool-loop turn re-bills the whole accumulated conversation at the full input price; a
        -- marker after the newest user/tool-result message lets the next turn read everything up to
        -- here from cache. Trailing developer and positional notes belong to the turn they follow
        -- (lifecycle messages, turn context), so the marker lands on that turn before them, as it
        -- precedes the memory recall. Providers cap breakpoints (Claude: 4); the mapper keeps
        -- system markers plus the most recent ones.
        local tail_index = #conversation_messages
        while tail_index > 0 and (conversation_messages[tail_index].role == prompt.ROLE.DEVELOPER
            or prompt.is_positional_note(conversation_messages[tail_index])) do
            tail_index = tail_index - 1
        end
        local tail = conversation_messages[tail_index]
        if not (tail and tail.role ~= prompt.ROLE.ASSISTANT and tail.role ~= prompt.ROLE.FUNCTION_CALL
            and tail.role ~= prompt.ROLE.CACHE_MARKER and tail.role ~= prompt.ROLE.SYSTEM) then
            tail_index = -1
        end

        -- Add ongoing conversation
        for index, msg in ipairs(conversation_messages) do
            table.insert(final_messages, msg)
            if index == tail_index then
                table.insert(final_messages, { role = prompt.ROLE.CACHE_MARKER, marker_id = "conversation_tail" })
            end
        end

        -- The recall note follows the conversation, where the host persists it
        if memory_prompt then
            table.insert(final_messages, memory_prompt)
        end

        return final_messages
    end
    local conversation = prompt_builder:get_messages()
    local projected = { system_message }
    for _, message in ipairs(conversation) do table.insert(projected, message) end
    local fingerprint, fingerprint_err = hash.sha256(canonical.encode(prefix_projection(projected, options.tools)))
    if fingerprint_err then
        return nil, output.errors.generate():kind(output.ERROR_TYPE.INVALID_REQUEST)
            :message("Prefix fingerprint failed: " .. tostring(fingerprint_err)):build()
    end

    -- Thinking blocks are bound to the prefix they were produced under. With
    -- drop_stale_thinking the request carries only blocks the host's rows mark
    -- with the current fingerprint (or that the host predicate accepts); the
    -- host's message tables keep theirs.
    local function current_thinking(messages: {any}): ({any}?, any)
        if not runtime_options.drop_stale_thinking then
            return messages, nil
        end
        local is_current = runtime_options.thinking_is_current
        local working = prompt.new(messages)
        local _, strip_err = working:drop_stale_thinking(function(msg)
            if is_current then
                return is_current(msg, fingerprint) == true
            end
            return msg.metadata.prefix_fingerprint == fingerprint
        end)
        if strip_err then
            return nil, output.errors.generate():kind(output.ERROR_TYPE.INVALID_REQUEST)
                :message(tostring(strip_err)):build()
        end
        return working:get_messages(), nil
    end

    local current, thinking_err = current_thinking(conversation)
    if not current then
        return nil, thinking_err
    end
    local final_messages = build_messages(current)
    if runtime_options.checkpoint then
        options.checkpoint = {
            token_threshold = runtime_options.checkpoint.token_threshold,
            compact = function(info)
                local replacement, compact_err = runtime_options.checkpoint.compact(info)
                if not replacement then return nil, compact_err end
                local retained, retained_err = current_thinking(replacement:get_messages())
                if not retained then return nil, retained_err end
                return build_messages(retained)
            end,
        }
    end

    if runtime_options.stream_target then
        options.stream = runtime_options.stream_target
    end

    -- Closing this channel cancels the in-flight model call.
    if runtime_options.cancel then
        options.cancel = runtime_options.cancel
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


    local context_notes = memory_prompt and { memory_prompt } or nil

    if runtime_options.stop_check and runtime_options.stop_check() then
        return { stopped = true, memory_recall_error = memory_recall_error }, nil
    end

    if runtime_options.checkpoint and not (llm_instance.ERROR_TYPE and llm_instance.ERROR_TYPE.CONTEXT_WINDOW) then
        return nil, output.errors.generate():kind(output.ERROR_TYPE.INVALID_REQUEST)
            :message("Checkpoint callbacks require an LLM with context admission support"):build()
    end

    local result, err, details = llm_instance.generate(final_messages, options)
    if err then
        if memory_recall_error then
            return { memory_recall_error = memory_recall_error }, err, details
        end
        return nil, err, details
    end

    if result.finish_reason == output.FINISH_REASON.CANCELLED then
        return {
            stopped = true,
            result = result.result,
            finish_reason = result.finish_reason,
            memory_recall_error = memory_recall_error,
            context_notes = context_notes,
            prefix_fingerprint = fingerprint
        }, nil
    end

    local response = {
        result = result.content or result.result,
        tokens = result.tokens,
        finish_reason = result.finish_reason,
        metadata = result.metadata,
        route_pin = route_pin(runtime_options.route, result.metadata),
        memory_recall_error = memory_recall_error,
        context_notes = context_notes,
        prefix_fingerprint = fingerprint
    }

    if output.detect_truncation(result) then
        response.truncated = true
        -- Incomplete calls remain non-executable. Hosts need the cause, however,
        -- to distinguish a tool retry from an empty no-tool response.
        response.truncation_reason = result.tool_calls and #result.tool_calls > 0
            and "tool_calls" or "empty_output"
        return response
    end

    if memory_ids then
        response.memory_recall = {
            memory_ids = memory_ids,
            count = #memory_ids
        }
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
            if tool_info and tool_info.agent_id and not tool_call.arguments_error then
                local delegate_call = {
                    id = tool_call.id,
                    name = tool_call.name,
                    arguments = tool_call.arguments,
                    registry_id = tool_call.registry_id,
                    context = tool_call.context,
                    provider_metadata = tool_call.provider_metadata,
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

function agent:get_stats(): table
    return {
        id = self.id,
        name = self.name,
        total_tokens = self.total_tokens
    }
end

return agent
