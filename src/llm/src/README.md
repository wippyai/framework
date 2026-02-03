# LLM

Multi-provider LLM integration library with contract-based architecture, model discovery, and streaming support.

## Installation

```yaml
entries:
  - name: llm
    kind: ns.dependency
    component: wippy/llm
    version: "*"
```

## Text Generation

```lua
local llm = require("llm")

-- Smart model resolution by name
local result, err = llm.generate("Hello!", {model = "claude-sonnet"})

-- By model class (uses highest priority model)
local result, err = llm.generate("Hello!", {model = "claude"})

-- Explicit class syntax
local result, err = llm.generate("Hello!", {model = "class:fast"})

-- Direct provider call (skip model discovery)
local result, err = llm.generate("Hello!", {
    model = "claude-3-5-sonnet-20241022",
    provider_id = "wippy.llm.claude:provider"
})
```

## Response Format

```lua
{
    result = "Generated text...",
    tool_calls = {},  -- empty if no tools called
    tokens = {
        prompt_tokens = 100,
        completion_tokens = 50,
        thinking_tokens = 0,
        total_tokens = 150,
        cache_read_input_tokens = 0,
        cache_creation_input_tokens = 0
    },
    finish_reason = "stop",  -- "stop", "length", "filtered", "tool_call", "error"
    metadata = {},
    usage_record = {usage_id = "..."}  -- if usage tracker configured
}
```

## Prompt Builder

```lua
local prompt = require("prompt")

local builder = prompt.new()
    :add_system("You are a helpful assistant")
    :add_user("What is Lua?")
    :add_assistant("Lua is a lightweight scripting language...")
    :add_user("Tell me more")

local result = llm.generate(builder, {model = "claude"})
```

### Multi-modal Content

```lua
local builder = prompt.new()
    :add_system("You are a vision assistant")
    :add_message(prompt.ROLE.USER, {
        prompt.text("What's in this image?"),
        prompt.image("https://example.com/image.jpg", "image/jpeg")
    })

-- Or with base64
:add_message(prompt.ROLE.USER, {
    prompt.text("Describe this"),
    prompt.image_base64("image/png", base64_data)
})
```

### Function Calls and Results

```lua
local builder = prompt.new()
    :add_user("What's the weather in Tokyo?")
    :add_function_call("get_weather", {location = "Tokyo"}, "call_123")
    :add_function_result("get_weather", '{"temp": 22, "condition": "sunny"}', "call_123")
```

### Cache Markers

```lua
local builder = prompt.new()
    :add_system("Long system prompt...")
    :add_cache_marker("system_cache")
    :add_user("Question")
```

## Tool Calling

```lua
local result = llm.generate(builder, {
    model = "claude",
    tools = {
        {
            name = "get_weather",
            description = "Get current weather for a location",
            schema = {
                type = "object",
                properties = {
                    location = {type = "string", description = "City name"}
                },
                required = {"location"}
            }
        }
    },
    tool_choice = "auto"  -- "auto", "none", "any", or specific tool name
})

if result.tool_calls and #result.tool_calls > 0 then
    for _, call in ipairs(result.tool_calls) do
        -- call.id, call.name, call.arguments
    end
end
```

## Structured Output

```lua
local schema = {
    type = "object",
    properties = {
        name = {type = "string"},
        age = {type = "integer"},
        interests = {
            type = "array",
            items = {type = "string"}
        }
    },
    required = {"name", "age"}
}

local result, err = llm.structured_output(schema, "Extract info about John who is 25 and likes coding", {
    model = "claude"
})

-- result.result contains the parsed object
```

## Embeddings

```lua
-- Single text
local result, err = llm.embed("Hello world", {model = "text-embedding-3-small"})
-- result.result = [[0.123, 0.456, ...]]

-- Multiple texts
local result, err = llm.embed({"Hello", "World"}, {model = "text-embedding-3-small"})
-- result.result = {[...], [...]}

-- With dimensions
local result, err = llm.embed("Hello", {
    model = "text-embedding-3-small",
    dimensions = 256
})
```

## Streaming

```lua
local result = llm.generate(builder, {
    model = "claude",
    stream = {
        reply_to = process.self(),
        topic = "llm_stream",
        buffer_size = 10
    }
})

-- Receive chunks via process messages
-- Each chunk: {type = "chunk|thinking|tool_call|error|done", ...}
```

### Output Library for Streaming

```lua
local output = require("output")

-- Create streamer
local streamer = output.streamer(pid, "llm_response", 10)
streamer:send_content("Hello")
streamer:send_thinking("Let me think...")
streamer:send_tool_call("get_weather", {location = "Tokyo"}, "call_123")
streamer:send_done({usage = output.usage(100, 50, 0, 0, 0)})

-- Buffered streaming
streamer:buffer_content("Some ")
streamer:buffer_content("text...")
streamer:flush()
```

## Model Discovery

```lua
-- Get all models
local models = llm.available_models()

-- Filter by capability
local models = llm.available_models(llm.CAPABILITY.VISION)
local models = llm.available_models(llm.CAPABILITY.TOOL_USE)

-- Get all classes
local classes = llm.get_classes()
```

### Capabilities

```lua
llm.CAPABILITY = {
    GENERATE = "generate",
    TOOL_USE = "tool_use",
    STRUCTURED_OUTPUT = "structured_output",
    EMBED = "embed",
    THINKING = "thinking",
    VISION = "vision",
    CACHING = "caching"
}
```

## Provider Status

```lua
local status, err = llm.status({model = "claude"})
-- {success = true, status = "healthy", message = "..."}
```

## Generation Options

```lua
local result = llm.generate(builder, {
    model = "claude",
    temperature = 0.7,
    max_tokens = 1000,
    thinking_effort = 50,  -- 0-100 for thinking models
    top_p = 0.9,
    frequency_penalty = 0.5,
    presence_penalty = 0.5,
    stop_sequences = {"END", "STOP"},
    seed = 12345,
    user = "user_123"  -- auto-set from security.actor() if available
})
```

## Providers

- `wippy.llm.claude` - Anthropic Claude API
- `wippy.llm.openai` - OpenAI API
- `wippy.llm.google.vertex` - Google Vertex AI
- `wippy.llm.google.generative_ai` - Google Generative AI (Gemini)

## Configuration

Environment variables:

```bash
# Claude
ANTHROPIC_API_KEY
ANTHROPIC_API_VERSION    # default: 2023-06-01
ANTHROPIC_BASE_URL       # default: https://api.anthropic.com
ANTHROPIC_TIMEOUT        # default: 240

# OpenAI
OPENAI_API_KEY
OPENAI_ORGANIZATION
OPENAI_BASE_URL
OPENAI_TIMEOUT

# Google
GOOGLE_CREDENTIALS       # service account JSON
GOOGLE_API_KEY           # for Generative AI
```

## Contracts

- `wippy.llm:generator` - Text generation with tool calling
- `wippy.llm:embedder` - Embedding generation
- `wippy.llm:structured_output` - Schema-constrained generation
- `wippy.llm:provider` - Provider health status
- `wippy.llm:usage_tracker` - Token usage tracking

## Registering Models

```yaml
entries:
  - name: my_model
    kind: registry.entry
    meta:
      type: llm.model
      name: my-custom-model
      title: My Custom Model
      class: [fast, chat]
      capabilities: [generate, tool_use]
      priority: 100
    providers:
      - id: wippy.llm.openai:provider
        provider_model: gpt-4o
        options:
          temperature: 0.7
```

## Registering Model Classes

```yaml
entries:
  - name: fast_class
    kind: registry.entry
    meta:
      type: llm.model.class
      name: fast
      title: Fast Models
      comment: Optimized for speed
```
