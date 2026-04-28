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
    local err = output.errors.generate("google")
        :with_contract(contract_args)
        :classifier(generate._mapper.classify_error)

    if not contract_args.model then
        return nil, err:kind(output.ERROR_TYPE.INVALID_REQUEST):message("Model is required"):build()
    end

    if not contract_args.messages or #contract_args.messages == 0 then
        return nil, err:kind(output.ERROR_TYPE.INVALID_REQUEST):message("Messages are required"):build()
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
            return nil, err:kind(output.ERROR_TYPE.INVALID_REQUEST):message(tool_config_error):build()
        end

        payload.tools = { functionDeclarations = tools }
        payload.toolConfig = { functionCallingConfig = tool_config }
    end

    local client_contract, contract_err = generate._contract.get(config.CLIENT_CONTRACT_ID)
    if contract_err then
        return nil, err
            :kind(output.ERROR_TYPE.SERVER_ERROR)
            :message("Failed to get client contract: " .. tostring(contract_err))
            :build()
    end

    local client_instance, open_err = client_contract
        :with_context(generate._ctx.all() or {})
        :open(tostring(generate._ctx.get("client_id")))
    if open_err then
        return nil, err
            :kind(output.ERROR_TYPE.SERVER_ERROR)
            :message("Failed to open client binding: " .. tostring(open_err))
            :build()
    end

    local endpoint_path = "generateContent"
    local request_options = { timeout = contract_args.timeout }

    if contract_args.stream and contract_args.stream.reply_to then
        endpoint_path = "streamGenerateContent"
        request_options.stream = true
        request_options.stream_reply_to = contract_args.stream.reply_to
        request_options.stream_topic = contract_args.stream.topic
        request_options.stream_buffer_size = contract_args.stream.buffer_size
    end

    local response = client_instance:request({
        endpoint_path = endpoint_path,
        model = contract_args.model,
        payload = payload,
        options = request_options
    })

    if response.status_code < 200 or response.status_code >= 300 then
        return nil, err:from(response):build()
    end

    local success, mapped_response = pcall(function()
        return generate._mapper.map_success_response(response)
    end)

    if not success then
        return nil, err
            :from({ message = mapped_response or "Failed to process Google response", status_code = 500 })
            :build()
    end

    return mapped_response
end

return generate
