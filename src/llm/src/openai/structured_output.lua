local openai_client = require("openai_client")
local openai_mapper = require("openai_mapper")
local output = require("output")
local json = require("json")
local hash = require("hash")

local structured_output_handler = {
    _client = openai_client,
    _mapper = openai_mapper
}

-- Generate a unique name for a schema based on its structure
local function _generate_schema_name(schema)
    local schema_str = json.encode(schema)
    local digest, err = hash.sha256(schema_str)
    if err then
        return nil, "Failed to generate schema name: " .. err
    end
    return "schema_" .. digest:sub(1,16), nil
end

-- Validate schema meets OpenAI requirements
local function _validate_schema(schema)
    local errors = {}

    if not schema or type(schema) ~= "table" then
        table.insert(errors, "Schema must be a table")
        return false, errors
    end

    if schema.type ~= "object" then
        table.insert(errors, "Root schema must be an object type")
    end

    if schema.additionalProperties ~= false then
        table.insert(errors, "Root schema must have additionalProperties: false")
    end

    if schema.properties then
        local properties = {}
        for prop_name, _ in pairs(schema.properties) do
            table.insert(properties, prop_name)
        end

        if not schema.required then
            table.insert(errors, "Schema must have a required array listing all properties")
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
                table.insert(errors, "Properties must be marked as required: " .. table.concat(missing_required, ", "))
            end
        end
    end

    return #errors == 0, errors
end

---@param contract_args table Contract arguments for structured output
---@return table Contract-compliant response
function structured_output_handler.handler(contract_args)
    -- Validate required arguments
    if not contract_args.model then
        return {
            success = false,
            error = output.ERROR_TYPE.INVALID_REQUEST,
            error_message = "Model is required",
            metadata = {}
        }
    end

    if not contract_args.messages or #contract_args.messages == 0 then
        return {
            success = false,
            error = output.ERROR_TYPE.INVALID_REQUEST,
            error_message = "Messages are required",
            metadata = {}
        }
    end

    if not contract_args.schema then
        return {
            success = false,
            error = output.ERROR_TYPE.INVALID_REQUEST,
            error_message = "Schema is required",
            metadata = {}
        }
    end

    -- Validate the schema
    local schema_valid, schema_errors = _validate_schema(contract_args.schema)
    if not schema_valid then
        return {
            success = false,
            error = output.ERROR_TYPE.INVALID_REQUEST,
            error_message = "Invalid schema: " .. table.concat(schema_errors, "; "),
            metadata = {}
        }
    end

    -- Generate a schema name if not provided
    local schema_name = contract_args.schema_name
    if not schema_name then
        local name, err = _generate_schema_name(contract_args.schema)
        if err then
            return {
                success = false,
                error = output.ERROR_TYPE.SERVER_ERROR,
                error_message = err,
                metadata = {}
            }
        end
        schema_name = name
    end

    -- Build OpenAI payload
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

    -- Use mapper for options mapping
    local mapped_options = structured_output_handler._mapper.map_options(contract_args.options)
    for key, value in pairs(mapped_options) do
        openai_payload[key] = value
    end

    -- Make the request
    local request_options = {
        timeout = contract_args.timeout
    }

    -- Perform the request to OpenAI
    local response, err = structured_output_handler._client.request(
        "/chat/completions",
        openai_payload,
        request_options
    )

    -- Handle request errors
    if err then
        return structured_output_handler._mapper.map_error_response(err)
    end

    -- Check response validity
    if not response or not response.choices or #response.choices == 0 then
        return {
            success = false,
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "Invalid response structure from OpenAI",
            metadata = response and response.metadata or {}
        }
    end

    -- Extract the first choice
    local first_choice = response.choices[1]
    if not first_choice or not first_choice.message then
        return {
            success = false,
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "Invalid choice structure in OpenAI response",
            metadata = response.metadata or {}
        }
    end

    -- Handle refusal
    if first_choice.message.refusal then
        return {
            success = false,
            error = output.ERROR_TYPE.CONTENT_FILTER,
            error_message = "Request was refused: " .. first_choice.message.refusal,
            metadata = response.metadata or {}
        }
    end

    -- Validate content exists
    if not first_choice.message.content then
        return {
            success = false,
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "No content in OpenAI response",
            metadata = response.metadata or {}
        }
    end

    -- Parse the JSON content for structured output
    local structured_data = nil
    local parsed_content, decode_err = json.decode(first_choice.message.content)
    if decode_err then
        return {
            success = false,
            error = output.ERROR_TYPE.MODEL_ERROR,
            error_message = "Model failed to return valid JSON: " .. decode_err,
            metadata = response.metadata or {}
        }
    end
    structured_data = parsed_content

    -- Build contract-compliant success response
    local final_response = {
        success = true,
        result = {
            data = structured_data
        },
        tokens = structured_output_handler._mapper.map_tokens(response.usage),
        finish_reason = structured_output_handler._mapper.map_finish_reason(first_choice.finish_reason),
        metadata = response.metadata or {}
    }

    return final_response
end

return structured_output_handler