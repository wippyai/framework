local generate_handler = require("generate_handler")
local status_handler = require("status_handler")
local structured_output_handler = require("structured_output_handler")
local json = require("json")
local env = require("env")

local function define_tests()
    local RUN_INTEGRATION_TESTS = env.get("ENABLE_INTEGRATION_TESTS")
    local TEST_MODEL = "us.anthropic.claude-haiku-4-5-20251001-v1:0"

    describe("Bedrock Integration Tests", function()

        before_all(function()
            if RUN_INTEGRATION_TESTS then
                print("Bedrock integration tests enabled, using model: " .. TEST_MODEL)
            else
                print("Bedrock integration tests disabled - set ENABLE_INTEGRATION_TESTS=true to enable")
            end
        end)

        describe("Status Check", function()
            it("should report healthy status", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping integration test - not enabled")
                    return
                end

                local response = status_handler.handler({ model = TEST_MODEL })

                test.is_true(response.success, "Status check failed: " .. (response.message or "unknown"))
                test.eq(response.status, "healthy")
            end)
        end)

        describe("Text Generation", function()
            it("should generate text successfully", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping integration test - not enabled")
                    return
                end

                local response = generate_handler.handler({
                    model = TEST_MODEL,
                    messages = {
                        {
                            role = "user",
                            content = { { type = "text", text = "Say hi" } }
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 32
                    }
                })

                test.is_true(response.success, "Generation failed: " .. (response.error_message or "unknown"))
                assert(response.success)
                test.not_nil(response.result.content)
                test.is_true(response.tokens.prompt_tokens > 0)
                test.is_true(response.tokens.completion_tokens > 0)
            end)
        end)

        describe("System Messages", function()
            it("should respect system messages", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping integration test - not enabled")
                    return
                end

                local response = generate_handler.handler({
                    model = TEST_MODEL,
                    messages = {
                        { role = "system", content = "Always reply with exactly one word: yes" },
                        {
                            role = "user",
                            content = { { type = "text", text = "ok?" } }
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 5
                    }
                })

                test.is_true(response.success, "Generation failed: " .. (response.error_message or "unknown"))
                assert(response.success)
                test.not_nil(response.result.content)
            end)
        end)

        describe("Tool Calling", function()
            it("should make tool calls when tools are provided", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping integration test - not enabled")
                    return
                end

                local response = generate_handler.handler({
                    model = TEST_MODEL,
                    messages = {
                        {
                            role = "user",
                            content = { { type = "text", text = "What is the weather in San Francisco? Use the get_weather tool." } }
                        }
                    },
                    tools = {
                        {
                            name = "get_weather",
                            description = "Get the current weather for a location",
                            schema = {
                                type = "object",
                                properties = {
                                    location = {
                                        type = "string",
                                        description = "City name"
                                    }
                                },
                                required = { "location" }
                            }
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 200
                    }
                })

                test.is_true(response.success, "Tool call failed: " .. (response.error_message or "unknown"))
                assert(response.success)
                test.not_nil(response.result.tool_calls)
                test.is_true(#response.result.tool_calls > 0)
                test.eq(response.result.tool_calls[1].name, "get_weather")
                test.eq(response.finish_reason, "tool_call")
            end)
        end)

        describe("Structured Output", function()
            it("should extract structured data", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping integration test - not enabled")
                    return
                end

                local response = structured_output_handler.handler({
                    model = TEST_MODEL,
                    messages = {
                        {
                            role = "user",
                            content = { { type = "text", text = "Extract: John Doe is 30 years old and lives in NYC" } }
                        }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            name = { type = "string" },
                            age = { type = "number" },
                            city = { type = "string" }
                        },
                        required = { "name", "age", "city" },
                        additionalProperties = false
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 200
                    }
                })

                test.is_true(response.success, "Structured output failed: " .. (response.error_message or "unknown"))
                assert(response.success)
                test.not_nil(response.result)
                test.not_nil(response.result.data)
                test.eq(response.result.data.name, "John Doe")
                test.eq(response.result.data.age, 30)
                test.eq(response.result.data.city, "NYC")
            end)
        end)

        describe("Token Usage Tracking", function()
            it("should return cache token counts", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping integration test - not enabled")
                    return
                end

                local response = generate_handler.handler({
                    model = TEST_MODEL,
                    messages = {
                        {
                            role = "user",
                            content = { { type = "text", text = "Say ok" } }
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 10
                    }
                })

                test.is_true(response.success, "Generation failed: " .. (response.error_message or "unknown"))
                assert(response.success)
                test.not_nil(response.tokens)
                test.not_nil(response.tokens.prompt_tokens)
                test.not_nil(response.tokens.completion_tokens)
                test.not_nil(response.tokens.total_tokens)
                test.is_true(response.tokens.total_tokens > 0)
            end)
        end)

        describe("Streaming", function()
            it("should stream text generation", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping integration test - not enabled")
                    return
                end

                local streaming_events = {}
                local mock_streamer = {
                    buffer_content = function(self, chunk)
                        table.insert(streaming_events, {type = "content", data = chunk})
                    end,
                    send_thinking = function(self, chunk) end,
                    send_tool_call = function(self, name, args, id) end,
                    send_error = function(self, error, message) end,
                    flush = function(self) end
                }

                generate_handler._output = {
                    streamer = function(reply_to, topic, buffer_size)
                        return mock_streamer
                    end,
                    ERROR_TYPE = require("output").ERROR_TYPE
                }

                local response = generate_handler.handler({
                    model = TEST_MODEL,
                    messages = {
                        {
                            role = "user",
                            content = { { type = "text", text = "Count from 1 to 5, one number per line" } }
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 50
                    },
                    stream = {
                        reply_to = "bedrock-stream-test-pid",
                        topic = "bedrock_stream_test"
                    }
                })

                test.is_true(response.success, "Streaming failed: " .. (response.error_message or "unknown"))
                assert(response.success)
                test.not_nil(response.result.content)

                local content_events = 0
                for _, event in ipairs(streaming_events) do
                    if event.type == "content" then
                        content_events = content_events + 1
                    end
                end
                test.is_true(content_events > 0, "No content streaming events occurred")
                test.is_true(response.tokens.prompt_tokens > 0)
                test.is_true(response.tokens.completion_tokens > 0)
                test.eq(response.finish_reason, "stop")
            end)

            it("should stream tool calls", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping integration test - not enabled")
                    return
                end

                local streaming_events = {}
                local mock_streamer = {
                    buffer_content = function(self, chunk)
                        table.insert(streaming_events, {type = "content", data = chunk})
                    end,
                    send_thinking = function(self, chunk) end,
                    send_tool_call = function(self, name, args, id)
                        table.insert(streaming_events, {type = "tool_call", name = name, args = args, id = id})
                    end,
                    send_error = function(self, error, message) end,
                    flush = function(self) end
                }

                generate_handler._output = {
                    streamer = function(reply_to, topic, buffer_size)
                        return mock_streamer
                    end,
                    ERROR_TYPE = require("output").ERROR_TYPE
                }

                local response = generate_handler.handler({
                    model = TEST_MODEL,
                    messages = {
                        {
                            role = "user",
                            content = { { type = "text", text = "What is 2+2? Use the calculate tool." } }
                        }
                    },
                    tools = {
                        {
                            name = "calculate",
                            description = "Evaluate a math expression",
                            schema = {
                                type = "object",
                                properties = {
                                    expression = { type = "string", description = "Math expression" }
                                },
                                required = { "expression" }
                            }
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 200
                    },
                    stream = {
                        reply_to = "bedrock-tool-stream-test-pid",
                        topic = "bedrock_tool_stream_test"
                    }
                })

                test.is_true(response.success, "Streaming tool call failed: " .. (response.error_message or "unknown"))
                assert(response.success)
                test.not_nil(response.result.tool_calls)
                test.is_true(#response.result.tool_calls > 0)
                test.eq(response.result.tool_calls[1].name, "calculate")

                local tool_call_events = 0
                for _, event in ipairs(streaming_events) do
                    if event.type == "tool_call" then
                        tool_call_events = tool_call_events + 1
                    end
                end
                test.is_true(tool_call_events > 0, "No tool call streaming events occurred")
                test.eq(response.finish_reason, "tool_call")
            end)
        end)

        describe("Error Handling", function()
            it("should return error for invalid model", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping integration test - not enabled")
                    return
                end

                local response = generate_handler.handler({
                    model = "nonexistent.model-that-does-not-exist-v1:0",
                    messages = {
                        {
                            role = "user",
                            content = { { type = "text", text = "test" } }
                        }
                    },
                    options = { max_tokens = 10 }
                })

                test.is_false(response.success)
                test.not_nil(response.error)
                test.not_nil(response.error_message)
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
