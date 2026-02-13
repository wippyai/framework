local openai_mapper = require("openai_mapper")
local json = require("json")
local test = require("test")

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

                test.eq(#openai_messages, 3)
                test.eq(openai_messages[1].role, "system")
                local sys_content = openai_messages[1].content :: any
                test.eq(sys_content[1].type, "text")
                test.eq(sys_content[1].text, "You are a helpful assistant")
                test.eq(openai_messages[2].role, "user")
                local usr_content = openai_messages[2].content :: any
                test.eq(usr_content[1].text, "Hello")
                test.eq(openai_messages[3].role, "assistant")
                test.eq(openai_messages[3].content, "Hi there!")
            end)

            it("should convert string content to processed format", function()
                local contract_messages = {
                    {
                        role = "user",
                        content = "Simple string message"
                    }
                }

                local openai_messages = openai_mapper.map_messages(contract_messages)

                test.eq(#openai_messages, 1)
                local msg_content = openai_messages[1].content :: any
                test.eq(msg_content[1].type, "text")
                test.eq(msg_content[1].text, "Simple string message")
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

                test.eq(#openai_messages, 1)
                local img_content = openai_messages[1].content :: any
                test.eq(img_content[1].type, "text")
                test.eq(img_content[2].type, "image_url")
                test.eq(img_content[2].image_url.url, "https://example.com/image.jpg")
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

                test.eq(#openai_messages, 1)
                local b64_content = openai_messages[1].content :: any
                test.eq(b64_content[1].type, "image_url")
                test.contains(b64_content[1].image_url.url, "data:image/jpeg;base64,")
                test.contains(b64_content[1].image_url.url, "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==")
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

                test.eq(#openai_messages, 1)
                test.eq(openai_messages[1].role, "assistant")
                test.eq(openai_messages[1].content, "")
                local tool_calls = openai_messages[1].tool_calls :: any
                test.eq(#tool_calls, 2)

                test.eq(tool_calls[1].id, "call_123")
                test.eq(tool_calls[1].type, "function")
                test.eq(tool_calls[1]["function"].name, "get_weather")

                local args1 = json.decode(tostring(tool_calls[1]["function"].arguments))
                test.eq(args1.location, "New York")

                test.eq(tool_calls[2].id, "call_456")
                test.eq(tool_calls[2]["function"].name, "calculate")
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

                test.eq(#openai_messages, 0)
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

                test.eq(#openai_messages, 1)
                local msg = openai_messages[1] :: any
                test.eq(msg.role, "tool")
                test.eq(msg.content, "The weather is sunny")
                test.eq(msg.tool_call_id, "call_123")
                test.eq(msg.name, "get_weather")
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

                test.eq(#openai_messages, 1)
                test.eq(openai_messages[1].role, "tool")
                test.eq(openai_messages[1].content, "Simple string result")
            end)

            it("should convert developer messages to system messages", function()
                local contract_messages = {
                    {
                        role = "developer",
                        content = {{ type = "text", text = "Debug: Use detailed explanations" }}
                    }
                }

                local openai_messages = openai_mapper.map_messages(contract_messages)

                test.eq(#openai_messages, 1)
                test.eq(openai_messages[1].role, "system")
                local dev_content = openai_messages[1].content :: any
                test.eq(dev_content[1].type, "text")
                test.eq(dev_content[1].text, "Debug: Use detailed explanations")
            end)

            it("should handle developer messages for o1-mini with no previous user message", function()
                local contract_messages = {
                    {
                        role = "developer",
                        content = {{ type = "text", text = "Be precise" }}
                    }
                }

                local openai_messages = openai_mapper.map_messages(contract_messages, { model = "o1-mini" })

                test.eq(#openai_messages, 1)
                test.eq(openai_messages[1].role, "system")
                local o1_content = openai_messages[1].content :: any
                test.eq(o1_content[1].type, "text")
                test.eq(o1_content[1].text, "Be precise")
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

                test.eq(#openai_messages, 1)
                test.eq(openai_messages[1].role, "user")
                local kept_content = openai_messages[1].content :: any
                test.eq(kept_content[1].text, "This should be kept")
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

                test.eq(#openai_tools, 2)
                test.eq(openai_tools[1].type, "function")
                test.eq(openai_tools[1]["function"].name, "get_weather")
                test.eq(openai_tools[1]["function"].description, "Get weather information")
                test.eq(openai_tools[1]["function"].parameters.type, "object")
                test.eq(openai_tools[1]["function"].parameters.properties.location.type, "string")

                test.not_nil(tool_map["get_weather"])
                test.not_nil(tool_map["calculate"])
            end)

            it("should handle empty tools array", function()
                local openai_tools, tool_map = openai_mapper.map_tools({})

                test.is_nil(openai_tools)
                test.is_nil(next(tool_map))
            end)

            it("should handle nil tools", function()
                local openai_tools, tool_map = openai_mapper.map_tools(nil)

                test.is_nil(openai_tools)
                test.is_nil(next(tool_map))
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

                test.eq(#openai_tools, 1)
                test.eq(openai_tools[1]["function"].name, "valid_tool")
                test.not_nil(tool_map["valid_tool"])
                test.is_nil(tool_map["invalid_tool"])
            end)
        end)

        describe("Tool Choice Mapping", function()
            local test_tools = {
                { name = "get_weather" },
                { name = "calculate" }
            }

            it("should map auto tool choice", function()
                local choice, error = openai_mapper.map_tool_choice("auto", test_tools)

                test.is_nil(error)
                test.eq(choice, "auto")
            end)

            it("should map none tool choice", function()
                local choice, error = openai_mapper.map_tool_choice("none", test_tools)

                test.is_nil(error)
                test.eq(choice, "none")
            end)

            it("should map any tool choice to required", function()
                local choice, error = openai_mapper.map_tool_choice("any", test_tools)

                test.is_nil(error)
                test.eq(choice, "required")
            end)

            it("should map specific tool name", function()
                local choice, error = openai_mapper.map_tool_choice("get_weather", test_tools)

                test.is_nil(error)
                test.eq(choice.type, "function")
                test.eq(choice["function"].name, "get_weather")
            end)

            it("should error on non-existent tool", function()
                local choice, error = openai_mapper.map_tool_choice("nonexistent_tool", test_tools)

                test.is_nil(choice)
                test.contains(error, "not found")
            end)

            it("should default to auto for nil input", function()
                local choice, error = openai_mapper.map_tool_choice(nil, test_tools)

                test.is_nil(error)
                test.eq(choice, "auto")
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

                test.eq(openai_options.temperature, 0.7)
                test.eq(openai_options.max_tokens, 150)
                test.eq(openai_options.top_p, 0.9)
                test.eq(openai_options.frequency_penalty, 0.5)
                test.eq(openai_options.presence_penalty, 0.3)
                test.not_nil(openai_options.stop)
                test.eq(#openai_options.stop, 2)
                test.eq(openai_options.stop[1], "STOP")
                test.eq(openai_options.stop[2], "END")
                test.eq(openai_options.seed, 42)
                test.eq(openai_options.user, "test-user")
            end)

            it("should handle reasoning model options", function()
                local contract_options = {
                    reasoning_model_request = true,
                    thinking_effort = 50,
                    max_tokens = 100,
                    temperature = 0.5 -- Should be ignored for reasoning models
                }

                local openai_options = openai_mapper.map_options(contract_options)

                test.eq(openai_options.max_completion_tokens, 100)
                test.is_nil(openai_options.max_tokens)
                test.eq(openai_options.reasoning_effort, "medium")
                test.is_nil(openai_options.temperature)
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

                    test.eq(openai_options.reasoning_effort, case.expected)
                end
            end)

            it("should handle nil options", function()
                local openai_options = openai_mapper.map_options(nil)

                test.is_nil(next(openai_options))
            end)

            it("should handle empty options", function()
                local openai_options = openai_mapper.map_options({})

                test.is_nil(next(openai_options))
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

                test.eq(#contract_tool_calls, 2)

                local tc1 = contract_tool_calls[1]
                if tc1 then
                    test.eq(tc1.id, "call_123")
                    test.eq(tc1.name, "get_weather")
                    test.eq(tc1.arguments.location, "New York")
                    test.eq(tc1.arguments.units, "celsius")
                end

                local tc2 = contract_tool_calls[2]
                if tc2 then
                    test.eq(tc2.id, "call_456")
                    test.eq(tc2.name, "calculate")
                    test.eq(tc2.arguments.expression, "2+2")
                end
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

                test.eq(#contract_tool_calls, 1)
                local tc = contract_tool_calls[1]
                if tc then
                    test.eq(tc.id, "call_123")
                    test.eq(tc.name, "test_tool")
                    test.not_nil(tc.arguments)
                    test.is_nil(next(tc.arguments))
                end
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

                test.eq(#contract_tool_calls, 1)
                local tc = contract_tool_calls[1]
                if tc then
                    test.not_nil(tc.arguments)
                    test.is_nil(next(tc.arguments))
                end
            end)

            it("should handle nil tool calls", function()
                local contract_tool_calls = openai_mapper.map_tool_calls(nil, {})

                test.eq(#contract_tool_calls, 0)
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
                    test.eq(result, case.expected)
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

                test.eq(contract_tokens.prompt_tokens, 100)
                test.eq(contract_tokens.completion_tokens, 50)
                test.eq(contract_tokens.total_tokens, 150)
                test.eq(contract_tokens.cache_creation_input_tokens, 0)
                test.eq(contract_tokens.cache_read_input_tokens, 0)
                test.eq(contract_tokens.thinking_tokens, 0)
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

                test.eq(contract_tokens.thinking_tokens, 20)
                test.eq(contract_tokens.prompt_tokens, 100)
                test.eq(contract_tokens.completion_tokens, 80)
                test.eq(contract_tokens.total_tokens, 200)
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

                test.eq(contract_tokens.cache_read_input_tokens, 30)
                test.eq(contract_tokens.cache_creation_input_tokens, 70)
                test.eq(contract_tokens.prompt_tokens, 70) -- adjusted: total minus cached
                test.eq(contract_tokens.completion_tokens, 50)
            end)

            it("should handle nil usage", function()
                local contract_tokens = openai_mapper.map_tokens(nil)

                test.is_nil(contract_tokens)
            end)

            it("should handle partial usage data", function()
                local openai_usage = {
                    prompt_tokens = 50
                    -- Missing other fields
                }

                local contract_tokens = openai_mapper.map_tokens(openai_usage)

                test.eq(contract_tokens.prompt_tokens, 50)
                test.eq(contract_tokens.completion_tokens, 0)
                test.eq(contract_tokens.total_tokens, 0)
                test.eq(contract_tokens.thinking_tokens, 0)
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
                local contract_response = openai_mapper.map_success_response(openai_response, context) :: any

                test.is_true(contract_response.success)
                test.eq(contract_response.result.content, "Hello, world!")
                test.not_nil(contract_response.result.tool_calls)
                test.eq(#contract_response.result.tool_calls, 0)
                test.eq(contract_response.finish_reason, "stop")
                test.eq(contract_response.tokens.prompt_tokens, 10)
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

                local contract_response = openai_mapper.map_success_response(openai_response, context) :: any

                test.is_true(contract_response.success)
                test.eq(contract_response.result.content, "I'll help with that.")
                local tc = contract_response.result.tool_calls :: any
                test.eq(#tc, 1)
                test.eq(tc[1].name, "calculate")
                test.eq(contract_response.finish_reason, "tool_call")
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
                local contract_response = openai_mapper.map_success_response(openai_response, context) :: any

                test.is_false(contract_response.success)
                test.eq(contract_response.error, "content_filtered")
                test.contains(contract_response.error_message, "refused")
                test.contains(contract_response.error_message, "I cannot assist with that request.")
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

                    test.is_false(contract_response.success)
                    test.eq(contract_response.error, case.error_type)
                    test.eq(contract_response.error_message, case.message)
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

                    test.is_false(contract_response.success)
                    test.eq(contract_response.error, case.error_type)
                end
            end)

            it("should handle nil error", function()
                local contract_response = openai_mapper.map_error_response(nil)

                test.is_false(contract_response.success)
                test.eq(contract_response.error, "server_error")
                test.eq(contract_response.error_message, "Unknown OpenAI error")
                test.not_nil(contract_response.metadata)
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
