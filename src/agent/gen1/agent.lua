local prompt = require("prompt")
local llm = require("llm")
local contract = require("contract")

---@class AgentDelegate
---@field id string Target agent ID to delegate to
---@field name string Tool name for delegation
---@field rule string Rule describing when to delegate

---@class MemoryContractConfig
---@field implementation_id string Memory implementation/binding ID
---@field context_values? table<string, any> Context values for memory contract

---@class TokenUsage
---@field prompt number Prompt tokens used
---@field completion number Completion tokens used
---@field thinking number Thinking tokens used
---@field total number Total tokens used

---@class AgentSpec
---@field id string Agent unique identifier
---@field name string Agent display name
---@field description string Agent description
---@field model? string LLM model identifier
---@field max_tokens? number Maximum completion tokens
---@field temperature? number Sampling temperature (0-1)
---@field thinking_effort? number Thinking effort (0-100)
---@field tools? string[] Array of tool IDs
---@field memory? string[] Array of memory items
---@field delegates? AgentDelegate[] Array of delegate configurations
---@field prompt? string Base system prompt
---@field memory_contract? MemoryContractConfig Memory contract configuration

---@class AgentRunner
---@field id string Agent ID
---@field name string Agent name
---@field description string Agent description
---@field model string LLM model
---@field max_tokens number Maximum tokens
---@field temperature number Temperature
---@field thinking_effort number Thinking effort
---@field tools string[] Tool IDs
---@field memory string[] Memory items
---@field delegates AgentDelegate[] Delegate configurations
---@field memory_contract? MemoryContractConfig Memory contract configuration
---@field base_prompt string Base prompt
---@field system_message table System message
---@field tool_ids string[] Tool IDs for LLM
---@field tool_schemas table<string, table> Custom tool schemas
---@field delegate_tools table<string, table> Delegate tool schemas
---@field delegate_map table<string, string> Maps tool IDs to agent IDs
---@field total_tokens TokenUsage Token usage statistics
---@field messages_handled number Messages processed

-- Main module
local agent = {}

-- Constants
agent.DEFAULT_MODEL = ""
agent.DEFAULT_MAX_TOKENS = 4096
agent.DEFAULT_TEMPERATURE = 0.7
agent.DEFAULT_THINKING_EFFORT = 0
agent.MEMORY_CONTRACT_ID = "wippy.agent.memory:contract"

-- For dependency injection in testing
agent._llm = nil
agent._prompt = nil
agent._contract = nil

-- Internal: Get LLM instance - use injected llm or require it
---@return table
local function get_llm()
    return agent._llm or llm
end

-- Internal: Get prompt module - use injected prompt or require it
---@return table
local function get_prompt()
    return agent._prompt or prompt
end

-- Internal: Get contract module - use injected contract or require it
---@return table
local function get_contract()
    return agent._contract or contract
end

-- Internal: Get memory contract instance with merged context
---@param self AgentRunner
---@param runtime_context? table<string, any> Runtime context values
---@return table|nil contract_instance, string|nil error
local function get_memory_contract(self, runtime_context)
    if not self.memory_contract or not self.memory_contract.implementation_id then
        return nil, "No memory contract configured for this agent"
    end

    local contract_module = get_contract()

    -- Get the memory contract definition
    local memory_contract_def, err = contract_module.get(agent.MEMORY_CONTRACT_ID)
    if err then
        return nil, "Failed to get memory contract: " .. err
    end

    -- Start with configured context values
    local merged_context = {}
    if self.memory_contract.context_values then
        for key, value in pairs(self.memory_contract.context_values) do
            merged_context[key] = value
        end
    end

    -- Add runtime context (overrides configured values)
    if runtime_context then
        for key, value in pairs(runtime_context) do
            merged_context[key] = value
        end
    end

    -- Always add agent_id
    merged_context.agent_id = self.id

    -- Open the specific implementation with merged context
    local memory_instance, err = memory_contract_def:open(self.memory_contract.implementation_id, merged_context)
    if err then
        return nil, "Failed to open memory implementation: " .. err
    end

    return memory_instance
end

-- Constructor: Create a new agent runner from an agent spec
---@param agent_spec AgentSpec
---@return AgentRunner|nil runner, string|nil error
function agent.new(agent_spec)
    if not agent_spec then
        return nil, "Agent spec is required"
    end

    ---@type AgentRunner
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
        memory_contract = agent_spec.memory_contract,

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
---@param self AgentRunner
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
---@param self AgentRunner
---@return table system_message
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
---@param self AgentRunner
---@param prompt_builder_slice table Prompt builder slice with conversation
---@param stream_target? table Optional stream target
---@param runtime_options? table Optional runtime options
---@return table|nil result, string|nil error
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
---@param self AgentRunner
---@param tool_name string Tool name
---@param tool_schema table Tool schema definition
---@return AgentRunner|nil self, string|nil error
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

-- Check if agent has memory contract configured
---@param self AgentRunner
---@return boolean
function agent:has_memory_contract()
    if not self.memory_contract then
        return false
    end
    return self.memory_contract.implementation_id ~= nil
end

-- Get memory contract instance with merged context
---@param self AgentRunner
---@param runtime_context? table<string, any> Runtime context values
---@return table|nil contract_instance, string|nil error
function agent:get_memory_contract(runtime_context)
    return get_memory_contract(self, runtime_context)
end

-- Get conversation statistics
---@param self AgentRunner
---@return table stats
function agent:get_stats()
    return {
        id = self.id,
        name = self.name,
        messages_handled = self.messages_handled,
        total_tokens = self.total_tokens
    }
end

return agent