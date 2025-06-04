local openai_client = require("openai_client")
local output = require("output")
local tools = require("tools")
local json = require("json")
local prompt_mapper = require("prompt_mapper")

-- OpenAI Tool/Function Calling Handler
-- Supports text generation with tool/function calling capabilities
local function handler(args)
    -- Validate required arguments
    if not args.model then
        return {
            error = output.ERROR_TYPE.INVALID_REQUEST,
            error_message = "Model is required"
        }
    end

    -- Format messages from various input formats
    local messages = args.messages or {}

    if #messages == 0 then
        return {
            error = output.ERROR_TYPE.INVALID_REQUEST,
            error_message = "No messages provided"
        }
    end

    -- Process all messages with the consistent prompt mapper
    messages = prompt_mapper.map_to_openai(messages, {
        model = args.model
    })

    -- Configure options objects for easier management
    local options = args.options or {}

    -- Check if this is an o* model (OpenAI o-series models)
    local is_o_model = args.model:match("^o%d") ~= nil

    -- Configure request payload
    local payload = {
        model = args.model,
        messages = messages,
        top_p = options.top_p,
        top_k = options.top_k,
        presence_penalty = options.presence_penalty,
        frequency_penalty = options.frequency_penalty,
        logit_bias = options.logit_bias,
        user = options.user,
        seed = options.seed
    }

    -- Handle max tokens parameter differently based on model type
    if options.max_tokens then
        if is_o_model then
            payload.max_completion_tokens = options.max_tokens
            -- Remove max_tokens for o* models as it's not supported
            payload.max_tokens = nil
        else
            payload.max_tokens = options.max_tokens
        end
    end

    -- Always apply max_completion_tokens if explicitly provided
    if options.max_completion_tokens then
        payload.max_completion_tokens = options.max_completion_tokens
        -- For consistency, remove max_tokens if max_completion_tokens is specified
        payload.max_tokens = nil
    end

    -- Add temperature based on model type
    if options.temperature ~= nil then
        payload.temperature = options.temperature
    end

    -- Add stop sequences if provided
    if options.stop_sequences then
        payload.stop = options.stop_sequences
    elseif options.stop then
        payload.stop = options.stop
    end

    -- Add thinking effort mapping - using the utility in openai client
    if args.thinking_effort and args.thinking_effort > 0 then
        payload.reasoning_effort = openai_client.map_thinking_effort(args.thinking_effort)
    end

    -- Remove temperature for o* models
    if is_o_model then
        payload.temperature = nil
    end

    -- Process tool schemas (either from tool_ids or direct tool_schemas)
    local request_tools = {}
    local tool_name_to_id_map = {} -- Map OpenAI tool names back to our IDs

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

        -- Convert tool schemas to OpenAI format
        for id, tool in pairs(tool_schemas) do
            local tool_entry = {
                type = "function"
            }
            -- Use bracket syntax for "function" keyword
            tool_entry["function"] = {
                name = tool.name,
                description = tool.description,
                parameters = tool.schema
            }
            table.insert(request_tools, tool_entry)

            -- Remember the mapping from tool name to ID for later
            tool_name_to_id_map[tool.name] = id
        end
    end

    -- If tool schemas are provided directly, use them
    if args.tool_schemas and next(args.tool_schemas) then
        for id, tool in pairs(args.tool_schemas) do
            local tool_entry = {
                type = "function"
            }
            -- Use bracket syntax for "function" keyword
            tool_entry["function"] = {
                name = tool.name,
                description = tool.description,
                parameters = tool.schema
            }
            table.insert(request_tools, tool_entry)

            -- Remember the mapping from tool name to ID
            tool_name_to_id_map[tool.name] = id
        end
    end

    -- Add tools to request if any are defined
    if #request_tools > 0 then
        payload.tools = request_tools

        -- Set tool_choice based on args.tool_call per spec
        if args.tool_call == "none" then
            payload.tool_choice = "none"
        elseif args.tool_call == "any" then
            payload.tool_choice = "required"
        elseif args.tool_call == "auto" or not args.tool_call then
            payload.tool_choice = "auto"
        elseif type(args.tool_call) == "string" and args.tool_call ~= "auto" and args.tool_call ~= "none" then
            -- A specific tool name was provided
            local tool_choice = {
                type = "function"
            }
            -- Use bracket syntax for "function" keyword
            tool_choice["function"] = {
                name = args.tool_call
            }
            payload.tool_choice = tool_choice

            -- Check if specified tool exists in our available tools
            local found = false
            for _, tool in ipairs(request_tools) do
                if tool["function"].name == args.tool_call then
                    found = true
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

    -- Handle streaming configuration
    local stream_config = nil
    if args.stream and type(args.stream) == "table" and args.stream.reply_to then
        stream_config = {
            enabled = true,
            reply_to = args.stream.reply_to,
            topic = args.stream.topic or "llm_response",
            buffer_size = args.stream.buffer_size or 10
        }
    end

    -- Make the request
    local request_options = {
        organization = args.organization,
        timeout = args.timeout or 120
    }

    -- Enable streaming in the request if configured
    if stream_config then
        request_options.stream = true
    end

    -- Perform the request to OpenAI
    local response, err = openai_client.request(
        openai_client.DEFAULT_CHAT_ENDPOINT,
        payload,
        request_options
    )

    -- Handle request errors
    if err then
        return openai_client.map_error(err)
    end

    -- Rest of the function remains the same...
    -- (Handling streaming, processing responses, etc.)

    -- Handle streaming responses
    if stream_config and response.stream then
        -- Create a streamer
        local streamer = output.streamer(
            stream_config.reply_to,
            stream_config.topic,
            stream_config.buffer_size
        )

        -- Variables to track the state
        local full_content = ""
        local finish_reason = nil
        local tool_calls_data = {}
        local has_tool_calls = false

        -- Process the streaming response
        local stream_content, stream_err, stream_result = openai_client.process_stream(response, {
            on_content = function(content_chunk)
                -- Always buffer content chunks
                streamer:buffer_content(content_chunk)
                full_content = full_content .. content_chunk
            end,
            on_tool_call = function(tool_call_info)
                -- Mark that we've seen a tool call
                has_tool_calls = true

                -- Add tool call to our tracking
                table.insert(tool_calls_data, tool_call_info)

                -- Parse arguments for streaming
                local parsed_args = {}
                if tool_call_info.arguments then
                    local args, parse_err = json.decode(tool_call_info.arguments)
                    if args and not parse_err then
                        parsed_args = args
                    end
                end

                return true
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

                -- Process all tool calls into our format
                local processed_tool_calls = {}
                for _, tool_call in ipairs(tool_calls_data) do
                    local parsed_args = {}
                    if tool_call.arguments then
                        local args, parse_err = json.decode(tool_call.arguments)
                        if args and not parse_err then
                            parsed_args = args
                        end
                    end

                    table.insert(processed_tool_calls, {
                        id = tool_call.id,
                        name = tool_call.name,
                        arguments = parsed_args,
                        registry_id = tool_name_to_id_map[tool_call.name]
                    })
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
            tokens = output.usage(
                stream_result.usage.prompt_tokens,
                stream_result.usage.completion_tokens,
                (stream_result.usage.completion_tokens_details and
                    stream_result.usage.completion_tokens_details.reasoning_tokens) or 0
            )
        end

        -- Return the final content and metadata for the caller
        if #tool_calls_data > 0 then
            -- Process tool calls into our format
            local processed_tool_calls = {}
            for _, tool_call in ipairs(tool_calls_data) do
                local parsed_args = {}
                if tool_call.arguments then
                    local args, parse_err = json.decode(tool_call.arguments)
                    if args and not parse_err then
                        parsed_args = args
                    end
                end

                table.insert(processed_tool_calls, {
                    id = tool_call.id,
                    name = tool_call.name,
                    arguments = parsed_args,
                    registry_id = tool_name_to_id_map[tool_call.name]
                })
            end

            return {
                result = {
                    content = full_content,
                    tool_calls = processed_tool_calls
                },
                tokens = tokens,
                metadata = response.metadata,
                finish_reason = "tool_call",
                streaming = true,
                provider = "openai",
                model = args.model
            }
        else
            return {
                result = stream_content or full_content,
                tokens = tokens,
                metadata = response.metadata,
                finish_reason = finish_reason and openai_client.FINISH_REASON_MAP[finish_reason] or finish_reason,
                streaming = true,
                provider = "openai",
                model = args.model
            }
        end
    end

    -- Handle non-streaming responses - check response validity
    if not response or not response.choices or #response.choices == 0 then
        return {
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "Invalid response structure from OpenAI"
        }
    end

    -- Extract the first choice
    local first_choice = response.choices[1]
    if not first_choice or not first_choice.message then
        return {
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "Invalid choice structure in OpenAI response"
        }
    end

    -- Extract token usage information
    local tokens = nil
    if response.usage then
        tokens = output.usage(
            response.usage.prompt_tokens,
            response.usage.completion_tokens,
            (response.usage.completion_tokens_details and
                response.usage.completion_tokens_details.reasoning_tokens) or 0
        )
    end

    -- Check if the response contains tool calls
    if first_choice.message.tool_calls and #first_choice.message.tool_calls > 0 then
        -- Process each tool call
        local processed_tool_calls = {}
        for _, tool_call in ipairs(first_choice.message.tool_calls) do
            if tool_call["function"] then
                -- Parse arguments JSON string into a Lua table
                local arguments = {}
                if tool_call["function"].arguments then
                    local parsed, parse_err = json.decode(tool_call["function"].arguments)
                    if not parse_err and parsed then
                        arguments = parsed
                    end
                end

                -- Add the processed tool call
                table.insert(processed_tool_calls, {
                    id = tool_call.id,
                    name = tool_call["function"].name,
                    arguments = arguments,
                    registry_id = tool_name_to_id_map[tool_call["function"].name]
                })
            end
        end

        -- Return tool call result in our standardized format
        return {
            result = {
                content = first_choice.message.content or "",
                tool_calls = processed_tool_calls
            },
            tokens = tokens,
            metadata = response.metadata,
            finish_reason = "tool_call",
            provider = "openai",
            model = args.model
        }
    elseif first_choice.message.content then
        -- Return text response
        return {
            result = first_choice.message.content,
            tokens = tokens,
            metadata = response.metadata,
            finish_reason = openai_client.FINISH_REASON_MAP[first_choice.finish_reason] or first_choice.finish_reason,
            provider = "openai",
            model = args.model
        }
    else
        return {
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "No content or tool calls in OpenAI response"
        }
    end
end

return { handler = handler }
