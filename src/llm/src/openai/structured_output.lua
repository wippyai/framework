local openai_client = require("openai_client")
local openai_mapper = require("openai_mapper")
local output = require("output")
local wire_request = require("wire_request")
local json = require("json")
local hash = require("hash")

type ClassifyError = (http_err: any?) -> (string, string, table?)

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
        :classifier(structured_output_handler._mapper.classify_error :: ClassifyError)

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

    local instructions = structured_output_handler._mapper.extract_instructions(contract_args.messages)
    local input_items = structured_output_handler._mapper.map_messages(contract_args.messages, {
        model = contract_args.model
    })

    if #input_items == 0 then
        return nil, err:kind(output.ERROR_TYPE.INVALID_REQUEST):message(output.NO_TURN_MESSAGE):build()
    end

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

    local mapped_options, options_err = structured_output_handler._mapper.map_options(contract_args.options, contract_args.accepts)
    if options_err then
        return nil, err:kind(output.ERROR_TYPE.INVALID_REQUEST):message(options_err):build()
    end
    for key, value in pairs(mapped_options) do
        payload[key] = value
    end

    local overlay_err = wire_request.apply(payload, (contract_args.options or {}).request, openai_mapper.STRUCTURED_REQUEST_KEYS)
    if overlay_err then
        return nil, err:kind(output.ERROR_TYPE.INVALID_REQUEST):message(overlay_err):build()
    end

    local request_options = {
        timeout = contract_args.timeout,
        retry = contract_args.retry,
    }

    local response, req_err = structured_output_handler._client.request("/responses", payload, request_options)

    if req_err then
        return nil, err:from(req_err):build()
    end

    local usage = type(response) == "table" and response.usage
    if type(usage) == "table" then
        for _, key in ipairs({ "input_tokens", "output_tokens", "total_tokens" }) do
            if usage[key] ~= nil and type(usage[key]) ~= "number" then usage = nil; break end
        end
    end
    if type(usage) == "table" then
        for _, key in ipairs({ "input_tokens_details", "output_tokens_details" }) do
            local detail = usage[key]
            if detail ~= nil and type(detail) ~= "table" then usage = nil; break end
            if type(detail) == "table" then
                for _, field in ipairs({ "cached_tokens", "reasoning_tokens" }) do
                    if detail[field] ~= nil and type(detail[field]) ~= "number" then usage = nil; break end
                end
                if not usage then break end
            end
        end
    end
    local tokens = type(usage) == "table" and structured_output_handler._mapper.map_tokens(usage) or nil
    local has_tool_calls = false
    if type(response) == "table" and type(response.output) == "table" then
        for _, item in ipairs(response.output) do
            if type(item) == "table" and item.type == "function_call" then has_tool_calls = true; break end
        end
    end
    local incomplete = type(response) == "table" and response.incomplete_details or nil
    local finish_reason = type(response) == "table" and type(response.status) == "string"
        and (incomplete == nil or type(incomplete) == "table")
        and (incomplete == nil or incomplete.reason == nil or type(incomplete.reason) == "string")
        and structured_output_handler._mapper.map_finish_reason(response.status, has_tool_calls, incomplete and incomplete.reason) or nil
    err:response(tokens, finish_reason)

    if not response or not response.output then
        return nil, err
            :kind(output.ERROR_TYPE.SERVER_ERROR)
            :message("Invalid response structure from OpenAI Responses API")
            :details(response and response.metadata or nil)
            :build()
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
        return nil, err
            :kind(output.ERROR_TYPE.CONTENT_FILTER)
            :message("Request was refused: " .. refusal)
            :details({ response_id = response.id, refusal = refusal })
            :build()
    end

    if not content_text or content_text == "" then
        return nil, err
            :kind(output.ERROR_TYPE.SERVER_ERROR)
            :message("No content in Responses API response")
            :details({ response_id = response.id })
            :build()
    end

    local parsed_content, decode_err = json.decode(tostring(content_text))
    if decode_err then
        return nil, err
            :kind(output.ERROR_TYPE.MODEL_ERROR)
            :message("Model failed to return valid JSON: " .. decode_err)
            :details({ response_id = response.id, raw_content = content_text })
            :build()
    end

    has_tool_calls = false
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
            response.status, has_tool_calls, response.incomplete_details and response.incomplete_details.reason or nil),
        metadata = meta
    }
end

return structured_output_handler
