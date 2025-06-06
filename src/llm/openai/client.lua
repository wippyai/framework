local json = require("json")
local http_client = require("http_client")
local env = require("env")
local output = require("output")
local ctx = require("ctx")

-- OpenAI Client Library
local openai = {}

-- Constants
openai.DEFAULT_API_ENDPOINT = "https://api.openai.com/v1"
openai.DEFAULT_CHAT_ENDPOINT = "/chat/completions"
openai.DEFAULT_EMBEDDING_ENDPOINT = "/embeddings"
openai.DEFAULT_API_KEY_ENV = "OPENAI_API_KEY"

-- Map OpenAI finish reasons to standardized finish reasons
openai.FINISH_REASON_MAP = {
    ["stop"] = output.FINISH_REASON.STOP,
    ["length"] = output.FINISH_REASON.LENGTH,
    ["content_filter"] = output.FINISH_REASON.CONTENT_FILTER,
    ["tool_calls"] = output.FINISH_REASON.TOOL_CALL,
}

-- Error type mapping function for OpenAI errors
-- Maps specific error messages to standardized error types
function openai.map_error(err)
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

    -- Special cases based on error message content
    if err.message then
        -- Check for context length errors
        if err.message:match("context length") or
            err.message:match("string too long") or
            err.message:match("maximum.+tokens") then
            error_type = output.ERROR_TYPE.CONTEXT_LENGTH
        end

        -- Check for content filter errors
        if err.message:match("content policy") or
            err.message:match("content filter") then
            error_type = output.ERROR_TYPE.CONTENT_FILTER
        end
    end

    -- Return already in the format expected by the text generation handler
    return {
        error = error_type,
        error_message = err.message or "Unknown OpenAI error"
    }
end

-- Map numeric thinking effort (0-100) to OpenAI reasoning effort values
function openai.map_thinking_effort(effort)
    if not effort then return nil end

    if effort < 25 then
        return "low"
    elseif effort < 75 then
        return "medium"
    else
        return "high"
    end
end

-- Extract metadata from OpenAI HTTP response
local function extract_response_metadata(http_response)
    if not http_response or not http_response.headers then
        return {}
    end

    local metadata = {
        -- Basic request information
        request_id = http_response.headers["X-Request-Id"],
        organization = http_response.headers["Openai-Organization"],
        processing_ms = tonumber(http_response.headers["Openai-Processing-Ms"]),
        version = http_response.headers["Openai-Version"],

        -- Rate limit information
        rate_limit = {
            limit_requests = tonumber(http_response.headers["X-Ratelimit-Limit-Requests"]),
            limit_tokens = tonumber(http_response.headers["X-Ratelimit-Limit-Tokens"]),
            remaining_requests = tonumber(http_response.headers["X-Ratelimit-Remaining-Requests"]),
            remaining_tokens = tonumber(http_response.headers["X-Ratelimit-Remaining-Tokens"]),
            reset_requests = http_response.headers["X-Ratelimit-Reset-Requests"],
            reset_tokens = http_response.headers["X-Ratelimit-Reset-Tokens"]
        },

        -- Additional headers that might be useful
        date = http_response.headers["Date"],
        content_type = http_response.headers["Content-Type"],
        cache_status = http_response.headers["Cf-Cache-Status"],
        cf_ray = http_response.headers["Cf-Ray"]
    }

    -- Add rate limit information if available
    local rate_limits = {}
    for header, value in pairs(http_response.headers) do
        if header:match("^x%-ratelimit") then
            local key = header:gsub("x%-ratelimit%-", ""):gsub("%-", "_")
            rate_limits[key] = tonumber(value) or value
        end
    end

    if next(rate_limits) then
        metadata.rate_limits = rate_limits
    end

    return metadata
end

-- Parse error from OpenAI response
local function parse_error(http_response)
    -- Always include status code to help with error type mapping
    local error_info = {
        status_code = http_response.status_code,
        message = "OpenAI API error: " .. (http_response.status_code or "unknown status")
    }

    -- Add request ID if available
    if http_response.headers and http_response.headers["x-request-id"] then
        error_info.headers = {
            request_id = http_response.headers["x-request-id"]
        }
    end

    local error_body

    -- Try to parse error body as JSON
    if http_response.body then
        error_body = http_response.body
    elseif http_response.stream then
        error_body = http_response.stream:read(4096)
    end

    if error_body then
        local parsed, decode_err = json.decode(error_body)
        if not decode_err and parsed and parsed.error then
            error_info.message = parsed.error.message or error_info.message
            error_info.code = parsed.error.code
            error_info.param = parsed.error.param
            error_info.type = parsed.error.type
        end
    end

    -- Add metadata from headers
    error_info.metadata = extract_response_metadata(http_response)

    return error_info
end

-- Make a request to the OpenAI API
function openai.request(endpoint_path, payload, options)
    options = options or {}

    -- the `provider_options` field from the Model card
    local provider_options = ctx.get("provider_options") or {}

    -- Get API key
    local api_key = env.get(provider_options.api_key_env or openai.DEFAULT_API_KEY_ENV)
    if not api_key then
        return nil, {
            status_code = 401,
            message = "OpenAI API key is required"
        }
    end

    -- Prepare headers
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. api_key
    }

    -- Add organization header if specified
    local organization = options.organization or env.get("OPENAI_ORGANIZATION")
    if organization then
        headers["OpenAI-Organization"] = organization
    end

    -- Prepare endpoint URL
    local base_url = provider_options.base_url or openai.DEFAULT_API_ENDPOINT
    local full_url = base_url .. endpoint_path

    -- Make the request
    local http_options = {
        headers = headers,
        timeout = options.timeout or 120
    }

    -- Handle streaming if requested
    if options.stream then
        http_options.stream = true
        payload.stream = true
        payload.stream_options = {
            include_usage = true
        }
    end

    -- Make the request
    http_options.body = json.encode(payload)

    -- Send the request
    local response = http_client.post(full_url, http_options)

    -- Check for errors
    -- todo: move it below?
    if response.status_code < 200 or response.status_code >= 300 then
        return nil, parse_error(response)
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
    local parsed, parse_err = json.decode(response.body)
    if parse_err then
        return nil, {
            status_code = response.status_code,
            message = "Failed to parse OpenAI response: " .. parse_err,
            metadata = extract_response_metadata(response)
        }
    end

    -- Add metadata to the response
    parsed.metadata = extract_response_metadata(response)

    return parsed
end

-- Process a streaming completion response
function openai.process_stream(stream_response, callbacks)
    if not stream_response or not stream_response.stream then
        return nil, "Invalid stream response"
    end

    local full_content = ""
    local finish_reason = nil
    local usage = nil
    local metadata = stream_response.metadata or {}

    -- Track tool calls across chunks
    local tool_calls_accumulator = {}
    local sent_tool_calls = {} -- Track which tool calls have been sent

    -- Default callbacks
    callbacks = callbacks or {}
    local on_content = callbacks.on_content or function() end
    local on_tool_call = callbacks.on_tool_call or function() end
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
            -- Continue to next chunk
            goto continue
        end

        -- Check for errors in the chunk
        local error_json = chunk:match('data:%s*({.-"error":.-)%s*\n')
        if error_json then
            local parsed_error, parse_err = json.decode(error_json)
            if not parse_err and parsed_error and parsed_error.error then
                local error_info = {
                    message = parsed_error.error.message,
                    code = parsed_error.error.code,
                    type = parsed_error.error.type,
                    param = parsed_error.error.param
                }
                on_error(error_info)
                return nil, error_info.message, { error = error_info }
            end
        end

        -- Process each data line in the chunk
        for data_line in chunk:gmatch('data:%s*(.-)%s*\n') do
            -- Skip empty data lines
            if data_line == "" then
                goto continue_line
            end

            -- Check for [DONE] marker
            if data_line == "[DONE]" then
                -- Process any accumulated tool calls that haven't been sent yet
                for id, tool_call in pairs(tool_calls_accumulator) do
                    -- Only send if complete and not already sent
                    if tool_call.name and tool_call.arguments and not sent_tool_calls[id] then
                        sent_tool_calls[id] = true
                        on_tool_call({
                            id = id,
                            name = tool_call.name,
                            arguments = tool_call.arguments
                        })
                    end
                end

                -- Create the final result
                local result = {
                    content = full_content,
                    finish_reason = finish_reason,
                    usage = usage,
                    metadata = metadata
                }
                -- Call the done callback
                on_done(result)
                return full_content, nil, result
            end

            -- Parse the JSON data
            local parsed, parse_err = json.decode(data_line)
            if parse_err then
                -- Skip lines that can't be parsed
                goto continue_line
            end

            -- Process the delta if present
            if parsed.choices and parsed.choices[1] then
                local choice = parsed.choices[1]

                -- Handle content delta
                if choice.delta and choice.delta.content then
                    local content_chunk = choice.delta.content
                    full_content = full_content .. content_chunk
                    on_content(content_chunk)
                end

                -- Handle tool call deltas
                if choice.delta and choice.delta.tool_calls then
                    for _, tool_call_delta in ipairs(choice.delta.tool_calls) do
                        local index = tool_call_delta.index
                        local id = tool_call_delta.id

                        -- Initialize tool call entry if new
                        if id and not tool_calls_accumulator[id] then
                            tool_calls_accumulator[id] = {
                                id = id,
                                index = index,
                                arguments = "",
                                name = nil
                            }
                        elseif not id and tool_call_delta.index ~= nil then
                            -- If no ID but we have an index, find the ID for this index
                            for tc_id, tc in pairs(tool_calls_accumulator) do
                                if tc.index == index then
                                    id = tc_id
                                    break
                                end
                            end
                        end

                        -- If we have a valid ID, update the tool call info
                        if id then
                            -- Track the index
                            if tool_call_delta.index ~= nil then
                                tool_calls_accumulator[id].index = tool_call_delta.index
                            end

                            -- Get function info if present
                            if tool_call_delta["function"] then
                                -- Update name if available
                                if tool_call_delta["function"].name then
                                    tool_calls_accumulator[id].name = tool_call_delta["function"].name
                                end

                                -- Accumulate argument chunks
                                if tool_call_delta["function"].arguments then
                                    tool_calls_accumulator[id].arguments =
                                        (tool_calls_accumulator[id].arguments or "") ..
                                        tool_call_delta["function"].arguments
                                end
                            end

                            -- Check if tool call is complete and should be sent
                            local tool_call = tool_calls_accumulator[id]
                            local is_complete, _ = json.decode(tool_call.arguments)
                            if tool_call.name and tool_call.arguments and not sent_tool_calls[id] and
                                (choice.finish_reason == "tool_calls" or -- End of response
                                    -- Check if we can successfully parse the arguments
                                    is_complete) then
                                sent_tool_calls[id] = true
                                on_tool_call({
                                    id = id,
                                    name = tool_call.name,
                                    arguments = tool_call.arguments
                                })
                            end
                        end
                    end
                end

                -- Record finish reason if present
                if choice.finish_reason then
                    finish_reason = choice.finish_reason

                    -- If we're finishing with tool_calls, make one final check for complete tool calls
                    if choice.finish_reason == "tool_calls" then
                        for id, tool_call in pairs(tool_calls_accumulator) do
                            if tool_call.name and tool_call.arguments and not sent_tool_calls[id] then
                                sent_tool_calls[id] = true
                                on_tool_call({
                                    id = id,
                                    name = tool_call.name,
                                    arguments = tool_call.arguments
                                })
                            end
                        end
                    end
                end
            end

            -- Capture usage info if present
            if parsed.usage then
                usage = parsed.usage
            end

            ::continue_line::
        end

        ::continue::
    end

    -- Process any remaining tool calls that haven't been sent
    for id, tool_call in pairs(tool_calls_accumulator) do
        if tool_call.name and tool_call.arguments and not sent_tool_calls[id] then
            sent_tool_calls[id] = true
            on_tool_call({
                id = id,
                name = tool_call.name,
                arguments = tool_call.arguments
            })
        end
    end

    -- Create the final result
    local result = {
        content = full_content,
        finish_reason = finish_reason,
        usage = usage,
        metadata = metadata
    }

    -- Make sure usage is included for o-models with reasoning
    if usage and usage.completion_tokens_details and usage.completion_tokens_details.reasoning_tokens then
        if not result.usage then result.usage = {} end
        if not result.usage.completion_tokens_details then result.usage.completion_tokens_details = {} end
        result.usage.completion_tokens_details.reasoning_tokens = usage.completion_tokens_details.reasoning_tokens
    end

    -- Call the done callback
    on_done(result)

    return full_content, nil, result
end

-- Extract usage information from response
function openai.extract_usage(openai_response)
    if not openai_response or not openai_response.usage then
        return nil
    end

    local usage = {
        prompt_tokens = openai_response.usage.prompt_tokens or 0,
        completion_tokens = openai_response.usage.completion_tokens or 0,
        total_tokens = openai_response.usage.total_tokens or 0
    }

    -- Add thinking tokens if available (mapped from reasoning_tokens)
    if openai_response.usage.completion_tokens_details and
        openai_response.usage.completion_tokens_details.reasoning_tokens then
        usage.thinking_tokens = openai_response.usage.completion_tokens_details.reasoning_tokens
    end

    -- Extract cache read tokens from prompt_tokens_details.cached_tokens
    if openai_response.usage.prompt_tokens_details and
        openai_response.usage.prompt_tokens_details.cached_tokens then
        usage.cache_read_tokens = openai_response.usage.prompt_tokens_details.cached_tokens
    else
        usage.cache_read_tokens = 0
    end

    -- Calculate cache write tokens
    -- Cache write tokens would be prompt tokens that weren't served from cache
    if usage.cache_read_tokens > 0 then
        usage.cache_write_tokens = math.max(0, usage.prompt_tokens - usage.cache_read_tokens)
    else
        -- If no cache read tokens, all prompt tokens are potentially cache write tokens
        -- But OpenAI doesn't explicitly provide this, so we set to 0 for accuracy
        usage.cache_write_tokens = 0
    end

    return usage
end

return openai
