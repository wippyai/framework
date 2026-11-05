local generate_handler = require("generate_handler")
local claude_client = require("claude_client")
local json = require("json")

local BINDING_BETA = "thinking-binding-controls-2026-08-01"

local SIGNED_THINKING = { type = "thinking", thinking = "Weighing the routes.", signature = "sig-original-1" }
local REDACTED_THINKING = { type = "redacted_thinking", data = "opaque-redacted-1" }

local function history_with_thinking(blocks)
    return {
        { role = "system", content = "You are the booking agent." },
        { role = "user", content = { { type = "text", text = "Plan the trip" } } },
        {
            role = "function_call",
            function_call = { id = "call_1", name = "search", arguments = { q = "flights" } },
            metadata = { thinking_blocks = blocks }
        },
        { role = "function_result", function_call_id = "call_1", content = "3 flights" },
        {
            role = "assistant",
            content = { { type = "text", text = "Here is the plan." } },
            metadata = { thinking_blocks = blocks }
        },
        { role = "user", content = { { type = "text", text = "Now book it" } } }
    }
end

local function capturing_client(captured, response)
    return {
        ENDPOINTS = { MESSAGES = "/v1/messages" },
        request = function(endpoint, payload, options)
            captured.payload = payload
            captured.options = options
            return response or {
                content = { { type = "text", text = "Booked." } },
                stop_reason = "end_turn",
                usage = { input_tokens = 30, output_tokens = 3 },
                metadata = {}
            }
        end
    }
end

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

            it("should forward retry to the client request", function()
                local captured_options = nil
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        captured_options = options
                        return {
                            content = { { type = "text", text = "Retried response" } },
                            stop_reason = "end_turn",
                            usage = { input_tokens = 10, output_tokens = 5 },
                            metadata = {}
                        }
                    end
                }

                local response = generate_handler.handler({
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Test" } } }
                    },
                    retry = { attempts = 2, backoff_ms = 0 }
                })

                test.is_true(response.success)
                local options = captured_options :: any
                test.eq(options.retry.attempts, 2)
                test.eq(options.retry.backoff_ms, 0)
            end)

            it("should handle thinking models with effort configuration", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        test.eq(payload.model, "claude-3-7-sonnet-20250219")
                        test.not_nil(payload.thinking)
                        test.eq(payload.thinking.type, "enabled")
                        test.gt(payload.thinking.budget_tokens, 1000)
                        test.is_nil(payload.temperature) -- Dropped, never forced to 1

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
                        temperature = 0.5 -- Dropped, budget thinking never injects a temperature
                    }
                }

                local response = generate_handler.handler(contract_args)
                test.is_true(response.success)
                assert(response.success)
                test.eq(response.result.content, "After thinking, here's my answer.")
                test.eq(response.metadata.thinking, "Let me think about this...")
                test.eq(response.metadata.adjusted.temperature.requested, 0.5)
                test.is_nil(response.metadata.adjusted.temperature.sent)
            end)

            it("should leave an unspecified timeout to the client", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function(endpoint, payload, options)
                        test.is_nil(options.timeout)
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
                                test.eq(first.tool_use_id, "call_456")
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
                        test.eq(user_msg.content[1].text, "Hello")
                        test.eq(user_msg.content[2].type, "text")
                        test.eq(user_msg.content[2].text, "<developer-instruction>Be concise</developer-instruction>")

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

            it("sends the requested cache lifetime on every breakpoint", function()
                local captured: any = {}
                generate_handler._client = capturing_client(captured, {
                    content = { { type = "text", text = "Cached for an hour" } },
                    stop_reason = "end_turn",
                    usage = {
                        input_tokens = 4,
                        output_tokens = 5,
                        cache_creation_input_tokens = 30,
                        cache_read_input_tokens = 0,
                        cache_creation = { ephemeral_5m_input_tokens = 0, ephemeral_1h_input_tokens = 30 }
                    },
                    metadata = {}
                })

                local response = generate_handler.handler({
                    model = "claude-sonnet-4-6",
                    messages = {
                        { role = "system", content = "System prompt" },
                        { role = "cache_marker" },
                        { role = "user", content = { { type = "text", text = "Hello" } } },
                        { role = "cache_marker", marker_id = "history_tail" }
                    },
                    options = { cache_ttl = "1h" }
                })

                test.is_true(response.success)
                test.eq(captured.payload.system[1].cache_control.ttl, "1h")
                test.eq(captured.payload.messages[1].content[1].cache_control.ttl, "1h")
                test.is_nil(captured.payload.cache_ttl)
                test.eq(response.tokens.cache_write_by_ttl["1h"], 30)
            end)

            it("rejects an unsupported cache lifetime before the request", function()
                local captured: any = {}
                generate_handler._client = capturing_client(captured)

                local response, err = generate_handler.handler({
                    model = "claude-sonnet-4-6",
                    messages = {
                        { role = "system", content = "System prompt" },
                        { role = "cache_marker" },
                        { role = "user", content = { { type = "text", text = "Hello" } } }
                    },
                    options = { cache_ttl = "2h" }
                })

                test.is_nil(response)
                test.eq(err:kind(), "Invalid")
                test.contains(err:message(), "cache_ttl")
                test.contains(err:message(), "2h")
                test.is_nil(captured.payload)
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
                test.eq(response.result.tool_calls[1].id, "call_123")
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

            it("reports one-hour cache writes from a streamed response", function()
                local usage = {
                    input_tokens = 4,
                    output_tokens = 5,
                    cache_creation_input_tokens = 30,
                    cache_read_input_tokens = 0,
                    cache_creation = { ephemeral_5m_input_tokens = 0, ephemeral_1h_input_tokens = 30 }
                }
                generate_handler._output = {
                    streamer = function()
                        return {
                            buffer_content = function() end,
                            send_tool_call = function() end,
                            flush = function() end
                        }
                    end,
                    FINISH_REASON = { TOOL_CALL = "tool_call" }
                }
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function()
                        return { stream = {}, metadata = {} }
                    end,
                    process_stream = function(_, callbacks)
                        callbacks.on_content("Cached")
                        callbacks.on_done({ finish_reason = "end_turn", usage = usage })
                        return "Cached", nil, { content = "Cached", finish_reason = "end_turn", usage = usage }
                    end
                }

                local response = generate_handler.handler({
                    model = "claude-sonnet-4-6",
                    messages = { { role = "user", content = { { type = "text", text = "Hello" } } } },
                    options = { cache_ttl = "1h" },
                    stream = { reply_to = "test-process", topic = "test_stream" }
                })

                test.is_true(response.success)
                test.eq(response.tokens.cache_write_tokens, 30)
                test.eq(response.tokens.cache_write_by_ttl["1h"], 30)
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

        describe("Thinking block binding", function()
            it("binds replayed blocks with drop_block under adaptive thinking", function()
                local captured = {}
                generate_handler._client = capturing_client(captured)

                local response = generate_handler.handler({
                    model = "claude-opus-5-5",
                    messages = history_with_thinking({ SIGNED_THINKING }),
                    accepts = { thinking = "adaptive" },
                    options = { thinking_effort = 50 }
                })

                test.is_true(response.success)
                test.eq(captured.payload.thinking.type, "adaptive")
                test.eq(captured.payload.thinking.block_binding.prefix_mismatch_behavior, "drop_block")
                test.eq(#captured.options.beta_features, 1)
                test.eq(captured.options.beta_features[1], BINDING_BETA)
            end)

            it("binds a history whose only replayed block is redacted", function()
                local captured = {}
                generate_handler._client = capturing_client(captured)

                generate_handler.handler({
                    model = "claude-opus-5-5",
                    messages = history_with_thinking({ REDACTED_THINKING }),
                    accepts = { thinking = "adaptive" },
                    options = { thinking_effort = 50 }
                })

                test.eq(captured.payload.thinking.block_binding.prefix_mismatch_behavior, "drop_block")
                test.eq(captured.options.beta_features[1], BINDING_BETA)
            end)

            it("binds replayed blocks under budget thinking", function()
                local captured = {}
                generate_handler._client = capturing_client(captured)

                generate_handler.handler({
                    model = "claude-sonnet-4-5",
                    messages = history_with_thinking({ SIGNED_THINKING }),
                    options = { thinking_effort = 50 }
                })

                test.eq(captured.payload.thinking.type, "enabled")
                test.not_nil(captured.payload.thinking.budget_tokens)
                test.eq(captured.payload.thinking.block_binding.prefix_mismatch_behavior, "drop_block")
                test.eq(captured.options.beta_features[1], BINDING_BETA)
            end)

            it("binds replayed blocks on an always route at the model's default effort", function()
                local captured = {}
                generate_handler._client = capturing_client(captured)

                generate_handler.handler({
                    model = "claude-opus-5-5",
                    messages = history_with_thinking({ SIGNED_THINKING }),
                    accepts = { thinking = "always" },
                    options = {}
                })

                local thinking = captured.payload.thinking
                test.eq(thinking.type, "adaptive")
                test.eq(thinking.block_binding.prefix_mismatch_behavior, "drop_block")
                test.is_nil(captured.payload.output_config)
                test.eq(#captured.options.beta_features, 1)
                test.eq(captured.options.beta_features[1], BINDING_BETA)
            end)

            it("decides the binding from the thinking object as finally sent", function()
                local captured = {}
                local real_mapper = generate_handler._mapper
                local mapped_options: any = nil
                generate_handler._mapper = setmetatable({
                    map_options = function(...)
                        local options, adjusted, options_err = real_mapper.map_options(...)
                        mapped_options = options
                        return options, adjusted, options_err
                    end,
                    map_tools = function(...)
                        mapped_options.thinking.type = "between_tools"
                        return real_mapper.map_tools(...)
                    end
                }, { __index = real_mapper })
                generate_handler._client = capturing_client(captured)

                generate_handler.handler({
                    model = "claude-sonnet-5-5",
                    messages = history_with_thinking({ SIGNED_THINKING }),
                    tools = { { name = "search", description = "Search", schema = { type = "object" } } },
                    accepts = { thinking = "adaptive" },
                    options = { thinking_effort = 50 }
                })
                generate_handler._mapper = real_mapper

                test.eq(captured.payload.thinking.type, "between_tools")
                test.is_nil(captured.payload.thinking.block_binding)
                test.is_nil(captured.options.beta_features)
            end)

            it("sends no binding when the history replays no thinking blocks", function()
                local captured = {}
                generate_handler._client = capturing_client(captured)

                generate_handler.handler({
                    model = "claude-opus-5-5",
                    messages = history_with_thinking({}),
                    accepts = { thinking = "adaptive" },
                    options = { thinking_effort = 50 }
                })

                test.eq(captured.payload.thinking.type, "adaptive")
                test.is_nil(captured.payload.thinking.block_binding)
                test.is_nil(captured.options.beta_features)
            end)

            it("never adds a thinking object to carry the binding when the request sends none", function()
                local captured = {}
                generate_handler._client = capturing_client(captured)

                generate_handler.handler({
                    model = "claude-opus-4-8",
                    messages = history_with_thinking({ SIGNED_THINKING }),
                    accepts = { thinking = "adaptive" },
                    options = { thinking_effort = 0 }
                })

                test.is_nil(captured.payload.thinking)
                test.is_nil(captured.options.beta_features)
                local replayed = captured.payload.messages[2].content[1]
                test.eq(replayed.type, "thinking")
                test.eq(replayed.signature, SIGNED_THINKING.signature)
            end)

            it("never adds a thinking object on a route that declares no thinking", function()
                local captured = {}
                generate_handler._client = capturing_client(captured)

                generate_handler.handler({
                    model = "claude-sonnet-4-5",
                    messages = history_with_thinking({ SIGNED_THINKING }),
                    accepts = { thinking = "none" },
                    options = {}
                })

                test.is_nil(captured.payload.thinking)
                test.is_nil(captured.options.beta_features)
            end)

            it("replays every thinking block unchanged when the conversation switches models", function()
                local captured = {}
                generate_handler._client = capturing_client(captured)

                generate_handler.handler({
                    model = "claude-haiku-5-5",
                    messages = history_with_thinking({ SIGNED_THINKING, REDACTED_THINKING }),
                    accepts = { thinking = "adaptive" },
                    options = { thinking_effort = 50 }
                })

                local messages = captured.payload.messages
                for _, index in ipairs({ 2, 4 }) do
                    local content = messages[index].content
                    test.eq(messages[index].role, "assistant")
                    test.eq(content[1].type, "thinking")
                    test.eq(content[1].thinking, SIGNED_THINKING.thinking)
                    test.eq(content[1].signature, SIGNED_THINKING.signature)
                    test.eq(content[2].type, "redacted_thinking")
                    test.eq(content[2].data, REDACTED_THINKING.data)
                end
                test.eq(captured.payload.thinking.block_binding.prefix_mismatch_behavior, "drop_block")
            end)

            it("stores response thinking blocks in the shape the API returned them", function()
                generate_handler._client = capturing_client({}, {
                    content = {
                        { type = "thinking", thinking = "Weighing the routes.", signature = "sig-new" },
                        { type = "redacted_thinking", data = "opaque-new" },
                        { type = "text", text = "Booked." }
                    },
                    stop_reason = "end_turn",
                    usage = { input_tokens = 30, output_tokens = 3 },
                    metadata = {}
                })

                local response = generate_handler.handler({
                    model = "claude-opus-5-5",
                    messages = history_with_thinking({}),
                    accepts = { thinking = "adaptive" },
                    options = { thinking_effort = 50 }
                })

                local blocks = response.metadata.thinking_blocks
                test.eq(#blocks, 2)
                test.eq(blocks[1].type, "thinking")
                test.eq(blocks[1].thinking, "Weighing the routes.")
                test.eq(blocks[1].signature, "sig-new")
                test.is_nil(blocks[1].data)
                test.eq(blocks[2].type, "redacted_thinking")
                test.eq(blocks[2].data, "opaque-new")
                test.is_nil(blocks[2].thinking)
                test.is_nil(blocks[2].signature)
            end)

            it("passes fields other than the stale ones through on replay", function()
                local captured = {}
                generate_handler._client = capturing_client(captured)

                generate_handler.handler({
                    model = "claude-opus-5-5",
                    messages = history_with_thinking({
                        { type = "thinking", thinking = "Weighing the routes.", signature = "sig-1", cache_control = { type = "ephemeral" } },
                        { type = "redacted_thinking", data = "opaque", provenance = "kept" }
                    }),
                    accepts = { thinking = "adaptive" },
                    options = { thinking_effort = 50 }
                })

                local content = captured.payload.messages[2].content
                test.eq(content[1].cache_control.type, "ephemeral")
                test.eq(content[1].signature, "sig-1")
                test.eq(content[2].provenance, "kept")
                test.eq(content[2].data, "opaque")
            end)

            it("replays stored blocks in the API shape of their type", function()
                local captured = {}
                generate_handler._client = capturing_client(captured)

                generate_handler.handler({
                    model = "claude-opus-5-5",
                    messages = history_with_thinking({
                        { type = "thinking", thinking = "Weighing the routes.", data = "stray", signature = "sig-1" },
                        { type = "redacted_thinking", thinking = "", data = "opaque-old", signature = "" }
                    }),
                    accepts = { thinking = "adaptive" },
                    options = { thinking_effort = 50 }
                })

                for _, index in ipairs({ 2, 4 }) do
                    local content = captured.payload.messages[index].content
                    test.eq(content[1].type, "thinking")
                    test.eq(content[1].thinking, "Weighing the routes.")
                    test.eq(content[1].signature, "sig-1")
                    test.is_nil(content[1].data)
                    test.eq(content[2].type, "redacted_thinking")
                    test.eq(content[2].data, "opaque-old")
                    test.is_nil(content[2].thinking)
                    test.is_nil(content[2].signature)
                end
            end)

            it("reports input_transformations from a non-streaming response in metadata", function()
                local captured = {}
                generate_handler._client = capturing_client(captured, {
                    content = { { type = "text", text = "Booked." } },
                    stop_reason = "end_turn",
                    usage = { input_tokens = 30, output_tokens = 3 },
                    metadata = {
                        input_transformations = {
                            { type = "thinking_dropped", path = "messages.1.content.0", reason = "prefix_binding_mismatch" }
                        }
                    }
                })

                local response = generate_handler.handler({
                    model = "claude-opus-5-5",
                    messages = history_with_thinking({ SIGNED_THINKING }),
                    accepts = { thinking = "adaptive" },
                    options = { thinking_effort = 50 }
                })

                local transformations = response.metadata.input_transformations
                test.eq(#transformations, 1)
                test.eq(transformations[1].type, "thinking_dropped")
                test.eq(transformations[1].path, "messages.1.content.0")
                test.eq(transformations[1].reason, "prefix_binding_mismatch")
            end)

            it("reports input_transformations from a streaming response in metadata", function()
                generate_handler._output = {
                    streamer = function()
                        return {
                            buffer_content = function() end,
                            send_thinking = function() end,
                            flush = function() end
                        }
                    end,
                    FINISH_REASON = { TOOL_CALL = "tool_call" }
                }
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function()
                        return { stream = {}, metadata = { request_id = "req_stream" } }
                    end,
                    process_stream = function(_, callbacks)
                        callbacks.on_content("Booked.")
                        local result = {
                            content = "Booked.",
                            finish_reason = "end_turn",
                            usage = { input_tokens = 30, output_tokens = 3 },
                            metadata = {
                                request_id = "req_stream",
                                input_transformations = {
                                    { type = "thinking_dropped", path = "messages.3.content.0", reason = "model_binding_mismatch" }
                                }
                            }
                        }
                        callbacks.on_done(result)
                        return "Booked.", nil, result
                    end
                }

                local response = generate_handler.handler({
                    model = "claude-opus-5-5",
                    messages = history_with_thinking({ SIGNED_THINKING }),
                    accepts = { thinking = "adaptive" },
                    options = { thinking_effort = 50 },
                    stream = { reply_to = "test-process", topic = "binding_stream" }
                })

                test.is_true(response.success)
                test.eq(response.metadata.request_id, "req_stream")
                local transformations = response.metadata.input_transformations
                test.eq(#transformations, 1)
                test.eq(transformations[1].reason, "model_binding_mismatch")
            end)

            describe("through the HTTP client", function()
                local saved = {}

                before_each(function()
                    saved.ctx = claude_client._ctx
                    saved.env = claude_client._env
                    saved.http = claude_client._http_client
                end)

                after_each(function()
                    claude_client._ctx = saved.ctx
                    claude_client._env = saved.env
                    claude_client._http_client = saved.http
                end)

                local function send(configured_betas)
                    local sent = {}
                    claude_client._ctx = {
                        all = function()
                            return { api_key = "test-key", beta_features = configured_betas }
                        end
                    }
                    claude_client._env = { get = function() return nil end }
                    claude_client._http_client = {
                        post = function(url, options)
                            sent.headers = options.headers
                            sent.body = json.decode(options.body)
                            return {
                                status_code = 200,
                                headers = { ["request-id"] = "req_bound" },
                                body = json.encode({
                                    content = { { type = "text", text = "Booked." } },
                                    stop_reason = "end_turn",
                                    usage = { input_tokens = 30, output_tokens = 3 },
                                    input_transformations = {
                                        { type = "thinking_dropped", path = "messages.1.content.0", reason = "prefix_binding_mismatch" }
                                    }
                                })
                            }
                        end
                    }
                    generate_handler._client = claude_client

                    local response = generate_handler.handler({
                        model = "claude-opus-5-5",
                        messages = history_with_thinking({ SIGNED_THINKING }),
                        accepts = { thinking = "adaptive" },
                        options = { thinking_effort = 50 }
                    })
                    return sent, response
                end

                it("sends the binding beta once alongside configured betas", function()
                    local sent, response = send({ "prompt-caching-2024-07-31" })

                    test.eq(sent.headers["anthropic-beta"], "prompt-caching-2024-07-31," .. BINDING_BETA)
                    test.eq(sent.body.thinking.block_binding.prefix_mismatch_behavior, "drop_block")
                    test.eq(response.metadata.request_id, "req_bound")
                    test.eq(response.metadata.input_transformations[1].reason, "prefix_binding_mismatch")
                end)

                it("sends the binding beta once when it is already configured", function()
                    local sent = send({ BINDING_BETA, "prompt-caching-2024-07-31" })

                    test.eq(sent.headers["anthropic-beta"], BINDING_BETA .. ",prompt-caching-2024-07-31")
                end)
            end)
        end)

        describe("Stream fallback signals", function()
            local streamed_args = {
                model = "claude-3-5-sonnet-20241022",
                messages = { { role = "user", content = { { type = "text", text = "Hi" } } } },
                stream = { reply_to = "test-process", topic = "test_stream" }
            }

            local function stream_with(streamer, process_stream)
                generate_handler._output = {
                    streamer = function() return streamer end,
                    FINISH_REASON = { TOOL_CALL = "tool_call" }
                }
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function() return { stream = {}, metadata = {} } end,
                    process_stream = process_stream
                }
            end

            local function recording_streamer(sent_any: boolean): any
                local errors_sent: {any} = {}
                return {
                    sent_any = sent_any,
                    errors_sent = errors_sent,
                    buffer_content = function() end,
                    send_thinking = function() end,
                    flush = function() end,
                    send_error = function(_, err_type, message)
                        table.insert(errors_sent, { type = err_type, message = message })
                    end
                }
            end

            it("marks a request error on a streaming call as not started", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function()
                        return nil, { status_code = 429, error = { type = "rate_limit_error", message = "slow down" } }
                    end
                }
                local response, err = generate_handler.handler(streamed_args)
                test.is_nil(response)
                local details = (err :: any):details()
                test.is_false(details.stream_started)
                test.eq(details.error_type, "rate_limit_exceeded")
            end)

            it("leaves stream_started unset on a request error without streaming", function()
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function()
                        return nil, { status_code = 503, message = "unavailable" }
                    end
                }
                local _, err = generate_handler.handler({
                    model = "claude-3-5-sonnet-20241022",
                    messages = { { role = "user", content = { { type = "text", text = "Hi" } } } }
                })
                local details = (err :: any):details()
                test.is_nil(details.stream_started)
                test.eq(details.error_type, "server_error")
            end)

            it("holds the error chunk back when the stream fails before anything was sent", function()
                local streamer = recording_streamer(false)
                stream_with(streamer, function(_, callbacks)
                    callbacks.on_content("Hel")
                    callbacks.on_error({ type = "overloaded_error", message = "Overloaded" })
                    return nil, "Overloaded"
                end)
                local response, err = generate_handler.handler(streamed_args)
                test.is_nil(response)
                test.eq(#streamer.errors_sent, 0)
                local details = (err :: any):details()
                test.is_false(details.stream_started)
                test.eq(details.error_type, "server_error")
                test.eq(details.deferred_error_message, "Overloaded")
                test.not_nil(details.deferred_error_type)
            end)

            it("sends the error chunk once part of the answer reached the client", function()
                local streamer = recording_streamer(true)
                stream_with(streamer, function(_, callbacks)
                    callbacks.on_thinking("thought")
                    callbacks.on_error({ message = "connection reset" })
                    return nil, "connection reset"
                end)
                local _, err = generate_handler.handler(streamed_args)
                test.eq(#streamer.errors_sent, 1)
                test.eq(streamer.errors_sent[1].message, "connection reset")
                local details = (err :: any):details()
                test.is_true(details.stream_started)
                test.is_nil(details.deferred_error_type)
            end)

            it("reports a streamer failure as a server error that does not allow fallback", function()
                generate_handler._output = {
                    streamer = function() return nil, "PID is required for streamer" end
                }
                generate_handler._client = {
                    ENDPOINTS = { MESSAGES = "/v1/messages" },
                    request = function() return { stream = {}, metadata = {} } end
                }
                local _, err = generate_handler.handler(streamed_args)
                local details = (err :: any):details()
                test.eq(details.error_type, "server_error")
                test.is_nil(details.stream_started)
                test.eq(err:message(), "PID is required for streamer")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
