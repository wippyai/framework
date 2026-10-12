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

### Route facts

Each provider route declares what the model accepts on the wire. These optional facts use a fixed vocabulary:

| Fact | Values | Meaning |
|---|---|---|
| `thinking` | `adaptive`, `budget`, `none` | How thinking effort is encoded |
| `sampling` | `true`, `false` | Whether temperature, top_p and top_k are accepted |
| `forced_tool_choice` | `true`, `false` | Whether `tool_choice = "any"` or a named tool is accepted |
| `structured_output` | `native`, `tool` | Native JSON schema output or a structured-output tool |

Missing facts preserve each driver's defaults. Claude and Bedrock default to budget thinking, sampling and forced tool choice enabled, and tool-based structured output. OpenAI, OpenAI-compatible and Google default to no thinking. Invalid fact values (outside the fixed vocabulary above) produce an `invalid_request` error naming the route, key and allowed values. A value inside that vocabulary but outside what a specific driver can honor is also `invalid_request`, naming the fact, the value and that driver's supported values: Bedrock only supports tool-based structured output, OpenAI and OpenAI-compatible only support `adaptive` or `none` thinking, and Google only supports `none` thinking.

Facts are normalized when building generation and structured-output requests. Discovery cards, `llm.available_models`, `llm.resolve_model`, and resolver results retain their original shape. Canonical route facts win over legacy forms and caller options. Resolved calls ignore caller `model_profile` and reject caller `accepts`. Direct calls can declare facts:

```lua
local response, err = llm.generate("Explain the result", {
    provider_id = "wippy.llm.claude:provider",
    model = "claude-sonnet-5",
    accepts = { thinking = "adaptive", sampling = false },
    thinking_effort = 50,
    temperature = 0.7
})
-- response.metadata.adjusted.temperature = { requested = 0.7 }
```

When `sampling = false`, the request removes temperature, top_p and top_k. When `thinking = "none"`, it removes a positive thinking_effort. Each removal appears in `metadata.adjusted[param] = { requested = value, sent = nil }` (Lua omits the nil field). With caller `strict = true`, adjustments fail with `invalid_request` naming the parameters before the provider HTTP request. The strict flag and fact/legacy options are not sent as driver request options.

Claude and Bedrock budget thinking never injects a temperature; the provider default is already 1. A caller temperature of 1 is sent unchanged with no adjustment. Any other caller temperature is dropped, never sent, and reported as `metadata.adjusted.temperature = { requested = value }` (no `sent`); with `sampling = false`, `metadata.adjusted` reports exactly this one entry, since sampling removal already stripped the option before the driver saw it.

Adaptive Claude and Bedrock requests with positive thinking_effort send `thinking.type = "adaptive"` and an effort level in `output_config`; they do not calculate a budget or touch temperature. An absent or zero effort sends no thinking fields.

The forced tool choice rule is provider-agnostic: a route with `forced_tool_choice = false` rejects a `tool_choice` of `"any"` or a tool name, for every driver, unless the caller permits `tool_choice_fallback = "auto"`. The caller must enforce tool use itself when accepting that fallback. The response reports `metadata.tool_choice = { requested = "any", sent = "auto" }` independently of `metadata.adjusted`. A route that can only produce structured output by forcing a tool (`structured_output = "tool"`, Bedrock's only mode) rejects `forced_tool_choice = false` the same way. Native Claude structured output requires `additionalProperties: false` on every object in the schema; an open object is rejected with its path.

Legacy forms remain supported through the normalizer:

| Legacy form | Canonical form / behavior |
|---|---|
| Route `options.reasoning_model_request = true` | Only on a route whose driver declares it owns this flag (OpenAI, OpenAI-compatible): `thinking: adaptive`, `sampling: false`; false, absent, or a driver that does not declare it derives nothing |
| Route `options.model_profile.thinking_mode = adaptive_only` | `thinking: adaptive` only |
| Route `options.model_profile.forced_tool_choice` | `forced_tool_choice`, preserving both true and false |
| Route `options.model_profile.structured_output_mode = native` | `structured_output: native` |
| Caller `reasoning_model_request = true` | Same driver-declares-it rule as the route form; when it applies, derives adaptive thinking and no sampling unless canonically declared on the route |
| Direct caller `model_profile` | Same legacy mappings; direct caller `accepts` wins |
| Connection keys in route `options` | Still supported; use route `context` for new configuration |

`reasoning_model_request` is a legacy flag owned by the driver that historically read it: a driver's `contract.binding` entry declares `meta.legacy_reasoning_flag: true` (OpenAI, OpenAI-compatible) to opt in. A route or provider entry bound to any other driver (Claude, Bedrock, Google, or a custom driver that never declared it) ignores the flag entirely; the request behaves exactly as if it were absent.

Provider open context composition is unchanged: provider entry `driver.options`, then route `context`, then route `options`. Request defaults come from route `options`, with caller options on top. Timeout and retry retain their existing transport handling. Embed and evaluate paths do not normalize route facts.

### Retry

Drivers retry transient failures (connection errors, 408, 409, 425, 429, 5xx) with exponential backoff before any response body is read, so a streamed response is never replayed. Health probes (`status`) always send a single request.

```lua
llm.generate(builder, {
    model = "claude",
    retry = { attempts = 3, backoff_ms = 500 }  -- retries after the first attempt; backoff doubles each time
})
```

A per-call `retry` replaces the provider policy, which is set in the provider entry's `driver.options.retry` or in a resolved provider's `context` and reaches the driver through its context. `attempts` is capped at 10 and `backoff_ms` at 60000.

Retries stay on one route. Moving to other routes and models is [Fallback](#fallback); a call's `deadline_ms` also stops a retry whose backoff would end past the deadline.

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

## Typed evaluation

`llm.evaluate(state, questions, options)` asks a model to assess a string or JSON-compatible state against independent named questions. It returns model-estimated probabilities, not generated text or a new application state. Your code chooses thresholds, validates business rules, and takes actions. `choice` is categorical, `predicate` is a probability that a statement holds, and `score` is an ordinal rubric (not an arbitrary numeric/reward score).

```lua
local result, err = llm.evaluate(conversation, {
    intent = {
        type = "choice",
        instructions = "Which queue owns this conversation",
        domain = {
            billing = "Payments, refunds and invoices",
            technical = "Bugs, outages and integrations",
            other = "None of these"
        }
    },
    resolved = {
        type = "predicate",
        instructions = "The customer considers the issue closed"
    },
    mood = {
        type = "score",
        instructions = "Emotional temperature of the customer",
        domain = {"calm", "frustrated", "angry"}
    }
}, {model = "jev"})
```

`state` is input context, not a state-machine state. The model sees every question against that same context; answers are not a joint distribution or a guaranteed consistent assignment. Slot keys are caller identifiers and are never shown to the model. A `choice` domain is an array of unique option names or a map of option to description; include `other` when none may fit. A `score` domain is an ordered array of at least two level descriptions; a `predicate` domain is optional and describes the `yes` and `no` outcomes. A predicate is not a boolean: apply a domain-specific threshold in code.

### Readings

```lua
-- result.result structure:
{
    intent = {
        type = "choice",
        choice = "technical",
        probabilities = {billing = 0.08, technical = 0.85, other = 0.07},
        confidence = 0.82   -- provider-specific certainty statistic, if supplied
    },
    resolved = {
        type = "predicate",
        probability = 0.92
    },
    mood = {
        type = "score",
        score = 2.6,                       -- expected 1-based level index, NOT a physical quantity
        level = 3,                         -- 1-based index of the highest-probability level
        probabilities = {0.05, 0.3, 0.65}, -- aligned with the declared domain
        confidence = 0.78                 -- not interchangeable across providers
    }
}
```

`result.result` holds the readings; the raw evaluator contract uses `result.readings`. Preserve the full distributions: an expected ordinal score can hide ambiguity between very different levels. Confidence is a provider-defined statistic derived from a distribution; do not transfer a confidence threshold between models without evaluation. Calibration is an empirical property of a model on your own data, not guaranteed by this contract.

### Registering an evaluation model

```yaml
entries:
  - name: jev
    kind: registry.entry
    meta:
      type: llm.model
      name: jev
      title: Jev (System One)
      class: [evaluate]
      capabilities: [evaluate]
      priority: 100
    providers:
      - id: wippy.llm.typesafe:provider
        provider_model: jev-latest
```

The module ships the `wippy.llm.typesafe:provider` entry bound to its driver and credential variables. Driver env vars: `TYPESAFE_API_KEY`, `TYPESAFE_BASE_URL` (default `https://api.typesafe.ai/v1`), `TYPESAFE_TIMEOUT`.

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
    EVALUATE = "evaluate",
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
    CONTENT_FILTER = "content_filtered",
    TIMEOUT = "timeout_error",
    MODEL_ERROR = "model_error",
    NETWORK_ERROR = "network_error"
}
```

These are the types drivers report (`output.ERROR_TYPE`). A driver error keeps its type in `details.error_type`, which fallback decisions use; the stdlib error kind alone cannot tell `context_length_exceeded`, `content_filtered` and `invalid_request` apart.

## Registering Models

The entry keeps metadata, limits, pricing and a `providers` list. Routes are tried by descending `priority` when a call fails (see [Fallback](#fallback)); a single route behaves as before. Put connection and transport settings (API keys, base URL, timeout, retry, headers) in `context`, and request defaults in `options`.

```yaml
entries:
  - name: claude-sonnet
    kind: registry.entry
    meta:
      type: llm.model
      name: claude-sonnet
      title: Claude Sonnet 5
      class: [fast, chat]
      capabilities: [generate, tool_use, vision, thinking, caching]
      priority: 100
    providers:
      - id: wippy.llm.claude:provider
        provider_model: claude-sonnet-5
        thinking: adaptive
        sampling: false
        forced_tool_choice: true
        structured_output: native
        context:
          timeout: 120
        options:
          thinking_effort: 40
    max_tokens: 1000000
    output_tokens: 128000
    pricing: { input: 2, output: 10 }
```

Additional model entries can use these routes with the same top-level structure. Limits and pricing should reflect your provider's current offering.

```yaml
# Claude Opus 5.5
providers:
  - id: wippy.llm.claude:provider
    provider_model: claude-opus-5-5
    thinking: adaptive
    sampling: false
    forced_tool_choice: false
    structured_output: native
    options:
      thinking_effort: 60
```

```yaml
# Claude Haiku 4.5: absent facts retain the driver's budget-thinking defaults
providers:
  - id: wippy.llm.claude:provider
    provider_model: claude-haiku-4-5-20251001
    options:
      temperature: 0.7
```

```yaml
# OpenAI reasoning model
providers:
  - id: wippy.llm.openai:provider
    provider_model: gpt-5-mini
    thinking: adaptive
    sampling: false
    options:
      thinking_effort: 50
```

```yaml
# Claude via Bedrock, using an inference profile
providers:
  - id: wippy.llm.bedrock:provider
    provider_model: us.anthropic.claude-sonnet-4-6
    thinking: adaptive
    sampling: true
    context:
      timeout: 120
      retry: { attempts: 3 }
    options:
      thinking_effort: 50
```

The reserved route keys are `id`, `provider_model`, `context`, `options`, `priority`, and the four facts above. Custom model resolvers return the same card and route structure.

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

## Fallback

When a call fails, it can move on to other routes and models. The candidates of a call are:

1. The routes of the resolved card, by descending `priority`. A route without one counts as 0 and equal priorities keep list order. These serve the same model through other endpoints.
2. The routes of each model in the card's `fallback` list, in order. A reference is a model name or `class:<name>` (the top model of that class). It is resolved only when the chain reaches it, through the bound model resolver if there is one. A card is tried once, and the `fallback` list of a fallback card is not followed. At most 4 candidates are tried per call.

```yaml
- name: claude-sonnet-4-6
  kind: registry.entry
  meta:
    type: llm.model
    name: claude-sonnet-4-6
    class: [balanced]
    capabilities: [generate, tool_use, vision, structured_output]
    priority: 100
  providers:
    - id: wippy.llm.claude:provider
      provider_model: claude-sonnet-4-6
      priority: 100
    - id: wippy.llm.bedrock:provider          # the same model through another endpoint
      provider_model: us.anthropic.claude-sonnet-4-6
      priority: 50
  fallback: [gemini-pro, class:fast]          # other models, in order
  fallback_on: [rate_limit_exceeded, server_error, timeout_error, network_error]
```

Whether a failure moves the call on depends on its error type and on the candidate:

| Error type | First candidate | Later candidates |
|---|---|---|
| `rate_limit_exceeded`, `server_error`, `timeout_error`, `network_error` | next (the default `fallback_on`) | next |
| `authentication_error`, `model_error`, `context_length_exceeded` | next only when listed in `fallback_on` | next |
| `invalid_request`, `content_filtered` | next only when listed in `fallback_on` | stop |
| an error without a type | stop | stop |

`fallback_on` replaces the default set only when it names at least one type; an empty list counts as unset.

A candidate's own transport retries run before the call moves on. A later candidate whose provider cannot be opened, or whose route facts reject the call, is skipped; on the first candidate these errors fail the call as before. Every candidate is called with its own route `context`, `provider_model`, route `options` under the caller's options, and route facts. Nothing carries over from a previous candidate. A `max_tokens` above the candidate card's `output_tokens` is lowered to that limit and reported in `metadata.adjusted.max_tokens` as `requested` and `sent`; with `strict = true` the candidate rejects the call instead, like any other adjustment. A card without `output_tokens` sets no limit.

A streamed call moves on only while the client has received nothing, which the driver reports as `stream_started = false` in the error details. After the first chunk an error never moves the call on. While nothing has been sent, the framework drivers hold the stream's error chunk back; `llm` sends it if the whole call fails, so a call without fallback streams exactly as before. A driver that does not report `stream_started` never falls back while streaming. Drivers built on `output` use `output.send_or_defer_error` and `output.stream_error_details` for this.

Embeddings move only between the routes of the resolved card, because vectors of different models are not compatible. Evaluation skips fallback models that do not declare the `evaluate` capability. `llm.status` and calls with an explicit `provider_id` do not fall back; `route` together with `provider_id` is rejected, because a direct call bypasses the catalog the pin refers to.

Per-call options, never sent to the driver:

```lua
llm.generate(builder, {
    model = "claude",
    fallback = { "gpt-5" },   -- replaces the card's list; false disables fallback, other routes included
    deadline_ms = 60000       -- budget for the whole call
})

-- Exactly one route and no chain, e.g. to stay on the model that answered an earlier step
llm.generate(builder, { model = "claude", route = earlier_result.metadata.route })
```

`deadline_ms` caps each request timeout to the remaining budget, stops transport retries that would end past it, and does not start a fallback candidate with less than 5 seconds left.

A successful resolved call reports the answering route in `metadata.route` (`model`, `provider_id`, `provider_model`). Earlier failures are listed in `metadata.fallbacks`: `model`, `provider_id`, `provider_model`, then `error_type` and `message`, or `skipped = true` and `message`. Usage is tracked under the model that answered. A failed chain returns the last error message followed by the candidates that were tried.

## Providers

- `wippy.llm.claude` - Anthropic Claude (direct API)
- `wippy.llm.bedrock` - AWS Bedrock (Converse API for text generation, InvokeModel for embeddings)
- `wippy.llm.openai` - OpenAI native via the Responses API (`/v1/responses`) — GPT-5.x, o-series, encrypted reasoning persistence, `xhigh`/`minimal` reasoning effort. Use this for `api.openai.com`.
- `wippy.llm.openai_compat` - OpenAI-compatible Chat Completions (`/v1/chat/completions`) — Ollama, vLLM, llama.cpp, LM Studio, OpenRouter, Together, Groq, Fireworks, DeepInfra, Mistral, DeepSeek, etc. Use this for any non-OpenAI backend that exposes a `/chat/completions` endpoint.
- `wippy.llm.google.vertex` - Google Vertex AI
- `wippy.llm.google.generative_ai` - Google Generative AI (Gemini)

### Environment Variables

```
# Claude
ANTHROPIC_API_KEY
ANTHROPIC_API_VERSION       # default: 2023-06-01
ANTHROPIC_BASE_URL          # default: https://api.anthropic.com
ANTHROPIC_TIMEOUT           # default: 240

# OpenAI (Responses API — wippy.llm.openai)
OPENAI_API_KEY
OPENAI_ORGANIZATION
OPENAI_BASE_URL             # default: https://api.openai.com/v1
OPENAI_TIMEOUT              # default: 600

# OpenAI-compatible (Chat Completions — wippy.llm.openai_compat)
OPENAI_COMPAT_API_KEY       # may be unused for local Ollama
OPENAI_COMPAT_BASE_URL      # e.g. http://localhost:11434/v1 for Ollama
OPENAI_COMPAT_ORGANIZATION
OPENAI_COMPAT_TIMEOUT       # default: 600

# AWS Bedrock
AWS_ACCESS_KEY_ID           # optional, for local dev
AWS_SECRET_ACCESS_KEY       # optional, for local dev
AWS_SESSION_TOKEN           # optional, for temporary credentials
AWS_REGION                  # default: us-east-1
BEDROCK_BASE_URL            # override endpoint
BEDROCK_TIMEOUT             # default: 600

# Google
GOOGLE_CREDENTIALS          # service account JSON
GOOGLE_API_KEY              # for Generative AI
```

The two OpenAI providers use independent env vars so you can run real OpenAI (`wippy.llm.openai`) and a local model (`wippy.llm.openai_compat`) side by side without conflicts.

In ECS/EKS pods, AWS credentials are resolved automatically from the container metadata endpoint. No env vars needed in production.

## Contracts

- `wippy.llm:generator` - Text generation with tool calling
- `wippy.llm:embedder` - Embedding generation
- `wippy.llm:evaluator` - Typed probabilistic evaluations
- `wippy.llm:structured_output` - Schema-constrained generation
- `wippy.llm:provider` - Provider health status
- `wippy.llm:usage_tracker` - Token usage tracking

## Subnamespaces

- `wippy.llm.claude` - Claude provider (direct API)
- `wippy.llm.bedrock` - AWS Bedrock provider
- `wippy.llm.openai` - OpenAI native (Responses API)
- `wippy.llm.openai_compat` - OpenAI-compatible (Chat Completions) for Ollama / vLLM / OpenRouter / Together / Groq / etc.
- `wippy.llm.google` - Google providers (Vertex AI, Generative AI)
- `wippy.llm.typesafe` - TypeSafe Jev evaluation provider
- `wippy.llm.discovery` - Model and provider discovery
- `wippy.llm.util` - Utilities (text compression)
- `wippy.llm.env` - Environment configuration
