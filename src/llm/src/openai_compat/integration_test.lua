local generate_handler = require("generate_handler")
local embed_handler = require("embed_handler")
local structured_output_handler = require("structured_output_handler")
local status_handler = require("status_handler")
local json = require("json")
local env = require("env")
local ctx = require("ctx")
local test = require("test")

local function define_tests()
    -- Toggle to enable/disable real API integration tests
    local RUN_INTEGRATION_TESTS = env.get("ENABLE_INTEGRATION_TESTS")

    describe("OpenAI Integration Tests", function()
        local actual_api_key = nil

        before_all(function()
            -- Check if we have a real API key for integration tests.
            -- Prefer OPENAI_COMPAT_API_KEY; fall back to OPENAI_API_KEY for
            -- developers who already have OpenAI configured locally.
            actual_api_key = env.get("OPENAI_COMPAT_API_KEY") or env.get("OPENAI_API_KEY")

            if RUN_INTEGRATION_TESTS then
                if actual_api_key and #actual_api_key > 10 then
                    print("Integration tests will run with real API key")
                else
                    print("Integration tests disabled - no valid API key found")
                    RUN_INTEGRATION_TESTS = false
                end
            else
                print("Integration tests disabled - set ENABLE_INTEGRATION_TESTS=true to enable")
            end
        end)

        before_each(function()
            -- Set up context with API key for each test
            if actual_api_key then
                generate_handler._client._ctx = {
                    all = function()
                        return { api_key = actual_api_key }
                    end
                }

                embed_handler._client._ctx = {
                    all = function()
                        return { api_key = actual_api_key }
                    end
                }

                structured_output_handler._client._ctx = {
                    all = function()
                        return { api_key = actual_api_key }
                    end
                }

                -- Mock env dependency (return nil for environment lookups)
                generate_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                embed_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                structured_output_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }
            end
        end)

        after_each(function()
            -- Clean up mocked dependencies
            generate_handler._client._ctx = nil
            generate_handler._client._env = nil
            generate_handler._output = nil

            embed_handler._client._ctx = nil
            embed_handler._client._env = nil

            structured_output_handler._client._ctx = nil
            structured_output_handler._client._env = nil
        end)

        describe("Text Generation Integration", function()
            it("should generate text with gpt-4o-mini", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping integration test - not enabled")
                    return
                end

                local contract_args = {
                    model = "gpt-4o-mini",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "Reply with exactly 'Integration test successful'" }}
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 10
                    }
                }

                local response = generate_handler.handler(contract_args)

                test.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                test.contains(tostring(response.result.content), "Integration test successful")
                test.is_true(response.tokens.prompt_tokens > 0, "No prompt tokens reported")
                test.is_true(response.tokens.completion_tokens > 0, "No completion tokens reported")
                test.is_true(response.tokens.total_tokens > 0, "No total tokens reported")
                test.eq(response.finish_reason, "stop")
            end)

            it("should handle system messages in text generation", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping system message test - not enabled")
                    return
                end

                local contract_args = {
                    model = "gpt-4o-mini",
                    messages = {
                        {
                            role = "system",
                            content = {{ type = "text", text = "You are a helpful assistant who responds with enthusiasm. Always start with 'Absolutely!'" }}
                        },
                        {
                            role = "user",
                            content = {{ type = "text", text = "Can you help me?" }}
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 20
                    }
                }

                local response = generate_handler.handler(contract_args)

                test.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                test.contains(tostring(response.result.content), "Absolutely")
            end)

            it("should generate text with tool calling", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping integration test - not enabled")
                    return
                end

                local contract_args = {
                    model = "gpt-4o-mini",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "Calculate 15 * 7 using the calculator" }}
                        }
                    },
                    tools = {
                        {
                            name = "calculate",
                            description = "Perform mathematical calculations",
                            schema = {
                                type = "object",
                                properties = {
                                    expression = { type = "string", description = "Mathematical expression" }
                                },
                                required = { "expression" }
                            }
                        }
                    },
                    tool_choice = "calculate",
                    options = {
                        temperature = 0
                    }
                }

                local response = generate_handler.handler(contract_args)

                test.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                test.not_nil(response.result.tool_calls, "No tool calls in response")
                test.is_true(#response.result.tool_calls > 0, "Expected at least one tool call")
                assert(response.result.tool_calls[1])
                test.eq(response.result.tool_calls[1].name, "calculate")
                test.contains(tostring(response.result.tool_calls[1].arguments.expression), "15")
                test.contains(tostring(response.result.tool_calls[1].arguments.expression), "7")
                -- Forced tool_choice returns "stop" from OpenAI API
                test.is_true(
                    response.finish_reason == "tool_call" or response.finish_reason == "stop",
                    "finish_reason should be tool_call or stop, got: " .. tostring(response.finish_reason)
                )
            end)

            it("should handle multiple tool calls", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping multiple tool calls test - not enabled")
                    return
                end

                local contract_args = {
                    model = "gpt-4o",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "What's the weather in London and calculate 20 * 30?" }}
                        }
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
                    },
                    options = {
                        temperature = 0
                    }
                }

                local response = generate_handler.handler(contract_args)

                test.is_true(response.success, "Multiple tool calls failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                test.not_nil(response.result.tool_calls, "No tool calls in response")
                test.is_true(#response.result.tool_calls > 0, "Expected at least one tool call")
            end)

            it("should generate text with gpt-5-mini reasoning model", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping integration test - not enabled")
                    return
                end

                local contract_args = {
                    model = "gpt-5-mini",
                    messages = {
                        {
                            role = "user",
                            content = {{
                                type = "text",
                                text = "Think step by step: If a train travels 60 mph for 2 hours, then 40 mph for 1 hour, what's the total distance?"
                            }}
                        }
                    },
                    options = {
                        reasoning_model_request = true,
                        thinking_effort = 25,
                        max_tokens = 2000
                    }
                }

                local response = generate_handler.handler(contract_args)

                test.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                test.contains(tostring(response.result.content), "160")  -- 120 + 40 = 160 miles
                test.not_nil(response.tokens.thinking_tokens, "No thinking tokens reported")
                test.is_true(response.tokens.thinking_tokens > 0, "Expected non-zero thinking tokens")
                test.eq(response.finish_reason, "stop")
            end)

            it("should handle gpt-5-mini with thinking effort", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping gpt-5-mini test - not enabled")
                    return
                end

                local contract_args = {
                    model = "gpt-5-mini",
                    messages = {
                        {
                            role = "user",
                            content = {{
                                type = "text",
                                text = "Calculate the compound interest: Principal $1000, Rate 5% annual, Time 3 years. Show your work."
                            }}
                        }
                    },
                    options = {
                        reasoning_model_request = true,
                        thinking_effort = 30,
                        max_tokens = 2000
                    }
                }

                local response = generate_handler.handler(contract_args)

                test.is_true(response.success, "gpt-5-mini request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                test.not_nil(response.result.content, "No content in response")
                test.not_nil(response.tokens.thinking_tokens, "No thinking tokens")
                test.is_true(response.tokens.thinking_tokens > 0, "Expected thinking tokens")
            end)

            it("should handle streaming generation", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping integration test - not enabled")
                    return
                end

                -- Mock the output module for streaming since we can't test real streaming easily
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
                        {
                            role = "user",
                            content = {{ type = "text", text = "Count from 1 to 5 separated by spaces" }}
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 20
                    },
                    stream = {
                        reply_to = "integration-test-pid",
                        topic = "integration_stream"
                    }
                }

                local response = generate_handler.handler(contract_args)

                test.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                test.contains(tostring(response.result.content), "1")
                test.contains(tostring(response.result.content), "5")
                test.is_true(response.tokens.prompt_tokens > 0, "No prompt tokens reported")
                test.eq(response.finish_reason, "stop")
            end)
        end)

        describe("Streaming Integration Tests", function()
            it("should stream simple text generation", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping streaming test - not enabled")
                    return
                end

                local streaming_events = {}
                local mock_streamer = {
                    buffer_content = function(self, chunk)
                        table.insert(streaming_events, {type = "content", data = chunk})
                    end,
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
                        {
                            role = "user",
                            content = {{type = "text", text = "Count from 1 to 5, separated by commas"}}
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 50
                    },
                    stream = {
                        reply_to = "test-streaming-pid",
                        topic = "test_basic_stream"
                    }
                }

                local response = generate_handler.handler(contract_args)

                test.is_true(response.success, "Streaming request failed: " .. (response.error_message or "unknown"))
                assert(response.success)
                test.not_nil(response.result.content, "No content in streaming response")
                test.contains(tostring(response.result.content), "1")
                test.contains(tostring(response.result.content), "5")

                -- Verify streaming events occurred
                local content_events = 0
                for _, event in ipairs(streaming_events) do
                    if event.type == "content" then
                        content_events = content_events + 1
                    end
                end
                test.is_true(content_events > 0, "No content streaming events occurred")

                test.is_true(response.tokens.prompt_tokens > 0, "No prompt tokens")
                test.is_true(response.tokens.completion_tokens > 0, "No completion tokens")
                test.eq(response.finish_reason, "stop")
            end)

            it("should handle streaming with system prompts", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping streaming system prompt test - not enabled")
                    return
                end

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
                        {
                            role = "system",
                            content = {{type = "text", text = "You are a robot. Start every response with 'BEEP BOOP:'"}}
                        },
                        {
                            role = "user",
                            content = {{type = "text", text = "Say hello"}}
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 30
                    },
                    stream = {
                        reply_to = "test-system-streaming-pid",
                        topic = "test_system_stream"
                    }
                }

                local response = generate_handler.handler(contract_args)

                test.is_true(response.success, "Streaming with system prompt failed")
                assert(response.success)
                test.not_nil(response.result.content:upper():find("BEEP"), "Response doesn't follow system prompt: " .. response.result.content)
            end)

            it("should stream tool calls", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping streaming tool call test - not enabled")
                    return
                end

                local streaming_events = {}
                local mock_streamer = {
                    buffer_content = function(self, chunk)
                        table.insert(streaming_events, {type = "content", data = chunk})
                    end,
                    send_tool_call = function(self, name, args, id)
                        table.insert(streaming_events, {type = "tool_call", name = name, args = args, id = id})
                    end,
                    send_error = function(self, error, message) end,
                    flush = function(self) end
                }

                generate_handler._output = {
                    streamer = function(reply_to, topic, buffer_size)
                        return mock_streamer
                    end
                }

                local contract_args = {
                    model = "gpt-4o",
                    messages = {
                        {
                            role = "user",
                            content = {{type = "text", text = "Calculate the area of a circle with radius 10cm"}}
                        }
                    },
                    tools = {
                        {
                            name = "calculate",
                            description = "Perform mathematical calculations",
                            schema = {
                                type = "object",
                                properties = {
                                    expression = {type = "string", description = "Mathematical expression"}
                                },
                                required = {"expression"}
                            }
                        }
                    },
                    options = {
                        temperature = 0
                    },
                    stream = {
                        reply_to = "test-tool-streaming-pid",
                        topic = "test_tool_stream"
                    }
                }

                local response = generate_handler.handler(contract_args)

                test.is_true(response.success, "Streaming tool call failed: " .. (response.error_message or "unknown"))
                assert(response.success)
                test.not_nil(response.result.tool_calls, "No tool calls in response")
                test.is_true(#response.result.tool_calls > 0, "Expected at least one tool call")

                local tool_call = response.result.tool_calls[1]
                assert(tool_call)
                test.eq(tool_call.name, "calculate")
                test.not_nil(tool_call.arguments.expression, "No expression in tool call")

                -- Verify streaming events
                local tool_call_events = 0
                for _, event in ipairs(streaming_events) do
                    if event.type == "tool_call" then
                        tool_call_events = tool_call_events + 1
                    end
                end
                test.is_true(tool_call_events > 0, "No tool call streaming events occurred")

                test.eq(response.finish_reason, "tool_call")
            end)

            it("should handle streaming conversation with tool results", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping streaming conversation flow test - not enabled")
                    return
                end

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

                -- Step 1: Get tool call response
                local initial_args = {
                    model = "gpt-4o",
                    messages = {
                        {
                            role = "user",
                            content = {{type = "text", text = "What is the square root of 144?"}}
                        }
                    },
                    tools = {
                        {
                            name = "calculate",
                            description = "Perform mathematical calculations",
                            schema = {
                                type = "object",
                                properties = {
                                    expression = {type = "string"}
                                },
                                required = {"expression"}
                            }
                        }
                    },
                    options = {
                        temperature = 0
                    },
                    stream = {
                        reply_to = "test-conversation-streaming-pid",
                        topic = "test_conversation_stream"
                    }
                }

                local initial_response = generate_handler.handler(initial_args)

                test.is_true(initial_response.success, "Initial streaming request failed")
                assert(initial_response.success)
                test.not_nil(initial_response.result.tool_calls, "No tool calls in initial response")
                test.is_true(#initial_response.result.tool_calls > 0, "Expected tool call")

                local tool_call = initial_response.result.tool_calls[1]
                assert(tool_call)

                -- Step 2: Continue conversation with tool result - using proper contract format
                local continuation_args = {
                    model = "gpt-4o",
                    messages = {
                        {
                            role = "user",
                            content = {{type = "text", text = "What is the square root of 144?"}}
                        },
                        {
                            role = "function_call",
                            function_call = {
                                id = tool_call.id,
                                name = tool_call.name,
                                arguments = tool_call.arguments
                            }
                        },
                        {
                            role = "function_result",
                            function_call_id = tool_call.id,
                            name = tool_call.name,
                            content = {{type = "text", text = "The square root of 144 is 12"}}
                        }
                    },
                    options = {
                        temperature = 0
                    },
                    stream = {
                        reply_to = "test-conversation-streaming-pid",
                        topic = "test_conversation_stream"
                    }
                }

                local continuation_response = generate_handler.handler(continuation_args)

                test.is_true(continuation_response.success, "Continuation streaming failed: " .. (continuation_response.error_message or "unknown"))
                assert(continuation_response.success)
                test.contains(tostring(continuation_response.result.content), "12")
                test.eq(continuation_response.finish_reason, "stop")
            end)

            it("should handle streaming with gpt-5-mini reasoning", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping gpt-5-mini streaming test - not enabled")
                    return
                end

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
                    model = "gpt-5-mini",
                    messages = {
                        {
                            role = "user",
                            content = {{type = "text", text = "Think step by step: If I have 3 apples and buy 5 more, then give away 2, how many do I have left?"}}
                        }
                    },
                    options = {
                        reasoning_model_request = true,
                        thinking_effort = 30,
                        max_tokens = 2000
                    },
                    stream = {
                        reply_to = "test-reasoning-streaming-pid",
                        topic = "test_reasoning_stream"
                    }
                }

                local response = generate_handler.handler(contract_args)

                test.is_true(response.success, "gpt-5-mini streaming failed: " .. (response.error_message or "unknown"))
                assert(response.success)
                test.not_nil(response.result.content, "No content in response")
                test.is_true(#response.result.content > 0, "Response should have content")

                -- Verify reasoning tokens
                test.not_nil(response.tokens.thinking_tokens, "No thinking tokens")
                test.is_true(response.tokens.thinking_tokens > 0, "Thinking tokens should be non-zero")
                test.eq(response.finish_reason, "stop")
            end)

            it("should handle streaming with gpt-5-mini percentage calculation", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping gpt-5-mini percentage streaming test - not enabled")
                    return
                end

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
                    model = "gpt-5-mini",
                    messages = {
                        {
                            role = "user",
                            content = {{type = "text", text = "Calculate step by step: What is 25% of 240?"}}
                        }
                    },
                    options = {
                        reasoning_model_request = true,
                        thinking_effort = 25,
                        max_tokens = 2000
                    },
                    stream = {
                        reply_to = "test-gpt5-streaming-pid",
                        topic = "test_gpt5_stream"
                    }
                }

                local response = generate_handler.handler(contract_args)

                test.is_true(response.success, "gpt-5-mini percentage streaming failed: " .. (response.error_message or "unknown"))
                assert(response.success)
                test.not_nil(response.result.content, "No content in response")
                test.is_true(#response.result.content > 0, "Response should have content")

                -- Verify reasoning tokens
                test.not_nil(response.tokens.thinking_tokens, "No thinking tokens")
                test.is_true(response.tokens.thinking_tokens > 0, "Thinking tokens should be non-zero")
                test.eq(response.finish_reason, "stop")
            end)
        end)

        describe("Embeddings Integration", function()
            it("should generate embeddings with text-embedding-3-small", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping integration test - not enabled")
                    return
                end

                local contract_args = {
                    model = "text-embedding-3-small",
                    input = "This is a test sentence for embedding generation"
                }

                local response = embed_handler.handler(contract_args)

                test.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                test.not_nil(response.result.embeddings, "No embeddings in response")
                test.eq(#response.result.embeddings, 1, "Expected 1 embedding")
                test.eq(type(response.result.embeddings[1]), "table", "Embedding should be array")
                test.is_true(#response.result.embeddings[1] > 100, "Embedding should have many dimensions")
                test.is_true(response.tokens.prompt_tokens > 0, "No prompt tokens reported")
                test.is_true(response.tokens.total_tokens > 0, "No total tokens reported")
            end)

            it("should generate multiple embeddings", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping integration test - not enabled")
                    return
                end

                local contract_args = {
                    model = "text-embedding-3-small",
                    input = {
                        "First test sentence for embedding",
                        "Second different sentence for comparison"
                    }
                }

                local response = embed_handler.handler(contract_args)

                test.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                test.not_nil(response.result.embeddings, "No embeddings in response")
                test.eq(#response.result.embeddings, 2, "Expected 2 embeddings")
                test.eq(type(response.result.embeddings[1]), "table", "First embedding should be array")
                test.eq(type(response.result.embeddings[2]), "table", "Second embedding should be array")
                test.eq(#response.result.embeddings[1], #response.result.embeddings[2], "Embeddings should have same dimensions")
                test.is_true(response.tokens.prompt_tokens > 0, "No prompt tokens reported")
            end)

            it("should respect dimensions parameter", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping integration test - not enabled")
                    return
                end

                local contract_args = {
                    model = "text-embedding-3-small",
                    input = "Test sentence with custom dimensions",
                    options = {
                        dimensions = 512
                    }
                }

                local response = embed_handler.handler(contract_args)

                test.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                test.not_nil(response.result.embeddings, "No embeddings in response")
                test.eq(#response.result.embeddings[1], 512, "Expected 512 dimensions")
            end)
        end)

        describe("Structured Output Integration", function()
            it("should generate structured output with gpt-4o", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping integration test - not enabled")
                    return
                end

                local contract_args = {
                    model = "gpt-4o",
                    messages = {
                        {
                            role = "user",
                            content = {{
                                type = "text",
                                text = "Create a fictional person profile with name, age, and occupation"
                            }}
                        }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            name = { type = "string" },
                            age = { type = "number" },
                            occupation = { type = "string" }
                        },
                        required = { "name", "age", "occupation" },
                        additionalProperties = false
                    },
                    options = {
                        temperature = 0
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                test.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                test.not_nil(response.result.data, "No structured data in response")
                assert(response.result.data)
                test.not_nil(response.result.data.name, "Missing name in structured output")
                test.eq(type(response.result.data.name), "string", "Name should be string")
                test.not_nil(response.result.data.age, "Missing age in structured output")
                test.eq(type(response.result.data.age), "number", "Age should be number")
                test.not_nil(response.result.data.occupation, "Missing occupation in structured output")
                assert(response.result.data)
                test.eq(type(response.result.data.occupation), "string", "Occupation should be string")
                test.is_true(response.tokens.prompt_tokens > 0, "No prompt tokens reported")
                test.eq(response.finish_reason, "stop")
            end)

            it("should generate complex nested structured output", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping integration test - not enabled")
                    return
                end

                local contract_args = {
                    model = "gpt-4o",
                    messages = {
                        {
                            role = "user",
                            content = {{
                                type = "text",
                                text = "Create a company profile with basic info and a list of departments"
                            }}
                        }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            company_name = { type = "string" },
                            founded_year = { type = "number" },
                            headquarters = { type = "string" },
                            departments = {
                                type = "array",
                                items = {
                                    type = "object",
                                    properties = {
                                        name = { type = "string" },
                                        employees = { type = "number" }
                                    },
                                    required = { "name", "employees" },
                                    additionalProperties = false
                                }
                            }
                        },
                        required = { "company_name", "founded_year", "headquarters", "departments" },
                        additionalProperties = false
                    },
                    options = {
                        temperature = 0
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                test.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                test.not_nil(response.result.data, "No structured data in response")
                assert(response.result.data)
                test.not_nil(response.result.data.company_name, "Missing company_name")
                test.not_nil(response.result.data.departments, "Missing departments")
                test.eq(type(response.result.data.departments), "table", "Departments should be array")
                test.is_true(#response.result.data.departments > 0, "Should have at least one department")

                assert(response.result.data)
                local first_dept = response.result.data.departments[1]
                test.not_nil(first_dept.name, "First department missing name")
                test.not_nil(first_dept.employees, "First department missing employees")
                test.eq(type(first_dept.employees), "number", "Employee count should be number")
            end)

            it("should generate structured output with gpt-5-mini reasoning", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping gpt-5-mini structured output test - not enabled")
                    return
                end

                local contract_args = {
                    model = "gpt-5-mini",
                    messages = {
                        {
                            role = "user",
                            content = {{
                                type = "text",
                                text = "Analyze this problem: 'If 5 apples cost $3, how much do 8 apples cost?' Provide a structured solution."
                            }}
                        }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            problem_type = { type = "string" },
                            given_values = {
                                type = "object",
                                properties = {
                                    apples = { type = "number" },
                                    cost = { type = "number" }
                                },
                                required = { "apples", "cost" },
                                additionalProperties = false
                            },
                            solution_steps = {
                                type = "array",
                                items = { type = "string" }
                            },
                            final_answer = { type = "number" }
                        },
                        required = { "problem_type", "given_values", "solution_steps", "final_answer" },
                        additionalProperties = false
                    },
                    schema_name = "math_solution",
                    options = {
                        reasoning_model_request = true,
                        thinking_effort = 30,
                        max_tokens = 2000
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                test.is_true(response.success, "gpt-5-mini structured output failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                test.not_nil(response.result.data, "No structured data in response")
                assert(response.result.data)
                test.not_nil(response.result.data.problem_type, "Missing problem_type")
                test.eq(response.result.data.given_values.apples, 5)
                test.eq(response.result.data.given_values.cost, 3)
                test.eq(response.result.data.final_answer, 4.8) -- 8 * 3/5 = 4.8
                test.not_nil(response.tokens.thinking_tokens, "No thinking tokens reported")
                test.is_true(response.tokens.thinking_tokens > 0, "Expected non-zero thinking tokens")
            end)
        end)

        describe("Error Handling Integration", function()
            it("should handle model not found errors", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping integration test - not enabled")
                    return
                end

                local contract_args = {
                    model = "nonexistent-model-123",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "Test message" }}
                        }
                    }
                }

                local response = generate_handler.handler(contract_args)

                test.is_false(response.success, "Expected error for nonexistent model")
                test.eq(response.error, "model_error")
                test.contains(tostring(response.error_message), "does not exist")
            end)

            it("should handle authentication errors", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping authentication error test - not enabled")
                    return
                end

                -- Temporarily override with invalid key
                generate_handler._client._ctx = {
                    all = function()
                        return { api_key = "invalid-key-12345" }
                    end
                }

                local contract_args = {
                    model = "gpt-4o-mini",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "Test message" }}
                        }
                    }
                }

                local response = generate_handler.handler(contract_args)

                test.is_false(response.success, "Expected authentication error")
                test.eq(response.error, "authentication_error")

                -- Restore valid key
                generate_handler._client._ctx = {
                    all = function()
                        return { api_key = actual_api_key }
                    end
                }
            end)

            it("should handle invalid schema errors", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping integration test - not enabled")
                    return
                end

                local contract_args = {
                    model = "gpt-4o",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "Generate data" }}
                        }
                    },
                    schema = {
                        type = "array",  -- Should be object for root schema
                        items = { type = "string" }
                    }
                }

                local response, err = structured_output_handler.handler(contract_args)

                test.is_false(response.success, "Expected error for invalid schema")
                test.eq(response.error, "invalid_request")
                test.contains(tostring(response.error_message), "Root schema must be an object")
            end)

            it("should handle rate limit errors gracefully", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping rate limit test - not enabled (would need rate limiting)")
                    return
                end

                -- Note: This test is hard to trigger reliably in normal circumstances
                print("Rate limit test placeholder - would need specific setup to trigger")
            end)
        end)

        describe("Performance and Edge Cases", function()
            it("should handle large context with proper limits", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping large context test - not enabled")
                    return
                end

                -- Create moderately large but valid content
                local large_content = string.rep("This is test content. ", 1000) -- ~20k characters

                local contract_args = {
                    model = "gpt-4o-mini",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = large_content .. " Summarize this in one sentence." }}
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 50
                    }
                }

                local response = generate_handler.handler(contract_args)

                test.is_true(response.success, "Large context request failed: " .. (response.error_message or "unknown"))
                assert(response.success)
                test.not_nil(response.result.content, "No content in response")
                test.is_true(response.tokens.prompt_tokens > 1000, "Expected many prompt tokens")
            end)

            it("should preserve metadata across all handler types", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping metadata test - not enabled")
                    return
                end

                -- Test metadata in text generation
                local gen_response = generate_handler.handler({
                    model = "gpt-4o-mini",
                    messages = {{ role = "user", content = {{ type = "text", text = "Hello" }} }},
                    options = { temperature = 0, max_tokens = 5 }
                })

                test.is_true(gen_response.success, "Text generation failed")
                assert(gen_response.success)
                test.not_nil(gen_response.metadata, "No metadata in text generation")

                -- Test metadata in embeddings
                local embed_response = embed_handler.handler({
                    model = "text-embedding-3-small",
                    input = "Test metadata"
                })

                test.is_true(embed_response.success, "Embeddings failed")
                assert(embed_response.success)
                test.not_nil(embed_response.metadata, "No metadata in embeddings")

                -- Test metadata in structured output
                local struct_response = structured_output_handler.handler({
                    model = "gpt-4o",
                    messages = {{ role = "user", content = {{ type = "text", text = "Generate test data" }} }},
                    schema = {
                        type = "object",
                        properties = { test = { type = "boolean" } },
                        required = { "test" },
                        additionalProperties = false
                    }
                })

                test.is_true(struct_response.success, "Structured output failed")
                assert(struct_response.success)
                test.not_nil(struct_response.metadata, "No metadata in structured output")
            end)
        end)

        describe("Status Handler Integration Tests", function()
            local actual_api_key = nil

            before_all(function()
                actual_api_key = env.get("OPENAI_COMPAT_API_KEY") or env.get("OPENAI_API_KEY")
                if not RUN_INTEGRATION_TESTS or not actual_api_key then
                    print("Status integration tests disabled")
                end
            end)

            before_each(function()
                if actual_api_key then
                    status_handler._client._ctx = {
                        all = function()
                            return { api_key = actual_api_key }
                        end
                    }
                    status_handler._client._env = {
                        get = function(key)
                            return nil
                        end
                    }
                end
            end)

            after_each(function()
                status_handler._client._ctx = nil
                status_handler._client._env = nil
            end)

            it("should return healthy status with real API", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping real API status test")
                    return
                end

                local response = status_handler.handler()

                test.is_true(response.success, "API status check failed")
                assert(response.success)
                test.eq(response.status, "healthy")
                test.eq(response.message, "OpenAI API is responding normally")
            end)

            it("should handle invalid API key", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping invalid key test")
                    return
                end

                status_handler._client._ctx = {
                    all = function()
                        return { api_key = "sk-invalid12345" }
                    end
                }

                local response = status_handler.handler()

                test.is_false(response.success, "Expected auth failure")
                test.eq(response.status, "unhealthy")
                test.contains(tostring(response.message), "Incorrect API")
            end)

            it("should work with custom base URL", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping custom base URL test")
                    return
                end

                status_handler._client._ctx = {
                    all = function()
                        return {
                            api_key = actual_api_key,
                            base_url = "https://api.openai.com/v1"
                        }
                    end
                }

                local response = status_handler.handler()

                test.is_true(response.success, "Custom base URL failed")
                assert(response.success)
                test.eq(response.status, "healthy")
            end)

            it("should handle organization context", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping organization test")
                    return
                end

                local test_org = env.get("OPENAI_COMPAT_ORGANIZATION") or env.get("OPENAI_ORGANIZATION")
                if test_org then
                    status_handler._client._ctx = {
                        all = function()
                            return {
                                api_key = actual_api_key,
                                organization = test_org
                            }
                        end
                    }

                    local response = status_handler.handler()

                    test.is_true(response.success, "Organization context failed")
                    assert(response.success)
                    test.eq(response.status, "healthy")
                else
                    print("Skipping org test - no OPENAI_COMPAT_ORGANIZATION / OPENAI_ORGANIZATION env var")
                end
            end)

            it("should handle connection timeout", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping timeout test")
                    return
                end

                status_handler._client._ctx = {
                    all = function()
                        return {
                            api_key = actual_api_key,
                            base_url = "https://httpstat.us/200?sleep=5000",
                            timeout = 1
                        }
                    end
                }

                local response = status_handler.handler()

                test.is_false(response.success, "Expected timeout")
                test.eq(response.status, "unhealthy")
                test.contains(tostring(response.message), "Connection failed")
            end)

            it("should resolve API key from environment", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping env resolution test")
                    return
                end

                status_handler._client._ctx = {
                    all = function()
                        return { api_key_env = "OPENAI_COMPAT_API_KEY" }
                    end
                }

                status_handler._client._env = {
                    get = function(key)
                        if key == "OPENAI_COMPAT_API_KEY" then
                            return actual_api_key
                        end
                        return nil
                    end
                }

                local response = status_handler.handler()

                test.is_true(response.success, "Env API key resolution failed")
                assert(response.success)
                test.eq(response.status, "healthy")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
