local claude = require("claude_client")
local output = require("output")
local mapper = require("mapper")

-- Claude Text Generation Handler
-- Supports text generation without tool calling functionality
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

    -- Process messages using the mapper
    local processed = mapper.process_messages(messages)

    -- Configure request payload
    local payload = {
        model = args.model,
        messages = processed.messages,
        max_tokens = options.max_tokens,
        temperature = options.temperature,
        stop_sequences = options.stop_sequences
    }

    -- Only add system content if we have any
    if processed.system then
        payload.system = processed.system
        -- Debug system message token count issue
        print("Adding system content to payload, count:", #processed.system)
    elseif processed.has_system then
        print("WARNING: System content was detected but not added to payload")
    end

    -- Configure thinking if enabled
    payload = mapper.configure_thinking(payload, args.model, options)

    -- Handle streaming if requested
    if args.stream and args.stream.reply_to then
        -- Create a streamer with the provided reply_to process ID
        local streamer = output.streamer(
            args.stream.reply_to,
            args.stream.topic or "llm_response",
            args.stream.buffer_size or 10
        )

        -- Make streaming request
        local response, err = claude.request(
            claude.API_ENDPOINTS.MESSAGES,
            payload,
            {
                api_key = args.api_key,
                api_version = args.api_version,
                stream = true,
                timeout = args.timeout or 120,
                beta_features = options.beta_features
            }
        )

        -- Handle request errors
        if err then
            local mapped_error = mapper.map_error(err)

            streamer:send_error(
                mapped_error.error,
                mapped_error.error_message,
                mapped_error.code
            )

            return mapped_error
        end

        -- Variables to store the full result
        local full_content = ""
        local finish_reason = nil
        local thinking_content = ""
        local has_thinking = false

        -- Process the streaming response
        local stream_content, stream_err, stream_result = claude.process_stream(response, {
            on_content = function(content_chunk)
                full_content = full_content .. content_chunk
                streamer:buffer_content(content_chunk)
            end,
            on_thinking = function(thinking_chunk)
                -- Collect thinking content and stream it
                thinking_content = thinking_content .. thinking_chunk
                has_thinking = true
                streamer:send_thinking(thinking_chunk)
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
            tokens = mapper.extract_usage(stream_result)
        end

        -- Map the finish reason to standardized format
        local standardized_finish_reason = mapper.FINISH_REASON_MAP[finish_reason] or finish_reason

        -- Return the final result with streaming flag
        local result = mapper.format_text_response(
            full_content,
            args.model,
            tokens,
            standardized_finish_reason,
            response.metadata,
            has_thinking and thinking_content or nil
        )

        result.streaming = true
        return result
    else
        -- Non-streaming request
        local response, err = claude.request(
            claude.API_ENDPOINTS.MESSAGES,
            payload,
            {
                api_key = args.api_key,
                api_version = args.api_version,
                timeout = args.timeout or 120,
                beta_features = options.beta_features
            }
        )

        -- Handle errors
        if err then
            return mapper.map_error(err)
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

        -- Extract content and thinking using the mapper
        local extracted = mapper.extract_response_content(response)

        -- Extract token usage
        local tokens = mapper.extract_usage(response)

        -- Map finish reason to standardized format
        local finish_reason = mapper.FINISH_REASON_MAP[response.stop_reason] or response.stop_reason

        -- Return successful response with standardized finish reason
        return mapper.format_text_response(
            extracted.content,
            args.model,
            tokens,
            finish_reason,
            response.metadata,
            extracted.thinking
        )
    end
end

-- Return the handler function
return { handler = handler }
