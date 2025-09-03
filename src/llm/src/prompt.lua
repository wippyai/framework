-- Prompt Library - Universal abstract prompt builder for LLM messages
-- Focuses only on building a universal internal message format with support for various content types

local json = require("json")

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
    FUNCTION_RESULT = "function_result",
    CACHE_MARKER = "cache_marker"
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

-- Create an image content part from URL
function prompt.image(url)
    return {
        type = prompt.CONTENT_TYPE.IMAGE,
        source = {
            type = "url",
            url = url
        }
    }
end

-- Create an image content part from base64 data
function prompt.image_base64(mime_type, data)
    return {
        type = prompt.CONTENT_TYPE.IMAGE,
        source = {
            type = "base64",
            mime_type = mime_type,
            data = data
        }
    }
end

---------------------------
-- Helper Functions
---------------------------

-- Process function result content to extract images and clean text
local function process_function_result_content(content)
    local parsed
    local was_string = false

    -- Handle both string and table content
    if type(content) == "string" then
        -- Only process strings that contain _images
        if not content:find('"_images"') then
            return content, nil
        end

        -- Try to parse as JSON
        local err
        parsed, err = json.decode(content)
        if err or type(parsed) ~= "table" or not parsed._images then
            return content, nil -- Return original if parsing fails or no _images
        end
        was_string = true
    elseif type(content) == "table" then
        -- Direct table content
        if not content._images then
            return content, nil
        end
        parsed = content
        was_string = false
    else
        return content, nil
    end

    -- Extract images
    local images = {}
    if type(parsed._images) == "table" then
        for _, img in ipairs(parsed._images) do
            if type(img) == "table" then
                -- Handle both URL format and universal format
                if img.url then
                    -- Old URL format for backward compatibility
                    table.insert(images, prompt.image(img.url))
                elseif img.type == "image" and img.source then
                    -- New universal format - use as-is
                    table.insert(images, img)
                end
            end
        end
    end

    -- Remove _images from the parsed data
    parsed._images = nil

    -- Add replacement text if we found images
    if #images > 0 then
        if parsed.result and type(parsed.result) == "string" then
            parsed.result = parsed.result .. " (see image results below)"
        end
    end

    -- Return in appropriate format
    local cleaned_content
    if was_string then
        cleaned_content = json.encode(parsed)
    else
        cleaned_content = parsed
    end

    return cleaned_content, images
end

---------------------------
-- Core Message Builder
---------------------------

-- Create a new prompt builder instance, optionally with starting messages
function prompt.new(messages)
    local builder = {
        messages = messages or {}
    }

    -- Add a developer message with contextual tips and optional meta
    builder.add_developer = function(self, content, meta)
        if content and #content > 0 then
            return self:add_message(
                prompt.ROLE.DEVELOPER,
                { prompt.text(content) },
                nil,
                meta
            )
        end
        return self
    end

    -- Add a message with specified role and content parts
    builder.add_message = function(self, role, content_parts, name, metadata)
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
                (not name or name == last_msg.name) and
                (not meta or not last_msg.metadat) then -- Don't merge if either has metadata
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
                    metadata = metadata
                }

                if name then
                    message.name = name
                end

                table.insert(self.messages, message)
            end
        end
        return self
    end

    -- Add a system message with text content and optional meta
    builder.add_system = function(self, content, meta)
        if content and #content > 0 then
            return self:add_message(
                prompt.ROLE.SYSTEM,
                { prompt.text(content) },
                nil,
                meta
            )
        end
        return self
    end

    -- Add a user message with text content and optional meta
    builder.add_user = function(self, content, meta)
        return self:add_message(
            prompt.ROLE.USER,
            { prompt.text(content) },
            nil,
            meta
        )
    end

    -- Add an assistant message with text content and optional meta
    builder.add_assistant = function(self, content, meta)
        return self:add_message(
            prompt.ROLE.ASSISTANT,
            { prompt.text(content) },
            nil,
            meta
        )
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
            role = prompt.ROLE.CACHE_MARKER,
            marker_id = marker_id or "default"
        })
        return self
    end

    -- Get all messages in the current builder (with image processing)
    builder.get_messages = function(self)
        local processed_messages = {}
        local collected_images = {}

        for i, msg in ipairs(self.messages) do
            if msg.role == prompt.ROLE.FUNCTION_RESULT then
                -- Process function result for images
                local original_content = msg.content

                -- Handle legacy format where content was already wrapped in prompt.text()
                if type(original_content) == "table" and #original_content > 0 and original_content[1].text then
                    original_content = original_content[1].text
                end

                local cleaned_content, images = process_function_result_content(original_content)

                -- Create processed message with cleaned content
                local processed_msg = {
                    role = msg.role,
                    name = msg.name,
                    content = { prompt.text(type(cleaned_content) == "table" and json.encode(cleaned_content) or cleaned_content) }
                }

                if msg.function_call_id then
                    processed_msg.function_call_id = msg.function_call_id
                end

                table.insert(processed_messages, processed_msg)

                -- Collect images if found
                if images then
                    for _, img in ipairs(images) do
                        table.insert(collected_images, img)
                    end
                end
            else
                -- Copy other messages as-is
                table.insert(processed_messages, msg)
            end

            -- Check if we need to insert collected images
            -- Insert when: we have images AND the next message is not a function_call/function_result (or we're at the end)
            if #collected_images > 0 then
                local next_msg = self.messages[i + 1]
                local should_insert = not next_msg or
                    (next_msg.role ~= prompt.ROLE.FUNCTION_CALL and next_msg.role ~= prompt.ROLE.FUNCTION_RESULT)

                if should_insert then
                    -- Create new user message with all collected images
                    table.insert(processed_messages, {
                        role = prompt.ROLE.USER,
                        content = collected_images
                    })

                    -- Clear collected images for next cluster
                    collected_images = {}
                end
            end
        end

        return processed_messages
    end

    -- Clear all messages
    builder.clear = function(self)
        self.messages = {}
        return self
    end

    -- Build the prompt in universal format
    builder.build = function(self)
        return {
            messages = self:get_messages()
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

            -- Copy meta if present
            if msg.metadata then
                new_msg.metadata = {}
                for k, v in pairs(msg.metadata) do
                    if type(v) == "table" then
                        new_msg.metadata[k] = {}
                        for k2, v2 in pairs(v) do
                            new_msg.metadata[k][k2] = v2
                        end
                    else
                        new_msg.metadata[k] = v
                    end
                end
            end

            -- Copy function call if present
            if msg.function_call then
                new_msg.function_call = {}
                for k, v in pairs(msg.function_call) do
                    new_msg.function_call[k] = v
                end
            end

            -- Copy content if present
            if msg.content then
                if type(msg.content) == "string" then
                    new_msg.content = msg.content
                else
                    new_msg.content = table.create(#msg.content, 0)
                    for _, part in ipairs(msg.content) do
                        if type(part) == "table" then
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

return prompt
