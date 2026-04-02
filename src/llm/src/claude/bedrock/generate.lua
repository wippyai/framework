local bedrock_client = require("bedrock_client")
local mapper = require("mapper")
local output = require("output")
local json = require("json")

local generate_handler = {
    _client = bedrock_client,
    _mapper = mapper,
    _output = output
}

local function handle_streaming(stream_response, context, stream_config)
    local streamer, streamer_err = generate_handler._output.streamer(
        tostring(stream_config.reply_to),
        tostring(stream_config.topic),
        stream_config.buffer_size or 10
    )

    if not streamer then
        return generate_handler._mapper.map_error_response({
            message = streamer_err or "Failed to create streamer",
            status_code = 500
        })
    end

    local full_content = ""
    local tool_calls = {}
    local finish_reason = nil
    local final_usage = nil

    local stream_content, stream_err, stream_result = generate_handler._client.process_stream(stream_response, {
        on_content = function(chunk)
            streamer:buffer_content(chunk)
            full_content = full_content .. chunk
        end,

        on_thinking = function(chunk)
            streamer:send_thinking(chunk)
        end,

        on_tool_call = function(tool_info)
            local mapped_calls = generate_handler._mapper.map_tool_calls({ tool_info }, context.name_to_id_map)
            if mapped_calls[1] then
                table.insert(tool_calls, mapped_calls[1])
                streamer:send_tool_call(
                    tostring(mapped_calls[1].name),
                    tostring(mapped_calls[1].arguments),
                    tostring(mapped_calls[1].id)
                )
            end
        end,

        on_error = function(error_info)
            local error_response = generate_handler._mapper.map_error_response(error_info)
            streamer:send_error(tostring(error_response.error), tostring(error_response.error_message), nil)
        end,

        on_done = function(result)
            streamer:flush()
            finish_reason = result.finish_reason
            final_usage = result.usage
        end
    })

    if stream_err then
        return generate_handler._mapper.map_error_response({
            message = stream_err,
            status_code = 500
        })
    end

    return generate_handler._mapper.format_streaming_response(
        stream_result,
        context.name_to_id_map,
        final_usage,
        finish_reason,
        stream_response.metadata
    )
end

function generate_handler.handler(contract_args)
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

    local context = {
        model = contract_args.model,
        has_tools = (contract_args.tools and #contract_args.tools > 0),
        name_to_id_map = {}
    }

    local mapped_messages = generate_handler._mapper.map_messages(contract_args.messages)
    local mapped_options = generate_handler._mapper.map_options(contract_args.options or {}, contract_args.model)

    local bedrock_payload = {
        messages = mapped_messages.messages,
        max_tokens = mapped_options.max_tokens or 2000
    }

    if mapped_messages.system then
        bedrock_payload.system = mapped_messages.system
    end

    for k, v in pairs(mapped_options) do
        if k ~= "max_tokens" then
            bedrock_payload[k] = v
        end
    end

    if contract_args.tools and #contract_args.tools > 0 then
        local claude_tools, name_to_id_map = generate_handler._mapper.map_tools(contract_args.tools)
        local tool_choice, tool_choice_error = generate_handler._mapper.map_tool_choice(
            contract_args.tool_choice,
            claude_tools
        )

        if tool_choice_error then
            return {
                success = false,
                error = output.ERROR_TYPE.INVALID_REQUEST,
                error_message = tool_choice_error,
                metadata = {}
            }
        end

        if #claude_tools > 0 then
            bedrock_payload.tools = claude_tools
            if tool_choice then
                bedrock_payload.tool_choice = tool_choice
            end
        end

        context.name_to_id_map = name_to_id_map
        context.has_tools = true
    end

    local request_options = {
        timeout = contract_args.timeout or 600
    }

    local stream_config = nil
    if contract_args.stream and contract_args.stream.reply_to then
        request_options.stream = true
        stream_config = contract_args.stream
    end

    local response, request_err = generate_handler._client.request(
        contract_args.model,
        bedrock_payload,
        request_options
    )

    if request_err then
        return generate_handler._mapper.map_error_response(request_err)
    end

    if stream_config then
        return handle_streaming(response, context, stream_config)
    else
        return generate_handler._mapper.format_success_response(response, contract_args.model, context.name_to_id_map)
    end
end

return generate_handler
