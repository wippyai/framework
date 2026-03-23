local generate_handler = require("generate_handler")
local json = require("json")

local function define_tests()
    describe("Bedrock Generate Handler", function()

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
                test.contains(response.error_message, "Messages are required")
            end)
        end)

        describe("Basic Text Generation", function()
            it("should pass model to client.request as first argument", function()
                local captured_model = nil
                generate_handler._client = {
                    request = function(model_id, payload, options)
                        captured_model = model_id
                        return {
                            content = {
                                { type = "text", text = "Hello!" }
                            },
                            stop_reason = "end_turn",
                            usage = { input_tokens = 10, output_tokens = 5 },
                            metadata = {}
                        }
                    end
                }

                generate_handler.handler({
                    model = "us.anthropic.claude-haiku-4-5-20251001-v1:0",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Hi" } } }
                    }
                })

                test.eq(captured_model, "us.anthropic.claude-haiku-4-5-20251001-v1:0")
            end)

            it("should not include model field in payload", function()
                local captured_payload = nil
                generate_handler._client = {
                    request = function(model_id, payload, options)
                        captured_payload = payload
                        return {
                            content = {
                                { type = "text", text = "Hello!" }
                            },
                            stop_reason = "end_turn",
                            usage = { input_tokens = 10, output_tokens = 5 },
                            metadata = {}
                        }
                    end
                }

                generate_handler.handler({
                    model = "us.anthropic.claude-haiku-4-5-20251001-v1:0",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Hi" } } }
                    }
                })

                test.is_nil((captured_payload :: any).model)
            end)

            it("should map response correctly", function()
                generate_handler._client = {
                    request = function(model_id, payload, options)
                        return {
                            content = {
                                { type = "text", text = "Generated response" }
                            },
                            stop_reason = "end_turn",
                            usage = {
                                input_tokens = 12,
                                output_tokens = 8
                            },
                            metadata = { request_id = "req_bedrock_123" }
                        }
                    end
                }

                local response = generate_handler.handler({
                    model = "us.anthropic.claude-haiku-4-5-20251001-v1:0",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Hello" } } }
                    }
                })

                test.is_true(response.success)
                assert(response.success)
                test.eq(response.result.content, "Generated response")
                test.not_nil(response.result.tool_calls)
                test.eq(#response.result.tool_calls, 0)
                test.eq(response.tokens.prompt_tokens, 12)
                test.eq(response.tokens.completion_tokens, 8)
                test.eq(response.tokens.total_tokens, 20)
                test.eq(response.finish_reason, "stop")
                test.eq(response.metadata.request_id, "req_bedrock_123")
            end)
        end)

        describe("Custom Options", function()
            it("should pass max_tokens to payload", function()
                local captured_payload = nil
                generate_handler._client = {
                    request = function(model_id, payload, options)
                        captured_payload = payload
                        return {
                            content = { { type = "text", text = "Response" } },
                            stop_reason = "end_turn",
                            usage = { input_tokens = 5, output_tokens = 3 },
                            metadata = {}
                        }
                    end
                }

                generate_handler.handler({
                    model = "us.anthropic.claude-haiku-4-5-20251001-v1:0",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Test" } } }
                    },
                    options = { max_tokens = 500 }
                })

                test.eq((captured_payload :: any).max_tokens, 500)
            end)

            it("should pass temperature to payload", function()
                local captured_payload = nil
                generate_handler._client = {
                    request = function(model_id, payload, options)
                        captured_payload = payload
                        return {
                            content = { { type = "text", text = "Response" } },
                            stop_reason = "end_turn",
                            usage = { input_tokens = 5, output_tokens = 3 },
                            metadata = {}
                        }
                    end
                }

                generate_handler.handler({
                    model = "us.anthropic.claude-haiku-4-5-20251001-v1:0",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Test" } } }
                    },
                    options = { temperature = 0.7 }
                })

                test.eq((captured_payload :: any).temperature, 0.7)
            end)

            it("should pass top_p to payload", function()
                local captured_payload = nil
                generate_handler._client = {
                    request = function(model_id, payload, options)
                        captured_payload = payload
                        return {
                            content = { { type = "text", text = "Response" } },
                            stop_reason = "end_turn",
                            usage = { input_tokens = 5, output_tokens = 3 },
                            metadata = {}
                        }
                    end
                }

                generate_handler.handler({
                    model = "us.anthropic.claude-haiku-4-5-20251001-v1:0",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Test" } } }
                    },
                    options = { top_p = 0.9 }
                })

                test.eq((captured_payload :: any).top_p, 0.9)
            end)
        end)

        describe("Tool Calling", function()
            it("should include tools in payload", function()
                local captured_payload = nil
                generate_handler._client = {
                    request = function(model_id, payload, options)
                        captured_payload = payload
                        return {
                            content = {
                                {
                                    type = "tool_use",
                                    id = "toolu_123",
                                    name = "get_weather",
                                    input = { location = "NYC" }
                                }
                            },
                            stop_reason = "tool_use",
                            usage = { input_tokens = 20, output_tokens = 15 },
                            metadata = {}
                        }
                    end
                }

                generate_handler.handler({
                    model = "us.anthropic.claude-haiku-4-5-20251001-v1:0",
                    messages = {
                        { role = "user", content = { { type = "text", text = "What's the weather?" } } }
                    },
                    tools = {
                        {
                            name = "get_weather",
                            description = "Get the weather",
                            schema = {
                                type = "object",
                                properties = {
                                    location = { type = "string" }
                                },
                                required = { "location" }
                            }
                        }
                    }
                })

                test.not_nil((captured_payload :: any).tools)
                test.is_true(#(captured_payload :: any).tools > 0)
            end)

            it("should map tool calls in response", function()
                generate_handler._client = {
                    request = function(model_id, payload, options)
                        return {
                            content = {
                                {
                                    type = "tool_use",
                                    id = "toolu_abc",
                                    name = "get_weather",
                                    input = { location = "San Francisco" }
                                }
                            },
                            stop_reason = "tool_use",
                            usage = { input_tokens = 25, output_tokens = 18 },
                            metadata = {}
                        }
                    end
                }

                local response = generate_handler.handler({
                    model = "us.anthropic.claude-haiku-4-5-20251001-v1:0",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Weather in SF?" } } }
                    },
                    tools = {
                        {
                            name = "get_weather",
                            description = "Get the weather",
                            schema = {
                                type = "object",
                                properties = {
                                    location = { type = "string" }
                                },
                                required = { "location" }
                            }
                        }
                    }
                })

                test.is_true(response.success)
                assert(response.success)
                test.not_nil(response.result.tool_calls)
                test.eq(#response.result.tool_calls, 1)
                test.eq(response.result.tool_calls[1].name, "get_weather")
                test.eq(response.finish_reason, "tool_call")
            end)
        end)

        describe("System Messages", function()
            it("should pass system messages in payload", function()
                local captured_payload = nil
                generate_handler._client = {
                    request = function(model_id, payload, options)
                        captured_payload = payload
                        return {
                            content = { { type = "text", text = "I am helpful!" } },
                            stop_reason = "end_turn",
                            usage = { input_tokens = 20, output_tokens = 5 },
                            metadata = {}
                        }
                    end
                }

                generate_handler.handler({
                    model = "us.anthropic.claude-haiku-4-5-20251001-v1:0",
                    messages = {
                        { role = "system", content = "You are a helpful assistant" },
                        { role = "user", content = { { type = "text", text = "Hello" } } }
                    }
                })

                test.not_nil((captured_payload :: any).system)
            end)
        end)

        describe("Error Handling", function()
            it("should handle API errors", function()
                generate_handler._client = {
                    request = function(model_id, payload, options)
                        return nil, {
                            status_code = 400,
                            message = "Invalid model specified"
                        }
                    end
                }

                local response = generate_handler.handler({
                    model = "invalid-model",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Hello" } } }
                    }
                })

                test.is_false(response.success)
                test.not_nil(response.error)
                test.not_nil(response.error_message)
            end)

            it("should handle rate limiting", function()
                generate_handler._client = {
                    request = function(model_id, payload, options)
                        return nil, {
                            status_code = 429,
                            message = "Rate limit exceeded"
                        }
                    end
                }

                local response = generate_handler.handler({
                    model = "us.anthropic.claude-haiku-4-5-20251001-v1:0",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Hello" } } }
                    }
                })

                test.is_false(response.success)
                test.eq(response.error, "rate_limit_exceeded")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
