local openai_client = require("openai_client")
local openai_mapper = require("openai_mapper")
local output = require("output")
local json = require("json")
local hash = require("hash")

local structured_output_handler = {
    _client = openai_client,
    _mapper = openai_mapper
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
    local errs = {}

    if not schema or type(schema) ~= "table" then
        table.insert(errs, "Schema must be a table")
        return false, errs
    end

    if schema.type ~= "object" then
        table.insert(errs, "Root schema must be an object type")
    end

    if schema.additionalProperties ~= false then
        table.insert(errs, "Root schema must have additionalProperties: false")
    end

    if schema.properties then
        local properties = {}
        for prop_name, _ in pairs(schema.properties) do
            table.insert(properties, prop_name)
        end

        if not schema.required then
            table.insert(errs, "Schema must have a required array listing all properties")
        else
            local missing_required = {}
            for _, prop_name in ipairs(properties) do
                local found = false
                for _, req_prop in ipairs(schema.required) do
                    if req_prop == prop_name then
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(missing_required, prop_name)
                end
            end

            if #missing_required > 0 then
                table.insert(errs, "Properties must be marked as required: " .. table.concat(missing_required, ", "))
            end
        end
    end

    return #errs == 0, errs
end

function structured_output_handler.handler(contract_args)
    local err = output.errors.structured_output(contract_args)
        :classifier(structured_output_handler._mapper.classify_error)

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

    local openai_payload = {
        model = contract_args.model,
        messages = contract_args.messages,
        response_format = {
            type = "json_schema",
            json_schema = {
                name = schema_name,
                schema = contract_args.schema,
                strict = true
            }
        }
    }

    local mapped_options = structured_output_handler._mapper.map_options(contract_args.options)
    for key, value in pairs(mapped_options) do
        openai_payload[key] = value
    end

    local request_options = {
        timeout = contract_args.timeout
    }

    local response, req_err = structured_output_handler._client.request(
        "/chat/completions",
        openai_payload,
        request_options
    )

    if req_err then
        return nil, err:from(req_err):build()
    end

    if not response or not response.choices or #response.choices == 0 then
        return nil, err
            :kind(output.ERROR_TYPE.SERVER_ERROR)
            :message("Invalid response structure from OpenAI")
            :details(response and response.metadata or nil)
            :build()
    end

    local first_choice = response.choices[1]
    if not first_choice or not first_choice.message then
        return nil, err
            :kind(output.ERROR_TYPE.SERVER_ERROR)
            :message("Invalid choice structure in OpenAI response")
            :build()
    end

    if first_choice.message.refusal then
        return nil, err
            :kind(output.ERROR_TYPE.CONTENT_FILTER)
            :message("Request was refused: " .. first_choice.message.refusal)
            :details({ refusal = first_choice.message.refusal })
            :build()
    end

    if not first_choice.message.content then
        return nil, err
            :kind(output.ERROR_TYPE.SERVER_ERROR)
            :message("No content in OpenAI response")
            :build()
    end

    local parsed_content, decode_err = json.decode(tostring(first_choice.message.content))
    if decode_err then
        return nil, err
            :kind(output.ERROR_TYPE.MODEL_ERROR)
            :message("Model failed to return valid JSON: " .. decode_err)
            :details({ raw_content = first_choice.message.content })
            :build()
    end

    return {
        success = true,
        result = {
            data = parsed_content
        },
        tokens = structured_output_handler._mapper.map_tokens(response.usage),
        finish_reason = structured_output_handler._mapper.map_finish_reason(first_choice.finish_reason),
        metadata = response.metadata or {}
    }
end

return structured_output_handler
