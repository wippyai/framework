local generate_handler = require("generate_handler")
local json = require("json")
local test = require("test")

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

                local response, err = generate_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Invalid")
                test.contains(tostring(err:message()), "Model is required")
            end)

            it("should require messages parameter", function()
                local contract_args = {
                    model = "gpt-4o-mini"
                }

                local response, err = generate_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Invalid")
                test.contains(tostring(err:message()), "Messages are required")
            end)

            it("should reject empty messages array", function()
                local contract_args = {
                    model = "gpt-4o-mini",
                    messages = {}
                }

                local response, err = generate_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Invalid")
                test.contains(tostring(err:message()), "Messages are required")
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
                        test.contains(tostring(url), "chat/completions")

                        local payload = json.decode(tostring(options.body))
                        test.eq(payload.model, "gpt-4o-mini")
                        test.not_nil(payload.messages)

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

                test.is_true(response.success)
                assert(response.success)
                test.eq(response.result.content, "Hello! How can I help you today!")
                test.eq(response.tokens.prompt_tokens, 12)
                test.eq(response.tokens.completion_tokens, 8)
                test.eq(response.tokens.total_tokens, 20)
                test.eq(response.finish_reason, "stop")
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
                        local payload = json.decode(tostring(options.body))
                        test.eq(payload.temperature, 0.3)
                        test.eq(payload.max_tokens, 50)
                        test.eq(payload.top_p, 0.9)
                        test.eq(payload.frequency_penalty, 0.5)
                        test.eq(payload.presence_penalty, 0.2)
                        test.not_nil(payload.stop)
                        test.eq(payload.stop[1], "STOP")

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

                test.is_true(response.success)
                assert(response.success)
                test.eq(response.result.content, "Response")
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
                        local payload = json.decode(tostring(options.body))
                        test.eq(payload.model, "o1-mini")
                        test.eq(payload.reasoning_effort, "medium")
                        test.eq(payload.max_completion_tokens, 100)
                        test.is_nil(payload.max_tokens)
                        test.eq(payload.temperature, 0.7)

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
                    accepts = { thinking = "adaptive" },
                    options = {
                        thinking_effort = 50,
                        max_tokens = 100,
                        temperature = 0.7
                    }
                }

                local response = generate_handler.handler(contract_args)

                test.is_true(response.success)
                assert(response.success)
                test.eq(response.tokens.thinking_tokens, 10)
                test.eq(response.tokens.total_tokens, 50)
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
                        local payload = json.decode(tostring(options.body))
                        test.not_nil(payload.tools)
                        test.eq(#payload.tools, 1)
                        test.eq(payload.tools[1].type, "function")
                        test.eq(payload.tools[1]["function"].name, "calculate")

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

                test.is_true(response.success)
                assert(response.success)
                test.eq(response.result.content, "I'll help with that calculation.")
                test.not_nil(response.result.tool_calls)
                test.eq(#response.result.tool_calls, 1)
                assert(response.result.tool_calls[1])
                test.eq(response.result.tool_calls[1].name, "calculate")
                test.eq(response.result.tool_calls[1].arguments.expression, "2+2")
                test.eq(response.finish_reason, "tool_call")
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
                        local payload = json.decode(tostring(options.body))
                        test.not_nil(payload.tool_choice)
                        test.eq(payload.tool_choice.type, "function")
                        test.eq(payload.tool_choice["function"].name, "calculate")

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

                test.is_true(response.success)
                assert(response.success)
                assert(response.result.tool_calls[1])
                test.eq(response.result.tool_calls[1].name, "calculate")
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
                        test.is_true(options.stream)

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

                test.is_true(response.success)
                assert(response.success)
                test.eq(response.result.content, "Hello world")
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

                test.is_true(response.success)
                assert(response.success)
                test.not_nil(response.result.tool_calls)
                test.eq(#response.result.tool_calls, 1)
                assert(response.result.tool_calls[1])
                test.eq(response.result.tool_calls[1].name, "calculate")
                test.eq(response.finish_reason, "tool_call")
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

                local response, err = generate_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "PermissionDenied")
                test.contains(tostring(err:message()), "Invalid API key")
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

                local response, err = generate_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "NotFound")
                test.contains(tostring(err:message()), "does not exist")
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

                local response, err = generate_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Invalid")
                test.contains(tostring(err:message()), "context length")
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

                local response, err = generate_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "RateLimited")
                test.contains(tostring(err:message()), "Rate limit")
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

                local response, err = generate_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Unavailable")
                test.contains(tostring(err:message()), "Invalid OpenAI response structure")
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
                        test.contains(tostring(url), "https://custom.openai.proxy/v1/chat/completions")
                        test.eq(options.headers["Authorization"], "Bearer custom-key")
                        test.eq(options.headers["OpenAI-Organization"], "org-custom")

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

                test.is_true(response.success)
                assert(response.success)
                test.eq(response.result.content, "Response")
            end)
        end)

        describe("Stream fallback signals", function()
            local real_client
            local streamed_args = {
                model = "llama-3",
                messages = { { role = "user", content = { { type = "text", text = "Hi" } } } },
                stream = { reply_to = "test-process", topic = "test_stream" }
            }

            before_each(function()
                real_client = generate_handler._client
            end)

            after_each(function()
                generate_handler._client = real_client
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
                    request = function() return { stream = {}, metadata = {} } end,
                    process_stream = process_stream
                }
            end

            it("marks a request error on a streaming call as not started", function()
                generate_handler._client = {
                    request = function() return nil, { status_code = 429, message = "Too many requests" } end
                }
                local response, err = generate_handler.handler(streamed_args)
                test.is_nil(response)
                local details = (err :: any):details()
                test.is_false(details.stream_started)
                test.eq(details.error_type, "rate_limit_exceeded")
            end)

            it("leaves stream_started unset on a request error without streaming", function()
                generate_handler._client = {
                    request = function() return nil, { status_code = 500, message = "Server error" } end
                }
                local _, err = generate_handler.handler({
                    model = "llama-3",
                    messages = { { role = "user", content = { { type = "text", text = "Hi" } } } }
                })
                test.is_nil((err :: any):details().stream_started)
            end)

            it("holds the error chunk back when the stream fails before anything was sent", function()
                local streamer = recording_streamer(false)
                stream_with(streamer, function(_, callbacks)
                    callbacks.on_content("He")
                    callbacks.on_error({ message = "Overloaded" })
                    return nil, "Overloaded"
                end)
                local response, err = generate_handler.handler(streamed_args)
                test.is_nil(response)
                test.eq(#streamer.errors_sent, 0)
                local details = (err :: any):details()
                test.is_false(details.stream_started)
                test.eq(details.deferred_error_message, "Overloaded")
                test.not_nil(details.deferred_error_type)
            end)

            it("sends the error chunk once part of the answer reached the client", function()
                local streamer = recording_streamer(true)
                stream_with(streamer, function(_, callbacks)
                    callbacks.on_reasoning("thinking")
                    callbacks.on_error({ message = "stream broke" })
                    return nil, "stream broke"
                end)
                local _, err = generate_handler.handler(streamed_args)
                test.eq(#streamer.errors_sent, 1)
                test.eq(streamer.errors_sent[1].message, "stream broke")
                local details = (err :: any):details()
                test.is_true(details.stream_started)
                test.is_nil(details.deferred_error_type)
            end)

            it("reports a streamer failure as a server error that does not allow fallback", function()
                generate_handler._output = { streamer = function() return nil, "PID is required for streamer" end }
                generate_handler._client = {
                    request = function() return { stream = {}, metadata = {} } end
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
