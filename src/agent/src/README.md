# Agent

LLM agent framework with compilation, tool execution, traits, delegation, and memory recall.

## Installation

```yaml
- name: dep.wippy.agent
  kind: ns.dependency
  component: wippy/agent
  version: ">=v0.4.0"
```

Requires `wippy/llm >= 0.4.0`.

## Agent Context

The primary SDK entry point. Chains configuration calls and produces a compiled agent runner.

```lua
local agent_context = require("context")

local ctx = agent_context.new({
    context = { session_id = "abc123", user_id = "u1" },
    delegate_tools = {
        enabled = true,
        description_suffix = " (delegate agent)"
    }
})

local runner, err = ctx
    :add_tools({ "my_ns:search", { id = "my_ns:fetch", alias = "web_fetch" } })
    :add_delegates({
        { id = "specialist_ns:specialist", name = "ask_specialist", rule = "for technical questions" }
    })
    :set_memory_contract({
        implementation_id = "my_ns:memory_impl",
        context = { user_id = "u1" },
        options = { max_items = 5 }
    })
    :load_agent("my_ns:my_agent")
```

### Runtime Switching

```lua
-- Switch to a different agent (recompiles with current tools/delegates)
local ok, err = ctx:switch_to_agent("my_ns:other_agent")

-- Switch model on the current agent
local ok, err = ctx:switch_to_model("claude-opus")

-- Update runtime context
ctx:update_context({ locale = "en-US" })

-- Get current state
local config = ctx:get_config()
-- config.current_agent_id, config.current_model, config.delegate_tools_enabled
```

### Inline Agent Spec

`load_agent` accepts a table instead of an ID string:

```lua
local runner, err = ctx:load_agent({
    id = "inline-agent",
    name = "helper",
    prompt = "You are a concise helper.",
    model = "claude-sonnet",
    max_tokens = 1024,
    tools = { "my_ns:search" }
}, { model = "claude-opus" }) -- model override
```

## Agent Definition (YAML)

Agents are defined as registry entries with type `agent.gen1`:

```yaml
entries:
  - name: my_agent
    kind: registry.entry
    meta:
      type: agent.gen1
      name: my-agent
      title: My Agent
      comment: A helpful assistant
      class: [public]
    prompt: |
      You are a helpful assistant.
    model: claude-sonnet
    max_tokens: 4096
    temperature: 0.7
    thinking_effort: 50
    tools:
      - my_ns:tool_one
      - id: my_ns:tool_two
        alias: custom_name
        context:
          setting: value
      - my_ns:*                    # wildcard: all tools in namespace
    traits:
      - time_aware
      - id: custom_trait
        context:
          key: value
    memory:
      - "Background knowledge item"
    delegates:
      - id: specialist_ns:specialist_agent
        name: ask_specialist
        rule: for complex technical questions
    memory_contract:
      implementation_id: my_ns:memory_impl
      context:
        user_id: ${user_id}
      options:
        max_items: 5
        max_length: 2000
        recall_cooldown: 2
        min_conversation_length: 3
```

## Compilation

The compiler resolves tools, traits, and delegates from a raw agent spec into a runnable `CompiledAgentSpec`.

```lua
local compiler = require("compiler")
local agent = require("agent")

local compiled_spec, err = compiler.compile(raw_spec, {
    context_merger = function(trait_ctx, agent_ctx, tool_ctx)
        -- custom 3-way merge
        local merged = {}
        for k, v in pairs(trait_ctx or {}) do merged[k] = v end
        for k, v in pairs(agent_ctx or {}) do merged[k] = v end
        for k, v in pairs(tool_ctx or {}) do merged[k] = v end
        return merged
    end,
    delegates = {
        generate_tool_schemas = true,
        description_suffix = " (delegate agent)",
        tool_schema = {
            type = "object",
            properties = {
                message = { type = "string", description = "The message to forward" }
            },
            required = { "message" }
        }
    }
})

local runner, err = agent.new(compiled_spec)
```

### Compiled Spec Structure

```lua
{
    id = "my_ns:my_agent",
    name = "my-agent",
    description = "A helpful assistant",
    model = "claude-sonnet",
    max_tokens = 4096,
    temperature = 0.7,
    thinking_effort = 50,
    prompt = "Combined system prompt with trait prompts appended",
    tools = {                       -- keyed by canonical name
        tool_one = {
            name = "tool_one",
            description = "...",
            schema = { ... },
            registry_id = "my_ns:tool_one",
            context = { agent_id = "my_ns:my_agent" },
            meta = {}
        },
        ask_specialist = {          -- delegate tool
            name = "ask_specialist",
            description = "Forward the request to for complex technical questions",
            schema = { ... },
            agent_id = "specialist_ns:specialist_agent",
            context = { ... }
        }
    },
    memory = { "Background knowledge item" },
    memory_contract = { ... },
    prompt_funcs = {                -- from traits with prompt_func_id
        { trait_id = "...", func_id = "...", context = { ... } }
    },
    step_funcs = {                  -- from traits with step_func_id
        { trait_id = "...", func_id = "...", context = { ... } }
    }
}
```

## Running Steps

```lua
local prompt = require("prompt")

local builder = prompt.new()
    :add_user("What's the weather in Tokyo?")

local response, err = runner:step(builder, {
    context = { session_id = "abc123" },
    stream_target = { reply_to = process.self(), topic = "stream" },
    tool_call = "auto",
    disable_memory_recall = false,
    previous_memory_ids = { "mem_1", "mem_2" }
})
```

### Response Structure

```lua
{
    result = { ... },               -- content blocks from LLM
    tool_calls = {                  -- nil if none
        {
            id = "call-123",
            name = "get_weather",
            arguments = { location = "Tokyo" },
            registry_id = "my_ns:get_weather",
            context = { agent_id = "..." }
        }
    },
    delegate_calls = {              -- nil if none
        {
            id = "call-456",
            name = "ask_specialist",
            arguments = { message = "..." },
            agent_id = "specialist_ns:specialist_agent",
            context = { from_agent_id = "...", to_agent_id = "..." }
        }
    },
    tokens = { prompt_tokens = 100, completion_tokens = 50, thinking_tokens = 0 },
    finish_reason = "stop",
    memory_recall = { memory_ids = { "mem_3" }, count = 1 },
    memory_prompt = { ... }
}
```

### Token Tracking

```lua
local stats = runner:get_stats()
-- stats.total_tokens.prompt
-- stats.total_tokens.completion
-- stats.total_tokens.thinking
-- stats.total_tokens.total
```

## Tool Execution

```lua
local tool_caller = require("caller")

local caller = tool_caller.new()
    :set_strategy(tool_caller.STRATEGY.PARALLEL) -- or SEQUENTIAL (default)

-- Validate tool calls from LLM response
local validated, err = caller:validate(response.tool_calls)

-- Execute tools with session context
local results = caller:execute({ session_id = "abc123" }, validated)

for call_id, result in pairs(results) do
    if result.error then
        builder:add_function_result(result.tool_call.name, json.encode({ error = result.error }), call_id)
    else
        builder:add_function_result(result.tool_call.name, json.encode(result.result), call_id)
    end
end
```

### Exclusive Tools

Tools with `meta.exclusive = true` in their registry entry cancel all other concurrent tool calls in the same batch. Only one exclusive tool is allowed per batch.

## Traits

Traits add reusable capabilities (prompt text, tools, delegates) to agents at compile time.

### Trait Definition (YAML)

```yaml
entries:
  - name: time_aware
    kind: registry.entry
    meta:
      name: Time Aware
      type: agent.trait
      comment: Adds current time context
    build_func_id: wippy.agent.traits:init_time_aware
    prompt_func_id: my_ns:time_prompt_func   # called at each step
    step_func_id: my_ns:time_step_func       # called at each step
    tools:
      - my_ns:get_current_time
      - id: my_ns:calendar
        alias: cal
        context:
          timezone: UTC
    context:
      time_interval: 15
      timezone: UTC
```

### Trait Functions

```lua
-- Build function: called during compilation, returns contributions
local function execute(base_prompt, context)
    return {
        prompt = "Additional prompt text...",
        tools = { { id = "my_ns:dynamic_tool" } },
        delegates = { { id = "other_ns:agent", name = "helper" } },
        context = { extra_key = "value" }
    }
end
return { execute = execute }
```

```lua
-- Prompt function: called at each agent:step(), returns dynamic prompt text
local function execute(base_prompt)
    return "Current time: Thursday, February 12, 2026 at 14:00 UTC"
end
return { execute = execute }
```

### Built-in Traits

- `wippy.agent.traits:time_aware` -- Injects rounded current time via `build_func_id`. Configurable via context: `time_interval` (minutes, default 15), `timezone` (default UTC).

## Delegation

Delegates are other agents exposed as tools. The LLM calls them like regular tools; the runner separates them in the response.

```lua
-- In agent YAML definition
delegates:
  - id: specialist_ns:specialist_agent
    name: ask_specialist
    rule: for complex technical questions
    context:
      domain: backend
```

```lua
-- After runner:step()
if response.delegate_calls then
    for _, dc in ipairs(response.delegate_calls) do
        -- dc.agent_id:  "specialist_ns:specialist_agent"
        -- dc.name:      "ask_specialist"
        -- dc.arguments: { message = "..." }
        -- dc.context:   { from_agent_id = "...", to_agent_id = "...", domain = "backend" }
    end
end
```

## Memory

### Static Memory

Appended to the system prompt at agent creation:

```yaml
memory:
  - "You specialize in backend systems"
  - "Always cite sources"
```

### Memory Contract (Dynamic Recall)

Configured per-agent, backed by an implementation of the `wippy.agent:memory` contract:

```yaml
memory_contract:
  implementation_id: my_ns:memory_impl
  context:
    user_id: ${user_id}
  options:
    max_items: 3
    max_length: 1000
    recall_cooldown: 1
    min_conversation_length: 2
    enabled: true
```

At each step the runner checks recall eligibility (cooldown, min conversation length), calls `recall` on the memory contract with recent actions and previous memory IDs, and injects matching memories as a developer message.

## Discovery

### Agent Registry

```lua
local agent_registry = require("agent_registry")

local spec, err = agent_registry.get_by_id("my_ns:my_agent")
local spec, err = agent_registry.get_by_name("my-agent")
local agents, err = agent_registry.list_by_class("public")
local agents, err = agent_registry.list_by_class("public", { raw_entries = true })
```

### Tool Resolver

```lua
local tools = require("tools")

local schema, err = tools.get_tool_schema("my_ns:search")
-- schema: { id, registry_id, name, title, description, schema, meta }

local schemas, errors = tools.get_tool_schemas({ "my_ns:search", "my_ns:fetch" })
local ordered, errors = tools.get_tool_schemas_ordered({ "my_ns:search", "my_ns:fetch" })
local found, err = tools.find_tools({ namespace = "my_ns" })
local tool_id, err = tools.resolve_name_to_id("search", { "my_ns:search", "my_ns:fetch" })
local meta_map, errors = tools.get_tools_meta({ "my_ns:search" })
```

### Trait Resolver

```lua
local traits = require("traits")

local trait, err = traits.get_by_id("wippy.agent.traits:time_aware")
local trait, err = traits.get_by_name("Time Aware")
local all_traits = traits.get_all()

-- TraitSpec: { id, name, description, prompt, tools, build_func_id, prompt_func_id, step_func_id, context }
```

### Agent Selector

LLM-powered selection of an agent from a class based on user prompt:

```lua
local selector = require("selector")

local result, err = selector.select_agent("Help me analyze this data", "public")
-- result: { success = true, agent = "my_ns:data_analyst", reason = "..." }

-- Alternative interface
local result, err = selector.execute({
    user_prompt = "Help me analyze this data",
    class_name = "public"
})
```

## Contracts

### `wippy.agent:memory`

Memory recall interface. Implementations provide a `recall` method:

```lua
-- recall input
{
    recent_actions = { "user: How do I optimize?", "tool: analyze_schema -> 3 missing indexes" },
    previous_memories = { "mem_1", "mem_2" },
    constraints = { max_items = 3, max_length = 1000 }
}

-- recall output
{
    memories = {
        { id = "mem_3", content = "User prefers PostgreSQL" },
        { id = "mem_4", content = "Production DB has 50 tables" }
    }
}
```

### `wippy.agent:resolver`

Agent resolution contract. Applications provide a binding to handle custom agent ID formats (e.g., `skill:uuid`). If no binding exists, `context.lua` falls back to registry lookup. The contract has a single `resolve` method:

```lua
-- resolve input
{ agent_id = "skill:abc-123" }

-- resolve output: a raw agent spec table for compilation
{
    id = "skill:abc-123",
    name = "my-skill",
    prompt = "...",
    model = "claude-sonnet",
    tools = { "my_ns:tool" }
}
```

## Subnamespaces

| Namespace | Module | Description |
|---|---|---|
| `wippy.agent` | `agent` | Agent runner |
| `wippy.agent` | `context` | Agent context manager |
| `wippy.agent.compiler` | `compiler` | Agent compilation |
| `wippy.agent.discovery` | `registry` | Agent registry lookup |
| `wippy.agent.discovery` | `tools` | Tool schema resolver |
| `wippy.agent.discovery` | `traits` | Trait resolver |
| `wippy.agent.discovery` | `selector` | LLM-powered agent selector |
| `wippy.agent.tools` | `caller` | Tool execution (sequential/parallel) |
| `wippy.agent.traits` | `time_aware` | Built-in time-aware trait |
