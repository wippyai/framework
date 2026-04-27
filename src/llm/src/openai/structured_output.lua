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
    return "schema_" .. digest:sub(1, 16), nil
end

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

function structured_output_handler.handler(contract_args)
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

    local schema_valid, schema_errors = _validate_schema(contract_args.schema)
    if not schema_valid then
        return {
            success = false,
            error = output.ERROR_TYPE.INVALID_REQUEST,
            error_message = "Invalid schema: " .. table.concat(schema_errors, "; "),
            metadata = {}
        }
    end

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

    local instructions = structured_output_handler._mapper.extract_instructions(contract_args.messages)
    local input_items = structured_output_handler._mapper.map_messages(contract_args.messages, {
        model = contract_args.model
    })

    local payload = {
        model = contract_args.model,
        input = input_items,
        text = {
            format = {
                type = "json_schema",
                name = schema_name,
                schema = contract_args.schema,
                strict = true
            }
        }
    }

    if instructions and instructions ~= "" then
        payload.instructions = instructions
    end

    local mapped_options = structured_output_handler._mapper.map_options(contract_args.options)
    for key, value in pairs(mapped_options) do
        payload[key] = value
    end

    local request_options = {
        timeout = contract_args.timeout
    }

    local response, err = structured_output_handler._client.request("/responses", payload, request_options)

    if err then
        return structured_output_handler._mapper.map_error_response(err)
    end

    if not response or not response.output then
        return {
            success = false,
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "Invalid response structure from OpenAI Responses API",
            metadata = response and response.metadata or {}
        }
    end

    local content_text = nil
    local refusal = nil
    for _, item in ipairs(response.output) do
        if item.type == "message" and item.content then
            for _, part in ipairs(item.content) do
                if part.type == "output_text" and part.text then
                    content_text = (content_text or "") .. part.text
                elseif part.type == "refusal" and part.refusal then
                    refusal = part.refusal
                end
            end
        end
    end

    if refusal then
        return {
            success = false,
            error = output.ERROR_TYPE.CONTENT_FILTER,
            error_message = "Request was refused: " .. refusal,
            metadata = response.metadata or {}
        }
    end

    if not content_text or content_text == "" then
        return {
            success = false,
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "No content in Responses API response",
            metadata = response.metadata or {}
        }
    end

    local parsed_content, decode_err = json.decode(tostring(content_text))
    if decode_err then
        return {
            success = false,
            error = output.ERROR_TYPE.MODEL_ERROR,
            error_message = "Model failed to return valid JSON: " .. decode_err,
            metadata = response.metadata or {}
        }
    end

    local has_tool_calls = false
    for _, item in ipairs(response.output) do
        if item.type == "function_call" then has_tool_calls = true; break end
    end

    local meta = response.metadata or {}
    if response.id then meta.response_id = response.id end

    return {
        success = true,
        result = {
            data = parsed_content
        },
        tokens = structured_output_handler._mapper.map_tokens(response.usage),
        finish_reason = structured_output_handler._mapper.map_finish_reason(
            response.status,
            has_tool_calls,
            response.incomplete_details and response.incomplete_details.reason or nil
        ),
        metadata = meta
    }
end

return structured_output_handler
