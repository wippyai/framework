local structured_output_handler = require("structured_output_handler")
local json = require("json")
local env = require("env")
local ctx = require("ctx")
local hash = require("hash")

local function define_tests()
    describe("Claude Structured Output Handler", function()

        after_each(function()
            -- Clean up injected dependencies
            structured_output_handler._client._ctx = nil
            structured_output_handler._client._env = nil
            structured_output_handler._client._http_client = nil
        end)

        describe("Contract Argument Validation", function()
            it("should require model parameter", function()
                local contract_args = {
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { name = { type = "string" } },
                        required = { "name" },
                        additionalProperties = false
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_contain("Model is required")
            end)

            it("should require messages parameter", function()
                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    schema = {
                        type = "object",
                        properties = { name = { type = "string" } },
                        required = { "name" },
                        additionalProperties = false
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_contain("Messages are required")
            end)

            it("should require schema parameter", function()
                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_contain("Schema is required")
            end)

            it("should reject empty messages array", function()
                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {},
                    schema = {
                        type = "object",
                        properties = { test = { type = "boolean" } },
                        required = { "test" },
                        additionalProperties = false
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_contain("Messages are required")
            end)
        end)

        describe("Schema Validation", function()
            it("should validate schema structure requirements", function()
                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "array", -- Should be object
                        items = { type = "string" }
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_contain("Root schema must be type 'object'")
            end)

            it("should require additionalProperties: false", function()
                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            name = { type = "string" }
                        },
                        required = { "name" }
                        -- Missing additionalProperties: false
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_contain("additionalProperties: false")
            end)

            it("should require all properties in required array", function()
                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            name = { type = "string" },
                            age = { type = "number" }
                        },
                        required = { "name" }, -- Missing "age"
                        additionalProperties = false
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_contain("All properties must be marked as required")
            end)

            it("should require required array when properties exist", function()
                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            name = { type = "string" }
                        },
                        additionalProperties = false
                        -- Missing required array
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_contain("Schema must have 'required' array")
            end)

            it("should handle non-table schema", function()
                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = "not a table"
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_contain("Schema must be a table")
            end)

            it("should accept valid schema", function()
                structured_output_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                structured_output_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                structured_output_handler._client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = json.encode({
                                content = {
                                    {
                                        type = "tool_use",
                                        name = "structured_output",
                                        id = "tool_123",
                                        input = { name = "Alice", age = 30 }
                                    }
                                },
                                stop_reason = "tool_use",
                                usage = { input_tokens = 15, output_tokens = 10 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
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
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_true()
            end)
        end)

        describe("Successful Structured Output", function()
            it("should handle successful structured response", function()
                structured_output_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                structured_output_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                structured_output_handler._client._http_client = {
                    post = function(url, options)
                        expect(url).to_contain("/v1/messages")

                        local payload = json.decode(options.body)
                        expect(payload.model).to_equal("claude-3-5-sonnet-20241022")
                        expect(payload.tools).not_to_be_nil()
                        expect(#payload.tools).to_equal(1)
                        expect(payload.tools[1].name).to_equal("structured_output")
                        expect(payload.tool_choice).not_to_be_nil()
                        expect(payload.tool_choice.type).to_equal("tool")
                        expect(payload.tool_choice.name).to_equal("structured_output")

                        return {
                            status_code = 200,
                            body = json.encode({
                                content = {
                                    {
                                        type = "tool_use",
                                        name = "structured_output",
                                        id = "tool_456",
                                        input = {
                                            name = "Bob",
                                            age = 25,
                                            city = "Boston"
                                        }
                                    }
                                },
                                stop_reason = "tool_use",
                                usage = {
                                    input_tokens = 20,
                                    output_tokens = 15
                                },
                                metadata = { request_id = "req_struct123" }
                            }),
                            headers = { ["request-id"] = "req_struct123" }
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate person data" }} }
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
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.result).not_to_be_nil()
                expect(response.result.data).not_to_be_nil()
                expect(response.result.data.name).to_equal("Bob")
                expect(response.result.data.age).to_equal(25)
                expect(response.result.data.city).to_equal("Boston")
                expect(response.tokens.prompt_tokens).to_equal(20)
                expect(response.tokens.completion_tokens).to_equal(15)
                expect(response.tokens.total_tokens).to_equal(35)
                expect(response.finish_reason).to_equal("stop")
            end)

            it("should handle nested object schemas", function()
                structured_output_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                structured_output_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                structured_output_handler._client._http_client = {
                    post = function(url, options)
                        local payload = json.decode(options.body)
                        expect(payload.tools[1].input_schema.properties.address).not_to_be_nil()
                        expect(payload.tools[1].input_schema.properties.address.type).to_equal("object")

                        return {
                            status_code = 200,
                            body = json.encode({
                                content = {
                                    {
                                        type = "tool_use",
                                        name = "structured_output",
                                        id = "tool_nested",
                                        input = {
                                            name = "Carol",
                                            address = {
                                                street = "456 Oak Ave",
                                                city = "Chicago"
                                            }
                                        }
                                    }
                                },
                                stop_reason = "tool_use",
                                usage = { input_tokens = 25, output_tokens = 20 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate person with address" }} }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            name = { type = "string" },
                            address = {
                                type = "object",
                                properties = {
                                    street = { type = "string" },
                                    city = { type = "string" }
                                },
                                required = { "street", "city" },
                                additionalProperties = false
                            }
                        },
                        required = { "name", "address" },
                        additionalProperties = false
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.result.data.name).to_equal("Carol")
                expect(response.result.data.address.street).to_equal("456 Oak Ave")
                expect(response.result.data.address.city).to_equal("Chicago")
            end)

            it("should handle arrays in schemas", function()
                structured_output_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                structured_output_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                structured_output_handler._client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = json.encode({
                                content = {
                                    {
                                        type = "tool_use",
                                        name = "structured_output",
                                        id = "tool_array",
                                        input = {
                                            name = "David",
                                            skills = { "JavaScript", "Python", "Lua" }
                                        }
                                    }
                                },
                                stop_reason = "tool_use",
                                usage = { input_tokens = 18, output_tokens = 12 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate person with skills" }} }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            name = { type = "string" },
                            skills = {
                                type = "array",
                                items = { type = "string" }
                            }
                        },
                        required = { "name", "skills" },
                        additionalProperties = false
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.result.data.name).to_equal("David")
                expect(type(response.result.data.skills)).to_equal("table")
                expect(#response.result.data.skills).to_equal(3)
                expect(response.result.data.skills[1]).to_equal("JavaScript")
                expect(response.result.data.skills[2]).to_equal("Python")
                expect(response.result.data.skills[3]).to_equal("Lua")
            end)

            it("should handle system messages in mapper", function()
                structured_output_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                structured_output_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                structured_output_handler._client._http_client = {
                    post = function(url, options)
                        local payload = json.decode(options.body)
                        expect(payload.system).not_to_be_nil()
                        expect(#payload.system).to_equal(1)
                        expect(payload.system[1].type).to_equal("text")
                        expect(payload.system[1].text).to_equal("Be precise and accurate")

                        return {
                            status_code = 200,
                            body = json.encode({
                                content = {
                                    {
                                        type = "tool_use",
                                        name = "structured_output",
                                        id = "tool_system",
                                        input = { status = "success" }
                                    }
                                },
                                stop_reason = "tool_use",
                                usage = { input_tokens = 25, output_tokens = 8 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "system", content = "Be precise and accurate" },
                        { role = "user", content = {{ type = "text", text = "Generate status" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { status = { type = "string" } },
                        required = { "status" },
                        additionalProperties = false
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.result.data.status).to_equal("success")
            end)
        end)

        describe("Options Handling", function()
            it("should handle standard model options", function()
                structured_output_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                structured_output_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                structured_output_handler._client._http_client = {
                    post = function(url, options)
                        local payload = json.decode(options.body)
                        expect(payload.temperature).to_equal(0.2)
                        expect(payload.max_tokens).to_equal(200)
                        expect(payload.top_p).to_equal(0.8)

                        return {
                            status_code = 200,
                            body = json.encode({
                                content = {
                                    {
                                        type = "tool_use",
                                        name = "structured_output",
                                        id = "tool_options",
                                        input = { test = true }
                                    }
                                },
                                stop_reason = "tool_use",
                                usage = { input_tokens = 10, output_tokens = 5 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { test = { type = "boolean" } },
                        required = { "test" },
                        additionalProperties = false
                    },
                    options = {
                        temperature = 0.2,
                        max_tokens = 200,
                        top_p = 0.8
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_true()
            end)

            it("should handle thinking configuration for Claude 3.7", function()
                structured_output_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                structured_output_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                structured_output_handler._client._http_client = {
                    post = function(url, options)
                        local payload = json.decode(options.body)
                        expect(payload.model).to_equal("claude-3-7-sonnet-20250219")
                        expect(payload.thinking).not_to_be_nil()
                        expect(payload.thinking.type).to_equal("enabled")
                        expect(payload.thinking.budget_tokens).to_be_greater_than(1024)
                        expect(payload.temperature).to_equal(1) -- Required for thinking
                        expect(payload.max_tokens).to_be_greater_than(payload.thinking.budget_tokens)

                        return {
                            status_code = 200,
                            body = json.encode({
                                content = {
                                    {
                                        type = "thinking",
                                        thinking = "Let me structure this properly..."
                                    },
                                    {
                                        type = "tool_use",
                                        name = "structured_output",
                                        id = "tool_thinking",
                                        input = { result = "structured thinking" }
                                    }
                                },
                                stop_reason = "tool_use",
                                usage = {
                                    input_tokens = 30,
                                    output_tokens = 25
                                }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-7-sonnet-20250219",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate structured data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { result = { type = "string" } },
                        required = { "result" },
                        additionalProperties = false
                    },
                    options = {
                        thinking_effort = 80,
                        max_tokens = 150,
                        temperature = 0.5 -- Should be overridden to 1
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.result.data.result).to_equal("structured thinking")
            end)
        end)

        describe("Error Handling", function()
            it("should handle Claude API errors", function()
                structured_output_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                structured_output_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                structured_output_handler._client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 400,
                            body = json.encode({
                                type = "error",
                                error = {
                                    type = "invalid_request_error",
                                    message = "Invalid model specified"
                                }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "invalid-model",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { test = { type = "string" } },
                        required = { "test" },
                        additionalProperties = false
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_equal("Invalid model specified")
            end)

            it("should handle missing tool_use block", function()
                structured_output_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                structured_output_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                structured_output_handler._client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = json.encode({
                                content = {
                                    {
                                        type = "text",
                                        text = "I'll provide the data in JSON format: {\"test\": \"value\"}"
                                    }
                                },
                                stop_reason = "end_turn",
                                usage = { input_tokens = 15, output_tokens = 10 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { test = { type = "string" } },
                        required = { "test" },
                        additionalProperties = false
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("server_error")
                expect(response.error_message).to_contain("Claude failed to use the structured_output tool")
            end)

            it("should handle tool_use block without input", function()
                structured_output_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                structured_output_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                structured_output_handler._client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = json.encode({
                                content = {
                                    {
                                        type = "tool_use",
                                        name = "structured_output",
                                        id = "tool_noinput"
                                        -- Missing input field
                                    }
                                },
                                stop_reason = "tool_use",
                                usage = { input_tokens = 15, output_tokens = 5 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { test = { type = "string" } },
                        required = { "test" },
                        additionalProperties = false
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("server_error")
                expect(response.error_message).to_contain("Tool use block does not contain input")
            end)

            it("should handle invalid response structure", function()
                structured_output_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                structured_output_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                structured_output_handler._client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = json.encode({}), -- Empty response
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { test = { type = "string" } },
                        required = { "test" },
                        additionalProperties = false
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("server_error")
                expect(response.error_message).to_contain("Invalid response structure")
            end)

            it("should handle authentication errors", function()
                structured_output_handler._client._ctx = {
                    all = function()
                        return { api_key = "invalid-key" }
                    end
                }

                structured_output_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                structured_output_handler._client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 401,
                            body = json.encode({
                                type = "error",
                                error = {
                                    type = "authentication_error",
                                    message = "Invalid API key"
                                }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { test = { type = "string" } },
                        required = { "test" },
                        additionalProperties = false
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.error).to_equal("authentication_error")
                expect(response.error_message).to_equal("Invalid API key")
            end)

            it("should handle rate limit errors", function()
                structured_output_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                structured_output_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                structured_output_handler._client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 429,
                            body = json.encode({
                                type = "error",
                                error = {
                                    type = "rate_limit_error",
                                    message = "Rate limit exceeded"
                                }
                            }),
                            headers = {
                                ["anthropic-ratelimit-requests-remaining"] = "0"
                            }
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { test = { type = "string" } },
                        required = { "test" },
                        additionalProperties = false
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.error).to_equal("rate_limit_exceeded")
                expect(response.error_message).to_equal("Rate limit exceeded")
            end)
        end)

        describe("Context Resolution", function()
            it("should resolve API configuration from context", function()
                structured_output_handler._client._ctx = {
                    all = function()
                        return {
                            api_key_env = "CUSTOM_ANTHROPIC_KEY",
                            base_url = "https://custom.claude.api"
                        }
                    end
                }

                structured_output_handler._client._env = {
                    get = function(key)
                        if key == "CUSTOM_ANTHROPIC_KEY" then return "custom-structured-key" end
                        return nil
                    end
                }

                structured_output_handler._client._http_client = {
                    post = function(url, options)
                        expect(url).to_equal("https://custom.claude.api/v1/messages")
                        expect(options.headers["x-api-key"]).to_equal("custom-structured-key")

                        return {
                            status_code = 200,
                            body = json.encode({
                                content = {
                                    {
                                        type = "tool_use",
                                        name = "structured_output",
                                        id = "tool_context",
                                        input = { success = true }
                                    }
                                },
                                stop_reason = "tool_use",
                                usage = { input_tokens = 10, output_tokens = 5 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { success = { type = "boolean" } },
                        required = { "success" },
                        additionalProperties = false
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.result.data.success).to_be_true()
            end)

            it("should handle custom timeout", function()
                structured_output_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                structured_output_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                structured_output_handler._client._http_client = {
                    post = function(url, options)
                        expect(options.timeout).to_equal(60)

                        return {
                            status_code = 200,
                            body = json.encode({
                                content = {
                                    {
                                        type = "tool_use",
                                        name = "structured_output",
                                        id = "tool_timeout",
                                        input = { value = 123 }
                                    }
                                },
                                stop_reason = "tool_use",
                                usage = { input_tokens = 8, output_tokens = 4 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { value = { type = "number" } },
                        required = { "value" },
                        additionalProperties = false
                    },
                    timeout = 60
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_true()
            end)
        end)

        describe("Tool Configuration", function()
            it("should configure structured_output tool correctly", function()
                structured_output_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                structured_output_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                local tool_validated = false
                structured_output_handler._client._http_client = {
                    post = function(url, options)
                        local payload = json.decode(options.body)

                        expect(payload.tools).not_to_be_nil()
                        expect(#payload.tools).to_equal(1)

                        local tool = payload.tools[1]
                        expect(tool.name).to_equal("structured_output")
                        expect(tool.description).to_contain("Generate structured output")
                        expect(tool.input_schema).not_to_be_nil()
                        expect(tool.input_schema.type).to_equal("object")
                        expect(tool.input_schema.additionalProperties).to_equal(false)

                        expect(payload.tool_choice).not_to_be_nil()
                        expect(payload.tool_choice.type).to_equal("tool")
                        expect(payload.tool_choice.name).to_equal("structured_output")

                        tool_validated = true

                        return {
                            status_code = 200,
                            body = json.encode({
                                content = {
                                    {
                                        type = "tool_use",
                                        name = "structured_output",
                                        id = "tool_config",
                                        input = { configured = true }
                                    }
                                },
                                stop_reason = "tool_use",
                                usage = { input_tokens = 12, output_tokens = 6 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Test tool configuration" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { configured = { type = "boolean" } },
                        required = { "configured" },
                        additionalProperties = false
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(tool_validated).to_be_true()
                expect(response.success).to_be_true()
                expect(response.result.data.configured).to_be_true()
            end)
        end)

        describe("Message Processing", function()
            it("should handle complex message formats", function()
                structured_output_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                structured_output_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                structured_output_handler._client._http_client = {
                    post = function(url, options)
                        local payload = json.decode(options.body)

                        -- Verify system content is mapped correctly
                        expect(payload.system).not_to_be_nil()
                        expect(#payload.system).to_equal(1)
                        expect(payload.system[1].text).to_equal("Extract structured data accurately")

                        -- Verify messages are mapped
                        expect(#payload.messages).to_equal(1)
                        expect(payload.messages[1].role).to_equal("user")

                        return {
                            status_code = 200,
                            body = json.encode({
                                content = {
                                    {
                                        type = "tool_use",
                                        name = "structured_output",
                                        id = "tool_complex",
                                        input = {
                                            extracted = true,
                                            data = { field = "value" }
                                        }
                                    }
                                },
                                stop_reason = "tool_use",
                                usage = { input_tokens = 20, output_tokens = 12 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "system", content = "Extract structured data accurately" },
                        { role = "user", content = {{ type = "text", text = "Process this data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            extracted = { type = "boolean" },
                            data = {
                                type = "object",
                                properties = { field = { type = "string" } },
                                required = { "field" },
                                additionalProperties = false
                            }
                        },
                        required = { "extracted", "data" },
                        additionalProperties = false
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.result.data.extracted).to_be_true()
                expect(response.result.data.data.field).to_equal("value")
            end)
        end)

        describe("Response Format Compliance", function()
            it("should return contract-compliant success response", function()
                structured_output_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                structured_output_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                structured_output_handler._client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = json.encode({
                                content = {
                                    {
                                        type = "tool_use",
                                        name = "structured_output",
                                        id = "tool_compliance",
                                        input = {
                                            status = "completed",
                                            count = 42
                                        }
                                    }
                                },
                                stop_reason = "tool_use",
                                usage = {
                                    input_tokens = 15,
                                    output_tokens = 8,
                                    cache_creation_input_tokens = 5,
                                    cache_read_input_tokens = 2
                                }
                            }),
                            headers = {
                                ["request-id"] = "req_compliance123",
                                ["processing-ms"] = "180"
                            }
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate status" }} }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            status = { type = "string" },
                            count = { type = "number" }
                        },
                        required = { "status", "count" },
                        additionalProperties = false
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                -- Verify contract compliance
                expect(response.success).to_be_true()
                expect(response.result).not_to_be_nil()
                expect(response.result.data).not_to_be_nil()
                expect(response.tokens).not_to_be_nil()
                expect(response.finish_reason).not_to_be_nil()
                expect(response.metadata).not_to_be_nil()

                -- Verify specific values
                expect(response.result.data.status).to_equal("completed")
                expect(response.result.data.count).to_equal(42)
                expect(response.tokens.prompt_tokens).to_equal(15)
                expect(response.tokens.completion_tokens).to_equal(8)
                expect(response.tokens.total_tokens).to_equal(23)
                expect(response.tokens.cache_write_tokens).to_equal(5)
                expect(response.tokens.cache_read_tokens).to_equal(2)
                expect(response.finish_reason).to_equal("stop")
                expect(response.metadata.request_id).to_equal("req_compliance123")
            end)
        end)

        describe("Edge Cases", function()
            it("should handle missing API key", function()
                structured_output_handler._client._ctx = {
                    all = function()
                        return {}
                    end
                }

                structured_output_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                structured_output_handler._client._http_client = nil

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { test = { type = "string" } },
                        required = { "test" },
                        additionalProperties = false
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.error).to_equal("authentication_error")
                expect(response.error_message).to_contain("API key is required")
            end)

            it("should handle connection failures", function()
                structured_output_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                structured_output_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                structured_output_handler._client._http_client = {
                    post = function(url, options)
                        return nil -- Simulate connection failure
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { test = { type = "string" } },
                        required = { "test" },
                        additionalProperties = false
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.error).to_equal("server_error")
                expect(response.error_message).to_equal("Connection failed")
            end)

            it("should handle JSON parsing errors gracefully", function()
                structured_output_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                structured_output_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                structured_output_handler._client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = "invalid json {", -- Malformed JSON
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { test = { type = "string" } },
                        required = { "test" },
                        additionalProperties = false
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.error).to_equal("server_error")
                expect(response.error_message).to_contain("Failed to parse Claude response")
            end)

            it("should handle wrong tool name in response", function()
                structured_output_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                structured_output_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                structured_output_handler._client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = json.encode({
                                content = {
                                    {
                                        type = "tool_use",
                                        name = "wrong_tool", -- Wrong tool name
                                        id = "tool_wrong",
                                        input = { test = "value" }
                                    }
                                },
                                stop_reason = "tool_use",
                                usage = { input_tokens = 10, output_tokens = 5 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { test = { type = "string" } },
                        required = { "test" },
                        additionalProperties = false
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("server_error")
                expect(response.error_message).to_contain("Claude failed to use the structured_output tool")
            end)
        end)

        describe("Complex Schema Validation", function()
            it("should validate deeply nested schemas", function()
                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            user = {
                                type = "object",
                                properties = {
                                    profile = {
                                        type = "object",
                                        properties = {
                                            name = { type = "string" }
                                        },
                                        required = { "name" },
                                        additionalProperties = false
                                    }
                                },
                                required = { "profile" },
                                additionalProperties = false
                            }
                        },
                        required = { "user" },
                        additionalProperties = false
                    }
                }

                structured_output_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                structured_output_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                structured_output_handler._client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = json.encode({
                                content = {
                                    {
                                        type = "tool_use",
                                        name = "structured_output",
                                        id = "tool_nested_deep",
                                        input = {
                                            user = {
                                                profile = {
                                                    name = "Deep Nester"
                                                }
                                            }
                                        }
                                    }
                                },
                                stop_reason = "tool_use",
                                usage = { input_tokens = 30, output_tokens = 18 }
                            }),
                            headers = {}
                        }
                    end
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.result.data.user.profile.name).to_equal("Deep Nester")
            end)

            it("should handle array schemas with object items", function()
                structured_output_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                structured_output_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                structured_output_handler._client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = json.encode({
                                content = {
                                    {
                                        type = "tool_use",
                                        name = "structured_output",
                                        id = "tool_array_obj",
                                        input = {
                                            users = {
                                                { name = "Alice", age = 30 },
                                                { name = "Bob", age = 25 }
                                            }
                                        }
                                    }
                                },
                                stop_reason = "tool_use",
                                usage = { input_tokens = 35, output_tokens = 22 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate user list" }} }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            users = {
                                type = "array",
                                items = {
                                    type = "object",
                                    properties = {
                                        name = { type = "string" },
                                        age = { type = "number" }
                                    },
                                    required = { "name", "age" },
                                    additionalProperties = false
                                }
                            }
                        },
                        required = { "users" },
                        additionalProperties = false
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_true()
                expect(#response.result.data.users).to_equal(2)
                expect(response.result.data.users[1].name).to_equal("Alice")
                expect(response.result.data.users[2].age).to_equal(25)
            end)
        end)

        describe("Metadata and Token Handling", function()
            it("should extract and format metadata correctly", function()
                structured_output_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                structured_output_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                structured_output_handler._client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = json.encode({
                                content = {
                                    {
                                        type = "tool_use",
                                        name = "structured_output",
                                        id = "tool_meta",
                                        input = { result = "success" }
                                    }
                                },
                                stop_reason = "tool_use",
                                usage = {
                                    input_tokens = 12,
                                    output_tokens = 6,
                                    cache_creation_input_tokens = 3,
                                    cache_read_input_tokens = 1
                                }
                            }),
                            headers = {
                                ["request-id"] = "req_metadata456",
                                ["processing-ms"] = "250",
                                ["anthropic-ratelimit-requests-remaining"] = "999"
                            }
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Test metadata" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { result = { type = "string" } },
                        required = { "result" },
                        additionalProperties = false
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.metadata.request_id).to_equal("req_metadata456")
                expect(response.metadata.processing_ms).to_equal(250)
                expect(response.metadata.rate_limits.requests_remaining).to_equal(999)
                expect(response.tokens.cache_write_tokens).to_equal(3)
                expect(response.tokens.cache_read_tokens).to_equal(1)
            end)
        end)

        describe("Tool Choice Validation", function()
            it("should force structured_output tool usage", function()
                structured_output_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                structured_output_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                local tool_choice_validated = false
                structured_output_handler._client._http_client = {
                    post = function(url, options)
                        local payload = json.decode(options.body)

                        -- Verify tool choice is set to force our tool
                        expect(payload.tool_choice).not_to_be_nil()
                        expect(payload.tool_choice.type).to_equal("tool")
                        expect(payload.tool_choice.name).to_equal("structured_output")

                        -- Verify only one tool is provided
                        expect(#payload.tools).to_equal(1)
                        expect(payload.tools[1].name).to_equal("structured_output")

                        tool_choice_validated = true

                        return {
                            status_code = 200,
                            body = json.encode({
                                content = {
                                    {
                                        type = "tool_use",
                                        name = "structured_output",
                                        id = "tool_forced",
                                        input = { forced = true }
                                    }
                                },
                                stop_reason = "tool_use",
                                usage = { input_tokens = 8, output_tokens = 4 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { forced = { type = "boolean" } },
                        required = { "forced" },
                        additionalProperties = false
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(tool_choice_validated).to_be_true()
                expect(response.success).to_be_true()
                expect(response.result.data.forced).to_be_true()
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)