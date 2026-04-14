local http_client = require("http_client")
local json = require("json")
local env = require("env")
local ctx = require("ctx")
local store = require("store")
local time = require("time")

local credentials = {}

credentials._http_client = http_client
credentials._env = env
credentials._ctx = ctx
credentials._store = store
credentials._time = time

credentials.CACHE_KEY = "aws_bedrock_credentials"
credentials.DEFAULT_CACHE_ID = "app:cache"

local function resolve_string(key, default_env)
    local ctx_all = credentials._ctx.all() or {}

    if ctx_all[key] then
        return tostring(ctx_all[key])
    end
    local env_key = key .. "_env"
    if ctx_all[env_key] then
        local val = credentials._env.get(tostring(ctx_all[env_key]))
        if val and val ~= "" then return val end
    end
    if default_env then
        local val = credentials._env.get(default_env)
        if val and val ~= "" then return val end
    end
    return nil
end

-- Fetch temporary credentials from ECS/EKS container metadata endpoint
function credentials.fetch_container_credentials()
    local full_uri = credentials._env.get("AWS_CONTAINER_CREDENTIALS_FULL_URI")
    local relative_uri = credentials._env.get("AWS_CONTAINER_CREDENTIALS_RELATIVE_URI")

    local creds_url = nil
    if full_uri and full_uri ~= "" then
        creds_url = full_uri
    elseif relative_uri and relative_uri ~= "" then
        creds_url = "http://169.254.170.2" .. relative_uri
    end

    if not creds_url then
        return nil, "No container credentials endpoint available"
    end

    local auth_token = credentials._env.get("AWS_CONTAINER_AUTHORIZATION_TOKEN")
    local request_headers = {}
    if auth_token and auth_token ~= "" then
        request_headers["Authorization"] = auth_token
    end

    local response, err = credentials._http_client.get(creds_url, {
        headers = request_headers,
        timeout = 5
    })

    if err then
        return nil, "Container credentials request failed: " .. tostring(err)
    end

    if not response or response.status_code ~= 200 then
        return nil, "Container credentials endpoint returned " ..
            (response and tostring(response.status_code) or "no response")
    end

    local parsed, parse_err = json.decode(tostring(response.body))
    if parse_err then
        return nil, "Failed to parse container credentials: " .. tostring(parse_err)
    end

    local expiration = nil
    if parsed.Expiration then
        local exp_time, exp_err = credentials._time.parse(time.RFC3339, tostring(parsed.Expiration))
        if not exp_err and exp_time then
            expiration = exp_time:unix()
        end
    end

    return {
        access_key = parsed.AccessKeyId,
        secret_key = parsed.SecretAccessKey,
        session_token = parsed.Token,
        expiration = expiration
    }
end

-- Check if container metadata endpoint is available
function credentials.has_container_endpoint()
    local full_uri = credentials._env.get("AWS_CONTAINER_CREDENTIALS_FULL_URI")
    local relative_uri = credentials._env.get("AWS_CONTAINER_CREDENTIALS_RELATIVE_URI")
    return (full_uri and full_uri ~= "") or (relative_uri and relative_uri ~= "")
end

-- Fetch temporary credentials from EC2 instance metadata (IMDSv2)
function credentials.fetch_instance_credentials()
    local token_response, token_err = credentials._http_client.put(
        "http://169.254.169.254/latest/api/token", {
            headers = { ["X-aws-ec2-metadata-token-ttl-seconds"] = "21600" },
            timeout = 2
        })

    if token_err or not token_response or token_response.status_code ~= 200 then
        return nil, "IMDS token request failed: " .. tostring(token_err or "non-200 response")
    end

    local token = tostring(token_response.body)
    local imds_headers = { ["X-aws-ec2-metadata-token"] = token }

    local role_response, role_err = credentials._http_client.get(
        "http://169.254.169.254/latest/meta-data/iam/security-credentials/", {
            headers = imds_headers,
            timeout = 2
        })

    if role_err or not role_response or role_response.status_code ~= 200 then
        return nil, "IMDS role lookup failed: " .. tostring(role_err or "non-200 response")
    end

    local role_name = tostring(role_response.body):match("^%s*(.-)%s*$")
    if not role_name or role_name == "" then
        return nil, "No IAM role found on instance"
    end

    local creds_response, creds_err = credentials._http_client.get(
        "http://169.254.169.254/latest/meta-data/iam/security-credentials/" .. role_name, {
            headers = imds_headers,
            timeout = 2
        })

    if creds_err or not creds_response or creds_response.status_code ~= 200 then
        return nil, "IMDS credentials fetch failed: " .. tostring(creds_err or "non-200 response")
    end

    local parsed, parse_err = json.decode(tostring(creds_response.body))
    if parse_err then
        return nil, "Failed to parse IMDS credentials: " .. tostring(parse_err)
    end

    local expiration = nil
    if parsed.Expiration then
        local exp_time, exp_err = credentials._time.parse(time.RFC3339, tostring(parsed.Expiration))
        if not exp_err and exp_time then
            expiration = exp_time:unix()
        end
    end

    return {
        access_key = parsed.AccessKeyId,
        secret_key = parsed.SecretAccessKey,
        session_token = parsed.Token,
        expiration = expiration
    }
end

-- Check if EC2 instance metadata is reachable
function credentials.has_instance_endpoint()
    local response, err = credentials._http_client.put(
        "http://169.254.169.254/latest/api/token", {
            headers = { ["X-aws-ec2-metadata-token-ttl-seconds"] = "21600" },
            timeout = 1
        })
    return not err and response ~= nil and response.status_code == 200
end

-- Read credentials from cache store (populated by credential_refresher)
local function read_from_cache()
    local ok, store_instance, err = pcall(function()
        return credentials._store.get(
            credentials._env.get("APP_CACHE") or credentials.DEFAULT_CACHE_ID)
    end)

    if not ok or err or not store_instance then
        return nil
    end

    local cached = store_instance:get(credentials.CACHE_KEY)
    store_instance:release()

    if not cached then return nil end

    -- Check expiration with 5-minute buffer
    if cached.expiration then
        local now = credentials._time.now()
        if now:unix() + 300 >= cached.expiration then
            return nil
        end
    end

    return cached
end

-- Resolve AWS credentials: env vars -> cache -> direct metadata fetch
function credentials.resolve()
    local region = resolve_string("region", "AWS_REGION")
        or resolve_string("aws_region", "AWS_DEFAULT_REGION")
        or "us-east-1"

    -- Static credentials from context or env vars
    local access_key = resolve_string("access_key", "AWS_ACCESS_KEY_ID")
    local secret_key = resolve_string("secret_key", "AWS_SECRET_ACCESS_KEY")

    if access_key and secret_key then
        local session_token = resolve_string("session_token", "AWS_SESSION_TOKEN")
        return {
            access_key = access_key,
            secret_key = secret_key,
            session_token = session_token,
            region = region
        }
    end

    -- Read from cache (populated by credential_refresher service)
    local cached = read_from_cache()
    if cached then
        cached.region = region
        return cached
    end

    -- Try container metadata (Fargate/ECS/EKS)
    if credentials.has_container_endpoint() then
        local container_creds, container_err = credentials.fetch_container_credentials()
        if container_creds then
            container_creds.region = region
            return container_creds
        end
    end

    -- Try EC2 instance metadata (IMDS)
    local instance_creds, instance_err = credentials.fetch_instance_credentials()
    if instance_creds then
        instance_creds.region = region
        return instance_creds
    end

    return nil, "AWS credentials not found. Provide AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY, " ..
        "or run on EC2 with an IAM role, or in ECS/EKS with a task role. " ..
        "(" .. tostring(instance_err) .. ")"
end

return credentials
