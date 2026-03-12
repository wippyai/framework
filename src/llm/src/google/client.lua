local json = require("json")
local http_client = require("http_client")
local output = require("output")

type StreamInput = {
    stream: any,
    metadata: table?,
}

type StreamResult = {
    content: string,
    tool_calls: {any},
    finish_reason: string?,
    usage: any?,
    metadata: table,
}

type StreamCallbacks = {
    on_content: ((text: string) -> nil)?,
    on_tool_call: ((part: any) -> nil)?,
    on_thinking: ((text: string) -> nil)?,
    on_error: ((error_info: any) -> nil)?,
    on_done: ((result: StreamResult) -> nil)?,
}

local client = {
    _http_client = http_client
}

local function extract_response_metadata(response_body: any)
    if not response_body then
        return {}
    end

    local metadata = {}

    metadata.model_version = response_body.modelVersion
    metadata.response_id = response_body.responseId
    metadata.create_time = response_body.createTime

    return metadata
end

local function parse_error_response(http_response)
    local error_info = {
        status_code = http_response.status_code,
        message = "Google API error: " .. (http_response.status_code or "unknown status")
    }

    if http_response.body then
        local parsed, decode_err = json.decode(http_response.body)
        if not decode_err and parsed then
            error_info.metadata = extract_response_metadata(parsed)
            if parsed.error then
                error_info.message = parsed.error.message or error_info.message
                error_info.code = parsed.error.code
                error_info.param = parsed.error.param
                error_info.type = parsed.error.type
            end
        end
    end

    return error_info
end

function client.process_stream(stream_response: StreamInput, callbacks: StreamCallbacks?): (string?, string?, StreamResult?)
    if not stream_response or not stream_response.stream then
        return nil, "Invalid stream response"
    end

    callbacks = callbacks or {}
    local on_content = callbacks.on_content or function(_text: string) end
    local on_tool_call = callbacks.on_tool_call or function(_part: any) end
    local on_thinking = callbacks.on_thinking or function(_text: string) end
    local on_error = callbacks.on_error or function(_error_info: any) end
    local on_done = callbacks.on_done or function(_result: StreamResult) end

    local full_content = ""
    local tool_calls: {any} = {}
    local finish_reason: string? = nil
    local usage: any = nil
    local metadata = stream_response.metadata or {}

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

        for data_line in chunk:gmatch('data:%s*(.-)%s*\n') do
            if data_line == "" then
                goto continue_line
            end

            local parsed, parse_err = json.decode(data_line)
            if parse_err then
                goto continue_line
            end

            if parsed.error then
                local error_info = {
                    message = parsed.error.message,
                    code = parsed.error.code,
                    status = parsed.error.status
                }
                on_error(error_info)
                return nil, tostring(error_info.message)
            end

            if parsed.modelVersion then
                metadata.model_version = parsed.modelVersion
            end
            if parsed.responseId then
                metadata.response_id = parsed.responseId
            end

            if parsed.candidates and parsed.candidates[1] then
                local candidate = parsed.candidates[1]

                if candidate.content and candidate.content.parts then
                    for _, part in ipairs(candidate.content.parts) do
                        if part.functionCall then
                            table.insert(tool_calls, part)
                            on_tool_call(part)
                        elseif part.text then
                            local text = tostring(part.text)
                            if part.thought == true then
                                on_thinking(text)
                            else
                                full_content = full_content .. text
                                on_content(text)
                            end
                        end
                    end
                end

                if candidate.finishReason then
                    finish_reason = tostring(candidate.finishReason)
                end
            end

            if parsed.usageMetadata then
                usage = parsed.usageMetadata
            end

            ::continue_line::
        end

        ::continue::
    end

    local result: StreamResult = {
        content = full_content,
        tool_calls = tool_calls,
        finish_reason = finish_reason,
        usage = usage,
        metadata = metadata
    }

    on_done(result)
    return full_content, nil, result
end

--- Process a streaming response and send chunks via output.streamer.
--- Returns an aggregated Google-like response compatible with map_success_response().
local function handle_stream_response(response, http_options)
    local reply_to = http_options.stream_reply_to :: string?
    local topic = http_options.stream_topic :: string?
    local streamer = output.streamer(reply_to, topic, http_options.stream_buffer_size or 10)
    if not streamer then
        return nil, {
            status_code = 500,
            message = "Failed to create streamer"
        }
    end

    local full_content = ""
    local tool_call_parts: {any} = {}
    local finish_reason: string? = nil
    local usage_metadata: any = nil
    local response_metadata: table = {}

    local callbacks = {
        on_content = function(chunk: string)
            full_content = full_content .. chunk
            streamer:buffer_content(chunk)
        end,

        on_tool_call = function(tool_part: any)
            table.insert(tool_call_parts, tool_part)
            if tool_part.functionCall then
                streamer:send_tool_call(
                    tostring(tool_part.functionCall.name),
                    tostring(tool_part.functionCall.args or "{}"),
                    tostring(tool_part.functionCall.name)
                )
            end
        end,

        on_thinking = function(text: string)
            streamer:send_thinking(text)
        end,

        on_error = function(error_info: any)
            streamer:send_error("server_error", tostring(error_info.message), nil)
        end,

        on_done = function(result: StreamResult)
            streamer:flush()
            finish_reason = result.finish_reason
            usage_metadata = result.usage
            response_metadata = result.metadata
        end,
    }

    local _, stream_err = client.process_stream(
        { stream = response.stream, metadata = {} },
        callbacks :: StreamCallbacks
    )

    if stream_err then
        return nil, {
            status_code = 500,
            message = "Stream processing failed: " .. tostring(stream_err)
        }
    end

    -- Reconstruct Google-like response
    local parts = {}
    if full_content ~= "" then
        table.insert(parts, { text = full_content })
    end
    for _, tc_part in ipairs(tool_call_parts) do
        table.insert(parts, tc_part)
    end

    return {
        candidates = {
            {
                content = { parts = parts, role = "model" },
                finishReason = finish_reason
            }
        },
        usageMetadata = usage_metadata,
        modelVersion = response_metadata.model_version,
        responseId = response_metadata.response_id,
        metadata = response_metadata,
        status_code = response.status_code or 200
    }
end

function client.request(method, url, http_options)
    http_options.headers["Accept"] = "application/json"

    if http_options.stream then
        url = url .. "?alt=sse"
        http_options.headers["Accept"] = "text/event-stream"
    end

    local response = nil
    local err = nil
    if method == "GET" then
        response, err = client._http_client.get(url, http_options)
    else
        http_options.headers["Content-Type"] = "application/json"
        response, err = client._http_client.post(url, http_options)
    end

    if not response then
        return nil, {
            status_code = 0,
            message = "Connection failed: " .. tostring(err)
        }
    end

    if response.status_code < 200 or response.status_code >= 300 then
        if http_options.stream and response.stream and not response.body then
            local body_data = response.stream:read()
            response.body = body_data
        end
        local parsed_error = parse_error_response(response)
        return nil, parsed_error
    end

    -- Streaming: process stream, send chunks via streamer, return aggregated response
    if http_options.stream and response.stream then
        return handle_stream_response(response, http_options)
    end

    local parsed, parse_err = json.decode(response.body)
    if parse_err then
        local parse_error = {
            status_code = response.status_code,
            message = "Failed to parse Google response: " .. parse_err,
            metadata = {}
        }
        return nil, parse_error
    end

    parsed.metadata = extract_response_metadata(parsed)
    parsed.status_code = response.status_code

    return parsed
end

return client
