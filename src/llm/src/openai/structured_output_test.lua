local structured_output_handler = require("structured_output_handler")
local json = require("json")
local test = require("test")

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

                local response, err = structured_output_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Invalid")
                test.contains(tostring(err:message()), "Model is required")
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

                local response, err = structured_output_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Invalid")
                test.contains(tostring(err:message()), "Messages are required")
            end)

            it("should require schema parameter", function()
                local contract_args = {
                    model = "gpt-4o",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    }
                }

                local response, err = structured_output_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Invalid")
                test.contains(tostring(err:message()), "Schema is required")
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

                local response, err = structured_output_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Invalid")
                test.contains(tostring(err:message()), "Messages are required")
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

                local response, err = structured_output_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Invalid")
                test.contains(tostring(err:message()), "Root schema must be an object")
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

                local response, err = structured_output_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Invalid")
                test.contains(tostring(err:message()), "additionalProperties: false")
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

                local response, err = structured_output_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Invalid")
                test.contains(tostring(err:message()), "Properties must be marked as required")
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

                local response, err = structured_output_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Invalid")
                test.contains(tostring(err:message()), "Schema must have a required array")
            end)

            it("should handle non-table schema", function()
                local contract_args = {
                    model = "gpt-4o",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = "not a table"
                }

                local response, err = structured_output_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Invalid")
                test.contains(tostring(err:message()), "Schema must be a table")
            end)

            it("should pass valid schema", function()
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
                                id = "resp_valid",
                                status = "completed",
                                output = {
                                    {
                                        type = "message",
                                        role = "assistant",
                                        content = {
                                            { type = "output_text", text = '{"name":"John","age":30}' }
                                        }
                                    }
                                },
                                usage = { input_tokens = 15, output_tokens = 10, total_tokens = 25 }
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

                local response, err = structured_output_handler.handler(contract_args)

                test.is_true(response.success)
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
                        -- Responses API endpoint
                        test.contains(tostring(url), "/responses")

                        local payload = json.decode(tostring(options.body))
                        test.eq(payload.model, "gpt-4o")
                        -- Responses API uses text.format.json_schema instead of response_format.json_schema
                        test.is_nil(payload.response_format)
                        test.not_nil(payload.text)
                        test.not_nil(payload.text.format)
                        test.eq(payload.text.format.type, "json_schema")
                        test.is_true(payload.text.format.strict)
                        test.not_nil(payload.text.format.schema)

                        return {
                            status_code = 200,
                            body = json.encode({
                                id = "resp_struct_1",
                                status = "completed",
                                output = {
                                    {
                                        type = "message",
                                        role = "assistant",
                                        content = {
                                            { type = "output_text", text = '{"name":"Alice","age":25,"city":"New York"}' }
                                        }
                                    }
                                },
                                usage = {
                                    input_tokens = 20,
                                    output_tokens = 15,
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

                local response, err = structured_output_handler.handler(contract_args)

                test.is_true(response.success)
                assert(response.result)
                local data = assert(response.result.data)
                test.eq(data.name, "Alice")
                test.eq(data.age, 25)
                test.eq(data.city, "New York")
                test.eq(response.tokens.prompt_tokens, 20)
                test.eq(response.tokens.completion_tokens, 15)
                test.eq(response.tokens.total_tokens, 35)
                test.eq(response.finish_reason, "stop")
                test.eq(response.metadata.response_id, "resp_struct_1")
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
                        local payload = json.decode(tostring(options.body))
                        test.not_nil(payload.text.format.schema.properties.address)
                        test.eq(payload.text.format.schema.properties.address.type, "object")

                        return {
                            status_code = 200,
                            body = json.encode({
                                id = "resp_nested",
                                status = "completed",
                                output = {
                                    {
                                        type = "message",
                                        role = "assistant",
                                        content = {
                                            { type = "output_text", text = '{"name":"Bob","address":{"street":"123 Main St","city":"Boston"}}' }
                                        }
                                    }
                                },
                                usage = { input_tokens = 25, output_tokens = 20, total_tokens = 45 }
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

                local response, err = structured_output_handler.handler(contract_args)

                test.is_true(response.success)
                assert(response.result)
                local data = assert(response.result.data)
                test.eq(data.name, "Bob")
                test.eq(data.address.street, "123 Main St")
                test.eq(data.address.city, "Boston")
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
                                id = "resp_arr",
                                status = "completed",
                                output = {
                                    {
                                        type = "message",
                                        role = "assistant",
                                        content = {
                                            { type = "output_text", text = '{"name":"Carol","skills":["JavaScript","Python","Go"]}' }
                                        }
                                    }
                                },
                                usage = { input_tokens = 18, output_tokens = 12, total_tokens = 30 }
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

                local response, err = structured_output_handler.handler(contract_args)

                test.is_true(response.success)
                assert(response.result)
                local data = assert(response.result.data)
                test.eq(data.name, "Carol")
                test.eq(type(data.skills), "table")
                test.eq(#data.skills, 3)
                test.eq(data.skills[1], "JavaScript")
                test.eq(data.skills[2], "Python")
                test.eq(data.skills[3], "Go")
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
                        local payload = json.decode(tostring(options.body))
                        test.contains(tostring(payload.text.format.name), "schema_")
                        test.gt(string.len(payload.text.format.name), 7)

                        return {
                            status_code = 200,
                            body = json.encode({
                                id = "r",
                                status = "completed",
                                output = {
                                    {
                                        type = "message",
                                        role = "assistant",
                                        content = { { type = "output_text", text = '{"test":true}' } }
                                    }
                                },
                                usage = { input_tokens = 10, output_tokens = 5, total_tokens = 15 }
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

                local response, err = structured_output_handler.handler(contract_args)

                test.is_true(response.success)
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
                        local payload = json.decode(tostring(options.body))
                        test.eq(payload.text.format.name, "custom_schema_name")

                        return {
                            status_code = 200,
                            body = json.encode({
                                id = "r",
                                status = "completed",
                                output = {
                                    {
                                        type = "message",
                                        role = "assistant",
                                        content = { { type = "output_text", text = '{"value":42}' } }
                                    }
                                },
                                usage = { input_tokens = 10, output_tokens = 5, total_tokens = 15 }
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

                local response, err = structured_output_handler.handler(contract_args)

                test.is_true(response.success)
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
                        local payload = json.decode(tostring(options.body))
                        test.eq(payload.temperature, 0.2)
                        -- Responses API uses max_output_tokens
                        test.eq(payload.max_output_tokens, 200)
                        test.is_nil(payload.max_tokens)
                        test.eq(payload.top_p, 0.8)

                        return {
                            status_code = 200,
                            body = json.encode({
                                id = "r",
                                status = "completed",
                                output = {
                                    {
                                        type = "message",
                                        role = "assistant",
                                        content = { { type = "output_text", text = '{"test":true}' } }
                                    }
                                },
                                usage = { input_tokens = 10, output_tokens = 5, total_tokens = 15 }
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

                local response, err = structured_output_handler.handler(contract_args)

                test.is_true(response.success)
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
                        local payload = json.decode(tostring(options.body))
                        test.eq(payload.model, "o1-mini")
                        -- Responses API: reasoning.effort and max_output_tokens
                        test.not_nil(payload.reasoning)
                        test.eq(payload.reasoning.effort, "high")
                        test.eq(payload.max_output_tokens, 150)
                        test.is_nil(payload.reasoning_effort)
                        test.is_nil(payload.max_tokens)
                        test.is_nil(payload.max_completion_tokens)
                        test.is_nil(payload.temperature)

                        return {
                            status_code = 200,
                            body = json.encode({
                                id = "resp_reason_struct",
                                status = "completed",
                                output = {
                                    {
                                        type = "message",
                                        role = "assistant",
                                        content = {
                                            { type = "output_text", text = '{"result":"structured thinking"}' }
                                        }
                                    }
                                },
                                usage = {
                                    input_tokens = 25,
                                    output_tokens = 30,
                                    output_tokens_details = { reasoning_tokens = 15 },
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

                local response, err = structured_output_handler.handler(contract_args)

                test.is_true(response.success)
                assert(response.result)
                local data = assert(response.result.data)
                test.eq(data.result, "structured thinking")
                test.eq(response.tokens.thinking_tokens, 15)
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
                                id = "resp_refusal",
                                status = "completed",
                                output = {
                                    {
                                        type = "message",
                                        role = "assistant",
                                        content = {
                                            { type = "refusal", refusal = "I cannot generate that type of content." }
                                        }
                                    }
                                },
                                usage = { input_tokens = 15, output_tokens = 8, total_tokens = 23 }
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

                local response, err = structured_output_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Invalid")
                test.contains(tostring(err:message()), "I cannot generate that type of content.")
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
                                id = "r",
                                status = "completed",
                                output = {
                                    {
                                        type = "message",
                                        role = "assistant",
                                        content = { { type = "output_text", text = "invalid json {" } }
                                    }
                                },
                                usage = { input_tokens = 15, output_tokens = 10, total_tokens = 25 }
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

                local response, err = structured_output_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "NotFound")
                test.contains(tostring(err:message()), "Model failed to return valid JSON")
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
                                id = "r",
                                status = "completed",
                                -- output is present but message has no content parts
                                output = {
                                    {
                                        type = "message",
                                        role = "assistant",
                                        content = {}
                                    }
                                },
                                usage = { input_tokens = 15, output_tokens = 0, total_tokens = 15 }
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

                local response, err = structured_output_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Unavailable")
                test.contains(tostring(err:message()), "No content")
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

                local response, err = structured_output_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "PermissionDenied")
                test.contains(tostring(err:message()), "Invalid API key")
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

                local response, err = structured_output_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "NotFound")
                test.contains(tostring(err:message()), "does not exist")
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
                            body = json.encode({}), -- Empty response, no output[]
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

                local response, err = structured_output_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Unavailable")
                test.contains(tostring(err:message()), "Invalid response structure")
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
                        test.contains(tostring(url), "https://custom.structured.api/v1/responses")
                        test.eq(options.headers["Authorization"], "Bearer custom-structured-key")
                        test.eq(options.timeout, 45)

                        return {
                            status_code = 200,
                            body = json.encode({
                                id = "r",
                                status = "completed",
                                output = {
                                    {
                                        type = "message",
                                        role = "assistant",
                                        content = { { type = "output_text", text = '{"success":true}' } }
                                    }
                                },
                                usage = { input_tokens = 10, output_tokens = 5, total_tokens = 15 }
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

                local response, err = structured_output_handler.handler(contract_args)

                test.is_true(response.success)
                assert(response.result)
                local data = assert(response.result.data)
                test.is_true(data.success)
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
                        test.eq(options.timeout, 60)

                        return {
                            status_code = 200,
                            body = json.encode({
                                id = "r",
                                status = "completed",
                                output = {
                                    {
                                        type = "message",
                                        role = "assistant",
                                        content = { { type = "output_text", text = '{"value":123}' } }
                                    }
                                },
                                usage = { input_tokens = 8, output_tokens = 4, total_tokens = 12 }
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

                local response, err = structured_output_handler.handler(contract_args)

                test.is_true(response.success)
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
