local generate_handler = require("generate_handler")
local json = require("json")

local function define_tests()
    describe("Claude Generate Handler", function()
        after_each(function()
            -- Clean up injected dependencies
            generate_handler._client = nil
            generate_handler._output = nil
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
                    model = "claude-3-5-sonnet-20241022"
                })
                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Invalid")
                test.contains(err:message(), "Messages are required")
            end)

            it("should reject empty messages array", function()
                local response, err = generate_handler.handler({
                    model = "claude-3-5-sonnet-20241022",
                    messages = {}
                })
                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Invalid")
                test.contains(err:message(), "Messages are required")
            end)
        end)

        describe("Basic Text Generation", function()
            it("should generate text successfully", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        test.eq(endpoint, "/v1/messages")
                        test.eq(payload.model, "claude-3-5-sonnet-20241022")
                        test.not_nil(payload.messages)
                        test.eq(payload.max_tokens, 2000)

                        return {
                            content = {
                                { type = "text", text = "Hello! How can I help you today?" }
                            },
                            stop_reason = "end_turn",
                            usage = {
                                input_tokens = 12,
                                output_tokens = 8
                            },
                            metadata = { request_id = "req_123" }
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Hello" } } }
                    }
                }

                local response = generate_handler.handler(contract_args)

                test.is_true(response.success)
                assert(response.success)
                test.eq(response.result.content, "Hello! How can I help you today?")
                test.not_nil(response.result.tool_calls)
                test.eq(#response.result.tool_calls, 0)
                test.eq(response.tokens.prompt_tokens, 12)
                test.eq(response.tokens.completion_tokens, 8)
                test.eq(response.tokens.total_tokens, 20)
                test.eq(response.finish_reason, "stop")
                test.eq(response.metadata.request_id, "req_123")
            end)

            it("should handle multiple content blocks", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        return {
                            content = {
                                { type = "text", text = "First part. " },
                                { type = "text", text = "Second part." }
                            },
                            stop_reason = "end_turn",
                            usage = { input_tokens = 8, output_tokens = 6 },
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Tell me a story" } } }
                    }
                }

                local response = generate_handler.handler(contract_args)
                test.is_true(response.success)
                assert(response.success)
                test.eq(response.result.content, "First part. Second part.")
            end)

            it("should handle max_tokens finish reason", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        return {
                            content = {
                                { type = "text", text = "Partial response due to limit" }
                            },
                            stop_reason = "max_tokens",
                            usage = { input_tokens = 20, output_tokens = 50 },
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Write a long story" } } }
                    },
                    options = { max_tokens = 50 }
                }

                local response = generate_handler.handler(contract_args)
                test.is_true(response.success)
                assert(response.success)
                test.eq(response.finish_reason, "length")
            end)
        end)

        describe("Options Mapping", function()
            it("should handle basic options correctly", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        test.eq(payload.temperature, 0.7)
                        test.eq(payload.max_tokens, 100)
                        test.eq(payload.top_p, 0.9)
                        test.not_nil(payload.stop_sequences)
                        test.eq(payload.stop_sequences[1], "STOP")
                        test.eq(options.timeout, 60)

                        return {
                            content = { { type = "text", text = "Response with custom options" } },
                            stop_reason = "end_turn",
                            usage = { input_tokens = 10, output_tokens = 5 },
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Test" } } }
                    },
                    options = {
                        temperature = 0.7,
                        max_tokens = 100,
                        top_p = 0.9,
                        stop_sequences = { "STOP" }
                    },
                    timeout = 60
                }

                local response = generate_handler.handler(contract_args)
                test.is_true(response.success)
                assert(response.success)
                test.eq(response.result.content, "Response with custom options")
            end)

            it("should handle thinking models with effort configuration", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        test.eq(payload.model, "claude-3-7-sonnet-20250219")
                        test.not_nil(payload.thinking)
                        test.eq(payload.thinking.type, "enabled")
                        test.gt(payload.thinking.budget_tokens, 1000)
                        test.eq(payload.temperature, 1) -- Required for thinking

                        return {
                            content = {
                                { type = "thinking", thinking = "Let me think about this..." },
                                { type = "text",     text = "After thinking, here's my answer." }
                            },
                            stop_reason = "end_turn",
                            usage = { input_tokens = 15, output_tokens = 25 },
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-7-sonnet-20250219",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Complex question?" } } }
                    },
                    options = {
                        thinking_effort = 50,
                        temperature = 0.5 -- Should be overridden to 1
                    }
                }

                local response = generate_handler.handler(contract_args)
                test.is_true(response.success)
                assert(response.success)
                test.eq(response.result.content, "After thinking, here's my answer.")
                test.eq(response.metadata.thinking, "Let me think about this...")
            end)

            it("should use default timeout when not specified", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        test.eq(options.timeout, 600) -- Default timeout
                        return {
                            content = { { type = "text", text = "Default timeout" } },
                            stop_reason = "end_turn",
                            usage = { input_tokens = 5, output_tokens = 3 },
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Test" } } }
                    }
                }

                local response = generate_handler.handler(contract_args)
                test.is_true(response.success)
                assert(response.success)
            end)
        end)

        describe("Message Processing", function()
            it("should handle system messages", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        test.not_nil(payload.system)
                        test.eq(#payload.system, 1)
                        test.eq(payload.system[1].type, "text")
                        test.eq(payload.system[1].text, "You are a helpful assistant")

                        return {
                            content = { { type = "text", text = "I'll be helpful!" } },
                            stop_reason = "end_turn",
                            usage = { input_tokens = 20, output_tokens = 5 },
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "system", content = "You are a helpful assistant" },
                        { role = "user",   content = { { type = "text", text = "Hi" } } }
                    }
                }

                local response = generate_handler.handler(contract_args)
                test.is_true(response.success)
                assert(response.success)
                test.eq(response.result.content, "I'll be helpful!")
            end)

            it("should handle function call and result messages", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        -- Verify function_call converted to assistant tool_use
                        local found_assistant = false
                        local found_tool_result = false

                        for _, msg in ipairs(payload.messages) do
                            if msg.role == "assistant" and msg.content and #msg.content > 0 and msg.content[1].type == "tool_use" then
                                found_assistant = true
                                test.eq(msg.content[1].name, "get_weather")
                                test.eq(msg.content[1].input.location, "NYC")
                            elseif msg.role == "user" and msg.content and #msg.content > 0 and msg.content[1].type == "tool_result" then
                                found_tool_result = true
                                local first = (msg :: any).content[1]
                                test.eq(first.tool_use_id, "call-456")
                                test.eq(first.content, "Sunny, 75°F")
                            end
                        end

                        test.is_true(found_assistant)
                        test.is_true(found_tool_result)

                        return {
                            content = { { type = "text", text = "Based on the weather, it's nice!" } },
                            stop_reason = "end_turn",
                            usage = { input_tokens = 30, output_tokens = 12 },
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "What's the weather?" } } },
                        {
                            role = "function_call",
                            function_call = {
                                name = "get_weather",
                                arguments = { location = "NYC" },
                                id = "call_123"
                            },
                            content = {}
                        },
                        {
                            role = "function_result",
                            name = "get_weather",
                            content = { { type = "text", text = "Sunny, 75°F" } },
                            function_call_id = "call_456"
                        }
                    }
                }

                local response = generate_handler.handler(contract_args)
                test.is_true(response.success)
                assert(response.success)
                test.eq(response.result.content, "Based on the weather, it's nice!")
            end)

            it("should handle developer messages", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        -- Verify developer message is appended to previous user message
                        test.eq(#payload.messages, 1)
                        local user_msg = payload.messages[1]
                        test.eq(user_msg.role, "user")
                        test.contains(user_msg.content[1].text, "Hello")
                        test.contains(user_msg.content[1].text, 
                            "<developer-instruction>Be concise</developer-instruction>")

                        return {
                            content = { { type = "text", text = "Hi!" } },
                            stop_reason = "end_turn",
                            usage = { input_tokens = 15, output_tokens = 2 },
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user",      content = { { type = "text", text = "Hello" } } },
                        { role = "developer", content = "Be concise" }
                    }
                }

                local response = generate_handler.handler(contract_args)
                test.is_true(response.success)
                assert(response.success)
                test.eq(response.result.content, "Hi!")
            end)

            it("should handle cache markers", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        -- Verify cache control was added
                        test.not_nil(payload.system)
                        test.eq(#payload.system, 2)
                        test.not_nil(payload.system[1].cache_control)
                        test.eq(payload.system[1].cache_control.type, "ephemeral")

                        return {
                            content = { { type = "text", text = "Cache enabled response" } },
                            stop_reason = "end_turn",
                            usage = {
                                input_tokens = 25,
                                output_tokens = 8,
                                cache_creation_input_tokens = 20,
                                cache_read_input_tokens = 0
                            },
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "system",      content = "System prompt 1" },
                        { role = "cache_marker" },
                        { role = "system",      content = "System prompt 2" },
                        { role = "user",        content = { { type = "text", text = "Hello" } } }
                    }
                }

                local response = generate_handler.handler(contract_args)
                test.is_true(response.success)
                assert(response.success)
                test.eq(response.tokens.cache_write_tokens, 20)
                test.eq(response.tokens.cache_read_tokens, 0)
            end)
        end)

        describe("Image Content", function()
            it("should handle image content in messages", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        -- Verify image content is processed correctly
                        local user_msg = payload.messages[1]
                        test.not_nil(user_msg.content)
                        test.eq(#user_msg.content, 2)
                        test.eq(user_msg.content[1].type, "text")
                        test.eq(user_msg.content[2].type, "image")
                        test.eq(user_msg.content[2].source.type, "base64")
                        test.eq(user_msg.content[2].source.media_type, "image/jpeg")

                        return {
                            content = { { type = "text", text = "I can see the image." } },
                            stop_reason = "end_turn",
                            usage = { input_tokens = 50, output_tokens = 10 },
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        {
                            role = "user",
                            content = {
                                { type = "text", text = "What do you see?" },
                                {
                                    type = "image",
                                    source = {
                                        type = "base64",
                                        mime_type = "image/jpeg",
                                        data = "iVBORw0KGgoAAAANSUhEUgAA..."
                                    }
                                }
                            }
                        }
                    }
                }

                local response = generate_handler.handler(contract_args)
                test.is_true(response.success)
                assert(response.success)
                test.eq(response.result.content, "I can see the image.")
            end)

            it("should handle URL images", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        local user_msg = payload.messages[1]
                        test.eq(user_msg.content[2].type, "image")
                        test.eq(user_msg.content[2].source.type, "url")
                        test.eq(user_msg.content[2].source.url, "https://example.com/image.jpg")

                        return {
                            content = { { type = "text", text = "I can see the URL image." } },
                            stop_reason = "end_turn",
                            usage = { input_tokens = 45, output_tokens = 12 },
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        {
                            role = "user",
                            content = {
                                { type = "text", text = "Describe this image:" },
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
                }

                local response = generate_handler.handler(contract_args)
                test.is_true(response.success)
                assert(response.success)
                test.eq(response.result.content, "I can see the URL image.")
            end)
        end)

        describe("Tool Calling", function()
            it("should handle basic tool calls", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        test.not_nil(payload.tools)
                        test.eq(#payload.tools, 1)
                        test.eq(payload.tools[1].name, "get_weather")

                        return {
                            content = {
                                { type = "text", text = "I'll check the weather for you." },
                                {
                                    type = "tool_use",
                                    id = "call_123",
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

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "What's the weather in NYC?" } } }
                    },
                    tools = {
                        {
                            name = "get_weather",
                            description = "Get weather information",
                            schema = {
                                type = "object",
                                properties = {
                                    location = { type = "string" }
                                },
                                required = { "location" }
                            },
                            id = "weather_tool_123"
                        }
                    }
                }

                local response = generate_handler.handler(contract_args)

                test.is_true(response.success)
                assert(response.success)
                test.eq(response.result.content, "I'll check the weather for you.")
                test.eq(#response.result.tool_calls, 1)
                test.eq(response.result.tool_calls[1].id, "call-123")
                test.eq(response.result.tool_calls[1].name, "get_weather")
                test.eq(response.result.tool_calls[1].arguments.location, "NYC")
                test.eq(response.result.tool_calls[1].registry_id, "weather_tool_123")
                test.eq(response.finish_reason, "tool_call")
            end)

            it("should handle multiple tool calls", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        return {
                            content = {
                                { type = "text", text = "I'll help with both tasks." },
                                {
                                    type = "tool_use",
                                    id = "call_1",
                                    name = "get_weather",
                                    input = { location = "NYC" }
                                },
                                {
                                    type = "tool_use",
                                    id = "call_2",
                                    name = "calculate",
                                    input = { expression = "2+2" }
                                }
                            },
                            stop_reason = "tool_use",
                            usage = { input_tokens = 30, output_tokens = 20 },
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Get NYC weather and calculate 2+2" } } }
                    },
                    tools = {
                        {
                            name = "get_weather",
                            description = "Get weather",
                            schema = { type = "object" },
                            id = "weather_id"
                        },
                        {
                            name = "calculate",
                            description = "Calculate",
                            schema = { type = "object" },
                            id = "calc_id"
                        }
                    }
                }

                local response = generate_handler.handler(contract_args)
                test.is_true(response.success)
                assert(response.success)
                test.eq(#response.result.tool_calls, 2)
                test.eq(response.result.tool_calls[1].name, "get_weather")
                test.eq(response.result.tool_calls[2].name, "calculate")
            end)

            it("should handle tool_choice auto", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        test.not_nil(payload.tool_choice)
                        test.eq(payload.tool_choice.type, "auto")

                        return {
                            content = { { type = "text", text = "I can help without tools." } },
                            stop_reason = "end_turn",
                            usage = { input_tokens = 15, output_tokens = 8 },
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Just chat" } } }
                    },
                    tools = {
                        { name = "helper", description = "Helper", schema = { type = "object" } }
                    },
                    tool_choice = "auto"
                }

                local response = generate_handler.handler(contract_args)
                test.is_true(response.success)
                assert(response.success)
                test.eq(#response.result.tool_calls, 0)
                test.eq(response.finish_reason, "stop")
            end)

            it("should handle tool_choice none", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        test.not_nil(payload.tool_choice)
                        test.eq(payload.tool_choice.type, "none")

                        return {
                            content = { { type = "text", text = "No tools used" } },
                            stop_reason = "end_turn",
                            usage = { input_tokens = 12, output_tokens = 4 },
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Just respond" } } }
                    },
                    tools = {
                        { name = "helper", description = "Helper", schema = { type = "object" } }
                    },
                    tool_choice = "none"
                }

                local response = generate_handler.handler(contract_args)
                test.is_true(response.success)
                assert(response.success)
                test.eq(#response.result.tool_calls, 0)
            end)

            it("should handle specific tool choice", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        test.not_nil(payload.tool_choice)
                        test.eq(payload.tool_choice.type, "tool")
                        test.eq(payload.tool_choice.name, "calculate")

                        return {
                            content = {
                                {
                                    type = "tool_use",
                                    id = "call_forced",
                                    name = "calculate",
                                    input = { expression = "forced" }
                                }
                            },
                            stop_reason = "tool_use",
                            usage = { input_tokens = 10, output_tokens = 5 },
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Test" } } }
                    },
                    tools = {
                        { name = "calculate", description = "Calculate", schema = { type = "object" }, id = "calc_id" }
                    },
                    tool_choice = "calculate"
                }

                local response = generate_handler.handler(contract_args)
                test.is_true(response.success)
                assert(response.success)
                test.eq(response.result.tool_calls[1].name, "calculate")
                test.eq(response.result.tool_calls[1].registry_id, "calc_id")
            end)

            it("should handle invalid tool choice", function()
                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Test" } } }
                    },
                    tools = {
                        { name = "existing_tool", description = "Exists", schema = { type = "object" } }
                    },
                    tool_choice = "nonexistent_tool"
                }

                local response, err = generate_handler.handler(contract_args)
                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Invalid")
                test.contains(err:message(), "not found")
            end)

            it("should handle mixed content and tool use blocks", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        return {
                            content = {
                                { type = "text", text = "I'll calculate that. " },
                                {
                                    type = "tool_use",
                                    id = "call_mixed",
                                    name = "calculate",
                                    input = { expression = "5*7" }
                                },
                                { type = "text", text = " Calculation complete." }
                            },
                            stop_reason = "tool_use",
                            usage = { input_tokens = 20, output_tokens = 15 },
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Calculate 5*7" } } }
                    },
                    tools = {
                        { name = "calculate", description = "Calculate", schema = { type = "object" }, id = "calc_mixed" }
                    }
                }

                local response = generate_handler.handler(contract_args)
                test.is_true(response.success)
                assert(response.success)
                test.eq(response.result.content, "I'll calculate that.  Calculation complete.")
                test.eq(#response.result.tool_calls, 1)
                test.eq(response.result.tool_calls[1].name, "calculate")
                test.eq(response.finish_reason, "tool_call")
            end)
        end)

        describe("Streaming", function()
            it("should handle basic streaming responses", function()
                local mock_streamer = {
                    buffer_content = function(self, chunk) end,
                    send_tool_call = function(self, name, args, id) end,
                    flush = function(self) end
                }

                generate_handler._output = {
                    streamer = function(reply_to, topic, buffer_size)
                        return mock_streamer
                    end,
                    FINISH_REASON = { TOOL_CALL = "tool_call" }
                }

                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        test.is_true(options.stream)
                        return {
                            stream = {},
                            metadata = { request_id = "req_stream" }
                        }
                    end,
                    process_stream = function(stream_response, callbacks)
                        callbacks.on_content("Hello")
                        callbacks.on_content(" world")
                        callbacks.on_done({
                            finish_reason = "end_turn",
                            usage = { input_tokens = 10, output_tokens = 5 }
                        })
                        return "Hello world", nil, {
                            content = "Hello world",
                            finish_reason = "end_turn",
                            usage = { input_tokens = 10, output_tokens = 5 }
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Hello" } } }
                    },
                    stream = {
                        reply_to = "test-process",
                        topic = "test_stream"
                    }
                }

                local response = generate_handler.handler(contract_args)
                test.is_true(response.success)
                assert(response.success)
                test.eq(response.result.content, "Hello world")
            end)

            it("should handle streaming tool calls", function()
                local mock_streamer = {
                    buffer_content = function(self, chunk) end,
                    send_tool_call = function(self, name, args, id) end,
                    flush = function(self) end
                }

                generate_handler._output = {
                    streamer = function(reply_to, topic, buffer_size)
                        return mock_streamer
                    end,
                    FINISH_REASON = { TOOL_CALL = "tool_call" }
                }

                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        return {
                            stream = {},
                            metadata = {}
                        }
                    end,
                    process_stream = function(stream_response, callbacks)
                        callbacks.on_content("I will help.")
                        callbacks.on_tool_call({
                            id = "call_123",
                            name = "calculate",
                            arguments = { expr = "2+2" }
                        })
                        callbacks.on_done({
                            finish_reason = "tool_use",
                            usage = { input_tokens = 20, output_tokens = 10 }
                        })
                        return "I will help.", nil, {
                            content = "I will help.",
                            tool_calls = { { id = "call_123", name = "calculate", arguments = { expr = "2+2" } } },
                            finish_reason = "tool_use",
                            usage = { input_tokens = 20, output_tokens = 10 }
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Calculate 2+2" } } }
                    },
                    tools = {
                        { name = "calculate", description = "Calculate", schema = { type = "object" }, id = "calc_id" }
                    },
                    stream = {
                        reply_to = "test-process",
                        topic = "test_stream_tools"
                    }
                }

                local response = generate_handler.handler(contract_args)
                test.is_true(response.success)
                assert(response.success)
                test.eq(response.result.content, "I will help.")
                test.eq(#response.result.tool_calls, 1)
                test.eq(response.result.tool_calls[1].name, "calculate")
                test.eq(response.finish_reason, "tool_call")
            end)

            it("should handle streaming thinking content", function()
                local mock_streamer = {
                    buffer_content = function(self, chunk) end,
                    send_thinking = function(self, chunk) end,
                    flush = function(self) end
                }

                generate_handler._output = {
                    streamer = function(reply_to, topic, buffer_size)
                        return mock_streamer
                    end,
                    FINISH_REASON = { TOOL_CALL = "tool_call" }
                }

                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        return {
                            stream = {},
                            metadata = {}
                        }
                    end,
                    process_stream = function(stream_response, callbacks)
                        callbacks.on_thinking("Let me think...")
                        callbacks.on_thinking(" The answer is 42.")
                        callbacks.on_content("The answer is 42.")
                        callbacks.on_done({
                            finish_reason = "end_turn",
                            usage = { input_tokens = 25, output_tokens = 8 }
                        })
                        return "The answer is 42.", nil, {
                            content = "The answer is 42.",
                            thinking = { { type = "thinking", thinking = "Let me think... The answer is 42." } },
                            finish_reason = "end_turn",
                            usage = { input_tokens = 25, output_tokens = 8 }
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-7-sonnet-20250219",
                    messages = {
                        { role = "user", content = { { type = "text", text = "What is the meaning of life?" } } }
                    },
                    stream = {
                        reply_to = "test-process",
                        topic = "test_thinking_stream"
                    }
                }

                local response = generate_handler.handler(contract_args)
                test.is_true(response.success)
                assert(response.success)
                test.eq(response.result.content, "The answer is 42.")
                test.eq(response.metadata.thinking, "Let me think... The answer is 42.")
                local blocks = response.metadata.thinking_blocks :: any
                test.eq(#blocks, 1)
                test.eq(blocks[1].type, "thinking")
                test.eq(blocks[1].thinking, "Let me think... The answer is 42.")
            end)

            it("should handle streaming errors", function()
                local mock_streamer = {
                    buffer_content = function(self, chunk) end,
                    send_error = function(self, error, message) end,
                    flush = function(self) end
                }

                generate_handler._output = {
                    streamer = function(reply_to, topic, buffer_size)
                        return mock_streamer
                    end,
                    FINISH_REASON = { TOOL_CALL = "tool_call" }
                }

                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        return {
                            stream = {},
                            metadata = {}
                        }
                    end,
                    process_stream = function(stream_response, callbacks)
                        callbacks.on_error({ message = "Stream error occurred" })
                        return nil, "Stream error occurred"
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Test" } } }
                    },
                    stream = {
                        reply_to = "test-process",
                        topic = "test_error_stream"
                    }
                }

                local response, err = generate_handler.handler(contract_args)
                test.is_nil(response)
                test.not_nil(err)
                test.contains(err:message(), "Stream error occurred")
            end)
        end)

        describe("Error Handling", function()
            it("should handle authentication errors", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        return nil, {
                            status_code = 401,
                            error = {
                                type = "authentication_error",
                                message = "Invalid API key"
                            }
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Test" } } }
                    }
                }

                local response, err = generate_handler.handler(contract_args)
                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "PermissionDenied")
                test.eq(err:message(), "Invalid API key")
            end)

            it("should handle rate limit errors", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        return nil, {
                            status_code = 429,
                            error = {
                                type = "rate_limit_error",
                                message = "Rate limit exceeded"
                            }
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Test" } } }
                    }
                }

                local response, err = generate_handler.handler(contract_args)
                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "RateLimited")
                test.eq(err:message(), "Rate limit exceeded")
            end)

            it("should handle model not found errors", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        return nil, {
                            status_code = 404,
                            error = {
                                type = "not_found_error",
                                message = "Model not found"
                            }
                        }
                    end
                }

                local contract_args = {
                    model = "nonexistent-model",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Test" } } }
                    }
                }

                local response, err = generate_handler.handler(contract_args)
                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "NotFound")
                test.contains(err:message(), "not found")
            end)

            it("should handle server errors", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        return nil, {
                            status_code = 500,
                            message = "Internal server error"
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Test" } } }
                    }
                }

                local response, err = generate_handler.handler(contract_args)
                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Unavailable")
                test.contains(err:message(), "server error")
            end)

            it("should handle connection failures", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        return nil, {
                            status_code = 0,
                            message = "Connection failed"
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Test" } } }
                    }
                }

                local response, err = generate_handler.handler(contract_args)
                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Unavailable")
                test.eq(err:message(), "Connection failed")
            end)

            it("should handle API key missing", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        return nil, {
                            status_code = 401,
                            message = "Claude API key is required"
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Test" } } }
                    }
                }

                local response, err = generate_handler.handler(contract_args)
                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "PermissionDenied")
                test.contains(err:message(), "API key")
            end)

            it("should handle JSON parsing errors", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        return nil, {
                            status_code = 500,
                            message = "Failed to parse Claude response"
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Test" } } }
                    }
                }

                local response, err = generate_handler.handler(contract_args)
                test.is_nil(response)
                test.not_nil(err)
                test.contains(err:message(), "Failed to parse Claude response")
            end)
        end)

        describe("Response Format Compliance", function()
            it("should return proper contract response structure", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        return {
                            content = { { type = "text", text = "Test response" } },
                            stop_reason = "end_turn",
                            usage = {
                                input_tokens = 5,
                                output_tokens = 3,
                                cache_creation_input_tokens = 10,
                                cache_read_input_tokens = 5
                            },
                            metadata = { request_id = "req_format" }
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Test" } } }
                    }
                }

                local response = generate_handler.handler(contract_args)

                -- Verify contract compliance
                test.is_true(response.success)
                assert(response.success)
                test.not_nil(response.result)
                test.not_nil(response.result.content)
                test.not_nil(response.result.tool_calls)
                test.eq(type(response.result.tool_calls), "table")
                test.not_nil(response.tokens)
                test.not_nil(response.finish_reason)
                test.not_nil(response.metadata)

                -- Verify specific values
                test.eq(response.result.content, "Test response")
                test.eq(response.tokens.prompt_tokens, 5)
                test.eq(response.tokens.completion_tokens, 3)
                test.eq(response.tokens.total_tokens, 8)
                test.eq(response.tokens.cache_write_tokens, 10)
                test.eq(response.tokens.cache_read_tokens, 5)
                test.eq(response.finish_reason, "stop")
                test.eq(response.metadata.request_id, "req_format")
            end)

            it("should handle empty tool_calls array properly", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        return {
                            content = { { type = "text", text = "No tools used" } },
                            stop_reason = "end_turn",
                            usage = { input_tokens = 10, output_tokens = 4 },
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Test" } } }
                    }
                }

                local response = generate_handler.handler(contract_args)
                test.is_true(response.success)
                assert(response.success)
                test.not_nil(response.result.tool_calls)
                test.eq(#response.result.tool_calls, 0)
                test.eq(response.finish_reason, "stop")
            end)

            it("should preserve metadata from Claude responses", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        return {
                            content = { { type = "text", text = "Response" } },
                            stop_reason = "end_turn",
                            usage = { input_tokens = 8, output_tokens = 3 },
                            metadata = {
                                request_id = "req_meta123",
                                processing_ms = 250,
                                custom_field = "custom_value"
                            }
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Test" } } }
                    }
                }

                local response = generate_handler.handler(contract_args)
                test.is_true(response.success)
                assert(response.success)
                test.eq(response.metadata.request_id, "req_meta123")
                test.eq(response.metadata.processing_ms, 250)
                test.eq(response.metadata.custom_field, "custom_value")
            end)
        end)

        describe("Edge Cases", function()
            it("should handle empty content blocks", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        return {
                            content = {
                                { type = "text", text = "" }
                            },
                            stop_reason = "end_turn",
                            usage = { input_tokens = 5, output_tokens = 0 },
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Give me nothing" } } }
                    }
                }

                local response = generate_handler.handler(contract_args)
                test.is_true(response.success)
                assert(response.success)
                test.eq(response.result.content, "")
            end)

            it("should handle missing usage information", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        return {
                            content = { { type = "text", text = "No usage info" } },
                            stop_reason = "end_turn",
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Test" } } }
                    }
                }

                local response = generate_handler.handler(contract_args)
                test.is_true(response.success)
                assert(response.success)
                test.is_nil(response.tokens)
            end)

            it("should handle malformed tool call arguments", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        return {
                            content = {
                                {
                                    type = "tool_use",
                                    id = "call_malformed",
                                    name = "broken_tool",
                                    input = "not an object" -- Should be an object
                                }
                            },
                            stop_reason = "tool_use",
                            usage = { input_tokens = 10, output_tokens = 5 },
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Test" } } }
                    },
                    tools = {
                        { name = "broken_tool", description = "Broken", schema = { type = "object" } }
                    }
                }

                local response = generate_handler.handler(contract_args)
                test.is_true(response.success)
                assert(response.success)
                test.eq(#response.result.tool_calls, 1)
                test.eq(response.result.tool_calls[1].arguments, "not an object")
            end)

            it("should handle stop_sequence finish reason", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        return {
                            content = { { type = "text", text = "Response stopped by sequence" } },
                            stop_reason = "stop_sequence",
                            usage = { input_tokens = 15, output_tokens = 8 },
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Generate until STOP" } } }
                    },
                    options = {
                        stop_sequences = { "STOP" }
                    }
                }

                local response = generate_handler.handler(contract_args)
                test.is_true(response.success)
                assert(response.success)
                test.eq(response.finish_reason, "stop")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
