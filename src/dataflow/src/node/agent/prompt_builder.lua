local prompt_lib = require("prompt")
local data_reader = require("data_reader")
local json = require("json")
local agent_consts = require("agent_consts")

local prompt_builder = {}
local mt = { __index = prompt_builder }

function prompt_builder.new(dataflow_id, node_id, node_path)
    if not dataflow_id then
        return nil, "dataflow_id is required"
    end
    if not node_id then
        return nil, "node_id is required"
    end
    if not node_path then
        return nil, "node_path is required"
    end

    local self = setmetatable({}, mt)
    self.dataflow_id = dataflow_id
    self.node_id = node_id
    self.node_path = node_path
    self._arena_config = nil
    self._initial_input = nil

    return self, nil
end

function prompt_builder:with_arena_config(arena_config)
    self._arena_config = arena_config
    return self
end

function prompt_builder:with_initial_input(initial_input)
    self._initial_input = initial_input
    return self
end

function prompt_builder:_parse_json_content(content, content_type)
    if content_type == "application/json" and type(content) == "string" then
        local parsed, err = json.decode(content)
        if err then
            return content, nil
        end
        return parsed, nil
    end
    return content, nil
end

function prompt_builder:_load_conversation_history()
    local reader = data_reader.with_dataflow(self.dataflow_id)
        :fetch_options({ replace_references = true })
        :with_nodes(self.node_id)
        :with_data_types(
            agent_consts.DATA_TYPE.AGENT_ACTION,
            agent_consts.DATA_TYPE.AGENT_OBSERVATION,
            agent_consts.DATA_TYPE.AGENT_MEMORY,
            agent_consts.DATA_TYPE.AGENT_DELEGATION
        )

    local history_items, err = reader:all()
    if err then
        return nil, "Failed to load conversation history: " .. err
    end

    if #history_items == 0 then
        return history_items, nil
    end

    table.sort(history_items, function(a, b)
        return (a.created_at or "") < (b.created_at or "")
    end)

    return history_items, nil
end

function prompt_builder:_format_action(action_item, builder)
    local content, err = self:_parse_json_content(action_item.content, action_item.content_type)
    if err then
        return "Failed to parse action content: " .. err
    end

    local metadata = action_item.metadata or {}
    local thinking_blocks = {}
    local text_content = ""
    local tool_calls = {}
    local delegate_calls = {}

    -- todo: totally wrong! should not be here! we must retain format? use new blocks
    if metadata.llm_meta and metadata.llm_meta.thinking then
        table.insert(thinking_blocks, metadata.llm_meta.thinking)
    end

    if type(content) == "table" then
        text_content = content.result or ""
        tool_calls = content.tool_calls or {}
        delegate_calls = content.delegate_calls or {}
    else
        text_content = content or ""
    end

    local content_parts = {}

    for _, thinking in ipairs(thinking_blocks) do
        table.insert(content_parts, thinking)
    end

    if text_content and text_content ~= "" then
        table.insert(content_parts, prompt_lib.text(text_content))
    end

    if #content_parts > 0 then
        builder:add_message(prompt_lib.ROLE.ASSISTANT, content_parts, nil, metadata.llm_meta)
    end

    -- Process regular tool calls (create function_call entries)
    if #tool_calls > 0 then
        for _, tool_call in ipairs(tool_calls) do
            local call_id = tool_call.id
            if not call_id then
                return "Tool call missing ID in action"
            end
            builder:add_function_call(tool_call.name, tool_call.arguments, call_id)
        end
    end

    -- Process delegate calls (create function_call entries too)
    -- Delegate calls also need to appear in conversation for proper LLM context
    if #delegate_calls > 0 then
        for _, delegate_call in ipairs(delegate_calls) do
            local call_id = delegate_call.id
            if not call_id then
                return "Delegate call missing ID in action"
            end

            -- Add delegate call as function_call to maintain conversation flow
            -- The delegation_handler will create child nodes and map results back
            builder:add_function_call(delegate_call.name, delegate_call.arguments, call_id)
        end
    end

    return nil
end

function prompt_builder:_format_observation(obs_item, builder)
    local content, err = self:_parse_json_content(obs_item.content, obs_item.content_type)
    if err then
        return "Failed to parse observation content: " .. err
    end

    local metadata = obs_item.metadata or {}

    -- Handle tool result observations (both regular tools and delegations)
    local tool_call_id = metadata.tool_call_id
    local tool_name = metadata.tool_name

    if tool_call_id and tool_name then
        -- Tool result observation - could be from regular tool or delegation
        local result_content
        if metadata.is_error then
            result_content = "Error: " .. tostring(content)
        elseif content == nil then
            result_content = "nil"
        elseif type(content) == "table" then
            local json_str, json_err = json.encode(content)
            if json_err then
                result_content = "[Failed to encode JSON result]"
            else
                result_content = json_str
            end
        else
            result_content = tostring(content)
        end

        builder:add_function_result(tool_name, result_content, tool_call_id)
    else
        -- System feedback or other observation - add as developer message
        local feedback_content = tostring(content)
        if feedback_content and feedback_content ~= "" then
            builder:add_developer(feedback_content)
        end
    end

    return nil
end

function prompt_builder:_format_memory(memory_item, builder)
    local content = memory_item.content
    if not content or content == "" then
        return nil
    end

    local metadata = memory_item.metadata or {}
    local message_meta = metadata.llm_meta or {}
    builder:add_developer(content, message_meta)
    return nil
end

function prompt_builder:_format_delegation(delegation_item, builder)
    local content = delegation_item.content
    if not content then
        return nil
    end

    local metadata = delegation_item.metadata or {}
    local tool_call_id = metadata.tool_call_id
    local tool_name = metadata.tool_name

    if tool_call_id and tool_name then
        -- Delegation result mapped back as function_result
        local result_content
        if type(content) == "table" then
            local json_str, json_err = json.encode(content)
            if json_err then
                result_content = "[Failed to encode delegation result]"
            else
                result_content = json_str
            end
        else
            result_content = tostring(content)
        end

        builder:add_function_result(tool_name, result_content, tool_call_id)
    else
        -- Standalone delegation result
        local delegation_text = "Delegation result: " .. tostring(content)
        builder:add_developer(delegation_text)
    end

    return nil
end

function prompt_builder:build_prompt(system_prompt, initial_input)
    if not system_prompt then
        return nil, "system_prompt is required"
    end

    local input_content = initial_input or self._initial_input

    local history_items, err = self:_load_conversation_history()
    if err then
        return nil, err
    end

    local builder = prompt_lib.new()

    builder:add_system(system_prompt)
    builder:add_cache_marker("system_complete")

    if self._arena_config then
        local tool_calling = self._arena_config.tool_calling

        if tool_calling == "none" then
            builder:add_system("Respond with text only, do not call any tools.")
        elseif tool_calling == "auto" then
            builder:add_system("Use appropriate tools when needed to advance the task. You may respond with text only if no tools are required.")
        elseif tool_calling == "any" then
            builder:add_system("You must use tools to complete tasks. Use the finish tool when you have completed the task.")
        end
    end

    if input_content then
        local input_text
        if type(input_content) == "table" then
            local json_str, json_err = json.encode(input_content)
            if json_err then
                input_text = "[Complex input data]"
            else
                input_text = json_str
            end
        else
            input_text = tostring(input_content)
        end
        builder:add_user(input_text)
    end

    for i, item in ipairs(history_items) do
        local process_err = nil

        if item.type == agent_consts.DATA_TYPE.AGENT_ACTION then
            process_err = self:_format_action(item, builder)
        elseif item.type == agent_consts.DATA_TYPE.AGENT_OBSERVATION then
            process_err = self:_format_observation(item, builder)
        elseif item.type == agent_consts.DATA_TYPE.AGENT_MEMORY then
            process_err = self:_format_memory(item, builder)
        elseif item.type == agent_consts.DATA_TYPE.AGENT_DELEGATION then
            process_err = self:_format_delegation(item, builder)
        end

        if process_err then
            return nil, process_err
        end
    end

    return builder, nil
end

return prompt_builder