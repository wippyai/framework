local llm = require("llm")
local env = require("env")

local function define_tests()
    local RUN_INTEGRATION_TESTS = env.get("ENABLE_INTEGRATION_TESTS")

    describe("LLM Integration Tests", function()
        before_all(function()
            if not RUN_INTEGRATION_TESTS then
                print("Integration tests disabled - set ENABLE_INTEGRATION_TESTS=true to enable")
            end
        end)

        it("should call provider directly with provider_id and model", function()
            if not RUN_INTEGRATION_TESTS then
                print("Skipping direct provider test - not enabled")
                return
            end
            local messages = {
                {
                    role = "user",
                    content = {
                        { type = "text", text = "Say 'Hello from OpenAI integration test'" }
                    }
                }
            }

            local options = {
                provider_id = "wippy.llm.openai:provider",
                model = "gpt-4.1",
                temperature = 0.3,
                max_tokens = 100
            }

            local result, err = llm.generate(messages, options)

            test.is_nil(err)
            test.not_nil(result)
            test.not_nil(result.result)
            test.eq(type(result.result), "string")
            test.not_nil(result.tokens)
        end)

        it("should handle streaming with provider_id", function()
            if not RUN_INTEGRATION_TESTS then
                print("Skipping streaming provider test - not enabled")
                return
            end

            local messages = {
                {
                    role = "user",
                    content = {
                        { type = "text", text = "Count to 5" }
                    }
                }
            }

            local options = {
                provider_id = "wippy.llm.openai:provider",
                model = "gpt-4o-mini",
                temperature = 0,
                max_tokens = 50,
                stream = {
                    reply_to = "test_process",
                    topic = "test_topic"
                }
            }

            local result, err = llm.generate(messages, options)

            test.is_nil(err)
            test.not_nil(result)
            test.not_nil(result.result)
        end)

        it("should handle tool calling with provider_id", function()
            if not RUN_INTEGRATION_TESTS then
                print("Skipping tool calling provider test - not enabled")
                return
            end

            local messages = {
                {
                    role = "user",
                    content = {
                        { type = "text", text = "What is 15 * 23? Use the calculator tool." }
                    }
                }
            }

            local tools = {
                {
                    name = "calculator",
                    description = "Perform basic mathematical calculations",
                    schema = {
                        type = "object",
                        properties = {
                            expression = {
                                type = "string",
                                description = "Mathematical expression to calculate"
                            }
                        },
                        required = {"expression"}
                    }
                }
            }

            local options = {
                provider_id = "wippy.llm.openai:provider",
                model = "gpt-4.1",
                tools = tools,
                tool_choice = "auto",
                temperature = 0
            }

            local result, err = llm.generate(messages, options)

            test.is_nil(err)
            test.not_nil(result)
            test.not_nil(result.tool_calls)
            test.gt(#result.tool_calls, 0)
            test.eq(result.tool_calls[1].name, "calculator")
        end)

        it("should generate text via Bedrock provider using Converse API", function()
            if not RUN_INTEGRATION_TESTS then return end

            local messages = {
                { role = "user", content = { { type = "text", text = "Say 'Hello from Bedrock'" } } }
            }

            local options = {
                provider_id = "wippy.llm.bedrock:provider",
                model = "us.anthropic.claude-haiku-4-5-20251001-v1:0",
                temperature = 0,
                max_tokens = 50
            }

            local result, err = llm.generate(messages, options)

            test.is_nil(err)
            test.not_nil(result)
            test.eq(type(result.result), "string")
            test.is_true(#result.result > 0)
            test.not_nil(result.tokens)
            test.is_true(result.tokens.prompt_tokens > 0)
        end)

        it("should handle Bedrock tool calling via Converse API", function()
            if not RUN_INTEGRATION_TESTS then return end

            local messages = {
                { role = "user", content = { { type = "text", text = "What is 15 * 23? Use the calculator tool." } } }
            }

            local tools = {
                {
                    name = "calculator",
                    description = "Perform basic mathematical calculations",
                    schema = {
                        type = "object",
                        properties = {
                            expression = { type = "string", description = "Mathematical expression" }
                        },
                        required = { "expression" }
                    }
                }
            }

            local options = {
                provider_id = "wippy.llm.bedrock:provider",
                model = "us.anthropic.claude-haiku-4-5-20251001-v1:0",
                tools = tools,
                tool_choice = "auto",
                temperature = 0,
                max_tokens = 200
            }

            local result, err = llm.generate(messages, options)

            test.is_nil(err)
            test.not_nil(result)
            test.not_nil(result.tool_calls)
            test.gt(#result.tool_calls, 0)
            test.eq(result.tool_calls[1].name, "calculator")
        end)

        it("should handle Bedrock structured output via Converse API", function()
            if not RUN_INTEGRATION_TESTS then return end

            local messages = {
                { role = "user", content = { { type = "text", text = "Extract: Alice is 28 and lives in Paris" } } }
            }

            local schema = {
                type = "object",
                properties = {
                    name = { type = "string" },
                    age = { type = "number" },
                    city = { type = "string" }
                },
                required = { "name", "age", "city" },
                additionalProperties = false
            }

            local options = {
                provider_id = "wippy.llm.bedrock:provider",
                model = "us.anthropic.claude-haiku-4-5-20251001-v1:0",
                temperature = 0,
                max_tokens = 200
            }

            local result, err = llm.structured_output(schema, messages, options)

            test.is_nil(err)
            test.not_nil(result)
            test.not_nil(result.result)
            test.eq((result.result :: any).name, "Alice")
            test.eq((result.result :: any).age, 28)
            test.eq((result.result :: any).city, "Paris")
        end)

        it("should handle Bedrock Titan embedding via InvokeModel", function()
            if not RUN_INTEGRATION_TESTS then return end

            local options = {
                provider_id = "wippy.llm.bedrock:provider",
                model = "amazon.titan-embed-text-v2:0"
            }

            local result, err = llm.embed("Hello from Titan embeddings", options)

            test.is_nil(err)
            test.not_nil(result)
            test.not_nil(result.result)
            test.eq(type(result.result), "table")
            test.eq(#result.result, 1)
            test.is_true(#result.result[1] > 0)
            test.not_nil(result.tokens)
        end)

        it("should handle Bedrock Cohere embedding via InvokeModel", function()
            if not RUN_INTEGRATION_TESTS then return end

            local options = {
                provider_id = "wippy.llm.bedrock:provider",
                model = "cohere.embed-english-v3"
            }

            local result, err = llm.embed({ "First text", "Second text" }, options)

            test.is_nil(err)
            test.not_nil(result)
            test.not_nil(result.result)
            test.eq(type(result.result), "table")
            test.eq(#result.result, 2)
            test.is_true(#result.result[1] > 0)
            test.is_true(#result.result[2] > 0)
        end)

        it("should handle Bedrock streaming via ConverseStream", function()
            if not RUN_INTEGRATION_TESTS then return end

            local messages = {
                { role = "user", content = { { type = "text", text = "Count 1 2 3" } } }
            }

            local options = {
                provider_id = "wippy.llm.bedrock:provider",
                model = "us.anthropic.claude-haiku-4-5-20251001-v1:0",
                temperature = 0,
                max_tokens = 30,
                stream = {
                    reply_to = "e2e_bedrock_stream",
                    topic = "bedrock_stream_test"
                }
            }

            local result, err = llm.generate(messages, options)

            test.is_nil(err)
            test.not_nil(result)
            test.not_nil(result.result)
            test.is_true(#result.result > 0)
        end)
    end)
end

return require("test").run_cases(define_tests)