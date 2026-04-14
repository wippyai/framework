local generate_handler = require("generate_handler")
local json = require("json")

local function define_tests()
    describe("Bedrock Generate Handler (Converse API)", function()

        after_each(function()
            generate_handler._client = nil
        end)

        describe("Contract Validation", function()
            it("should require model parameter", function()
                local response = generate_handler.handler({
                    messages = { { role = "user", content = { { type = "text", text = "Test" } } } }
                })
                test.is_false(response.success)
                test.eq(response.error, "invalid_request")
                test.contains(response.error_message, "Model is required")
            end)

            it("should require messages parameter", function()
                local response = generate_handler.handler({
                    model = "us.anthropic.claude-haiku-4-5-20251001-v1:0"
                })
                test.is_false(response.success)
                test.eq(response.error, "invalid_request")
                test.contains(response.error_message, "Messages are required")
            end)

            it("should reject empty messages array", function()
                local response = generate_handler.handler({
                    model = "us.anthropic.claude-haiku-4-5-20251001-v1:0",
                    messages = {}
                })
                test.is_false(response.success)
                test.eq(response.error, "invalid_request")
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

                local response = generate_handler.handler({
                    model = "invalid-model",
                    messages = { { role = "user", content = { { type = "text", text = "Hello" } } } }
                })

                test.is_false(response.success)
                test.not_nil(response.error)
            end)

            it("should handle rate limiting", function()
                generate_handler._client = {
                    converse = function(model_id, payload, options)
                        return nil, { status_code = 429, message = "Rate limit exceeded" }
                    end
                }

                local response = generate_handler.handler({
                    model = "test-model",
                    messages = { { role = "user", content = { { type = "text", text = "Hello" } } } }
                })

                test.is_false(response.success)
                test.eq(response.error, "rate_limit_exceeded")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
