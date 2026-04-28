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
                        -- Responses API endpoint
                        test.contains(tostring(url), "/responses")

                        local payload = json.decode(tostring(options.body))
                        test.eq(payload.model, "gpt-4o-mini")
                        -- Responses API uses `input` items, not `messages`
                        test.not_nil(payload.input)
                        test.is_nil(payload.messages)

                        return {
                            status_code = 200,
                            body = json.encode({
                                id = "resp_text_1",
                                status = "completed",
                                output = {
                                    {
                                        type = "message",
                                        role = "assistant",
                                        content = {
                                            { type = "output_text", text = "Hello! How can I help you today!" }
                                        }
                                    }
                                },
                                usage = {
                                    input_tokens = 12,
                                    output_tokens = 8,
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

                local response, err = generate_handler.handler(contract_args)

                test.is_true(response.success)
                assert(response.success)
                test.eq(response.result.content, "Hello! How can I help you today!")
                test.eq(response.tokens.prompt_tokens, 12)
                test.eq(response.tokens.completion_tokens, 8)
                test.eq(response.tokens.total_tokens, 20)
                test.eq(response.finish_reason, "stop")
                test.eq(response.metadata.response_id, "resp_text_1")
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
                        -- Responses API supported sampling parameters
                        test.eq(payload.temperature, 0.3)
                        test.eq(payload.max_output_tokens, 50)
                        test.is_nil(payload.max_tokens)
                        test.is_nil(payload.max_completion_tokens)
                        test.eq(payload.top_p, 0.9)
                        -- Chat-Completions-only sampling fields are filtered out by the mapper
                        test.is_nil(payload.frequency_penalty)
                        test.is_nil(payload.presence_penalty)
                        test.is_nil(payload.stop)
                        test.is_nil(payload.seed)

                        return {
                            status_code = 200,
                            body = json.encode({
                                id = "resp_opts",
                                status = "completed",
                                output = {
                                    {
                                        type = "message",
                                        role = "assistant",
                                        content = { { type = "output_text", text = "Response" } }
                                    }
                                },
                                usage = { input_tokens = 10, output_tokens = 5, total_tokens = 15 }
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
                        stop_sequences = {"STOP"},
                        seed = 42
                    }
                }

                local response, err = generate_handler.handler(contract_args)

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
                        -- Responses API: reasoning.effort, not reasoning_effort; max_output_tokens not max_completion_tokens
                        test.not_nil(payload.reasoning)
                        test.eq(payload.reasoning.effort, "medium")
                        test.is_nil(payload.reasoning_effort)
                        test.eq(payload.max_output_tokens, 100)
                        test.is_nil(payload.max_tokens)
                        test.is_nil(payload.max_completion_tokens)
                        test.is_nil(payload.temperature)

                        return {
                            status_code = 200,
                            body = json.encode({
                                id = "resp_reason",
                                status = "completed",
                                output = {
                                    {
                                        type = "message",
                                        role = "assistant",
                                        content = { { type = "output_text", text = "Reasoning response" } }
                                    }
                                },
                                usage = {
                                    input_tokens = 15,
                                    output_tokens = 25,
                                    output_tokens_details = { reasoning_tokens = 10 },
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

                local response, err = generate_handler.handler(contract_args)

                test.is_true(response.success)
                assert(response.success)
                test.eq(response.tokens.thinking_tokens, 10)
                test.eq(response.tokens.total_tokens, 50)
            end)

            it("should pull system messages into instructions field", function()
                -- Responses API: system messages live in a separate `instructions` field,
                -- not inside the input array.
                generate_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }
                generate_handler._client._env = {
                    get = function(_) return nil end
                }
                generate_handler._client._http_client = {
                    post = function(_, options)
                        local payload = json.decode(tostring(options.body))
                        test.eq(payload.instructions, "Be brief")
                        for _, item in ipairs(payload.input) do
                            test.is_true(item.role ~= "system")
                            test.is_true(item.role ~= "developer")
                        end

                        return {
                            status_code = 200,
                            body = json.encode({
                                id = "r",
                                status = "completed",
                                output = {
                                    { type = "message", role = "assistant", content = { { type = "output_text", text = "ok" } } }
                                },
                                usage = { input_tokens = 1, output_tokens = 1 }
                            }),
                            headers = {}
                        }
                    end
                }

                local response = generate_handler.handler({
                    model = "gpt-4o-mini",
                    messages = {
                        { role = "system", content = "Be brief" },
                        { role = "user", content = "Hi" }
                    }
                })
                test.is_true(response.success)
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
                        -- Responses API: name & parameters are top-level on the tool, no nested .function wrapper
                        test.eq(payload.tools[1].type, "function")
                        test.eq(payload.tools[1].name, "calculate")
                        test.is_nil(payload.tools[1]["function"])
                        test.not_nil(payload.tools[1].parameters)

                        return {
                            status_code = 200,
                            body = json.encode({
                                id = "resp_tool",
                                status = "completed",
                                output = {
                                    {
                                        type = "message",
                                        role = "assistant",
                                        content = { { type = "output_text", text = "I'll help with that calculation." } }
                                    },
                                    {
                                        type = "function_call",
                                        call_id = "call_123",
                                        name = "calculate",
                                        arguments = '{"expression": "2+2"}'
                                    }
                                },
                                usage = {
                                    input_tokens = 15,
                                    output_tokens = 10,
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

                local response, err = generate_handler.handler(contract_args)

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
                        -- Responses API: tool_choice for a specific function is { type = "function", name = "..." }
                        test.eq(payload.tool_choice.type, "function")
                        test.eq(payload.tool_choice.name, "calculate")
                        test.is_nil(payload.tool_choice["function"])

                        return {
                            status_code = 200,
                            body = json.encode({
                                id = "resp_forced",
                                status = "completed",
                                output = {
                                    {
                                        type = "function_call",
                                        call_id = "call_forced",
                                        name = "calculate",
                                        arguments = '{"expression": "forced"}'
                                    }
                                },
                                usage = { input_tokens = 10, output_tokens = 5, total_tokens = 15 }
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

                local response, err = generate_handler.handler(contract_args)

                test.is_true(response.success)
                assert(response.success)
                assert(response.result.tool_calls[1])
                test.eq(response.result.tool_calls[1].name, "calculate")
            end)
        end)

        describe("Streaming Support", function()
            local function build_mock_stream(chunks)
                local s = { chunks = chunks, current = 0 }
                setmetatable(s, {
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
                return s
            end

            it("should handle streaming responses", function()
                local mock_stream = build_mock_stream({
                    'data: {"type":"response.created","response":{"id":"r1","status":"in_progress"}}\n\n',
                    'data: {"type":"response.output_item.added","output_index":0,"item":{"type":"message","id":"msg_1","role":"assistant","content":[]}}\n\n',
                    'data: {"type":"response.output_text.delta","item_id":"msg_1","output_index":0,"content_index":0,"sequence_number":1,"delta":"Hello"}\n\n',
                    'data: {"type":"response.output_text.delta","item_id":"msg_1","output_index":0,"content_index":0,"sequence_number":2,"delta":" world"}\n\n',
                    'data: {"type":"response.completed","response":{"id":"r1","status":"completed","usage":{"input_tokens":3,"output_tokens":2,"total_tokens":5}}}\n\n'
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
                    send_thinking = function(self, chunk) end,
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

                local response, err = generate_handler.handler(contract_args)

                test.is_true(response.success)
                assert(response.success)
                test.eq(response.result.content, "Hello world")
                test.eq(response.finish_reason, "stop")
                test.eq(response.tokens.prompt_tokens, 3)
                test.eq(response.tokens.completion_tokens, 2)
            end)

            it("should handle streaming tool calls", function()
                local mock_stream = build_mock_stream({
                    'data: {"type":"response.created","response":{"id":"r2","status":"in_progress"}}\n\n',
                    'data: {"type":"response.output_item.added","output_index":0,"item":{"type":"message","id":"msg_1","role":"assistant","content":[]}}\n\n',
                    'data: {"type":"response.output_text.delta","item_id":"msg_1","output_index":0,"content_index":0,"sequence_number":1,"delta":"I will help."}\n\n',
                    'data: {"type":"response.output_item.added","output_index":1,"item":{"type":"function_call","id":"fc_1","call_id":"call_123","name":"calculate","arguments":""}}\n\n',
                    'data: {"type":"response.function_call_arguments.delta","item_id":"fc_1","output_index":1,"sequence_number":2,"delta":"{\\"expr\\""}\n\n',
                    'data: {"type":"response.function_call_arguments.delta","item_id":"fc_1","output_index":1,"sequence_number":3,"delta":":\\"2+2\\"}"}\n\n',
                    'data: {"type":"response.function_call_arguments.done","item_id":"fc_1","output_index":1,"sequence_number":4,"name":"calculate","arguments":"{\\"expr\\":\\"2+2\\"}"}\n\n',
                    'data: {"type":"response.completed","response":{"id":"r2","status":"completed","usage":{"input_tokens":5,"output_tokens":4,"total_tokens":9}}}\n\n'
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
                    send_thinking = function(self, chunk) end,
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

                local response, err = generate_handler.handler(contract_args)

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
                            body = json.encode({}), -- Empty response (no output[])
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

                -- Empty/missing output array should yield a server_error from the response mapper
                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Unavailable")
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
                        test.contains(tostring(url), "https://custom.openai.proxy/v1/responses")
                        test.eq(options.headers["Authorization"], "Bearer custom-key")
                        test.eq(options.headers["OpenAI-Organization"], "org-custom")

                        return {
                            status_code = 200,
                            body = json.encode({
                                id = "resp_ctx",
                                status = "completed",
                                output = {
                                    {
                                        type = "message",
                                        role = "assistant",
                                        content = { { type = "output_text", text = "Response" } }
                                    }
                                },
                                usage = { input_tokens = 5, output_tokens = 3, total_tokens = 8 }
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

                test.is_true(response.success)
                assert(response.success)
                test.eq(response.result.content, "Response")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
