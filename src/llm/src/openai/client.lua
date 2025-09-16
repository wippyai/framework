local json = require("json")
local http_client = require("http_client")
local env = require("env")
local ctx = require("ctx")

local openai_client = {}

-- Allow aliasing for testing
openai_client._http_client = http_client
openai_client._env = env
openai_client._ctx = ctx

-- Enhanced batch context resolution with individual context keys
local function resolve_context_values(value_configs)
    local ctx_all = openai_client._ctx.all() or {}
    local results = {}

    for key, value_config in pairs(value_configs) do
        local result = nil

        -- Check for direct value first
        if ctx_all[key] then
            result = ctx_all[key]
        else
            -- Check for env variable reference
            local env_key = key .. "_env"
            if ctx_all[env_key] then
                local env_value = openai_client._env.get(ctx_all[env_key])
                if env_value and env_value ~= '' then
                    result = env_value
                end
            end
        end

        -- Use default env variable if no result
        if not result and value_config.default_env_var then
            local env_value = openai_client._env.get(value_config.default_env_var)
            if env_value and env_value ~= '' then
                result = env_value
            end
        end

        results[key] = result or value_config.default_value
    end

    return results
end

-- Extract metadata from HTTP response headers
local function extract_response_metadata(http_response)
    if not http_response or not http_response.headers then
        return {}
    end

    local metadata = {
        request_id = http_response.headers["X-Request-Id"],
        organization = http_response.headers["Openai-Organization"],
        processing_ms = tonumber(http_response.headers["Openai-Processing-Ms"]),
        version = http_response.headers["Openai-Version"]
    }

    -- Add rate limit information
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

-- Parse error from OpenAI HTTP response
local function parse_error_response(http_response)
    local error_info = {
        status_code = http_response and http_response.status_code or 0,
        message = "OpenAI API error: " .. (http_response and http_response.status_code or "connection failed")

    }

    -- open router and other providers sometimes store error in various places
    print("error detected", http_response.body)

    -- Add request ID if available
    if http_response and http_response.headers and http_response.headers["x-request-id"] then
        error_info.request_id = http_response.headers["x-request-id"]
    end

    -- Try to parse error body - check for actual content, not just existence
    if http_response and http_response.body then
        if http_response.body ~= "" and http_response.body ~= "no body" then
            local parsed, decode_err = json.decode(http_response.body)

            if not decode_err and parsed and parsed.error then
                error_info.message = parsed.error.message or error_info.message
                error_info.code = parsed.error.code
                error_info.param = parsed.error.param
                error_info.type = parsed.error.type

                -- Handle OpenRouter-style nested error metadata
                if parsed.error.metadata and parsed.error.metadata.raw then
                    error_info.nested_error = parsed.error.metadata.raw
                    error_info.provider_name = parsed.error.metadata.provider_name

                    -- Try to parse the nested error for more specific info
                    local nested_parsed, nested_err = json.decode(parsed.error.metadata.raw)
                    if not nested_err and nested_parsed then
                        if nested_parsed.message then
                            error_info.detailed_message = nested_parsed.message
                        end
                    end
                end
            end
        end
    end

    -- Add metadata from headers
    error_info.metadata = extract_response_metadata(http_response)

    return error_info
end

-- Prepare HTTP headers for OpenAI request
local function prepare_headers(api_key, organization, method, additional_headers)
    local headers = {
        ["Authorization"] = "Bearer " .. api_key
    }

    -- Only add Content-Type for methods that have a body
    if method == "POST" or method == "PUT" or method == "PATCH" then
        headers["Content-Type"] = "application/json"
    end

    if organization then
        headers["OpenAI-Organization"] = organization
    end

    -- Merge additional headers from context
    if additional_headers then
        for header_name, header_value in pairs(additional_headers) do
            headers[header_name] = header_value
        end
    end

    return headers
end

-- Main HTTP request function
function openai_client.request(endpoint_path, payload, options)
    options = options or {}
    local method = options.method or "POST"

    -- Resolve configuration values
    local config = resolve_context_values({
        api_key = {
            default_value = nil,
            default_env_var = "OPENAI_API_KEY"
        },
        base_url = {
            default_value = "https://api.openai.com/v1",
            default_env_var = "OPENAI_BASE_URL"
        },
        organization = {
            default_value = nil,
            default_env_var = "OPENAI_ORGANIZATION"
        },
        timeout = {
            default_value = 120,
            default_env_var = "OPENAI_TIMEOUT"
        },
        headers = {
            default_value = nil,
            default_env_var = nil
        }
    })

    -- Validate API key
    if not config.api_key then
        local error_response = {
            status_code = 401,
            message = "OpenAI API key is required"
        }
        return nil, error_response
    end

    -- Prepare request
    local full_url = config.base_url .. endpoint_path
    local headers = prepare_headers(config.api_key, config.organization, method, config.headers)

    local http_options = {
        headers = headers,
        timeout = options.timeout or config.timeout
    }

    -- Handle payload and streaming for methods that support body
    if method == "POST" or method == "PUT" or method == "PATCH" then
        payload = payload or {}

        -- Handle streaming payload modifications BEFORE encoding
        if options.stream then
            payload.stream = true
            payload.stream_options = {
                include_usage = true
            }
        else
            payload.usage = { include = true }
        end

        http_options.body = json.encode(payload)

        -- Handle streaming http options
        if options.stream then
            http_options.stream = true
        end
    end

    -- Make the HTTP request using appropriate method
    local response
    if method == "GET" then
        response, err = openai_client._http_client.get(full_url, http_options)
    elseif method == "DELETE" then
        response, err = openai_client._http_client.delete(full_url, http_options)
    elseif method == "PUT" then
        response, err = openai_client._http_client.put(full_url, http_options)
    elseif method == "PATCH" then
        response, err = openai_client._http_client.patch(full_url, http_options)
    else -- Default to POST
        response, err = openai_client._http_client.post(full_url, http_options)
    end

    -- Handle nil response (connection failures)
    if not response then
        return nil, {
            status_code = 0,
            message = "Connection failed: " .. tostring(err)
        }
    end

    -- Check for HTTP errors
    if response.status_code < 200 or response.status_code >= 300 then
        local parsed_error = parse_error_response(response)
        return nil, parsed_error
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

    -- Parse non-streaming response
    local parsed, parse_err = json.decode(response.body)
    if parse_err then
        local parse_error = {
            status_code = response.status_code,
            message = "Failed to parse OpenAI response: " .. parse_err,
            metadata = extract_response_metadata(response)
        }
        return nil, parse_error
    end

    -- Add metadata to the response
    parsed.metadata = extract_response_metadata(response)

    return parsed
end

-- Process streaming response
function openai_client.process_stream(stream_response, callbacks)
    if not stream_response or not stream_response.stream then
        return nil, "Invalid stream response"
    end

    local full_content = ""
    local finish_reason = nil
    local usage = nil
    local metadata = stream_response.metadata or {}

    -- Track tool calls across chunks
    local tool_calls_accumulator = {}
    local sent_tool_calls = {}

    -- Track reasoning details for OpenRouter
    local reasoning_accumulator = {}

    -- Default callbacks
    callbacks = callbacks or {}
    local on_content = callbacks.on_content or function() end
    local on_tool_call = callbacks.on_tool_call or function() end
    local on_reasoning = callbacks.on_reasoning or function() end
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
                -- Process any remaining tool calls
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

                -- Create final result with reasoning if present
                local result = {
                    content = full_content,
                    finish_reason = finish_reason,
                    usage = usage,
                    metadata = metadata
                }

                -- Add reasoning details if accumulated
                if next(reasoning_accumulator) then
                    result.reasoning_details = reasoning_accumulator
                end

                on_done(result)
                return full_content, nil, result
            end

            -- Parse the JSON data
            local parsed, parse_err = json.decode(data_line)
            if parse_err then
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

                -- Handle reasoning details delta (OpenRouter)
                if choice.delta and choice.delta.reasoning_details then
                    for _, reasoning_detail in ipairs(choice.delta.reasoning_details) do
                        table.insert(reasoning_accumulator, reasoning_detail)
                        if reasoning_detail.text then
                            on_reasoning(reasoning_detail.text)
                        end
                    end
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
                            -- Find ID for this index
                            for tc_id, tc in pairs(tool_calls_accumulator) do
                                if tc.index == index then
                                    id = tc_id
                                    break
                                end
                            end
                        end

                        -- Update tool call info if we have a valid ID
                        if id then
                            if tool_call_delta.index ~= nil then
                                tool_calls_accumulator[id].index = tool_call_delta.index
                            end

                            if tool_call_delta["function"] then
                                if tool_call_delta["function"].name then
                                    tool_calls_accumulator[id].name = tool_call_delta["function"].name
                                end

                                if tool_call_delta["function"].arguments then
                                    tool_calls_accumulator[id].arguments =
                                        (tool_calls_accumulator[id].arguments or "") ..
                                        tool_call_delta["function"].arguments
                                end
                            end

                            -- Check if tool call is complete
                            local tool_call = tool_calls_accumulator[id]
                            local is_complete, _ = json.decode(tool_call.arguments)
                            if tool_call.name and tool_call.arguments and not sent_tool_calls[id] and
                                (choice.finish_reason == "tool_calls" or is_complete) then
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

                    -- Final check for tool calls on finish
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

    -- Process any remaining tool calls
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

    -- Create final result with reasoning if present
    local result = {
        content = full_content,
        finish_reason = finish_reason,
        usage = usage,
        metadata = metadata
    }

    -- Add reasoning details if accumulated
    if next(reasoning_accumulator) then
        result.reasoning_details = reasoning_accumulator
    end

    on_done(result)
    return full_content, nil, result
end

return openai_client
