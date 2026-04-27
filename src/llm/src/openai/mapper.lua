local json = require("json")
local output = require("output")

local openai_mapper = {}

-- Error type mapping from HTTP status codes and message content
local function map_error_type(status_code, message)
    local error_type = output.ERROR_TYPE.SERVER_ERROR

    if status_code == 400 then
        error_type = output.ERROR_TYPE.INVALID_REQUEST
    elseif status_code == 401 or status_code == 403 then
        error_type = output.ERROR_TYPE.AUTHENTICATION
    elseif status_code == 404 then
        error_type = output.ERROR_TYPE.MODEL_ERROR
    elseif status_code == 429 then
        error_type = output.ERROR_TYPE.RATE_LIMIT
    elseif status_code and status_code >= 500 then
        error_type = output.ERROR_TYPE.SERVER_ERROR
    end

    if message then
        local lower_msg = message:lower()
        if lower_msg:match("context length") or lower_msg:match("maximum.+tokens") or lower_msg:match("string too long") then
            error_type = output.ERROR_TYPE.CONTEXT_LENGTH
        elseif lower_msg:match("content policy") or lower_msg:match("content filter") then
            error_type = output.ERROR_TYPE.CONTENT_FILTER
        elseif lower_msg:match("timeout") or lower_msg:match("timed out") then
            error_type = output.ERROR_TYPE.TIMEOUT
        elseif lower_msg:match("network") or lower_msg:match("connection") then
            error_type = output.ERROR_TYPE.NETWORK_ERROR
        end
    end

    return error_type
end

-- Convert a contract content part to a Responses API input content piece.
-- Input messages use input_text / input_image; assistant messages use output_text.
local function to_input_content_part(part)
    if type(part) == "string" then
        return { type = "input_text", text = part }
    end
    if type(part) ~= "table" then
        return { type = "input_text", text = tostring(part or "") }
    end

    if part.type == "text" then
        return { type = "input_text", text = tostring(part.text or "") }
    end

    if part.type == "image" and part.source then
        if part.source.type == "url" then
            return { type = "input_image", image_url = part.source.url }
        elseif part.source.type == "base64" and part.source.mime_type then
            local data_url = "data:" .. part.source.mime_type .. ";base64," .. part.source.data
            return { type = "input_image", image_url = data_url }
        end
    end

    if part.type == "input_text" or part.type == "input_image" or part.type == "input_file" then
        return part
    end

    return { type = "input_text", text = tostring(part.text or part.content or "") }
end

local function to_output_content_part(part)
    if type(part) == "string" then
        return { type = "output_text", text = part }
    end
    if type(part) ~= "table" then
        return { type = "output_text", text = tostring(part or "") }
    end
    if part.type == "text" then
        return { type = "output_text", text = tostring(part.text or "") }
    end
    if part.type == "output_text" then
        return part
    end
    return { type = "output_text", text = tostring(part.text or "") }
end

local function normalize_input_content(content)
    if content == nil or content == "" then
        return { { type = "input_text", text = "" } }
    end
    if type(content) == "string" then
        return { { type = "input_text", text = content } }
    end
    if type(content) == "table" then
        local parts = {}
        for i, p in ipairs(content) do
            parts[i] = to_input_content_part(p)
        end
        if #parts == 0 then
            return { { type = "input_text", text = "" } }
        end
        return parts
    end
    return { { type = "input_text", text = tostring(content) } }
end

local function normalize_output_content(content)
    if content == nil or content == "" then
        return nil
    end
    if type(content) == "string" then
        return { { type = "output_text", text = content } }
    end
    if type(content) == "table" then
        local parts = {}
        for i, p in ipairs(content) do
            parts[i] = to_output_content_part(p)
        end
        if #parts == 0 then return nil end
        return parts
    end
    return { { type = "output_text", text = tostring(content) } }
end

local function extract_text(content)
    if content == nil then return "" end
    if type(content) == "string" then return content end
    if type(content) == "table" then
        local out = ""
        for _, p in ipairs(content) do
            if type(p) == "string" then
                out = out .. p
            elseif type(p) == "table" and p.text then
                out = out .. tostring(p.text)
            end
        end
        return out
    end
    return tostring(content)
end

local function encode_arguments(arguments)
    if type(arguments) == "string" then
        return arguments
    end
    if type(arguments) == "table" then
        if not next(arguments) then
            return json.encode({ invoke = true })
        end
        return json.encode(arguments)
    end
    return tostring(arguments or "")
end

-- Pull all system / developer messages out of the contract message stream
-- into a single instructions string. Returns instructions plus a set of
-- consumed indices so map_messages can skip them.
function openai_mapper.extract_instructions(contract_messages)
    if not contract_messages then return nil, {} end

    local parts = {}
    local consumed = {}
    for i, msg in ipairs(contract_messages) do
        if msg.role == "system" or msg.role == "developer" then
            local text = extract_text(msg.content)
            if text and text ~= "" then
                table.insert(parts, text)
            end
            consumed[i] = true
        end
    end

    if #parts == 0 then return nil, consumed end
    return table.concat(parts, "\n\n"), consumed
end

-- Map contract messages into the Responses API input[] array.
-- system / developer messages are pulled out via extract_instructions().
function openai_mapper.map_messages(contract_messages, options)
    options = options or {}
    if not contract_messages then return {} end

    local _, consumed = openai_mapper.extract_instructions(contract_messages)
    local items = {}

    for i, msg in ipairs(contract_messages) do
        if not consumed[i] and msg.role ~= "cache_marker" then
            if msg.role == "user" then
                table.insert(items, {
                    type = "message",
                    role = "user",
                    content = normalize_input_content(msg.content)
                })
            elseif msg.role == "assistant" then
                local content = normalize_output_content(msg.content)
                if content then
                    table.insert(items, {
                        type = "message",
                        role = "assistant",
                        content = content
                    })
                end
            elseif msg.role == "function_call" then
                if msg.function_call and msg.function_call.id then
                    local pm = msg.function_call.provider_metadata
                    if pm and pm.encrypted_reasoning and pm.encrypted_reasoning ~= "" then
                        table.insert(items, {
                            type = "reasoning",
                            encrypted_content = pm.encrypted_reasoning,
                            summary = {}
                        })
                    end

                    table.insert(items, {
                        type = "function_call",
                        call_id = msg.function_call.id,
                        name = msg.function_call.name,
                        arguments = encode_arguments(msg.function_call.arguments)
                    })
                end
            elseif msg.role == "function_result" then
                local call_id = msg.function_call_id or (msg.function_call and msg.function_call.id)
                if call_id then
                    local out_text = ""
                    if type(msg.content) == "string" then
                        out_text = msg.content
                    elseif type(msg.content) == "table" then
                        if #msg.content > 0 and msg.content[1] and msg.content[1].text then
                            out_text = msg.content[1].text
                        else
                            out_text = json.encode(msg.content)
                        end
                    else
                        out_text = tostring(msg.content or "")
                    end
                    table.insert(items, {
                        type = "function_call_output",
                        call_id = call_id,
                        output = out_text
                    })
                end
            end
        end
    end

    return items
end

-- Map contract tools to Responses API tool definitions.
-- Format: { type = "function", name, description, parameters, strict }.
-- strict defaults to false for back-compat with existing tool schemas.
function openai_mapper.map_tools(contract_tools, opts)
    opts = opts or {}
    if not contract_tools or #contract_tools == 0 then
        return nil, {}
    end

    local strict_default = opts.strict_default
    if strict_default == nil then strict_default = false end

    local tools = {}
    local tool_name_map = {}

    for _, tool in ipairs(contract_tools) do
        if tool.name and tool.description and tool.schema then
            table.insert(tools, {
                type = "function",
                name = tool.name,
                description = tool.description,
                parameters = tool.schema,
                strict = strict_default
            })
            tool_name_map[tool.name] = tool
        end
    end

    return tools, tool_name_map
end

function openai_mapper.map_tool_choice(contract_choice, available_tools)
    if not contract_choice or contract_choice == "auto" then
        return "auto", nil
    elseif contract_choice == "none" then
        return "none", nil
    elseif contract_choice == "any" then
        return "required", nil
    elseif type(contract_choice) == "string" then
        for _, tool in ipairs(available_tools or {}) do
            if tool.name == contract_choice then
                return { type = "function", name = contract_choice }, nil
            end
        end
        return nil, "Tool '" .. contract_choice .. "' not found in available tools"
    end

    return "auto", nil
end

local function map_thinking_effort(effort)
    if effort == nil then return nil end
    if effort <= 0 then return "minimal" end
    if effort < 25 then return "low" end
    if effort < 60 then return "medium" end
    if effort < 90 then return "high" end
    return "xhigh"
end

openai_mapper.REASONING_PERSISTENCE = {
    PREVIOUS_RESPONSE = "previous_response",  -- store=true on server, hand off response_id (default)
    ENCRYPTED_CONTENT = "encrypted_content",  -- store=false, encrypted reasoning travels in messages
    NONE = "none"                             -- reasoning state not preserved across turns
}

function openai_mapper.resolve_reasoning_persistence(contract_options)
    if not contract_options or not contract_options.reasoning_persistence then
        return openai_mapper.REASONING_PERSISTENCE.PREVIOUS_RESPONSE
    end
    return contract_options.reasoning_persistence
end

function openai_mapper.map_options(contract_options)
    if not contract_options then return {} end

    local opts = {}
    local is_reasoning_request = contract_options.reasoning_model_request == true
    local persistence = openai_mapper.resolve_reasoning_persistence(contract_options)

    if contract_options.max_tokens then
        opts.max_output_tokens = contract_options.max_tokens
    end

    if is_reasoning_request then
        local reasoning = {}
        if contract_options.thinking_effort ~= nil then
            reasoning.effort = map_thinking_effort(contract_options.thinking_effort)
        end
        if contract_options.reasoning_summary then
            reasoning.summary = contract_options.reasoning_summary
        end
        if next(reasoning) then
            opts.reasoning = reasoning
        end
    else
        if contract_options.temperature ~= nil then
            opts.temperature = contract_options.temperature
        end
        if contract_options.top_p ~= nil then
            opts.top_p = contract_options.top_p
        end
    end

    if contract_options.user then
        opts.user = contract_options.user
    end

    if contract_options.parallel_tool_calls ~= nil then
        opts.parallel_tool_calls = contract_options.parallel_tool_calls
    end

    if contract_options.previous_response_id then
        opts.previous_response_id = contract_options.previous_response_id
    end

    if contract_options.store ~= nil then
        opts.store = contract_options.store
    end

    -- Encrypted reasoning persistence: ZDR-style flow where the client carries
    -- the encrypted reasoning state across turns. Force store=false (server
    -- discards state) and request the encrypted blob via include[].
    if persistence == openai_mapper.REASONING_PERSISTENCE.ENCRYPTED_CONTENT then
        if opts.store == nil then opts.store = false end
        opts.include = opts.include or {}
        local already_present = false
        for _, v in ipairs(opts.include) do
            if v == "reasoning.encrypted_content" then already_present = true; break end
        end
        if not already_present then
            table.insert(opts.include, "reasoning.encrypted_content")
        end
    end

    return opts
end

-- RESPONSE MAPPING

local function partition_output(output_items)
    local messages = {}
    local function_calls = {}
    local reasoning_items = {}

    if not output_items then
        return messages, function_calls, reasoning_items
    end

    for _, item in ipairs(output_items) do
        if item.type == "message" then
            table.insert(messages, item)
        elseif item.type == "function_call" then
            table.insert(function_calls, item)
        elseif item.type == "reasoning" then
            table.insert(reasoning_items, item)
        end
    end

    return messages, function_calls, reasoning_items
end

local function collect_message_text(message_items)
    local text = ""
    local refusal = nil
    for _, msg in ipairs(message_items) do
        if msg.content then
            for _, part in ipairs(msg.content) do
                if part.type == "output_text" and part.text then
                    text = text .. part.text
                elseif part.type == "refusal" and part.refusal then
                    refusal = part.refusal
                end
            end
        end
    end
    return text, refusal
end

local function collect_reasoning_text(reasoning_items)
    local text = ""
    for _, item in ipairs(reasoning_items) do
        if item.summary then
            for _, part in ipairs(item.summary) do
                if part.type == "summary_text" and part.text then
                    text = text .. part.text
                end
            end
        end
        if item.content then
            for _, part in ipairs(item.content) do
                if part.type == "reasoning_text" and part.text then
                    text = text .. part.text
                end
            end
        end
    end
    return text
end

function openai_mapper.map_tool_calls(function_call_items, reasoning_items)
    if not function_call_items then return {} end

    -- Pull encrypted_content blobs out of reasoning items in output order, so
    -- they can travel back on the next turn attached to function_calls via
    -- provider_metadata (mirrors Google's thought_signature flow).
    local encrypted_blobs = {}
    if reasoning_items then
        for _, ri in ipairs(reasoning_items) do
            if ri.encrypted_content and ri.encrypted_content ~= "" then
                table.insert(encrypted_blobs, ri.encrypted_content)
            end
        end
    end

    local result = {}
    for i, item in ipairs(function_call_items) do
        local arguments = {}
        if item.arguments then
            local parsed_args, parse_err = json.decode(tostring(item.arguments))
            if not parse_err and parsed_args then
                arguments = parsed_args
            end
        end

        local entry = {
            id = item.call_id or item.id,
            name = item.name,
            arguments = arguments
        }

        -- Distribute encrypted reasoning blobs across function_calls. Typical
        -- case: a single reasoning item precedes one or more function_calls;
        -- we attach the same blob to each so any subset replayed will carry
        -- the reasoning state.
        if #encrypted_blobs > 0 then
            local blob = encrypted_blobs[i] or encrypted_blobs[1]
            entry.provider_metadata = { encrypted_reasoning = blob }
        end

        result[i] = entry
    end
    return result
end

function openai_mapper.map_finish_reason(status, has_tool_calls, incomplete_reason)
    -- Truncated / filtered responses must surface as length / filtered even
    -- when function_call items were partially produced.
    if status == "incomplete" then
        if incomplete_reason == "content_filter" then
            return output.FINISH_REASON.CONTENT_FILTER
        end
        return output.FINISH_REASON.LENGTH
    end
    if status == "failed" or status == "cancelled" then
        return output.FINISH_REASON.ERROR
    end
    if has_tool_calls then
        return output.FINISH_REASON.TOOL_CALL
    end
    if status == "completed" then
        return output.FINISH_REASON.STOP
    end
    return output.FINISH_REASON.STOP
end

function openai_mapper.map_tokens(usage)
    if not usage then return nil end

    local prompt_tokens = tonumber(usage.input_tokens) or 0
    local completion_tokens = tonumber(usage.output_tokens) or 0
    local total = tonumber(usage.total_tokens) or (prompt_tokens + completion_tokens)

    local tokens = {
        prompt_tokens = prompt_tokens,
        completion_tokens = completion_tokens,
        total_tokens = total,
        cache_write_tokens = 0,
        cache_read_tokens = 0,
        thinking_tokens = 0
    }

    if usage.output_tokens_details and usage.output_tokens_details.reasoning_tokens then
        tokens.thinking_tokens = tonumber(usage.output_tokens_details.reasoning_tokens) or 0
    end

    if usage.input_tokens_details and usage.input_tokens_details.cached_tokens then
        local cached = tonumber(usage.input_tokens_details.cached_tokens) or 0
        tokens.cache_read_tokens = cached
        tokens.cache_write_tokens = math.max(0, prompt_tokens - cached)
        tokens.prompt_tokens = math.max(0, prompt_tokens - cached)
    end

    tokens.cache_creation_input_tokens = tokens.cache_write_tokens
    tokens.cache_read_input_tokens = tokens.cache_read_tokens

    return tokens
end

function openai_mapper.map_success_response(api_response, context)
    if not api_response then
        error("Invalid Responses API response: nil")
    end
    if not api_response.output then
        error("Invalid Responses API response structure: missing output")
    end

    local messages, function_calls, reasoning_items = partition_output(api_response.output)
    local content_text, refusal = collect_message_text(messages)

    if refusal then
        return {
            success = false,
            error = output.ERROR_TYPE.CONTENT_FILTER,
            error_message = "Request was refused: " .. refusal,
            metadata = api_response.metadata or {}
        }
    end

    local response = {
        success = true,
        metadata = api_response.metadata or {}
    }

    if api_response.id then
        response.metadata.response_id = api_response.id
    end

    local thinking = collect_reasoning_text(reasoning_items)
    if thinking ~= "" then
        response.metadata.thinking = thinking
    end

    -- Surface encrypted reasoning blobs at response level too, so callers that
    -- preserve text-only assistant turns (no tool calls) can still hand off
    -- the reasoning state on the next turn.
    if reasoning_items then
        local blobs = {}
        for _, ri in ipairs(reasoning_items) do
            if ri.encrypted_content and ri.encrypted_content ~= "" then
                table.insert(blobs, ri.encrypted_content)
            end
        end
        if #blobs > 0 then
            response.metadata.encrypted_reasoning = blobs[1]
            if #blobs > 1 then
                response.metadata.encrypted_reasoning_items = blobs
            end
        end
    end

    local mapped_tool_calls = openai_mapper.map_tool_calls(function_calls, reasoning_items)

    response.result = {
        content = content_text or "",
        tool_calls = mapped_tool_calls
    }

    response.finish_reason = openai_mapper.map_finish_reason(
        api_response.status,
        #mapped_tool_calls > 0,
        api_response.incomplete_details and api_response.incomplete_details.reason or nil
    )

    response.tokens = openai_mapper.map_tokens(api_response.usage)
    return response
end

function openai_mapper.map_error_response(api_error)
    if not api_error then
        local response = {
            success = false,
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "Unknown OpenAI error",
            metadata = {}
        }
        return response, output.to_structured_error(response)
    end

    local error_message = api_error.message or "OpenAI API error"
    local error_type = map_error_type(api_error.status_code, error_message)

    local response = {
        success = false,
        error = error_type,
        error_message = error_message,
        metadata = api_error.metadata or {}
    }
    return response, output.to_structured_error(response)
end

return openai_mapper
