# Agent

LLM agent framework with tool support, traits, delegation, and memory integration.

## Installation

```yaml
entries:
  - name: agent
    kind: ns.dependency
    component: wippy/agent
    version: "*"
```

## Agent Specification

Define agents in YAML:

```yaml
entries:
  - name: my_agent
    kind: registry.entry
    meta:
      type: agent
      name: my-agent
      title: My Agent
      comment: A helpful assistant
    model: claude
    max_tokens: 1024
    temperature: 0.7
    thinking_effort: 50
    prompt: |
      You are a helpful assistant.
      Be concise and accurate.
    tools:
      - my_namespace:tool_one
      - id: my_namespace:tool_two
        alias: custom_name
        context:
          setting: value
    traits:
      - time_aware
      - id: custom_trait
        context:
          key: value
    delegates:
      - id: specialist_agent
        name: ask_specialist
        rule: for complex technical questions
```

## Compilation

```lua
local compiler = require("compiler")
local agent = require("agent")

-- Load raw spec from registry
local raw_spec = registry.get("my_namespace:my_agent")

-- Compile with optional config
local compiled_spec, err = compiler.compile(raw_spec.data, {
    delegates = {
        generate_tool_schemas = true,
        description_suffix = " (delegate agent)"
    }
})

-- Create runner
local runner, err = agent.new(compiled_spec)
```

## Running Steps

```lua
local prompt = require("prompt")

-- Build conversation
local builder = prompt.new()
    :add_user("What's the weather in Tokyo?")

-- Execute step
local response, err = runner:step(builder, {
    context = {session_id = "abc123"},
    stream_target = {reply_to = process.self(), topic = "stream"}
})

-- Response structure
-- response.result - Generated text
-- response.tool_calls - Tool calls to execute
-- response.delegate_calls - Delegation requests
-- response.tokens - Token usage
-- response.finish_reason - "stop", "tool_call", etc.
-- response.memory_recall - Memory recall info if triggered
```

## Tool Execution

```lua
local tool_caller = require("caller")

local caller = tool_caller.new()
    :set_strategy(tool_caller.STRATEGY.PARALLEL)

-- Validate tool calls from LLM response
local validated, err = caller:validate(response.tool_calls)

-- Execute tools
local results = caller:execute({session_id = "abc123"}, validated)

-- Add results to conversation
for call_id, result in pairs(results) do
    local tool_call = result.tool_call
    if result.error then
        builder:add_function_result(tool_call.name, json.encode({error = result.error}), call_id)
    else
        builder:add_function_result(tool_call.name, json.encode(result.result), call_id)
    end
end
```

## Traits

Traits add reusable capabilities to agents:

```yaml
entries:
  - name: time_aware
    kind: registry.entry
    meta:
      type: agent.trait
      name: time_aware
    prompt: "Current time context will be provided."
    prompt_func_id: my_namespace:time_prompt_func
    tools:
      - my_namespace:get_current_time
```

### Trait Functions

```lua
-- Prompt function (called at each step)
local function time_prompt(base_prompt, context)
    return "Current time: " .. os.date("%Y-%m-%d %H:%M:%S")
end

-- Build function (called during compilation)
local function build_tools(base_prompt, context)
    return {
        prompt = "Additional context...",
        tools = {{id = "dynamic:tool", schema = {...}}},
        delegates = {{id = "other:agent", name = "helper"}}
    }
end
```

## Delegation

Agents can delegate to other agents:

```lua
if response.delegate_calls and #response.delegate_calls > 0 then
    for _, delegate in ipairs(response.delegate_calls) do
        -- delegate.agent_id - Target agent ID
        -- delegate.name - Tool name used
        -- delegate.arguments - Arguments from LLM
        -- delegate.context - Merged context
    end
end
```

## Memory Integration

Configure memory recall for agents:

```yaml
entries:
  - name: my_agent
    kind: registry.entry
    meta:
      type: agent
    memory_contract:
      implementation_id: my_namespace:memory_impl
      context:
        user_id: ${user_id}
      options:
        max_items: 5
        max_length: 2000
        recall_cooldown: 2
        min_conversation_length: 3
```

Memory is recalled automatically based on conversation context:

```lua
local response = runner:step(builder, {
    context = {user_id = "123"},
    disable_memory_recall = false,
    previous_memory_ids = {"mem_1", "mem_2"}
})

-- response.memory_recall.memory_ids - IDs of recalled memories
-- response.memory_recall.count - Number of memories
```

## Context Management

```lua
local context_manager = require("context")

-- Load agent by ID or name
local ctx, err = context_manager.load("my_namespace:my_agent")
-- or
local ctx, err = context_manager.load_by_name("my-agent")

-- Get compiled runner
local runner = ctx:get_runner()

-- Switch agent at runtime
ctx:switch_agent("other_namespace:specialist")

-- Merge additional context
ctx:merge_context({session_id = "abc"})
```

## Tool Discovery

```lua
local tools = require("tools")

-- Find tools by namespace
local tool_list = tools.find_tools({namespace = "my_namespace"})

-- Get tool schema
local schema, err = tools.get_tool_schema("my_namespace:my_tool")
-- schema.name, schema.description, schema.schema, schema.meta

-- Wildcard tool inclusion in agents
tools:
  - "my_namespace:*"  -- All tools in namespace
```

## Streaming

```lua
local response = runner:step(builder, {
    stream_target = {
        reply_to = process.self(),
        topic = "agent_stream",
        buffer_size = 10
    }
})

-- Receive stream chunks via process messages
```

## Token Tracking

```lua
local stats = runner:get_stats()
-- stats.total_tokens.prompt
-- stats.total_tokens.completion
-- stats.total_tokens.thinking
-- stats.total_tokens.total
```

## Subnamespaces

- `wippy.agent.compiler` - Agent compilation
- `wippy.agent.tools` - Tool caller and discovery
- `wippy.agent.discovery` - Agent and trait registry
- `wippy.agent.traits` - Built-in traits

## Contracts

- `wippy.agent:memory` - Memory recall interface for agents
