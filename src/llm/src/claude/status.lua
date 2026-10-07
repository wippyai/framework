local claude_client = require("claude_client")
local mapper = require("mapper")
local transport = require("transport")

local status_handler = {
    _client = claude_client,
    _mapper = mapper
}

-- Probes the models endpoint: a lightweight GET that consumes no tokens.
function status_handler.handler()
    local _, request_err = status_handler._client.request(
        "/v1/models",
        nil,
        { method = "GET", timeout = 15, retry = false }
    )
    if request_err then
        return transport.health_failure(request_err)
    end

    return {
        success = true,
        status = "healthy",
        message = "Claude API is responding normally"
    }
end

return status_handler
