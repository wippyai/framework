local claude_client = require("claude_client")
local mapper = require("mapper")

-- Claude Status Handler - using proper models endpoint for health check
local status_handler = {
    _client = claude_client,
    _mapper = mapper
}

function status_handler.handler()
    -- Use the models endpoint - lightweight GET request, no token consumption
    local response, request_err = status_handler._client.request(
        "/v1/models",
        nil,
        { method = "GET", timeout = 15 }
    )

    if request_err then
        -- Determine status based on error type
        local status = "unhealthy"
        local message = request_err.message or "Connection failed"

        -- Network/connection errors
        if request_err.status_code == 0 or not request_err.status_code then
            status = "unhealthy"
            message = "Connection failed"
        -- Rate limit - degraded but service is available
        elseif request_err.status_code == 429 then
            status = "degraded"
            message = "Rate limited but service is available"
        -- Auth errors - configuration issue
        elseif request_err.status_code == 401 or request_err.status_code == 403 then
            status = "unhealthy"
            message = request_err.message or "Authentication failed"
        -- Server errors - degraded
        elseif request_err.status_code and request_err.status_code >= 500 and request_err.status_code < 600 then
            status = "degraded"
            message = "Service experiencing issues"
        end

        return {
            success = false,
            status = status,
            message = message
        }
    end

    -- Success - API is healthy and returning model list
    return {
        success = true,
        status = "healthy",
        message = "Claude API is responding normally"
    }
end

return status_handler