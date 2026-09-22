local json = require("json")
local http_client = require("http_client")
local env = require("env")
local ctx = require("ctx")
local transport = require("transport")

type TypeSafeConfig = {
    api_key: string?,
    base_url: string,
    timeout: number,
    retry: transport.Retry?,
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

local function resolve_config(): TypeSafeConfig
    local ctx_all = (typesafe_client._ctx.all() or {}) :: {[string]: any}

    local function resolve_string(key: string, default_env: string?): string?
        return transport.config_value(ctx_all, typesafe_client._env, key, default_env)
    end

    local config = {
        api_key = resolve_string("api_key", "TYPESAFE_API_KEY"),
        base_url = resolve_string("base_url", "TYPESAFE_BASE_URL") or "https://api.typesafe.ai/v1",
        timeout = tonumber(resolve_string("timeout", "TYPESAFE_TIMEOUT")) or 60,
        retry = transport.normalize_retry(ctx_all.retry),
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

local function parse_error_response(http_response: transport.HttpResponse): transport.RequestError
    local error_info: transport.RequestError = {
        status_code = http_response.status_code,
        message = "TypeSafe API error: " .. tostring(http_response.status_code)
    }

    local body = http_response.body
    if body and body ~= "" and body ~= "no body" then
        local parsed, decode_err = json.decode(body)

        if not decode_err and type(parsed) == "table" then
            local described = describe_detail(parsed.detail)
            if described then
                error_info.message = described
            end
            if type(parsed.detail) == "table" and parsed.detail.error_type then
                error_info.error_type = tostring(parsed.detail.error_type)
            end
        else
            error_info.message = error_info.message .. ": " .. body
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
        return transport.dispatch(typesafe_client._http_client, method, full_url, http_options)
    end

    local retry = transport.normalize_retry(options.retry) or config.retry
    local response, request_error = transport.send(send_once, parse_error_response, retry)
    if not response then
        return nil, request_error
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
