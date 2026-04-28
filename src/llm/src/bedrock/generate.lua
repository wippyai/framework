local bedrock_client = require("bedrock_client")
local mapper = require("mapper")
local output = require("output")

local generate_handler = {
    _client = bedrock_client,
    _mapper = mapper,
    _output = output
}

local function handle_streaming(stream_response, context, stream_config, err)
    local streamer, streamer_err = generate_handler._output.streamer(
        tostring(stream_config.reply_to),
        tostring(stream_config.topic),
        stream_config.buffer_size or 10
    )

    if not streamer then
        return nil, err
            :from({ message = streamer_err or "Failed to create streamer", status_code = 500 })
            :build()
    end

    local full_content = ""
    local tool_calls = {}
    local finish_reason = nil
    local final_usage = nil

    local _, stream_err, stream_result = generate_handler._client.process_converse_stream(stream_response, {
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
            local e = err:from(error_info):build()
            streamer:send_error(tostring(e:kind()), tostring(e:message()), nil)
        end,

        on_done = function(result)
            streamer:flush()
            finish_reason = result.finish_reason
            final_usage = result.usage
        end
    })

    if stream_err then
        return nil, err
            :from({ message = stream_err, status_code = 500 })
            :build()
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
    local err = output.errors.generate("bedrock")
        :with_contract(contract_args)
        :classifier(generate_handler._mapper.classify_error)

    if not contract_args.model then
        return nil, err:kind(output.ERROR_TYPE.INVALID_REQUEST):message("Model is required"):build()
    end

    if not contract_args.messages or #contract_args.messages == 0 then
        return nil, err:kind(output.ERROR_TYPE.INVALID_REQUEST):message("Messages are required"):build()
    end

    local context = {
        model = contract_args.model,
        name_to_id_map = {}
    }

    local mapped = generate_handler._mapper.map_messages(contract_args.messages)
    local inference_config, additional_fields = generate_handler._mapper.map_options(contract_args.options or {})

    if not inference_config.maxTokens then
        inference_config.maxTokens = 2000
    end

    local converse_payload = {
        messages = mapped.messages
    }

    if mapped.system then
        converse_payload.system = mapped.system
    end

    if next(inference_config) then
        converse_payload.inferenceConfig = inference_config
    end

    if next(additional_fields) then
        converse_payload.additionalModelRequestFields = additional_fields
    end

    if contract_args.tools and #contract_args.tools > 0 then
        local converse_tools, name_to_id_map = generate_handler._mapper.map_tools(contract_args.tools)

        if converse_tools then
            converse_payload.toolConfig = {
                tools = converse_tools
            }

            local tool_choice = generate_handler._mapper.map_tool_choice(
                contract_args.tool_choice,
                converse_tools
            )
            if tool_choice then
                converse_payload.toolConfig.toolChoice = tool_choice
            end
        end

        context.name_to_id_map = name_to_id_map
    end

    if contract_args.stream and contract_args.stream.reply_to then
        local stream_response, stream_err = generate_handler._client.converse_stream(
            contract_args.model,
            converse_payload,
            { timeout = contract_args.timeout or 600 }
        )

        if stream_err then
            return nil, err:from(stream_err):build()
        end

        return handle_streaming(stream_response, context, contract_args.stream, err)
    end

    local response, request_err = generate_handler._client.converse(
        contract_args.model,
        converse_payload,
        { timeout = contract_args.timeout or 600 }
    )

    if request_err then
        return nil, err:from(request_err):build()
    end

    return generate_handler._mapper.format_success_response(response, context.name_to_id_map)
end

return generate_handler
