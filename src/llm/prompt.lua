-- Prompt Library - Universal abstract prompt builder for LLM messages
-- Focuses only on building a universal internal message format with support for various content types

-- Main module
local prompt = {}

---------------------------
-- Constants
---------------------------

-- Message roles that are universally supported
prompt.ROLE = {
    SYSTEM = "system",
    USER = "user",
    ASSISTANT = "assistant",
    DEVELOPER = "developer",
    FUNCTION_CALL = "function_call",
    FUNCTION_RESULT = "function_result"
}

-- Content types
prompt.CONTENT_TYPE = {
    TEXT = "text",
    IMAGE = "image"
}

---------------------------
-- Content Part Constructors
---------------------------

-- Create a text content part
function prompt.text(content)
    return {
        type = prompt.CONTENT_TYPE.TEXT,
        text = content
    }
end

-- Create an image content part
function prompt.image(url, alt_text, mime_type)
    local image_part = {
        type = prompt.CONTENT_TYPE.IMAGE,
        source = {
            type = "url",
            url = url
        }
    }

    if alt_text then
        image_part.alt = alt_text
    end

    if mime_type then
        image_part.mime_type = mime_type
    end

    return image_part
end

---------------------------
-- Core Message Builder
---------------------------

-- Create a new prompt builder instance, optionally with starting messages
function prompt.new(messages)
    local builder = {
        messages = messages or {}
    }

    -- Add a developer message with contextual tips
    builder.add_developer = function(self, content)
        if content and #content > 0 then
            return self:add_message(
                prompt.ROLE.DEVELOPER,
                { prompt.text(content) }
            )
        end
        return self
    end

    -- Add a message with specified role and content parts
    builder.add_message = function(self, role, content_parts, name, meta)
        if role and content_parts and #content_parts > 0 then
            local mergeable_roles = {
                [prompt.ROLE.USER] = true,
                [prompt.ROLE.SYSTEM] = true,
                [prompt.ROLE.ASSISTANT] = true,
                [prompt.ROLE.DEVELOPER] = true
            }

            -- Check if we can merge with the last message
            local last_msg = self.messages[#self.messages]
            if last_msg and mergeable_roles[role] and last_msg.role == role and
                (not name or name == last_msg.name) then
                -- Same mergeable role, merge content
                for _, part in ipairs(content_parts) do
                    -- For text content, merge with previous text content if present
                    if part.type == prompt.CONTENT_TYPE.TEXT and
                        last_msg.content[#last_msg.content] and
                        last_msg.content[#last_msg.content].type == prompt.CONTENT_TYPE.TEXT then
                        -- Merge text with newline separator
                        last_msg.content[#last_msg.content].text =
                            last_msg.content[#last_msg.content].text .. "\n\n" .. part.text
                    else
                        -- Add as new content part
                        table.insert(last_msg.content, part)
                    end
                end
            else
                -- Create new message
                local message = {
                    role = role,
                    content = content_parts,
                    meta = meta
                }

                if name then
                    message.name = name
                end

                table.insert(self.messages, message)
            end
        end
        return self
    end

    -- Add a system message with text content
    builder.add_system = function(self, content)
        if content and #content > 0 then
            return self:add_message(
                prompt.ROLE.SYSTEM,
                { prompt.text(content) }
            )
        end
        return self
    end

    -- Add a user message with text content
    builder.add_user = function(self, content)
        if content and #content > 0 then
            return self:add_message(
                prompt.ROLE.USER,
                { prompt.text(content) }
            )
        end
        return self
    end

    -- Add an assistant message with text content
    builder.add_assistant = function(self, content, meta)
        if content and #content > 0 then
            return self:add_message(
                prompt.ROLE.ASSISTANT,
                { prompt.text(content) },
                nil,
                meta
            )
        end
        return self
    end

    -- Add a function call by assistant
    builder.add_function_call = function(self, function_name, arguments, function_call_id)
        if function_name and arguments then
            local message = {
                role = prompt.ROLE.FUNCTION_CALL,
                content = {}, -- Empty content when there's a function call
                function_call = {
                    name = function_name,
                    arguments = arguments
                }
            }

            if function_call_id then
                message.function_call.id = function_call_id
            end

            table.insert(self.messages, message)
        end
        return self
    end

    -- Add a function result message
    builder.add_function_result = function(self, name, content, function_call_id)
        if name and content then
            local message = {
                role = prompt.ROLE.FUNCTION_RESULT,
                name = name,
                content = { prompt.text(content) }
            }

            if function_call_id then
                message.function_call_id = function_call_id
            end

            table.insert(self.messages, message)
        end
        return self
    end

    -- Add a cache marker message (special message that can be interpreted by provider adapters)
    builder.add_cache_marker = function(self, marker_id)
        -- Add a simple marker message that can be recognized by adapter layers
        table.insert(self.messages, {
            role = "cache_marker",
            marker_id = marker_id or "default"
        })
        return self
    end

    -- Get all messages in the current builder
    builder.get_messages = function(self)
        return self.messages
    end

    -- Clear all messages
    builder.clear = function(self)
        self.messages = {}
        return self
    end

    -- Build the prompt in universal format
    builder.build = function(self)
        return {
            messages = self.messages
        }
    end

    -- Clone this builder (for creating variations)
    builder.clone = function(self)
        local new_builder = prompt.new()

        -- Deep copy all messages
        for _, msg in ipairs(self.messages) do
            local new_msg = {
                role = msg.role
            }

            -- Copy simple fields
            if msg.name then new_msg.name = msg.name end
            if msg.marker_id then new_msg.marker_id = msg.marker_id end
            if msg.function_call_id then new_msg.function_call_id = msg.function_call_id end

            -- Copy function call if present
            if msg.function_call then
                new_msg.function_call = {}
                for k, v in pairs(msg.function_call) do
                    new_msg.function_call[k] = v
                end
            end

            -- Copy content if present
            if msg.content then
                new_msg.content = {}
                for _, part in ipairs(msg.content) do
                    local new_part = {}
                    for k, v in pairs(part) do
                        if type(v) == "table" then
                            new_part[k] = {}
                            for k2, v2 in pairs(v) do
                                new_part[k][k2] = v2
                            end
                        else
                            new_part[k] = v
                        end
                    end
                    table.insert(new_msg.content, new_part)
                end
            end

            table.insert(new_builder.messages, new_msg)
        end

        return new_builder
    end

    return builder
end

-- Helper to create a prompt builder with an initial system message
function prompt.with_system(system_content)
    local builder = prompt.new()
    if system_content and #system_content > 0 then
        builder:add_system(system_content)
    end
    return builder
end

-- Helper to create a conversation from a list of alternating user/assistant messages
function prompt.from_conversation(system_content, messages)
    local builder = prompt.new()

    -- Add system message if provided
    if system_content and #system_content > 0 then
        builder:add_system(system_content)
    end

    -- Add conversation messages
    if messages and #messages > 0 then
        for i, message in ipairs(messages) do
            -- Even indices are user messages, odd are assistant
            if i % 2 == 1 then
                builder:add_user(message)
            else
                builder:add_assistant(message)
            end
        end
    end

    return builder
end

-- Calculate the string size of the prompt in bytes
function prompt.calculate_size(messages)
    local json = require("json")

    -- Use messages array if provided, or empty array
    local msgs = messages or {}

    -- Convert to JSON string to get a consistent size measurement
    local json_str = json.encode(msgs)

    -- Return the length in bytes
    return #json_str
end

return prompt
