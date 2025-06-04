local claude_client = require("claude_client")
local output = require("output")
local tools = require("tools")
local json = require("json")

-- Helper function to check if a model supports thinking
local function model_supports_thinking(model)
    -- Currently, only Claude 3.7 models support extended thinking
    if not model then
        return false
    end

    return model:match("claude%-3%-7") or model:match("claude%-3%.7")
end

-- Simplified function to extract only valid thinking blocks
local function extract_thinking_blocks(msg)
    local blocks = {}

    -- Check if thinking is in a name field
    if msg.meta and type(msg.meta) == "table" then
        -- Check for thinking_blocks array
        if msg.meta.thinking and type(msg.meta.thinking) == "table" then
            return { msg.meta.thinking }
        end
    end

    return {}
end

-- Function to consolidate consecutive assistant messages
local function consolidate_messages(messages)
    if #messages <= 1 then
        return messages
    end

    local result = {}
    local current_assistant_msg = nil

    for i, msg in ipairs(messages) do
        if msg.role == "assistant" then
            if current_assistant_msg then
                -- Merge content with existing assistant message
                for _, content_part in ipairs(msg.content) do
                    table.insert(current_assistant_msg.content, content_part)
                end
            else
                -- Start a new assistant message group
                current_assistant_msg = {
                    role = "assistant",
                    content = {}
                }
                -- Copy content
                for _, content_part in ipairs(msg.content) do
                    table.insert(current_assistant_msg.content, content_part)
                end
                table.insert(result, current_assistant_msg)
            end
        else
            -- Non-assistant message breaks the grouping
            current_assistant_msg = nil
            table.insert(result, msg)
        end
    end

    return result
end

-- Claude Tool Calling Handler
local function handler(args)
    -- Validate required arguments
    if not args.model then
        return {
            error = output.ERROR_TYPE.INVALID_REQUEST,
            error_message = "Model is required"
        }
    end

    -- Format messages
    local messages = args.messages or {}
    if #messages == 0 then
        return {
            error = output.ERROR_TYPE.INVALID_REQUEST,
            error_message = "No messages provided"
        }
    end

    -- Configure options
    local options = args.options or {}

    -- Process messages - separating system, developer, and cache marker messages from regular messages
    local processed_messages = {}
    local system_content = {}

    -- Track cache markers and their positions
    local cache_marker_positions = {}
    local current_marker_idx = 1
    local has_cache_markers = false

    -- Debug token count issue detection
    local has_system_content = false

    -- Map developer instructions to positions
    local developer_instructions = {}

    -- Track tool use IDs to ensure proper matching between tool_use and tool_result
    local tool_use_ids = {}

    -- Simple map to track thinking blocks per tool use ID
    local tool_use_thinking = {}

    -- First pass: Process system messages, collect developer instructions, and extract thinking blocks
    for i, msg in ipairs(messages) do
        if msg.role == "system" then
            has_system_content = true
            -- Handle system messages - add to system content
            if type(msg.content) == "string" then
                table.insert(system_content, {
                    type = "text",
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
        elseif msg.role == "developer" then
            -- Collect developer instruction content
            local dev_content
            if type(msg.content) == "string" then
                dev_content = msg.content
            else
                -- If content is an array, extract the text
                local text = ""
                for _, part in ipairs(msg.content) do
                    if part.type == "text" then
                        text = text .. part.text
                    end
                end
                dev_content = text
            end

            -- Find the previous non-developer, non-cache_marker message index
            local prev_msg_idx = i - 1
            while prev_msg_idx >= 1 do
                local prev_role = messages[prev_msg_idx].role
                if prev_role ~= "developer" and prev_role ~= "cache_marker" then
                    -- Store developer instruction with the index of the previous message
                    if not developer_instructions[prev_msg_idx] then
                        developer_instructions[prev_msg_idx] = {}
                    end
                    table.insert(developer_instructions[prev_msg_idx], dev_content)
                    break
                end
                prev_msg_idx = prev_msg_idx - 1
            end
        elseif msg.role == "assistant" and (msg.function_call or (type(msg.content) == "table" and #msg.content > 0)) then
            -- Extract thinking blocks from assistant messages that have function calls
            local thinking_blocks = extract_thinking_blocks(msg)

            -- Associate thinking blocks with tool uses in this message
            if msg.function_call and msg.function_call.id then
                tool_use_thinking[msg.function_call.id] = thinking_blocks
            elseif type(msg.content) == "table" then
                for _, part in ipairs(msg.content) do
                    if part.type == "function_call" and part.id then
                        tool_use_thinking[part.id] = thinking_blocks
                    end
                end
            end
        elseif msg.role == "function_call" and msg.function_call and msg.function_call.id then
            -- Save the tool ID to validate later
            tool_use_ids[msg.function_call.id] = true
        end
    end

    -- Second pass: Process the main conversation messages
    for i = 1, #messages do
        local msg = messages[i]

        if msg.role == "user" then
            -- Regular user message - format content properly
            local content
            if type(msg.content) == "string" then
                content = { { type = "text", text = msg.content } }
            else
                content = msg.content
            end

            -- Add to processed messages
            table.insert(processed_messages, {
                role = "user",
                content = content
            })

            -- Track position for message cache markers
            current_marker_idx = #processed_messages
        elseif msg.role == "assistant" then
            -- Regular assistant message - extract thinking, tool uses, and regular content
            local thinking_blocks = extract_thinking_blocks(msg)
            local text_blocks = {}
            local tool_use_blocks = {}
            local content

            -- Format content properly
            if type(msg.content) == "string" then
                content = { { type = "text", text = msg.content } }
            else
                content = msg.content
            end

            -- Separate different content types
            for _, part in ipairs(content) do
                if part.type == "thinking" or part.type == "redacted_thinking" then
                    -- Skip here, we already extracted thinking blocks
                elseif part.type == "function_call" then
                    -- Convert function_call to tool_use format
                    local function_id = part.id
                    local function_name = part.name
                    local arguments = part.arguments

                    -- Convert arguments from string to object if needed
                    if type(arguments) == "string" then
                        local success, parsed = pcall(json.decode, arguments)
                        if success then
                            arguments = parsed
                        end
                    end

                    if not arguments or next(arguments) == nil then
                        arguments = { run = true }
                    end

                    -- Add to tool_use blocks
                    table.insert(tool_use_blocks, {
                        type = "tool_use",
                        id = function_id,
                        name = function_name,
                        input = arguments
                    })

                    -- Track this tool use ID for later validation
                    tool_use_ids[function_id] = true
                else
                    table.insert(text_blocks, part)
                end
            end

            -- Also check for function_call at top level
            if msg.function_call then
                local function_id = msg.function_call.id
                local function_name = msg.function_call.name
                local arguments = msg.function_call.arguments

                -- Convert arguments from string to object if needed
                if type(arguments) == "string" then
                    local success, parsed = pcall(json.decode, arguments)
                    if success then
                        arguments = parsed
                    end
                end

                if not arguments or next(arguments) == nil then
                    arguments = { run = true }
                end

                -- Add to tool_use blocks
                table.insert(tool_use_blocks, {
                    type = "tool_use",
                    id = function_id,
                    name = function_name,
                    input = arguments
                })

                -- Track this tool use ID for later validation
                tool_use_ids[function_id] = true

                -- Store thinking blocks with this tool use ID
                if #thinking_blocks > 0 then
                    tool_use_thinking[function_id] = thinking_blocks
                end
            end

            -- If we have tool_use blocks, create separate assistant messages
            -- with thinking + one tool_use per message
            if #tool_use_blocks > 0 then
                for _, tool_use in ipairs(tool_use_blocks) do
                    local assistant_message = {
                        role = "assistant",
                        content = {}
                    }

                    -- Add thinking blocks first (if any)
                    for _, thinking in ipairs(thinking_blocks) do
                        table.insert(assistant_message.content, thinking)
                    end

                    -- Then add the tool_use block
                    table.insert(assistant_message.content, tool_use)

                    -- Add to processed messages
                    table.insert(processed_messages, assistant_message)
                end

                -- If we also have text blocks, create a separate message for them
                if #text_blocks > 0 then
                    local text_message = {
                        role = "assistant",
                        content = {}
                    }

                    -- Add thinking blocks first
                    for _, thinking in ipairs(thinking_blocks) do
                        table.insert(text_message.content, thinking)
                    end

                    -- Then add text blocks
                    for _, block in ipairs(text_blocks) do
                        table.insert(text_message.content, block)
                    end

                    table.insert(processed_messages, text_message)
                end
            else
                -- No tool uses, just create a regular assistant message
                local combined_content = {}

                -- Add thinking blocks first
                for _, thinking in ipairs(thinking_blocks) do
                    table.insert(combined_content, thinking)
                end

                -- Then add regular text blocks
                for _, block in ipairs(text_blocks) do
                    table.insert(combined_content, block)
                end

                -- Add to processed messages
                table.insert(processed_messages, {
                    role = "assistant",
                    content = combined_content
                })
            end

            -- Track position for message cache markers
            current_marker_idx = #processed_messages
        elseif msg.role == "function_call" then
            -- Handle function call messages - convert to assistant with tool_use
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

            if not arguments or next(arguments) == nil then
                arguments = { run = true }
            end

            -- Get thinking blocks for this tool use if available
            local thinking_blocks = tool_use_thinking[function_id] or {}

            -- Create an assistant message with tool_use content block
            local assistant_message = {
                role = "assistant",
                content = {}
            }

            -- Add thinking blocks first
            for _, thinking in ipairs(thinking_blocks) do
                table.insert(assistant_message.content, thinking)
            end

            -- Then add the tool_use block
            table.insert(assistant_message.content, {
                type = "tool_use",
                id = function_id,
                name = function_name,
                input = arguments
            })

            table.insert(processed_messages, assistant_message)

            -- Track this tool use ID for later validation
            tool_use_ids[function_id] = true

            -- Track position for message cache markers
            current_marker_idx = #processed_messages
        elseif msg.role == "function_result" then
            -- Handle function results - convert to user with tool_result
            local function_call_id = msg.function_call_id
            local result_content = ""

            -- Extract content from function result
            if type(msg.content) == "string" then
                result_content = msg.content
            elseif type(msg.content) == "table" and #msg.content > 0 then
                if msg.content[1].type == "text" then
                    result_content = msg.content[1].text
                end
            end

            if type(result_content) == "table" then
                result_content = json.encode(result_content)
            end

            -- Ensure we have a corresponding tool_use for this tool_result
            if not tool_use_ids[function_call_id] then
                print("Warning: Missing tool_use for tool_result ID: " .. function_call_id)

                -- Create a placeholder tool_use to satisfy Claude's requirements
                local name = msg.name or "unknown_tool"

                local assistant_message = {
                    role = "assistant",
                    content = {
                        {
                            type = "tool_use",
                            id = function_call_id,
                            name = name,
                            input = { run = true }
                        }
                    }
                }

                table.insert(processed_messages, assistant_message)
                tool_use_ids[function_call_id] = true
            end

            -- Create a user message with tool_result content block
            table.insert(processed_messages, {
                role = "user",
                content = {
                    {
                        type = "tool_result",
                        tool_use_id = function_call_id,
                        content = result_content
                    }
                }
            })

            -- Track position for message cache markers
            current_marker_idx = #processed_messages
        end
    end

    -- Apply developer instructions to messages
    for i, msg in ipairs(messages) do
        if developer_instructions[i] and #developer_instructions[i] > 0 then
            -- Get the corresponding processed message index
            local processed_idx = 0
            local cur_reg_msg = 0

            -- Count regular messages up to this index to find the processed message
            for j = 1, i do
                if messages[j].role ~= "developer" and messages[j].role ~= "cache_marker" and messages[j].role ~= "system" then
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
                    if last_content.type == "text" then
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

        if not applied then
            system_content[#system_content].cache_control = {
                type = "ephemeral"
            }
            print("Applied fallback cache_control to last system block")
        end
    end

    -- Process tool schemas (either from tool_ids or direct tool_schemas)
    local claude_tools = {}
    local tool_name_to_id_map = {} -- Map tool names back to our IDs

    -- If tool IDs are provided, resolve them
    if args.tool_ids and #args.tool_ids > 0 then
        local tool_schemas, errors = tools.get_tool_schemas(args.tool_ids)

        if errors and next(errors) then
            local err_msg = "Failed to resolve tool schemas: "
            for id, err in pairs(errors) do
                err_msg = err_msg .. id .. " (" .. err .. "), "
            end
            return {
                error = output.ERROR_TYPE.INVALID_REQUEST,
                error_message = err_msg:sub(1, -3) -- Remove trailing comma and space
            }
        end

        -- Convert tool schemas to Claude format
        for id, tool in pairs(tool_schemas) do
            table.insert(claude_tools, {
                name = tool.name,
                description = tool.description,
                input_schema = tool.schema
            })

            -- Remember the mapping from tool name to ID
            tool_name_to_id_map[tool.name] = id
        end
    end

    -- If tool schemas are provided directly, use them
    if args.tool_schemas and next(args.tool_schemas) then
        for id, tool in pairs(args.tool_schemas) do
            table.insert(claude_tools, {
                name = tool.name,
                description = tool.description,
                input_schema = tool.schema
            })

            -- Remember the mapping from tool name to ID
            tool_name_to_id_map[tool.name] = id
        end
    end

    -- Configure tool_choice based on args.tool_call
    local tool_choice = nil
    if #claude_tools > 0 then
        if args.tool_call == "none" then
            tool_choice = { type = "none" }
        elseif args.tool_call == "any" then
            tool_choice = { type = "any" }
        elseif args.tool_call == "auto" or not args.tool_call then
            tool_choice = { type = "auto" }
        elseif type(args.tool_call) == "string" and args.tool_call ~= "auto" and args.tool_call ~= "none" then
            -- A specific tool name was provided
            -- Check if specified tool exists
            local found = false
            for _, tool in ipairs(claude_tools) do
                if tool.name == args.tool_call then
                    found = true
                    tool_choice = {
                        type = "tool",
                        name = args.tool_call
                    }
                    break
                end
            end

            if not found then
                return {
                    error = output.ERROR_TYPE.INVALID_REQUEST,
                    error_message = "Specified tool '" .. args.tool_call .. "' not found in available tools"
                }
            end
        end
    end

    -- Consolidate consecutive assistant messages
    processed_messages = consolidate_messages(processed_messages)

    -- Configure request payload
    local payload = {
        model = args.model,
        messages = processed_messages,
        max_tokens = options.max_tokens,
        temperature = options.temperature,
        stop_sequences = options.stop_sequences,
        tools = #claude_tools > 0 and claude_tools or nil,
        tool_choice = tool_choice
    }

    -- Only add system content if we have any
    if #system_content > 0 then
        payload.system = system_content
    elseif has_system_content then
        print("WARNING: System content was detected but not added to payload")
    end

    -- Add thinking if enabled and model supports it
    if options.thinking_effort and options.thinking_effort > 0 then
        if model_supports_thinking(args.model) then
            -- Calculate thinking budget based on thinking effort
            local thinking_budget = claude_client.calculate_thinking_budget(options.thinking_effort)

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
            end
        end

        -- Set temperature to 1 when thinking is enabled (REQUIRED by Claude API)
        payload.temperature = 1
    end

    -- Function to handle error mapping
    local function map_claude_error(err)
        return claude_client.map_error(err)
    end

    -- Handle streaming if requested
    if args.stream and args.stream.reply_to then
        -- Create a streamer with the provided reply_to process ID
        local streamer = output.streamer(
            args.stream.reply_to,
            args.stream.topic or "llm_response",
            args.stream.buffer_size or 10
        )

        -- Make streaming request
        local response, err = claude_client.request(
            claude_client.API_ENDPOINTS.MESSAGES,
            payload,
            {
                api_version = args.api_version,
                stream = true,
                timeout = args.timeout or 120,
                beta_features = options.beta_features
            }
        )

        -- Handle request errors
        if err then
            local mapped_error = map_claude_error(err)

            streamer:send_error(
                mapped_error.error,
                mapped_error.error_message,
                mapped_error.code
            )

            return mapped_error
        end

        -- Variables to track the state
        local full_content = ""
        local finish_reason = nil
        local tool_calls = {}
        local thinking_content = ""
        local has_thinking = false

        -- Track thinking blocks with their content and signatures
        local thinking_block = {}
        local current_thinking_block = {
            content = "",
            signature = nil,
            index = nil,
            type = nil
        }

        -- Process the streaming response
        local stream_content, stream_err, stream_result = claude_client.process_stream(response, {
            on_content = function(content_chunk)
                full_content = full_content .. content_chunk
                streamer:buffer_content(content_chunk)
            end,
            on_tool_call = function(tool_call_info)
                -- Track tool calls
                table.insert(tool_calls, {
                    id = tool_call_info.id or "",
                    name = tool_call_info.name or "",
                    arguments = tool_call_info.arguments or {},
                    registry_id = tool_name_to_id_map[tool_call_info.name]
                })

                return true
            end,
            on_thinking = function(thinking_chunk, details)
                -- Update thinking content string for backward compatibility
                thinking_content = thinking_content .. thinking_chunk
                has_thinking = true
                streamer:send_thinking(thinking_chunk)

                -- Track thinking blocks with more detail
                if details then
                    if details.type == "thinking_delta" then
                        -- Update the current thinking block
                        if current_thinking_block.index == nil then
                            current_thinking_block.index = details.block_index
                            current_thinking_block.type = "thinking"
                        end

                        -- Append to content
                        current_thinking_block.content = current_thinking_block.content .. thinking_chunk
                    elseif details.type == "signature_delta" and details.signature then
                        -- Store signature with current thinking block
                        if current_thinking_block.index ~= nil then
                            current_thinking_block.signature = details.signature

                            -- Store the completed thinking block
                            thinking_block = {
                                type = current_thinking_block.type,
                                thinking = current_thinking_block.content,
                                signature = current_thinking_block.signature
                            }

                            -- Reset for next block
                            current_thinking_block = {
                                content = "",
                                signature = nil,
                                index = nil,
                                type = nil
                            }
                        end
                    end
                end

                print(json.encode(details))
            end,
            on_error = function(error_info)
                -- Convert error to standard format
                local mapped_error = {
                    error = output.ERROR_TYPE.SERVER_ERROR,
                    error_message = error_info.message or "Error processing stream",
                    code = error_info.code
                }

                -- Send error to the streamer
                streamer:send_error(
                    mapped_error.error,
                    mapped_error.error_message,
                    mapped_error.code
                )
            end,
            on_done = function(result)
                -- Flush any remaining content
                streamer:flush()

                -- Save finish reason
                if result.finish_reason then
                    finish_reason = result.finish_reason
                end

                -- If there's a remaining thinking block in progress, store it
                if current_thinking_block.index ~= nil and current_thinking_block.content ~= "" and current_thinking_block.signature then
                    thinking_block = {
                        type = current_thinking_block.type or "thinking",
                        thinking = current_thinking_block.content,
                        signature = current_thinking_block.signature
                    }
                end
            end
        })

        -- Handle streaming errors
        if stream_err then
            return {
                error = output.ERROR_TYPE.SERVER_ERROR,
                error_message = stream_err,
                code = stream_result and stream_result.error and stream_result.error.code,
                streaming = true
            }
        end

        -- Extract tokens from stream_result if available
        local tokens = nil
        if stream_result and stream_result.usage then
            -- Create token usage object
            tokens = output.usage(
                stream_result.usage.input_tokens or 0,
                stream_result.usage.output_tokens or 0,
                0, -- Claude doesn't return thinking tokens separately
                stream_result.usage.cache_creation_input_tokens or 0,
                stream_result.usage.cache_read_input_tokens or 0
            )

            -- Ensure the cache tokens are directly accessible in the result
            if stream_result.usage.cache_creation_input_tokens and stream_result.usage.cache_creation_input_tokens > 0 then
                tokens.cache_creation_input_tokens = stream_result.usage.cache_creation_input_tokens
            end

            if stream_result.usage.cache_read_input_tokens and stream_result.usage.cache_read_input_tokens > 0 then
                tokens.cache_read_input_tokens = stream_result.usage.cache_read_input_tokens
            end
        end

        -- Prepare the result based on whether we have tool calls or just text
        local result
        if #tool_calls > 0 then
            result = {
                result = {
                    content = full_content,
                    tool_calls = tool_calls
                },
                tokens = tokens,
                metadata = response.metadata,
                finish_reason = "tool_call",
                streaming = true,
                provider = "anthropic",
                model = args.model
            }
        else
            -- Map the finish reason to standardized format
            local standardized_finish_reason = claude_client.FINISH_REASON_MAP[finish_reason] or finish_reason

            result = {
                result = full_content,
                tokens = tokens,
                metadata = response.metadata,
                finish_reason = standardized_finish_reason,
                streaming = true,
                provider = "anthropic",
                model = args.model
            }
        end

        -- Add thinking content at both root level and in meta for consistency
        if has_thinking then
            -- Initialize meta if not present
            if not result.meta then
                result.meta = {}
            end

            result.meta.thinking = thinking_block
        end

        return result
    else
        -- Non-streaming request
        local response, err = claude_client.request(
            claude_client.API_ENDPOINTS.MESSAGES,
            payload,
            {
                api_version = args.api_version,
                timeout = args.timeout or 120,
                beta_features = options.beta_features
            }
        )

        -- Handle errors
        if err then
            local mapped_error = map_claude_error(err)
            return mapped_error
        end

        -- Check response validity
        if not response then
            return {
                error = output.ERROR_TYPE.SERVER_ERROR,
                error_message = "Empty response from Claude API"
            }
        end

        if not response.content then
            return {
                error = output.ERROR_TYPE.SERVER_ERROR,
                error_message = "Invalid response structure from Claude API (missing content)"
            }
        end

        -- Process the response content
        local content_text = ""
        local tool_calls = {}
        local thinking_content = ""
        local has_thinking = false
        local thinking_block = {}

        for i, block in ipairs(response.content) do
            if block.type == "text" then
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
                    arguments = arguments,
                    registry_id = tool_name_to_id_map[block.name]
                })
            elseif block.type == "thinking" or block.type == "redacted_thinking" then
                -- Store thinking blocks
                has_thinking = true

                -- Add to structured thinking blocks collection
                if (block.type == "thinking" and block.signature) or block.type == "redacted_thinking" then
                    thinking_block = {
                        type = block.type,
                        thinking = block.type == "thinking" and block.thinking or "",
                        data = block.type == "redacted_thinking" and block.data or nil,
                        signature = block.signature or nil
                    }
                end

                -- Also store as text for backward compatibility
                if block.type == "thinking" then
                    thinking_content = thinking_content .. (block.thinking or "")
                end
            end
        end

        -- Extract token usage information with proper output format
        local tokens = nil
        if response.usage then
            -- Use output.usage to create a properly formatted token usage object
            tokens = output.usage(
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
        end

        -- Prepare the result based on whether we have tool calls or just text
        local result
        if #tool_calls > 0 then
            result = {
                result = {
                    content = content_text,
                    tool_calls = tool_calls
                },
                tokens = tokens,
                metadata = response.metadata,
                finish_reason = "tool_call",
                provider = "anthropic",
                model = args.model
            }
        else
            -- Map finish reason to standardized format
            local finish_reason = claude_client.FINISH_REASON_MAP[response.stop_reason] or response.stop_reason

            -- Return successful text response
            result = {
                result = content_text,
                tokens = tokens,
                metadata = response.metadata,
                finish_reason = finish_reason,
                provider = "anthropic",
                model = args.model
            }
        end

        -- Add thinking content at both root level and in meta for consistency
        if has_thinking then
            -- Initialize meta if not present
            if not result.meta then
                result.meta = {}
            end

            result.meta.thinking = thinking_block
        end

        return result
    end
end

-- Return the handler function
return { handler = handler }
