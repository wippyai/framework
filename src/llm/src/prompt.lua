-- Prompt Library - Universal abstract prompt builder for LLM messages
-- Focuses only on building a universal internal message format with support for various content types

local json = require("json")

type ImageSource = {
    type: string,
    url: string?,
    mime_type: string?,
    data: string?,
}

type ContentPart = {
    type: string,
    text: string?,
    source: ImageSource?,
}

type FunctionCallOptions = {
    provider_metadata: table?,
}

type FunctionResultOptions = {
    is_error: boolean?,
}

type FunctionCall = {
    name: string,
    arguments: string,
    id: string?,
    provider_metadata: table?,
}

type Message = {
    role: string,
    content: {ContentPart}?,
    name: string?,
    metadata: table?,
    function_call: FunctionCall?,
    function_call_id: string?,
    is_error: boolean?,
    marker_id: string?,
}

type PromptBuilder = {
    messages: {Message},
    add_system: (self: any, content: string, meta: table?) -> PromptBuilder,
    add_user: (self: any, content: string, meta: table?) -> PromptBuilder,
    add_assistant: (self: any, content: string, meta: table?) -> PromptBuilder,
    add_developer: (self: any, content: string, meta: table?) -> PromptBuilder,
    add_message: (self: any, role: string, content_parts: {ContentPart}, name: string?, metadata: table?) -> PromptBuilder,
    add_function_call: (self: any, function_name: string, arguments: string, function_call_id: string?, options: FunctionCallOptions?) -> PromptBuilder,
    add_function_result: (self: any, name: string, content: any, function_call_id: string?, options: FunctionResultOptions?) -> PromptBuilder,
    add_cache_marker: (self: any, marker_id: string?) -> PromptBuilder,
    drop_stale_thinking: (self: any, is_current: (msg: Message) -> boolean) -> (PromptBuilder?, string?),
    get_messages: (self: any) -> {Message},
    build: (self: any) -> {messages: {Message}},
    clone: (self: any) -> PromptBuilder,
    clear: (self: any) -> PromptBuilder,
}

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
    IMAGE = "image",
    DOCUMENT = "document"
}

---------------------------
-- Content Part Constructors
---------------------------

-- Create a text content part
function prompt.text(content: string): ContentPart
    return {
        type = prompt.CONTENT_TYPE.TEXT,
        text = content
    }
end

-- Create an image content part from URL
function prompt.image(url: string, mime_type: string?): ContentPart
    return {
        type = prompt.CONTENT_TYPE.IMAGE,
        source = {
            type = "url",
            url = url,
            mime_type = mime_type
        }
    }
end

-- Create an image content part from base64 data
function prompt.image_base64(mime_type: string, data: string): ContentPart
    return {
        type = prompt.CONTENT_TYPE.IMAGE,
        source = {
            type = "base64",
            mime_type = mime_type,
            data = data
        }
    }
end

-- Create a document content part from base64 data (PDF, etc.)
-- Works with both Anthropic direct API and AWS Bedrock Converse API.
function prompt.document_base64(mime_type: string, data: string): ContentPart
    return {
        type = prompt.CONTENT_TYPE.DOCUMENT,
        source = {
            type = "base64",
            mime_type = mime_type,
            data = data
        }
    }
end

-- A positional note is a system or developer message marked with
-- metadata.preserve_position. Drivers render it at its conversation position
-- instead of folding it into the top-level instructions.
function prompt.is_positional_note(msg: Message): boolean
    return (msg.role == prompt.ROLE.SYSTEM or msg.role == prompt.ROLE.DEVELOPER)
        and type(msg.metadata) == "table" and msg.metadata.preserve_position == true
end

-- Text of a developer message as drivers without a developer role render it
-- inside a user turn, so the model can tell host guidance from user prose.
function prompt.developer_instruction(text: string): string
    return "<developer-instruction>" .. text .. "</developer-instruction>"
end

---------------------------
-- Helper Functions
---------------------------

-- Process function result content to extract images and clean text
local function process_function_result_content(content: any): (any, {ContentPart}?)
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
function prompt.new(messages: {Message}?)
    local builder = {
        messages = messages or {}
    }

    -- Add a developer message with contextual tips and optional meta
    builder.add_developer = function(self: any, content: string, meta: table?)
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
    builder.add_message = function(self: any, role: string, content_parts: {ContentPart}, name: string?, metadata: table?)
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
                (not metadata or metadata.preserve_position ~= true) and
                (not last_msg.metadata or last_msg.metadata.preserve_position ~= true) then
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
                local message: Message = {
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
    builder.add_system = function(self: any, content: string, meta: table?)
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
    builder.add_user = function(self: any, content: string, meta: table?)
        return self:add_message(
            prompt.ROLE.USER,
            { prompt.text(content) },
            nil,
            meta
        )
    end

    -- Add an assistant message with text content and optional meta
    builder.add_assistant = function(self: any, content: string, meta: table?)
        return self:add_message(
            prompt.ROLE.ASSISTANT,
            { prompt.text(content) },
            nil,
            meta
        )
    end

    -- Add a function call by assistant
    builder.add_function_call = function(self: any, function_name: string, arguments: string, function_call_id: string?, options: FunctionCallOptions?)
        if function_name and arguments then
            local message: Message = {
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

            if options and options.provider_metadata then
                message.function_call.provider_metadata = options.provider_metadata
            end

            table.insert(self.messages, message)
        end
        return self
    end

    -- Add a function result message
    builder.add_function_result = function(self: any, name: string, content: any, function_call_id: string?, options: FunctionResultOptions?)
        if name and content then
            local message: Message = {
                role = prompt.ROLE.FUNCTION_RESULT,
                name = name,
                content = { prompt.text(content) }
            }

            if function_call_id then
                message.function_call_id = function_call_id
            end
            if options and options.is_error == true then message.is_error = true end

            table.insert(self.messages, message)
        end
        return self
    end

    -- Add a cache marker message (special message that can be interpreted by provider adapters)
    builder.add_cache_marker = function(self: any, marker_id: string?)
        -- Add a simple marker message that can be recognized by adapter layers
        local message: Message = {
            role = prompt.ROLE.CACHE_MARKER,
            marker_id = marker_id or "default"
        }
        table.insert(self.messages, message)
        return self
    end

    -- Remove thinking blocks the current request can no longer replay.
    -- Providers bind each block to the exact prefix before it and chain it to
    -- the previous block, so blocks may be dropped only from the front: every
    -- block up to the last stale one goes. An assistant turn (a run of
    -- assistant and function call messages) whose calls still await results
    -- keeps its blocks, because the provider needs them to continue the round.
    builder.drop_stale_thinking = function(self: any, is_current: (msg: Message) -> boolean): (PromptBuilder?, string?)
        local messages: {Message} = self.messages :: {Message}
        local resolved: {[string]: boolean} = {}
        for _, msg in ipairs(messages) do
            if msg.role == prompt.ROLE.FUNCTION_RESULT and msg.function_call_id then
                resolved[msg.function_call_id] = true
            end
        end

        local function in_turn(msg: Message): boolean
            return msg.role == prompt.ROLE.ASSISTANT or msg.role == prompt.ROLE.FUNCTION_CALL
        end

        local function carries(msg: Message): boolean
            if not in_turn(msg) or type(msg.metadata) ~= "table" then return false end
            local blocks = msg.metadata.thinking_blocks
            return type(blocks) == "table" and #blocks > 0
        end

        -- First unanswered call of each assistant turn, keyed by message index.
        local open_call: {[integer]: string} = {}
        local turn_start: integer? = nil
        for index, msg in ipairs(messages) do
            if in_turn(msg) then
                turn_start = turn_start or index
            else
                turn_start = nil
            end
            if turn_start then
                local ids: {any} = {}
                if msg.role == prompt.ROLE.FUNCTION_CALL then
                    table.insert(ids, {
                        id = msg.function_call and msg.function_call.id or false,
                        name = msg.function_call and msg.function_call.name,
                    })
                else
                    for _, part in ipairs(msg.content or {}) do
                        if (part :: any).type == "function_call" then
                            table.insert(ids, { id = (part :: any).id or false, name = (part :: any).name })
                        end
                    end
                end
                for _, call in ipairs(ids) do
                    if not open_call[turn_start] and not (call.id and resolved[call.id]) then
                        open_call[turn_start] = string.format("%s (%s)",
                            call.id and tostring(call.id) or "without id", tostring(call.name or "unnamed"))
                    end
                end
            end
        end

        -- The current round is the last assistant turn when no user message
        -- follows it: the request continues that round, and the provider
        -- requires the final assistant turn to keep its thinking. Its blocks
        -- are never stripped here; a provider that can drop mismatched blocks
        -- handles them.
        local current_round = #messages + 1
        for index = #messages, 1, -1 do
            local role = messages[index].role
            if role == prompt.ROLE.USER then
                break
            end
            if in_turn(messages[index]) then
                current_round = index
            elseif current_round <= #messages then
                break
            end
        end

        local last_stale: integer? = nil
        for index = 1, current_round - 1 do
            local msg = messages[index]
            if carries(msg) and not is_current(msg) then
                last_stale = index
            end
        end
        if not last_stale then
            return self, nil
        end

        local stale: {integer} = {}
        turn_start = nil
        for index = 1, last_stale do
            local msg = messages[index]
            if in_turn(msg) then
                turn_start = turn_start or index
            else
                turn_start = nil
            end
            if carries(msg) then
                local open = turn_start and open_call[turn_start]
                if open then
                    return nil, string.format(
                        "thinking blocks of message %d must stay: its turn has open tool call %s", index, open)
                end
                table.insert(stale, index)
            end
        end

        -- Stripped messages are replaced by copies, so message tables the
        -- caller shares with the builder keep their blocks.
        for _, index in ipairs(stale) do
            local copy: Message = {} :: Message
            for key, value in pairs(messages[index] :: table) do
                (copy :: any)[key] = value
            end
            local metadata = {}
            for key, value in pairs(messages[index].metadata :: table) do
                if key ~= "thinking_blocks" then metadata[key] = value end
            end
            copy.metadata = metadata
            messages[index] = copy
        end
        return self, nil
    end

    -- Get all messages in the current builder (with image processing)
    builder.get_messages = function(self: any): {Message}
        local processed_messages: {Message} = {}
        local collected_images: {ContentPart} = {}
        local existing_messages: {Message} = self.messages :: {Message}

        for i, msg in ipairs(existing_messages) do
            if msg.role == prompt.ROLE.FUNCTION_RESULT then
                -- Process function result for images
                local original_content = msg.content

                -- Handle legacy format where content was already wrapped in prompt.text()
                if type(original_content) == "table" and #original_content > 0 and original_content[1].text then
                    original_content = original_content[1].text
                end

                local cleaned_content, images = process_function_result_content(original_content)

                -- Create processed message with cleaned content
                local processed_msg: Message = {
                    role = msg.role,
                    name = msg.name,
                    is_error = msg.is_error,
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
                local next_msg = existing_messages[i + 1]
                local should_insert = not next_msg or
                    (next_msg.role ~= prompt.ROLE.FUNCTION_CALL and next_msg.role ~= prompt.ROLE.FUNCTION_RESULT)

                if should_insert then
                    -- Create new user message with all collected images
                    local image_msg: Message = {
                        role = prompt.ROLE.USER,
                        content = collected_images
                    }
                    table.insert(processed_messages, image_msg)

                    -- Clear collected images for next cluster
                    collected_images = {}
                end
            end
        end

        return processed_messages
    end

    -- Clear all messages
    builder.clear = function(self: any)
        self.messages = {}
        return self
    end

    -- Build the prompt in universal format
    builder.build = function(self: any)
        return {
            messages = self:get_messages()
        }
    end

    -- Clone this builder (for creating variations)
    builder.clone = function(self: any)
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
            if msg.is_error ~= nil then new_msg.is_error = msg.is_error end

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
function prompt.with_system(system_content: string)
    local builder = prompt.new()
    if system_content and #system_content > 0 then
        (builder :: any):add_system(system_content)
    end
    return builder
end

return prompt
