local llm = require("llm")

local function define_tests()
    describe("LLM Integration Tests", function()
        it("should call provider directly with provider_id and model", function()
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

            expect(err).to_be_nil()
            expect(result).not_to_be_nil()
            expect(result.result).not_to_be_nil()
            expect(type(result.result)).to_equal("string")
            expect(result.tokens).not_to_be_nil()
        end)

        it("should handle streaming with provider_id", function()
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

            expect(err).to_be_nil()
            expect(result).not_to_be_nil()
            expect(result.result).not_to_be_nil()
        end)

        it("should handle tool calling with provider_id", function()
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

            expect(err).to_be_nil()
            expect(result).not_to_be_nil()
            expect(result.tool_calls).not_to_be_nil()
            expect(#result.tool_calls).to_be_greater_than(0)
            expect(result.tool_calls[1].name).to_equal("calculator")
        end)
    end)
end

return require("test").run_cases(define_tests)