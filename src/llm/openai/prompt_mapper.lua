local json = require("json")

-- Prompt Mapper - Converts internal prompt format to provider-specific formats
local prompt_mapper = {}

-- Map internal messages to OpenAI API format
function prompt_mapper.map_to_openai(messages, options)
    options = options or {}
    local is_o1_mini = options.model and options.model:match("^o1%-mini") ~= nil

    local processed_messages = {}

    for _, msg in ipairs(messages) do
        msg.meta = nil

        -- Pass through standard OpenAI message types
        if msg.role == "user" or msg.role == "assistant" or msg.role == "system" then
            table.insert(processed_messages, msg)

            -- Convert function_call messages to assistant messages with tool_calls
        elseif msg.role == "function_call" then
            local assistant_msg = {
                role = "assistant",
                content = ""
            }

            -- Add tool_calls data
            if msg.function_call then
                assistant_msg.tool_calls = {
                    {
                        id = msg.function_call.id or "call_" .. tostring(os.time()),
                        type = "function",
                        ["function"] = {
                            name = msg.function_call.name,
                            arguments = (type(msg.function_call.arguments) == "table")
                                and json.encode(msg.function_call.arguments)
                                or tostring(msg.function_call.arguments)
                        }
                    }
                }
            end

            table.insert(processed_messages, assistant_msg)

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

            -- Handle developer messages specially for o1-mini
        elseif msg.role == "developer" and is_o1_mini then
            -- Convert developer message to user message with special formatting
            local content = ""
            if type(msg.content) == "string" then
                content = msg.content
            elseif type(msg.content) == "table" then
                -- Handle structured content
                for _, part in ipairs(msg.content) do
                    if part.type == "text" then
                        content = content .. part.text
                    end
                end
            end

            -- Find the previous user message to attach this instruction to
            local prev_user_idx = nil
            for i = #processed_messages, 1, -1 do
                if processed_messages[i].role == "user" then
                    prev_user_idx = i
                    break
                end
            end

            if prev_user_idx then
                -- Append to existing user message
                local user_msg = processed_messages[prev_user_idx]
                local new_content = ""

                if type(user_msg.content) == "string" then
                    new_content = user_msg.content .. "\n\nDeveloper instructions:\n" .. content
                    user_msg.content = new_content
                elseif type(user_msg.content) == "table" then
                    -- Find the last text part
                    local last_text_idx = nil
                    for i = #user_msg.content, 1, -1 do
                        if user_msg.content[i].type == "text" then
                            last_text_idx = i
                            break
                        end
                    end

                    if last_text_idx then
                        user_msg.content[last_text_idx].text = user_msg.content[last_text_idx].text ..
                            "\n\nDeveloper instructions:\n" .. content
                    else
                        -- No text part found, add one
                        table.insert(user_msg.content, {
                            type = "text",
                            text = "Developer instructions:\n" .. content
                        })
                    end
                end
            else
                -- Convert to system message as fallback
                table.insert(processed_messages, {
                    role = "system",
                    content = content
                })
            end

            -- For regular developer messages (non-o1-mini models)
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
        end
    end

    return processed_messages
end

-- Standardize content to a simple string
function prompt_mapper.standardize_content(content)
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

return prompt_mapper
