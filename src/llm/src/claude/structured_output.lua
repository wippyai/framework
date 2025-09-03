local claude_client = require("claude_client")
local mapper = require("mapper")
local output = require("output")
local json = require("json")
local hash = require("hash")

local structured_output_handler = {
    _client = claude_client,
    _mapper = mapper,
    _output = output
}

local function validate_schema(schema)
    local errors = {}

    if not schema or type(schema) ~= "table" then
        table.insert(errors, "Schema must be a table")
        return false, errors
    end

    if schema.type ~= "object" then
        table.insert(errors, "Root schema must be type 'object'")
    end

    if schema.additionalProperties ~= false then
        table.insert(errors, "Root schema must have 'additionalProperties: false' for reliable structured output")
    end

    if schema.properties and type(schema.properties) == "table" then
        local property_names = {}
        for name, _ in pairs(schema.properties) do
            table.insert(property_names, name)
        end

        if not schema.required or type(schema.required) ~= "table" then
            table.insert(errors, "Schema must have 'required' array when properties are defined")
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
                table.insert(errors, "All properties must be marked as required: " .. table.concat(missing, ", "))
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

    local mapped_messages = structured_output_handler._mapper.map_messages(contract_args.messages)
    local mapped_options = structured_output_handler._mapper.map_options(contract_args.options or {}, contract_args.model)

    local structured_tool = {
        name = "structured_output",
        description = "Generate structured output matching the required schema. Use this tool to return data in the exact format specified.",
        schema = contract_args.schema
    }

    local claude_tools, _ = structured_output_handler._mapper.map_tools({structured_tool})

    local tool_choice = {
        type = "tool",
        name = "structured_output"
    }

    local claude_payload = {
        model = contract_args.model,
        messages = mapped_messages.messages,
        tools = claude_tools,
        tool_choice = tool_choice,
        max_tokens = mapped_options.max_tokens or 2000
    }

    if mapped_messages.system then
        claude_payload.system = mapped_messages.system
    end

    for k, v in pairs(mapped_options) do
        if k ~= "max_tokens" then
            claude_payload[k] = v
        end
    end

    local request_options = {
        timeout = contract_args.timeout
    }

    local response, request_err = structured_output_handler._client.request(
        structured_output_handler._client.ENDPOINTS.MESSAGES,
        claude_payload,
        request_options
    )

    if request_err then
        local error_response = structured_output_handler._mapper.map_error_response(request_err)
        error_response.success = false
        return error_response
    end

    if not response or not response.content then
        return {
            success = false,
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "Invalid response structure from Claude",
            metadata = response and response.metadata or {}
        }
    end

    local tool_use_block = nil
    for _, block in ipairs(response.content) do
        if block.type == "tool_use" and block.name == "structured_output" then
            tool_use_block = block
            break
        end
    end

    if not tool_use_block then
        return {
            success = false,
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "Claude failed to use the structured_output tool",
            metadata = response.metadata or {}
        }
    end

    if not tool_use_block.input then
        return {
            success = false,
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "Tool use block does not contain input",
            metadata = response.metadata or {}
        }
    end

    return {
        success = true,
        result = {
            data = tool_use_block.input
        },
        tokens = structured_output_handler._mapper.map_tokens(response.usage),
        finish_reason = "stop",
        metadata = response.metadata or {}
    }
end

return structured_output_handler