local json = require("json")
local output = require("output")

local mapper = {}

-- Remove elements that are not supported by Google
local function filter_tool_schema(schema)
    local function recursive_filter(obj)
        if type(obj) ~= "table" then
            return obj
        end

        obj.multipleOf = nil

        for key, value in pairs(obj) do
            if type(value) == "table" then
                obj[key] = recursive_filter(value)
            end
        end

        return obj
    end

    schema.examples = nil

    return recursive_filter(schema)
end

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

local function convert_image_content(content_part)
    if content_part.type == "image" and content_part.source then
        if content_part.source.type == "url" then
            return {
                fileData = {
                    mimeType = "",
                    fileUri = content_part.source.url
                }
            }
        elseif content_part.source.type == "base64" and content_part.source.mime_type and content_part.source.data then
            return {
                inlineData = {
                    mimeType = content_part.source.mime_type,
                    data = content_part.source.data
                }
            }
        end
    end
    return content_part
end

local function normalize_content(content)
    -- Handle empty/nil content
    if content == "" or content == nil then
        return { { text = "" } }
    end

    -- Handle string content
    if type(content) == "string" then
        return { { text = content } }
    end

    -- Handle array content
    if type(content) == "table" then
        local processed_content = {}
        for i, part in ipairs(content) do
            if part.type == "text" then
                local text_content = part.text
                while type(text_content) == "table" and text_content.text do
                    text_content = text_content.text
                end

                local text_part = {
                    text = tostring(text_content or "")
                }

                processed_content[i] = text_part
            else
                processed_content[i] = convert_image_content(part)
            end
        end
        return processed_content
    end

    return content
end

function mapper.map_messages(contract_messages, options)
    options = options or {}
    local processed_messages = {}
    local system_instructions = {}
    local i = 1

    while i <= #contract_messages do
        local msg = contract_messages[i]
        msg.metadata = nil

        if msg.role == "developer" or msg.role == "system" then
            table.insert(system_instructions, { text = mapper.standardize_content(msg.content) })
            i = i + 1
        elseif msg.role == "user" then
            table.insert(processed_messages, { role = "user", parts = normalize_content(msg.content) })
            i = i + 1
        elseif msg.role == "assistant" then
            local assistant_msg = mapper.standardize_content(msg.content)
            if assistant_msg ~= "" then
                table.insert(processed_messages, { role = "model", parts = { text = assistant_msg } })
            end

            i = i + 1
        elseif msg.role == "function_result" then
            local tool_content = nil

            if type(msg.content) == "table" then
                -- If it's an array containing a text part, extract the text
                if #msg.content == 1 and msg.content[1].type == "text" then
                    tool_content = msg.content[1].text
                else
                 -- Otherwise assume the table IS the structured content the function returned
                 tool_content = msg.content
                end
            elseif type(msg.content) == "string" then
                 local decoded, decode_err = json.decode(msg.content)
                 if not decode_err then
                    tool_content = decoded -- Use decoded table/value
                 else
                    -- If not valid JSON, pass the raw string as content
                    tool_content = msg.content
                 end
            elseif msg.content ~= nil then
                -- Handle other non-nil types (boolean, number)
                 tool_content = msg.content
            else
                 -- Default to empty object or string if content is nil
                 tool_content = ""
            end

            table.insert(processed_messages, {
                role = "user",
                parts = {
                    {
                        functionResponse = {
                            name = msg.name,
                            response = {
                                name = msg.name,
                                content = tool_content
                            }
                        }
                    }
                }
            })
            i = i + 1
        elseif msg.role == "function_call" then
            local arguments = msg.function_call.arguments

            table.insert(processed_messages, { role = "model", parts = {
                functionCall = {
                    name = msg.function_call.name,
                    args = (type(arguments) == "string") and json.decode(arguments) or arguments
                }
            } })
            i = i + 1
        else
            -- Skip unknown message types
            i = i + 1
        end
    end
    return processed_messages, system_instructions
end

function mapper.map_tools(contract_tools)
    if not contract_tools or #contract_tools == 0 then
        return nil
    end

    local tools = {}

    for _, tool in ipairs(contract_tools) do
        if tool.name and tool.description and tool.schema then
            table.insert(tools, {
                name = tool.name,
                description = tool.description,
                parameters = filter_tool_schema(tool.schema)
            })
        end
    end

    return tools
end

function mapper.map_tool_config(contract_choice, available_tools)
    if not contract_choice or contract_choice == "auto" or contract_choice == "any" then
        return {mode = "AUTO"}, nil
    elseif contract_choice == "none" then
        return {mode = "NONE"}, nil
    elseif type(contract_choice) == "string" then
        -- Specific tool name - verify it exists
        for _, tool in ipairs(available_tools or {}) do
            if tool.name == contract_choice then
                return {
                    mode = "ANY",
                    allowedFunctionNames = { contract_choice }
                }, nil
            end
        end
        return nil, "Tool '" .. contract_choice .. "' not found in available tools"
    end

    return "AUTO", nil
end

function mapper.map_options(contract_options)
    if not contract_options then return {} end

    return {
        maxOutputTokens = contract_options.max_tokens,
        temperature = contract_options.temperature,
        stopSequences = contract_options.stop_sequences,
        topP = contract_options.top_p,
        seed = contract_options.seed,
        presencePenalty = contract_options.presence_penalty,
        frequencyPenalty = contract_options.frequency_penalty
    }
end

function mapper.map_tool_calls(function_calls)
    if not function_calls then
        return {}
    end

    local contract_tool_calls = {}
    for i, function_call in ipairs(function_calls) do
        contract_tool_calls[i] = {
            id = (function_call.name or "func") .. "_" .. os.time() .. "_" .. math.random(1000, 9999),
            name = function_call.name,
            arguments = function_call.args or {},
        }
    end

    return contract_tool_calls
end

function mapper.map_finish_reason(openai_finish_reason)
    local FINISH_REASON_MAP = {
        ["STOP"] = output.FINISH_REASON.STOP,
        ["MAX_TOKENS"] = output.FINISH_REASON.LENGTH,
        ["SAFETY"] = output.FINISH_REASON.CONTENT_FILTER,
        ["RECITATION"] = output.FINISH_REASON.CONTENT_FILTER,
        ["LANGUAGE"] = output.FINISH_REASON.CONTENT_FILTER,
        ["BLOCKLIST"] = output.FINISH_REASON.CONTENT_FILTER,
        ["PROHIBITED_CONTENT"] = output.FINISH_REASON.CONTENT_FILTER,
        ["SPII"] = output.FINISH_REASON.CONTENT_FILTER,
        ["IMAGE_SAFETY"] = output.FINISH_REASON.CONTENT_FILTER,
        ["MALFORMED_FUNCTION_CALL"] = output.FINISH_REASON.ERROR,
        ["OTHER"] = output.FINISH_REASON.ERROR
    }

    return FINISH_REASON_MAP[openai_finish_reason] or output.FINISH_REASON.ERROR
end

function mapper.map_tokens(google_usage)
    if not google_usage then
        return nil
    end

    local tokens = {
        prompt_tokens = google_usage.promptTokenCount or 0,
        completion_tokens = google_usage.candidatesTokenCount or 0,
        total_tokens = google_usage.totalTokenCount or 0,
        cache_write_tokens = 0,
        cache_read_tokens = 0,
        thinking_tokens = google_usage.thoughtsTokenCount
    }

    if google_usage.cachedContentTokenCount then
        tokens.cache_read_tokens = google_usage.cachedContentTokenCount
        tokens.cache_write_tokens = math.max(0, tokens.prompt_tokens - tokens.cache_read_tokens)
        tokens.prompt_tokens = tokens.prompt_tokens - tokens.cache_read_tokens
    end

    return tokens
end

function mapper.map_success_response(google_response)
    if not google_response or not google_response.candidates or #google_response.candidates == 0 then
        error("Invalid Google response structure")
    end

    local content = ""
    local candidate = google_response.candidates[1]

    local tool_calls = {}
    if candidate.content and candidate.content.parts then
        for _, content_part in ipairs(candidate.content.parts) do
            if content_part.text then
                content = content .. content_part.text
            elseif content_part.functionCall then
                table.insert(tool_calls, content_part.functionCall)
            end
        end
    end

    local response = {
        success = true,
        metadata = google_response.metadata or {}
    }
    if #tool_calls > 0 then
        response.result = {
            content = content,
            tool_calls = mapper.map_tool_calls(tool_calls)
        }
        response.finish_reason = output.FINISH_REASON.TOOL_CALL
    else
        response.result = {
            content = content,
            tool_calls = {}
        }
        response.finish_reason = mapper.map_finish_reason(candidate.finishReason or "UNKNOWN")
    end

    response.tokens = mapper.map_tokens(google_response.usageMetadata)

    return response
end

function mapper.map_error_response(google_error)
    if not google_error then
        return {
            success = false,
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "Unknown Google error",
            metadata = {}
        }
    end

    local error_message = google_error.message or "Google API error"
    local error_type = map_error_type(google_error.status_code, error_message)

    return {
        success = false,
        error = error_type,
        error_message = error_message,
        metadata = google_error.metadata or {}
    }
end

-- Standardize content to a simple string (for instructions)
function mapper.standardize_content(content)
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

return mapper
