local generate_handler = require("generate_handler")
local json = require("json")

local BINDING_BETA = "thinking-binding-controls-2026-08-01"
local CLAUDE_MODEL = "us.anthropic.claude-opus-5-5-v1:0"

local function history_with_thinking(blocks)
    return {
        { role = "user", content = { { type = "text", text = "Plan the trip" } } },
        {
            role = "assistant",
            content = { { type = "text", text = "Here is the plan." } },
            metadata = { thinking_blocks = blocks }
        },
        { role = "user", content = { { type = "text", text = "Now book it" } } }
    }
end

local SIGNED_THINKING = { type = "thinking", thinking = "Weighing the routes.", signature = "sig-original-1" }

local function converse_response(extra)
    local response = {
        output = { message = { role = "assistant", content = { { text = "Booked." } } } },
        stopReason = "end_turn",
        usage = { inputTokens = 30, outputTokens = 3 },
        metadata = {}
    }
    for k, v in pairs(extra or {}) do response[k] = v end
    return response
end

local function define_tests()
    describe("Bedrock Generate Handler (Converse API)", function()

        after_each(function()
            generate_handler._client = nil
        end)

        describe("Contract Validation", function()
            it("should require model parameter", function()
                local response, err = generate_handler.handler({
                    messages = { { role = "user", content = { { type = "text", text = "Test" } } } }
                })
                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Invalid")
                test.contains(err:message(), "Model is required")
            end)

            it("should require messages parameter", function()
                local response, err = generate_handler.handler({
                    model = "us.anthropic.claude-haiku-4-5-20251001-v1:0"
                })
                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Invalid")
                test.contains(err:message(), "Messages are required")
            end)

            it("should reject empty messages array", function()
                local response, err = generate_handler.handler({
                    model = "us.anthropic.claude-haiku-4-5-20251001-v1:0",
                    messages = {}
                })
                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Invalid")
            end)
        end)

        describe("Converse API Call", function()
            it("should call converse with model as first argument", function()
                local captured_model = nil
                generate_handler._client = {
                    converse = function(model_id, payload, options)
                        captured_model = model_id
                        return {
                            output = { message = { role = "assistant", content = { { text = "Hi" } } } },
                            stopReason = "end_turn",
                            usage = { inputTokens = 5, outputTokens = 2 },
                            metadata = {}
                        }
                    end
                }

                generate_handler.handler({
                    model = "us.anthropic.claude-haiku-4-5-20251001-v1:0",
                    messages = { { role = "user", content = { { type = "text", text = "Hi" } } } }
                })

                test.eq(captured_model, "us.anthropic.claude-haiku-4-5-20251001-v1:0")
            end)

            it("should forward retry to the client request", function()
                local captured_options = nil
                generate_handler._client = {
                    converse = function(model_id, payload, options)
                        captured_options = options
                        return {
                            output = { message = { role = "assistant", content = { { text = "Hi" } } } },
                            stopReason = "end_turn",
                            usage = { inputTokens = 5, outputTokens = 2 },
                            metadata = {}
                        }
                    end
                }

                generate_handler.handler({
                    model = "us.anthropic.claude-haiku-4-5-20251001-v1:0",
                    messages = { { role = "user", content = { { type = "text", text = "Hi" } } } },
                    retry = { attempts = 2, backoff_ms = 0 }
                })

                local options = captured_options :: any
                test.eq(options.retry.attempts, 2)
                test.eq(options.retry.backoff_ms, 0)
            end)

            it("should include inferenceConfig in payload", function()
                local captured_payload = nil
                generate_handler._client = {
                    converse = function(model_id, payload, options)
                        captured_payload = payload
                        return {
                            output = { message = { role = "assistant", content = { { text = "Ok" } } } },
                            stopReason = "end_turn",
                            usage = { inputTokens = 5, outputTokens = 2 },
                            metadata = {}
                        }
                    end
                }

                generate_handler.handler({
                    model = "test-model",
                    messages = { { role = "user", content = { { type = "text", text = "Hi" } } } },
                    options = { temperature = 0.5, max_tokens = 500 }
                })

                test.not_nil((captured_payload :: any).inferenceConfig)
                test.eq((captured_payload :: any).inferenceConfig.temperature, 0.5)
                test.eq((captured_payload :: any).inferenceConfig.maxTokens, 500)
            end)

            it("should map response correctly", function()
                generate_handler._client = {
                    converse = function(model_id, payload, options)
                        return {
                            output = {
                                message = {
                                    role = "assistant",
                                    content = { { text = "Generated text" } }
                                }
                            },
                            stopReason = "end_turn",
                            usage = { inputTokens = 12, outputTokens = 8, totalTokens = 20 },
                            metadata = { request_id = "req_123" }
                        }
                    end
                }

                local response = generate_handler.handler({
                    model = "test-model",
                    messages = { { role = "user", content = { { type = "text", text = "Hello" } } } }
                })

                test.is_true(response.success)
                test.eq(response.result.content, "Generated text")
                test.eq(#response.result.tool_calls, 0)
                test.eq(response.tokens.prompt_tokens, 12)
                test.eq(response.tokens.completion_tokens, 8)
                test.eq(response.finish_reason, "stop")
            end)

            it("should include system messages in payload", function()
                local captured_payload = nil
                generate_handler._client = {
                    converse = function(model_id, payload, options)
                        captured_payload = payload
                        return {
                            output = { message = { role = "assistant", content = { { text = "Ok" } } } },
                            stopReason = "end_turn",
                            usage = { inputTokens = 10, outputTokens = 2 },
                            metadata = {}
                        }
                    end
                }

                generate_handler.handler({
                    model = "test-model",
                    messages = {
                        { role = "system", content = "Be helpful" },
                        { role = "user", content = { { type = "text", text = "Hello" } } }
                    }
                })

                test.not_nil((captured_payload :: any).system)
                test.eq((captured_payload :: any).system[1].text, "Be helpful")
            end)
        end)

        describe("Tool Calling", function()
            it("should include toolConfig in payload", function()
                local captured_payload = nil
                generate_handler._client = {
                    converse = function(model_id, payload, options)
                        captured_payload = payload
                        return {
                            output = {
                                message = {
                                    role = "assistant",
                                    content = {
                                        { toolUse = { toolUseId = "call_1", name = "get_weather", input = { location = "NYC" } } }
                                    }
                                }
                            },
                            stopReason = "tool_use",
                            usage = { inputTokens = 20, outputTokens = 15 },
                            metadata = {}
                        }
                    end
                }

                generate_handler.handler({
                    model = "test-model",
                    messages = { { role = "user", content = { { type = "text", text = "Weather?" } } } },
                    tools = {
                        { name = "get_weather", description = "Get weather", schema = { type = "object", properties = { location = { type = "string" } } } }
                    }
                })

                test.not_nil((captured_payload :: any).toolConfig)
                test.not_nil((captured_payload :: any).toolConfig.tools)
                test.eq(#(captured_payload :: any).toolConfig.tools, 1)
            end)

            it("should map tool calls in response", function()
                generate_handler._client = {
                    converse = function(model_id, payload, options)
                        return {
                            output = {
                                message = {
                                    role = "assistant",
                                    content = {
                                        { toolUse = { toolUseId = "call_abc", name = "get_weather", input = { location = "SF" } } }
                                    }
                                }
                            },
                            stopReason = "tool_use",
                            usage = { inputTokens = 25, outputTokens = 18 },
                            metadata = {}
                        }
                    end
                }

                local response = generate_handler.handler({
                    model = "test-model",
                    messages = { { role = "user", content = { { type = "text", text = "Weather?" } } } },
                    tools = {
                        { name = "get_weather", description = "Get weather", schema = { type = "object", properties = { location = { type = "string" } } } }
                    }
                })

                test.is_true(response.success)
                test.eq(#response.result.tool_calls, 1)
                test.eq(response.result.tool_calls[1].name, "get_weather")
                test.eq(response.finish_reason, "tool_call")
            end)
        end)

        describe("Error Handling", function()
            it("should handle API errors", function()
                generate_handler._client = {
                    converse = function(model_id, payload, options)
                        return nil, { status_code = 400, message = "Invalid model" }
                    end
                }

                local response, err = generate_handler.handler({
                    model = "invalid-model",
                    messages = { { role = "user", content = { { type = "text", text = "Hello" } } } }
                })

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Invalid")
            end)

            it("should handle rate limiting", function()
                generate_handler._client = {
                    converse = function(model_id, payload, options)
                        return nil, { status_code = 429, message = "Rate limit exceeded" }
                    end
                }

                local response, err = generate_handler.handler({
                    model = "test-model",
                    messages = { { role = "user", content = { { type = "text", text = "Hello" } } } }
                })

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "RateLimited")
            end)
        end)

        describe("Thinking block binding", function()
            local function capture()
                local captured = {}
                generate_handler._client = {
                    converse = function(model_id, payload, options)
                        captured.payload = payload
                        return converse_response()
                    end
                }
                return captured
            end

            it("binds replayed reasoning with drop_block under adaptive thinking", function()
                local captured = capture()

                generate_handler.handler({
                    model = CLAUDE_MODEL,
                    messages = history_with_thinking({ SIGNED_THINKING }),
                    accepts = { thinking = "adaptive" },
                    options = { thinking_effort = 50 }
                })

                local fields = captured.payload.additionalModelRequestFields
                test.eq(fields.thinking.type, "adaptive")
                test.eq(fields.thinking.block_binding.prefix_mismatch_behavior, "drop_block")
                test.eq(#fields.anthropic_beta, 1)
                test.eq(fields.anthropic_beta[1], BINDING_BETA)
                test.eq(#captured.payload.additionalModelResponseFieldPaths, 1)
                test.eq(captured.payload.additionalModelResponseFieldPaths[1], "/input_transformations")
                local replayed = captured.payload.messages[2].content[1].reasoningContent.reasoningText
                test.eq(replayed.text, SIGNED_THINKING.thinking)
                test.eq(replayed.signature, SIGNED_THINKING.signature)
            end)

            it("binds replayed reasoning under budget thinking", function()
                local captured = capture()

                generate_handler.handler({
                    model = CLAUDE_MODEL,
                    messages = history_with_thinking({ SIGNED_THINKING }),
                    options = { thinking_effort = 50 }
                })

                local fields = captured.payload.additionalModelRequestFields
                test.eq(fields.thinking.type, "enabled")
                test.eq(fields.thinking.block_binding.prefix_mismatch_behavior, "drop_block")
                test.eq(fields.anthropic_beta[1], BINDING_BETA)
            end)

            it("binds replayed reasoning on an always route at the model's default effort", function()
                local captured = capture()

                generate_handler.handler({
                    model = CLAUDE_MODEL,
                    messages = history_with_thinking({ SIGNED_THINKING }),
                    accepts = { thinking = "always" },
                    options = { thinking_effort = 0 }
                })

                local fields = captured.payload.additionalModelRequestFields
                test.eq(fields.thinking.type, "adaptive")
                test.is_nil(fields.output_config)
                test.eq(fields.thinking.block_binding.prefix_mismatch_behavior, "drop_block")
                test.eq(fields.anthropic_beta[1], BINDING_BETA)
                test.eq(captured.payload.additionalModelResponseFieldPaths[1], "/input_transformations")
            end)

            it("decides the binding from the thinking object as finally sent", function()
                local captured = capture()
                local real_mapper = generate_handler._mapper
                local fields: any = nil
                generate_handler._mapper = setmetatable({
                    map_options = function(...)
                        local config, additional, adjusted, options_err = real_mapper.map_options(...)
                        fields = additional
                        return config, additional, adjusted, options_err
                    end,
                    map_tools = function(...)
                        fields.thinking.type = "between_tools"
                        return real_mapper.map_tools(...)
                    end
                }, { __index = real_mapper })

                generate_handler.handler({
                    model = CLAUDE_MODEL,
                    messages = history_with_thinking({ SIGNED_THINKING }),
                    tools = { { name = "search", description = "Search", schema = { type = "object" } } },
                    accepts = { thinking = "adaptive" },
                    options = { thinking_effort = 50 }
                })
                generate_handler._mapper = real_mapper

                local sent = captured.payload.additionalModelRequestFields
                test.eq(sent.thinking.type, "between_tools")
                test.is_nil(sent.thinking.block_binding)
                test.is_nil(sent.anthropic_beta)
                test.is_nil(captured.payload.additionalModelResponseFieldPaths)
            end)

            it("rejects a request list field the binding extends when it is not a list", function()
                for _, request in ipairs({
                    { additionalModelRequestFields = { anthropic_beta = "context-1m-2025-08-07" } },
                    { additionalModelResponseFieldPaths = "/stop_sequence" }
                }) do
                    local captured = capture()
                    local response, err = generate_handler.handler({
                        model = CLAUDE_MODEL,
                        messages = history_with_thinking({ SIGNED_THINKING }),
                        accepts = { thinking = "adaptive" },
                        options = { thinking_effort = 50, request = request }
                    })

                    test.is_nil(response)
                    test.eq(err:kind(), "Invalid")
                    test.contains(err:message(), next(request) == "additionalModelRequestFields"
                        and "additionalModelRequestFields.anthropic_beta" or "additionalModelResponseFieldPaths")
                    test.is_nil(captured.payload)
                end
            end)

            it("sends no binding when the history replays no reasoning", function()

                local captured = capture()

                generate_handler.handler({
                    model = CLAUDE_MODEL,
                    messages = history_with_thinking({}),
                    accepts = { thinking = "adaptive" },
                    options = { thinking_effort = 50 }
                })

                local fields = captured.payload.additionalModelRequestFields
                test.is_nil(fields.thinking.block_binding)
                test.is_nil(fields.anthropic_beta)
                test.is_nil(captured.payload.additionalModelResponseFieldPaths)
            end)

            it("never adds a thinking object to carry the binding when the request sends none", function()
                local captured = capture()

                generate_handler.handler({
                    model = CLAUDE_MODEL,
                    messages = history_with_thinking({ SIGNED_THINKING }),
                    accepts = { thinking = "adaptive" },
                    options = { thinking_effort = 0 }
                })

                test.is_nil(captured.payload.additionalModelRequestFields)
                test.is_nil(captured.payload.additionalModelResponseFieldPaths)
                local replayed = captured.payload.messages[2].content[1].reasoningContent.reasoningText
                test.eq(replayed.signature, SIGNED_THINKING.signature)
            end)

            it("reports input_transformations from a streaming response in metadata", function()
                generate_handler._output = {
                    streamer = function()
                        return { buffer_content = function() end, send_thinking = function() end, flush = function() end }
                    end
                }
                generate_handler._client = {
                    converse_stream = function()
                        return { stream = {}, metadata = { request_id = "req_stream" } }, nil
                    end,
                    process_converse_stream = function(_, callbacks)
                        callbacks.on_content("Booked.")
                        local result = {
                            content = "Booked.",
                            finish_reason = "end_turn",
                            usage = { inputTokens = 30, outputTokens = 3 },
                            metadata = {
                                request_id = "req_stream",
                                input_transformations = {
                                    { type = "thinking_dropped", path = "messages.1.content.0", reason = "prefix_binding_mismatch" }
                                }
                            }
                        }
                        callbacks.on_done(result)
                        return "Booked.", nil, result
                    end
                }

                local response = generate_handler.handler({
                    model = CLAUDE_MODEL,
                    messages = history_with_thinking({ SIGNED_THINKING }),
                    accepts = { thinking = "adaptive" },
                    options = { thinking_effort = 50 },
                    stream = { reply_to = "test-process", topic = "binding_stream" }
                })

                test.is_true(response.success)
                test.eq(response.metadata.request_id, "req_stream")
                test.eq(response.metadata.input_transformations[1].reason, "prefix_binding_mismatch")
            end)
        end)

        describe("Stream fallback signals", function()
            local real_output
            local streamed_args = {
                model = "us.anthropic.claude-sonnet-4-6",
                messages = { { role = "user", content = { { type = "text", text = "Hi" } } } },
                stream = { reply_to = "test-process", topic = "test_stream" }
            }

            before_each(function()
                real_output = generate_handler._output
            end)

            after_each(function()
                generate_handler._output = real_output
            end)

            local function recording_streamer(sent_any: boolean): any
                local errors_sent: {any} = {}
                return {
                    sent_any = sent_any,
                    errors_sent = errors_sent,
                    buffer_content = function() end,
                    send_thinking = function() end,
                    send_tool_call = function() end,
                    flush = function() end,
                    send_error = function(_, err_type, message)
                        table.insert(errors_sent, { type = err_type, message = message })
                    end
                }
            end

            local function stream_with(streamer, process_stream)
                generate_handler._output = { streamer = function() return streamer end }
                generate_handler._client = {
                    converse_stream = function() return { stream = {}, metadata = {} }, nil end,
                    process_converse_stream = process_stream
                }
            end

            it("marks a request error on a streaming call as not started", function()
                generate_handler._client = {
                    converse_stream = function() return nil, { status_code = 429, message = "Rate limit exceeded" } end
                }
                local response, err = generate_handler.handler(streamed_args)
                test.is_nil(response)
                local details = (err :: any):details()
                test.is_false(details.stream_started)
                test.eq(details.error_type, "rate_limit_exceeded")
            end)

            it("leaves stream_started unset on a request error without streaming", function()
                generate_handler._client = {
                    converse = function() return nil, { status_code = 503, message = "Unavailable" } end
                }
                local _, err = generate_handler.handler({
                    model = "us.anthropic.claude-sonnet-4-6",
                    messages = { { role = "user", content = { { type = "text", text = "Hi" } } } }
                })
                test.is_nil((err :: any):details().stream_started)
            end)

            it("holds the error chunk back when the stream fails before anything was sent", function()
                local streamer = recording_streamer(false)
                stream_with(streamer, function(_, callbacks)
                    callbacks.on_content("He")
                    callbacks.on_error({ message = "Throttled" })
                    return nil, "Throttled"
                end)
                local response, err = generate_handler.handler(streamed_args)
                test.is_nil(response)
                test.eq(#streamer.errors_sent, 0)
                local details = (err :: any):details()
                test.is_false(details.stream_started)
                test.eq(details.deferred_error_message, "Throttled")
                test.not_nil(details.deferred_error_type)
            end)

            it("sends the error chunk once part of the answer reached the client", function()
                local streamer = recording_streamer(true)
                stream_with(streamer, function(_, callbacks)
                    callbacks.on_thinking("thought")
                    callbacks.on_error({ message = "model stream error" })
                    return nil, "model stream error"
                end)
                local _, err = generate_handler.handler(streamed_args)
                test.eq(#streamer.errors_sent, 1)
                test.eq(streamer.errors_sent[1].message, "model stream error")
                local details = (err :: any):details()
                test.is_true(details.stream_started)
                test.is_nil(details.deferred_error_type)
            end)

            it("reports a streamer failure as a server error that does not allow fallback", function()
                generate_handler._output = { streamer = function() return nil, "PID is required for streamer" end }
                generate_handler._client = {
                    converse_stream = function() return { stream = {}, metadata = {} }, nil end
                }
                local _, err = generate_handler.handler(streamed_args)
                local details = (err :: any):details()
                test.eq(details.error_type, "server_error")
                test.is_nil(details.stream_started)
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
