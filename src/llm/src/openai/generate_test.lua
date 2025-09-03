local generate_handler = require("generate_handler")
local json = require("json")

local function define_tests()
    describe("OpenAI Generate Handler", function()

        after_each(function()
            -- Clean up injected dependencies
            generate_handler._client._ctx = nil
            generate_handler._client._env = nil
            generate_handler._client._http_client = nil
            generate_handler._output = nil
        end)

        describe("Contract Argument Validation", function()
            it("should require model parameter", function()
                local contract_args = {
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Hello" }} }
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_contain("Model is required")
            end)

            it("should require messages parameter", function()
                local contract_args = {
                    model = "gpt-4o-mini"
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_contain("Messages are required")
            end)

            it("should reject empty messages array", function()
                local contract_args = {
                    model = "gpt-4o-mini",
                    messages = {}
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_contain("Messages are required")
            end)
        end)

        describe("Text Generation", function()
            it("should handle successful text generation", function()
                generate_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                generate_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                generate_handler._client._http_client = {
                    post = function(url, options)
                        expect(url).to_contain("chat/completions")

                        local payload = json.decode(options.body)
                        expect(payload.model).to_equal("gpt-4o-mini")
                        expect(payload.messages).not_to_be_nil()

                        return {
                            status_code = 200,
                            body = json.encode({
                                choices = {
                                    {
                                        message = {
                                            content = "Hello! How can I help you today!"
                                        },
                                        finish_reason = "stop"
                                    }
                                },
                                usage = {
                                    prompt_tokens = 12,
                                    completion_tokens = 8,
                                    total_tokens = 20
                                }
                            }),
                            headers = { ["X-Request-Id"] = "req_test123" }
                        }
                    end
                }

                local contract_args = {
                    model = "gpt-4o-mini",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Hello" }} }
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.result.content).to_equal("Hello! How can I help you today!")
                expect(response.tokens.prompt_tokens).to_equal(12)
                expect(response.tokens.completion_tokens).to_equal(8)
                expect(response.tokens.total_tokens).to_equal(20)
                expect(response.finish_reason).to_equal("stop")
            end)

            it("should handle options mapping", function()
                generate_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                generate_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                generate_handler._client._http_client = {
                    post = function(url, options)
                        local payload = json.decode(options.body)
                        expect(payload.temperature).to_equal(0.3)
                        expect(payload.max_tokens).to_equal(50)
                        expect(payload.top_p).to_equal(0.9)
                        expect(payload.frequency_penalty).to_equal(0.5)
                        expect(payload.presence_penalty).to_equal(0.2)
                        expect(payload.stop).not_to_be_nil()
                        expect(payload.stop[1]).to_equal("STOP")

                        return {
                            status_code = 200,
                            body = json.encode({
                                choices = {{ message = { content = "Response" }, finish_reason = "stop" }},
                                usage = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "gpt-4o-mini",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Test" }} }
                    },
                    options = {
                        temperature = 0.3,
                        max_tokens = 50,
                        top_p = 0.9,
                        frequency_penalty = 0.5,
                        presence_penalty = 0.2,
                        stop_sequences = {"STOP"}
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.result.content).to_equal("Response")
            end)

            it("should handle reasoning models (o-series)", function()
                generate_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                generate_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                generate_handler._client._http_client = {
                    post = function(url, options)
                        local payload = json.decode(options.body)
                        expect(payload.model).to_equal("o1-mini")
                        expect(payload.reasoning_effort).to_equal("medium")
                        expect(payload.max_completion_tokens).to_equal(100)
                        expect(payload.max_tokens).to_be_nil()
                        expect(payload.temperature).to_be_nil()

                        return {
                            status_code = 200,
                            body = json.encode({
                                choices = {
                                    {
                                        message = { content = "Reasoning response" },
                                        finish_reason = "stop"
                                    }
                                },
                                usage = {
                                    prompt_tokens = 15,
                                    completion_tokens = 25,
                                    completion_tokens_details = { reasoning_tokens = 10 },
                                    total_tokens = 50
                                }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "o1-mini",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Solve this problem" }} }
                    },
                    options = {
                        reasoning_model_request = true,
                        thinking_effort = 50,
                        max_tokens = 100,
                        temperature = 0.7 -- Should be ignored
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.tokens.thinking_tokens).to_equal(10)
                expect(response.tokens.total_tokens).to_equal(50)
            end)
        end)

        describe("Tool Calling", function()
            it("should handle tool calls in response", function()
                generate_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                generate_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                generate_handler._client._http_client = {
                    post = function(url, options)
                        local payload = json.decode(options.body)
                        expect(payload.tools).not_to_be_nil()
                        expect(#payload.tools).to_equal(1)
                        expect(payload.tools[1].type).to_equal("function")
                        expect(payload.tools[1]["function"].name).to_equal("calculate")

                        return {
                            status_code = 200,
                            body = json.encode({
                                choices = {
                                    {
                                        message = {
                                            content = "I'll help with that calculation.",
                                            tool_calls = {
                                                {
                                                    id = "call_123",
                                                    type = "function",
                                                    ["function"] = {
                                                        name = "calculate",
                                                        arguments = '{"expression": "2+2"}'
                                                    }
                                                }
                                            }
                                        },
                                        finish_reason = "tool_calls"
                                    }
                                },
                                usage = {
                                    prompt_tokens = 15,
                                    completion_tokens = 10,
                                    total_tokens = 25
                                }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "gpt-4o-mini",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Calculate 2+2" }} }
                    },
                    tools = {
                        {
                            name = "calculate",
                            description = "Perform calculations",
                            schema = {
                                type = "object",
                                properties = {
                                    expression = { type = "string" }
                                },
                                required = { "expression" }
                            }
                        }
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.result.content).to_equal("I'll help with that calculation.")
                expect(response.result.tool_calls).not_to_be_nil()
                expect(#response.result.tool_calls).to_equal(1)
                expect(response.result.tool_calls[1].name).to_equal("calculate")
                expect(response.result.tool_calls[1].arguments.expression).to_equal("2+2")
                expect(response.finish_reason).to_equal("tool_call")
            end)

            it("should handle tool_choice parameter", function()
                generate_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                generate_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                generate_handler._client._http_client = {
                    post = function(url, options)
                        local payload = json.decode(options.body)
                        expect(payload.tool_choice).not_to_be_nil()
                        expect(payload.tool_choice.type).to_equal("function")
                        expect(payload.tool_choice["function"].name).to_equal("calculate")

                        return {
                            status_code = 200,
                            body = json.encode({
                                choices = {
                                    {
                                        message = {
                                            tool_calls = {
                                                {
                                                    id = "call_forced",
                                                    type = "function",
                                                    ["function"] = {
                                                        name = "calculate",
                                                        arguments = '{"expression": "forced"}'
                                                    }
                                                }
                                            }
                                        },
                                        finish_reason = "tool_calls"
                                    }
                                },
                                usage = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "gpt-4o-mini",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Test" }} }
                    },
                    tools = {
                        {
                            name = "calculate",
                            description = "Calculate",
                            schema = { type = "object" }
                        }
                    },
                    tool_choice = "calculate"
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.result.tool_calls[1].name).to_equal("calculate")
            end)
        end)

        describe("Streaming Support", function()
            it("should handle streaming responses", function()
                local stream_chunks = {
                    'data: {"choices":[{"delta":{"content":"Hello"}}]}\n\n',
                    'data: {"choices":[{"delta":{"content":" world"}}]}\n\n',
                    'data: {"choices":[{"finish_reason":"stop"}]}\n\n',
                    'data: [DONE]\n\n'
                }

                local mock_stream = {
                    chunks = stream_chunks,
                    current = 0
                }

                setmetatable(mock_stream, {
                    __index = {
                        read = function(self)
                            self.current = self.current + 1
                            if self.current <= #self.chunks then
                                return self.chunks[self.current]
                            end
                            return nil
                        end
                    }
                })

                generate_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                generate_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                generate_handler._client._http_client = {
                    post = function(url, options)
                        expect(options.stream).to_be_true()

                        return {
                            status_code = 200,
                            stream = mock_stream,
                            headers = {},
                            metadata = { request_id = "req_stream123" }
                        }
                    end
                }

                local mock_streamer = {
                    buffer_content = function(self, chunk) end,
                    send_tool_call = function(self, name, args, id) end,
                    send_error = function(self, error, message) end,
                    flush = function(self) end
                }

                generate_handler._output = {
                    streamer = function(reply_to, topic, buffer_size)
                        return mock_streamer
                    end
                }

                local contract_args = {
                    model = "gpt-4o-mini",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Hello" }} }
                    },
                    stream = {
                        reply_to = "test-process-id",
                        topic = "test_stream"
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.result.content).to_equal("Hello world")
            end)

            it("should handle streaming tool calls", function()
                local stream_chunks = {
                    'data: {"choices":[{"delta":{"content":"I will help."}}]}\n\n',
                    'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"id":"call_123","type":"function","function":{"name":"calculate"}}]}}]}\n\n',
                    'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"function":{"arguments":"{\\"expr\\""}}]}}]}\n\n',
                    'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"function":{"arguments":":\\"2+2\\"}"}}]}}]}\n\n',
                    'data: {"choices":[{"finish_reason":"tool_calls"}]}\n\n',
                    'data: [DONE]\n\n'
                }

                local mock_stream = {
                    chunks = stream_chunks,
                    current = 0
                }

                setmetatable(mock_stream, {
                    __index = {
                        read = function(self)
                            self.current = self.current + 1
                            if self.current <= #self.chunks then
                                return self.chunks[self.current]
                            end
                            return nil
                        end
                    }
                })

                generate_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                generate_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                generate_handler._client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            stream = mock_stream,
                            headers = {},
                            metadata = {}
                        }
                    end
                }

                local mock_streamer = {
                    buffer_content = function(self, chunk) end,
                    send_tool_call = function(self, name, args, id) end,
                    send_error = function(self, error, message) end,
                    flush = function(self) end
                }

                generate_handler._output = {
                    streamer = function(reply_to, topic, buffer_size)
                        return mock_streamer
                    end
                }

                local contract_args = {
                    model = "gpt-4o-mini",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Calculate 2+2" }} }
                    },
                    tools = {
                        {
                            name = "calculate",
                            description = "Calculate",
                            schema = { type = "object" }
                        }
                    },
                    stream = {
                        reply_to = "test-process-id",
                        topic = "test_stream_tools"
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.result.tool_calls).not_to_be_nil()
                expect(#response.result.tool_calls).to_equal(1)
                expect(response.result.tool_calls[1].name).to_equal("calculate")
                expect(response.finish_reason).to_equal("tool_call")
            end)
        end)

        describe("Error Handling", function()
            it("should handle API authentication errors", function()
                generate_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                generate_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                generate_handler._client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 401,
                            body = json.encode({
                                error = {
                                    message = "Invalid API key provided",
                                    type = "invalid_request_error"
                                }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "gpt-4o-mini",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Test" }} }
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("authentication_error")
                expect(response.error_message).to_contain("Invalid API key")
            end)

            it("should handle model not found errors", function()
                generate_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                generate_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                generate_handler._client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 404,
                            body = json.encode({
                                error = {
                                    message = "The model 'nonexistent-model' does not exist",
                                    type = "invalid_request_error"
                                }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "nonexistent-model",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Test" }} }
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("model_error")
                expect(response.error_message).to_contain("does not exist")
            end)

            it("should handle context length errors", function()
                generate_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                generate_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                generate_handler._client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 400,
                            body = json.encode({
                                error = {
                                    message = "This model's maximum context length is 4096 tokens",
                                    type = "invalid_request_error"
                                }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "gpt-4o-mini",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Very long message" }} }
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("context_length_exceeded")
                expect(response.error_message).to_contain("context length")
            end)

            it("should handle rate limit errors", function()
                generate_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                generate_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                generate_handler._client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 429,
                            body = json.encode({
                                error = {
                                    message = "Rate limit exceeded",
                                    type = "rate_limit_exceeded"
                                }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "gpt-4o-mini",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Test" }} }
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("rate_limit_exceeded")
                expect(response.error_message).to_contain("Rate limit")
            end)

            it("should handle invalid response structure", function()
                generate_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                generate_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                generate_handler._client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = json.encode({}), -- Empty response
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "gpt-4o-mini",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Test" }} }
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("server_error")
                expect(response.error_message).to_contain("Invalid OpenAI response structure")
            end)
        end)

        describe("Context Resolution", function()
            it("should resolve configuration from context", function()
                generate_handler._client._ctx = {
                    all = function()
                        return {
                            api_key_env = "CUSTOM_API_KEY",
                            base_url = "https://custom.openai.proxy/v1",
                            organization = "org-custom",
                            timeout = 90
                        }
                    end
                }

                generate_handler._client._env = {
                    get = function(key)
                        if key == "CUSTOM_API_KEY" then return "custom-key" end
                        return nil
                    end
                }

                generate_handler._client._http_client = {
                    post = function(url, options)
                        expect(url).to_contain("https://custom.openai.proxy/v1/chat/completions")
                        expect(options.headers["Authorization"]).to_equal("Bearer custom-key")
                        expect(options.headers["OpenAI-Organization"]).to_equal("org-custom")

                        return {
                            status_code = 200,
                            body = json.encode({
                                choices = {{ message = { content = "Response" }, finish_reason = "stop" }},
                                usage = { prompt_tokens = 5, completion_tokens = 3, total_tokens = 8 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "gpt-4o-mini",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Test" }} }
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.result.content).to_equal("Response")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)