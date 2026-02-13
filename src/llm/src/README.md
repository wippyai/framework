# LLM

Multi-provider LLM integration library with contract-based architecture, smart model resolution, and streaming.

## Installation

```yaml
- name: dep.wippy.llm
  kind: ns.dependency
  component: wippy/llm
  version: ">=v0.4.0"
```

## Text Generation

```lua
local llm = require("llm")

-- Smart model resolution: name -> class -> class:prefix
local result, err = llm.generate("Hello!", {model = "claude-sonnet"})
local result, err = llm.generate("Hello!", {model = "claude"})
local result, err = llm.generate("Hello!", {model = "class:fast"})

-- Direct provider call (skip model discovery)
local result, err = llm.generate("Hello!", {
    model = "claude-sonnet-4-20250514",
    provider_id = "wippy.llm.claude:provider"
})
```

### Generation Options

```lua
local result = llm.generate(builder, {
    model = "claude",
    temperature = 0.7,
    max_tokens = 1000,
    thinking_effort = 50,   -- 0-100, for thinking-capable models
    top_p = 0.9,
    frequency_penalty = 0.5,
    presence_penalty = 0.5,
    stop_sequences = {"END"},
    seed = 12345,
    stream = {
        reply_to = process.self(),
        topic = "llm_stream",
        buffer_size = 10
    }
})
```

### Response Format

```lua
-- result structure:
{
    result = "Generated text...",
    tool_calls = {
        {id = "call-123", name = "get_weather", arguments = {location = "Tokyo"}}
    },
    tokens = {
        prompt_tokens = 100,
        completion_tokens = 50,
        thinking_tokens = 0,
        total_tokens = 150,
        cache_read_input_tokens = 0,
        cache_creation_input_tokens = 0
    },
    finish_reason = "stop",  -- "stop" | "length" | "filtered" | "tool_call" | "error"
    metadata = {},
    usage_record = {usage_id = "..."}
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
    :add_developer("Keep responses concise")

local result = llm.generate(builder, {model = "claude"})
```

### Multi-modal Content

```lua
builder:add_message(prompt.ROLE.USER, {
    prompt.text("What's in this image?"),
    prompt.image("https://example.com/image.jpg", "image/jpeg")
})

-- Base64 images
builder:add_message(prompt.ROLE.USER, {
    prompt.text("Describe this"),
    prompt.image_base64("image/png", base64_data)
})
```

### Function Calls and Results

```lua
builder:add_function_call("get_weather", {location = "Tokyo"}, "call-123")
builder:add_function_result("get_weather", '{"temp": 22}', "call-123")
```

### Cache Markers

```lua
builder:add_system("Long system prompt...")
builder:add_cache_marker("system_cache")
builder:add_user("Question")
```

### Builder Operations

```lua
local messages = builder:get_messages()
local cloned = builder:clone()
builder:clear()

-- Initialize with existing messages
local builder = prompt.new(existing_messages)
local builder = prompt.with_system("System prompt")
```

### Roles and Content Types

```lua
prompt.ROLE = {
    SYSTEM, USER, ASSISTANT, DEVELOPER,
    FUNCTION_CALL, FUNCTION_RESULT, CACHE_MARKER
}
prompt.CONTENT_TYPE = {TEXT, IMAGE}
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
    tool_choice = "auto"  -- "auto" | "none" | "any" | "tool_name"
})

if result.tool_calls and #result.tool_calls > 0 then
    for _, call in ipairs(result.tool_calls) do
        -- call.id, call.name, call.arguments
    end
end
```

## Structured Output

```lua
local result, err = llm.structured_output(schema, "Extract info about John", {
    model = "claude"
})
-- result.result contains the parsed object matching the schema
```

OpenAI models require all properties in `required`, use `type = {"string", "null"}` for optional fields, and set `additionalProperties = false`.

## Embeddings

```lua
-- Single text
local result, err = llm.embed("Hello world", {model = "text-embedding-3-small"})
-- result.result = {0.123, 0.456, ...}

-- Multiple texts
local result, err = llm.embed({"Hello", "World"}, {
    model = "text-embedding-3-small",
    dimensions = 256
})
-- result.result = {{...}, {...}}
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
local ch = process.listen("llm_stream")
while true do
    local chunk = ch:receive()
    if chunk.type == "chunk" then
        io.write(chunk.content)
    elseif chunk.type == "thinking" then
        -- reasoning content
    elseif chunk.type == "tool_call" then
        -- tool_call.name, tool_call.arguments, tool_call.id
    elseif chunk.type == "done" then
        break
    elseif chunk.type == "error" then
        break
    end
end
```

### Output Library

```lua
local output = require("output")

-- Create streamer for sending chunks
local streamer = output.streamer(pid, "topic", buffer_size)
streamer:send_content("Hello")
streamer:send_thinking("Reasoning...")
streamer:send_tool_call("tool_name", {arg = "val"}, "call-id")
streamer:send_error("server_error", "Something failed")
streamer:send_done({usage = output.usage(100, 50, 0, 0, 0)})

-- Buffered streaming
streamer:buffer_content("partial ")
streamer:buffer_content("text...")
streamer:flush()
```

## Model Discovery

```lua
local models = llm.available_models()
local vision_models = llm.available_models(llm.CAPABILITY.VISION)
local tool_models = llm.available_models(llm.CAPABILITY.TOOL_USE)

local classes = llm.get_classes()

local status, err = llm.status({model = "claude"})
-- {success = true, status = "healthy", message = "..."}
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

## Error Handling

```lua
local result, err = llm.generate("Hello", {model = "claude"})
if err then
    -- transport/system error
end
if result and result.error then
    -- provider error
    -- result.error: error type constant
    -- result.error_message: human-readable message
end
```

### Error Types

```lua
llm.ERROR_TYPE = {
    INVALID_REQUEST = "invalid_request",
    AUTHENTICATION = "authentication_error",
    RATE_LIMIT = "rate_limit_exceeded",
    SERVER_ERROR = "server_error",
    CONTEXT_LENGTH = "context_length_exceeded",
    CONTENT_FILTER = "content_filter",
    TIMEOUT = "timeout_error",
    MODEL_ERROR = "model_error"
}
```

## Registering Models

```yaml
entries:
  - name: claude-sonnet
    kind: registry.entry
    meta:
      type: llm.model
      name: claude-sonnet
      title: Claude Sonnet
      class: [fast, chat]
      capabilities: [generate, tool_use, vision, thinking, caching]
      priority: 100
    providers:
      - id: wippy.llm.claude:provider
        provider_model: claude-sonnet-4-20250514
        options:
          temperature: 0.7
    max_tokens: 200000
    output_tokens: 8192
    pricing:
      input: 3
      output: 15
```

### Model Classes

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

## Providers

- `wippy.llm.claude` - Anthropic Claude
- `wippy.llm.openai` - OpenAI (also compatible with OpenRouter, LM Studio)
- `wippy.llm.google.vertex` - Google Vertex AI
- `wippy.llm.google.generative_ai` - Google Generative AI (Gemini)

### Environment Variables

```
# Claude
ANTHROPIC_API_KEY
ANTHROPIC_API_VERSION       # default: 2023-06-01
ANTHROPIC_BASE_URL          # default: https://api.anthropic.com
ANTHROPIC_TIMEOUT           # default: 240

# OpenAI
OPENAI_API_KEY
OPENAI_ORGANIZATION
OPENAI_BASE_URL
OPENAI_TIMEOUT

# Google
GOOGLE_CREDENTIALS          # service account JSON
GOOGLE_API_KEY              # for Generative AI
```

## Contracts

- `wippy.llm:generator` - Text generation with tool calling
- `wippy.llm:embedder` - Embedding generation
- `wippy.llm:structured_output` - Schema-constrained generation
- `wippy.llm:provider` - Provider health status
- `wippy.llm:usage_tracker` - Token usage tracking

## Subnamespaces

- `wippy.llm.claude` - Claude provider
- `wippy.llm.openai` - OpenAI provider
- `wippy.llm.google` - Google providers (Vertex AI, Generative AI)
- `wippy.llm.discovery` - Model and provider discovery
- `wippy.llm.util` - Utilities (text compression)
- `wippy.llm.env` - Environment configuration
