local json = require("json")
local http_client = require("http_client")
local base64 = require("base64")
local env = require("env")
local ctx = require("ctx")
local sigv4 = require("sigv4")
local credentials = require("bedrock_credentials")
local claude_client = require("claude_client")

local bedrock_client = {}

bedrock_client._http_client = http_client
bedrock_client._env = env
bedrock_client._ctx = ctx
bedrock_client._sigv4 = sigv4
bedrock_client._credentials = credentials

bedrock_client.ANTHROPIC_VERSION = "bedrock-2023-05-31"
bedrock_client.SERVICE = "bedrock"

local function resolve_config()
    local ctx_all = bedrock_client._ctx.all() or {}

    local function resolve_string(key, default_env)
        if ctx_all[key] then
            return tostring(ctx_all[key])
        end
        local env_key = key .. "_env"
        if ctx_all[env_key] then
            local val = bedrock_client._env.get(tostring(ctx_all[env_key]))
            if val and val ~= "" then return val end
        end
        if default_env then
            local val = bedrock_client._env.get(default_env)
            if val and val ~= "" then return val end
        end
        return nil
    end

    local region = resolve_string("region", "AWS_REGION")
        or resolve_string("aws_region", "AWS_DEFAULT_REGION")
        or "us-east-1"

    return {
        region = region,
        base_url = resolve_string("base_url", "BEDROCK_BASE_URL")
            or ("https://bedrock-runtime." .. region .. ".amazonaws.com"),
        timeout = tonumber(resolve_string("timeout", "BEDROCK_TIMEOUT")) or 600,
        anthropic_version = resolve_string("anthropic_version") or bedrock_client.ANTHROPIC_VERSION,
        headers = ctx_all.headers
    }
end

local function extract_host(url)
    return url:match("^https?://([^/]+)")
end

local function extract_response_metadata(http_response)
    if not http_response or not http_response.headers then
        return {}
    end

    local metadata = {
        request_id = http_response.headers["x-amzn-requestid"]
            or http_response.headers["x-amz-request-id"],
    }

    -- Extract rate limit headers (Bedrock uses x-amzn-bedrock-* prefix)
    local rate_limits = {}
    for header, value in pairs(http_response.headers) do
        if header:match("^x%-amzn%-bedrock") then
            local key = header:gsub("x%-amzn%-bedrock%-", ""):gsub("%-", "_")
            rate_limits[key] = tonumber(value) or value
        end
        -- Also capture standard Anthropic rate limit headers (Bedrock may forward them)
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
        message = "Bedrock API error: " .. (http_response and http_response.status_code or "connection failed")
    }

    if http_response and http_response.headers then
        error_info.request_id = http_response.headers["x-amzn-requestid"]
            or http_response.headers["x-amz-request-id"]
    end

    local resp = http_response :: any
    local error_body = resp and resp.body
    if resp and resp.stream then
        error_body = resp.stream:read(4096)
    end

    if error_body and #error_body > 0 then
        local parsed, parse_err = json.decode(tostring(error_body))
        if not parse_err and parsed then
            if parsed.error then
                error_info.error = parsed.error
                error_info.message = parsed.error.message or error_info.message
            elseif parsed.message then
                error_info.message = parsed.message
            elseif parsed.Message then
                error_info.message = parsed.Message
            end
        end
    end

    error_info.metadata = extract_response_metadata(http_response :: any)
    return error_info
end

function bedrock_client.invoke_path(model_id)
    return "/model/" .. model_id .. "/invoke"
end

function bedrock_client.invoke_stream_path(model_id)
    return "/model/" .. model_id .. "/invoke-with-response-stream"
end

-- Make a signed request to Bedrock Runtime
function bedrock_client.request(model_id, payload, options)
    options = options or {}
    local method = options.method or "POST"
    local config = resolve_config()

    local creds, creds_err = bedrock_client._credentials.resolve()
    if not creds then
        return nil, {
            status_code = 401,
            message = creds_err or "AWS credentials are required"
        }
    end

    local path
    if options.stream then
        path = bedrock_client.invoke_stream_path(model_id)
    else
        path = bedrock_client.invoke_path(model_id)
    end

    local full_url = config.base_url .. path
    local host = extract_host(config.base_url)

    if payload then
        payload.anthropic_version = config.anthropic_version
    end

    local body = ""
    if method == "POST" or method == "PUT" or method == "PATCH" then
        payload = payload or {}
        body = json.encode(payload)
    end

    local headers: {[string]: string} = {
        ["content-type"] = "application/json",
        ["accept"] = "application/json"
    }

    if config.headers then
        for header_name, header_value in pairs(config.headers) do
            headers[tostring(header_name)] = tostring(header_value)
        end
    end

    local signed_headers, sign_err = bedrock_client._sigv4.sign_request({
        method = method,
        host = host,
        uri = path,
        headers = headers,
        body = body,
        region = config.region,
        service = bedrock_client.SERVICE,
        access_key = creds.access_key,
        secret_key = creds.secret_key,
        session_token = creds.session_token
    })

    if sign_err then
        return nil, {
            status_code = 0,
            message = "Request signing failed: " .. tostring(sign_err)
        }
    end

    local request_opts: {[string]: any} = {
        timeout = tonumber(options.timeout) or config.timeout,
        body = body
    }
    request_opts.headers = signed_headers

    if options.stream then
        request_opts.stream = true
    end

    local response, err = (bedrock_client._http_client :: any).post(full_url, request_opts)

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

    local parsed, parse_err = json.decode(tostring(response.body))
    if parse_err then
        return nil, {
            status_code = response.status_code,
            message = "Failed to parse Bedrock response: " .. parse_err,
            metadata = extract_response_metadata(response)
        }
    end

    parsed.metadata = extract_response_metadata(response :: any)
    return parsed
end

-- Parse a single AWS eventstream message from a binary buffer.
-- Returns: payload string, bytes consumed, or nil and error.
local function parse_eventstream_message(buf)
    if #buf < 12 then
        return nil, 0
    end

    local total_length = string.unpack(">I4", buf, 1)
    local headers_length = string.unpack(">I4", buf, 5)

    if #buf < total_length then
        return nil, 0
    end

    -- payload sits after prelude (12) + headers, before trailing CRC (4)
    local payload_offset = 13 + headers_length
    local payload_length = total_length - 12 - headers_length - 4

    if payload_length <= 0 then
        return "", total_length
    end

    local payload = buf:sub(payload_offset, payload_offset + payload_length - 1)
    return payload, total_length
end

-- Read all eventstream messages from a binary stream, yielding decoded JSON payloads.
-- Each payload contains a "type" field matching the Claude SSE event types.
local function read_eventstream_events(stream)
    local events = {}
    local buf = ""

    while true do
        local chunk, err = stream:read(0)

        if err then
            return nil, err
        end

        if not chunk or #chunk == 0 then
            break
        end

        buf = buf .. chunk

        while #buf >= 12 do
            local payload, consumed = parse_eventstream_message(buf)
            if consumed == 0 then
                break
            end

            buf = buf:sub(consumed + 1)

            if payload and #payload > 0 then
                local decoded, decode_err = json.decode(payload)
                if not decode_err and decoded then
                    if decoded.bytes then
                        local raw = base64.decode(tostring(decoded.bytes))
                        if raw then
                            local inner, inner_err = json.decode(raw)
                            if not inner_err and inner then
                                table.insert(events, inner)
                            end
                        end
                    else
                        table.insert(events, decoded)
                    end
                end
            end
        end
    end

    return events
end

-- Process Bedrock eventstream, dispatching to the same callbacks as Claude SSE.
function bedrock_client.process_stream(stream_response, callbacks)
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

    local events, stream_err = read_eventstream_events(stream_response.stream)
    if stream_err then
        on_error({ message = stream_err })
        return nil, stream_err
    end

    for _, data in ipairs(events) do
        local event_type = data.type

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
            if data.error then
                on_error(data.error)
                return nil, data.error.message
            end
        end
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

return bedrock_client
