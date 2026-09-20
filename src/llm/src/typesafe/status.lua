local typesafe_client = require("typesafe_client")

local status_handler = {
    _client = typesafe_client
}

function status_handler.handler()
    local response, request_err = status_handler._client.request("/models", nil, { method = "GET" })

    if request_err then
        local status = "unhealthy"
        local message = request_err.message or "Connection failed"

        if request_err.status_code == 0 or not request_err.status_code then
            status = "unhealthy"
            message = "Connection failed"
        elseif request_err.status_code == 429 then
            status = "degraded"
            message = "Rate limited but service is available"
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
        message = "TypeSafe API is responding normally"
    }
end

return status_handler
