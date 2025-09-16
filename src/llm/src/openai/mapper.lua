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

-- Check if model is a Claude model (for cache control support)
local function is_claude_model(model_name)
    if not model_name then return false end
    local lower_model = model_name:lower()
    return lower_model:match("claude") ~= nil
end

-- Apply cache control to text parts of a message
local function apply_cache_control_to_message(message)
    if not message or not message.content then return end

    for _, content_part in ipairs(message.content) do
        if content_part.type == "text" then
            content_part.cache_control = { type = "ephemeral" }
        end
    end
end

-- Extract reasoning text from reasoning_details (OpenRouter)
function openai_mapper.extract_reasoning_text(reasoning_details)
    if not reasoning_details then return "" end
    local reasoning_text = ""
    for _, detail in ipairs(reasoning_details) do
        if detail.text then
            reasoning_text = reasoning_text .. detail.text
        end
    end
    return reasoning_text
end

-- Convert universal image format to OpenAI format
local function convert_image_content(content_part)
    if content_part.type == "image" and content_part.source then
        if content_part.source.type == "url" then
            return {
                type = "image_url",
                image_url = { url = content_part.source.url }
            }
        elseif content_part.source.type == "base64" and content_part.source.mime_type then
            local data_url = "data:" .. content_part.source.mime_type .. ";base64," .. content_part.source.data
            return {
                type = "image_url",
                image_url = { url = data_url }
            }
        end
    end
    return content_part
end

-- Normalize content to structured format (for system/user messages)
local function normalize_content(content)
    -- Handle empty/nil content
    if content == "" or content == nil then
        return { { type = "text", text = "" } }
    end

    -- Handle string content
    if type(content) == "string" then
        return { { type = "text", text = content } }
    end

    -- Handle array content
    if type(content) == "table" then
        local processed_content = {}
        for i, part in ipairs(content) do
            if part.type == "text" then
                -- Handle nested text structures
                local text_content = part.text
                while type(text_content) == "table" and text_content.text do
                    text_content = text_content.text
                end

                -- Ensure string and proper field order
                local text_part = {
                    type = "text",
                    text = tostring(text_content or "")
                }

                -- Preserve cache_control if already present
                if part.cache_control then
                    text_part.cache_control = part.cache_control
                end

                processed_content[i] = text_part
            else
                processed_content[i] = convert_image_content(part)
            end
        end
        return processed_content
    end

    return content
end

-- MESSAGE MAPPING FUNCTIONS

---@param contract_messages table[] Array of contract message objects
---@param options table|nil Message mapping options
---@return table[] OpenAI messages format
function openai_mapper.map_messages(contract_messages, options)
    options = options or {}
    local processed_messages = {}
    local i = 1
    local is_claude = is_claude_model(options.model)

    while i <= #contract_messages do
        local msg = contract_messages[i]

        -- Clear metadata
        msg.metadata = nil

        if msg.role == "cache_marker" then
            -- Handle cache marker for Claude models
            if is_claude and #processed_messages > 0 then
                apply_cache_control_to_message(processed_messages[#processed_messages])
            end
            -- Skip cache marker message (don't add to processed_messages)
            i = i + 1
        elseif msg.role == "user" or msg.role == "system" then
            -- Standard user/system messages - use structured content
            local processed_msg = {
                role = msg.role,
                content = normalize_content(msg.content)
            }
            table.insert(processed_messages, processed_msg)
            i = i + 1
        elseif msg.role == "assistant" then
            -- Assistant messages - ALWAYS use simple string content for OpenRouter compatibility
            local assistant_msg = {
                role = "assistant",
                content = openai_mapper.standardize_content(msg.content), -- Simple string only
                tool_calls = {}
            }

            -- Preserve reasoning_details if present
            if msg.reasoning_details then
                assistant_msg.reasoning_details = msg.reasoning_details
            end

            i = i + 1 -- Move to next message

            -- Check if next messages are function_calls that should be consolidated
            while i <= #contract_messages and contract_messages[i].role == "function_call" do
                local func_msg = contract_messages[i]

                if func_msg.function_call and func_msg.function_call.id then
                    local arguments = func_msg.function_call.arguments
                    if type(arguments) == "table" and not next(arguments) then
                        arguments = { invoke = true }
                    end

                    table.insert(assistant_msg.tool_calls, {
                        id = func_msg.function_call.id,
                        type = "function",
                        ["function"] = {
                            name = func_msg.function_call.name,
                            arguments = (type(arguments) == "table") and json.encode(arguments) or tostring(arguments)
                        }
                    })
                end
                i = i + 1
            end

            -- Remove tool_calls field if empty
            if #assistant_msg.tool_calls == 0 then
                assistant_msg.tool_calls = nil
            end

            table.insert(processed_messages, assistant_msg)
        elseif msg.role == "function_result" then
            -- Convert function results to tool messages - use simple string content
            local tool_content = ""

            -- Extract text content properly
            if type(msg.content) == "string" then
                tool_content = msg.content
            elseif type(msg.content) == "table" then
                if #msg.content > 0 and msg.content[1] and msg.content[1].text then
                    -- Extract text from structured content
                    tool_content = msg.content[1].text
                else
                    -- Fallback: encode the table as JSON string
                    tool_content = json.encode(msg.content)
                end
            else
                tool_content = tostring(msg.content or "")
            end

            local tool_msg = {
                role = "tool",
                content = tool_content -- Simple string for OpenRouter compatibility
            }

            if msg.function_call_id then
                tool_msg.tool_call_id = msg.function_call_id
            end

            if msg.name then
                tool_msg.name = msg.name
            end

            table.insert(processed_messages, tool_msg)
            i = i + 1
        elseif msg.role == "developer" then
            -- Convert developer messages to system messages
            local content = ""
            if type(msg.content) == "string" then
                content = msg.content
            elseif type(msg.content) == "table" then
                for _, part in ipairs(msg.content) do
                    if part.type == "text" then
                        content = content .. part.text
                    end
                end
            end

            table.insert(processed_messages, {
                role = "system",
                content = normalize_content(content)
            })
            i = i + 1
        elseif msg.role == "function_call" then
            -- Standalone function_call (shouldn't happen with proper consolidation above)
            i = i + 1
        else
            -- Skip unknown message types
            i = i + 1
        end
    end

    return processed_messages
end

-- INPUT MAPPING FUNCTIONS

---@param contract_tools table[] Array of contract tool definitions
---@return table|nil, table OpenAI tools format and tool name map
function openai_mapper.map_tools(contract_tools)
    if not contract_tools or #contract_tools == 0 then
        return nil, {}
    end

    local openai_tools = {}
    local tool_name_map = {}

    for _, tool in ipairs(contract_tools) do
        if tool.name and tool.description and tool.schema then
            table.insert(openai_tools, {
                type = "function",
                ["function"] = {
                    name = tool.name,
                    description = tool.description,
                    parameters = tool.schema
                }
            })
            tool_name_map[tool.name] = tool
        end
    end

    return openai_tools, tool_name_map
end

---@param contract_choice string|nil Tool choice from contract
---@param available_tools table[] Available tools to validate against
---@return string|table|nil, string|nil OpenAI tool choice format and error message
function openai_mapper.map_tool_choice(contract_choice, available_tools)
    if not contract_choice or contract_choice == "auto" then
        return "auto", nil
    elseif contract_choice == "none" then
        return "none", nil
    elseif contract_choice == "any" then
        return "required", nil
    elseif type(contract_choice) == "string" then
        -- Specific tool name - verify it exists
        for _, tool in ipairs(available_tools or {}) do
            if tool.name == contract_choice then
                return {
                    type = "function",
                    ["function"] = { name = contract_choice }
                }, nil
            end
        end
        return nil, "Tool '" .. contract_choice .. "' not found in available tools"
    end

    return "auto", nil
end

---@param contract_options table|nil Contract options
---@return table OpenAI options
function openai_mapper.map_options(contract_options)
    if not contract_options then return {} end

    local openai_options = {}
    local is_reasoning_request = contract_options.reasoning_model_request == true

    if contract_options.max_tokens then
        if is_reasoning_request then
            openai_options.max_completion_tokens = contract_options.max_tokens
        else
            openai_options.max_tokens = contract_options.max_tokens
        end
    end

    if is_reasoning_request and contract_options.thinking_effort then
        local effort = contract_options.thinking_effort
        if effort < 25 then
            openai_options.reasoning_effort = "low"
        elseif effort < 75 then
            openai_options.reasoning_effort = "medium"
        else
            openai_options.reasoning_effort = "high"
        end
    else
        if contract_options.temperature ~= nil and not is_reasoning_request then
            openai_options.temperature = contract_options.temperature
        end
    end

    openai_options.top_p = contract_options.top_p
    openai_options.frequency_penalty = contract_options.frequency_penalty
    openai_options.presence_penalty = contract_options.presence_penalty
    openai_options.seed = contract_options.seed
    openai_options.user = contract_options.user

    if contract_options.stop_sequences then
        openai_options.stop = contract_options.stop_sequences
    end

    return openai_options
end

-- OUTPUT MAPPING FUNCTIONS

---@param openai_tool_calls table[] OpenAI tool calls
---@param tool_name_map table Tool name mapping
---@return table[] Contract format tool calls
function openai_mapper.map_tool_calls(openai_tool_calls, tool_name_map)
    if not openai_tool_calls then return {} end

    local contract_tool_calls = {}
    for i, tool_call in ipairs(openai_tool_calls) do
        if tool_call["function"] then
            local arguments = {}
            if tool_call["function"].arguments then
                local parsed_args, parse_err = json.decode(tool_call["function"].arguments)
                if not parse_err and parsed_args then
                    arguments = parsed_args
                end
            end

            contract_tool_calls[i] = {
                id = tool_call.id,
                name = tool_call["function"].name,
                arguments = arguments
            }
        end
    end

    return contract_tool_calls
end

---@param openai_finish_reason string|nil OpenAI finish reason
---@return string Contract format finish reason
function openai_mapper.map_finish_reason(openai_finish_reason)
    local FINISH_REASON_MAP = {
        ["stop"] = output.FINISH_REASON.STOP,
        ["length"] = output.FINISH_REASON.LENGTH,
        ["content_filter"] = output.FINISH_REASON.CONTENT_FILTER,
        ["tool_calls"] = output.FINISH_REASON.TOOL_CALL
    }

    return FINISH_REASON_MAP[openai_finish_reason] or output.FINISH_REASON.ERROR
end

---@param openai_usage table|nil OpenAI usage object
---@return table|nil Contract format token usage
function openai_mapper.map_tokens(openai_usage)
    if not openai_usage then return nil end

    local tokens = {
        prompt_tokens = openai_usage.prompt_tokens or 0,
        completion_tokens = openai_usage.completion_tokens or 0,
        total_tokens = openai_usage.total_tokens or 0,
        cache_write_tokens = 0,
        cache_read_tokens = 0,
        thinking_tokens = 0
    }

    if openai_usage.completion_tokens_details and openai_usage.completion_tokens_details.reasoning_tokens then
        tokens.thinking_tokens = openai_usage.completion_tokens_details.reasoning_tokens
    end

    if openai_usage.prompt_tokens_details and openai_usage.prompt_tokens_details.cached_tokens then
        tokens.cache_read_tokens = openai_usage.prompt_tokens_details.cached_tokens
        tokens.cache_write_tokens = math.max(0, tokens.prompt_tokens - tokens.cache_read_tokens)
        tokens.prompt_tokens = tokens.prompt_tokens - tokens.cache_read_tokens
    end

    return tokens
end

---@param openai_response table OpenAI API response
---@param context table Response mapping context
---@return table Contract success response
function openai_mapper.map_success_response(openai_response, context)
    if not openai_response or not openai_response.choices or #openai_response.choices == 0 then
        error("Invalid OpenAI response structure")
    end

    local choice = openai_response.choices[1]
    if not choice.message then
        error("No message in OpenAI choice")
    end

    if choice.message.refusal then
        return {
            success = false,
            error = output.ERROR_TYPE.CONTENT_FILTER,
            error_message = "Request was refused: " .. choice.message.refusal,
            metadata = openai_response.metadata or {}
        }
    end

    local response = {
        success = true,
        metadata = openai_response.metadata or {}
    }

    -- Handle reasoning details - store both thinking text and original details
    if openai_response.reasoning_details then
        response.metadata.thinking = openai_mapper.extract_reasoning_text(openai_response.reasoning_details)
        response.metadata.reasoning_details = openai_response.reasoning_details
    end

    if choice.message.tool_calls and #choice.message.tool_calls > 0 then
        response.result = {
            content = choice.message.content or "",
            tool_calls = openai_mapper.map_tool_calls(choice.message.tool_calls, context.tool_name_map)
        }
        response.finish_reason = output.FINISH_REASON.TOOL_CALL
    else
        response.result = {
            content = choice.message.content or "",
            tool_calls = {}
        }
        response.finish_reason = openai_mapper.map_finish_reason(choice.finish_reason)
    end

    response.tokens = openai_mapper.map_tokens(openai_response.usage)
    return response
end

---@param openai_error table OpenAI error object
---@return table Contract error response
function openai_mapper.map_error_response(openai_error)
    if not openai_error then
        return {
            success = false,
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "Unknown OpenAI error",
            metadata = {}
        }
    end

    local error_message = openai_error.message or "OpenAI API error"
    local error_type = map_error_type(openai_error.status_code, error_message)

    return {
        success = false,
        error = error_type,
        error_message = error_message,
        metadata = openai_error.metadata or {}
    }
end

-- Standardize content to a simple string (for assistant and tool messages)
function openai_mapper.standardize_content(content)
    if type(content) == "string" then
        return content
    elseif type(content) == "table" then
        local result = ""
        for _, part in ipairs(content) do
            if part.type == "text" then
                result = result .. part.text
            end
        end
        return result
    end
    return ""
end

return openai_mapper
