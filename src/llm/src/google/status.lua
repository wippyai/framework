local contract = require("contract")
local config = require("google_config")
local ctx = require("ctx")
local transport = require("transport")

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
            message = "Failed to get client contract: " .. tostring(err)
        }
    end

    local client_instance, err = client_contract
        :with_context(status._ctx.all() or {})
        :open(tostring(status._ctx.get("client_id")))
    if err then
        return {
            success = false,
            status = 500,
            message = "Failed to open client binding: " .. tostring(err)
        }
    end

    local response = client_instance:request({
        model = contract_args.model,
        options = { method = "GET", retry = false }
    })

    if response and response.status_code and response.status_code ~= 200 then
        return transport.health_failure(response :: transport.RequestError)
    end

    return {
        success = true,
        status = "healthy",
        message = "Google API is responding normally"
    }
end

return status
