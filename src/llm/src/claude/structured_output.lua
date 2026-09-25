local claude_client = require("claude_client")
local mapper = require("mapper")
local output = require("output")
local json = require("json")
local hash = require("hash")

type ClassifyError = (http_err: any?) -> (string, string, table?)

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

-- Native structured output (output_config.format) constrains every object in the
-- schema: each one must close itself with additionalProperties = false. Offending
-- objects are reported by path; the caller's schema is never rewritten, since
-- closing an open object changes what the caller accepts.
local SUBSCHEMA_LISTS = { "anyOf", "allOf", "oneOf", "prefixItems" }
local SUBSCHEMA_MAPS = { "properties", "$defs", "definitions" }

local function has_type(node, name)
    if node.type == name then return true end
    if type(node.type) == "table" then
        for _, t in ipairs(node.type) do
            if t == name then return true end
        end
    end
    return false
end

local function open_objects(node, path, found)
    if type(node) ~= "table" then return found end
    if (has_type(node, "object") or node.properties ~= nil) and node.additionalProperties ~= false then
        table.insert(found, path == "" and "(root)" or path)
    end
    local prefix = path == "" and "" or (path .. ".")
    for _, key in ipairs(SUBSCHEMA_MAPS) do
        if type(node[key]) == "table" then
            local names = {}
            for name in pairs(node[key]) do table.insert(names, name) end
            table.sort(names)
            for _, name in ipairs(names) do
                open_objects(node[key][name], prefix .. key .. "." .. name, found)
            end
        end
    end
    if type(node.items) == "table" then open_objects(node.items, prefix .. "items", found) end
    for _, key in ipairs(SUBSCHEMA_LISTS) do
        if type(node[key]) == "table" then
            for i, sub in ipairs(node[key]) do open_objects(sub, prefix .. key .. "." .. i, found) end
        end
    end
    return found
end

local function model_profile(contract_args)
    local profile = contract_args.options and contract_args.options.model_profile
    return type(profile) == "table" and profile or {}
end

-- The answer of a native structured output call: the JSON text of the response,
-- decoded. Refusals, truncation and non-JSON text are errors, never results.
local function native_result(response, err)
    if response.stop_reason == "refusal" then
        return nil, err:kind(output.ERROR_TYPE.CONTENT_FILTER)
            :message("Claude declined the structured output request (stop_reason refusal)"):build()
    end
    if response.stop_reason == "max_tokens" then
        return nil, err:kind(output.ERROR_TYPE.MODEL_ERROR)
            :message("Structured output was truncated (stop_reason max_tokens)"):build()
    end
    local text = ""
    for _, block in ipairs(response.content or {}) do
        if block.type == "text" and type(block.text) == "string" then
            text = text .. block.text
        end
    end
    local data, decode_err = json.decode(text)
    if decode_err or type(data) ~= "table" then
        return nil, err:kind(output.ERROR_TYPE.MODEL_ERROR)
            :message("Structured output is not a JSON object: " .. tostring(decode_err or text:sub(1, 120))):build()
    end
    return data
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
        return nil, err:kind(output.ERROR_TYPE.INVALID_REQUEST):message("Schema is required for structured output"):build()
    end

    local schema_valid, schema_errors = validate_schema(contract_args.schema)
    if not schema_valid then
        return nil, err
            :kind(output.ERROR_TYPE.INVALID_REQUEST)
            :message("Invalid schema: " .. table.concat(schema_errors, "; "))
            :details({ schema_errors = schema_errors })
            :build()
    end

    local profile = model_profile(contract_args)
    local native = profile.structured_output_mode == "native"

    if native then
        local open = open_objects(contract_args.schema, "", {})
        if #open > 0 then
            return nil, err
                :kind(output.ERROR_TYPE.INVALID_REQUEST)
                :message("Invalid schema for native structured output: objects without 'additionalProperties: false' at "
                    .. table.concat(open, ", "))
                :details({ schema_errors = open })
                :build()
        end
    elseif profile.forced_tool_choice == false then
        return nil, err
            :kind(output.ERROR_TYPE.INVALID_REQUEST)
            :message("Model does not accept a forced tool choice (model_profile.forced_tool_choice = false): "
                .. "structured output needs model_profile.structured_output_mode = \"native\"")
            :build()
    end

    local mapped_messages = structured_output_handler._mapper.map_messages(contract_args.messages)
    local mapped_options = structured_output_handler._mapper.map_options(contract_args.options or {}, contract_args.model)

    if native then
        local output_config = mapped_options.output_config or {}
        output_config.format = { type = "json_schema", schema = contract_args.schema }

        local native_payload = {
            model = contract_args.model,
            messages = mapped_messages.messages,
            max_tokens = mapped_options.max_tokens or 2000
        }
        if mapped_messages.system then
            native_payload.system = mapped_messages.system
        end
        for k, v in pairs(mapped_options) do
            if k ~= "max_tokens" then
                native_payload[k] = v
            end
        end
        native_payload.output_config = output_config

        local response, request_err = structured_output_handler._client.request(
            structured_output_handler._client.ENDPOINTS.MESSAGES,
            native_payload,
            { timeout = contract_args.timeout, retry = contract_args.retry }
        )
        if request_err then
            return nil, err:from(request_err):build()
        end
        if not response or not response.content then
            return nil, err
                :kind(output.ERROR_TYPE.SERVER_ERROR)
                :message("Invalid response structure from Claude")
                :details(response and response.metadata or nil)
                :build()
        end

        local data, data_err = native_result(response, err)
        if not data then
            return nil, data_err
        end

        return {
            success = true,
            result = { data = data },
            tokens = structured_output_handler._mapper.map_tokens(response.usage),
            finish_reason = "stop",
            metadata = response.metadata or {}
        }
    end

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
        timeout = contract_args.timeout,
        retry = contract_args.retry
    }

    local response, request_err = structured_output_handler._client.request(
        structured_output_handler._client.ENDPOINTS.MESSAGES,
        claude_payload,
        request_options
    )

    if request_err then
        return nil, err:from(request_err):build()
    end

    if not response or not response.content then
        return nil, err
            :kind(output.ERROR_TYPE.SERVER_ERROR)
            :message("Invalid response structure from Claude")
            :details(response and response.metadata or nil)
            :build()
    end

    local tool_use_block = nil
    for _, block in ipairs(response.content) do
        if block.type == "tool_use" and block.name == "structured_output" then
            tool_use_block = block
            break
        end
    end

    if not tool_use_block then
        return nil, err
            :kind(output.ERROR_TYPE.SERVER_ERROR)
            :message("Claude failed to use the structured_output tool")
            :build()
    end

    if not tool_use_block.input then
        return nil, err
            :kind(output.ERROR_TYPE.SERVER_ERROR)
            :message("Tool use block does not contain input")
            :build()
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
