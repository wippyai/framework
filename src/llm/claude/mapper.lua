local output = require("output")
local prompt = require("prompt")
local json = require("json")

-- Claude Mapper Library - Standardizes Claude API request/response mapping
local mapper = {}

-- Map finish reasons from Claude to standard format
mapper.FINISH_REASON_MAP = {
    ["end_turn"] = output.FINISH_REASON.STOP,
    ["max_tokens"] = output.FINISH_REASON.LENGTH,
    ["stop_sequence"] = output.FINISH_REASON.STOP,
    ["tool_use"] = output.FINISH_REASON.TOOL_CALL
}

-- Map Claude API errors to standardized error types
function mapper.map_error(err)
    if not err then
        return {
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "Unknown error (nil error object)"
        }
    end

    -- Default to server error unless we determine otherwise
    local error_type = output.ERROR_TYPE.SERVER_ERROR

    -- Special cases for common error types based on status code
    if err.status_code == 401 then
        error_type = output.ERROR_TYPE.AUTHENTICATION
    elseif err.status_code == 404 then
        error_type = output.ERROR_TYPE.MODEL_ERROR
    elseif err.status_code == 429 then
        error_type = output.ERROR_TYPE.RATE_LIMIT
    elseif err.status_code >= 500 then
        error_type = output.ERROR_TYPE.SERVER_ERROR
    end

    -- Check for field validation errors (400 errors)
    if err.status_code == 400 then
        error_type = output.ERROR_TYPE.INVALID_REQUEST
    end

    -- Special cases based on error message content
    if err.message then
        -- Check for model errors (expanded patterns)
        if (err.message:match("model") and
                (err.message:match("does not exist") or
                    err.message:match("not found") or
                    err.message:match("access"))) then
            error_type = output.ERROR_TYPE.MODEL_ERROR
        end

        -- Check for context length errors
        if err.message:match("context length") or
            err.message:match("maximum.+tokens") or
            err.message:match("too long") or
            err.message:match("token limit") or
            err.message:match("resulted in %d+ tokens") then
            error_type = output.ERROR_TYPE.CONTEXT_LENGTH
        end

        -- Check for content filter errors
        if err.message:match("content policy") or
            err.message:match("content filter") or
            err.message:match("violates") then
            error_type = output.ERROR_TYPE.CONTENT_FILTER
        end

        -- Check for extended thinking not supported
        if err.message:match("thinking.+not supported") or
            err.message:match("not.+support.+thinking") then
            error_type = output.ERROR_TYPE.INVALID_REQUEST
        end
    end

    -- Return in the format expected by the text generation handler
    return {
        error = error_type,
        error_message = err.message or "Unknown Claude API error"
    }
end

-- Extract token usage information from Claude response
function mapper.extract_usage(response)
    if not response or not response.usage then
        return nil
    end

    local tokens = output.usage(
        response.usage.input_tokens or 0,
        response.usage.output_tokens or 0,
        0, -- Claude doesn't return thinking tokens separately
        response.usage.cache_creation_input_tokens or 0,
        response.usage.cache_read_input_tokens or 0
    )

    -- Ensure the cache tokens are directly accessible in the result
    if response.usage.cache_creation_input_tokens and response.usage.cache_creation_input_tokens > 0 then
        tokens.cache_creation_input_tokens = response.usage.cache_creation_input_tokens
    end

    if response.usage.cache_read_input_tokens and response.usage.cache_read_input_tokens > 0 then
        tokens.cache_read_input_tokens = response.usage.cache_read_input_tokens
    end

    return tokens
end

-- Helper function to check if a model supports thinking
function mapper.model_supports_thinking(model)
    -- Currently, only Claude 3.7 models support extended thinking
    if not model then
        return false
    end

    return model:match("claude%-3%-7") or model:match("claude%-3%.7")
end

-- Process Claude messages for standardized format
function mapper.process_messages(messages)
    local processed_messages = {}
    local system_content = {}
    local developer_instructions = {}

    -- Track cache markers and their positions
    local cache_marker_positions = {}
    local current_marker_idx = 1
    local has_cache_markers = false
    local has_system_content = false

    -- First pass: Process system messages and collect developer instructions
    for i, msg in ipairs(messages) do
        if msg.role == prompt.ROLE.SYSTEM then
            has_system_content = true
            -- Handle system messages - add to system content
            if type(msg.content) == "string" then
                table.insert(system_content, {
                    type = prompt.CONTENT_TYPE.TEXT,
                    text = msg.content
                })
            else
                -- If content is an array, add each part
                for _, part in ipairs(msg.content) do
                    table.insert(system_content, part)
                end
            end

            -- Track this position for potential system cache markers
            current_marker_idx = #system_content
        elseif msg.role == "cache_marker" then
            -- Found a cache marker - record its position
            table.insert(cache_marker_positions, current_marker_idx)
            has_cache_markers = true
            -- Don't add this to processed messages
        elseif msg.role == prompt.ROLE.DEVELOPER then
            -- Collect developer instruction content
            local dev_content
            if type(msg.content) == "string" then
                dev_content = msg.content
            else
                -- If content is an array, extract the text
                local text = ""
                for _, part in ipairs(msg.content) do
                    if part.type == prompt.CONTENT_TYPE.TEXT then
                        text = text .. part.text
                    end
                end
                dev_content = text
            end

            -- Find the previous non-developer, non-cache_marker message index
            local prev_msg_idx = i - 1
            while prev_msg_idx >= 1 do
                local prev_role = messages[prev_msg_idx].role
                if prev_role ~= prompt.ROLE.DEVELOPER and prev_role ~= "cache_marker" and prev_role ~= prompt.ROLE.SYSTEM then
                    -- Store developer instruction with the index of the previous message
                    if not developer_instructions[prev_msg_idx] then
                        developer_instructions[prev_msg_idx] = {}
                    end
                    table.insert(developer_instructions[prev_msg_idx], dev_content)
                    break
                end
                prev_msg_idx = prev_msg_idx - 1
            end
        elseif msg.role == prompt.ROLE.FUNCTION_RESULT then
            -- Handle function results - convert to Claude's tool_result format
            local function_name = msg.name
            local result_content = ""

            -- Extract content from function result
            if type(msg.content) == "string" then
                result_content = msg.content
            elseif type(msg.content) == "table" then
                if #msg.content > 0 and msg.content[1].type == prompt.CONTENT_TYPE.TEXT then
                    result_content = msg.content[1].text
                end
            end

            -- Create a user message with tool_result content block
            table.insert(processed_messages, {
                role = "user", -- Claude's format requires "user" role for tool result
                content = {
                    {
                        type = "tool_result",
                        tool_use_id = msg.function_call_id,
                        content = result_content
                    }
                }
            })

            -- Track position for message cache markers
            current_marker_idx = #processed_messages
        elseif msg.role == prompt.ROLE.FUNCTION_CALL then
            -- Handle function call messages as assistant with tool_use format
            local function_name = msg.function_call.name
            local arguments = msg.function_call.arguments
            local function_id = msg.function_call.id

            -- Convert arguments from string to object if needed
            if type(arguments) == "string" then
                local success, parsed = pcall(json.decode, arguments)
                if success then
                    arguments = parsed
                end
            end

            -- Create an assistant message with tool_use content block
            table.insert(processed_messages, {
                role = "assistant", -- Claude's format requires "assistant" role for tool use
                content = {
                    {
                        type = "tool_use",
                        id = function_id,
                        name = function_name,
                        input = arguments
                    }
                }
            })

            -- Track position for message cache markers
            current_marker_idx = #processed_messages
        else
            -- Regular user or assistant message
            local role = msg.role
            local content

            -- Format content properly
            if type(msg.content) == "string" then
                content = { { type = prompt.CONTENT_TYPE.TEXT, text = msg.content } }
            else
                content = msg.content
            end

            -- Process content array for any function calls (if in assistant message)
            if role == prompt.ROLE.ASSISTANT and content then
                for j, part in ipairs(content) do
                    if part.type == "function_call" then
                        -- Get function call data
                        local function_name = part.name
                        local function_id = part.id
                        local arguments = part.arguments

                        -- Convert arguments to proper format if it's a string (JSON)
                        if type(arguments) == "string" then
                            local success, parsed = pcall(json.decode, arguments)
                            if success then
                                arguments = parsed
                            end
                        end

                        -- Replace with tool_use format
                        content[j] = {
                            type = "tool_use",
                            id = function_id,
                            name = function_name,
                            input = arguments
                        }
                    end
                end
            end

            -- Add to processed messages
            table.insert(processed_messages, {
                role = role,
                content = content
            })

            -- Track position for potential message cache markers
            current_marker_idx = #processed_messages
        end
    end

    -- Second pass: Apply developer instructions to messages
    for i, msg in ipairs(messages) do
        if developer_instructions[i] and #developer_instructions[i] > 0 then
            -- Get the corresponding processed message index
            local processed_idx = 0
            local cur_reg_msg = 0

            -- Count regular messages up to this index to find the processed message
            for j = 1, i do
                if messages[j].role ~= prompt.ROLE.DEVELOPER and messages[j].role ~= "cache_marker" and messages[j].role ~= prompt.ROLE.SYSTEM then
                    cur_reg_msg = cur_reg_msg + 1
                end

                if j == i then
                    processed_idx = cur_reg_msg
                    break
                end
            end

            if processed_idx > 0 and processed_idx <= #processed_messages then
                -- Get the last content block
                local last_content_idx = #processed_messages[processed_idx].content
                if last_content_idx > 0 then
                    local last_content = processed_messages[processed_idx].content[last_content_idx]

                    -- If it's a text block, append all the developer instructions
                    if last_content.type == prompt.CONTENT_TYPE.TEXT then
                        for _, instruction in ipairs(developer_instructions[i]) do
                            last_content.text = last_content.text ..
                                "\n<developer-instruction>" .. instruction .. "</developer-instruction>"
                        end
                    end
                end
            end
        end
    end

    -- Apply cache markers to system blocks at the recorded positions
    if has_cache_markers and #system_content > 0 then
        -- If we have specific positions, use them
        if #cache_marker_positions > 0 then
            -- We can have up to 4 cache markers, according to Claude documentation
            for i = 1, math.min(#cache_marker_positions, 4) do
                local pos = cache_marker_positions[i]
                -- Only apply if the position is valid for system content
                if pos > 0 and pos <= #system_content then
                    system_content[pos].cache_control = {
                        type = "ephemeral"
                    }
                end
            end
        end

        -- If no valid positions were applied (or no positions were specified),
        -- apply to the last system block as fallback
        local applied = false
        for _, block in ipairs(system_content) do
            if block.cache_control then
                applied = true
                break
            end
        end

        if not applied and #system_content > 0 then
            system_content[#system_content].cache_control = {
                type = "ephemeral"
            }
        end
    end

    return {
        messages = processed_messages,
        system = #system_content > 0 and system_content or nil,
        has_system = has_system_content
    }
end

-- Extract content and tool calls from Claude response
function mapper.extract_response_content(response)
    if not response or not response.content then
        return nil
    end

    local content_text = ""
    local tool_calls = {}
    local thinking_content = ""
    local has_thinking = false

    for _, block in ipairs(response.content) do
        if block.type == prompt.CONTENT_TYPE.TEXT then
            content_text = content_text .. (block.text or "")
        elseif block.type == "tool_use" then
            -- Process tool use blocks
            local arguments = {}

            -- Parse the JSON input if available
            if block.input then
                arguments = block.input
            end

            -- Add to the tool calls list
            table.insert(tool_calls, {
                id = block.id or "",
                name = block.name or "",
                arguments = arguments
            })
        elseif block.type == "thinking" or block.type == "redacted_thinking" then
            -- Store thinking content
            if block.type == "thinking" then
                thinking_content = thinking_content .. (block.thinking or "")
            end
            has_thinking = true
        end
    end

    return {
        content = content_text,
        tool_calls = #tool_calls > 0 and tool_calls or nil,
        thinking = has_thinking and thinking_content or nil,
        has_thinking = has_thinking
    }
end

-- Map tool choice for Claude API based on tool_call setting
function mapper.map_tool_choice(tool_call, tools)
    if not tools or #tools == 0 then
        return nil
    end

    if tool_call == "none" then
        return { type = "none" }
    elseif tool_call == "auto" or not tool_call then
        return { type = "auto" }
    elseif type(tool_call) == "string" and tool_call ~= "auto" and tool_call ~= "none" then
        -- A specific tool name was provided
        -- Check if specified tool exists
        for _, tool in ipairs(tools) do
            if tool.name == tool_call then
                return {
                    type = "tool",
                    name = tool_call
                }
            end
        end

        -- Not found
        return nil, "Specified tool '" .. tool_call .. "' not found in available tools"
    end

    return nil
end

-- Format standardized response for text generation
function mapper.format_text_response(content, model, tokens, finish_reason, metadata, thinking_content)
    local result = {
        result = content,
        tokens = tokens,
        metadata = metadata,
        finish_reason = finish_reason,
        provider = "anthropic",
        model = model
    }

    -- Add thinking if it was included
    if thinking_content then
        result.thinking = thinking_content
    end

    return result
end

-- Format standardized response for tool calls
function mapper.format_tool_response(content_text, tool_calls, model, tokens, metadata, thinking_content)
    local result = {
        result = {
            content = content_text,
            tool_calls = tool_calls
        },
        tokens = tokens,
        metadata = metadata,
        finish_reason = output.FINISH_REASON.TOOL_CALL,
        provider = "anthropic",
        model = model
    }

    -- Add thinking if it was included
    if thinking_content then
        result.thinking = thinking_content
    end

    return result
end

-- Calculate thinking budget based on thinking effort (0-100)
function mapper.calculate_thinking_budget(effort)
    if not effort or effort <= 0 then
        return 0 -- No thinking
    end

    -- Constants for thinking budget
    local MIN_THINKING_BUDGET = 1024
    local MAX_THINKING_BUDGET = 24000

    -- Scale the thinking budget linearly from minimum to maximum
    local scaled_budget = MIN_THINKING_BUDGET + (MAX_THINKING_BUDGET - MIN_THINKING_BUDGET) * (effort / 100)

    -- Round to the nearest integer
    return math.floor(scaled_budget + 0.5)
end

-- Prepare request payload with thinking configuration
function mapper.configure_thinking(payload, model, options)
    if not options.thinking_effort or options.thinking_effort <= 0 then
        return payload
    end

    if not mapper.model_supports_thinking(model) then
        return payload
    end

    -- Calculate thinking budget based on thinking effort
    local thinking_budget = mapper.calculate_thinking_budget(options.thinking_effort)

    if thinking_budget > 0 then
        -- Ensure max_tokens is greater than thinking budget
        if not payload.max_tokens or payload.max_tokens <= thinking_budget then
            -- Set max_tokens to thinking budget + 1000 tokens as a reasonable buffer
            payload.max_tokens = thinking_budget + 1024
        end

        -- Add thinking configuration
        payload.thinking = {
            type = "enabled",
            budget_tokens = thinking_budget
        }

        -- Set temperature to 1 when thinking is enabled (REQUIRED by Claude API)
        payload.temperature = 1
    end

    return payload
end

return mapper
