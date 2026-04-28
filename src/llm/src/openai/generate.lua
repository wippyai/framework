local openai_client = require("openai_client")
local openai_mapper = require("openai_mapper")
local output = require("output")

local generate_handler = {
    _client = openai_client,
    _mapper = openai_mapper,
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

    local _, stream_err, stream_result = generate_handler._client.process_stream(stream_response, {
        on_content = function(chunk)
            streamer:buffer_content(chunk)
            full_content = full_content .. chunk
        end,

        on_tool_call = function(tool_info)
            local mapped = generate_handler._mapper.map_tool_calls({
                {
                    call_id = tool_info.id,
                    name = tool_info.name,
                    arguments = tool_info.arguments
                }
            })

            if mapped[1] then
                table.insert(tool_calls, mapped[1])
                streamer:send_tool_call(
                    tostring(mapped[1].name),
                    tostring(mapped[1].arguments),
                    tostring(mapped[1].id)
                )
            end
        end,

        on_reasoning = function(reasoning_chunk)
            if streamer.send_thinking then
                streamer:send_thinking(reasoning_chunk)
            end
        end,

        on_error = function(error_info)
            local e = err:from(error_info):build()
            streamer:send_error(tostring(e:kind()), tostring(e:message()), nil)
        end,

        on_done = function(_)
            streamer:flush()
        end
    })

    if stream_err then
        return nil, err
            :from({ message = stream_err, status_code = 500 })
            :build()
    end

    local meta = stream_response.metadata or {}
    if stream_result and stream_result.response_id then
        meta.response_id = stream_result.response_id
    end

    local has_tool_calls = #tool_calls > 0
    local status = stream_result and stream_result.status or "completed"
    local incomplete_reason = stream_result and stream_result.incomplete_reason or nil

    return {
        success = true,
        result = {
            content = full_content,
            tool_calls = tool_calls
        },
        tokens = generate_handler._mapper.map_tokens(stream_result and stream_result.usage),
        finish_reason = generate_handler._mapper.map_finish_reason(status, has_tool_calls, incomplete_reason),
        metadata = meta
    }
end

function generate_handler.handler(contract_args)
    local err = output.errors.generate(contract_args):classifier(generate_handler._mapper.classify_error)

    if not contract_args.model then
        return nil, err:kind(output.ERROR_TYPE.INVALID_REQUEST):message("Model is required"):build()
    end

    if not contract_args.messages or #contract_args.messages == 0 then
        return nil, err:kind(output.ERROR_TYPE.INVALID_REQUEST):message("Messages are required"):build()
    end

    local context = {
        model = contract_args.model,
        has_tools = (contract_args.tools and #contract_args.tools > 0),
        tool_name_map = {},
        err = err
    }

    local instructions = generate_handler._mapper.extract_instructions(contract_args.messages)
    local input_items = generate_handler._mapper.map_messages(contract_args.messages, {
        model = contract_args.model
    })

    local payload = {
        model = contract_args.model,
        input = input_items
    }

    if instructions and instructions ~= "" then
        payload.instructions = instructions
    end

    local mapped_options = generate_handler._mapper.map_options(contract_args.options)
    for key, value in pairs(mapped_options) do
        payload[key] = value
    end

    if contract_args.tools and #contract_args.tools > 0 then
        local strict_default = false
        if contract_args.options and contract_args.options.strict_tools then
            strict_default = true
        end

        local tools, tool_name_map = generate_handler._mapper.map_tools(contract_args.tools, {
            strict_default = strict_default
        })
        local tool_choice, tool_choice_error = generate_handler._mapper.map_tool_choice(
            contract_args.tool_choice,
            contract_args.tools
        )

        if tool_choice_error then
            return nil, err:kind(output.ERROR_TYPE.INVALID_REQUEST):message(tool_choice_error):build()
        end

        payload.tools = tools
        payload.tool_choice = tool_choice
        context.tool_name_map = tool_name_map
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
        "/responses",
        payload,
        request_options
    )

    if request_err then
        return nil, err:from(request_err):build()
    end

    if stream_config then
        return handle_streaming(response, context, stream_config, err)
    end

    local success, mapped_response, mapped_err = pcall(function()
        return generate_handler._mapper.map_success_response(response, context)
    end)

    if not success then
        return nil, err
            :from({ message = mapped_response or "Failed to process Responses API response", status_code = 500 })
            :build()
    end

    if mapped_err then
        return nil, mapped_err
    end

    return mapped_response
end

return generate_handler
