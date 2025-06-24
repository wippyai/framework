# LLM Library Specification and Usage Guide

This document specifies the standard input and output formats for the LLM functions in our system, as well as providing practical examples of how to use the library.

## 1. Overview

The LLM library provides a unified interface for working with large language models from various providers (OpenAI, Anthropic, Google, etc.). Key features include:

- Text generation with various models
- Tool/function calling capabilities
- Structured output generation
- Embedding generation
- Model discovery and capability filtering

## 2. Basic Text Generation

### Example: Simple String Prompt

```lua
local llm = require("llm")

-- Generate text with a simple string prompt
local response = llm.generate("What are the three laws of robotics?", {
    model = "gpt-4o"
})

-- Access the response content
print(response.result)

-- Access token usage information
print("Used " .. response.tokens.total_tokens .. " tokens")
```

### Example: Using Prompt Builder

```lua
local llm = require("llm")
local prompt = require("prompt")

-- Create a prompt builder for more complex prompts
local builder = prompt.new()
builder:add_system("You are a helpful AI assistant specializing in physics.")
builder:add_user("Explain how black holes work in simple terms.")

-- Generate text using the prompt builder
local response = llm.generate(builder, {
    model = "claude-3-5-haiku",
    temperature = 0.7,
    max_tokens = 500
})

print(response.result)
```

## 3. Prompt Builder Usage

The prompt builder provides a flexible way to construct complex prompts with different message types:

```lua
local prompt = require("prompt")

-- Create a new prompt builder
local builder = prompt.new()

-- Add system message (instructions for the model)
builder:add_system("You are an expert programmer specializing in Lua.")

-- Add user message (the query or instruction)
builder:add_user("Write a function to calculate Fibonacci numbers recursively.")

-- Add previous assistant message (for conversation context)
builder:add_assistant("Here's a simple recursive implementation of the Fibonacci function:")

-- Add developer message (instructions that won't be shown to end users)
builder:add_developer("Include detailed comments and optimize for readability.")

-- Add a message with custom role and content
builder:add_message(
    prompt.ROLE.USER,
    {
        {
            type = "text",
            text = "How can I make this more efficient?"
        }
    }
)

-- Add a message with an image (for multimodal models)
builder:add_message(
    prompt.ROLE.USER,
    {
        prompt.text("What's in this image?"),
        prompt.image("https://example.com/image.jpg", "A diagram")
    }
)

-- Get all messages from the builder
local messages = builder:get_messages()

-- Use the builder with the LLM library
local response = llm.generate(builder, { model = "gpt-4o" })
```

## 4. Tool Calling

Tools allow the model to call functions to access external data or perform operations.

### Example: Weather Tool

```lua
local llm = require("llm")
local prompt = require("prompt")

-- Create a prompt
local builder = prompt.new()
builder:add_user("What's the weather in Tokyo right now?")

-- Generate with tool access
local response = llm.generate(builder, {
    model = "gpt-4o",
    tool_ids = { "system:weather" },  -- Reference to pre-registered tools
    temperature = 0
})

-- Check if there are tool calls in the response
if response.tool_calls then
    for _, tool_call in ipairs(response.tool_calls) do
        print("Tool: " .. tool_call.name)
        print("Arguments: " .. require("json").encode(tool_call.arguments))
        
        -- Here you would handle the tool call by executing the actual function
        -- and then continue the conversation with the result
    end
end
```

### Example: Custom Tool Schema

```lua
local llm = require("llm")

-- Define a calculator tool schema
local calculator_tool = {
    name = "calculate",
    description = "Perform mathematical calculations",
    schema = {
        type = "object",
        properties = {
            expression = {
                type = "string",
                description = "The mathematical expression to evaluate"
            }
        },
        required = { "expression" }
    }
}

-- Generate with custom tool schema
local response = llm.generate("What is 125 * 16?", {
    model = "claude-3-5-haiku",
    tool_schemas = {
        ["test:calculator"] = calculator_tool
    }
})
```

## 5. Structured Output

Generate JSON-structured responses directly with a defined schema.

**Important Note for OpenAI Models:**
For OpenAI models, all properties must be included in the `required` array, even if they are conceptually optional. For optional parameters, you should use a union type combining the actual type with "null", for example: `type = {"string", "null"}`. Additionally, `additionalProperties = false` is mandatory for OpenAI schemas.

### Example: Weather Schema

```lua
local llm = require("llm")

-- Define a weather information schema
local weather_schema = {
    type = "object",
    properties = {
        temperature = {
            type = "number",
            description = "Temperature in celsius"
        },
        condition = {
            type = "string",
            description = "Weather condition (sunny, cloudy, rainy, etc.)"
        },
        humidity = {
            type = {"number", "null"},
            description = "Humidity percentage (if available)"
        },
    },
    required = { "temperature", "condition", "humidity" },
    additionalProperties = false
}

-- Generate structured output
local response = llm.structured_output(
    weather_schema, 
    "What's the weather like today in New York?", 
    { model = "gpt-4o" }
)

-- Access structured data directly
print("Temperature: " .. response.result.temperature)
print("Condition: " .. response.result.condition)
if response.result.humidity ~= nil then
    print("Humidity: " .. response.result.humidity .. "%")
end
```

## 6. Generating Embeddings

Embeddings represent text as vectors for semantic search and analysis.

### Example: Single Text Embedding

```lua
local llm = require("llm")

-- Generate an embedding for a single text
local text = "The quick brown fox jumps over the lazy dog."
local response = llm.embed(text, {
    model = "text-embedding-3-large"
})

-- Access the embedding vector
print("Vector dimensions: " .. #response.result)
print("First few values: " .. table.concat({
    response.result[1],
    response.result[2],
    response.result[3]
}, ", "))
```

### Example: Multiple Text Embeddings

```lua
local llm = require("llm")

-- Generate embeddings for multiple texts
local texts = {
    "The quick brown fox jumps over the lazy dog.",
    "Machine learning is a subfield of artificial intelligence."
}

local response = llm.embed(texts, {
    model = "text-embedding-3-large",
    dimensions = 1536  -- Optionally specify dimensions
})

-- Access the embedding vectors
print("Number of embeddings: " .. #response.result)
print("Dimensions of first embedding: " .. #response.result[1])
```

## 7. Model Discovery

Find and filter available models based on capabilities.

### Example: Listing Available Models

```lua
local llm = require("llm")

-- Get all available models
local all_models = llm.available_models()
print("Total models: " .. #all_models)

-- Get models with specific capabilities
local generate_models = llm.available_models(llm.CAPABILITY.GENERATE)
local tool_models = llm.available_models(llm.CAPABILITY.TOOL_USE)
local embed_models = llm.available_models(llm.CAPABILITY.EMBED)

print("Models supporting generation: " .. #generate_models)
print("Models supporting tool use: " .. #tool_models)
print("Models supporting embeddings: " .. #embed_models)

-- Get models grouped by provider
local providers = llm.models_by_provider()
for provider_name, provider in pairs(providers) do
    print(provider_name .. ": " .. #provider.models .. " models")
end
```

### Error Types

The LLM library defines the following error types:

```lua
llm.ERROR_TYPE = {
    INVALID_REQUEST = "invalid_request",       -- Malformed request or invalid parameters
    AUTHENTICATION = "authentication_error",   -- Invalid API key or authentication failed
    RATE_LIMIT = "rate_limit_exceeded",        -- Provider rate limit exceeded
    SERVER_ERROR = "server_error",             -- Provider server error
    CONTEXT_LENGTH = "context_length_exceeded", -- Input exceeds model's context length
    CONTENT_FILTER = "content_filter",         -- Content filtered by provider safety systems
    TIMEOUT = "timeout_error",                 -- Request timed out
    MODEL_ERROR = "model_error"                -- Invalid model or model unavailable
}
```

### Finish/Stop Reason Types

Text generation uses these finish reason constants:

```lua
llm.FINISH_REASON = {
    STOP = "stop",               -- Normal completion
    LENGTH = "length",           -- Reached max tokens
    CONTENT_FILTER = "filtered", -- Content filtered by provider
    TOOL_CALL = "tool_call",     -- Model made a tool/function call
    ERROR = "error"              -- Other error
}
```

### Example: Error Handling Methods

```lua
local llm = require("llm")

-- Option 1: Using response.error
local response = llm.generate("Hello", {
    model = "nonexistent-model"
})

if response and response.error then
    print("Error type: " .. response.error)
    print("Error message: " .. response.error_message)
    
    -- Handle specific error types
    if response.error == llm.ERROR_TYPE.MODEL_ERROR then
        print("Invalid model specified")
    elseif response.error == llm.ERROR_TYPE.AUTHENTICATION then
        print("Authentication failed - check API key")
    elseif response.error == llm.ERROR_TYPE.CONTEXT_LENGTH then
        print("Input is too long for this model")
    end
end

-- Option 2: Using the second return value
local response, err = llm.generate("Hello", {
    model = "nonexistent-model"
})

if err then
    print("Error: " .. err)
else
    print(response.result)
end
```

## 9. Comprehensive Examples

### Complete Conversation Flow with Tools

This example demonstrates a complete conversation flow with tool calling:

```lua
local llm = require("llm")
local prompt = require("prompt")

-- Define a weather tool schema
local weather_tool = {
    name = "get_weather",
    description = "Get weather information for a location",
    schema = {
        type = "object",
        properties = {
            location = {
                type = "string",
                description = "The city or location"
            },
            units = {
                type = "string",
                enum = { "celsius", "fahrenheit" },
                default = "celsius"
            }
        },
        required = { "location" }
    }
}

-- Start a conversation
local builder = prompt.new()
builder:add_system("You are a helpful assistant that can answer questions and use tools.")
builder:add_user("What's the weather like in Paris today?")

-- First LLM call - expect a tool call
local response = llm.generate(builder, {
    model = "gpt-4o",
    tool_schemas = {
        ["weather:current"] = weather_tool
    }
})

-- Check for tool calls
if response.tool_calls and #response.tool_calls > 0 then
    local tool_call = response.tool_calls[1]
    
    -- Simulate executing the tool
    local tool_result = {
        temperature = 22,
        condition = "sunny",
        humidity = 65,
        wind_speed = 10
    }
    
    -- Add the tool call and result to the conversation
    builder:add_function_call(
        tool_call.name,
        tool_call.arguments,
        tool_call.id
    )
    
    builder:add_function_result(
        tool_call.name, 
        require("json").encode(tool_result),
        tool_call.id
    )
    
    -- Continue the conversation with the tool result
    local final_response = llm.generate(builder, {
        model = "gpt-4o"
    })
    
    print("Final response: " .. final_response.result)
end
```

### Using Different Model Capabilities

```lua
local llm = require("llm")
local prompt = require("prompt")

-- Create a prompt that requires reasoning
local builder = prompt.new()
builder:add_user("Solve this step by step: If a train travels at 60 mph for 2.5 hours, then slows down to 40 mph for 1.5 hours, what is the total distance traveled?")

-- Use Claude 3.7 with thinking capabilities
local response = llm.generate(builder, {
    model = "claude-3-7-sonnet",
    thinking_effort = 80,  -- High thinking effort (0-100)
    temperature = 0        -- Deterministic output
})

-- Access thinking process if available
if response.thinking then
    print("Thinking process: " .. response.thinking)
end

print("Answer: " .. response.result)

-- Token usage breakdown
print("Prompt tokens: " .. response.tokens.prompt_tokens)
print("Completion tokens: " .. response.tokens.completion_tokens)
print("Thinking tokens: " .. (response.tokens.thinking_tokens or 0))
print("Total tokens: " .. response.tokens.total_tokens)
```

### Using Local Models

```lua
local llm = require("llm")

-- Generate text using a locally hosted model
local response = llm.generate("Explain quantum computing in simple terms", {
    model = "local-QwQ-32B-Q4_K_M",  -- This model runs locally via LM Studio
    provider_options = {  -- Override default provider options if needed
        base_url = "http://localhost:5000/v1",  -- Custom endpoint
        api_key_env = "LOCAL_API_KEY"           -- Different API key variable
    }
})

print(response.result)
```

## 10. Input and Output Format Reference

### Generate Function Input Format

```lua
{
    -- Core parameters
    model = "claude-3-7-sonnet",          -- Required: The model to use
    
    -- Content can be:
    -- 1. A string prompt
    -- 2. A prompt builder object
    -- 3. A table of messages
    -- 4. Any object that has a get_messages() function
    
    -- Thinking capabilities (for models with thinking support)
    thinking_effort = 0,                  -- Optional: 0-100, for models with thinking capability
    
    -- Tool configuration (for tool calling only)
    tool_ids = {"system:weather", "tools:calculator"}, -- Optional: List of tool IDs to use
    tool_schemas = { ... },               -- Optional: Tool definitions matching tool_resolver format
    tool_call = "auto",                   -- Optional: "auto", "any", tool-name (forced)
    
    -- Streaming configuration
    stream = {                            -- Optional: For streaming responses
        reply_to = "process-id",          -- Required for streaming: Process ID to send chunks to
        topic = "llm_response",           -- Optional: Topic name for streaming messages
    },

    -- Provider override options (primarily for local models)
    provider_options = {                  -- Optional: Override model provider settings
        base_url = "http://localhost:1234/v1",  -- API endpoint for local models
        api_key_env = "OPENAI_API_KEY",         -- Environment variable for API key
        -- Any other provider-specific options
    },
    
    -- Generation parameters (model specific)
    temperature = 0.7,                    -- Optional: Controls randomness (0-1)
    top_p = 0.9,                          -- Optional: Nucleus sampling parameter
    top_k = 40,                           -- Optional: Top-k filtering
    max_tokens = 1024,                    -- Optional: Maximum tokens to generate
    -- Other provider-specific options
    
    timeout = 120                         -- Optional: Request timeout in seconds (default: 120)
}
```

### Generate Function Output Format

```lua
{
    -- Success case
    result = "Generated text response",    -- String: The generated text
    
    -- Tool calls (if the model made tool calls)
    tool_calls = {                         -- Table: Array of tool calls (if any)
        {
            id = "call_123",               -- String: Unique ID for this tool call
            name = "get_weather",          -- String: Name of the tool to call
            arguments = {                  -- Table: Arguments for the tool
                location = "New York",
                units = "celsius"
            }
        }
    },
    
    -- Token usage information
    tokens = {
        prompt_tokens = 56,                -- Number: Tokens used in the prompt
        completion_tokens = 142,           -- Number: Tokens generated in the response
        thinking_tokens = 25,              -- Number: Tokens used for reasoning (if applicable)
        cache_read_tokens = 0,             -- Number: Tokens read from cache
        cache_write_tokens = 0,            -- Number: Tokens written to cache
        total_tokens = 223                 -- Number: Total tokens used
    },
    
    -- Additional information
    metadata = {                           -- Table: Provider-specific metadata
        request_id = "req_123abc",
        processing_ms = 350,
        -- Other provider-specific metadata
    },
    
    -- Usage record
    usage_record = {                       -- Table: Usage tracking information
        user_id = "user123",
        model_id = "claude-3-7-sonnet",
        prompt_tokens = 56,
        completion_tokens = 142,
        -- Additional usage details
    },
    
    finish_reason = "stop",                -- String: Why generation stopped (stop, length, content_filter, tool_call)
    
    -- Error case (mutually exclusive with success case)
    error = "model_error",                 -- String: Error type constant from llm.ERROR_TYPE
    error_message = "Model not found",     -- String: Human-readable error message
}
```

### Embeddings Function Input Format

```lua
{
    -- Required parameters
    model = "text-embedding-3-large",      -- String: The embedding model to use
    input = "Text to embed",               -- String, Array of strings, or Table with string values    
    
    dimensions = 1536,                     -- Number: Dimensions for the embedding output (model-specific)
    
    timeout = 60,                           -- Number: Request timeout in seconds (default: 60)
    
    -- Provider override options (if needed)
    provider_options = {                  -- Optional: Override model provider settings
        base_url = "http://localhost:1234/v1",
        api_key_env = "OPENAI_API_KEY",
    },
}
```

### Embeddings Function Output Format

```lua
{
    -- Success case (for both single input and multiple inputs)
    result = {                             -- Float array or array of float arrays
        -- For single input: A vector of floats
        [1] = 0.0023,
        [2] = -0.0075,
        -- ... more dimensions
        
        -- For multiple inputs: An array of vectors
        -- [1] = {0.0023, -0.0075, ...},
        -- [2] = {0.0118, 0.0240, ...},
    },
    
    -- Token usage information
    tokens = {
        prompt_tokens = 8,                 -- Number: Tokens used for the input text
        total_tokens = 8                   -- Number: Equal to prompt_tokens for embeddings
    },
    
    -- Additional metadata (if provided by the API)
    metadata = {
        request_id = "req_abc123",         -- String: Provider-specific request identifier
        processing_ms = 45,                -- Number: Processing time in milliseconds
    },
    
    -- Error case (mutually exclusive with success case)
    error = "model_error",                 -- String: Error type constant from llm.ERROR_TYPE
    error_message = "Model not found"      -- String: Human-readable error message
}
```

## 11. Config File Example

The LLM models are defined in a YAML configuration file. Here's an example of how a model is configured:

```yaml
entries:
  - name: claude-3-7-sonnet
    kind: registry.entry
    meta:
      name: claude-3-7-sonnet
      type: llm.model
      title: Claude 3.7 Sonnet
      comment: Anthropic's most intelligent model with extended thinking capabilities
      capabilities:
        - tool_use
        - vision
        - thinking
        - caching
        - generate
    max_tokens: 200000
    handlers:
      call_tools: wippy.llm.claude:tool_calling
      generate: wippy.llm.claude:text_generation
      structured_output: wippy.llm.claude:structured_output
    output_tokens: 8192
    pricing:
      input: 3
      output: 15
    provider_model: claude-3-7-sonnet-20250219
    
  - name: local-QwQ-32B-Q4_K_M
    kind: registry.entry
    meta:
      name: local-QwQ-32B-Q4_K_M
      type: llm.model
      title: 'Local: QwQ-32B'
      comment: Locally hosted LM Studio model (QwQ-32B, 32 billion parameter model)
      capabilities:
        - generate
        - tool_use
    max_tokens: 4096
    handlers:
      call_tools: wippy.llm.openai:tool_calling
      generate: wippy.llm.openai:text_generation
      structured_output: wippy.llm.openai:structured_output
    output_tokens: 4096
    pricing:
      cached_input: 0
      input: 0
      output: 0
    provider_model: qwq-32b
    provider_options:
      base_url: http://localhost:1234/v1
      api_key_env: OPENAI_API_KEY
```

For local models, the `provider_options` field is particularly important as it specifies how to connect to the locally running model server.