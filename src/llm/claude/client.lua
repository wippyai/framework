local http_client = require("http_client")
local env = require("env")
local json = require("json")
local time = require("time")
local output = require("output")
local ctx = require("ctx")

-- Claude Client Library (Refactored to match OpenAI style)
local claude = {}

-- Constants for API paths
claude.API_URL = "https://api.anthropic.com"
claude.API_VERSION = "2023-06-01" -- The API version is required for all Claude API requests
claude.API_ENDPOINTS = {
    MESSAGES = "/v1/messages"
}
claude.DEFAULT_MAX_TOKENS = 2000
claude.DEFAULT_THINKING_BUDGET = 1024
claude.MAX_THINKING_BUDGET = 24000 -- Maximum thinking budget for 100% thinking effort
claude.DEFAULT_API_KEY_ENV = "ANTHROPIC_API_KEY"

-- Map Claude finish reasons to standardized finish reasons
claude.FINISH_REASON_MAP = {
    ["end_turn"] = output.FINISH_REASON.STOP,
    ["max_tokens"] = output.FINISH_REASON.LENGTH,
    ["stop_sequence"] = output.FINISH_REASON.STOP,
    ["tool_use"] = output.FINISH_REASON.TOOL_CALL
}

-- Calculate thinking budget based on thinking effort (0-100)
function claude.calculate_thinking_budget(effort)
    if not effort or effort <= 0 then
        return 0 -- No thinking
    end

    -- Scale the thinking budget linearly from minimum (1024) to maximum (24000)
    local scaled_budget = 1024 + (claude.MAX_THINKING_BUDGET - 1024) * (effort / 100)

    -- Round to the nearest integer
    return math.floor(scaled_budget + 0.5)
end

-- Error type mapping function for Claude errors
function claude.map_error(err)
    if not err then
        return {
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "Unknown error (nil error object)"
        }
    end

    -- Default to server error unless we determine otherwise
    local error_type = output.ERROR_TYPE.SERVER_ERROR

    -- Special cases for common error types based on status code
    if err.status_code == 401 then
        error_type = output.ERROR_TYPE.AUTHENTICATION
    elseif err.status_code == 404 then
        error_type = output.ERROR_TYPE.MODEL_ERROR
    elseif err.status_code == 429 then
        error_type = output.ERROR_TYPE.RATE_LIMIT
    elseif err.status_code >= 500 then
        error_type = output.ERROR_TYPE.SERVER_ERROR
    end

    -- Check for field validation errors (400 errors)
    if err.status_code == 400 then
        error_type = output.ERROR_TYPE.INVALID_REQUEST
    end

    -- Special cases based on error message content
    if err.message then
        -- Check for model errors (expanded patterns)
        if (err.message:match("model") and
                (err.message:match("does not exist") or
                    err.message:match("not found") or
                    err.message:match("access"))) then
            error_type = output.ERROR_TYPE.MODEL_ERROR
        end

        -- Check for context length errors
        if err.message:match("context length") or
            err.message:match("maximum.+tokens") or
            err.message:match("too long") or
            err.message:match("token limit") or
            err.message:match("resulted in %d+ tokens") then
            error_type = output.ERROR_TYPE.CONTEXT_LENGTH
        end

        -- Check for content filter errors
        if err.message:match("content policy") or
            err.message:match("content filter") or
            err.message:match("violates") then
            error_type = output.ERROR_TYPE.CONTENT_FILTER
        end

        -- Check for extended thinking not supported
        if err.message:match("thinking.+not supported") or
            err.message:match("not.+support.+thinking") then
            error_type = output.ERROR_TYPE.INVALID_REQUEST
        end
    end

    -- Return in the format expected by the text generation handler
    return {
        error = error_type,
        error_message = err.message or "Unknown Claude API error"
    }
end

-- Extract metadata from Claude HTTP response
local function extract_response_metadata(http_response)
    if not http_response or not http_response.headers then
        return {}
    end

    local metadata = {
        -- Basic request information
        request_id = http_response.headers["Request-Id"] or http_response.headers["X-Request-Id"],
        processing_ms = tonumber(http_response.headers["Processing-Ms"]),

        -- Rate limit information
        rate_limit = {
            requests_limit = tonumber(http_response.headers["Anthropic-RateLimit-Requests-Limit"]),
            requests_remaining = tonumber(http_response.headers["Anthropic-RateLimit-Requests-Remaining"]),
            requests_reset = http_response.headers["Anthropic-RateLimit-Requests-Reset"],
            tokens_limit = tonumber(http_response.headers["Anthropic-RateLimit-Tokens-Limit"]),
            tokens_remaining = tonumber(http_response.headers["Anthropic-RateLimit-Tokens-Remaining"]),
            tokens_reset = http_response.headers["Anthropic-RateLimit-Tokens-Reset"],
            input_tokens_limit = tonumber(http_response.headers["Anthropic-RateLimit-Input-Tokens-Limit"]),
            input_tokens_remaining = tonumber(http_response.headers["Anthropic-RateLimit-Input-Tokens-Remaining"]),
            input_tokens_reset = http_response.headers["Anthropic-RateLimit-Input-Tokens-Reset"],
            output_tokens_limit = tonumber(http_response.headers["Anthropic-RateLimit-Output-Tokens-Limit"]),
            output_tokens_remaining = tonumber(http_response.headers["Anthropic-RateLimit-Output-Tokens-Remaining"]),
            output_tokens_reset = http_response.headers["Anthropic-RateLimit-Output-Tokens-Reset"]
        },

        -- Additional headers that might be useful
        date = http_response.headers["Date"],
        content_type = http_response.headers["Content-Type"],
        retry_after = http_response.headers["Retry-After"]
    }

    return metadata
end

-- Parse error from Claude response
local function parse_error(http_response)
    -- Always include status code to help with error type mapping
    local error_info = {
        status_code = http_response.status_code,
        message = "Claude API error: " .. (http_response.status_code or "unknown status")
    }

    -- Add request ID if available
    if http_response.headers and http_response.headers["X-Request-Id"] then
        error_info.request_id = http_response.headers["X-Request-Id"]
    end

    local error_body

    -- Try to parse error body as JSON
    if http_response.body then
        error_body = http_response.body
    elseif http_response.stream then
        error_body = http_response.stream:read(4096)
    end

    if error_body then
        local parsed, parse_err = json.decode(error_body)
        if parsed then
            if parsed.error and parsed.error.message then
                error_info.message = parsed.error.message
                error_info.type = parsed.error.type
            elseif parsed.message then
                error_info.message = parsed.message
                error_info.type = parsed.type
            end
        end
    end

    -- Add metadata from headers
    error_info.metadata = extract_response_metadata(http_response)
    return error_info
end

-- Make a request to the Claude API
function claude.request(endpoint_path, payload, options)
    options = options or {}

    -- the `provider_options` field from the Model card
    local provider_options = ctx.get("provider_options") or {}

    -- Get API key
    local api_key = env.get(provider_options.api_key_env or claude.DEFAULT_API_KEY_ENV)
    if not api_key then
        return nil, {
            status_code = 401,
            message = "Claude API key is required"
        }
    end

    -- Get API version
    local api_version = options.api_version or claude.API_VERSION

    -- Ensure max_tokens is always present in the payload
    -- Claude API requires this field, even in streaming requests
    if not payload.max_tokens then
        payload.max_tokens = options.max_tokens or claude.DEFAULT_MAX_TOKENS
    end

    -- Prepare headers
    local headers = {
        ["Content-Type"] = "application/json",
        ["X-Api-Key"] = api_key,
        ["Anthropic-Version"] = api_version
    }

    -- Add beta features if enabled
    if options.beta_features and #options.beta_features > 0 then
        headers["anthropic-beta"] = table.concat(options.beta_features, ",")
    end

    -- Prepare endpoint URL
    local base_url = provider_options.base_url or claude.API_URL
    local url = base_url .. endpoint_path

    -- HTTP options
    local http_options = {
        headers = headers,
        timeout = options.timeout or 240
    }

    -- Enable streaming if requested
    if options.stream then
        http_options.stream = { buffer_size = 4096 }
        payload.stream = true
    end

    -- Encode payload
    local payload_json, err = json.encode(payload)
    if err then
        return nil, {
            status_code = 400,
            message = "Failed to encode request: " .. err
        }
    end

    http_options.body = payload_json

    -- Make the request
    local response, err = http_client.post(url, http_options)

    -- Handle request errors
    if err then
        local error_msg = "HTTP request failed"
        if type(err) == "string" then
            error_msg = error_msg .. ": " .. err
        elseif type(err) == "table" and err.message then
            error_msg = error_msg .. ": " .. err.message
        end

        return nil, {
            status_code = 0,
            message = error_msg
        }
    end

    -- Handle HTTP error status codes
    if response.status_code < 200 or response.status_code >= 300 then
        local error_info = parse_error(response)
        return nil, error_info
    end

    -- Handle streaming response
    if options.stream and response.stream then
        return {
            stream = response.stream,
            status_code = response.status_code,
            headers = response.headers,
            metadata = extract_response_metadata(response)
        }
    end

    -- Parse successful response
    local success, parsed = pcall(json.decode, response.body)
    if not success then
        return nil, {
            status_code = response.status_code,
            message = "Failed to parse Claude response: " .. parsed,
            metadata = extract_response_metadata(response)
        }
    end

    -- Add metadata to the response
    parsed.metadata = extract_response_metadata(response)
    return parsed
end

-- Send a message using the Messages API
function claude.create_message(options)
    options = options or {}

    -- Build request payload
    local payload = {
        model = options.model,
        max_tokens = options.max_tokens or claude.DEFAULT_MAX_TOKENS,
        messages = options.messages or {},
        temperature = options.temperature,
        system = options.system,
        stop_sequences = options.stop_sequences,
        stream = options.stream and true or nil
    }

    -- Add thinking configuration if enabled
    if options.thinking_enabled and options.thinking_effort then
        -- Calculate thinking budget based on thinking effort
        local thinking_budget = claude.calculate_thinking_budget(options.thinking_effort)

        -- Only add thinking config if budget > 0
        if thinking_budget > 0 then
            payload.thinking = {
                type = "enabled",
                budget_tokens = thinking_budget
            }
        end
    end

    -- Add tools if provided
    if options.tools and #options.tools > 0 then
        payload.tools = options.tools

        -- Set tool_choice based on options
        if options.tool_choice then
            payload.tool_choice = options.tool_choice
        end
    end

    -- Send request
    local response, err = claude.request(
        claude.API_ENDPOINTS.MESSAGES,
        payload,
        {
            api_key = options.api_key,
            api_version = options.api_version,
            stream = options.stream,
            beta_features = options.beta_features,
            timeout = options.timeout
        }
    )

    -- Handle errors
    if err then
        return nil, err
    end

    -- Handle streaming if a handler is provided
    if options.stream and options.stream_handler and response.stream then
        return claude.process_stream(response, options.stream_handler)
    end

    return response
end

-- Process a streaming completion response
function claude.process_stream(stream_response, callbacks)
    if not stream_response then
        return nil, "Invalid stream response (nil)"
    end

    if not stream_response.stream then
        return nil, "Invalid stream response (missing stream)"
    end

    local full_content = ""
    local finish_reason = nil
    local stop_sequence = nil
    local usage = {}
    local metadata = stream_response.metadata or {}
    local content_blocks = {}
    local tool_calls = {}

    -- New: Track thinking blocks with their content and signatures
    local thinking_blocks = {}
    local current_thinking_block = {
        content = "",
        signature = "",
        index = nil
    }

    -- Default callbacks with proper empty functions
    callbacks = callbacks or {}
    local on_content = callbacks.on_content or function() end
    local on_tool_call = callbacks.on_tool_call or function() end
    local on_thinking = callbacks.on_thinking or function() end
    local on_error = callbacks.on_error or function() end
    local on_done = callbacks.on_done or function() end

    -- Process each streamed chunk
    while true do
        local chunk, err = stream_response.stream:read()

        -- Handle read errors
        if err then
            on_error(err)
            return nil, err
        end

        -- End of stream
        if not chunk then
            break
        end

        -- Skip empty chunks
        if chunk == "" then
            goto continue
        end

        -- Process the chunk - extract all events
        local event_pattern = "event: ([^\n]+)\ndata: ([^\n]+)"
        for event_type, data_json in chunk:gmatch(event_pattern) do
            -- Parse the data as JSON
            local success, data = pcall(json.decode, data_json)
            if not success or not data then
                goto continue_event
            end

            -- Handle different event types
            if event_type == "message_start" then
                -- Store initial usage information
                if data.message and data.message.usage then
                    usage = data.message.usage
                end
            elseif event_type == "content_block_delta" then
                -- Handle content block delta safely
                local block_index = data.index or 0
                local delta = data.delta or {}

                if not delta.type then
                    goto continue_event
                end

                if delta.type == "text_delta" then
                    -- Text content
                    local content_chunk = delta.text or ""
                    full_content = full_content .. content_chunk
                    on_content(content_chunk)
                elseif delta.type == "thinking_delta" then
                    -- Thinking content
                    local thinking_chunk = delta.thinking or ""

                    -- Update current thinking block
                    if current_thinking_block.index == nil then
                        current_thinking_block.index = block_index
                    end

                    -- Append to the current thinking block content
                    current_thinking_block.content = current_thinking_block.content .. thinking_chunk

                    -- Call the thinking callback with both content and block info
                    -- For backward compatibility, pass content as first arg
                    -- Pass full block info as second arg for new implementations
                    on_thinking(thinking_chunk, {
                        type = "thinking_delta",
                        content = thinking_chunk,
                        block_index = block_index,
                        block = current_thinking_block
                    })
                elseif delta.type == "signature_delta" then
                    -- Signature for thinking block
                    local signature = delta.signature or ""

                    -- Store signature with current thinking block
                    if current_thinking_block.index ~= nil then
                        current_thinking_block.signature = signature

                        -- Call the thinking callback with signature info
                        on_thinking("", {
                            type = "signature_delta",
                            signature = signature,
                            block_index = current_thinking_block.index,
                            block = current_thinking_block
                        })

                        -- Store the completed thinking block
                        thinking_blocks[current_thinking_block.index] = {
                            content = current_thinking_block.content,
                            signature = current_thinking_block.signature
                        }
                    end
                elseif delta.type == "input_json_delta" then
                    -- Tool use content
                    local tool_call_index = data.index or 0

                    -- Initialize tool call if needed
                    if not tool_calls[tool_call_index] then
                        tool_calls[tool_call_index] = {
                            partial_json = "",
                            id = nil,
                            name = nil,
                            arguments = nil
                        }
                    end

                    -- Accumulate JSON
                    tool_calls[tool_call_index].partial_json =
                        tool_calls[tool_call_index].partial_json ..
                        (delta.partial_json or "")
                end
            elseif event_type == "content_block_stop" then
                -- A content block has been completed
                local block_index = data.index or 0

                -- If this is a thinking block and we have a complete block, reset for next one
                if content_blocks[block_index] and content_blocks[block_index].type == "thinking" then
                    -- Reset for next thinking block
                    current_thinking_block = {
                        content = "",
                        signature = "",
                        index = nil
                    }
                end

                -- If this is a completed tool call, try to parse it
                if tool_calls[block_index] and tool_calls[block_index].partial_json then
                    local json_str = tool_calls[block_index].partial_json

                    -- Make sure the JSON is valid by adding missing braces if needed
                    if not json_str:match("^%s*{") then
                        json_str = "{" .. json_str
                    end
                    if not json_str:match("}%s*$") then
                        json_str = json_str .. "}"
                    end

                    local success, parsed_input = pcall(json.decode, json_str)

                    if success and parsed_input then
                        -- Get the tool call details from content_blocks data
                        if content_blocks[block_index] and
                            content_blocks[block_index].type == "tool_use" then
                            local tool_call = content_blocks[block_index]

                            -- Store complete tool call info
                            tool_calls[block_index].id = tool_call.id or ""
                            tool_calls[block_index].name = tool_call.name or ""
                            tool_calls[block_index].arguments = parsed_input

                            -- Notify about the tool call
                            on_tool_call({
                                id = tool_call.id or "",
                                name = tool_call.name or "",
                                arguments = parsed_input
                            })
                        end
                    end
                end
            elseif event_type == "content_block_start" then
                -- Store content block information safely
                if data.index ~= nil and data.content_block then
                    local block_index = data.index
                    content_blocks[block_index] = data.content_block

                    -- If this is a thinking block, initialize tracking
                    if data.content_block.type == "thinking" then
                        -- Initialize the current thinking block
                        current_thinking_block = {
                            content = data.content_block.thinking or "",
                            signature = data.content_block.signature or "",
                            index = block_index
                        }

                        -- Store initial state
                        thinking_blocks[block_index] = {
                            content = current_thinking_block.content,
                            signature = current_thinking_block.signature
                        }
                    end

                    -- If this is a tool_use block, initialize the tool call entry
                    if data.content_block.type == "tool_use" then
                        tool_calls[block_index] = tool_calls[block_index] or {
                            partial_json = "",
                            id = data.content_block.id,
                            name = data.content_block.name,
                            arguments = nil -- Will be filled when we get the complete JSON
                        }
                    end
                end
            elseif event_type == "message_delta" then
                -- Update finish reason and usage
                if data.delta then
                    finish_reason = data.delta.stop_reason
                    stop_sequence = data.delta.stop_sequence
                end

                if data.usage then
                    -- Update usage information
                    for k, v in pairs(data.usage) do
                        usage[k] = v
                    end
                end
            elseif event_type == "message_stop" then
                -- End of message, create final result

                -- Prepare the finalized tool calls for the result
                local finalized_tool_calls = {}
                for idx, tool_call in pairs(tool_calls) do
                    if tool_call.id and tool_call.name then
                        table.insert(finalized_tool_calls, {
                            id = tool_call.id,
                            name = tool_call.name,
                            arguments = tool_call.arguments or {}
                        })
                    end
                end

                -- Add thinking blocks to the result
                local result = {
                    content = full_content,
                    finish_reason = finish_reason,
                    stop_sequence = stop_sequence,
                    tool_calls = #finalized_tool_calls > 0 and finalized_tool_calls or nil,
                    usage = usage,
                    metadata = metadata,
                    thinking_blocks = thinking_blocks -- New: include thinking blocks in result
                }

                -- Call the done callback
                on_done(result)
                return full_content, nil, result
            elseif event_type == "error" then
                -- Handle error events
                if data and data.error then
                    local error_info = {
                        message = data.error.message or "Unknown streaming error",
                        type = data.error.type
                    }
                    on_error(error_info)
                    return nil, error_info.message, { error = error_info }
                end
            end

            ::continue_event::
        end

        ::continue::
    end

    -- Prepare the finalized tool calls for the result
    local finalized_tool_calls = {}
    for idx, tool_call in pairs(tool_calls) do
        if tool_call.id and tool_call.name then
            table.insert(finalized_tool_calls, {
                id = tool_call.id,
                name = tool_call.name,
                arguments = tool_call.arguments or {}
            })
        end
    end

    -- Create the final result if we didn't get a message_stop event
    local result = {
        content = full_content,
        finish_reason = finish_reason,
        stop_sequence = stop_sequence,
        tool_calls = #finalized_tool_calls > 0 and finalized_tool_calls or nil,
        usage = usage,
        metadata = metadata,
        thinking_blocks = thinking_blocks -- New: include thinking blocks in result
    }

    -- Call the done callback
    on_done(result)

    return full_content, nil, result
end

-- Extract usage information from response
function claude.extract_usage(claude_response)
    if not claude_response or not claude_response.usage then
        return nil
    end

    local usage = {
        prompt_tokens = claude_response.usage.input_tokens or 0,
        completion_tokens = claude_response.usage.output_tokens or 0,
        total_tokens = (claude_response.usage.input_tokens or 0) +
            (claude_response.usage.output_tokens or 0)
    }

    -- Add cache tokens if available
    if claude_response.usage.cache_creation_input_tokens then
        usage.cache_creation_input_tokens = claude_response.usage.cache_creation_input_tokens
    end

    if claude_response.usage.cache_read_input_tokens then
        usage.cache_read_input_tokens = claude_response.usage.cache_read_input_tokens
    end

    return usage
end

return claude
