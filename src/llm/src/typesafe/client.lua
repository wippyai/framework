local json = require("json")
local http_client = require("http_client")
local env = require("env")
local ctx = require("ctx")
local time = require("time")

type TypeSafeConfig = {
    api_key: string?,
    base_url: string,
    timeout: number,
    retry: table?,
    headers: any
}

type ResponseMetadata = {
    request_id: string?,
    retry_after: any?
}

local typesafe_client = {}

typesafe_client._http_client = http_client
typesafe_client._env = env
typesafe_client._ctx = ctx

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

local function resolve_config(): TypeSafeConfig
    local ctx_all = typesafe_client._ctx.all() or {}

    local function resolve_string(key: string, default_env: string?): string?
        if ctx_all[key] then
            return tostring(ctx_all[key])
        end
        local env_key = key .. "_env"
        if ctx_all[env_key] then
            local val = typesafe_client._env.get(tostring(ctx_all[env_key]))
            if val and val ~= "" then return val end
        end
        if default_env then
            local val = typesafe_client._env.get(default_env)
            if val and val ~= "" then return val end
        end
        return nil
    end

    local config = {
        api_key = resolve_string("api_key", "TYPESAFE_API_KEY"),
        base_url = resolve_string("base_url", "TYPESAFE_BASE_URL") or "https://api.typesafe.ai/v1",
        timeout = tonumber(resolve_string("timeout", "TYPESAFE_TIMEOUT")) or 60,
        retry = normalize_retry(ctx_all.retry),
        headers = ctx_all.headers
    }
    return config
end

-- HTTP field names are case-insensitive and reach Lua in whatever case the transport kept
local function header_value(headers: any, name: string): any
    local direct = headers[name]
    if direct ~= nil then
        return direct
    end

    local wanted = name:lower()
    for key, value in pairs(headers) do
        if tostring(key):lower() == wanted then
            return value
        end
    end

    return nil
end

local function extract_response_metadata(http_response): ResponseMetadata
    if not http_response or not http_response.headers then
        return {}
    end

    local metadata: ResponseMetadata = {}

    local request_id = header_value(http_response.headers, "x-typesafe-request-id")
    if request_id then
        metadata.request_id = tostring(request_id)
    end

    local retry_after = header_value(http_response.headers, "retry-after")
    if retry_after then
        metadata.retry_after = tonumber(retry_after) or retry_after
    end

    return metadata
end

-- TypeSafe reports a single problem as a detail object and request validation
-- as a list of per-field entries; both collapse into one message.
local function describe_detail(detail: any): string?
    if type(detail) == "string" then
        return detail
    end
    if type(detail) ~= "table" then
        return nil
    end
    if detail.message then
        return tostring(detail.message)
    end

    local parts: {string} = {}
    for _, item in ipairs(detail) do
        if type(item) == "table" and item.msg then
            local location = ""
            if type(item.loc) == "table" then
                location = table.concat(item.loc, ".") .. ": "
            end
            parts[#parts + 1] = location .. tostring(item.msg)
        end
    end

    if #parts > 0 then
        return table.concat(parts, "; ")
    end
    return nil
end

local function parse_error_response(http_response)
    local status_code = http_response and http_response.status_code or 0
    local error_info = {
        status_code = status_code,
        message = "TypeSafe API error: " .. tostring(status_code)
    }

    local body = http_response and http_response.body
    if body and body ~= "" and body ~= "no body" then
        local parsed, decode_err = json.decode(tostring(body))

        if not decode_err and type(parsed) == "table" then
            local described = describe_detail(parsed.detail)
            if described then
                error_info.message = described
            end
            if type(parsed.detail) == "table" and parsed.detail.error_type then
                error_info.error_type = parsed.detail.error_type
            end
        else
            error_info.message = error_info.message .. ": " .. tostring(body)
        end
    end

    error_info.metadata = extract_response_metadata(http_response)

    return error_info
end

local function prepare_headers(api_key, method, additional_headers): {[string]: string}
    local headers: {[string]: string} = {}
    headers["Authorization"] = "Bearer " .. tostring(api_key)

    if method == "POST" then
        headers["Content-Type"] = "application/json"
    end

    if additional_headers then
        for header_name, header_value in pairs(additional_headers) do
            headers[tostring(header_name)] = tostring(header_value)
        end
    end

    return headers
end

function typesafe_client.request(endpoint_path, payload, options)
    options = options or {}
    local method = options.method or "POST"

    local config = resolve_config()

    if not config.api_key then
        return nil, {
            status_code = 401,
            message = "TypeSafe API key is required"
        }
    end

    local full_url = config.base_url .. endpoint_path
    local headers: {[string]: string} = prepare_headers(config.api_key, method, config.headers)

    local http_options: {[string]: any} = {
        headers = headers,
        timeout = tonumber(options.timeout) or config.timeout
    }

    if method == "POST" then
        local body, encode_err = json.encode(payload or {})
        if not body then
            return nil, { status_code = 400, message = "Failed to encode TypeSafe request: " .. tostring(encode_err) }
        end
        http_options.body = body
    end

    local function send_once()
        if method == "GET" then
            return typesafe_client._http_client.get(full_url, http_options)
        end
        return typesafe_client._http_client.post(full_url, http_options)
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

    local parsed, parse_err = json.decode(response.body or "")
    if parse_err or type(parsed) ~= "table" then
        return nil, {
            status_code = response.status_code,
            message = "Failed to parse TypeSafe response: " .. tostring(parse_err or "expected a JSON object"),
            metadata = extract_response_metadata(response)
        }
    end

    parsed.metadata = extract_response_metadata(response)

    return parsed
end

return typesafe_client
