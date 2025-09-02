local json = require("json")
local http_client = require("http_client")
local env = require("env")
local ctx = require("ctx")

local claude_client = {}

claude_client._http_client = http_client
claude_client._env = env
claude_client._ctx = ctx

claude_client.ENDPOINTS = {
    MESSAGES = "/v1/messages"
}

---@param value_configs table configuration for context value resolution
---@return table resolved configuration values
local function resolve_context_values(value_configs)
    local ctx_all = claude_client._ctx.all() or {}
    local results = {}

    for key, value_config in pairs(value_configs) do
        local result = nil

        if ctx_all[key] then
            result = ctx_all[key]
        else
            local env_key = key .. "_env"
            if ctx_all[env_key] then
                local env_value = claude_client._env.get(ctx_all[env_key])
                if env_value then
                    result = env_value
                end
            end
        end

        if not result and value_config.default_env_var then
            local env_value = claude_client._env.get(value_config.default_env_var)
            if env_value then
                result = env_value
            end
        end

        results[key] = result or value_config.default_value
    end

    return results
end

---@param http_response table HTTP response object
---@return table extracted metadata
local function extract_response_metadata(http_response)
    if not http_response or not http_response.headers then
        return {}
    end

    local metadata = {
        request_id = http_response.headers["request-id"] or http_response.headers["x-request-id"],
        processing_ms = tonumber(http_response.headers["processing-ms"])
    }

    local rate_limits = {}
    for header, value in pairs(http_response.headers) do
        if header:match("^anthropic%-ratelimit") then
            local key = header:gsub("anthropic%-ratelimit%-", ""):gsub("%-", "_")
            rate_limits[key] = tonumber(value) or value
        end
    end

    if next(rate_limits) then
        metadata.rate_limits = rate_limits
    end

    return metadata
end

---@param http_response table HTTP response object
---@return table parsed error information
local function parse_error_response(http_response)
    local error_info = {
        status_code = http_response and http_response.status_code or 0,
        message = "Claude API error: " .. (http_response and http_response.status_code or "connection failed")
    }

    if http_response and http_response.headers then
        error_info.request_id = http_response.headers["request-id"] or
            http_response.headers["x-request-id"]
    end

    local error_body = http_response and http_response.body
    if http_response and http_response.stream then
        error_body = http_response.stream:read(4096)
    end

    if error_body and #error_body > 0 then
        local parsed, parse_err = json.decode(error_body)
        if not parse_err and parsed then
            if parsed.error then
                error_info.error = parsed.error
                error_info.message = parsed.error.message or error_info.message
            end
            error_info.request_id = parsed.request_id or error_info.request_id
        end
    end

    error_info.metadata = extract_response_metadata(http_response)
    return error_info
end

---@param api_key string Anthropic API key
---@param api_version string API version
---@param beta_features table|nil beta features array
---@param method string HTTP method
---@param additional_headers table|nil additional headers
---@return table prepared headers
local function prepare_headers(api_key, api_version, beta_features, method, additional_headers)
    local headers = {
        ["x-api-key"] = api_key,
        ["anthropic-version"] = api_version
    }

    if method == "POST" or method == "PUT" or method == "PATCH" then
        headers["content-type"] = "application/json"
    end

    if beta_features and #beta_features > 0 then
        headers["anthropic-beta"] = table.concat(beta_features, ",")
    end

    if additional_headers then
        for header_name, header_value in pairs(additional_headers) do
            headers[header_name] = header_value
        end
    end

    return headers
end

---@param endpoint_path string API endpoint path
---@param payload table|nil request payload
---@param options table|nil request options
---@return table|nil, table|nil response data and error
function claude_client.request(endpoint_path, payload, options)
    options = options or {}
    local method = options.method or "POST"

    local config = resolve_context_values({
        api_key = {
            default_value = nil,
            default_env_var = "ANTHROPIC_API_KEY"
        },
        base_url = {
            default_value = "https://api.anthropic.com",
            default_env_var = "ANTHROPIC_BASE_URL"
        },
        api_version = {
            default_value = "2023-06-01",
            default_env_var = "ANTHROPIC_API_VERSION"
        },
        beta_features = {
            default_value = {},
            default_env_var = nil
        },
        timeout = {
            default_value = 240,
            default_env_var = "ANTHROPIC_TIMEOUT"
        },
        headers = {
            default_value = nil,
            default_env_var = nil
        }
    })

    if not config.api_key then
        return nil, {
            status_code = 401,
            message = "Claude API key is required"
        }
    end

    local full_url = config.base_url .. endpoint_path
    local headers = prepare_headers(config.api_key, config.api_version, config.beta_features, method, config.headers)

    local http_options = {
        headers = headers,
        timeout = options.timeout or config.timeout
    }

    if method == "POST" or method == "PUT" or method == "PATCH" then
        payload = payload or {}

        if options.stream then
            payload.stream = true
        end

        http_options.body = json.encode(payload)

        if options.stream then
            http_options.stream = { buffer_size = 4096 }
        end
    end

    local response
    if method == "GET" then
        response = claude_client._http_client.get(full_url, http_options)
    elseif method == "DELETE" then
        response = claude_client._http_client.delete(full_url, http_options)
    elseif method == "PUT" then
        response = claude_client._http_client.put(full_url, http_options)
    elseif method == "PATCH" then
        response = claude_client._http_client.patch(full_url, http_options)
    else
        response = claude_client._http_client.post(full_url, http_options)
    end

    if not response then
        return nil, {
            status_code = 0,
            message = "Connection failed"
        }
    end

    if response.status_code < 200 or response.status_code >= 300 then
        return nil, parse_error_response(response)
    end

    if options.stream and response.stream then
        return {
            stream = response.stream,
            status_code = response.status_code,
            headers = response.headers,
            metadata = extract_response_metadata(response)
        }
    end

    local parsed, parse_err = json.decode(response.body)
    if parse_err then
        return nil, {
            status_code = response.status_code,
            message = "Failed to parse Claude response: " .. parse_err,
            metadata = extract_response_metadata(response)
        }
    end

    parsed.metadata = extract_response_metadata(response)
    return parsed
end

---@param stream_response table streaming response object
---@param callbacks table callback functions for stream events
---@return string|nil, string|nil, table|nil content, error, full result
function claude_client.process_stream(stream_response, callbacks)
    if not stream_response or not stream_response.stream then
        return nil, "Invalid stream response"
    end

    callbacks = callbacks or {}
    local on_content = callbacks.on_content or function() end
    local on_tool_call = callbacks.on_tool_call or function() end
    local on_thinking = callbacks.on_thinking or function() end
    local on_error = callbacks.on_error or function() end
    local on_done = callbacks.on_done or function() end

    local full_content = ""
    local tool_calls = {}
    local thinking_blocks = {}
    local finish_reason = nil
    local usage = {}
    local content_blocks = {}

    while true do
        local chunk, err = stream_response.stream:read()

        if err then
            on_error({ message = err })
            return nil, err
        end

        if not chunk then
            break
        end

        if chunk == "" then
            goto continue
        end

        for event_type, data_json in chunk:gmatch("event: ([^\n]+)\ndata: ([^\n]+)") do
            local data, decode_err = json.decode(data_json)
            if decode_err or not data then
                goto continue_event
            end

            if event_type == "message_start" then
                if data.message and data.message.usage then
                    usage = data.message.usage
                end
            elseif event_type == "content_block_start" then
                if data.index ~= nil and data.content_block then
                    content_blocks[data.index] = data.content_block

                    if data.content_block.type == "thinking" then
                        thinking_blocks[data.index] = {
                            type = "thinking",
                            thinking = data.content_block.thinking or "",
                            signature = data.content_block.signature or ""
                        }
                    end
                end
            elseif event_type == "content_block_delta" then
                local index = data.index or 0
                local delta = data.delta or {}

                if delta.type == "text_delta" then
                    local text_chunk = delta.text or ""
                    full_content = full_content .. text_chunk
                    on_content(text_chunk)
                elseif delta.type == "thinking_delta" then
                    local thinking_chunk = delta.thinking or ""
                    on_thinking(thinking_chunk)

                    if thinking_blocks[index] then
                        thinking_blocks[index].thinking = thinking_blocks[index].thinking .. thinking_chunk
                    end
                elseif delta.type == "signature_delta" then
                    local signature_chunk = delta.signature or ""

                    if thinking_blocks[index] then
                        thinking_blocks[index].signature = thinking_blocks[index].signature .. signature_chunk
                    end
                elseif delta.type == "input_json_delta" then
                    if not tool_calls[index] then
                        tool_calls[index] = { partial_json = "" }
                    end
                    tool_calls[index].partial_json = tool_calls[index].partial_json .. (delta.partial_json or "")
                end
            elseif event_type == "content_block_stop" then
                local index = data.index or 0

                if content_blocks[index] and content_blocks[index].type == "tool_use" then
                    local json_str = ""
                    if tool_calls[index] and tool_calls[index].partial_json then
                        json_str = tool_calls[index].partial_json
                    end

                    local arguments = {}
                    if json_str ~= "" then
                        local parsed_args, parse_err = json.decode(json_str)
                        if not parse_err then
                            arguments = parsed_args or {}
                        end
                    end

                    local tool_call = {
                        id = content_blocks[index].id or "",
                        name = content_blocks[index].name or "",
                        arguments = arguments
                    }

                    tool_calls[index] = tool_call
                    on_tool_call(tool_call)
                end
            elseif event_type == "message_delta" then
                if data.delta then
                    finish_reason = data.delta.stop_reason
                end
                if data.usage then
                    for k, v in pairs(data.usage) do
                        usage[k] = v
                    end
                end
            elseif event_type == "message_stop" then
                local final_tool_calls = {}
                for _, tool_call in pairs(tool_calls) do
                    if type(tool_call) == "table" and tool_call.id then
                        table.insert(final_tool_calls, tool_call)
                    end
                end

                local final_thinking_blocks = {}
                for _, thinking_block in pairs(thinking_blocks) do
                    if type(thinking_block) == "table" and thinking_block.type == "thinking" then
                        table.insert(final_thinking_blocks, thinking_block)
                    end
                end

                local result = {
                    content = full_content,
                    tool_calls = final_tool_calls,
                    thinking = final_thinking_blocks,
                    finish_reason = finish_reason,
                    usage = usage,
                    metadata = stream_response.metadata or {}
                }

                on_done(result)
                return full_content, nil, result
            elseif event_type == "error" then
                if data and data.error then
                    on_error(data.error)
                    return nil, data.error.message
                end
            end

            ::continue_event::
        end

        ::continue::
    end

    local final_tool_calls = {}
    for _, tool_call in pairs(tool_calls) do
        if type(tool_call) == "table" and tool_call.id then
            table.insert(final_tool_calls, tool_call)
        end
    end

    local final_thinking_blocks = {}
    for _, thinking_block in pairs(thinking_blocks) do
        if type(thinking_block) == "table" and thinking_block.type == "thinking" then
            table.insert(final_thinking_blocks, thinking_block)
        end
    end

    local result = {
        content = full_content,
        tool_calls = final_tool_calls,
        thinking = final_thinking_blocks,
        finish_reason = finish_reason,
        usage = usage,
        metadata = stream_response.metadata or {}
    }

    on_done(result)
    return full_content, nil, result
end

return claude_client