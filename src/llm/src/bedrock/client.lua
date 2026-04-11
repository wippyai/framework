local json = require("json")
local http_client = require("http_client")
local base64 = require("base64")
local env = require("env")
local ctx = require("ctx")
local sigv4 = require("sigv4")
local credentials = require("bedrock_credentials")

local bedrock_client = {}

bedrock_client._http_client = http_client
bedrock_client._env = env
bedrock_client._ctx = ctx
bedrock_client._sigv4 = sigv4
bedrock_client._credentials = credentials

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

    local rate_limits = {}
    for header, value in pairs(http_response.headers) do
        if header:match("^x%-amzn%-bedrock") then
            local key = header:gsub("x%-amzn%-bedrock%-", ""):gsub("%-", "_")
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

-- Make a signed POST request to a bedrock-runtime path
local function signed_request(path, payload, options)
    options = options or {}
    local config = resolve_config()

    local creds, creds_err = bedrock_client._credentials.resolve()
    if not creds then
        return nil, {
            status_code = 401,
            message = creds_err or "AWS credentials are required"
        }
    end

    local full_url = config.base_url .. path
    local host = extract_host(config.base_url)

    local body = ""
    if payload then
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
        method = "POST",
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

-- InvokeModel: POST /model/{modelId}/invoke
function bedrock_client.invoke(model_id, payload, options)
    local path = "/model/" .. model_id .. "/invoke"
    return signed_request(path, payload, options)
end

-- Converse: POST /model/{modelId}/converse
function bedrock_client.converse(model_id, payload, options)
    local path = "/model/" .. model_id .. "/converse"
    return signed_request(path, payload, options)
end

-- ConverseStream: POST /model/{modelId}/converse-stream (returns eventstream)
function bedrock_client.converse_stream(model_id, payload, options)
    options = options or {}
    options.stream = true
    local path = "/model/" .. model_id .. "/converse-stream"
    return signed_request(path, payload, options)
end

-- Parse eventstream headers from binary header block
local function parse_eventstream_headers(buf: string, headers_length: integer): {[string]: string}
    local headers: {[string]: string} = {}
    local pos: integer = 1
    while pos <= headers_length do
        local name_len: integer = string.byte(buf, pos) :: integer
        pos = pos + 1
        local name = buf:sub(pos, pos + name_len - 1)
        pos = pos + name_len
        local header_type: integer = string.byte(buf, pos) :: integer
        pos = pos + 1

        if header_type == 7 then
            local val_len: integer = string.unpack(">I2", buf, pos) :: integer
            pos = pos + 2
            local value = buf:sub(pos, pos + val_len - 1)
            pos = pos + val_len
            headers[name] = value
        else
            break
        end
    end
    return headers
end

local function parse_eventstream_message(buf: string): (string?, {[string]: string}?, integer)
    if #buf < 12 then
        return nil, nil, 0
    end

    local total_length: integer = string.unpack(">I4", buf, 1) :: integer
    local headers_length: integer = string.unpack(">I4", buf, 5) :: integer

    if #buf < (total_length :: number) then
        return nil, nil, 0
    end

    local headers_buf = buf:sub(13, 12 + headers_length)
    local headers = parse_eventstream_headers(headers_buf, headers_length)

    local payload_offset: integer = 13 + headers_length
    local payload_length: integer = total_length - 12 - headers_length - 4

    if payload_length <= 0 then
        return "", headers, total_length
    end

    local payload = buf:sub(payload_offset, payload_offset + payload_length - 1)
    return payload, headers, total_length
end

-- Read all eventstream messages from a binary stream
-- For InvokeModel: events have {"bytes": "base64..."} payload wrapping inner JSON with "type" field
-- For ConverseStream: events have event type in headers (:event-type) and payload is the body directly
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
            local payload, headers, consumed = parse_eventstream_message(buf)
            if consumed == 0 then
                break
            end

            buf = buf:sub(consumed + 1)

            if payload and #payload > 0 then
                local decoded, decode_err = json.decode(payload)
                if not decode_err and decoded then
                    if decoded.bytes then
                        -- InvokeModel format: inner JSON wrapped in base64
                        local raw = base64.decode(tostring(decoded.bytes))
                        if raw then
                            local inner, inner_err = json.decode(raw)
                            if not inner_err and inner then
                                table.insert(events, inner)
                            end
                        end
                    else
                        -- ConverseStream format: payload is the body, event type in headers
                        local event_type = headers and headers[":event-type"]
                        if event_type then
                            local event = {}
                            event[event_type] = decoded
                            table.insert(events, event)
                        else
                            table.insert(events, decoded)
                        end
                    end
                end
            end
        end
    end

    return events
end

-- Process ConverseStream eventstream, dispatching to callbacks
function bedrock_client.process_converse_stream(stream_response, callbacks)
    if not stream_response or not stream_response.stream then
        return nil, "Invalid stream response"
    end

    callbacks = callbacks or {}
    local on_content = callbacks.on_content or function(_chunk: string) end
    local on_tool_call = callbacks.on_tool_call or function(_info: any) end
    local on_thinking = callbacks.on_thinking or function(_chunk: string) end
    local on_error = callbacks.on_error or function(_info: any) end
    local on_done = callbacks.on_done or function(_result: any) end

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

    for _, event in ipairs(events) do
        -- Converse stream events use top-level keys instead of a "type" field
        if event.messageStart then
            -- Nothing to extract at message start for Converse
        elseif event.contentBlockStart then
            local data = event.contentBlockStart
            local index = data.contentBlockIndex or 0
            local start_block = data.start or {}

            content_blocks[index] = start_block

            if start_block.toolUse then
                tool_calls[index] = {
                    id = start_block.toolUse.toolUseId or "",
                    name = start_block.toolUse.name or "",
                    partial_json = ""
                }
            elseif start_block.reasoningContent then
                thinking_blocks[index] = {
                    type = "thinking",
                    thinking = "",
                    signature = ""
                }
            end
        elseif event.contentBlockDelta then
            local data = event.contentBlockDelta
            local index = data.contentBlockIndex or 0
            local delta = data.delta or {}

            if delta.text then
                local text_chunk = tostring(delta.text)
                full_content = full_content .. text_chunk
                on_content(text_chunk)
            elseif delta.reasoningContent then
                local rc = delta.reasoningContent
                if rc.text then
                    on_thinking(tostring(rc.text))
                    if thinking_blocks[index] then
                        thinking_blocks[index].thinking = thinking_blocks[index].thinking .. rc.text
                    end
                end
                if rc.signature then
                    if thinking_blocks[index] then
                        thinking_blocks[index].signature = thinking_blocks[index].signature .. rc.signature
                    end
                end
            elseif delta.toolUse then
                if tool_calls[index] then
                    tool_calls[index].partial_json = tool_calls[index].partial_json .. (delta.toolUse.input or "")
                end
            end
        elseif event.contentBlockStop then
            local index = (event.contentBlockStop.contentBlockIndex or 0)

            if tool_calls[index] and tool_calls[index].partial_json then
                local json_str = tool_calls[index].partial_json
                local arguments = {}
                if json_str ~= "" then
                    local parsed_args, parse_err = json.decode(json_str)
                    if not parse_err then
                        arguments = parsed_args or {}
                    end
                end

                tool_calls[index] = {
                    id = tool_calls[index].id,
                    name = tool_calls[index].name,
                    arguments = arguments
                }
                on_tool_call(tool_calls[index])
            end
        elseif event.messageStop then
            finish_reason = event.messageStop.stopReason
        elseif event.metadata then
            if event.metadata.usage then
                usage = event.metadata.usage
            end
        elseif event.internalServerException or event.modelStreamErrorException
            or event.validationException or event.throttlingException then
            local exc = event.internalServerException or event.modelStreamErrorException
                or event.validationException or event.throttlingException
            on_error({ message = exc.message or "Stream error" })
            return nil, exc.message or "Stream error"
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
