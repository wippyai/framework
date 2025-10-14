local contract = require("contract")
local mapper = require("google_mapper")
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
        return nil, "Failed to generate schema name: " .. err
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
    if not contract_args.model then
        return structured_output._mapper.map_error_response({
            message = "Model is required",
            status_code = 400
        })
    end

    if not contract_args.messages or #contract_args.messages == 0 then
        return structured_output._mapper.map_error_response({
            message = "Messages are required",
            status_code = 400
        })
    end

    if not contract_args.schema then
        return structured_output._mapper.map_error_response({
            message = "Schema is required",
            status_code = 400
        })
    end

    local schema_valid, schema_errors = _validate_schema(contract_args.schema)
    if not schema_valid then
        return structured_output._mapper.map_error_response({
            message = "Invalid schema: " .. table.concat(schema_errors, "; "),
            status_code = 400
        })
    end

    local schema_name = contract_args.schema_name
    if not schema_name then
        local name, err = _generate_schema_name(contract_args.schema)
        if err then
            return structured_output._mapper.map_error_response({
                message = err,
                status_code = 500
            })
        end
        schema_name = name
    end

    local messages, system_instructions = structured_output._mapper.map_messages(contract_args.messages, {
        model = contract_args.model
    })

    local payload = {
        contents = messages,
        response_mime_type = "application/json",
        responseSchema = contract_args.schema
    }

    if #system_instructions > 0 then
        payload.systemInstruction.parts = system_instructions
    end

    local mapped_options = structured_output._mapper.map_options(contract_args.options)
    for key, value in pairs(mapped_options) do
        if value ~= nil then
            payload.generationConfig[key] = value
        end
    end

    local client_contract, err = structured_output._contract.get(config.CLIENT_CONTRACT_ID)
    if err then
        return structured_output._mapper.map_error_response({
            message = "Failed to get client contract: " .. err,
            status_code = 500
        })
    end

    local client_instance, err = client_contract
        :with_context(structured_output._ctx.all() or {})
        :open(structured_output._ctx.get("client_id"))
    if err then
        return structured_output._mapper.map_error_response({
            message = "Failed to open client binding: " .. err,
            status_code = 500
        })
    end

    local response, request_err = client_instance:request({
        endpoint_path = "generateContent",
        model = contract_args.model,
        payload = payload,
        options = { timeout = contract_args.timeout }
    })

    if request_err then
        return structured_output._mapper.map_error_response(err)
    end

    local success, mapped_response = pcall(function()
        return structured_output._mapper.map_success_response(response)
    end)

    if not success then
        return structured_output._mapper.map_error_response({
            message = mapped_response or "Failed to process Google response",
            status_code = 500
        })
    end

    local structured_data, decode_err = json.decode(mapped_response.result.content)
    if decode_err then
        return structured_output._mapper.map_error_response({
            message = "Model failed to return valid JSON: " .. decode_err,
            status_code = 404
        })
    end

    mapped_response.result = { data = structured_data }

    return mapped_response
end

return structured_output
