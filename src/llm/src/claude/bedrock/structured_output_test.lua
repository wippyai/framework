local structured_output_handler = require("structured_output_handler")
local json = require("json")

local function define_tests()
    describe("Bedrock Structured Output Handler", function()

        after_each(function()
            structured_output_handler._client = nil
        end)

        describe("Contract Validation", function()
            it("should require model parameter", function()
                local response = structured_output_handler.handler({
                    messages = {
                        { role = "user", content = { { type = "text", text = "Extract data" } } }
                    },
                    schema = {
                        type = "object",
                        properties = { name = { type = "string" } },
                        required = { "name" },
                        additionalProperties = false
                    }
                })

                test.is_false(response.success)
                test.eq(response.error, "invalid_request")
                test.contains(response.error_message, "Model is required")
            end)

            it("should require messages parameter", function()
                local response = structured_output_handler.handler({
                    model = "us.anthropic.claude-haiku-4-5-20251001-v1:0",
                    schema = {
                        type = "object",
                        properties = { name = { type = "string" } },
                        required = { "name" },
                        additionalProperties = false
                    }
                })

                test.is_false(response.success)
                test.eq(response.error, "invalid_request")
                test.contains(response.error_message, "Messages are required")
            end)

            it("should require schema parameter", function()
                local response = structured_output_handler.handler({
                    model = "us.anthropic.claude-haiku-4-5-20251001-v1:0",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Extract data" } } }
                    }
                })

                test.is_false(response.success)
                test.eq(response.error, "invalid_request")
                test.contains(response.error_message, "Schema is required")
            end)

            it("should reject invalid schema without object type", function()
                local response = structured_output_handler.handler({
                    model = "us.anthropic.claude-haiku-4-5-20251001-v1:0",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Extract data" } } }
                    },
                    schema = {
                        type = "array",
                        items = { type = "string" }
                    }
                })

                test.is_false(response.success)
                test.eq(response.error, "invalid_request")
                test.contains(response.error_message, "Invalid schema")
            end)

            it("should reject schema without additionalProperties false", function()
                local response = structured_output_handler.handler({
                    model = "us.anthropic.claude-haiku-4-5-20251001-v1:0",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Extract data" } } }
                    },
                    schema = {
                        type = "object",
                        properties = { name = { type = "string" } },
                        required = { "name" }
                    }
                })

                test.is_false(response.success)
                test.eq(response.error, "invalid_request")
                test.contains(response.error_message, "Invalid schema")
            end)
        end)

        describe("Successful Extraction", function()
            it("should extract data from tool_use response with structured_output name", function()
                structured_output_handler._client = {
                    request = function(model_id, payload, options)
                        test.eq(payload.tool_choice.type, "tool")
                        test.eq(payload.tool_choice.name, "structured_output")

                        return {
                            content = {
                                {
                                    type = "tool_use",
                                    id = "toolu_extract",
                                    name = "structured_output",
                                    input = {
                                        name = "John Doe",
                                        age = 30
                                    }
                                }
                            },
                            stop_reason = "tool_use",
                            usage = { input_tokens = 50, output_tokens = 25 },
                            metadata = { request_id = "req_so_123" }
                        }
                    end
                }

                local response = structured_output_handler.handler({
                    model = "us.anthropic.claude-haiku-4-5-20251001-v1:0",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Extract name and age from: John Doe, 30 years old" } } }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            name = { type = "string" },
                            age = { type = "number" }
                        },
                        required = { "name", "age" },
                        additionalProperties = false
                    }
                })

                test.is_true(response.success)
                assert(response.success)
                test.not_nil(response.result)
                test.not_nil(response.result.data)
                test.eq(response.result.data.name, "John Doe")
                test.eq(response.result.data.age, 30)
                test.eq(response.finish_reason, "stop")
                test.not_nil(response.tokens)
            end)
        end)

        describe("Error Handling", function()
            it("should handle API errors", function()
                structured_output_handler._client = {
                    request = function(model_id, payload, options)
                        return nil, {
                            status_code = 500,
                            message = "Internal server error"
                        }
                    end
                }

                local response = structured_output_handler.handler({
                    model = "us.anthropic.claude-haiku-4-5-20251001-v1:0",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Extract data" } } }
                    },
                    schema = {
                        type = "object",
                        properties = { name = { type = "string" } },
                        required = { "name" },
                        additionalProperties = false
                    }
                })

                test.is_false(response.success)
                test.not_nil(response.error)
            end)

            it("should handle missing tool_use in response", function()
                structured_output_handler._client = {
                    request = function(model_id, payload, options)
                        return {
                            content = {
                                { type = "text", text = "I cannot extract the data." }
                            },
                            stop_reason = "end_turn",
                            usage = { input_tokens = 30, output_tokens = 10 },
                            metadata = {}
                        }
                    end
                }

                local response = structured_output_handler.handler({
                    model = "us.anthropic.claude-haiku-4-5-20251001-v1:0",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Extract data" } } }
                    },
                    schema = {
                        type = "object",
                        properties = { name = { type = "string" } },
                        required = { "name" },
                        additionalProperties = false
                    }
                })

                test.is_false(response.success)
                test.eq(response.error, "server_error")
                test.contains(response.error_message, "structured_output")
            end)

            it("should handle nil response content", function()
                structured_output_handler._client = {
                    request = function(model_id, payload, options)
                        return {
                            stop_reason = "end_turn",
                            usage = { input_tokens = 10, output_tokens = 0 },
                            metadata = {}
                        }
                    end
                }

                local response = structured_output_handler.handler({
                    model = "us.anthropic.claude-haiku-4-5-20251001-v1:0",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Extract data" } } }
                    },
                    schema = {
                        type = "object",
                        properties = { name = { type = "string" } },
                        required = { "name" },
                        additionalProperties = false
                    }
                })

                test.is_false(response.success)
                test.eq(response.error, "server_error")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
