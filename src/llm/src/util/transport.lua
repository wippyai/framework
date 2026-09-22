local time = require("time")

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

-- Resolves a string setting from a literal context value, then from the env
-- variable named by `<key>_env` in the context, then from the provider's
-- default env variable. Empty env values count as unset.
function transport.config_value(ctx_all: {[string]: any}, env_module: any, key: string, default_env: string?): string?
    if ctx_all[key] then
        return tostring(ctx_all[key])
    end
    local env_key = ctx_all[key .. "_env"]
    if env_key then
        local value = env_module.get(tostring(env_key))
        if type(value) == "string" and value ~= "" then return value end
    end
    if default_env then
        local value = env_module.get(default_env)
        if type(value) == "string" and value ~= "" then return value end
    end
    return nil
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

function transport.dispatch(http: any, method: string, url: string, options: {[string]: any}): (HttpResponse?, string?)
    local verb = VERBS[method]
    if not verb then
        error("Unsupported HTTP method: " .. tostring(method))
    end
    local response, err = http[verb](url, options)
    return response :: HttpResponse?, err and tostring(err) or nil
end

local function backoff(retry: Retry, attempt: number)
    local delay_ms = retry.backoff_ms * (2 ^ (attempt - 1))
    if delay_ms <= 0 then return end
    time.sleep(tostring(math.floor(math.min(delay_ms, MAX_BACKOFF_MS))) .. "ms")
end

-- Sends a request with bounded exponential backoff. `send_once` performs one
-- attempt and returns (response, err); `parse_error` maps a non-2xx response
-- to the provider's error shape. Without a retry policy the request is sent once.
function transport.send(send_once: () -> (HttpResponse?, string?), parse_error: (HttpResponse) -> RequestError, retry: Retry?): (HttpResponse?, RequestError?)
    local retries = 0
    while true do
        local response, err = send_once()

        local request_error: RequestError
        if not response then
            request_error = {
                status_code = 0,
                message = err and ("Connection failed: " .. tostring(err)) or "Connection failed"
            }
        elseif response.status_code < 200 or response.status_code >= 300 then
            request_error = parse_error(response)
        else
            return response, nil
        end

        if not retry or retries >= retry.attempts or not transport.retryable(request_error) then
            return nil, request_error
        end

        retries = retries + 1
        backoff(retry, retries)
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

return transport
