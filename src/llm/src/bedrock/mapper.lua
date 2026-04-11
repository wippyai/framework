local output = require("output")
local prompt = require("prompt")
local json = require("json")

local mapper = {}

-- Converse stopReason -> contract finish_reason
mapper.FINISH_REASON_MAP = {} :: {[string]: string}
mapper.FINISH_REASON_MAP["end_turn"] = output.FINISH_REASON.STOP
mapper.FINISH_REASON_MAP["max_tokens"] = output.FINISH_REASON.LENGTH
mapper.FINISH_REASON_MAP["stop_sequence"] = output.FINISH_REASON.STOP
mapper.FINISH_REASON_MAP["tool_use"] = output.FINISH_REASON.TOOL_CALL
mapper.FINISH_REASON_MAP["guardrail_intervened"] = output.FINISH_REASON.CONTENT_FILTER
mapper.FINISH_REASON_MAP["content_filtered"] = output.FINISH_REASON.CONTENT_FILTER

mapper.HTTP_STATUS_MAP = {} :: {[number]: string}
mapper.HTTP_STATUS_MAP[400] = output.ERROR_TYPE.INVALID_REQUEST
mapper.HTTP_STATUS_MAP[401] = output.ERROR_TYPE.AUTHENTICATION
mapper.HTTP_STATUS_MAP[403] = output.ERROR_TYPE.AUTHENTICATION
mapper.HTTP_STATUS_MAP[404] = output.ERROR_TYPE.MODEL_ERROR
mapper.HTTP_STATUS_MAP[413] = output.ERROR_TYPE.INVALID_REQUEST
mapper.HTTP_STATUS_MAP[429] = output.ERROR_TYPE.RATE_LIMIT
mapper.HTTP_STATUS_MAP[500] = output.ERROR_TYPE.SERVER_ERROR
mapper.HTTP_STATUS_MAP[502] = output.ERROR_TYPE.SERVER_ERROR
mapper.HTTP_STATUS_MAP[503] = output.ERROR_TYPE.SERVER_ERROR

local function approximate_token_count(text)
    if not text or text == "" then return 0 end
    return math.ceil(string.len(text) / 4)
end

function mapper.map_error_response(bedrock_error)
    if not bedrock_error then
        local response = {
            success = false,
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "Unknown error"
        }
        return response, output.to_structured_error(response)
    end

    local error_type = output.ERROR_TYPE.SERVER_ERROR
    local error_message = "Unknown Bedrock API error"

    if bedrock_error.status_code then
        error_type = mapper.HTTP_STATUS_MAP[bedrock_error.status_code] or output.ERROR_TYPE.SERVER_ERROR
    end
    if bedrock_error.message then
        error_message = bedrock_error.message
    end

    local response = {
        success = false,
        error = error_type,
        error_message = error_message,
        metadata = bedrock_error.metadata or {}
    }
    return response, output.to_structured_error(response)
end

function mapper.map_tokens(converse_usage)
    if not converse_usage then
        return nil
    end

    local tokens = output.usage(
        converse_usage.inputTokens or 0,
        converse_usage.outputTokens or 0,
        0,
        converse_usage.cacheWriteInputTokens or 0,
        converse_usage.cacheReadInputTokens or 0
    )

    tokens.cache_write_tokens = converse_usage.cacheWriteInputTokens or 0
    tokens.cache_read_tokens = converse_usage.cacheReadInputTokens or 0

    return tokens
end

function mapper.map_finish_reason(stop_reason)
    return mapper.FINISH_REASON_MAP[stop_reason] or stop_reason
end

local function convert_image_to_converse(content_part)
    if content_part.type == "image" and content_part.source then
        if content_part.source.type == "base64" then
            return {
                image = {
                    format = content_part.source.mime_type and content_part.source.mime_type:match("/(.+)") or "png",
                    source = {
                        bytes = content_part.source.data
                    }
                }
            }
        end
    end
    return nil
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

-- Map contract messages to Converse format
function mapper.map_messages(contract_messages)
    if not contract_messages or #contract_messages == 0 then
        return { messages = {}, system = nil }
    end

    local converse_messages = {}
    local system_blocks = {}

    for _, msg in ipairs(contract_messages) do
        if msg.role == prompt.ROLE.SYSTEM then
            if type(msg.content) == "string" then
                table.insert(system_blocks, { text = msg.content })
            elseif type(msg.content) == "table" then
                for _, part in ipairs(msg.content) do
                    if part.type == "text" then
                        table.insert(system_blocks, { text = part.text })
                    end
                end
            end
        elseif msg.role == "cache_marker" then
            -- Apply cachePoint to the last system block or last message content
            if #converse_messages == 0 and #system_blocks > 0 then
                table.insert(system_blocks, { cachePoint = { type = "default" } })
            elseif #converse_messages > 0 then
                local last_msg = converse_messages[#converse_messages]
                if last_msg.content and #last_msg.content > 0 then
                    table.insert(last_msg.content, { cachePoint = { type = "default" } })
                end
            end
        elseif msg.role == prompt.ROLE.DEVELOPER then
            local dev_text = type(msg.content) == "string" and msg.content or
                (type(msg.content) == "table" and msg.content[1] and msg.content[1].text) or ""

            if dev_text ~= "" then
                table.insert(system_blocks, { text = dev_text })
            end
        elseif msg.role == prompt.ROLE.FUNCTION_RESULT then
            local result_text = type(msg.content) == "string" and msg.content or
                (type(msg.content) == "table" and msg.content[1] and msg.content[1].text) or ""

            table.insert(converse_messages, {
                role = "user",
                content = {
                    {
                        toolResult = {
                            toolUseId = msg.function_call_id or "",
                            content = { { text = result_text } },
                            status = "success"
                        }
                    }
                }
            })
        elseif msg.role == prompt.ROLE.FUNCTION_CALL then
            local arguments = normalize_tool_arguments(msg.function_call.arguments)
            local content_blocks = {}

            if msg.metadata and msg.metadata.thinking_blocks then
                for _, thinking_block in ipairs(msg.metadata.thinking_blocks) do
                    if thinking_block.type == "thinking" then
                        table.insert(content_blocks, {
                            reasoningContent = {
                                reasoningText = {
                                    text = thinking_block.thinking or "",
                                    signature = thinking_block.signature or ""
                                }
                            }
                        })
                    end
                end
            end

            table.insert(content_blocks, {
                toolUse = {
                    toolUseId = msg.function_call.id or "",
                    name = msg.function_call.name or "",
                    input = arguments
                }
            })

            table.insert(converse_messages, {
                role = "assistant",
                content = content_blocks
            })
        elseif msg.role == prompt.ROLE.ASSISTANT then
            local content_blocks = {}

            if msg.metadata and msg.metadata.thinking_blocks then
                for _, thinking_block in ipairs(msg.metadata.thinking_blocks) do
                    if thinking_block.type == "thinking" then
                        table.insert(content_blocks, {
                            reasoningContent = {
                                reasoningText = {
                                    text = thinking_block.thinking or "",
                                    signature = thinking_block.signature or ""
                                }
                            }
                        })
                    end
                end
            end

            local content = msg.content
            if type(content) == "string" then
                if content ~= "" then
                    table.insert(content_blocks, { text = content })
                end
            elseif type(content) == "table" then
                for _, part in ipairs(content) do
                    if part.type == "text" and part.text and part.text ~= "" then
                        table.insert(content_blocks, { text = part.text })
                    elseif part.type == "function_call" then
                        local args = normalize_tool_arguments(part.arguments)
                        table.insert(content_blocks, {
                            toolUse = {
                                toolUseId = part.id or "",
                                name = part.name or "",
                                input = args
                            }
                        })
                    elseif part.type == "image" then
                        local img = convert_image_to_converse(part)
                        if img then
                            table.insert(content_blocks, img)
                        end
                    end
                end
            end

            if #content_blocks > 0 then
                table.insert(converse_messages, {
                    role = "assistant",
                    content = content_blocks
                })
            end
        else
            -- User messages
            local content_blocks = {}
            local content = msg.content
            if type(content) == "string" then
                table.insert(content_blocks, { text = content })
            elseif type(content) == "table" then
                for _, part in ipairs(content) do
                    if part.type == "text" and part.text then
                        table.insert(content_blocks, { text = part.text })
                    elseif part.type == "image" then
                        local img = convert_image_to_converse(part)
                        if img then
                            table.insert(content_blocks, img)
                        end
                    end
                end
            end

            if #content_blocks > 0 then
                table.insert(converse_messages, {
                    role = "user",
                    content = content_blocks
                })
            end
        end
    end

    -- Consolidate consecutive same-role messages
    local consolidated = {}
    for _, msg in ipairs(converse_messages) do
        if #consolidated > 0 and consolidated[#consolidated].role == msg.role then
            for _, block in ipairs(msg.content) do
                table.insert(consolidated[#consolidated].content, block)
            end
        else
            table.insert(consolidated, msg)
        end
    end

    return {
        messages = consolidated,
        system = #system_blocks > 0 and system_blocks or nil
    }
end

-- Map contract tools to Converse toolConfig
function mapper.map_tools(contract_tools)
    local converse_tools = {}
    local name_to_id_map = {}

    if not contract_tools then
        return nil, name_to_id_map
    end

    for _, tool in ipairs(contract_tools) do
        if tool.schema then
            table.insert(converse_tools, {
                toolSpec = {
                    name = tool.name,
                    description = tool.description,
                    inputSchema = {
                        json = tool.schema
                    }
                }
            })
            name_to_id_map[tool.name] = tool.id or tool.registry_id
        end
    end

    if #converse_tools == 0 then
        return nil, name_to_id_map
    end

    return converse_tools, name_to_id_map
end

-- Map contract tool_choice to Converse format
function mapper.map_tool_choice(contract_choice, tools)
    if not tools or #tools == 0 then
        return nil
    end

    if not contract_choice or contract_choice == "auto" then
        return nil
    elseif contract_choice == "none" then
        return nil
    elseif contract_choice == "any" then
        return { any = table.create(0, 1) }
    elseif type(contract_choice) == "string" then
        return { tool = { name = contract_choice } }
    end

    return nil
end

-- Map contract options to Converse inferenceConfig + additionalModelRequestFields
function mapper.map_options(contract_options)
    local inference_config = {}
    local additional_fields = {}

    if not contract_options then
        return inference_config, additional_fields
    end

    if contract_options.max_tokens then
        inference_config.maxTokens = contract_options.max_tokens
    end
    if contract_options.temperature then
        inference_config.temperature = contract_options.temperature
    end
    if contract_options.top_p then
        inference_config.topP = contract_options.top_p
    end
    if contract_options.stop_sequences then
        inference_config.stopSequences = contract_options.stop_sequences
    end

    -- Thinking/reasoning support
    if contract_options.thinking_effort and contract_options.thinking_effort > 0 then
        local thinking_budget = 1024 + (24000 - 1024) * (contract_options.thinking_effort / 100)
        thinking_budget = math.floor(thinking_budget + 0.5)

        additional_fields.thinking = {
            type = "enabled",
            budget_tokens = thinking_budget
        }

        -- Force temperature to 1 for thinking models
        inference_config.temperature = 1

        -- Ensure max_tokens accommodates thinking budget
        if not inference_config.maxTokens or inference_config.maxTokens <= thinking_budget then
            inference_config.maxTokens = thinking_budget + 1024
        end
    end

    -- Pass through top_k as additional field
    if contract_options.top_k then
        additional_fields.top_k = contract_options.top_k
    end

    return inference_config, additional_fields
end

-- Extract content from Converse response
function mapper.extract_response_content(converse_response)
    local content_text = ""
    local tool_calls = {}
    local thinking_blocks = {}

    if not converse_response or not converse_response.output
        or not converse_response.output.message
        or not converse_response.output.message.content then
        return {
            content = content_text,
            tool_calls = tool_calls,
            thinking_blocks = thinking_blocks
        }
    end

    for _, block in ipairs(converse_response.output.message.content) do
        if block.text then
            content_text = content_text .. block.text
        elseif block.toolUse then
            table.insert(tool_calls, {
                id = block.toolUse.toolUseId or "",
                name = block.toolUse.name or "",
                arguments = block.toolUse.input or {}
            })
        elseif block.reasoningContent and block.reasoningContent.reasoningText then
            table.insert(thinking_blocks, {
                type = "thinking",
                thinking = block.reasoningContent.reasoningText.text or "",
                signature = block.reasoningContent.reasoningText.signature or ""
            })
        end
    end

    return {
        content = content_text,
        tool_calls = tool_calls,
        thinking_blocks = thinking_blocks
    }
end

-- Map tool calls with registry ID resolution
function mapper.map_tool_calls(raw_tool_calls, name_to_id_map)
    local contract_tool_calls = {}
    for _, tool_call in ipairs(raw_tool_calls) do
        table.insert(contract_tool_calls, {
            id = tool_call.id,
            name = tool_call.name,
            arguments = tool_call.arguments,
            registry_id = name_to_id_map[tool_call.name]
        })
    end
    return contract_tool_calls
end

local function extract_thinking_text(thinking_blocks)
    local parts = {}
    for _, block in ipairs(thinking_blocks) do
        if block.type == "thinking" and block.thinking and block.thinking ~= "" then
            table.insert(parts, block.thinking)
        end
    end
    return table.concat(parts)
end

-- Format a full success response from Converse API response
function mapper.format_success_response(converse_response, name_to_id_map)
    local extracted = mapper.extract_response_content(converse_response)
    local tokens = mapper.map_tokens(converse_response.usage)
    local finish_reason = mapper.map_finish_reason(converse_response.stopReason)
    local thinking_content = extract_thinking_text(extracted.thinking_blocks)

    if tokens and thinking_content ~= "" then
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
        metadata = converse_response.metadata or {}
    }

    result.metadata.thinking = thinking_content
    result.metadata.thinking_blocks = extracted.thinking_blocks

    return result
end

-- Format a success response from streaming result
function mapper.format_streaming_response(stream_result, name_to_id_map, usage, finish_reason, response_metadata)
    local thinking_blocks = stream_result.thinking or {}
    local thinking_content = extract_thinking_text(thinking_blocks)
    local mapped_tool_calls = mapper.map_tool_calls(stream_result.tool_calls or {}, name_to_id_map or {})
    local tokens = mapper.map_tokens(usage)

    if tokens and thinking_content ~= "" then
        tokens.thinking_tokens = approximate_token_count(thinking_content)
    end

    local result = {
        success = true,
        result = {
            content = stream_result.content or "",
            tool_calls = mapped_tool_calls
        },
        tokens = tokens,
        finish_reason = mapper.map_finish_reason(finish_reason),
        metadata = response_metadata or {}
    }

    result.metadata.thinking = thinking_content
    result.metadata.thinking_blocks = thinking_blocks

    return result
end

return mapper
