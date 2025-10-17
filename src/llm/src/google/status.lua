local contract = require("contract")
local config = require("google_config")
local ctx = require("ctx")

local status = {
    _ctx = ctx,
    _contract = contract,
}

function status.handler(contract_args)
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

    local response = client_instance:request({
        model = contract_args.model,
        options = { method = "GET" }
    })

    if response and response.status_code and response.status_code ~= 200 then
        local result = { success = false }
        result.status = "unhealthy"
        result.message = response.message or "Connection failed"

        -- Network/connection errors
        if response.status_code == 0 or not response.status_code then
            result.status = "unhealthy"
            result.message = "Connection failed"
        -- Rate limit - degraded but service is available
        elseif response.status_code == 429 then
            result.status = "degraded"
            result.message = "Rate limited but service is available"
        -- Server errors - degraded
        elseif response.status_code and response.status_code >= 500 and response.status_code < 600 then
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
