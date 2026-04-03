local generate_handler = require("generate_handler")
local status_handler = require("status_handler")
local structured_output_handler = require("structured_output_handler")
local embed_handler = require("embed_handler")
local output = require("output")
local json = require("json")
local env = require("env")

local function define_tests()
    local RUN_INTEGRATION_TESTS = env.get("ENABLE_INTEGRATION_TESTS")
    local CLAUDE_MODEL = "us.anthropic.claude-haiku-4-5-20251001-v1:0"
    local TITAN_EMBED_MODEL = "amazon.titan-embed-text-v2:0"
    local COHERE_EMBED_MODEL = "cohere.embed-english-v3"

    describe("Bedrock Integration Tests", function()

        before_all(function()
            if RUN_INTEGRATION_TESTS then
                print("Bedrock integration tests enabled")
                print("  Claude model: " .. CLAUDE_MODEL)
                print("  Titan embed: " .. TITAN_EMBED_MODEL)
                print("  Cohere embed: " .. COHERE_EMBED_MODEL)
            else
                print("Bedrock integration tests disabled - set ENABLE_INTEGRATION_TESTS=true to enable")
            end
        end)

        describe("Status Check", function()
            it("should report healthy status via Converse", function()
                if not RUN_INTEGRATION_TESTS then return end

                local response = status_handler.handler({ model = CLAUDE_MODEL })

                test.is_true(response.success, "Status check failed: " .. (response.message or "unknown"))
                test.eq(response.status, "healthy")
            end)
        end)

        describe("Text Generation (Converse API)", function()
            it("should generate text successfully", function()
                if not RUN_INTEGRATION_TESTS then return end

                local response = generate_handler.handler({
                    model = CLAUDE_MODEL,
                    messages = {
                        { role = "user", content = { { type = "text", text = "Say hi" } } }
                    },
                    options = { temperature = 0, max_tokens = 32 }
                })

                test.is_true(response.success, "Generation failed: " .. (response.error_message or "unknown"))
                assert(response.success)
                test.not_nil(response.result.content)
                test.is_true(#response.result.content > 0)
                test.is_true(response.tokens.prompt_tokens > 0)
                test.is_true(response.tokens.completion_tokens > 0)
            end)

            it("should respect system messages", function()
                if not RUN_INTEGRATION_TESTS then return end

                local response = generate_handler.handler({
                    model = CLAUDE_MODEL,
                    messages = {
                        { role = "system", content = "Always reply with exactly one word: yes" },
                        { role = "user", content = { { type = "text", text = "ok?" } } }
                    },
                    options = { temperature = 0, max_tokens = 5 }
                })

                test.is_true(response.success, "Generation failed: " .. (response.error_message or "unknown"))
                assert(response.success)
                test.not_nil(response.result.content)
            end)
        end)

        describe("Tool Calling (Converse API)", function()
            it("should make tool calls", function()
                if not RUN_INTEGRATION_TESTS then return end

                local response = generate_handler.handler({
                    model = CLAUDE_MODEL,
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
                                properties = { location = { type = "string", description = "City name" } },
                                required = { "location" }
                            }
                        }
                    },
                    options = { temperature = 0, max_tokens = 200 }
                })

                test.is_true(response.success, "Tool call failed: " .. (response.error_message or "unknown"))
                assert(response.success)
                test.not_nil(response.result.tool_calls)
                test.is_true(#response.result.tool_calls > 0)
                test.eq(response.result.tool_calls[1].name, "get_weather")
                test.eq(response.finish_reason, "tool_call")
            end)
        end)

        describe("Structured Output (Converse API)", function()
            it("should extract structured data", function()
                if not RUN_INTEGRATION_TESTS then return end

                local response = structured_output_handler.handler({
                    model = CLAUDE_MODEL,
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
                    options = { temperature = 0, max_tokens = 200 }
                })

                test.is_true(response.success, "Structured output failed: " .. (response.error_message or "unknown"))
                assert(response.success)
                test.not_nil(response.result.data)
                test.eq(response.result.data.name, "John Doe")
                test.eq(response.result.data.age, 30)
                test.eq(response.result.data.city, "NYC")
            end)
        end)

        describe("Streaming (Converse API)", function()
            it("should stream text generation", function()
                if not RUN_INTEGRATION_TESTS then return end

                local streaming_events = {}
                local mock_streamer = {
                    buffer_content = function(self, chunk)
                        table.insert(streaming_events, { type = "content", data = chunk })
                    end,
                    send_thinking = function(self, chunk) end,
                    send_tool_call = function(self, name, args, id) end,
                    send_error = function(self, err, message) end,
                    flush = function(self) end
                }

                generate_handler._output = {
                    streamer = function(reply_to, topic, buffer_size)
                        return mock_streamer
                    end,
                    ERROR_TYPE = output.ERROR_TYPE
                }

                local response = generate_handler.handler({
                    model = CLAUDE_MODEL,
                    messages = {
                        { role = "user", content = { { type = "text", text = "Count from 1 to 5" } } }
                    },
                    options = { temperature = 0, max_tokens = 50 },
                    stream = {
                        reply_to = "test-pid",
                        topic = "test_stream"
                    }
                })

                test.is_true(response.success, "Streaming failed: " .. json.encode(response))
                test.not_nil(response.result, "Result is nil: " .. json.encode(response))
                test.not_nil(response.result.content, "Content is nil")
                test.is_true(#response.result.content > 0, "Content is empty")
                test.is_true(response.tokens.prompt_tokens > 0)
                test.eq(response.finish_reason, "stop")
            end)
        end)

        describe("Titan Embeddings (InvokeModel)", function()
            it("should generate single embedding", function()
                if not RUN_INTEGRATION_TESTS then return end

                local response = embed_handler.handler({
                    model = TITAN_EMBED_MODEL,
                    input = "Hello world"
                })

                test.is_true(response.success, "Titan embed failed: " .. (response.error_message or "unknown"))
                assert(response.success)
                test.not_nil(response.result.embeddings)
                test.eq(#response.result.embeddings, 1)
                test.is_true(#response.result.embeddings[1] > 0)
                test.is_true(response.tokens.prompt_tokens > 0)
            end)

            it("should generate multiple embeddings", function()
                if not RUN_INTEGRATION_TESTS then return end

                local response = embed_handler.handler({
                    model = TITAN_EMBED_MODEL,
                    input = { "First text", "Second text" }
                })

                test.is_true(response.success, "Titan batch embed failed: " .. (response.error_message or "unknown"))
                assert(response.success)
                test.eq(#response.result.embeddings, 2)
                test.is_true(#response.result.embeddings[1] > 0)
                test.is_true(#response.result.embeddings[2] > 0)
            end)

            it("should respect dimensions option", function()
                if not RUN_INTEGRATION_TESTS then return end

                local response = embed_handler.handler({
                    model = TITAN_EMBED_MODEL,
                    input = "Test dimensions",
                    options = { dimensions = 256 }
                })

                test.is_true(response.success, "Titan dimensions failed: " .. (response.error_message or "unknown"))
                assert(response.success)
                test.eq(#response.result.embeddings[1], 256)
            end)
        end)

        describe("Cohere Embeddings (InvokeModel)", function()
            it("should generate single embedding", function()
                if not RUN_INTEGRATION_TESTS then return end

                local response = embed_handler.handler({
                    model = COHERE_EMBED_MODEL,
                    input = "Hello world"
                })

                test.is_true(response.success, "Cohere embed failed: " .. (response.error_message or "unknown"))
                assert(response.success)
                test.not_nil(response.result.embeddings)
                test.eq(#response.result.embeddings, 1)
                test.is_true(#response.result.embeddings[1] > 0)
            end)

            it("should generate batch embeddings", function()
                if not RUN_INTEGRATION_TESTS then return end

                local response = embed_handler.handler({
                    model = COHERE_EMBED_MODEL,
                    input = { "First", "Second", "Third" }
                })

                test.is_true(response.success, "Cohere batch embed failed: " .. (response.error_message or "unknown"))
                assert(response.success)
                test.eq(#response.result.embeddings, 3)
            end)
        end)

        describe("Error Handling", function()
            it("should return error for invalid model", function()
                if not RUN_INTEGRATION_TESTS then return end

                local response = generate_handler.handler({
                    model = "nonexistent.model-v1:0",
                    messages = {
                        { role = "user", content = { { type = "text", text = "test" } } }
                    },
                    options = { max_tokens = 10 }
                })

                test.is_false(response.success)
                test.not_nil(response.error)
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
