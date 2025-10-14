local contract = require("contract")
local config = require("google_config")
local ctx = require("ctx")

local status = {
    _ctx = ctx,
    _contract = contract,
}

function status.handler()
    local client_contract, err = status._contract.get(config.CLIENT_CONTRACT_ID)
    if err then
        return {
            success = false,
            status = 500,
            message = "Failed to get client contract: " .. err
        }
    end

    local client_instance, err = client_contract
        :with_context(status._ctx.all() or {})
        :open(status._ctx.get("client_id"))
    if err then
        return {
            success = false,
            status = 500,
            message = "Failed to open client binding: " .. err
        }
    end

    local _, request_err = client_instance:request("/models", nil, {method = "GET"})

    if request_err then
        local result = { status = false }
        result.status = "unhealthy"
        result.message = request_err.message or "Connection failed"

        -- Network/connection errors
        if request_err.status_code == 0 or not request_err.status_code then
            result.status = "unhealthy"
            result.message = "Connection failed"
        -- Rate limit - degraded but service is available
        elseif request_err.status_code == 429 then
            result.status = "degraded"
            result.message = "Rate limited but service is available"
        -- Server errors - degraded
        elseif request_err.status_code and request_err.status_code >= 500 and request_err.status_code < 600 then
            result.status = "degraded"
            result.message = "Service experiencing issues"
        end

        return result
    end

    return {
        success = true,
        status = "healthy",
        message = "Google API is responding normally"
    }
end

return status
