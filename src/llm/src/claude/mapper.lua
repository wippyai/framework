local output = require("output")
local prompt = require("prompt")
local json = require("json")

local mapper = {}

mapper.FINISH_REASON_MAP = {
    ["end_turn"] = output.FINISH_REASON.STOP,
    ["max_tokens"] = output.FINISH_REASON.LENGTH,
    ["stop_sequence"] = output.FINISH_REASON.STOP,
    ["tool_use"] = output.FINISH_REASON.TOOL_CALL
}

mapper.CLAUDE_ERROR_TYPE_MAP = {
    ["invalid_request_error"] = output.ERROR_TYPE.INVALID_REQUEST,
    ["authentication_error"] = output.ERROR_TYPE.AUTHENTICATION,
    ["permission_error"] = output.ERROR_TYPE.AUTHENTICATION,
    ["not_found_error"] = output.ERROR_TYPE.MODEL_ERROR,
    ["request_too_large"] = output.ERROR_TYPE.INVALID_REQUEST,
    ["rate_limit_error"] = output.ERROR_TYPE.RATE_LIMIT,
    ["api_error"] = output.ERROR_TYPE.SERVER_ERROR,
    ["overloaded_error"] = output.ERROR_TYPE.SERVER_ERROR
}

mapper.HTTP_STATUS_MAP = {
    [400] = output.ERROR_TYPE.INVALID_REQUEST,
    [401] = output.ERROR_TYPE.AUTHENTICATION,
    [403] = output.ERROR_TYPE.AUTHENTICATION,
    [404] = output.ERROR_TYPE.MODEL_ERROR,
    [413] = output.ERROR_TYPE.INVALID_REQUEST,
    [429] = output.ERROR_TYPE.RATE_LIMIT,
    [500] = output.ERROR_TYPE.SERVER_ERROR,
    [502] = output.ERROR_TYPE.SERVER_ERROR,
    [503] = output.ERROR_TYPE.SERVER_ERROR,
    [529] = output.ERROR_TYPE.SERVER_ERROR
}

-- Claude API cache control limit
local MAX_CACHE_BREAKPOINTS = 4

-- Approximate token count from text (rough estimation: ~4 chars per token)
local function approximate_token_count(text)
    if not text or text == "" then return 0 end
    return math.ceil(string.len(text) / 4)
end

-- Sanitize tool ID to match Claude's pattern ^[a-zA-Z0-9*-]+$
local function sanitize_tool_id(original_id)
    if not original_id then
        return "tool_" .. tostring(math.random(100000, 999999))
    end

    -- Replace invalid characters with underscores, then replace underscores with hyphens
    local sanitized = string.gsub(original_id, "[^a-zA-Z0-9*%-]", "_")
    sanitized = string.gsub(sanitized, "_", "-")

    -- Ensure it starts with alphanumeric
    if not string.match(sanitized, "^[a-zA-Z0-9]") then
        sanitized = "tool-" .. sanitized
    end

    -- Ensure it's not empty
    if sanitized == "" or sanitized == "-" then
        sanitized = "tool-" .. tostring(math.random(100000, 999999))
    end

    return sanitized
end

-- Simple cache marker collapse: keep all system markers + most recent message markers
local function collapse_cache_positions(system_positions, message_positions)
    local total_positions = #system_positions + #message_positions

    -- No collapse needed
    if total_positions <= MAX_CACHE_BREAKPOINTS then
        return system_positions, message_positions
    end

    local final_system = {}
    local final_message = {}

    -- Keep all system markers (usually 1-2)
    for _, pos in ipairs(system_positions) do
        table.insert(final_system, pos)
    end

    -- Use remaining slots for most recent message markers
    local remaining_slots = MAX_CACHE_BREAKPOINTS - #final_system

    if remaining_slots > 0 and #message_positions > 0 then
        if #message_positions <= remaining_slots then
            -- Keep all message markers
            for _, pos in ipairs(message_positions) do
                table.insert(final_message, pos)
            end
        else
            -- Keep most recent N markers
            local start_idx = math.max(1, #message_positions - remaining_slots + 1)
            for i = start_idx, #message_positions do
                table.insert(final_message, message_positions[i])
            end
        end
    end

    return final_system, final_message
end

function mapper.map_error_response(claude_error)
    if not claude_error then
        return {
            success = false,
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "Unknown error"
        }
    end

    local error_type = output.ERROR_TYPE.SERVER_ERROR
    local error_message = "Unknown Claude API error"

    if claude_error.error and claude_error.error.type then
        error_type = mapper.CLAUDE_ERROR_TYPE_MAP[claude_error.error.type] or output.ERROR_TYPE.SERVER_ERROR
        error_message = claude_error.error.message or claude_error.message or error_message
    elseif claude_error.status_code then
        error_type = mapper.HTTP_STATUS_MAP[claude_error.status_code] or output.ERROR_TYPE.SERVER_ERROR
        error_message = claude_error.message or error_message
    elseif claude_error.message then
        error_message = claude_error.message
    end

    return {
        success = false,
        error = error_type,
        error_message = error_message,
        metadata = claude_error.metadata or {}
    }
end

function mapper.map_tokens(claude_usage)
    if not claude_usage then
        return nil
    end

    local tokens = output.usage(
        claude_usage.input_tokens or 0,
        claude_usage.output_tokens or 0,
        0, -- thinking_tokens - calculated separately
        claude_usage.cache_creation_input_tokens or 0,
        claude_usage.cache_read_input_tokens or 0
    )

    -- Use clean names for consistency
    tokens.cache_write_tokens = claude_usage.cache_creation_input_tokens or 0
    tokens.cache_read_tokens = claude_usage.cache_read_input_tokens or 0

    return tokens
end

function mapper.map_finish_reason(claude_stop_reason)
    return mapper.FINISH_REASON_MAP[claude_stop_reason] or claude_stop_reason
end

local function extract_thinking_content_from_blocks(thinking_blocks)
    local thinking_content = ""
    for _, block in ipairs(thinking_blocks) do
        if block.type == "thinking" and block.thinking then
            thinking_content = thinking_content .. block.thinking
        end
    end
    return thinking_content
end

local function convert_image_content(content_part)
    if content_part.type == "image" and content_part.source then
        if content_part.source.type == "base64" then
            return {
                type = "image",
                source = {
                    type = "base64",
                    media_type = content_part.source.mime_type,
                    data = content_part.source.data
                }
            }
        elseif content_part.source.type == "url" then
            return {
                type = "image",
                source = {
                    type = "url",
                    url = content_part.source.url
                }
            }
        end
    end
    return content_part
end

local function process_content_array(content)
    if type(content) == "string" then
        return content
    elseif type(content) == "table" then
        local processed = {}
        for _, part in ipairs(content) do
            table.insert(processed, convert_image_content(part))
        end
        return processed
    end
    return content
end

local function normalize_tool_arguments(raw_arguments)
    local arguments = raw_arguments

    if type(arguments) == "string" then
        local parsed, parse_err = json.decode(arguments)
        if not parse_err and type(parsed) == "table" then
            arguments = parsed
        else
            arguments = { value = arguments }
        end
    end

    if not arguments or type(arguments) ~= "table" then
        arguments = { run = true }
    end

    if next(arguments) == nil then
        arguments = { run = true }
    end

    return arguments
end

local function consolidate_messages(messages)
    if #messages <= 1 then
        return messages
    end

    local result = {}

    for i, msg in ipairs(messages) do
        if msg.role == "assistant" and #result > 0 and result[#result].role == "assistant" then
            for _, content_part in ipairs(msg.content) do
                if content_part ~= "" and content_part ~= nil then
                    table.insert(result[#result].content, content_part)
                end
            end
        else
            table.insert(result, msg)
        end
    end

    return result
end

local function ensure_content_exists(messages)
    for i = 1, #messages - 1 do
        if not messages[i].content or #messages[i].content == 0 then
            messages[i].content = {{ type = "text", text = "intercepted" }}
        end
    end
    return messages
end

function mapper.map_messages(contract_messages)
    if not contract_messages or #contract_messages == 0 then
        return {
            messages = {},
            system = nil
        }
    end

    local claude_messages = {}
    local system_blocks = {}
    local system_cache_positions = {}
    local message_cache_positions = {}
    local in_system_phase = true

    for i, msg in ipairs(contract_messages) do
        if msg.role == prompt.ROLE.SYSTEM then
            if type(msg.content) == "string" then
                table.insert(system_blocks, {
                    type = "text",
                    text = msg.content
                })
            elseif type(msg.content) == "table" then
                for _, part in ipairs(msg.content) do
                    table.insert(system_blocks, convert_image_content(part))
                end
            end
        elseif msg.role == "cache_marker" then
            if in_system_phase then
                -- Cache marker applies to system blocks
                table.insert(system_cache_positions, #system_blocks)
            else
                -- Cache marker applies to claude messages
                table.insert(message_cache_positions, #claude_messages)
            end
        elseif msg.role == prompt.ROLE.DEVELOPER then
            in_system_phase = false
            local dev_text = type(msg.content) == "string" and msg.content or
                (type(msg.content) == "table" and msg.content[1] and msg.content[1].text) or ""

            if dev_text ~= "" then
                -- Check if previous message is tool_result (or if no previous messages)
                local should_create_new_message = false

                if #claude_messages == 0 then
                    should_create_new_message = true
                else
                    local last_msg = claude_messages[#claude_messages]
                    -- If last message is tool_result, create new user message
                    if last_msg.role == "user" and last_msg.content and last_msg.content[1] and
                       last_msg.content[1].type == "tool_result" then
                        should_create_new_message = true
                    end
                end

                if should_create_new_message then
                    -- Create new user message for developer content
                    table.insert(claude_messages, {
                        role = "user",
                        content = {
                            {
                                type = "text",
                                text = dev_text
                            }
                        }
                    })
                else
                    -- Try to merge into previous message (existing logic)
                    local last_msg = claude_messages[#claude_messages]
                    for j = #last_msg.content, 1, -1 do
                        if last_msg.content[j].type == "text" then
                            last_msg.content[j].text = last_msg.content[j].text ..
                                "\n<developer-instruction>" .. dev_text .. "</developer-instruction>"
                            break
                        end
                    end
                end
            end
        elseif msg.role == prompt.ROLE.FUNCTION_RESULT then
            in_system_phase = false
            local result_text = type(msg.content) == "string" and msg.content or
                (type(msg.content) == "table" and msg.content[1] and msg.content[1].text) or ""

            table.insert(claude_messages, {
                role = "user",
                content = {
                    {
                        type = "tool_result",
                        tool_use_id = sanitize_tool_id(msg.function_call_id),
                        content = result_text
                    }
                }
            })
        elseif msg.role == prompt.ROLE.FUNCTION_CALL then
            in_system_phase = false
            local arguments = normalize_tool_arguments(msg.function_call.arguments)
            local content_blocks = {}

            if msg.metadata and msg.metadata.thinking_blocks then
                for _, thinking_block in ipairs(msg.metadata.thinking_blocks) do
                    table.insert(content_blocks, thinking_block)
                end
            end

            table.insert(content_blocks, {
                type = "tool_use",
                id = sanitize_tool_id(msg.function_call.id),
                name = msg.function_call.name,
                input = arguments
            })

            table.insert(claude_messages, {
                role = "assistant",
                content = content_blocks
            })
        elseif msg.role == prompt.ROLE.ASSISTANT then
            in_system_phase = false
            local content_blocks = {}

            if msg.metadata and msg.metadata.thinking_blocks then
                for _, thinking_block in ipairs(msg.metadata.thinking_blocks) do
                    table.insert(content_blocks, thinking_block)
                end
            end

            local regular_content = process_content_array(msg.content)

            if type(regular_content) == "string" and regular_content ~= "" then
                table.insert(content_blocks, {
                    type = "text",
                    text = regular_content
                })
            elseif type(regular_content) == "table" then
                for _, part in ipairs(regular_content) do
                    if part.type == "function_call" then
                        local arguments = normalize_tool_arguments(part.arguments)
                        table.insert(content_blocks, {
                            type = "tool_use",
                            id = sanitize_tool_id(part.id),
                            name = part.name,
                            input = arguments
                        })
                    elseif part.type == "text" and part.text and part.text ~= "" then
                        table.insert(content_blocks, part)
                    elseif part.type ~= "text" then
                        table.insert(content_blocks, part)
                    end
                end
            end

            table.insert(claude_messages, {
                role = msg.role,
                content = content_blocks
            })
        else
            -- User messages and other types
            in_system_phase = false
            local content = process_content_array(msg.content)
            if type(content) == "string" then
                content = {{ type = "text", text = content }}
            end
            table.insert(claude_messages, {
                role = msg.role,
                content = content
            })
        end
    end

    -- Collapse cache positions if needed
    local final_system_positions, final_message_positions = collapse_cache_positions(
        system_cache_positions, message_cache_positions
    )

    -- Apply cache control to system blocks
    if #final_system_positions > 0 and #system_blocks > 0 then
        for _, pos in ipairs(final_system_positions) do
            if pos > 0 and pos <= #system_blocks then
                system_blocks[pos].cache_control = { type = "ephemeral" }
            end
        end
    end

    -- Apply cache control to claude messages
    if #final_message_positions > 0 and #claude_messages > 0 then
        for _, pos in ipairs(final_message_positions) do
            if pos > 0 and pos <= #claude_messages then
                -- Apply cache control to the last content block of the message
                local msg = claude_messages[pos]
                if msg.content and #msg.content > 0 then
                    msg.content[#msg.content].cache_control = { type = "ephemeral" }
                end
            end
        end
    end

    claude_messages = consolidate_messages(claude_messages)
    claude_messages = ensure_content_exists(claude_messages)

    return {
        messages = claude_messages,
        system = #system_blocks > 0 and system_blocks or nil
    }
end

function mapper.map_tools(contract_tools)
    local claude_tools = {}
    local name_to_id_map = {}

    for _, tool in ipairs(contract_tools) do
        if tool.schema then
            local claude_meta = tool.meta and tool.meta.claude

            -- Check if this is a Claude native tool
            if claude_meta and claude_meta.type then
                -- Native tool format - only include type and tool-specific params
                local claude_tool = {
                    type = claude_meta.type,
                    name = tool.name
                }

                -- Copy other Claude parameters (excluding type)
                for key, value in pairs(claude_meta) do
                    if key ~= "type" then
                        claude_tool[key] = value
                    end
                end

                table.insert(claude_tools, claude_tool)
            else
                -- Custom tool format - include description and schema
                local claude_tool = {
                    name = tool.name,
                    description = tool.description,
                    input_schema = tool.schema
                }
                table.insert(claude_tools, claude_tool)
            end

            name_to_id_map[tool.name] = tool.id or tool.registry_id
        end
    end

    return claude_tools, name_to_id_map
end

function mapper.map_tool_choice(contract_choice, available_tools)
    if not available_tools or #available_tools == 0 then
        return nil
    end

    if not contract_choice or contract_choice == "auto" then
        return { type = "auto" }
    elseif contract_choice == "none" then
        return { type = "none" }
    elseif contract_choice == "any" then
        return { type = "any" }
    elseif type(contract_choice) == "string" then
        for _, tool in ipairs(available_tools) do
            if tool.name == contract_choice then
                return {
                    type = "tool",
                    name = contract_choice
                }
            end
        end
        return nil, "Tool '" .. contract_choice .. "' not found in available tools"
    end

    return nil, "Invalid tool_choice format"
end

function mapper.map_options(contract_options, model)
    local claude_options = {}

    if not contract_options then
        return claude_options
    end

    claude_options.temperature = contract_options.temperature
    claude_options.max_tokens = contract_options.max_tokens
    claude_options.top_p = contract_options.top_p
    claude_options.stop_sequences = contract_options.stop_sequences

    if contract_options.thinking_effort and contract_options.thinking_effort > 0 then
        local thinking_budget = 1024 + (24000 - 1024) * (contract_options.thinking_effort / 100)
        thinking_budget = math.floor(thinking_budget + 0.5)

        claude_options.thinking = {
            type = "enabled",
            budget_tokens = thinking_budget
        }

        claude_options.temperature = 1

        if not claude_options.max_tokens or claude_options.max_tokens <= thinking_budget then
            claude_options.max_tokens = thinking_budget + 1024
        end
    end

    return claude_options
end

function mapper.extract_response_content(claude_response)
    local content_text = ""
    local tool_calls = {}
    local thinking_blocks = {}

    if not claude_response or not claude_response.content then
        return {
            content = content_text,
            tool_calls = tool_calls,
            thinking_blocks = thinking_blocks
        }
    end

    for _, block in ipairs(claude_response.content) do
        if block.type == "text" then
            content_text = content_text .. (block.text or "")
        elseif block.type == "tool_use" then
            table.insert(tool_calls, {
                id = sanitize_tool_id(block.id),
                name = block.name or "",
                arguments = block.input or {}
            })
        elseif block.type == "thinking" or block.type == "redacted_thinking" then
            local thinking_block = {
                type = block.type,
                thinking = block.type == "thinking" and (block.thinking or "") or "",
                data = block.type == "redacted_thinking" and block.data or nil,
                signature = block.signature or ""
            }
            table.insert(thinking_blocks, thinking_block)
        end
    end

    return {
        content = content_text,
        tool_calls = tool_calls,
        thinking_blocks = thinking_blocks
    }
end

function mapper.map_tool_calls(claude_tool_calls, name_to_id_map)
    local contract_tool_calls = {}

    for _, tool_call in ipairs(claude_tool_calls) do
        table.insert(contract_tool_calls, {
            id = tool_call.id,
            name = tool_call.name,
            arguments = tool_call.arguments,
            registry_id = name_to_id_map[tool_call.name]
        })
    end

    return contract_tool_calls
end

function mapper.format_success_response(claude_response, model, name_to_id_map)
    local extracted = mapper.extract_response_content(claude_response)
    local tokens = mapper.map_tokens(claude_response.usage)
    local finish_reason = mapper.map_finish_reason(claude_response.stop_reason)
    local thinking_content = extract_thinking_content_from_blocks(extracted.thinking_blocks)

    -- Calculate approximate thinking tokens from thinking string
    if tokens and thinking_content and thinking_content ~= "" then
        tokens.thinking_tokens = approximate_token_count(thinking_content)
    end

    local result = {
        success = true,
        result = {
            content = extracted.content,
            tool_calls = mapper.map_tool_calls(extracted.tool_calls, name_to_id_map or {})
        },
        tokens = tokens,
        finish_reason = finish_reason,
        metadata = claude_response.metadata or {}
    }

    result.metadata.thinking = thinking_content
    result.metadata.thinking_blocks = extracted.thinking_blocks

    return result
end

function mapper.format_streaming_response(client_result, name_to_id_map, usage, finish_reason, response_metadata)
    local thinking_blocks = client_result.thinking or {}
    local thinking_content = extract_thinking_content_from_blocks(thinking_blocks)
    local mapped_tool_calls = mapper.map_tool_calls(client_result.tool_calls or {}, name_to_id_map or {})

    local tokens = mapper.map_tokens(usage)

    -- Calculate approximate thinking tokens from thinking string
    if tokens and thinking_content and thinking_content ~= "" then
        tokens.thinking_tokens = approximate_token_count(thinking_content)
    end

    local result = {
        success = true,
        result = {
            content = client_result.content or "",
            tool_calls = mapped_tool_calls
        },
        tokens = tokens,
        finish_reason = #mapped_tool_calls > 0 and output.FINISH_REASON.TOOL_CALL or
            mapper.map_finish_reason(finish_reason),
        metadata = response_metadata or {}
    }

    result.metadata.thinking = thinking_content
    result.metadata.thinking_blocks = thinking_blocks

    return result
end

return mapper
