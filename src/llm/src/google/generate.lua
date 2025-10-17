local contract = require("contract")
local mapper = require("google_mapper")
local output = require("output")
local config = require("google_config")
local ctx = require("ctx")

local generate = {
    _ctx = ctx,
    _contract = contract,
    _mapper = mapper,
    _output = output
}

function generate.handler(contract_args)
    if not contract_args.model then
        return generate._mapper.map_error_response({
            message = "Model is required",
            status_code = 400
        })
    end

    if not contract_args.messages or #contract_args.messages == 0 then
        return generate._mapper.map_error_response({
            message = "Messages are required",
            status_code = 400
        })
    end

    local messages, system_instructions = generate._mapper.map_messages(contract_args.messages, {
        model = contract_args.model
    })

    local payload = {
        contents = messages,
        generationConfig = {}
    }
    if #system_instructions > 0 then
        payload.systemInstruction = { parts = system_instructions }
    end

    local mapped_options = generate._mapper.map_options(contract_args.options)
    for key, value in pairs(mapped_options) do
        if value ~= nil then
            payload.generationConfig[key] = value
        end
    end
    if next(payload.generationConfig) == nil then
        payload.generationConfig = nil
    end

    if contract_args.tools and #contract_args.tools > 0 then
        local tools = generate._mapper.map_tools(contract_args.tools)
        local tool_config, tool_config_error = generate._mapper.map_tool_config(
            contract_args.tool_choice,
            contract_args.tools
        )

        if tool_config_error then
            return generate._mapper.map_error_response({
                message = tool_config_error,
                status_code = 400
            })
        end

        payload.tools = { functionDeclarations = tools }
        payload.toolConfig = { functionCallingConfig = tool_config }
    end

    local client_contract, err = generate._contract.get(config.CLIENT_CONTRACT_ID)
    if err then
        return generate._mapper.map_error_response({
            message = "Failed to get client contract: " .. err,
            status_code = 500
        })
    end

    local client_instance, err = client_contract
        :with_context(generate._ctx.all() or {})
        :open(generate._ctx.get("client_id"))
    if err then
        return generate._mapper.map_error_response({
            message = "Failed to open client binding: " .. err,
            status_code = 500
        })
    end

    local response = client_instance:request({
        endpoint_path = "generateContent",
        model = contract_args.model,
        payload = payload,
        options = { timeout = contract_args.timeout }
    })

    if response.status_code < 200 or response.status_code >= 300 then
        return generate._mapper.map_error_response(response)
    end

    local success, mapped_response = pcall(function()
        return generate._mapper.map_success_response(response)
    end)

    if not success then
        return generate._mapper.map_error_response({
            message = mapped_response or "Failed to process Google response",
            status_code = 500
        })
    end

    return mapped_response
end

return generate
