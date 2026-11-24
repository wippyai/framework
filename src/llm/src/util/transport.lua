local time = require("time")
local json = require("json")

type Retry = {
    attempts: number,
    backoff_ms: number
}

type HttpResponse = {
    status_code: number,
    body: string?,
    headers: {[string]: any}?,
    stream: any?
}

-- Request failure shared by every driver. status_code 0 means the request
-- never reached the provider; the optional fields carry what a provider
-- reports about the failure.
type RequestError = {
    status_code: number,
    message: string,
    stream_started: boolean?,
    error: any?,
    error_type: string?,
    type: string?,
    code: any?,
    param: any?,
    request_id: string?,
    provider_name: string?,
    nested_error: any?,
    detailed_message: string?,
    metadata: any?
}

type HealthFailure = {
    success: boolean,
    status: string,
    message: string
}

local MAX_ATTEMPTS = 10
local DEFAULT_BACKOFF_MS = 500
local MAX_BACKOFF_MS = 60000

local transport = {}

transport._time = time

-- Snapshot only values sent on this request; configured headers may carry
-- credentials under arbitrary names. Generated protocol headers are not secrets.
function transport.request_secrets(headers: {[string]: string}, configured_headers: {[string]: any}?): {string}
    local secrets: {string} = {}
    local seen: {[string]: boolean} = {}
    local configured: {[string]: boolean} = {}
    for name in pairs(configured_headers or {}) do configured[tostring(name):lower()] = true end
    local function add(value: string?)
        if value and value ~= "" and not seen[value] then
            seen[value] = true
            secrets[#secrets + 1] = value
        end
    end
    for name, value in pairs(headers) do
        local lower = name:lower()
        if configured[lower] or lower == "authorization" or lower == "x-api-key"
            or lower == "x-goog-api-key" or lower == "x-amz-security-token" then
            add(value)
            add(value:match("^[Bb][Ee][Aa][Rr][Ee][Rr]%s+(.+)$"))
            if lower == "authorization" then
                add(value:match("Credential=([^/ ,]+)"))
                add(value:match("Signature=([^ ,]+)"))
            end
        end
    end
    return secrets
end

-- Replace credential substrings and their serialized forms, including table keys
-- and nested diagnostics, without interpreting patterns in secrets.
function transport.redact_error(value: any, secrets: {string}?): any
    if not secrets or #secrets == 0 then return value end
    local variants: {string} = {}
    local seen: {[string]: boolean} = {}
    local function add(value: string)
        if not seen[value] then
            seen[value] = true
            variants[#variants + 1] = value
        end
    end
    for _, secret in ipairs(secrets) do
        if secret ~= "" then
            add(secret)
            add(json.encode(secret):sub(2, -2))
            local encoded = secret:gsub("([^%w%-._~])", function(char: string): string
                return string.format("%%%02X", string.byte(char))
            end)
            add(encoded)
            add(encoded:gsub("%%(%x%x)", string.lower))
            local form = encoded:gsub("%%20", "+")
            add(form)
            add(form:gsub("%%(%x%x)", string.lower))
        end
    end
    table.sort(variants, function(a: string, b: string): boolean
        if #a == #b then return a < b end
        return #a > #b
    end)
    local function redact_string(message: string): string
        local parts: {string} = {}
        local position = 1
        while position <= #message do
            local first: integer? = nil
            local last: integer = 0
            for _, secret in ipairs(variants) do
                local start_at, end_at = message:find(secret, position, true)
                if start_at and end_at and (not first or start_at < first) then
                    first, last = start_at, end_at
                end
            end
            if not first then
                parts[#parts + 1] = message:sub(position)
                break
            end
            parts[#parts + 1] = message:sub(position, first - 1)
            parts[#parts + 1] = "[REDACTED]"
            position = last + 1
        end
        return table.concat(parts)
    end
    local copies: {[any]: any} = {}
    local function redact(item: any): any
        if type(item) == "string" then return redact_string(item) end
        if type(item) == "userdata" then
            return errors.new({ message = redact_string(item:message()), kind = item:kind(),
                retryable = item:retryable(), details = redact(item:details()) })
        end
        if type(item) ~= "table" then return item end
        if copies[item] then return copies[item] end
        local result = {}
        copies[item] = result
        for key, nested in pairs(item) do result[redact(key)] = redact(nested) end
        return result
    end
    return redact(value)
end

function transport.now_ms(): number
    return math.floor(transport._time.now():unix_nano() / 1000000)
end

function transport.timeout_seconds(value: any): (number?, string?)
    local seconds = nil
    if type(value) == "number" then
        seconds = value
    elseif type(value) == "string" then
        seconds = tonumber(value)
        if seconds == nil then
            local duration = time.parse_duration(value)
            if duration then seconds = duration:seconds() end
        end
    end
    if seconds and seconds > 0 and seconds < math.huge then return seconds, nil end
    return nil, "Invalid timeout " .. string.format("%q", tostring(value))
        .. ": expected positive seconds or a duration string"
end

function transport.resolve_timeout(value: any, source: string?, fallback: number?, fallback_err: RequestError?): (number?, RequestError?)
    if value == nil or value == "" then return fallback, fallback_err end
    local seconds, err = transport.timeout_seconds(value)
    if err then
        return nil, { status_code = 400, error_type = "invalid_request",
            message = err .. " from " .. (source or "timeout") }
    end
    return seconds, nil
end

-- Resolves a string setting from a literal context value, then from the env
-- variable named by `<key>_env` in the context, then from the provider's
-- default env variable. Empty env values count as unset. A variable the
-- context names that the env cannot resolve answers an invalid_request error
-- naming it and the env's reason; the provider's default variable is optional,
-- so its failure to resolve leaves the setting unset.
function transport.config_value(ctx_all: {[string]: any}, env_module: any, key: string, default_env: string?): (string?, string?, RequestError?)
    if ctx_all[key] then
        return tostring(ctx_all[key]), "context." .. key
    end
    local env_key = ctx_all[key .. "_env"]
    if env_key then
        local name = tostring(env_key)
        local value, err = env_module.get(name)
        if err then
            return nil, nil, { status_code = 400, error_type = "invalid_request", param = key .. "_env",
                message = key .. "_env names environment variable " .. name .. ", which does not resolve: " .. tostring(err) }
        end
        if type(value) == "string" and value ~= "" then return value, name end
    end
    if default_env then
        local value = env_module.get(default_env)
        if type(value) == "string" and value ~= "" then return value, default_env end
    end
    return nil, nil
end

-- Reads the string settings of one context through config_value, keeping
-- the first unresolved env reference as its error.
function transport.config_reader(ctx_all: {[string]: any}, env_module: any)
    local reader: { error: RequestError? } = { error = nil }
    function reader.get(key: string, default_env: string?): string?
        local value, _, err = transport.config_value(ctx_all, env_module, key, default_env)
        if err and not reader.error then reader.error = err end
        return value
    end
    return reader
end

function transport.config_timeout(ctx_all: {[string]: any}, env_module: any, default_env: string, fallback: number): (number?, RequestError?)
    local context = { timeout = ctx_all.timeout, timeout_env = ctx_all.timeout_env }
    if context.timeout == "" then context.timeout = nil end
    local value, source, err = transport.config_value(context, env_module, "timeout", default_env)
    if err then return nil, err end
    return transport.resolve_timeout(value, source, fallback)
end

function transport.normalize_retry(raw: any): Retry?
    if type(raw) ~= "table" then return nil end
    local attempts = math.floor(tonumber(raw.attempts) or 0)
    if attempts <= 0 then return nil end

    local backoff_ms = math.floor(tonumber(raw.backoff_ms) or DEFAULT_BACKOFF_MS)
    return {
        attempts = math.min(attempts, MAX_ATTEMPTS),
        backoff_ms = math.max(0, math.min(backoff_ms, MAX_BACKOFF_MS))
    }
end

-- Resolves the policy for one request: a request value replaces the context
-- policy, and `false` sends the request once.
function transport.request_retry(request_retry: any, context_retry: Retry?): Retry?
    if request_retry == nil then return context_retry end
    return transport.normalize_retry(request_retry)
end

function transport.retryable(error_info: RequestError): boolean
    local status = error_info.status_code
    return status == 0
        or status == 408
        or status == 409
        or status == 425
        or status == 429
        or (status >= 500 and status < 600)
end

local VERBS = {
    GET = "get",
    POST = "post",
    PUT = "put",
    PATCH = "patch",
    DELETE = "delete"
}

function transport.dispatch(http: any, method: string, url: string, options: {[string]: any}, deadline_at: number?): (HttpResponse?, string | RequestError?)
    local verb = VERBS[method]
    if not verb then
        error("Unsupported HTTP method: " .. tostring(method))
    end
    local remaining_ms = nil
    if deadline_at ~= nil then
        remaining_ms = deadline_at - transport.now_ms()
        if remaining_ms <= 0 then return nil, "Request deadline exceeded" end
    end
    local timeout, timeout_err = transport.resolve_timeout(options.timeout, "timeout", 30)
    if not timeout then return nil, timeout_err end
    local timeout_ms = timeout * 1000
    if remaining_ms then timeout_ms = math.min(timeout_ms, remaining_ms) end
    -- Every retry starts with the original timeout and the remaining call budget.
    local request_options = {}
    for key, value in pairs(options) do request_options[key] = value end
    request_options.timeout = string.format("%.0fms", math.max(1, math.floor(timeout_ms)))
    local response, err = http[verb](url, request_options)
    return response :: HttpResponse?, err and tostring(err) or nil
end

-- Backoff before the given retry (1-based), doubling from backoff_ms and capped.
local function backoff_delay_ms(retry: Retry, attempt: number): number
    local delay_ms = retry.backoff_ms * (2 ^ (attempt - 1))
    if delay_ms <= 0 then return 0 end
    return math.floor(math.min(delay_ms, MAX_BACKOFF_MS))
end

-- Sends a request with bounded exponential backoff. `send_once` performs one
-- attempt and returns (response, err); `parse_error` maps a non-2xx response
-- to the provider's error shape. Without a retry policy the request is sent
-- once. `deadline_at` (Unix milliseconds) prevents dispatch after expiry. A retry whose
-- backoff would end at or after it is not attempted, and the last error is
-- returned instead.
function transport.send(send_once: () -> (HttpResponse?, string | RequestError?), parse_error: (HttpResponse) -> RequestError, retry: Retry?, deadline_at: number?): (HttpResponse?, RequestError?)
    local retries = 0
    while true do
        if deadline_at ~= nil and transport.now_ms() >= deadline_at then
            return nil, { status_code = 0, message = "Request deadline exceeded" }
        end
        local response, err = send_once()

        local request_error: RequestError
        if not response then
            if type(err) == "table" then
                request_error = err
            else
                request_error = {
                    status_code = 0,
                    message = err and ("Connection failed: " .. tostring(err)) or "Connection failed"
                }
            end
        elseif response.status_code < 200 or response.status_code >= 300 then
            request_error = parse_error(response)
        else
            return response, nil
        end

        if not retry or retries >= retry.attempts or not transport.retryable(request_error) then
            return nil, request_error
        end

        retries = retries + 1
        local delay_ms = backoff_delay_ms(retry, retries)
        if deadline_at ~= nil and transport.now_ms() + delay_ms >= deadline_at then
            return nil, request_error
        end
        if delay_ms > 0 then
            transport._time.sleep(tostring(delay_ms) .. "ms")
        end
    end
end

-- Classifies a failed health probe: throttling and server errors are
-- degraded, every other failure is unhealthy.
function transport.health_failure(request_err: RequestError): HealthFailure
    local status_code = request_err.status_code
    local status = "unhealthy"
    local message = request_err.message

    if status_code == 0 then
        message = "Connection failed"
    elseif status_code == 429 then
        status = "degraded"
        message = "Rate limited but service is available"
    elseif status_code >= 500 and status_code < 600 then
        status = "degraded"
        message = "Service experiencing issues"
    end

    return {
        success = false,
        status = status,
        message = message
    }
end

-- Concatenates string lists in order, naming each value once.
function transport.merge_unique(lists: {{string}}): {string}
    local merged: {string} = {}
    local seen: {[string]: boolean} = {}
    for _, list in ipairs(lists) do
        for _, value in ipairs(list) do
            if not seen[value] then
                seen[value] = true
                table.insert(merged, value)
            end
        end
    end
    return merged
end

-- Values of a stream's 0-based, possibly sparse content block index in index order.
function transport.in_index_order(blocks: {[number]: any}): {any}
    local indices: {number} = {}
    for index in pairs(blocks) do
        table.insert(indices, index)
    end
    table.sort(indices)
    local ordered: {any} = {}
    for _, index in ipairs(indices) do
        table.insert(ordered, blocks[index])
    end
    return ordered
end

return transport
