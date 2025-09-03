local openai_client = require("openai_client")

local status_handler = {
    _client = openai_client
}

function status_handler.handler()
    -- Make a simple API call to test connectivity using GET method
    local response, request_err = status_handler._client.request("/models", nil, {method = "GET"})

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

    -- Success - service is healthy
    return {
        success = true,
        status = "healthy",
        message = "OpenAI API is responding normally"
    }
end

return status_handler