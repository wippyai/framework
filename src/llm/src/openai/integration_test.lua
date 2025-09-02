local generate_handler = require("generate_handler")
local embed_handler = require("embed_handler")
local structured_output_handler = require("structured_output_handler")
local status_handler = require("status_handler")
local json = require("json")
local env = require("env")
local ctx = require("ctx")

local function define_tests()
    -- Toggle to enable/disable real API integration tests
    local RUN_INTEGRATION_TESTS = env.get("ENABLE_INTEGRATION_TESTS")

    describe("OpenAI Integration Tests", function()
        local actual_api_key = nil

        before_all(function()
            -- Check if we have a real API key for integration tests
            actual_api_key = env.get("OPENAI_API_KEY")

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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content).to_contain("Integration test successful")
                expect(response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens reported")
                expect(response.tokens.completion_tokens > 0).to_be_true("No completion tokens reported")
                expect(response.tokens.total_tokens > 0).to_be_true("No total tokens reported")
                expect(response.finish_reason).to_equal("stop")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content).to_contain("Absolutely")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.tool_calls).not_to_be_nil("No tool calls in response")
                expect(#response.result.tool_calls > 0).to_be_true("Expected at least one tool call")
                expect(response.result.tool_calls[1].name).to_equal("calculate")
                expect(response.result.tool_calls[1].arguments.expression).to_contain("15")
                expect(response.result.tool_calls[1].arguments.expression).to_contain("7")
                expect(response.finish_reason).to_equal("tool_call")
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

                expect(response.success).to_be_true("Multiple tool calls failed: " .. (response.error_message or "unknown error"))
                expect(response.result.tool_calls).not_to_be_nil("No tool calls in response")
                expect(#response.result.tool_calls > 0).to_be_true("Expected at least one tool call")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content).to_contain("160")  -- 120 + 40 = 160 miles
                expect(response.tokens.thinking_tokens).not_to_be_nil("No thinking tokens reported")
                expect(response.tokens.thinking_tokens > 0).to_be_true("Expected non-zero thinking tokens")
                expect(response.finish_reason).to_equal("stop")
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

                expect(response.success).to_be_true("gpt-5-mini request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content).not_to_be_nil("No content in response")
                expect(response.tokens.thinking_tokens).not_to_be_nil("No thinking tokens")
                expect(response.tokens.thinking_tokens > 0).to_be_true("Expected thinking tokens")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content).to_contain("1")
                expect(response.result.content).to_contain("5")
                expect(response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens reported")
                expect(response.finish_reason).to_equal("stop")
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

                expect(response.success).to_be_true("Streaming request failed: " .. (response.error_message or "unknown"))
                expect(response.result.content).not_to_be_nil("No content in streaming response")
                expect(response.result.content).to_contain("1")
                expect(response.result.content).to_contain("5")

                -- Verify streaming events occurred
                local content_events = 0
                for _, event in ipairs(streaming_events) do
                    if event.type == "content" then
                        content_events = content_events + 1
                    end
                end
                expect(content_events > 0).to_be_true("No content streaming events occurred")

                expect(response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens")
                expect(response.tokens.completion_tokens > 0).to_be_true("No completion tokens")
                expect(response.finish_reason).to_equal("stop")
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

                expect(response.success).to_be_true("Streaming with system prompt failed")
                expect(response.result.content:upper():find("BEEP")).not_to_be_nil("Response doesn't follow system prompt: " .. response.result.content)
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

                expect(response.success).to_be_true("Streaming tool call failed: " .. (response.error_message or "unknown"))
                expect(response.result.tool_calls).not_to_be_nil("No tool calls in response")
                expect(#response.result.tool_calls > 0).to_be_true("Expected at least one tool call")

                local tool_call = response.result.tool_calls[1]
                expect(tool_call.name).to_equal("calculate")
                expect(tool_call.arguments.expression).not_to_be_nil("No expression in tool call")

                -- Verify streaming events
                local tool_call_events = 0
                for _, event in ipairs(streaming_events) do
                    if event.type == "tool_call" then
                        tool_call_events = tool_call_events + 1
                    end
                end
                expect(tool_call_events > 0).to_be_true("No tool call streaming events occurred")

                expect(response.finish_reason).to_equal("tool_call")
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

                expect(initial_response.success).to_be_true("Initial streaming request failed")
                expect(initial_response.result.tool_calls).not_to_be_nil("No tool calls in initial response")
                expect(#initial_response.result.tool_calls > 0).to_be_true("Expected tool call")

                local tool_call = initial_response.result.tool_calls[1]

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

                expect(continuation_response.success).to_be_true("Continuation streaming failed: " .. (continuation_response.error_message or "unknown"))
                expect(continuation_response.result.content).to_contain("12")
                expect(continuation_response.finish_reason).to_equal("stop")
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

                expect(response.success).to_be_true("gpt-5-mini streaming failed: " .. (response.error_message or "unknown"))
                expect(response.result.content).not_to_be_nil("No content in response")
                expect(#response.result.content > 0).to_be_true("Response should have content")

                -- Verify reasoning tokens
                expect(response.tokens.thinking_tokens).not_to_be_nil("No thinking tokens")
                expect(response.tokens.thinking_tokens > 0).to_be_true("Thinking tokens should be non-zero")
                expect(response.finish_reason).to_equal("stop")
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

                expect(response.success).to_be_true("gpt-5-mini percentage streaming failed: " .. (response.error_message or "unknown"))
                expect(response.result.content).not_to_be_nil("No content in response")
                expect(#response.result.content > 0).to_be_true("Response should have content")

                -- Verify reasoning tokens
                expect(response.tokens.thinking_tokens).not_to_be_nil("No thinking tokens")
                expect(response.tokens.thinking_tokens > 0).to_be_true("Thinking tokens should be non-zero")
                expect(response.finish_reason).to_equal("stop")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.embeddings).not_to_be_nil("No embeddings in response")
                expect(#response.result.embeddings).to_equal(1, "Expected 1 embedding")
                expect(type(response.result.embeddings[1])).to_equal("table", "Embedding should be array")
                expect(#response.result.embeddings[1] > 100).to_be_true("Embedding should have many dimensions")
                expect(response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens reported")
                expect(response.tokens.total_tokens > 0).to_be_true("No total tokens reported")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.embeddings).not_to_be_nil("No embeddings in response")
                expect(#response.result.embeddings).to_equal(2, "Expected 2 embeddings")
                expect(type(response.result.embeddings[1])).to_equal("table", "First embedding should be array")
                expect(type(response.result.embeddings[2])).to_equal("table", "Second embedding should be array")
                expect(#response.result.embeddings[1]).to_equal(#response.result.embeddings[2], "Embeddings should have same dimensions")
                expect(response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens reported")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.embeddings).not_to_be_nil("No embeddings in response")
                expect(#response.result.embeddings[1]).to_equal(512, "Expected 512 dimensions")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.data).not_to_be_nil("No structured data in response")
                expect(response.result.data.name).not_to_be_nil("Missing name in structured output")
                expect(type(response.result.data.name)).to_equal("string", "Name should be string")
                expect(response.result.data.age).not_to_be_nil("Missing age in structured output")
                expect(type(response.result.data.age)).to_equal("number", "Age should be number")
                expect(response.result.data.occupation).not_to_be_nil("Missing occupation in structured output")
                expect(type(response.result.data.occupation)).to_equal("string", "Occupation should be string")
                expect(response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens reported")
                expect(response.finish_reason).to_equal("stop")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.data).not_to_be_nil("No structured data in response")
                expect(response.result.data.company_name).not_to_be_nil("Missing company_name")
                expect(response.result.data.departments).not_to_be_nil("Missing departments")
                expect(type(response.result.data.departments)).to_equal("table", "Departments should be array")
                expect(#response.result.data.departments > 0).to_be_true("Should have at least one department")

                local first_dept = response.result.data.departments[1]
                expect(first_dept.name).not_to_be_nil("First department missing name")
                expect(first_dept.employees).not_to_be_nil("First department missing employees")
                expect(type(first_dept.employees)).to_equal("number", "Employee count should be number")
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

                expect(response.success).to_be_true("gpt-5-mini structured output failed: " .. (response.error_message or "unknown error"))
                expect(response.result.data).not_to_be_nil("No structured data in response")
                expect(response.result.data.problem_type).not_to_be_nil("Missing problem_type")
                expect(response.result.data.given_values.apples).to_equal(5)
                expect(response.result.data.given_values.cost).to_equal(3)
                expect(response.result.data.final_answer).to_equal(4.8) -- 8 * 3/5 = 4.8
                expect(response.tokens.thinking_tokens).not_to_be_nil("No thinking tokens reported")
                expect(response.tokens.thinking_tokens > 0).to_be_true("Expected non-zero thinking tokens")
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

                expect(response.success).to_be_false("Expected error for nonexistent model")
                expect(response.error).to_equal("model_error")
                expect(response.error_message).to_contain("does not exist")
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

                expect(response.success).to_be_false("Expected authentication error")
                expect(response.error).to_equal("authentication_error")

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

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_false("Expected error for invalid schema")
                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_contain("Root schema must be an object")
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

                expect(response.success).to_be_true("Large context request failed: " .. (response.error_message or "unknown"))
                expect(response.result.content).not_to_be_nil("No content in response")
                expect(response.tokens.prompt_tokens > 1000).to_be_true("Expected many prompt tokens")
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

                expect(gen_response.success).to_be_true("Text generation failed")
                expect(gen_response.metadata).not_to_be_nil("No metadata in text generation")

                -- Test metadata in embeddings
                local embed_response = embed_handler.handler({
                    model = "text-embedding-3-small",
                    input = "Test metadata"
                })

                expect(embed_response.success).to_be_true("Embeddings failed")
                expect(embed_response.metadata).not_to_be_nil("No metadata in embeddings")

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

                expect(struct_response.success).to_be_true("Structured output failed")
                expect(struct_response.metadata).not_to_be_nil("No metadata in structured output")
            end)
        end)

        describe("Status Handler Integration Tests", function()
            local actual_api_key = nil

            before_all(function()
                actual_api_key = env.get("OPENAI_API_KEY")
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

                expect(response.success).to_be_true("API status check failed")
                expect(response.status).to_equal("healthy")
                expect(response.message).to_equal("OpenAI API is responding normally")
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

                expect(response.success).to_be_false("Expected auth failure")
                expect(response.status).to_equal("unhealthy")
                expect(response.message).to_contain("Incorrect API")
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

                expect(response.success).to_be_true("Custom base URL failed")
                expect(response.status).to_equal("healthy")
            end)

            it("should handle organization context", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping organization test")
                    return
                end

                local test_org = env.get("OPENAI_ORGANIZATION")
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

                    expect(response.success).to_be_true("Organization context failed")
                    expect(response.status).to_equal("healthy")
                else
                    print("Skipping org test - no OPENAI_ORGANIZATION env var")
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

                expect(response.success).to_be_false("Expected timeout")
                expect(response.status).to_equal("unhealthy")
                expect(response.message).to_contain("Connection failed")
            end)

            it("should resolve API key from environment", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping env resolution test")
                    return
                end

                status_handler._client._ctx = {
                    all = function()
                        return { api_key_env = "OPENAI_API_KEY" }
                    end
                }

                status_handler._client._env = {
                    get = function(key)
                        if key == "OPENAI_API_KEY" then
                            return actual_api_key
                        end
                        return nil
                    end
                }

                local response = status_handler.handler()

                expect(response.success).to_be_true("Env API key resolution failed")
                expect(response.status).to_equal("healthy")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)