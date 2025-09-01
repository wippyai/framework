# Agent Runner Library Specification and Usage Guide, Gen1

This document specifies the standard interface for the agent runner module in our system, as well as providing practical
examples of how to use the library.

## 1. Overview

The agent runner library provides a unified interface for running LLM agents with various capabilities. Key features
include:

- Creating agents from specifications
- Managing conversation history
- Executing LLM calls with appropriate context
- Tool and function calling support
- Delegation to other agents via delegates
- Tracking token usage and statistics
- Model thinking capabilities for complex reasoning

## 2. Basic Agent Creation and Usage

### Example: Creating and Running a Simple Agent

```lua
local agent_runner = require("agent_runner")
local agent_registry = require("agent_registry")

-- Get an agent specification from the registry
local agent_spec, err = agent_registry.get_by_id("app.shared:wiki-researcher")
if not agent_spec then
    print("Failed to load agent: " .. tostring(err))
    return
end

-- Create a new agent runner instance
local agent, err = agent_runner.new(agent_spec)
if not agent then
    print("Failed to create agent: " .. tostring(err))
    return
end

-- Add a user message to the conversation
agent:add_user_message("What can you tell me about the history of Lua programming language?")

-- Execute the agent to get a response
local result, err = agent:step()
if not result then
    print("Execution failed: " .. tostring(err))
    return
end

-- Print the response
print("Agent response: " .. result.result)

-- Add the assistant's response to conversation history
agent:add_assistant_message(result.result)

-- Print token usage
print("Total tokens used: " .. agent.total_tokens.total)
```

### Example: Continuing a Conversation

```lua
-- Continue the conversation with a follow-up question
agent:add_user_message("Who created it and when?")

-- Execute the agent again
local result, err = agent:step()
if result then
    print("Agent response: " .. result.result)
    
    -- Add the assistant's response to conversation history
    agent:add_assistant_message(result.result)
end

-- Get conversation statistics
local stats = agent:get_stats()
print("Messages handled: " .. stats.messages_handled)
print("Session duration: " .. stats.session_duration)
```

### Example: Using Thinking Effort for Complex Reasoning

```lua
local agent_runner = require("agent_runner")
local agent_registry = require("agent_registry")

-- Load an agent with thinking capabilities
local agent_spec, err = agent_registry.get_by_id("reasoning-assistant")
if not agent_spec then
    print("Failed to load agent: " .. tostring(err))
    return
end

-- Create agent runner instance with a model that supports thinking
local agent = agent_runner.new(agent_spec)

-- Add a complex reasoning question
agent:add_user_message("Explain the implications of the halting problem for artificial general intelligence")

-- Execute the agent with thinking capabilities
local result, err = agent:step()
if not result then
    print("Execution failed: " .. tostring(err))
    return
end

-- Print the response
print("Agent response: " .. result.result)

-- Show thinking token usage
print("Thinking tokens used: " .. (result.tokens.thinking_tokens or 0))
print("Total tokens used: " .. result.tokens.total_tokens)
```

## 3. Using Agents with Tools

Tools allow agents to access external data or perform operations.

### Example: Using Standard Tools

```lua
local agent_runner = require("agent_runner")
local agent_registry = require("agent_registry")

-- Load an agent with tool capabilities
local agent_spec, err = agent_registry.get_by_id("research-assistant")
if not agent_spec then
    print("Failed to load agent: " .. tostring(err))
    return
end

-- Create agent runner instance
local agent = agent_runner.new(agent_spec)

-- Add a user message that might require tools
agent:add_user_message("I need to search for recent papers on quantum computing")

-- Execute the agent (may result in tool calls)
local result = agent:step()

-- Process the result
print("Agent response: " .. result.result)

-- Check if there are tool calls in the response
if result.tool_calls and #result.tool_calls > 0 then
    -- Add the assistant's response to the conversation
    agent:add_assistant_message(result.result)
    
    for _, tool_call in ipairs(result.tool_calls) do
        print("Tool called: " .. tool_call.name)
        print("Arguments: " .. json.encode(tool_call.arguments))
        
        -- First add the function call to the conversation
        agent:add_function_call(
            tool_call.name,
            tool_call.arguments,
            tool_call.id
        )
        
        -- Handle the tool call (simplified example)
        local tool_result = handle_tool_call(tool_call)
        
        -- Then add the function result back to the conversation
        agent:add_function_result(tool_call.name, tool_result, tool_call.id)
    end
    
    -- Execute again to continue with the tool results
    result = agent:step()
    
    -- Add this response to the conversation
    agent:add_assistant_message(result.result)
    
    print("Agent response with tool results: " .. result.result)
end
```

### Example: Handling Tool Results

```lua
-- Function to handle tool calls (simplified example)
function handle_tool_call(tool_call)
    -- Example implementation for a search tool
    if tool_call.name == "search_papers" then
        return {
            papers = {
                {
                    title = "Recent Advances in Quantum Computing",
                    authors = "Smith, J. and Johnson, L.",
                    year = 2024,
                    url = "https://example.com/paper1"
                },
                {
                    title = "Quantum Algorithms for Machine Learning",
                    authors = "Lee, M. et al.",
                    year = 2023,
                    url = "https://example.com/paper2"
                }
            }
        }
    end
    
    error("not implemented")
end
```

### Example: Complete Conversation Flow with Tools

Here's a more complete example showing the full conversation flow with tools:

```lua
local agent_runner = require("agent_runner")
local agent_registry = require("agent_registry")

-- Load an agent with tool capabilities
local agent_spec, err = agent_registry.get_by_id("research-assistant")
if not agent_spec then
    print("Failed to load agent: " .. tostring(err))
    return
end

-- Create agent runner instance
local agent = agent_runner.new(agent_spec)

-- Function to handle the complete conversation flow
function run_conversation(query)
    -- Start with user query
    agent:add_user_message(query)
    
    -- Process conversation until complete
    while true do
        -- Execute next step
        local result, err = agent:step()
        
        if err then
            print("Error: " .. err)
            break
        end
        
        -- Print the current response
        if result.result and #result.result > 0 then
            print("Agent: " .. result.result)
        end
        
        -- Handle any tool calls
        if result.tool_calls and #result.tool_calls > 0 then
            -- Important: Add the assistant response to conversation
            agent:add_assistant_message(result.result)
            
            for _, tool_call in ipairs(result.tool_calls) do
                print("Tool called: " .. tool_call.name)
                
                -- First add the function call to the conversation
                agent:add_function_call(
                    tool_call.name,
                    tool_call.arguments,
                    tool_call.id
                )
                
                -- Process the tool call
                local tool_result = handle_tool_call(tool_call)
                
                -- Then add the result back to the conversation
                agent:add_function_result(tool_call.name, tool_result, tool_call.id)
            end
        else
            -- No tool calls, this turn is complete
            -- Important: Add the assistant response to conversation
            agent:add_assistant_message(result.result)
            break
        end
    end
end

-- Run a sample conversation
run_conversation("I need information on recent quantum computing papers")
```

## 4. Agent YAML Declaration Example

Agents are defined in YAML format in the registry system. Here's an example of how to define an agent:

```yaml
version: "1.0"
namespace: wippy.agents

meta:
  depends_on: [ ns:wippy.test ]

entries:
  # Example Agent: Research Assistant
  - name: research-assistant
    kind: registry.entry
    meta:
      type: "agent.gen1"
      name: "Research Assistant"
      comment: "An agent that helps with research and information gathering"
    data:
      prompt: |
        You are an AI research assistant designed to help users find information, analyze data, and synthesize knowledge.

        ## Guidelines:
        - Provide factual, well-researched information
        - When uncertain, acknowledge limitations
        - Cite sources whenever possible
        - Organize complex information clearly
        - Highlight key insights and takeaways

      model: "claude-3-7-sonnet"
      max_tokens: 4096
      temperature: 0.7
      thinking_effort: 80  # Higher thinking effort (0-100 scale)

      # Inherit capabilities from base agents
      inherit: [ "wippy.agents:base-conversational" ]

      # Traits that define this agent's capabilities
      traits: [ "thinking", "conversational" ]

      # Tools this agent can access
      tools: [ "system:search", "system:web_browser", "system:file_reader" ]

      # Long-term memory entries
      memory: [
        "You were created to help with academic and professional research",
        "You specialize in finding, summarizing, and analyzing information",
        "You should always provide balanced perspectives on controversial topics"
      ]

      # Other agents this agent can delegate tasks to
      delegate:
        wippy.agents:data-analyst:
          rule: "Give to data analyst if data analysis is needed"
          name: "to_data_analyst"
        wippy.agents:citation-assistant:
          rule: "Give to citation assistant if citation help is needed"
          name: "to_citation_assistant"

  # Example Agent: Data Analyst
  - name: data-analyst
    kind: registry.entry
    meta:
      type: "agent.gen1"
      name: "Data Analyst"
      comment: "Specialized agent for data analysis and visualization"
    data:
      prompt: |
        You are an AI data analyst specializing in statistical analysis and data visualization.
        Your role is to help extract insights from data and present them in clear, meaningful ways.

        ## Approach to Analysis:
        - Start with exploratory data analysis
        - Identify patterns, trends, and outliers
        - Use appropriate statistical methods
        - Create clear visualizations that tell a story
        - Explain findings in plain language

      model: "claude-3-7-sonnet"
      max_tokens: 2048
      temperature: 0.3
      thinking_effort: 90  # High thinking effort for complex analysis

      # Inherit from base computational agent
      inherit: [ "wippy.agents:base-computational" ]

      # Traits specific to data analysis
      traits: [ "thinking" ]

      # Tools specialized for data work
      tools: [
        "system:csv_processor",
        "system:statistical_analysis",
        "system:data_visualization"
      ]

      # Memory specific to data analysis
      memory: [
        "You excel at interpreting complex datasets",
        "Always explain statistical concepts in clear, simple terms",
        "Visualizations should prioritize clarity over complexity"
      ]
```

## 5. Input and Output Format Reference

### Agent Specification Format

```lua
{
    -- Agent metadata
    id = "research-assistant",              -- String: Unique identifier
    name = "Research Assistant",            -- String: Display name
    description = "Helps with research tasks", -- String: Description
    
    -- LLM configuration
    model = "claude-3-7-sonnet",            -- String: The LLM model to use
    max_tokens = 4096,                      -- Number: Maximum output tokens
    temperature = 0.7,                      -- Number: Temperature (0-1)
    thinking_effort = 80,                   -- Number: Thinking effort (0-100)
    
    -- System prompt
    prompt = "You are a research assistant...", -- String: Base system prompt
    
    -- Agent capabilities
    traits = {"conversational", "thinking"}, -- Array: Trait names to incorporate
    tools = {"system:search", "system:calculator"}, -- Array: Tool IDs
    
    -- Memory (context provided to the agent)
    memory = {                              -- Array: Long-term memory items
        "You were created on March 10, 2025",
        "Your purpose is to assist with research tasks"
    },
    
    -- Handouts (delegation capabilities)
    delegates = {                            -- Array: Agents to delegate to
        {
            id = "data-analyst-id",         -- String: Agent ID to delegate to
            name = "Data Analyst",          -- String: Display name
            description = "Expert in data analysis" -- String: Description
        }
    }
}
```

### Execute Function Output Format

```lua
{
    -- Success case
    result = "Generated text response",    -- String: The generated text
    
    -- Tool calls (if the model made tool calls)
    tool_calls = {                          -- Table: Array of tool calls (if any)
        {
            id = "call_123",                -- String: Unique ID for this tool call
            name = "get_weather",           -- String: Name of the tool to call
            arguments = {                   -- Table: Arguments for the tool
                location = "New York",
                units = "celsius"
            }
        }
    },
    
    -- Handout information (if the model delegated to another agent), removed from tools
    delegate_target = "data-analyst-id",    -- String: ID of the target agent
    delegate_message = "Analyze this data...", -- String: Message to forward
    
    -- Token usage information
    tokens = {
        prompt_tokens = 56,                -- Number: Tokens used in the prompt
        completion_tokens = 142,           -- Number: Tokens generated in the response
        thinking_tokens = 25,              -- Number: Tokens used for reasoning (if applicable)
        total_tokens = 223                 -- Number: Total tokens used
    }
}
```

### Agent Stats Output Format

```lua
{
    id = "research-assistant",            -- String: Agent ID
    name = "Research Assistant",          -- String: Agent name
    messages_handled = 5,                 -- Number: Messages processed in session
    session_duration = "00:05:23",        -- String: Session duration
    total_tokens = {                      -- Table: Token usage statistics
        prompt = 1245,                    -- Number: Prompt tokens used
        completion = 876,                 -- Number: Completion tokens used
        thinking = 320,                   -- Number: Thinking tokens used
        total = 2441                      -- Number: Total tokens used
    }
}
```

## 6. Using Thinking Effort for Enhanced Reasoning

The `thinking_effort` parameter allows you to control how much additional reasoning the model should apply when generating responses. This is particularly useful for:

- Complex problem-solving tasks
- Mathematical reasoning
- Logic puzzles and deductive reasoning
- In-depth analysis of data or text
- Multi-step planning

### Thinking Effort Scale

The parameter works on a scale from 0-100:

- **0**: Default behavior with no additional thinking (fastest)
- **25**: Light thinking for moderately complex tasks
- **50**: Moderate thinking for complex tasks
- **75**: Intensive thinking for very complex tasks
- **100**: Maximum thinking effort (slowest, most thorough)

### Optimal Usage

For best results:

- Use higher thinking effort (70-100) for tasks requiring rigorous reasoning
- Use moderate thinking effort (30-70) for general problem-solving
- Use low or no thinking effort (0-30) for straightforward questions
- Consider token usage tradeoffs - higher thinking effort consumes more tokens
- Best suited for Claude 3.7 and newer models with reasoning capabilities

### Token Tracking

When using thinking effort, token usage is automatically tracked in these categories:

- `prompt_tokens`: Tokens used in the input
- `completion_tokens`: Tokens used in the final response
- `thinking_tokens`: Tokens used during the reasoning process
- `total_tokens`: Combined total of all token usage