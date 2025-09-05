local openai_client = require("openai_client")
local openai_mapper = require("openai_mapper")
local output = require("output")

local generate_handler = {
    _client = openai_client,
    _mapper = openai_mapper,
    _output = output
}

---@param stream_response table OpenAI stream response
---@param context table Response mapping context
---@param stream_config table Stream configuration
---@return table Contract-compliant response
local function handle_streaming(stream_response, context, stream_config)
    local streamer = generate_handler._output.streamer(
        stream_config.reply_to,
        stream_config.topic,
        stream_config.buffer_size or 10
    )

    local full_content = ""
    local tool_calls = {}
    local finish_reason = nil
    local final_usage = nil
    local reasoning_details = nil

    local stream_content, stream_err, stream_result = generate_handler._client.process_stream(stream_response, {
        on_content = function(chunk)
            streamer:buffer_content(chunk)
            full_content = full_content .. chunk
        end,

        on_tool_call = function(tool_info)
            local mapped_calls = generate_handler._mapper.map_tool_calls({
                {
                    id = tool_info.id,
                    ["function"] = {
                        name = tool_info.name,
                        arguments = tool_info.arguments
                    }
                }
            }, context.tool_name_map)

            if mapped_calls[1] then
                table.insert(tool_calls, mapped_calls[1])
                streamer:send_tool_call(
                    mapped_calls[1].name,
                    mapped_calls[1].arguments,
                    mapped_calls[1].id
                )
            end
        end,

        on_reasoning = function(reasoning_chunk)
            -- Send reasoning content via streamer if available
            if streamer.send_thinking then
                streamer:send_thinking(reasoning_chunk)
            end
        end,

        on_error = function(error_info)
            local error_response = generate_handler._mapper.map_error_response(error_info)
            streamer:send_error(error_response.error, error_response.error_message)
        end,

        on_done = function(result)
            streamer:flush()
            finish_reason = result.finish_reason
            final_usage = result.usage
            reasoning_details = result.reasoning_details
        end
    })

    if stream_err then
        return generate_handler._mapper.map_error_response({
            message = stream_err,
            status_code = 500
        })
    end

    -- Build contract-compliant success response
    local response = {
        success = true,
        result = {
            content = full_content,
            tool_calls = tool_calls
        },
        tokens = generate_handler._mapper.map_tokens(final_usage),
        finish_reason = #tool_calls > 0 and output.FINISH_REASON.TOOL_CALL or generate_handler._mapper.map_finish_reason(finish_reason),
        metadata = stream_response.metadata or {}
    }

    -- Add reasoning metadata if present (OpenRouter)
    if reasoning_details then
        -- Use the mapper's extract_reasoning_text function for consistency
        response.metadata.thinking = generate_handler._mapper.extract_reasoning_text(reasoning_details)
        response.metadata.reasoning_details = reasoning_details
    end

    return response
end

---@param contract_args table Contract arguments
---@return table Contract-compliant response
function generate_handler.handler(contract_args)
    -- Validate required arguments
    if not contract_args.model then
        return {
            success = false,
            error = output.ERROR_TYPE.INVALID_REQUEST,
            error_message = "Model is required",
            metadata = {}
        }
    end

    if not contract_args.messages or #contract_args.messages == 0 then
        return {
            success = false,
            error = output.ERROR_TYPE.INVALID_REQUEST,
            error_message = "Messages are required",
            metadata = {}
        }
    end

    -- Create context for response mapping
    local context = {
        model = contract_args.model,
        has_tools = (contract_args.tools and #contract_args.tools > 0),
        tool_name_map = {}
    }

    -- Map messages using openai_mapper
    local messages = generate_handler._mapper.map_messages(contract_args.messages, {
        model = contract_args.model
    })

    -- Build OpenAI payload using context-driven mapper
    local openai_payload = {
        model = contract_args.model,
        messages = messages
    }

    -- Use mapper for options mapping
    local mapped_options = generate_handler._mapper.map_options(contract_args.options)
    for key, value in pairs(mapped_options) do
        openai_payload[key] = value
    end

    -- Handle tools if present
    if contract_args.tools and #contract_args.tools > 0 then
        local openai_tools, tool_name_map = generate_handler._mapper.map_tools(contract_args.tools)
        local tool_choice, tool_choice_error = generate_handler._mapper.map_tool_choice(
            contract_args.tool_choice,
            contract_args.tools
        )

        if tool_choice_error then
            return {
                success = false,
                error = output.ERROR_TYPE.INVALID_REQUEST,
                error_message = tool_choice_error,
                metadata = {}
            }
        end

        openai_payload.tools = openai_tools
        openai_payload.tool_choice = tool_choice
        context.tool_name_map = tool_name_map
        context.has_tools = true
    end

    -- Configure request options
    local request_options = {
        timeout = contract_args.timeout or 120,
    }

    local stream_config = nil
    if contract_args.stream and contract_args.stream.reply_to then
        request_options.stream = true
        stream_config = contract_args.stream
    end

    -- Make OpenAI request
    local response, request_err = generate_handler._client.request(
        "/chat/completions",
        openai_payload,
        request_options
    )

    if request_err then
        return generate_handler._mapper.map_error_response(request_err)
    end

    -- Handle response
    if stream_config then
        return handle_streaming(response, context, stream_config)
    else
        -- Handle non-streaming response
        local success, mapped_response = pcall(function()
            -- Add reasoning details to response if present
            if response.reasoning_details then
                response.reasoning_details = response.reasoning_details
            end

            return generate_handler._mapper.map_success_response(response, context)
        end)

        if not success then
            return generate_handler._mapper.map_error_response({
                message = mapped_response or "Failed to process OpenAI response",
                status_code = 500
            })
        end

        return mapped_response
    end
end

return generate_handler