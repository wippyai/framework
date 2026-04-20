local json = require("json")
local http_client = require("http_client")
local env = require("env")
local ctx = require("ctx")

type ClaudeConfig = {
    api_key: string?,
    base_url: string,
    api_version: string,
    beta_features: {string},
    timeout: number,
    headers: {[string]: string}?
}

type ResponseMetadata = {
    request_id: string?,
    processing_ms: number?,
    rate_limits: {[string]: string | number}?
}

local claude_client = {}

claude_client._http_client = http_client
claude_client._env = env
claude_client._ctx = ctx

claude_client.ENDPOINTS = {
    MESSAGES = "/v1/messages"
}

local function resolve_config()
    local ctx_all = claude_client._ctx.all() or {}

    local function resolve_string(key: string, default_env: string?): string?
        if ctx_all[key] then
            return tostring(ctx_all[key])
        end
        local env_key = key .. "_env"
        if ctx_all[env_key] then
            local val = claude_client._env.get(tostring(ctx_all[env_key]))
            if val and val ~= "" then return val end
        end
        if default_env then
            local val = claude_client._env.get(default_env)
            if val and val ~= "" then return val end
        end
        return nil
    end

    local config = {
        api_key = resolve_string("api_key", "ANTHROPIC_API_KEY"),
        base_url = resolve_string("base_url", "ANTHROPIC_BASE_URL") or "https://api.anthropic.com",
        api_version = resolve_string("api_version", "ANTHROPIC_API_VERSION") or "2023-06-01",
        beta_features = ctx_all.beta_features or {},
        timeout = tonumber(resolve_string("timeout", "ANTHROPIC_TIMEOUT")) or 600,
        headers = ctx_all.headers
    }
    return config
end

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

    error_info.metadata = extract_response_metadata(http_response :: any)
    return error_info
end

local function prepare_headers(api_key, api_version, beta_features, method, additional_headers): {[string]: string}
    local headers: {[string]: string} = {}
    headers["x-api-key"] = tostring(api_key)
    headers["anthropic-version"] = tostring(api_version)

    if method == "POST" or method == "PUT" or method == "PATCH" then
        headers["content-type"] = "application/json"
    end

    if beta_features and #beta_features > 0 then
        headers["anthropic-beta"] = table.concat(beta_features, ",")
    end

    if additional_headers then
        for header_name, header_value in pairs(additional_headers) do
            headers[tostring(header_name)] = tostring(header_value)
        end
    end

    return headers
end


function claude_client.request(endpoint_path, payload, options)
    options = options or {}
    local method = options.method or "POST"

    local config = resolve_config()

    if not config.api_key then
        return nil, {
            status_code = 401,
            message = "Claude API key is required"
        }
    end

    local full_url = config.base_url .. endpoint_path
    local headers: {[string]: string} = prepare_headers(config.api_key, config.api_version, config.beta_features, method, config.headers)

    local http_options: {[string]: any} = {
        headers = headers,
        timeout = tonumber(options.timeout) or config.timeout,
    }

    if method == "POST" or method == "PUT" or method == "PATCH" then
        payload = payload or {}

        if options.stream then
            payload.stream = true
        end

        http_options.body = json.encode(payload)

        if options.stream then
            http_options.stream = true
        end
    end

    local response, err
    if method == "GET" then
        response, err = claude_client._http_client.get(full_url, http_options)
    elseif method == "DELETE" then
        response, err = claude_client._http_client.delete(full_url, http_options)
    elseif method == "PUT" then
        response, err = claude_client._http_client.put(full_url, http_options)
    elseif method == "PATCH" then
        response, err = claude_client._http_client.patch(full_url, http_options)
    else
        response, err = claude_client._http_client.post(full_url, http_options)
    end

    if not response then
        return nil, {
            status_code = 0,
            message = err and ("Connection failed: " .. tostring(err)) or "Connection failed"
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

    local parsed, parse_err = json.decode(response.body or "")
    if parse_err then
        return nil, {
            status_code = response.status_code,
            message = "Failed to parse Claude response: " .. parse_err,
            metadata = extract_response_metadata(response)
        }
    end

    parsed.metadata = extract_response_metadata(response :: any)
    return parsed
end

function claude_client.process_stream(stream_response, callbacks)
    if not stream_response or not stream_response.stream then
        return nil, "Invalid stream response"
    end

    callbacks = callbacks or {}
    local on_content = callbacks.on_content or function(...) end
    local on_tool_call = callbacks.on_tool_call or function(...) end
    local on_thinking = callbacks.on_thinking or function(...) end
    local on_error = callbacks.on_error or function(...) end
    local on_done = callbacks.on_done or function(...) end

    local full_content = ""
    local tool_calls = {}
    local thinking_blocks = {}
    local finish_reason = nil
    local usage = {}
    local content_blocks = {}
    local leftover = ""

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

        if leftover ~= "" then
            chunk = leftover .. chunk
            leftover = ""
        end

        local last_boundary = 0
        local pos = 1
        while true do
            local found = chunk:find("\n\n", pos, true)
            if not found then break end
            last_boundary = found + 1
            pos = found + 2
        end

        if last_boundary == 0 then
            leftover = chunk
            goto continue
        end

        local complete = chunk:sub(1, last_boundary)
        if last_boundary < #chunk then
            leftover = chunk:sub(last_boundary + 1)
        end

        for event_type, data_json in complete:gmatch("event: ([^\n]+)\ndata: ([^\n]+)") do
            local data, decode_err = json.decode(tostring(data_json))
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
