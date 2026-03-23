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
