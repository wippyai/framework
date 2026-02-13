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
    end)
end

return require("test").run_cases(define_tests)