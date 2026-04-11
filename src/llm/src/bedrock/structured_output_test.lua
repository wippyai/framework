local structured_output_handler = require("structured_output_handler")
local json = require("json")

local function define_tests()
    describe("Bedrock Structured Output Handler (Converse API)", function()

        after_each(function()
            structured_output_handler._client = nil
        end)

        describe("Contract Validation", function()
            it("should require model parameter", function()
                local response = structured_output_handler.handler({
                    messages = { { role = "user", content = { { type = "text", text = "Test" } } } },
                    schema = { type = "object", properties = {}, required = {}, additionalProperties = false }
                })
                test.is_false(response.success)
                test.eq(response.error, "invalid_request")
                test.contains(response.error_message, "Model is required")
            end)

            it("should require messages parameter", function()
                local response = structured_output_handler.handler({
                    model = "test-model",
                    schema = { type = "object", properties = {}, required = {}, additionalProperties = false }
                })
                test.is_false(response.success)
                test.contains(response.error_message, "Messages are required")
            end)

            it("should require schema parameter", function()
                local response = structured_output_handler.handler({
                    model = "test-model",
                    messages = { { role = "user", content = { { type = "text", text = "Test" } } } }
                })
                test.is_false(response.success)
                test.contains(response.error_message, "Schema is required")
            end)

            it("should validate schema structure", function()
                local response = structured_output_handler.handler({
                    model = "test-model",
                    messages = { { role = "user", content = { { type = "text", text = "Test" } } } },
                    schema = { type = "string" }
                })
                test.is_false(response.success)
                test.contains(response.error_message, "type 'object'")
            end)
        end)

        describe("Structured Output", function()
            it("should extract structured data from tool_use response", function()
                structured_output_handler._client = {
                    converse = function(model_id, payload, options)
                        return {
                            output = {
                                message = {
                                    role = "assistant",
                                    content = {
                                        {
                                            toolUse = {
                                                toolUseId = "call_1",
                                                name = "structured_output",
                                                input = { name = "John", age = 30, city = "NYC" }
                                            }
                                        }
                                    }
                                }
                            },
                            stopReason = "tool_use",
                            usage = { inputTokens = 40, outputTokens = 20 },
                            metadata = {}
                        }
                    end
                }

                local response = structured_output_handler.handler({
                    model = "test-model",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Extract: John Doe is 30 from NYC" } } }
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
                    }
                })

                test.is_true(response.success)
                test.not_nil((response :: any).result.data)
                test.eq((response :: any).result.data.name, "John")
                test.eq((response :: any).result.data.age, 30)
                test.eq((response :: any).result.data.city, "NYC")
            end)

            it("should send forced tool_choice in payload", function()
                local captured_payload = nil
                structured_output_handler._client = {
                    converse = function(model_id, payload, options)
                        captured_payload = payload
                        return {
                            output = {
                                message = {
                                    role = "assistant",
                                    content = {
                                        { toolUse = { toolUseId = "c1", name = "structured_output", input = { x = 1 } } }
                                    }
                                }
                            },
                            stopReason = "tool_use",
                            usage = { inputTokens = 10, outputTokens = 5 },
                            metadata = {}
                        }
                    end
                }

                structured_output_handler.handler({
                    model = "test-model",
                    messages = { { role = "user", content = { { type = "text", text = "Test" } } } },
                    schema = {
                        type = "object",
                        properties = { x = { type = "number" } },
                        required = { "x" },
                        additionalProperties = false
                    }
                })

                test.not_nil((captured_payload :: any).toolConfig)
                test.not_nil((captured_payload :: any).toolConfig.toolChoice)
                test.eq((captured_payload :: any).toolConfig.toolChoice.tool.name, "structured_output")
            end)

            it("should handle missing tool_use in response", function()
                structured_output_handler._client = {
                    converse = function(model_id, payload, options)
                        return {
                            output = {
                                message = {
                                    role = "assistant",
                                    content = { { text = "I cannot do that" } }
                                }
                            },
                            stopReason = "end_turn",
                            usage = { inputTokens = 10, outputTokens = 5 },
                            metadata = {}
                        }
                    end
                }

                local response = structured_output_handler.handler({
                    model = "test-model",
                    messages = { { role = "user", content = { { type = "text", text = "Extract" } } } },
                    schema = {
                        type = "object",
                        properties = { x = { type = "number" } },
                        required = { "x" },
                        additionalProperties = false
                    }
                })

                test.is_false(response.success)
                test.contains(response.error_message, "structured_output tool")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
