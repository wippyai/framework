local bedrock_client = require("bedrock_client")

local status_handler = {
    _client = bedrock_client
}

function status_handler.handler(contract_args)
    local model = contract_args and contract_args.model or "us.anthropic.claude-haiku-4-5-20251001-v1:0"

    local payload = {
        messages = {
            { role = "user", content = { { text = "ping" } } }
        },
        inferenceConfig = {
            maxTokens = 1
        }
    }

    local response, request_err = status_handler._client.converse(
        model,
        payload,
        { timeout = 15 }
    )

    if request_err then
        local status = "unhealthy"
        local message = request_err.message or "Connection failed"

        if request_err.status_code == 0 or not request_err.status_code then
            status = "unhealthy"
            message = "Connection failed"
        elseif request_err.status_code == 429 then
            status = "degraded"
            message = "Rate limited but service is available"
        elseif request_err.status_code == 401 or request_err.status_code == 403 then
            status = "unhealthy"
            message = request_err.message or "Authentication failed"
        elseif request_err.status_code >= 500 and request_err.status_code < 600 then
            status = "degraded"
            message = "Service experiencing issues"
        end

        return {
            success = false,
            status = status,
            message = message
        }
    end

    return {
        success = true,
        status = "healthy",
        message = "Bedrock API is responding normally"
    }
end

return status_handler
