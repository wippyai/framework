local json = require("json")
local output = require("output")

local openai_mapper = {}

-- Error type mapping from HTTP status codes and message content
local function map_error_type(status_code, message)
    -- Default classification
    local error_type = output.ERROR_TYPE.SERVER_ERROR

    -- Map by status code first
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

    -- Override based on message content for more specific classification
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

---@param effort number|nil Thinking effort 0-100
---@return string|nil OpenAI reasoning effort value
local function map_thinking_effort(effort)
    if not effort or effort <= 0 then return nil end
    if effort < 25 then
        return "low"
    elseif effort < 75 then
        return "medium"
    else
        return "high"
    end
end

-- Convert universal image format to OpenAI format
local function convert_image_content(content_part)
    if content_part.type == "image" and content_part.source then
        if content_part.source.type == "url" then
            return {
                type = "image_url",
                image_url = {
                    url = content_part.source.url
                }
            }
        elseif content_part.source.type == "base64" and content_part.source.mime_type then
            -- Convert base64 with mime_type to data URL format for OpenAI
            local data_url = "data:" .. content_part.source.mime_type .. ";base64," .. content_part.source.data
            return {
                type = "image_url",
                image_url = {
                    url = data_url
                }
            }
        end
    end

    -- Return unchanged if not an image or unsupported format
    return content_part
end

-- Process content array to convert image formats
local function process_content_array(content)
    if type(content) == "string" then
        return content
    elseif type(content) == "table" then
        local processed_content = table.create(#content, 0)
        for i, part in ipairs(content) do
            processed_content[i] = convert_image_content(part)
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

    while i <= #contract_messages do
        local msg = contract_messages[i]
        msg.metadata = nil

        -- Pass through standard OpenAI message types
        if msg.role == "user" or msg.role == "assistant" or msg.role == "system" then
            local processed_msg = {
                role = msg.role,
                content = process_content_array(msg.content)
            }
            table.insert(processed_messages, processed_msg)
            i = i + 1

            -- Handle consecutive function_call messages - consolidate into one assistant message
        elseif msg.role == "function_call" then
            local assistant_msg = {
                role = "assistant",
                content = "",
                tool_calls = {}
            }

            -- Collect all consecutive function_call messages
            while i <= #contract_messages and contract_messages[i].role == "function_call" do
                local func_msg = contract_messages[i]

                if func_msg.function_call and func_msg.function_call.id then
                    table.insert(assistant_msg.tool_calls, {
                        id = func_msg.function_call.id,
                        type = "function",
                        ["function"] = {
                            name = func_msg.function_call.name,
                            arguments = (type(func_msg.function_call.arguments) == "table")
                                and json.encode(func_msg.function_call.arguments)
                                or tostring(func_msg.function_call.arguments)
                        }
                    })
                end

                i = i + 1
            end

            -- Only add the message if we have tool calls
            if #assistant_msg.tool_calls > 0 then
                table.insert(processed_messages, assistant_msg)
            end

            -- Convert function messages to tool messages
        elseif msg.role == "function_result" then
            local tool_msg = {
                role = "tool",
                content = (type(msg.content) == "table" and #msg.content > 0 and msg.content[1].text) or msg.content
            }

            if type(tool_msg.content) == "table" then
                tool_msg.content = json.encode(tool_msg.content)
            end

            -- Add tool_call_id if available
            if msg.function_call_id then
                tool_msg.tool_call_id = msg.function_call_id
            end

            -- Add name as metadata (not standard but useful)
            if msg.name then
                tool_msg.name = msg.name
            end

            table.insert(processed_messages, tool_msg)
            i = i + 1

            -- Handle developer messages - convert to system messages
        elseif msg.role == "developer" then
            -- Extract content from developer message
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

            -- Add as system message
            table.insert(processed_messages, {
                role = "system",
                content = content
            })
            i = i + 1
        else
            -- Skip unknown message types
            i = i + 1
        end
    end

    return processed_messages
end

-- Standardize content to a simple string
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

-- INPUT MAPPING FUNCTIONS

---@param contract_tools table[] Array of contract tool definitions
---@return table|nil, table OpenAI tools format and tool name map
function openai_mapper.map_tools(contract_tools)
    if not contract_tools or #contract_tools == 0 then
        return nil, {}
    end

    local openai_tools = table.create(#contract_tools, 0)
    local tool_name_map = {}
    local tool_count = 0

    for _, tool in ipairs(contract_tools) do
        if tool.name and tool.description and tool.schema then
            tool_count = tool_count + 1
            openai_tools[tool_count] = {
                type = "function",
                ["function"] = {
                    name = tool.name,
                    description = tool.description,
                    parameters = tool.schema
                }
            }
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
        local tool_exists = false
        if available_tools then
            for _, tool in ipairs(available_tools) do
                if tool.name == contract_choice then
                    tool_exists = true
                    break
                end
            end
        end

        if tool_exists then
            return {
                type = "function",
                ["function"] = { name = contract_choice }
            }, nil
        else
            return nil, "Tool '" .. contract_choice .. "' not found in available tools"
        end
    end

    return "auto", nil -- fallback
end

---@param contract_options table|nil Contract options
---@return table OpenAI options
function openai_mapper.map_options(contract_options)
    if not contract_options then return {} end

    local openai_options = {}

    -- Use caller-provided reasoning flag
    local is_reasoning_request = contract_options.reasoning_model_request == true

    -- Handle max tokens parameter - reasoning models automatically use completion tokens API
    if contract_options.max_tokens then
        if is_reasoning_request then
            openai_options.max_completion_tokens = contract_options.max_tokens
        else
            openai_options.max_tokens = contract_options.max_tokens
        end
    end

    -- Handle reasoning mode based on caller flag
    if is_reasoning_request and contract_options.thinking_effort then
        openai_options.reasoning_effort = map_thinking_effort(contract_options.thinking_effort)
        -- Reasoning models don't support temperature
    else
        -- Standard mode - always allow temperature
        if contract_options.temperature ~= nil then
            openai_options.temperature = contract_options.temperature
        end
    end

    -- Map other standard options
    openai_options.top_p = contract_options.top_p
    openai_options.frequency_penalty = contract_options.frequency_penalty
    openai_options.presence_penalty = contract_options.presence_penalty
    openai_options.seed = contract_options.seed
    openai_options.user = contract_options.user

    -- Handle stop sequences
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

    local contract_tool_calls = table.create(#openai_tool_calls, 0)

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
        cache_creation_input_tokens = 0,
        cache_read_input_tokens = 0,
        thinking_tokens = 0
    }

    -- Handle thinking tokens from reasoning-capable models
    if openai_usage.completion_tokens_details and openai_usage.completion_tokens_details.reasoning_tokens then
        tokens.thinking_tokens = openai_usage.completion_tokens_details.reasoning_tokens
    end

    -- Handle cache tokens if available
    if openai_usage.prompt_tokens_details and openai_usage.prompt_tokens_details.cached_tokens then
        tokens.cache_read_input_tokens = openai_usage.prompt_tokens_details.cached_tokens
        -- Calculate cache creation tokens (non-cached prompt tokens)
        tokens.cache_creation_input_tokens = math.max(0,
            tokens.prompt_tokens - tokens.cache_read_input_tokens)
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

    -- Check for refusals first
    if choice.message.refusal then
        return {
            success = false,
            error = output.ERROR_TYPE.CONTENT_FILTER,
            error_message = "Request was refused: " .. choice.message.refusal,
            metadata = openai_response.metadata or {}
        }
    end

    -- Build success response
    local response = {
        success = true,
        metadata = openai_response.metadata or {}
    }

    -- Handle tool calls vs text content
    if choice.message.tool_calls and #choice.message.tool_calls > 0 then
        -- Tool calling response
        response.result = {
            content = choice.message.content or "",
            tool_calls = openai_mapper.map_tool_calls(choice.message.tool_calls, context.tool_name_map)
        }
        response.finish_reason = output.FINISH_REASON.TOOL_CALL
    else
        -- Text response
        response.result = {
            content = choice.message.content or "",
            tool_calls = {}
        }
        response.finish_reason = openai_mapper.map_finish_reason(choice.finish_reason)
    end

    -- Add token usage
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

return openai_mapper
