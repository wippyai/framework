local json = require("json")

-- Agent Selector - Selects best agent from class based on user prompt
local agent_selector = {}

-- Constants
local DEFAULT_LLM_MODEL = "gpt-4.1" -- todo: use class!
local ANALYSIS_PROMPT_TEMPLATE = [[
You are an expert agent selector. Your task is to analyze a user prompt and select the most appropriate agent from the available agents in class "%s".

User Prompt: "%s"

Available Agents:
%s

Select the agent that best matches the user's request based on:
1. The agent's comment/description
2. The agent's title and capabilities
3. How well it aligns with the user's intent

You MUST select exactly one agent. If no agent seems perfectly suitable, select the closest match and explain why.
]]

-- Allow for dependency injection in testing
agent_selector._agent_registry = nil
agent_selector._llm = nil

-- Get agent registry instance
local function get_agent_registry()
    return agent_selector._agent_registry or require("agent_registry")
end

-- Get LLM instance
local function get_llm()
    return agent_selector._llm or require("llm")
end

-- Main selection function - returns (result, error)
function agent_selector.select_agent(user_prompt, class_name)
    if not user_prompt or user_prompt == "" then
        return nil, "User prompt is required"
    end

    if not class_name or class_name == "" then
        return nil, "Class name is required"
    end

    local registry = get_agent_registry()
    local llm = get_llm()

    -- Get all agents in the specified class
    local agents = registry.list_by_class(class_name)

    if not agents or #agents == 0 then
        return nil, "No agents found for class: " .. class_name
    end

    -- Build agent information for LLM analysis
    local agent_info = {}
    for _, agent in ipairs(agents) do
        table.insert(agent_info, {
            id = agent.id,
            name = (agent.meta and agent.meta.name) or agent.id,
            title = (agent.meta and agent.meta.title) or "",
            comment = (agent.meta and agent.meta.comment) or "",
            tags = (agent.meta and agent.meta.tags) or {}
        })
    end

    -- Create analysis prompt using the template
    local analysis_prompt = string.format(
        ANALYSIS_PROMPT_TEMPLATE,
        class_name,
        user_prompt,
        json.encode(agent_info)
    )

    -- Define response schema
    local response_schema = {
        type = "object",
        properties = {
            success = {
                type = "boolean",
                description = "Whether agent selection was successful"
            },
            agent = {
                type = "string",
                description = "ID of the selected agent"
            },
            reason = {
                type = "string",
                description = "Explanation for why this agent was selected"
            }
        },
        required = { "success", "agent", "reason" },
        additionalProperties = false
    }

    -- Use LLM to make selection
    local response, err = llm.structured_output(response_schema, analysis_prompt, {
        model = DEFAULT_LLM_MODEL,
        temperature = 0
    })

    if err then
        return nil, "Failed to analyze agents: " .. err
    end

    if not response then
        return nil, "No response from LLM"
    end

    if not response.result then
        return nil, "Invalid response from LLM - missing result field"
    end

    local result = response.result

    if not result.agent then
        return nil, "LLM response missing agent field"
    end

    -- Validate the selected agent exists
    local selected_agent_found = false
    for _, agent in ipairs(agents) do
        if agent.id == result.agent then
            selected_agent_found = true
            break
        end
    end

    if not selected_agent_found then
        return nil, "LLM selected invalid agent ID: " .. tostring(result.agent)
    end

    -- Ensure success is true since we found a valid agent
    result.success = true

    return result, nil
end

-- Public API function that matches expected interface
function agent_selector.execute(input)
    if not input then
        return nil, "Input is required"
    end

    local user_prompt = input.user_prompt or input.prompt
    local class_name = input.class_name or input.class

    return agent_selector.select_agent(user_prompt, class_name)
end

return agent_selector
