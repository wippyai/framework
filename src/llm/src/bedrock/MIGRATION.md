# Migrating to the New Bedrock Provider

The Bedrock provider has moved from `wippy.llm.claude.bedrock` to `wippy.llm.bedrock` as a standalone module. It now uses the AWS Converse API for text generation (supporting all Bedrock text models, not just Claude) and adds native embedding support via InvokeModel for Amazon Titan and Cohere Embed models.

## TL;DR

- **Namespace changed**: `wippy.llm.claude.bedrock` → `wippy.llm.bedrock`
- **Text generation now uses Converse API** (not Claude's Messages API via InvokeModel)
- **Works with any Bedrock text model**: Claude, Llama, Mistral, Nova, Cohere Command, DeepSeek, etc.
- **Embeddings now supported**: Titan Embed v1/v2, Cohere Embed v3/v4
- **Same environment variables, same SigV4 authentication, same IAM permissions**

## Migration Steps

### 1. Update model YAML configurations

Replace the provider ID in your model entries:

```yaml
# Before
providers:
  - id: wippy.llm.claude.bedrock:provider
    provider_model: us.anthropic.claude-haiku-4-5-20251001-v1:0

# After
providers:
  - id: wippy.llm.bedrock:provider
    provider_model: us.anthropic.claude-haiku-4-5-20251001-v1:0
```

The `provider_model` values stay the same — they are AWS model IDs.

### 2. Update direct `provider_id` calls in code

If you invoke providers directly by ID in `llm.generate()` / `llm.structured_output()` / `llm.embed()`, update the string:

```lua
-- Before
local result, err = llm.generate(messages, {
    provider_id = "wippy.llm.claude.bedrock:provider",
    model = "us.anthropic.claude-haiku-4-5-20251001-v1:0",
})

-- After
local result, err = llm.generate(messages, {
    provider_id = "wippy.llm.bedrock:provider",
    model = "us.anthropic.claude-haiku-4-5-20251001-v1:0",
})
```

### 3. Environment variables stay the same

No changes needed:

```
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_SESSION_TOKEN=...   # optional, for temporary credentials
BEDROCK_BASE_URL=...    # optional
BEDROCK_TIMEOUT=...     # optional, default 600 seconds
```

EC2 IMDS and ECS/EKS container credentials still work the same way. The credential refresher service is the same.

## New Capabilities

### Non-Claude text models

With the Converse API, you can now use any Bedrock text model through the same provider. Example with Llama:

```yaml
- name: llama-4-maverick
  kind: registry.entry
  meta:
    name: llama-4-maverick
    type: llm.model
    capabilities: [tool_use, generate]
    class: [open-source]
    priority: 50
  providers:
    - id: wippy.llm.bedrock:provider
      provider_model: meta.llama4-maverick-17b-instruct-v1:0
```

The contract interface is unchanged — tool calls, streaming, thinking, structured output all work the same way regardless of the underlying model family.

### Embeddings

Two families are supported, detected automatically from the model ID prefix.

**Amazon Titan** (model IDs starting with `amazon.titan-embed-`):

```yaml
- name: titan-embed-text-v2
  kind: registry.entry
  meta:
    name: titan-embed-text-v2
    type: llm.model
    capabilities: [embed]
    class: [embedding]
    priority: 8
  max_tokens: 8192
  dimensions: 1024
  providers:
    - id: wippy.llm.bedrock:provider
      provider_model: amazon.titan-embed-text-v2:0
```

Titan takes one text per request — batches are transparently sent as sequential calls. Supports `dimensions` option (256/512/1024).

**Cohere** (model IDs starting with `cohere.embed`):

```yaml
- name: cohere-embed-v4
  kind: registry.entry
  meta:
    name: cohere-embed-v4
    type: llm.model
    capabilities: [embed]
    class: [embedding]
    priority: 12
  max_tokens: 128000
  dimensions: 1536
  providers:
    - id: wippy.llm.bedrock:provider
      provider_model: cohere.embed-v4:0
```

Cohere batches up to 96 texts per request natively. Supports `dimensions` option (maps to `output_dimension` for v4; ignored by v3 which is fixed at 1024). The `input_type` defaults to `search_document` and can be overridden via options:

```lua
local result, err = llm.embed("search query", {
    model = "cohere-embed-v4",
    options = { input_type = "search_query" }
})
```

## Behavioral Differences

### Text generation — mostly transparent

The contract format (messages, tools, options) is identical. The mapper translates to Converse API format internally. For Claude models, all features still work:

- Tool calling (`toolConfig` in Converse)
- Extended thinking (`additionalModelRequestFields.thinking` in Converse)
- Prompt caching (`cachePoint` blocks in Converse)
- Vision/images
- Streaming (ConverseStream with binary eventstream)

### Streaming

The wire protocol is slightly different — ConverseStream uses the same binary eventstream format as InvokeModel streaming, but the event types are named differently (camelCase `contentBlockDelta` vs snake_case `content_block_delta`). This is handled internally — your streaming consumers see no difference.

### Error responses

The error handling is unchanged. HTTP status codes map to contract error types the same way.

## Tested Model Compatibility

The following was verified against real AWS Bedrock in `us-east-1`:

### Text Generation (Converse API)

| Model | Generate | Tool Calling | Structured Output | Thinking |
|-------|----------|--------------|-------------------|----------|
| Claude Haiku 4.5 | ✅ | ✅ | ✅ | ✅ |
| Claude Sonnet 4.5 | ✅ | ✅ | ✅ | ✅ |
| Claude Sonnet 4.6 | ✅ | ✅ | ✅ | ✅ |
| Claude 3.5 Haiku | ✅ | ✅ | ✅ | ❌ (model) |
| Llama 4 Scout | ✅ | ✅ | ✅ | ❌ (model) |
| Llama 4 Maverick | ✅ | ✅ | ✅ | ❌ (model) |
| Llama 3.3 70B | ✅ | ⚠️ see notes | ❌ | ❌ (model) |
| DeepSeek R1 | ✅ | ❌ (model) | ❌ | native (in text) |
| Mistral Pixtral Large | ✅ | ✅ | ⚠️ see notes | ❌ (model) |
| Nova Micro | ✅ | ✅ | ✅ | ❌ (model) |
| Nova Lite | ✅ | ✅ | ✅ | ❌ (model) |
| Nova Pro | ✅ | ✅ | ✅ | ❌ (model) |

### Embeddings (InvokeModel)

| Model | Batch | Custom Dimensions |
|-------|-------|-------------------|
| `amazon.titan-embed-text-v1` | sequential | fixed 1536 |
| `amazon.titan-embed-text-v2:0` | sequential | 256 / 512 / 1024 |
| `cohere.embed-english-v3` | native (≤96) | fixed 1024 |
| `cohere.embed-multilingual-v3` | native (≤96) | fixed 1024 |
| `cohere.embed-v4:0` / `us.cohere.embed-v4:0` | native (≤96) | 256 / 512 / 1024 / 1536 |

Cross-region inference profile prefixes (`us.`, `global.`, `eu.`) are supported for embedding model IDs — detected by substring match, not anchored.

### Known AWS Bedrock Model Limitations

These are AWS/model-side limitations, not framework bugs:

- **Llama 3.3 70B on Bedrock** returns tool calls as plain-text JSON inside a `text` content block, not as a proper `toolUse` block. Use Llama 4 Scout or Maverick if you need tool calling on an open-source model.
- **Mistral Pixtral Large** supports tool calling but rejects `toolChoice.tool` (forced specific tool selection) with a `ValidationException`. This means `structured_output` fails on Mistral Pixtral — the handler uses forced tool choice to guarantee schema adherence. Use a different model for structured output.
- **DeepSeek R1** does not support tool calling via Converse API. Use for pure text generation only. Its native reasoning appears inside the regular text output.
- **Non-Claude models** do not support the `thinking_effort` contract option. The parameter maps to `additionalModelRequestFields.thinking` which will be ignored or error on non-Claude models.

### Features Verified End-to-End

- SigV4 request signing
- Converse API for text generation (all 12 model families listed above)
- ConverseStream (binary eventstream with `:event-type` header parsing)
- Tool calling with `toolConfig`
- Forced tool choice (structured output)
- Extended thinking via `additionalModelRequestFields.thinking` (Claude)
- `inferenceConfig` parameters: `maxTokens`, `temperature`, `topP`, `stopSequences`
- Error mapping (400, 401, 403, 404, 429, 500)
- Cross-region inference profile model IDs

## What Stayed the Same

- SigV4 request signing
- AWS credential resolution chain (env vars → cache → ECS/EKS metadata → EC2 IMDS)
- Credential refresher background service
- Timeout configuration
- Environment variable names
- Contract interface (messages, tools, options, response format)

## Provider Entry Reference

Single provider, multiple contracts:

```
wippy.llm.bedrock:provider
├── wippy.llm:generator         → generate.lua (Converse API)
├── wippy.llm:structured_output → structured_output.lua (Converse API + tool use)
├── wippy.llm:embedder          → embed.lua (InvokeModel + Titan/Cohere adapters)
└── wippy.llm:provider          → status.lua (health check via Converse)
```

## Rollback

If you need to temporarily pin to the old namespace, the `feature/bedrock-provider` branch replaces `claude/bedrock/` entirely — there is no compatibility shim. Rolling back means reverting the merge commit. Model YAMLs that reference `wippy.llm.claude.bedrock:provider` will fail to resolve after the merge, so update them as part of the upgrade.
