local prompt = require("prompt")
local llm = require("llm")

-- Main module
local agent = {}

-- Constants
agent.DEFAULT_MODEL = ""
agent.DEFAULT_MAX_TOKENS = 4096
agent.DEFAULT_TEMPERATURE = 0.7
agent.DEFAULT_THINKING_EFFORT = 0

-- For dependency injection in testing
agent._llm = nil
agent._prompt = nil

-- Internal: Get LLM instance - use injected llm or require it
local function get_llm()
    return agent._llm or llm
end

-- Internal: Get prompt module - use injected prompt or require it
local function get_prompt()
    return agent._prompt or prompt
end

-- Constructor: Create a new agent runner from an agent spec
function agent.new(agent_spec)
    if not agent_spec then
        return nil, "Agent spec is required"
    end

    local runner = {
        -- Agent metadata
        id = agent_spec.id,
        name = agent_spec.name,
        description = agent_spec.description,

        -- LLM configuration
        model = agent_spec.model or agent.DEFAULT_MODEL,
        max_tokens = agent_spec.max_tokens or agent.DEFAULT_MAX_TOKENS,
        temperature = agent_spec.temperature or agent.DEFAULT_TEMPERATURE,
        thinking_effort = agent_spec.thinking_effort or agent.DEFAULT_THINKING_EFFORT,

        -- Agent capabilities
        tools = agent_spec.tools or {},
        memory = agent_spec.memory or {},
        delegates = agent_spec.delegates or {},

        -- Internal state
        base_prompt = agent_spec.prompt or "",
        system_message = nil, -- Will store the built system message
        tool_ids = {},
        tool_schemas = {},    -- Custom tool schemas
        delegate_tools = {},  -- Handout tool schemas
        delegate_map = {},    -- Maps tool IDs to target agent IDs
        total_tokens = {
            prompt = 0,
            completion = 0,
            thinking = 0,
            total = 0
        },

        -- Conversation state
        messages_handled = 0
    }

    -- Register standard tools (for passing tool_ids to LLM)
    if type(runner.tools) == "table" then
        for _, tool_id in ipairs(runner.tools) do
            table.insert(runner.tool_ids, tool_id)
        end
    end

    -- Add metatable for method access
    setmetatable(runner, { __index = agent })

    -- Generate delegate tools with schemas
    runner:_generate_delegate_tools()

    -- Build the system message
    runner.system_message = runner:_build_system_message()

    return runner
end

-- Generate delegate tools with schemas
function agent:_generate_delegate_tools()
    if not self.delegates or #self.delegates == 0 then return end

    for _, delegate in ipairs(self.delegates) do
        -- Get the tool name from delegate configuration (required)
        local tool_name = delegate.name
        if not tool_name or #tool_name == 0 then
            error("Handout name is required for agent " .. delegate.id)
        end

        -- Create description using the rule
        local description = "Forward the request to " .. (delegate.rule or "when appropriate")

        -- Create schema for this delegate
        local schema = {
            name = tool_name,
            description = description .. ", this is exit tool, you can not call anything else with it.",
            schema = {
                type = "object",
                properties = {
                    message = {
                        type = "string",
                        description = "The message to forward to the agent"
                    }
                },
                required = { "message" }
            }
        }

        -- Store the tool schema
        self.delegate_tools[tool_name] = schema

        -- Map this tool ID to the target agent ID
        self.delegate_map[tool_name] = delegate.id
    end
end

-- Build the system message from base prompt and agent metadata
-- Returns a system message instead of using a prompt builder
function agent:_build_system_message()
    local system_prompt = self.base_prompt

    -- Add agent identity
    system_prompt = system_prompt .. "\n\nYou are " .. self.name
    if self.description and #self.description > 0 then
        system_prompt = system_prompt .. ", " .. self.description
    end

    -- Add agent memory context
    if self.memory and #self.memory > 0 then
        system_prompt = system_prompt .. "\n\n## Your memory contains:"
        for _, memory_item in ipairs(self.memory) do
            system_prompt = system_prompt .. "\n- " .. memory_item
        end
    end

    -- Add information about available delegates
    if self.delegates and #self.delegates > 0 then
        system_prompt = system_prompt .. "\n\n## You can delegate tasks to these specialized agents:"
        for _, delegate in ipairs(self.delegates) do
            -- Get display name from the ID's last part if possible
            local display_name = delegate.id:match("[^:]+$") or delegate.name
            display_name = display_name:gsub("_", " "):gsub("%-", " ")
            display_name = display_name:sub(1, 1):upper() .. display_name:sub(2) -- Capitalize first letter

            -- Use rule for the description
            local description = delegate.rule or ""

            system_prompt = system_prompt .. "\n- " .. display_name .. ": " ..
                description .. " (use tool " .. delegate.name .. ")"
        end
    end

    -- Return the system message
    return {
        role = "system",
        content = system_prompt
    }
end

-- Execute the agent to get the next action
-- Modified to accept runtime options including tool_call
function agent:step(prompt_builder_slice, stream_target, runtime_options)
    -- Runtime options override agent defaults
    runtime_options = runtime_options or {}

    -- Get LLM instance
    local llm_instance = get_llm()

    -- Prepare LLM options
    local options = {
        model = self.model,
        max_tokens = self.max_tokens,
        temperature = self.temperature
    }

    -- Add standard tools as tool_ids
    if #self.tool_ids > 0 then
        options.tool_ids = self.tool_ids
    end

    if self.thinking_effort and self.thinking_effort > 0 then
        options.thinking_effort = self.thinking_effort
    end

    -- Add tool_call from runtime options if provided
    if runtime_options.tool_call ~= nil then
        options.tool_call = runtime_options.tool_call
    end

    -- Add custom tool schemas
    if next(self.tool_schemas) then
        options.tool_schemas = options.tool_schemas or {}
        for tool_id, schema in pairs(self.tool_schemas) do
            options.tool_schemas[tool_id] = schema
        end
    end

    -- Add delegate tools as tool_schemas
    if next(self.delegate_tools) then
        options.tool_schemas = options.tool_schemas or {}
        for tool_id, schema in pairs(self.delegate_tools) do
            options.tool_schemas[tool_id] = schema
        end
    end

    -- Create an array of final messages to send to LLM
    local final_messages = {}

    -- Always have system message
    table.insert(final_messages, self.system_message)
    if #self.tool_schemas == 0 then
        -- when no dynamic tools provided we can cache the system message
        table.insert(final_messages, { role = "cache_marker", marker_id = self.id })
    end

    for _, msg in ipairs(prompt_builder_slice:get_messages()) do
        table.insert(final_messages, msg)
    end

    if stream_target then
        options.stream = stream_target
    end

    -- Execute LLM call
    local result, err = llm_instance.generate(final_messages, options)

    if err then
        return nil, err
    end

    -- Create the response object with all necessary fields
    local response = {
        -- Text response priority: content > result
        result = result.content or result.result,
        tokens = result.tokens,
        finish_reason = result.finish_reason,
        meta = result.meta
    }

    -- Copy tool_calls if present
    if result.tool_calls then
        response.tool_calls = result.tool_calls
    end

    -- Update token usage statistics
    if result.tokens then
        self.total_tokens.prompt = self.total_tokens.prompt + (result.tokens.prompt_tokens or 0)
        self.total_tokens.completion = self.total_tokens.completion + (result.tokens.completion_tokens or 0)
        self.total_tokens.thinking = self.total_tokens.thinking + (result.tokens.thinking_tokens or 0)
        self.total_tokens.total = self.total_tokens.prompt + self.total_tokens.completion + self.total_tokens.thinking
    end

    -- Process delegate tool calls
    if response.tool_calls and #response.tool_calls > 0 then
        for _, tool_call in ipairs(response.tool_calls) do
            -- Check if this tool call is for a delegate
            if self.delegate_map[tool_call.name] then
                -- Mark that this is a delegate call
                response.function_name = tool_call.name
                response.delegate_target = self.delegate_map[tool_call.name]
                response.delegate_message = tool_call.arguments.message
                response.tool_calls = nil -- delegate intercept tools calls
                break
            end
        end
    end

    return response
end

-- Register a custom tool schema
function agent:register_tool(tool_name, tool_schema)
    if not tool_name then
        return nil, "Tool name is required"
    end

    if not tool_schema then
        return nil, "Tool schema is required"
    end

    -- Add to tool schemas only
    self.tool_schemas[tool_name] = tool_schema

    return self
end

-- Get conversation statistics
function agent:get_stats()
    return {
        id = self.id,
        name = self.name,
        messages_handled = self.messages_handled,
        total_tokens = self.total_tokens
    }
end

return agent
