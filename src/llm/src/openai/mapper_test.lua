local openai_mapper = require("openai_mapper")
local json = require("json")

local function define_tests()
    describe("OpenAI Mapper", function()

        describe("Message Mapping", function()
            it("should map standard user, assistant, system messages", function()
                local contract_messages = {
                    {
                        role = "system",
                        content = {{ type = "text", text = "You are a helpful assistant" }}
                    },
                    {
                        role = "user",
                        content = {{ type = "text", text = "Hello" }}
                    },
                    {
                        role = "assistant",
                        content = {{ type = "text", text = "Hi there!" }}
                    }
                }

                local openai_messages = openai_mapper.map_messages(contract_messages)

                expect(#openai_messages).to_equal(3)
                expect(openai_messages[1].role).to_equal("system")
                expect(openai_messages[1].content[1].type).to_equal("text")
                expect(openai_messages[1].content[1].text).to_equal("You are a helpful assistant")
                expect(openai_messages[2].role).to_equal("user")
                expect(openai_messages[2].content[1].text).to_equal("Hello")
                expect(openai_messages[3].role).to_equal("assistant")
                expect(openai_messages[3].content[1].text).to_equal("Hi there!")
            end)

            it("should convert string content to processed format", function()
                local contract_messages = {
                    {
                        role = "user",
                        content = "Simple string message"
                    }
                }

                local openai_messages = openai_mapper.map_messages(contract_messages)

                expect(#openai_messages).to_equal(1)
                expect(openai_messages[1].content).to_equal("Simple string message")
            end)

            it("should convert image content to OpenAI format", function()
                local contract_messages = {
                    {
                        role = "user",
                        content = {
                            { type = "text", text = "What's in this image?" },
                            {
                                type = "image",
                                source = {
                                    type = "url",
                                    url = "https://example.com/image.jpg"
                                }
                            }
                        }
                    }
                }

                local openai_messages = openai_mapper.map_messages(contract_messages)

                expect(#openai_messages).to_equal(1)
                expect(openai_messages[1].content[1].type).to_equal("text")
                expect(openai_messages[1].content[2].type).to_equal("image_url")
                expect(openai_messages[1].content[2].image_url.url).to_equal("https://example.com/image.jpg")
            end)

            it("should convert base64 image content with mime type", function()
                local contract_messages = {
                    {
                        role = "user",
                        content = {
                            {
                                type = "image",
                                source = {
                                    type = "base64",
                                    mime_type = "image/jpeg",
                                    data = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
                                }
                            }
                        }
                    }
                }

                local openai_messages = openai_mapper.map_messages(contract_messages)

                expect(#openai_messages).to_equal(1)
                expect(openai_messages[1].content[1].type).to_equal("image_url")
                expect(openai_messages[1].content[1].image_url.url).to_contain("data:image/jpeg;base64,")
                expect(openai_messages[1].content[1].image_url.url).to_contain("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==")
            end)

            it("should consolidate function_call messages into assistant message", function()
                local contract_messages = {
                    {
                        role = "function_call",
                        function_call = {
                            id = "call_123",
                            name = "get_weather",
                            arguments = { location = "New York" }
                        }
                    },
                    {
                        role = "function_call",
                        function_call = {
                            id = "call_456",
                            name = "calculate",
                            arguments = { expression = "2+2" }
                        }
                    }
                }

                local openai_messages = openai_mapper.map_messages(contract_messages)

                expect(#openai_messages).to_equal(1)
                expect(openai_messages[1].role).to_equal("assistant")
                expect(openai_messages[1].content).to_equal("")
                expect(#openai_messages[1].tool_calls).to_equal(2)

                expect(openai_messages[1].tool_calls[1].id).to_equal("call_123")
                expect(openai_messages[1].tool_calls[1].type).to_equal("function")
                expect(openai_messages[1].tool_calls[1]["function"].name).to_equal("get_weather")

                local args1 = json.decode(openai_messages[1].tool_calls[1]["function"].arguments)
                expect(args1.location).to_equal("New York")

                expect(openai_messages[1].tool_calls[2].id).to_equal("call_456")
                expect(openai_messages[1].tool_calls[2]["function"].name).to_equal("calculate")
            end)

            it("should skip function_call messages without id", function()
                local contract_messages = {
                    {
                        role = "function_call",
                        function_call = {
                            name = "get_weather",
                            arguments = { location = "New York" }
                            -- Missing id
                        }
                    }
                }

                local openai_messages = openai_mapper.map_messages(contract_messages)

                expect(#openai_messages).to_equal(0)
            end)

            it("should convert function_result messages to tool messages", function()
                local contract_messages = {
                    {
                        role = "function_result",
                        content = {{ type = "text", text = "The weather is sunny" }},
                        function_call_id = "call_123",
                        name = "get_weather"
                    }
                }

                local openai_messages = openai_mapper.map_messages(contract_messages)

                expect(#openai_messages).to_equal(1)
                expect(openai_messages[1].role).to_equal("tool")
                expect(openai_messages[1].content).to_equal("The weather is sunny")
                expect(openai_messages[1].tool_call_id).to_equal("call_123")
                expect(openai_messages[1].name).to_equal("get_weather")
            end)

            it("should handle string content in function_result", function()
                local contract_messages = {
                    {
                        role = "function_result",
                        content = "Simple string result",
                        function_call_id = "call_123"
                    }
                }

                local openai_messages = openai_mapper.map_messages(contract_messages)

                expect(#openai_messages).to_equal(1)
                expect(openai_messages[1].role).to_equal("tool")
                expect(openai_messages[1].content).to_equal("Simple string result")
            end)

            it("should convert developer messages to system messages", function()
                local contract_messages = {
                    {
                        role = "developer",
                        content = {{ type = "text", text = "Debug: Use detailed explanations" }}
                    }
                }

                local openai_messages = openai_mapper.map_messages(contract_messages)

                expect(#openai_messages).to_equal(1)
                expect(openai_messages[1].role).to_equal("system")
                expect(openai_messages[1].content).to_equal("Debug: Use detailed explanations")
            end)

            it("should handle developer messages for o1-mini with no previous user message", function()
                local contract_messages = {
                    {
                        role = "developer",
                        content = {{ type = "text", text = "Be precise" }}
                    }
                }

                local openai_messages = openai_mapper.map_messages(contract_messages, { model = "o1-mini" })

                expect(#openai_messages).to_equal(1)
                expect(openai_messages[1].role).to_equal("system")
                expect(openai_messages[1].content).to_equal("Be precise")
            end)

            it("should skip unknown message roles", function()
                local contract_messages = {
                    {
                        role = "unknown_role",
                        content = {{ type = "text", text = "This should be skipped" }}
                    },
                    {
                        role = "user",
                        content = {{ type = "text", text = "This should be kept" }}
                    }
                }

                local openai_messages = openai_mapper.map_messages(contract_messages)

                expect(#openai_messages).to_equal(1)
                expect(openai_messages[1].role).to_equal("user")
                expect(openai_messages[1].content[1].text).to_equal("This should be kept")
            end)
        end)

        describe("Tool Mapping", function()
            it("should map contract tools to OpenAI format", function()
                local contract_tools = {
                    {
                        name = "get_weather",
                        description = "Get weather information",
                        schema = {
                            type = "object",
                            properties = {
                                location = { type = "string" },
                                units = { type = "string", enum = {"celsius", "fahrenheit"} }
                            },
                            required = { "location" }
                        }
                    },
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

                local openai_tools, tool_map = openai_mapper.map_tools(contract_tools)

                expect(#openai_tools).to_equal(2)
                expect(openai_tools[1].type).to_equal("function")
                expect(openai_tools[1]["function"].name).to_equal("get_weather")
                expect(openai_tools[1]["function"].description).to_equal("Get weather information")
                expect(openai_tools[1]["function"].parameters.type).to_equal("object")
                expect(openai_tools[1]["function"].parameters.properties.location.type).to_equal("string")

                expect(tool_map["get_weather"]).not_to_be_nil()
                expect(tool_map["calculate"]).not_to_be_nil()
            end)

            it("should handle empty tools array", function()
                local openai_tools, tool_map = openai_mapper.map_tools({})

                expect(openai_tools).to_be_nil()
                expect(next(tool_map)).to_be_nil()
            end)

            it("should handle nil tools", function()
                local openai_tools, tool_map = openai_mapper.map_tools(nil)

                expect(openai_tools).to_be_nil()
                expect(next(tool_map)).to_be_nil()
            end)

            it("should skip tools with missing required fields", function()
                local contract_tools = {
                    {
                        name = "valid_tool",
                        description = "Valid tool",
                        schema = { type = "object" }
                    },
                    {
                        name = "invalid_tool"
                        -- Missing description and schema
                    }
                }

                local openai_tools, tool_map = openai_mapper.map_tools(contract_tools)

                expect(#openai_tools).to_equal(1)
                expect(openai_tools[1]["function"].name).to_equal("valid_tool")
                expect(tool_map["valid_tool"]).not_to_be_nil()
                expect(tool_map["invalid_tool"]).to_be_nil()
            end)
        end)

        describe("Tool Choice Mapping", function()
            local test_tools = {
                { name = "get_weather" },
                { name = "calculate" }
            }

            it("should map auto tool choice", function()
                local choice, error = openai_mapper.map_tool_choice("auto", test_tools)

                expect(error).to_be_nil()
                expect(choice).to_equal("auto")
            end)

            it("should map none tool choice", function()
                local choice, error = openai_mapper.map_tool_choice("none", test_tools)

                expect(error).to_be_nil()
                expect(choice).to_equal("none")
            end)

            it("should map any tool choice to required", function()
                local choice, error = openai_mapper.map_tool_choice("any", test_tools)

                expect(error).to_be_nil()
                expect(choice).to_equal("required")
            end)

            it("should map specific tool name", function()
                local choice, error = openai_mapper.map_tool_choice("get_weather", test_tools)

                expect(error).to_be_nil()
                expect(choice.type).to_equal("function")
                expect(choice["function"].name).to_equal("get_weather")
            end)

            it("should error on non-existent tool", function()
                local choice, error = openai_mapper.map_tool_choice("nonexistent_tool", test_tools)

                expect(choice).to_be_nil()
                expect(error).to_contain("not found")
            end)

            it("should default to auto for nil input", function()
                local choice, error = openai_mapper.map_tool_choice(nil, test_tools)

                expect(error).to_be_nil()
                expect(choice).to_equal("auto")
            end)
        end)

        describe("Options Mapping", function()
            it("should map standard options", function()
                local contract_options = {
                    temperature = 0.7,
                    max_tokens = 150,
                    top_p = 0.9,
                    frequency_penalty = 0.5,
                    presence_penalty = 0.3,
                    stop_sequences = {"STOP", "END"},
                    seed = 42,
                    user = "test-user"
                }

                local openai_options = openai_mapper.map_options(contract_options)

                expect(openai_options.temperature).to_equal(0.7)
                expect(openai_options.max_tokens).to_equal(150)
                expect(openai_options.top_p).to_equal(0.9)
                expect(openai_options.frequency_penalty).to_equal(0.5)
                expect(openai_options.presence_penalty).to_equal(0.3)
                expect(openai_options.stop).not_to_be_nil()
                expect(#openai_options.stop).to_equal(2)
                expect(openai_options.stop[1]).to_equal("STOP")
                expect(openai_options.stop[2]).to_equal("END")
                expect(openai_options.seed).to_equal(42)
                expect(openai_options.user).to_equal("test-user")
            end)

            it("should handle reasoning model options", function()
                local contract_options = {
                    reasoning_model_request = true,
                    thinking_effort = 50,
                    max_tokens = 100,
                    temperature = 0.5 -- Should be ignored for reasoning models
                }

                local openai_options = openai_mapper.map_options(contract_options)

                expect(openai_options.max_completion_tokens).to_equal(100)
                expect(openai_options.max_tokens).to_be_nil()
                expect(openai_options.reasoning_effort).to_equal("medium")
                expect(openai_options.temperature).to_be_nil()
            end)

            it("should map thinking effort levels correctly", function()
                local test_cases = {
                    { effort = 10, expected = "low" },
                    { effort = 24, expected = "low" },
                    { effort = 25, expected = "medium" },
                    { effort = 50, expected = "medium" },
                    { effort = 74, expected = "medium" },
                    { effort = 75, expected = "high" },
                    { effort = 100, expected = "high" }
                }

                for _, case in ipairs(test_cases) do
                    local contract_options = {
                        reasoning_model_request = true,
                        thinking_effort = case.effort
                    }

                    local openai_options = openai_mapper.map_options(contract_options)

                    expect(openai_options.reasoning_effort).to_equal(case.expected)
                end
            end)

            it("should handle nil options", function()
                local openai_options = openai_mapper.map_options(nil)

                expect(next(openai_options)).to_be_nil()
            end)

            it("should handle empty options", function()
                local openai_options = openai_mapper.map_options({})

                expect(next(openai_options)).to_be_nil()
            end)
        end)

        describe("Tool Calls Response Mapping", function()
            it("should map OpenAI tool calls to contract format", function()
                local openai_tool_calls = {
                    {
                        id = "call_123",
                        type = "function",
                        ["function"] = {
                            name = "get_weather",
                            arguments = '{"location": "New York", "units": "celsius"}'
                        }
                    },
                    {
                        id = "call_456",
                        type = "function",
                        ["function"] = {
                            name = "calculate",
                            arguments = '{"expression": "2+2"}'
                        }
                    }
                }

                local tool_name_map = {
                    ["get_weather"] = { name = "get_weather" },
                    ["calculate"] = { name = "calculate" }
                }

                local contract_tool_calls = openai_mapper.map_tool_calls(openai_tool_calls, tool_name_map)

                expect(#contract_tool_calls).to_equal(2)

                expect(contract_tool_calls[1].id).to_equal("call_123")
                expect(contract_tool_calls[1].name).to_equal("get_weather")
                expect(contract_tool_calls[1].arguments.location).to_equal("New York")
                expect(contract_tool_calls[1].arguments.units).to_equal("celsius")

                expect(contract_tool_calls[2].id).to_equal("call_456")
                expect(contract_tool_calls[2].name).to_equal("calculate")
                expect(contract_tool_calls[2].arguments.expression).to_equal("2+2")
            end)

            it("should handle invalid JSON arguments", function()
                local openai_tool_calls = {
                    {
                        id = "call_123",
                        type = "function",
                        ["function"] = {
                            name = "test_tool",
                            arguments = 'invalid json {'
                        }
                    }
                }

                local contract_tool_calls = openai_mapper.map_tool_calls(openai_tool_calls, {})

                expect(#contract_tool_calls).to_equal(1)
                expect(contract_tool_calls[1].id).to_equal("call_123")
                expect(contract_tool_calls[1].name).to_equal("test_tool")
                expect(contract_tool_calls[1].arguments).not_to_be_nil()
                expect(next(contract_tool_calls[1].arguments)).to_be_nil()
            end)

            it("should handle empty arguments", function()
                local openai_tool_calls = {
                    {
                        id = "call_123",
                        type = "function",
                        ["function"] = {
                            name = "test_tool",
                            arguments = ""
                        }
                    }
                }

                local contract_tool_calls = openai_mapper.map_tool_calls(openai_tool_calls, {})

                expect(#contract_tool_calls).to_equal(1)
                expect(contract_tool_calls[1].arguments).not_to_be_nil()
                expect(next(contract_tool_calls[1].arguments)).to_be_nil()
            end)

            it("should handle nil tool calls", function()
                local contract_tool_calls = openai_mapper.map_tool_calls(nil, {})

                expect(#contract_tool_calls).to_equal(0)
            end)
        end)

        describe("Finish Reason Mapping", function()
            it("should map all OpenAI finish reasons correctly", function()
                local test_cases = {
                    { openai = "stop", expected = "stop" },
                    { openai = "length", expected = "length" },
                    { openai = "content_filter", expected = "filtered" },
                    { openai = "tool_calls", expected = "tool_call" },
                    { openai = "unknown_reason", expected = "error" },
                    { openai = nil, expected = "error" }
                }

                for _, case in ipairs(test_cases) do
                    local result = openai_mapper.map_finish_reason(case.openai)
                    expect(result).to_equal(case.expected)
                end
            end)
        end)

        describe("Token Usage Mapping", function()
            it("should map standard token usage", function()
                local openai_usage = {
                    prompt_tokens = 100,
                    completion_tokens = 50,
                    total_tokens = 150
                }

                local contract_tokens = openai_mapper.map_tokens(openai_usage)

                expect(contract_tokens.prompt_tokens).to_equal(100)
                expect(contract_tokens.completion_tokens).to_equal(50)
                expect(contract_tokens.total_tokens).to_equal(150)
                expect(contract_tokens.cache_creation_input_tokens).to_equal(0)
                expect(contract_tokens.cache_read_input_tokens).to_equal(0)
                expect(contract_tokens.thinking_tokens).to_equal(0)
            end)

            it("should map reasoning tokens (thinking tokens)", function()
                local openai_usage = {
                    prompt_tokens = 100,
                    completion_tokens = 80,
                    total_tokens = 200,
                    completion_tokens_details = {
                        reasoning_tokens = 20
                    }
                }

                local contract_tokens = openai_mapper.map_tokens(openai_usage)

                expect(contract_tokens.thinking_tokens).to_equal(20)
                expect(contract_tokens.prompt_tokens).to_equal(100)
                expect(contract_tokens.completion_tokens).to_equal(80)
                expect(contract_tokens.total_tokens).to_equal(200)
            end)

            it("should map cache tokens", function()
                local openai_usage = {
                    prompt_tokens = 100,
                    completion_tokens = 50,
                    total_tokens = 150,
                    prompt_tokens_details = {
                        cached_tokens = 30
                    }
                }

                local contract_tokens = openai_mapper.map_tokens(openai_usage)

                expect(contract_tokens.cache_read_input_tokens).to_equal(30)
                expect(contract_tokens.cache_creation_input_tokens).to_equal(70)
                expect(contract_tokens.prompt_tokens).to_equal(100)
                expect(contract_tokens.completion_tokens).to_equal(50)
            end)

            it("should handle nil usage", function()
                local contract_tokens = openai_mapper.map_tokens(nil)

                expect(contract_tokens).to_be_nil()
            end)

            it("should handle partial usage data", function()
                local openai_usage = {
                    prompt_tokens = 50
                    -- Missing other fields
                }

                local contract_tokens = openai_mapper.map_tokens(openai_usage)

                expect(contract_tokens.prompt_tokens).to_equal(50)
                expect(contract_tokens.completion_tokens).to_equal(0)
                expect(contract_tokens.total_tokens).to_equal(0)
                expect(contract_tokens.thinking_tokens).to_equal(0)
            end)
        end)

        describe("Success Response Mapping", function()
            it("should map text-only response", function()
                local openai_response = {
                    choices = {
                        {
                            message = {
                                content = "Hello, world!"
                            },
                            finish_reason = "stop"
                        }
                    },
                    usage = {
                        prompt_tokens = 10,
                        completion_tokens = 5,
                        total_tokens = 15
                    },
                    metadata = { request_id = "req_test123" }
                }

                local context = { tool_name_map = {} }
                local contract_response = openai_mapper.map_success_response(openai_response, context)

                expect(contract_response.success).to_be_true()
                expect(contract_response.result.content).to_equal("Hello, world!")
                expect(contract_response.result.tool_calls).not_to_be_nil()
                expect(#contract_response.result.tool_calls).to_equal(0)
                expect(contract_response.finish_reason).to_equal("stop")
                expect(contract_response.tokens.prompt_tokens).to_equal(10)
            end)

            it("should map tool call response", function()
                local openai_response = {
                    choices = {
                        {
                            message = {
                                content = "I'll help with that.",
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
                        prompt_tokens = 20,
                        completion_tokens = 10,
                        total_tokens = 30
                    },
                    metadata = { request_id = "req_tool123" }
                }

                local context = {
                    tool_name_map = {
                        ["calculate"] = { name = "calculate" }
                    }
                }

                local contract_response = openai_mapper.map_success_response(openai_response, context)

                expect(contract_response.success).to_be_true()
                expect(contract_response.result.content).to_equal("I'll help with that.")
                expect(#contract_response.result.tool_calls).to_equal(1)
                expect(contract_response.result.tool_calls[1].name).to_equal("calculate")
                expect(contract_response.finish_reason).to_equal("tool_call")
            end)

            it("should handle refusal responses", function()
                local openai_response = {
                    choices = {
                        {
                            message = {
                                refusal = "I cannot assist with that request."
                            },
                            finish_reason = "stop"
                        }
                    },
                    usage = {
                        prompt_tokens = 15,
                        completion_tokens = 8,
                        total_tokens = 23
                    },
                    metadata = { request_id = "req_refusal123" }
                }

                local context = { tool_name_map = {} }
                local contract_response = openai_mapper.map_success_response(openai_response, context)

                expect(contract_response.success).to_be_false()
                expect(contract_response.error).to_equal("content_filtered")
                expect(contract_response.error_message).to_contain("refused")
                expect(contract_response.error_message).to_contain("I cannot assist with that request.")
            end)
        end)

        describe("Error Response Mapping", function()
            it("should map errors by status code", function()
                local test_cases = {
                    { status = 401, error_type = "authentication_error", message = "Invalid API key" },
                    { status = 404, error_type = "model_error", message = "Model not found" },
                    { status = 429, error_type = "rate_limit_exceeded", message = "Rate limit exceeded" },
                    { status = 500, error_type = "server_error", message = "Internal server error" }
                }

                for _, case in ipairs(test_cases) do
                    local openai_error = {
                        status_code = case.status,
                        message = case.message
                    }

                    local contract_response = openai_mapper.map_error_response(openai_error)

                    expect(contract_response.success).to_be_false()
                    expect(contract_response.error).to_equal(case.error_type)
                    expect(contract_response.error_message).to_equal(case.message)
                end
            end)

            it("should map errors by message content", function()
                local test_cases = {
                    { message = "context length exceeded", error_type = "context_length_exceeded" },
                    { message = "maximum context length is 4096 tokens", error_type = "context_length_exceeded" },
                    { message = "string too long", error_type = "context_length_exceeded" },
                    { message = "content policy violation", error_type = "content_filtered" },
                    { message = "content filter triggered", error_type = "content_filtered" }
                }

                for _, case in ipairs(test_cases) do
                    local openai_error = {
                        status_code = 400,
                        message = case.message
                    }

                    local contract_response = openai_mapper.map_error_response(openai_error)

                    expect(contract_response.success).to_be_false()
                    expect(contract_response.error).to_equal(case.error_type)
                end
            end)

            it("should handle nil error", function()
                local contract_response = openai_mapper.map_error_response(nil)

                expect(contract_response.success).to_be_false()
                expect(contract_response.error).to_equal("server_error")
                expect(contract_response.error_message).to_equal("Unknown OpenAI error")
                expect(contract_response.metadata).not_to_be_nil()
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)