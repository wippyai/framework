local typesafe_client = require("typesafe_client")
local transport = require("transport")

local status_handler = {
    _client = typesafe_client
}

function status_handler.handler()
    local _, request_err = status_handler._client.request("/models", nil, { method = "GET" })
    if request_err then
        return transport.health_failure(request_err)
    end

    return {
        success = true,
        status = "healthy",
        message = "TypeSafe API is responding normally"
    }
end

return status_handler
