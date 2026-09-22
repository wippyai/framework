local bedrock_client = require("bedrock_client")
local transport = require("transport")

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
        return transport.health_failure(request_err)
    end

    return {
        success = true,
        status = "healthy",
        message = "Bedrock API is responding normally"
    }
end

return status_handler
