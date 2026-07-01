local json = require("json")
local http_client = require("http_client")
local env = require("env")
local ctx = require("ctx")
local time = require("time")

type OpenAIConfig = {
    api_key: string?,
    base_url: string,
    organization: string?,
    timeout: number,
    retry: table?,
    headers: {[string]: string}?
}

type ResponseMetadata = {
    request_id: string?,
    organization: string?,
    processing_ms: number?,
    version: string?,
    rate_limits: {[string]: string | number}?
}

local openai_client = {}

openai_client._http_client = http_client
openai_client._env = env
openai_client._ctx = ctx

local function normalize_retry(raw)
    if type(raw) ~= "table" then return nil end
    local attempts = math.floor(tonumber(raw.attempts) or 0)
    if attempts <= 0 then return nil end
    if attempts > 10 then attempts = 10 end

    local backoff_ms = math.floor(tonumber(raw.backoff_ms) or 500)
    if backoff_ms < 0 then backoff_ms = 0 end
    if backoff_ms > 60000 then backoff_ms = 60000 end

    return { attempts = attempts, backoff_ms = backoff_ms }
end

local function retryable_error(error_info)
    local status = tonumber(error_info and error_info.status_code) or 0
    return status == 0
        or status == 408
        or status == 409
        or status == 425
        or status == 429
        or (status >= 500 and status < 600)
end

local function sleep_for_retry(retry, attempt)
    if not retry then return end
    local delay_ms = (tonumber(retry.backoff_ms) or 500) * (2 ^ math.max(0, attempt - 1))
    if delay_ms <= 0 then return end
    if delay_ms > 60000 then delay_ms = 60000 end
    time.sleep(tostring(math.floor(delay_ms)) .. "ms")
end

local function resolve_config()
    local ctx_all = openai_client._ctx.all() or {}

    local function resolve_string(key: string, default_env: string?): string?
        if ctx_all[key] then
            return tostring(ctx_all[key])
        end
        local env_key = key .. "_env"
        if ctx_all[env_key] then
            local val = openai_client._env.get(tostring(ctx_all[env_key]))
            if val and val ~= "" then return val end
        end
        if default_env then
            local val = openai_client._env.get(default_env)
            if val and val ~= "" then return val end
        end
        return nil
    end

    local config = {
        api_key = resolve_string("api_key", "OPENAI_API_KEY"),
        base_url = resolve_string("base_url", "OPENAI_BASE_URL") or "https://api.openai.com/v1",
        organization = resolve_string("organization", "OPENAI_ORGANIZATION"),
        timeout = tonumber(resolve_string("timeout", "OPENAI_TIMEOUT")) or 600,
        retry = normalize_retry(ctx_all.retry),
        headers = ctx_all.headers
    }
    return config
end

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

local function parse_error_response(http_response)
    local error_info = {
        status_code = http_response and http_response.status_code or 0,
        message = "OpenAI API error: " .. (http_response and http_response.status_code or "connection failed")
    }

    if http_response and http_response.headers and http_response.headers["x-request-id"] then
        error_info.request_id = http_response.headers["x-request-id"]
    end

    local resp = http_response :: any
    local error_body = resp and resp.body
    if resp and resp.stream and (not error_body or error_body == "" or error_body == "no body") then
        error_body = resp.stream:read(4096)
    end

    if error_body and error_body ~= "" and error_body ~= "no body" then
        local parsed, decode_err = json.decode(tostring(error_body))
        if not decode_err and parsed and parsed.error then
            error_info.message = parsed.error.message or error_info.message
            error_info.code = parsed.error.code
            error_info.param = parsed.error.param
            error_info.type = parsed.error.type
        end
    end

    error_info.metadata = extract_response_metadata(http_response :: any)
    return error_info
end

local function prepare_headers(api_key, organization, method, additional_headers): {[string]: string}
    local headers: {[string]: string} = {}
    headers["Authorization"] = "Bearer " .. tostring(api_key)

    if method == "POST" or method == "PUT" or method == "PATCH" then
        headers["Content-Type"] = "application/json"
    end

    if organization then
        headers["OpenAI-Organization"] = tostring(organization)
    end

    if additional_headers then
        for header_name, header_value in pairs(additional_headers) do
            headers[tostring(header_name)] = tostring(header_value)
        end
    end

    return headers
end

function openai_client.request(endpoint_path, payload, options)
    options = options or {}
    local method = options.method or "POST"

    local config = resolve_config()

    if not config.api_key then
        return nil, {
            status_code = 401,
            message = "OpenAI API key is required"
        }
    end

    local full_url = config.base_url .. endpoint_path
    local headers: {[string]: string} = prepare_headers(config.api_key, config.organization, method, config.headers)

    local http_options: {[string]: any} = {
        headers = headers,
        timeout = tonumber(options.timeout) or config.timeout,
    }

    if method == "POST" or method == "PUT" or method == "PATCH" then
        payload = payload or {}
        if options.stream then
            payload.stream = true
            http_options.stream = true
        end
        http_options.body = json.encode(payload)
    end

    local function send_once()
        if method == "GET" then
            return openai_client._http_client.get(full_url, http_options)
        elseif method == "DELETE" then
            return openai_client._http_client.delete(full_url, http_options)
        elseif method == "PUT" then
            return openai_client._http_client.put(full_url, http_options)
        elseif method == "PATCH" then
            return openai_client._http_client.patch(full_url, http_options)
        end
        return openai_client._http_client.post(full_url, http_options)
    end

    local retry = normalize_retry(options.retry) or config.retry
    local response, err
    local request_error = nil
    local retry_count = 0
    while true do
        response, err = send_once()

        if not response then
            request_error = {
                status_code = 0,
                message = err and ("Connection failed: " .. tostring(err)) or "Connection failed"
            }
        elseif response.status_code < 200 or response.status_code >= 300 then
            request_error = parse_error_response(response)
        else
            request_error = nil
        end

        if not request_error then break end
        if not retry or retry_count >= retry.attempts or not retryable_error(request_error) then
            return nil, request_error
        end

        retry_count = retry_count + 1
        sleep_for_retry(retry, retry_count)
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
            message = "Failed to parse OpenAI response: " .. parse_err,
            metadata = extract_response_metadata(response)
        }
    end

    parsed.metadata = extract_response_metadata(response :: any)
    return parsed
end

-- Process a /v1/responses streaming SSE response.
-- Each chunk is a `data: <json>` line; the JSON carries a `type` field that
-- names the event (e.g. response.output_text.delta). Multiple events are
-- separated by a blank line (\n\n).
function openai_client.process_stream(stream_response, callbacks)
    if not stream_response or not stream_response.stream then
        return nil, "Invalid stream response"
    end

    local full_content = ""
    local final_response = nil
    local final_usage = nil
    local response_id = nil
    local response_status = nil
    local incomplete_reason = nil
    local metadata = stream_response.metadata or {}

    local pending_calls = {}
    local sent_calls = {}

    callbacks = callbacks or {}
    local on_content = callbacks.on_content or function(...) end
    local on_tool_call = callbacks.on_tool_call or function(...) end
    local on_reasoning = callbacks.on_reasoning or function(...) end
    local on_error = callbacks.on_error or function(...) end
    local on_done = callbacks.on_done or function(...) end

    local function emit_call(item_id)
        local call = pending_calls[item_id]
        if not call or not call.call_id or not call.name then return end
        if sent_calls[call.call_id] then return end
        sent_calls[call.call_id] = true
        on_tool_call({
            id = call.call_id,
            name = call.name,
            arguments = call.arguments or ""
        })
    end

    local function build_result()
        local tool_calls_out = {}
        for _, call in pairs(pending_calls) do
            if call.call_id and call.name then
                table.insert(tool_calls_out, {
                    id = call.call_id,
                    name = call.name,
                    arguments = call.arguments or ""
                })
            end
        end

        return {
            content = full_content,
            tool_calls = tool_calls_out,
            usage = final_usage,
            status = response_status,
            incomplete_reason = incomplete_reason,
            response_id = response_id,
            response = final_response,
            metadata = metadata
        }
    end

    local leftover = ""

    while true do
        local chunk, err = stream_response.stream:read()

        if err then
            on_error(err)
            return nil, err
        end

        if not chunk then break end
        if chunk == "" then goto continue end

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

        for data_line in complete:gmatch('data:%s*(.-)%s*\n') do
            if data_line == "" or data_line == "[DONE]" then
                goto continue_line
            end

            local parsed, parse_err = json.decode(tostring(data_line))
            if parse_err or not parsed then
                goto continue_line
            end

            local etype = parsed.type

            if etype == "response.created" or etype == "response.in_progress" then
                if parsed.response then
                    if parsed.response.id then response_id = parsed.response.id end
                    if parsed.response.status then response_status = parsed.response.status end
                end
            elseif etype == "response.output_item.added" then
                local item = parsed.item
                if item and item.type == "function_call" then
                    local key = item.id or item.call_id
                    if key then
                        pending_calls[key] = pending_calls[key] or { arguments = "" }
                        local entry = pending_calls[key] :: any
                        entry.call_id = item.call_id or entry.call_id
                        entry.name = item.name or entry.name
                        if item.arguments and item.arguments ~= "" then
                            entry.arguments = item.arguments
                        end
                    end
                end
            elseif etype == "response.output_text.delta" then
                if parsed.delta and parsed.delta ~= "" then
                    full_content = full_content .. parsed.delta
                    on_content(parsed.delta)
                end
            elseif etype == "response.function_call_arguments.delta" then
                local key = parsed.item_id
                if key then
                    pending_calls[key] = pending_calls[key] or { arguments = "" }
                    if parsed.delta then
                        pending_calls[key].arguments = (pending_calls[key].arguments or "") .. parsed.delta
                    end
                end
            elseif etype == "response.function_call_arguments.done" then
                local key = parsed.item_id
                if key then
                    pending_calls[key] = pending_calls[key] or { arguments = "" }
                    if parsed.arguments then
                        pending_calls[key].arguments = parsed.arguments
                    end
                    if parsed.name then
                        pending_calls[key].name = parsed.name
                    end
                    emit_call(key)
                end
            elseif etype == "response.output_item.done" then
                local item = parsed.item
                if item and item.type == "function_call" then
                    local key = item.id or item.call_id
                    if key then
                        pending_calls[key] = pending_calls[key] or { arguments = "" }
                        local entry = pending_calls[key] :: any
                        entry.call_id = item.call_id or entry.call_id
                        entry.name = item.name or entry.name
                        if item.arguments and item.arguments ~= "" then
                            entry.arguments = item.arguments
                        end
                        emit_call(key)
                    end
                end
            elseif etype == "response.reasoning_summary_text.delta" then
                if parsed.delta and parsed.delta ~= "" then
                    on_reasoning(parsed.delta)
                end
            elseif etype == "response.completed" then
                if parsed.response then
                    final_response = parsed.response
                    final_usage = parsed.response.usage
                    response_status = parsed.response.status or "completed"
                    response_id = parsed.response.id or response_id
                    if parsed.response.incomplete_details then
                        incomplete_reason = parsed.response.incomplete_details.reason
                    end
                end
            elseif etype == "response.incomplete" then
                if parsed.response then
                    final_response = parsed.response
                    final_usage = parsed.response.usage
                    response_status = parsed.response.status or "incomplete"
                    if parsed.response.incomplete_details then
                        incomplete_reason = parsed.response.incomplete_details.reason
                    end
                end
            elseif etype == "response.failed" or etype == "error" or etype == "response.error" then
                local err_payload = parsed.response and parsed.response.error or parsed.error or parsed
                local error_info = {
                    message = (err_payload and err_payload.message) or "Responses stream failed",
                    code = err_payload and err_payload.code,
                    type = err_payload and err_payload.type,
                    param = err_payload and err_payload.param
                }
                on_error(error_info)
                return nil, error_info.message, { error = error_info }
            end

            ::continue_line::
        end

        ::continue::
    end

    for key, _ in pairs(pending_calls) do
        emit_call(key)
    end

    local result = build_result()
    on_done(result)
    return full_content, nil, result
end

return openai_client
