local structured_output_handler = require("structured_output_handler")
local json = require("json")

local function define_tests()
    describe("OpenAI Structured Output Handler", function()

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
                    model = "gpt-4o",
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
                    model = "gpt-4o",
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
                    model = "gpt-4o",
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
                    model = "gpt-4o",
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
                expect(response.error_message).to_contain("Root schema must be an object")
            end)

            it("should require additionalProperties: false", function()
                local contract_args = {
                    model = "gpt-4o",
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
                    model = "gpt-4o",
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
                expect(response.error_message).to_contain("Properties must be marked as required")
            end)

            it("should require required array when properties exist", function()
                local contract_args = {
                    model = "gpt-4o",
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
                expect(response.error_message).to_contain("Schema must have a required array")
            end)

            it("should handle non-table schema", function()
                local contract_args = {
                    model = "gpt-4o",
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
                                choices = {
                                    {
                                        message = {
                                            content = '{"name":"John","age":30}'
                                        },
                                        finish_reason = "stop"
                                    }
                                },
                                usage = { prompt_tokens = 15, completion_tokens = 10, total_tokens = 25 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "gpt-4o",
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
                        expect(url).to_contain("chat/completions")

                        local payload = json.decode(options.body)
                        expect(payload.model).to_equal("gpt-4o")
                        expect(payload.response_format).not_to_be_nil()
                        expect(payload.response_format.type).to_equal("json_schema")
                        expect(payload.response_format.json_schema.strict).to_be_true()
                        expect(payload.response_format.json_schema.schema).not_to_be_nil()

                        return {
                            status_code = 200,
                            body = json.encode({
                                choices = {
                                    {
                                        message = {
                                            content = '{"name":"Alice","age":25,"city":"New York"}'
                                        },
                                        finish_reason = "stop"
                                    }
                                },
                                usage = {
                                    prompt_tokens = 20,
                                    completion_tokens = 15,
                                    total_tokens = 35
                                }
                            }),
                            headers = { ["X-Request-Id"] = "req_struct123" }
                        }
                    end
                }

                local contract_args = {
                    model = "gpt-4o",
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
                expect(response.result.data.name).to_equal("Alice")
                expect(response.result.data.age).to_equal(25)
                expect(response.result.data.city).to_equal("New York")
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
                        expect(payload.response_format.json_schema.schema.properties.address).not_to_be_nil()
                        expect(payload.response_format.json_schema.schema.properties.address.type).to_equal("object")

                        return {
                            status_code = 200,
                            body = json.encode({
                                choices = {
                                    {
                                        message = {
                                            content = '{"name":"Bob","address":{"street":"123 Main St","city":"Boston"}}'
                                        },
                                        finish_reason = "stop"
                                    }
                                },
                                usage = { prompt_tokens = 25, completion_tokens = 20, total_tokens = 45 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "gpt-4o",
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
                expect(response.result.data.name).to_equal("Bob")
                expect(response.result.data.address.street).to_equal("123 Main St")
                expect(response.result.data.address.city).to_equal("Boston")
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
                                choices = {
                                    {
                                        message = {
                                            content = '{"name":"Carol","skills":["JavaScript","Python","Go"]}'
                                        },
                                        finish_reason = "stop"
                                    }
                                },
                                usage = { prompt_tokens = 18, completion_tokens = 12, total_tokens = 30 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "gpt-4o",
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
                expect(response.result.data.name).to_equal("Carol")
                expect(type(response.result.data.skills)).to_equal("table")
                expect(#response.result.data.skills).to_equal(3)
                expect(response.result.data.skills[1]).to_equal("JavaScript")
                expect(response.result.data.skills[2]).to_equal("Python")
                expect(response.result.data.skills[3]).to_equal("Go")
            end)

            it("should generate schema name automatically", function()
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
                        expect(payload.response_format.json_schema.name).to_contain("schema_")
                        expect(string.len(payload.response_format.json_schema.name)).to_be_greater_than(7)

                        return {
                            status_code = 200,
                            body = json.encode({
                                choices = {{ message = { content = '{"test":true}' }, finish_reason = "stop" }},
                                usage = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "gpt-4o",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { test = { type = "boolean" } },
                        required = { "test" },
                        additionalProperties = false
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_true()
            end)

            it("should handle custom schema name", function()
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
                        expect(payload.response_format.json_schema.name).to_equal("custom_schema_name")

                        return {
                            status_code = 200,
                            body = json.encode({
                                choices = {{ message = { content = '{"value":42}' }, finish_reason = "stop" }},
                                usage = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "gpt-4o",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { value = { type = "number" } },
                        required = { "value" },
                        additionalProperties = false
                    },
                    schema_name = "custom_schema_name"
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_true()
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
                                choices = {{ message = { content = '{"test":true}' }, finish_reason = "stop" }},
                                usage = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "gpt-4o",
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

            it("should handle reasoning model options", function()
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
                        expect(payload.model).to_equal("o1-mini")
                        expect(payload.reasoning_effort).to_equal("high")
                        expect(payload.max_completion_tokens).to_equal(150)
                        expect(payload.max_tokens).to_be_nil()
                        expect(payload.temperature).to_be_nil()

                        return {
                            status_code = 200,
                            body = json.encode({
                                choices = {
                                    {
                                        message = { content = '{"result":"structured thinking"}' },
                                        finish_reason = "stop"
                                    }
                                },
                                usage = {
                                    prompt_tokens = 25,
                                    completion_tokens = 30,
                                    completion_tokens_details = { reasoning_tokens = 15 },
                                    total_tokens = 70
                                }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "o1-mini",
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
                        reasoning_model_request = true,
                        thinking_effort = 80,
                        max_tokens = 150,
                        temperature = 0.5 -- Should be ignored
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.result.data.result).to_equal("structured thinking")
                expect(response.tokens.thinking_tokens).to_equal(15)
            end)
        end)

        describe("Error Handling", function()
            it("should handle refusal responses", function()
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
                                choices = {
                                    {
                                        message = {
                                            refusal = "I cannot generate that type of content."
                                        },
                                        finish_reason = "stop"
                                    }
                                },
                                usage = { prompt_tokens = 15, completion_tokens = 8, total_tokens = 23 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "gpt-4o",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate inappropriate content" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { content = { type = "string" } },
                        required = { "content" },
                        additionalProperties = false
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("content_filtered")
                expect(response.error_message).to_contain("I cannot generate that type of content.")
            end)

            it("should handle invalid JSON in response", function()
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
                                choices = {
                                    {
                                        message = {
                                            content = 'invalid json {'
                                        },
                                        finish_reason = "stop"
                                    }
                                },
                                usage = { prompt_tokens = 15, completion_tokens = 10, total_tokens = 25 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "gpt-4o",
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
                expect(response.error).to_equal("model_error")
                expect(response.error_message).to_contain("Model failed to return valid JSON")
            end)

            it("should handle missing content in response", function()
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
                                choices = {
                                    {
                                        message = {},
                                        finish_reason = "stop"
                                    }
                                },
                                usage = { prompt_tokens = 15, completion_tokens = 0, total_tokens = 15 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "gpt-4o",
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
                expect(response.error_message).to_contain("No content")
            end)

            it("should handle API authentication errors", function()
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
                            status_code = 401,
                            body = json.encode({
                                error = {
                                    message = "Invalid API key provided",
                                    type = "invalid_request_error"
                                }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "gpt-4o",
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
                expect(response.error).to_equal("authentication_error")
                expect(response.error_message).to_contain("Invalid API key")
            end)

            it("should handle model not found errors", function()
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
                            status_code = 404,
                            body = json.encode({
                                error = {
                                    message = "The model 'nonexistent-model' does not exist",
                                    type = "invalid_request_error"
                                }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "nonexistent-model",
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
                expect(response.error).to_equal("model_error")
                expect(response.error_message).to_contain("does not exist")
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
                    model = "gpt-4o",
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
        end)

        describe("Context Resolution", function()
            it("should resolve API configuration from context", function()
                structured_output_handler._client._ctx = {
                    all = function()
                        return {
                            api_key_env = "CUSTOM_OPENAI_KEY",
                            base_url = "https://custom.structured.api/v1",
                            timeout = 45
                        }
                    end
                }

                structured_output_handler._client._env = {
                    get = function(key)
                        if key == "CUSTOM_OPENAI_KEY" then return "custom-structured-key" end
                        return nil
                    end
                }

                structured_output_handler._client._http_client = {
                    post = function(url, options)
                        expect(url).to_contain("https://custom.structured.api/v1/chat/completions")
                        expect(options.headers["Authorization"]).to_equal("Bearer custom-structured-key")
                        expect(options.timeout).to_equal(45)

                        return {
                            status_code = 200,
                            body = json.encode({
                                choices = {{ message = { content = '{"success":true}' }, finish_reason = "stop" }},
                                usage = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "gpt-4o",
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
                                choices = {{ message = { content = '{"value":123}' }, finish_reason = "stop" }},
                                usage = { prompt_tokens = 8, completion_tokens = 4, total_tokens = 12 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "gpt-4o",
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
    end)
end

return require("test").run_cases(define_tests)