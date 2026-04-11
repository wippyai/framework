local bedrock_client = require("bedrock_client")
local mapper = require("mapper")
local output = require("output")
local json = require("json")

local structured_output_handler = {
    _client = bedrock_client,
    _mapper = mapper,
    _output = output
}

local function validate_schema(schema)
    local schema_errors = {}

    if not schema or type(schema) ~= "table" then
        table.insert(schema_errors, "Schema must be a table")
        return false, schema_errors
    end

    if schema.type ~= "object" then
        table.insert(schema_errors, "Root schema must be type 'object'")
    end

    if schema.additionalProperties ~= false then
        table.insert(schema_errors, "Root schema must have 'additionalProperties: false' for reliable structured output")
    end

    if schema.properties and type(schema.properties) == "table" then
        local property_names = {}
        for name, _ in pairs(schema.properties) do
            table.insert(property_names, name)
        end

        if not schema.required or type(schema.required) ~= "table" then
            table.insert(schema_errors, "Schema must have 'required' array when properties are defined")
        else
            local missing = {}
            for _, prop_name in ipairs(property_names) do
                local found = false
                for _, req_prop in ipairs(schema.required) do
                    if req_prop == prop_name then
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(missing, prop_name)
                end
            end

            if #missing > 0 then
                table.insert(schema_errors, "All properties must be marked as required: " .. table.concat(missing, ", "))
            end
        end
    end

    return #schema_errors == 0, schema_errors
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
            error_message = "Schema is required for structured output",
            metadata = {}
        }
    end

    local schema_valid, schema_errors = validate_schema(contract_args.schema)
    if not schema_valid then
        return {
            success = false,
            error = output.ERROR_TYPE.INVALID_REQUEST,
            error_message = "Invalid schema: " .. table.concat(schema_errors, "; "),
            metadata = {}
        }
    end

    local mapped = structured_output_handler._mapper.map_messages(contract_args.messages)
    local inference_config, additional_fields = structured_output_handler._mapper.map_options(contract_args.options or {})

    if not inference_config.maxTokens then
        inference_config.maxTokens = 2000
    end

    -- Build tool for structured output extraction
    local structured_tool = {
        toolSpec = {
            name = "structured_output",
            description = "Generate structured output matching the required schema. Use this tool to return data in the exact format specified.",
            inputSchema = {
                json = contract_args.schema
            }
        }
    }

    local converse_payload = {
        messages = mapped.messages,
        toolConfig = {
            tools = { structured_tool },
            toolChoice = { tool = { name = "structured_output" } }
        }
    }

    if mapped.system then
        converse_payload.system = mapped.system
    end

    if next(inference_config) then
        converse_payload.inferenceConfig = inference_config
    end

    if next(additional_fields) then
        converse_payload.additionalModelRequestFields = additional_fields
    end

    local response, request_err = structured_output_handler._client.converse(
        contract_args.model,
        converse_payload,
        { timeout = contract_args.timeout }
    )

    if request_err then
        local error_response = structured_output_handler._mapper.map_error_response(request_err)
        error_response.success = false
        return error_response
    end

    -- Extract tool_use block from response
    if not response or not response.output or not response.output.message
        or not response.output.message.content then
        return {
            success = false,
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "Invalid response structure from Bedrock",
            metadata = response and response.metadata or {}
        }
    end

    local tool_use_input = nil
    for _, block in ipairs(response.output.message.content) do
        if block.toolUse and block.toolUse.name == "structured_output" then
            tool_use_input = block.toolUse.input
            break
        end
    end

    if not tool_use_input then
        return {
            success = false,
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "Model failed to use the structured_output tool",
            metadata = response.metadata or {}
        }
    end

    return {
        success = true,
        result = {
            data = tool_use_input
        },
        tokens = structured_output_handler._mapper.map_tokens(response.usage),
        finish_reason = "stop",
        metadata = response.metadata or {}
    }
end

return structured_output_handler
