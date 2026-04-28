local contract = require("contract")
local mapper = require("google_mapper")
local output = require("output")
local json = require("json")
local hash = require("hash")
local config = require("google_config")
local ctx = require("ctx")

local structured_output = {
    _ctx = ctx,
    _contract = contract,
    _mapper = mapper
}

local function _generate_schema_name(schema)
    local schema_str = json.encode(schema)
    local digest, err = hash.sha256(schema_str)
    if err then
        return nil, "Failed to generate schema name: " .. tostring(err)
    end
    return "schema_" .. digest:sub(1,16), nil
end

local function _validate_schema(schema)
    local errors = {}
    if not schema or type(schema) ~= "table" then
        return false, { "Schema must be a table" }
    end

    if schema.type ~= "object" then
        table.insert(errors, "Root schema type must be `object`")
    end

    return #errors == 0, errors
end

function structured_output.handler(contract_args)
    local err = output.errors.structured_output(contract_args)
        :classifier(structured_output._mapper.classify_error)

    if not contract_args.model then
        return nil, err:kind(output.ERROR_TYPE.INVALID_REQUEST):message("Model is required"):build()
    end

    if not contract_args.messages or #contract_args.messages == 0 then
        return nil, err:kind(output.ERROR_TYPE.INVALID_REQUEST):message("Messages are required"):build()
    end

    if not contract_args.schema then
        return nil, err:kind(output.ERROR_TYPE.INVALID_REQUEST):message("Schema is required"):build()
    end

    local schema_valid, schema_errors = _validate_schema(contract_args.schema)
    if not schema_valid then
        return nil, err
            :kind(output.ERROR_TYPE.INVALID_REQUEST)
            :message("Invalid schema: " .. table.concat(schema_errors, "; "))
            :details({ schema_errors = schema_errors })
            :build()
    end

    local schema_name = contract_args.schema_name
    if not schema_name then
        local name, name_err = _generate_schema_name(contract_args.schema)
        if name_err then
            return nil, err:kind(output.ERROR_TYPE.SERVER_ERROR):message(name_err):build()
        end
        schema_name = name
    end

    local messages, system_instructions = structured_output._mapper.map_messages(contract_args.messages, {
        model = contract_args.model
    })

    local payload = {
        contents = messages,
        generationConfig = {
            response_mime_type = "application/json",
            responseSchema = contract_args.schema
        }
    }

    if #system_instructions > 0 then
        payload.systemInstruction = { parts = system_instructions }
    end

    local mapped_options = structured_output._mapper.map_options(contract_args.options)
    for key, value in pairs(mapped_options) do
        if value ~= nil then
            payload.generationConfig[key] = value
        end
    end

    local client_contract, contract_err = structured_output._contract.get(config.CLIENT_CONTRACT_ID)
    if contract_err then
        return nil, err
            :kind(output.ERROR_TYPE.SERVER_ERROR)
            :message("Failed to get client contract: " .. tostring(contract_err))
            :build()
    end

    local client_instance, open_err = client_contract
        :with_context(structured_output._ctx.all() or {})
        :open(tostring(structured_output._ctx.get("client_id")))
    if open_err then
        return nil, err
            :kind(output.ERROR_TYPE.SERVER_ERROR)
            :message("Failed to open client binding: " .. tostring(open_err))
            :build()
    end

    local response = client_instance:request({
        endpoint_path = "generateContent",
        model = contract_args.model,
        payload = payload,
        options = { timeout = contract_args.timeout }
    })

    if response.status_code < 200 or response.status_code >= 300 then
        return nil, err:from(response):build()
    end

    local success, mapped_response = pcall(function()
        return structured_output._mapper.map_success_response(response)
    end)

    if not success then
        return nil, err
            :from({ message = mapped_response or "Failed to process Google response", status_code = 500 })
            :build()
    end

    local result_table = mapped_response.result or {}
    local structured_data, decode_err = json.decode(tostring(result_table.content or ""))
    if decode_err then
        return nil, err
            :kind(output.ERROR_TYPE.MODEL_ERROR)
            :message("Model failed to return valid JSON: " .. decode_err)
            :build()
    end

    mapped_response.result = { data = structured_data }

    return mapped_response
end

return structured_output
