-- prompt_mapper.lua
-- Converts internal prompt format to provider-specific formats

local json = require("json")
local prompt = require("prompt") -- Assuming 'prompt.lua' contains your prompt builder definitions

-- Prompt Mapper - Converts internal prompt format to provider-specific formats
local prompt_mapper = {}

-- Helper to extract text content from a message part or string
local function extract_text_content(content)
    if type(content) == "string" then
        return content
    elseif type(content) == "table" then
        local text_parts = {}
        for _, part in ipairs(content) do
            -- Ensure part has 'type' and 'text' fields before accessing
            if part and part.type == prompt.CONTENT_TYPE.TEXT and part.text then
                table.insert(text_parts, part.text)
            end
        end
        return table.concat(text_parts, "\n\n") -- Combine text parts with newlines
    end
    return ""
end

-- Map internal messages to Vertex AI API format
-- Returns TWO values:
-- 1. contents (table): The array for the 'contents' field in the Vertex payload.
-- 2. system_instruction (table or nil): The object for the 'systemInstruction' field, or nil if no system/developer messages.
function prompt_mapper.map_to_vertex(messages)
    local processed_messages = {} -- For the main 'contents' array (user, model turns)
    local system_instruction_parts = {} -- To collect parts for the 'systemInstruction' field

    if not messages then messages = {} end -- Handle nil messages table

    for _, msg in ipairs(messages) do
        if not msg or not msg.role then goto continue end -- Skip invalid messages

        if msg.role == prompt.ROLE.SYSTEM or msg.role == prompt.ROLE.DEVELOPER then
            -- Collect system/developer messages for the systemInstruction field
            local text = extract_text_content(msg.content)
            if text ~= "" then
                 -- Vertex systemInstruction expects parts, typically just one text part
                 -- We combine all system/dev messages into one text part later
                table.insert(system_instruction_parts, { text = text })
            end
            -- Do not add these to the main processed_messages array

        elseif msg.role == prompt.ROLE.USER then
            -- Handle user messages
            local user_parts = {}
            if type(msg.content) == "table" then
                for _, part in ipairs(msg.content) do
                    if part and part.type == prompt.CONTENT_TYPE.TEXT and part.text then
                        table.insert(user_parts, { text = part.text })
                    elseif part and part.type == prompt.CONTENT_TYPE.IMAGE then
                        if not part.mime_type or part.mime_type == "" then
                            error("Image content must have a mime_type for Vertex")
                        end
                         if not part.source or not part.source.url then
                             error("Image content must have a source.url for Vertex (GCS URI or Base64 data)")
                         end
                         -- Decide between inlineData (Base64) and fileData (GCS URI) based on URL format potentially
                         -- Assuming Base64 if URL starts with 'data:', otherwise GCS URI. A more robust check might be needed.
                         if type(part.source.url) == "string" and part.source.url:sub(1, 5) == "data:" then
                             -- Extract base64 data and correct mimeType if needed
                             local data_parts = {}
                             for s in part.source.url:gmatch("([^;,]+)") do table.insert(data_parts, s) end
                             local base64_data = data_parts[3] -- Assuming format data:<mimeType>;base64,<data>
                             local actual_mime_type = data_parts[1]:sub(6) -- Extract mimeType after 'data:'
                             if base64_data then
                                 table.insert(user_parts, {
                                     inlineData = {
                                         mimeType = actual_mime_type or part.mime_type, -- Prefer mime from data URI
                                         data = base64_data
                                     }
                                 })
                             else
                                 error("Could not parse base64 data from image source URL: " .. part.source.url)
                             end
                         else -- Assume GCS URI for fileData
                            table.insert(user_parts, {
                                fileData = {
                                    mimeType = part.mime_type,
                                    fileUri = part.source.url -- Assuming URL is a GCS URI
                                }
                            })
                         end
                    end -- end image part
                end -- end loop through parts
            elseif type(msg.content) == "string" and msg.content ~= "" then
                table.insert(user_parts, { text = msg.content })
            end
            -- Only add the user message if it has valid parts
            if #user_parts > 0 then
                table.insert(processed_messages, { role = "user", parts = user_parts })
            end

        elseif msg.role == prompt.ROLE.ASSISTANT then
            -- Handle assistant messages -> map to "model" role
             local text_content = extract_text_content(msg.content)
             if text_content ~= "" then
                table.insert(processed_messages, {
                    role = "model",
                    parts = { { text = text_content } }
                })
             end
             -- Note: This currently only extracts text from assistant messages.
             -- If an assistant message *contains* a tool_call structure internally (less common), it's not mapped here.
             -- The FUNCTION_CALL role is for when the *model's turn* IS a tool call request.

        elseif msg.role == prompt.ROLE.FUNCTION_CALL then
             if not msg.function_call or not msg.function_call.name then goto continue end -- Skip invalid function calls
            -- Handle model requesting a function call -> map to "model" role with functionCall part
            local args = nil
            -- Ensure arguments are passed as a table/object if possible
            if type(msg.function_call.arguments) == "table" then
                 -- Pass table directly (Vertex expects an object)
                 args = msg.function_call.arguments
                 -- Handle empty table? Vertex might prefer omitting `args` if empty.
                 -- Let's check if the table is actually empty (has no keys)
                 if not next(args) then args = nil end
            elseif type(msg.function_call.arguments) == "string" and msg.function_call.arguments ~= "" then
                 -- Attempt to decode if it's a non-empty JSON string
                 local decoded_args, decode_err = json.decode(msg.function_call.arguments)
                 if not decode_err then
                    args = decoded_args
                    if type(args) == "table" and not next(args) then args = nil end -- Handle decoded empty object
                 else
                    -- If decode fails, log a warning and pass nil. Vertex requires args to be a JSON object.
                    -- print("Warning: Could not decode function call arguments string for function '" .. msg.function_call.name .. "': " .. msg.function_call.arguments)
                    args = nil
                 end
             -- Else: arguments are neither table nor string, pass nil
            end

            table.insert(processed_messages, {
                role = "model", -- Function calls originate from the model
                parts = {
                    {
                        functionCall = {
                            name = msg.function_call.name,
                            args = args -- Use the processed args table (or nil)
                        }
                    }
                }
            })

        elseif msg.role == prompt.ROLE.FUNCTION_RESULT then
             if not msg.name then goto continue end -- Skip invalid function results (missing name)
            -- Handle function result provided by user -> map to "user" role with functionResponse part
            local response_content = {}
            -- Vertex expects response content to be structured { name: string, content: any }
            -- Let's try to pass structured content if the input `msg.content` is a table,
            -- otherwise decode from JSON string, falling back to raw string if decode fails.
            if type(msg.content) == "table" then
                -- If it's an array containing a text part, extract the text
                if #msg.content == 1 and msg.content[1].type == prompt.CONTENT_TYPE.TEXT then
                    response_content = msg.content[1].text
                else
                 -- Otherwise assume the table IS the structured content the function returned
                 response_content = msg.content
                end
            elseif type(msg.content) == "string" then
                 local decoded, decode_err = json.decode(msg.content)
                 if not decode_err then
                    response_content = decoded -- Use decoded table/value
                 else
                    -- If not valid JSON, pass the raw string as content
                    response_content = msg.content
                 end
            elseif msg.content ~= nil then
                -- Handle other non-nil types (boolean, number) by converting to string? Or pass directly?
                -- Vertex API likely expects string or JSON object/array/primitive for content.
                -- Passing directly might work for primitives. Let's try passing directly.
                 response_content = msg.content
            else
                 -- Default to empty object or string if content is nil? Let's use empty string.
                 response_content = ""
            end

            local tool_msg = {
                role = "user", -- Function results are provided *to* the model, from the user's perspective
                parts = {
                    {
                        functionResponse = {
                            name = msg.name, -- The name of the function that was called
                            response = {
                                -- The structure required by Vertex API: { name: string, content: any }
                                name = msg.name,
                                content = response_content
                            }
                        }
                    }
                }
            }
            table.insert(processed_messages, tool_msg)
        end
        ::continue:: -- Label for skipping invalid messages in the loop
    end -- end message loop

    -- Consolidate collected system parts into a single text part if needed
    local final_system_text = ""
    if #system_instruction_parts > 0 then
        local texts = {}
        for _, part in ipairs(system_instruction_parts) do
            table.insert(texts, part.text)
        end
        final_system_text = table.concat(texts, "\n\n") -- Join multiple system/dev messages
    end

    local system_instruction = nil
    if final_system_text ~= "" then
        system_instruction = {
            -- Vertex systemInstruction uses 'parts' array, just like 'contents'
            parts = { { text = final_system_text } }
        }
    end

    -- Return both the main contents array and the system instruction object
    return processed_messages, system_instruction
end

-- Add other mappers if needed (e.g., map_to_openai, map_to_claude)
-- function prompt_mapper.map_to_openai(messages, options) ... end
-- function prompt_mapper.map_to_claude(messages) ... end

return prompt_mapper