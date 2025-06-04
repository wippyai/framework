local openai = require("openai_client")
local output = require("output")
local prompt_mapper = require("prompt_mapper")

-- OpenAI Text Generation Handler
-- Supports both streaming and non-streaming completion
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

    -- Map messages to OpenAI format using the prompt mapper
    messages = prompt_mapper.map_to_openai(messages, {
        model = args.model
    })

    if #messages == 0 then
        return {
            error = output.ERROR_TYPE.INVALID_REQUEST,
            error_message = "No messages provided"
        }
    end

    -- Configure options objects for easier management
    local options = args.options or {}

    -- Check if this is an o* model (OpenAI o-series models)
    local is_o_model = args.model:match("^o%d") ~= nil

    -- Configure request payload
    local payload = {
        model = args.model,
        messages = messages,
        top_p = options.top_p,
        n = options.n,
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
    if options.thinking_effort then
        payload.reasoning_effort = openai.map_thinking_effort(options.thinking_effort)
    end

    -- Remove temperature for o* models
    if is_o_model then
        payload.temperature = nil
    end

    -- Make the request
    local request_options = {
        api_key = args.api_key,
        organization = args.organization,
        timeout = args.timeout or 120,
        base_url = args.endpoint
    }

    -- Handle streaming if requested
    if args.stream and args.stream.reply_to then
        -- Enable streaming in the request
        request_options.stream = true

        -- Create a streamer with the provided reply_to process ID
        local streamer = output.streamer(
            args.stream.reply_to,
            args.stream.topic or "llm_response",
            args.stream.buffer_size or 10
        )

        -- Perform the streaming request
        local response, err = openai.request(
            openai.DEFAULT_CHAT_ENDPOINT,
            payload,
            request_options
        )

        -- Handle request errors
        if err then
            local mapped_error = openai.map_error(err)
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

        -- Process the streaming response
        local stream_content, stream_err, stream_result = openai.process_stream(response, {
            on_content = function(content_chunk)
                streamer:buffer_content(content_chunk)
            end,
            on_error = function(error_info)
                -- Convert error to standard format
                local mapped_error = {
                    error = output.ERROR_TYPE.SERVER_ERROR,
                    error_message = error_info.message or "Error processing stream",
                    code = error_info.code
                }

                -- If error mentions specific parameters, change error type
                if error_info.param and error_info.message then
                    if error_info.message:match("max_tokens") then
                        mapped_error.error = output.ERROR_TYPE.INVALID_REQUEST
                    end
                end

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
            -- If we already sent an error via on_error, just return the same error
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
        return {
            result = stream_content or full_content,
            tokens = tokens, -- Include token usage from the stream
            metadata = response.metadata,
            finish_reason = finish_reason and openai.FINISH_REASON_MAP[finish_reason] or finish_reason,
            streaming = true
        }
    else
        -- Non-streaming request
        local response, err = openai.request(
            openai.DEFAULT_CHAT_ENDPOINT,
            payload,
            request_options
        )

        -- Handle errors - use the map_error function to get standardized error format
        if err then
            return openai.map_error(err)
        end

        -- Check response validity
        if not response or not response.choices or #response.choices == 0 then
            return {
                error = output.ERROR_TYPE.SERVER_ERROR,
                error_message = "Invalid response structure from OpenAI"
            }
        end

        -- Extract content from first choice
        local first_choice = response.choices[1]
        local content = nil
        if first_choice and first_choice.message and first_choice.message.content then
            content = first_choice.message.content
        else
            return {
                error = output.ERROR_TYPE.SERVER_ERROR,
                error_message = "No content in OpenAI response"
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

        -- Use the finish reason map from the client
        local finish_reason = openai.FINISH_REASON_MAP[first_choice.finish_reason] or first_choice.finish_reason

        -- Return successful response with standardized finish reason
        return {
            result = content,
            tokens = tokens,
            metadata = response.metadata,
            finish_reason = finish_reason
        }
    end
end

-- Return the handler function
return { handler = handler }