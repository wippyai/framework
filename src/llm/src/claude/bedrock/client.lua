local json = require("json")
local http_client = require("http_client")
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

-- Delegate streaming to Claude client parser (same SSE format)
bedrock_client.process_stream = claude_client.process_stream

return bedrock_client
