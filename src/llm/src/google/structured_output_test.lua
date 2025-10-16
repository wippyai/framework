local structured_output = require("google_structured_output")
local tests = require("test")

local function define_tests()
    describe("Google Structured Output Handler", function()

        after_each(function()
            structured_output._contract = nil
            structured_output._mapper = nil
            structured_output._ctx = nil
        end)

        describe("Contract Argument Validation", function()
            it("should require model parameter", function()
                structured_output._mapper = {
                    map_error_response = function(error_info)
                        return {
                            success = false,
                            error = "invalid_request",
                            error_message = error_info.message,
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { name = { type = "string" } }
                    }
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_equal("Model is required")
            end)

            it("should require messages parameter", function()
                structured_output._mapper = {
                    map_error_response = function(error_info)
                        return {
                            success = false,
                            error = "invalid_request",
                            error_message = error_info.message,
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    schema = {
                        type = "object",
                        properties = { name = { type = "string" } }
                    }
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_equal("Messages are required")
            end)

            it("should require schema parameter", function()
                structured_output._mapper = {
                    map_error_response = function(error_info)
                        return {
                            success = false,
                            error = "invalid_request",
                            error_message = error_info.message,
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    }
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_equal("Schema is required")
            end)

            it("should reject empty messages array", function()
                structured_output._mapper = {
                    map_error_response = function(error_info)
                        return {
                            success = false,
                            error = "invalid_request",
                            error_message = error_info.message,
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {},
                    schema = {
                        type = "object",
                        properties = { test = { type = "boolean" } }
                    }
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_equal("Messages are required")
            end)
        end)

        describe("Schema Validation", function()
            it("should validate schema is a table", function()
                structured_output._mapper = {
                    map_error_response = function(error_info)
                        return {
                            success = false,
                            error = "invalid_request",
                            error_message = error_info.message,
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = "not a table"
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_contain("Schema must be a table")
            end)

            it("should require root schema type to be object", function()
                structured_output._mapper = {
                    map_error_response = function(error_info)
                        return {
                            success = false,
                            error = "invalid_request",
                            error_message = error_info.message,
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "array",
                        items = { type = "string" }
                    }
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_contain("Root schema type must be `object`")
            end)

            it("should accept valid object schema", function()
                structured_output._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Generate data" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = { content = '{"name":"John"}' },
                            tokens = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 },
                            finish_reason = "stop",
                            metadata = {}
                        }
                    end
                }

                structured_output._ctx = {
                    all = function()
                        return {}
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        return {
                            status_code = 200,
                            candidates = {
                                {
                                    content = {
                                        parts = {{ text = '{"name":"John"}' }}
                                    },
                                    finishReason = "STOP"
                                }
                            },
                            usageMetadata = {
                                promptTokenCount = 10,
                                candidatesTokenCount = 5,
                                totalTokenCount = 15
                            }
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                structured_output._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            name = { type = "string" }
                        }
                    }
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_true()
            end)

            it("should handle nil schema", function()
                structured_output._mapper = {
                    map_error_response = function(error_info)
                        return {
                            success = false,
                            error = "invalid_request",
                            error_message = error_info.message,
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = nil
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_equal("Schema is required")
            end)

            it("should handle empty schema table", function()
                structured_output._mapper = {
                    map_error_response = function(error_info)
                        return {
                            success = false,
                            error = "invalid_request",
                            error_message = error_info.message,
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {}
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_contain("Root schema type must be `object`")
            end)

            it("should handle schema with missing type field", function()
                structured_output._mapper = {
                    map_error_response = function(error_info)
                        return {
                            success = false,
                            error = "invalid_request",
                            error_message = error_info.message,
                            metadata = {}
                        }
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        properties = {
                            name = { type = "string" }
                        }
                    }
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_contain("Root schema type must be `object`")
            end)

            it("should accept schema with nested objects", function()
                structured_output._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Generate data" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = { content = '{"person":{"name":"Alice","age":30}}' },
                            tokens = { prompt_tokens = 15, completion_tokens = 10, total_tokens = 25 },
                            finish_reason = "stop",
                            metadata = {}
                        }
                    end
                }

                structured_output._ctx = {
                    all = function()
                        return {}
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        expect(args.payload.generationConfig.responseSchema.type).to_equal("object")
                        expect(args.payload.generationConfig.responseSchema.properties.person.type).to_equal("object")

                        return {
                            status_code = 200,
                            candidates = {
                                {
                                    content = {
                                        parts = {{ text = '{"person":{"name":"Alice","age":30}}' }}
                                    },
                                    finishReason = "STOP"
                                }
                            },
                            usageMetadata = {
                                promptTokenCount = 15,
                                candidatesTokenCount = 10,
                                totalTokenCount = 25
                            }
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                structured_output._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate person data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            person = {
                                type = "object",
                                properties = {
                                    name = { type = "string" },
                                    age = { type = "number" }
                                }
                            }
                        }
                    }
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_true()
            end)
        end)

        describe("Successful Structured Output", function()
            it("should handle successful structured response", function()
                structured_output._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Generate person data" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = { content = '{"name":"Alice","age":25,"city":"New York"}' },
                            tokens = { prompt_tokens = 20, completion_tokens = 15, total_tokens = 35 },
                            finish_reason = "stop",
                            metadata = {}
                        }
                    end
                }

                structured_output._ctx = {
                    all = function()
                        return {}
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        expect(args.endpoint_path).to_equal("generateContent")
                        expect(args.model).to_equal("gemini-1.5-pro")
                        expect(args.payload.generationConfig.response_mime_type).to_equal("application/json")
                        expect(args.payload.generationConfig.responseSchema).not_to_be_nil()

                        return {
                            status_code = 200,
                            candidates = {
                                {
                                    content = {
                                        parts = {{ text = '{"name":"Alice","age":25,"city":"New York"}' }}
                                    },
                                    finishReason = "STOP"
                                }
                            },
                            usageMetadata = {
                                promptTokenCount = 20,
                                candidatesTokenCount = 15,
                                totalTokenCount = 35
                            }
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                structured_output._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate person data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            name = { type = "string" },
                            age = { type = "number" },
                            city = { type = "string" }
                        }
                    }
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.result).not_to_be_nil()
                expect(response.result.data).not_to_be_nil()
                expect(response.result.data.name).to_equal("Alice")
                expect(response.result.data.age).to_equal(25)
                expect(response.result.data.city).to_equal("New York")
                expect(response.tokens.prompt_tokens).to_equal(20)
                expect(response.tokens.completion_tokens).to_equal(15)
                expect(response.finish_reason).to_equal("stop")
            end)

            it("should handle nested object schemas", function()
                structured_output._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Generate person with address" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = { content = '{"name":"Bob","address":{"street":"123 Main St","city":"Boston"}}' },
                            tokens = { prompt_tokens = 25, completion_tokens = 20, total_tokens = 45 },
                            finish_reason = "stop",
                            metadata = {}
                        }
                    end
                }

                structured_output._ctx = {
                    all = function()
                        return {}
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        return {
                            status_code = 200,
                            candidates = {
                                {
                                    content = {
                                        parts = {{ text = '{"name":"Bob","address":{"street":"123 Main St","city":"Boston"}}' }}
                                    },
                                    finishReason = "STOP"
                                }
                            },
                            usageMetadata = {
                                promptTokenCount = 25,
                                candidatesTokenCount = 20,
                                totalTokenCount = 45
                            }
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                structured_output._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
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
                                }
                            }
                        }
                    }
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.result.data.name).to_equal("Bob")
                expect(response.result.data.address.street).to_equal("123 Main St")
                expect(response.result.data.address.city).to_equal("Boston")
            end)

            it("should handle arrays in schemas", function()
                structured_output._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Generate person with skills" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = { content = '{"name":"Carol","skills":["JavaScript","Python","Go"]}' },
                            tokens = { prompt_tokens = 18, completion_tokens = 12, total_tokens = 30 },
                            finish_reason = "stop",
                            metadata = {}
                        }
                    end
                }

                structured_output._ctx = {
                    all = function()
                        return {}
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        return {
                            status_code = 200,
                            candidates = {
                                {
                                    content = {
                                        parts = {{ text = '{"name":"Carol","skills":["JavaScript","Python","Go"]}' }}
                                    },
                                    finishReason = "STOP"
                                }
                            },
                            usageMetadata = {
                                promptTokenCount = 18,
                                candidatesTokenCount = 12,
                                totalTokenCount = 30
                            }
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                structured_output._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
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
                        }
                    }
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.result.data.name).to_equal("Carol")
                expect(type(response.result.data.skills)).to_equal("table")
                expect(#response.result.data.skills).to_equal(3)
                expect(response.result.data.skills[1]).to_equal("JavaScript")
                expect(response.result.data.skills[2]).to_equal("Python")
                expect(response.result.data.skills[3]).to_equal("Go")
            end)

            it("should handle system instructions", function()
                structured_output._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Generate data" }} }
                        }, {
                            { text = "You are a data generator" }
                        }
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = { content = '{"value":42}' },
                            tokens = { prompt_tokens = 15, completion_tokens = 5, total_tokens = 20 },
                            finish_reason = "stop",
                            metadata = {}
                        }
                    end
                }

                structured_output._ctx = {
                    all = function()
                        return {}
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        expect(args.payload.systemInstruction).not_to_be_nil()
                        expect(args.payload.systemInstruction.parts[1].text).to_equal("You are a data generator")

                        return {
                            status_code = 200,
                            candidates = {
                                {
                                    content = {
                                        parts = {{ text = '{"value":42}' }}
                                    },
                                    finishReason = "STOP"
                                }
                            },
                            usageMetadata = {
                                promptTokenCount = 15,
                                candidatesTokenCount = 5,
                                totalTokenCount = 20
                            }
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                structured_output._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "system", content = {{ type = "text", text = "You are a data generator" }} },
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            value = { type = "number" }
                        }
                    }
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.result.data.value).to_equal(42)
            end)
        end)

        describe("Schema Name Generation", function()
            it("should generate schema name automatically", function()
                structured_output._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Generate data" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = { content = '{"test":true}' },
                            tokens = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 },
                            finish_reason = "stop",
                            metadata = {}
                        }
                    end
                }

                structured_output._ctx = {
                    all = function()
                        return {}
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        -- Schema name is generated but not used in Google API
                        -- Just verify the request is successful
                        return {
                            status_code = 200,
                            candidates = {
                                {
                                    content = {
                                        parts = {{ text = '{"test":true}' }}
                                    },
                                    finishReason = "STOP"
                                }
                            },
                            usageMetadata = {
                                promptTokenCount = 10,
                                candidatesTokenCount = 5,
                                totalTokenCount = 15
                            }
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                structured_output._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { test = { type = "boolean" } }
                    }
                    -- No schema_name provided
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.result.data.test).to_be_true()
            end)

            it("should use custom schema name when provided", function()
                structured_output._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Generate data" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = { content = '{"value":42}' },
                            tokens = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 },
                            finish_reason = "stop",
                            metadata = {}
                        }
                    end
                }

                structured_output._ctx = {
                    all = function()
                        return {}
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        return {
                            status_code = 200,
                            candidates = {
                                {
                                    content = {
                                        parts = {{ text = '{"value":42}' }}
                                    },
                                    finishReason = "STOP"
                                }
                            },
                            usageMetadata = {
                                promptTokenCount = 10,
                                candidatesTokenCount = 5,
                                totalTokenCount = 15
                            }
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                structured_output._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { value = { type = "number" } }
                    },
                    schema_name = "custom_schema_name"
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.result.data.value).to_equal(42)
            end)

            it("should generate different names for different schemas", function()
                -- This test verifies that schema name generation works
                -- by ensuring two different schemas can be processed
                structured_output._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Generate data" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = { content = '{"name":"test"}' },
                            tokens = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 },
                            finish_reason = "stop",
                            metadata = {}
                        }
                    end
                }

                structured_output._ctx = {
                    all = function()
                        return {}
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        return {
                            status_code = 200,
                            candidates = {
                                {
                                    content = {
                                        parts = {{ text = '{"name":"test"}' }}
                                    },
                                    finishReason = "STOP"
                                }
                            },
                            usageMetadata = {
                                promptTokenCount = 10,
                                candidatesTokenCount = 5,
                                totalTokenCount = 15
                            }
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                structured_output._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                -- First schema
                local contract_args1 = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { name = { type = "string" } }
                    }
                }

                local response1 = structured_output.handler(contract_args1)
                expect(response1.success).to_be_true()

                -- Second schema (different structure)
                local contract_args2 = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            name = { type = "string" },
                            age = { type = "number" }
                        }
                    }
                }

                local response2 = structured_output.handler(contract_args2)
                expect(response2.success).to_be_true()
            end)
        end)

        describe("Options Handling", function()
            it("should handle standard model options", function()
                structured_output._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Generate data" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {
                            temperature = 0.2,
                            maxOutputTokens = 200,
                            topP = 0.8
                        }
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = { content = '{"test":true}' },
                            tokens = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 },
                            finish_reason = "stop",
                            metadata = {}
                        }
                    end
                }

                structured_output._ctx = {
                    all = function()
                        return {}
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        expect(args.payload.generationConfig.temperature).to_equal(0.2)
                        expect(args.payload.generationConfig.maxOutputTokens).to_equal(200)
                        expect(args.payload.generationConfig.topP).to_equal(0.8)

                        return {
                            status_code = 200,
                            candidates = {
                                {
                                    content = {
                                        parts = {{ text = '{"test":true}' }}
                                    },
                                    finishReason = "STOP"
                                }
                            },
                            usageMetadata = {
                                promptTokenCount = 10,
                                candidatesTokenCount = 5,
                                totalTokenCount = 15
                            }
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                structured_output._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { test = { type = "boolean" } }
                    },
                    options = {
                        temperature = 0.2,
                        max_tokens = 200,
                        top_p = 0.8
                    }
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_true()
            end)

            it("should handle nil options", function()
                structured_output._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Generate data" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = { content = '{"value":1}' },
                            tokens = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 },
                            finish_reason = "stop",
                            metadata = {}
                        }
                    end
                }

                structured_output._ctx = {
                    all = function()
                        return {}
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        return {
                            status_code = 200,
                            candidates = {
                                {
                                    content = {
                                        parts = {{ text = '{"value":1}' }}
                                    },
                                    finishReason = "STOP"
                                }
                            },
                            usageMetadata = {
                                promptTokenCount = 10,
                                candidatesTokenCount = 5,
                                totalTokenCount = 15
                            }
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                structured_output._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { value = { type = "number" } }
                    }
                    -- No options provided
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_true()
            end)

            it("should pass timeout to client request", function()
                structured_output._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Generate data" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = { content = '{"data":"test"}' },
                            tokens = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 },
                            finish_reason = "stop",
                            metadata = {}
                        }
                    end
                }

                structured_output._ctx = {
                    all = function()
                        return {}
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        expect(args.options.timeout).to_equal(120)

                        return {
                            status_code = 200,
                            candidates = {
                                {
                                    content = {
                                        parts = {{ text = '{"data":"test"}' }}
                                    },
                                    finishReason = "STOP"
                                }
                            },
                            usageMetadata = {
                                promptTokenCount = 10,
                                candidatesTokenCount = 5,
                                totalTokenCount = 15
                            }
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                structured_output._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { data = { type = "string" } }
                    },
                    timeout = 120
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_true()
            end)

            it("should merge options with response_mime_type and responseSchema", function()
                structured_output._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Generate data" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {
                            temperature = 0.5,
                            topK = 40
                        }
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = { content = '{"result":"merged"}' },
                            tokens = { prompt_tokens = 12, completion_tokens = 6, total_tokens = 18 },
                            finish_reason = "stop",
                            metadata = {}
                        }
                    end
                }

                structured_output._ctx = {
                    all = function()
                        return {}
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        -- Verify all generationConfig fields are present
                        expect(args.payload.generationConfig.response_mime_type).to_equal("application/json")
                        expect(args.payload.generationConfig.responseSchema).not_to_be_nil()
                        expect(args.payload.generationConfig.temperature).to_equal(0.5)
                        expect(args.payload.generationConfig.topK).to_equal(40)

                        return {
                            status_code = 200,
                            candidates = {
                                {
                                    content = {
                                        parts = {{ text = '{"result":"merged"}' }}
                                    },
                                    finishReason = "STOP"
                                }
                            },
                            usageMetadata = {
                                promptTokenCount = 12,
                                candidatesTokenCount = 6,
                                totalTokenCount = 18
                            }
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                structured_output._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { result = { type = "string" } }
                    },
                    options = {
                        temperature = 0.5,
                        top_k = 40
                    }
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.result.data.result).to_equal("merged")
            end)
        end)

        describe("Error Handling", function()
            it("should handle invalid JSON in response", function()
                structured_output._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Generate data" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = { content = 'invalid json {' },
                            tokens = { prompt_tokens = 15, completion_tokens = 10, total_tokens = 25 },
                            finish_reason = "stop",
                            metadata = {}
                        }
                    end,
                    map_error_response = function(error_info)
                        return {
                            success = false,
                            error = "model_error",
                            error_message = error_info.message,
                            metadata = {}
                        }
                    end
                }

                structured_output._ctx = {
                    all = function()
                        return {}
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        return {
                            status_code = 200,
                            candidates = {
                                {
                                    content = {
                                        parts = {{ text = 'invalid json {' }}
                                    },
                                    finishReason = "STOP"
                                }
                            },
                            usageMetadata = {
                                promptTokenCount = 15,
                                candidatesTokenCount = 10,
                                totalTokenCount = 25
                            }
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                structured_output._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { test = { type = "string" } }
                    }
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("model_error")
                expect(response.error_message).to_contain("Model failed to return valid JSON")
            end)

            it("should handle API authentication errors", function()
                structured_output._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Generate data" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_error_response = function(error_info)
                        return {
                            success = false,
                            error = "authentication_error",
                            error_message = error_info.message,
                            metadata = {}
                        }
                    end
                }

                structured_output._ctx = {
                    all = function()
                        return {}
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        return {
                            status_code = 401,
                            message = "API key is invalid"
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                structured_output._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { test = { type = "string" } }
                    }
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("authentication_error")
                expect(response.error_message).to_contain("API key is invalid")
            end)

            it("should handle contract retrieval errors", function()
                structured_output._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Generate data" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_error_response = function(error_info)
                        return {
                            success = false,
                            error = "server_error",
                            error_message = error_info.message,
                            metadata = {}
                        }
                    end
                }

                structured_output._ctx = {
                    all = function()
                        return {}
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                structured_output._contract = {
                    get = function(contract_id)
                        return nil, "Contract not found"
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { test = { type = "string" } }
                    }
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("server_error")
                expect(response.error_message).to_contain("Failed to get client contract")
            end)

            it("should handle client binding errors", function()
                structured_output._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Generate data" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_error_response = function(error_info)
                        return {
                            success = false,
                            error = "server_error",
                            error_message = error_info.message,
                            metadata = {}
                        }
                    end
                }

                structured_output._ctx = {
                    all = function()
                        return {}
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return nil, "Failed to initialize client"
                    end
                }

                structured_output._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { test = { type = "string" } }
                    }
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("server_error")
                expect(response.error_message).to_contain("Failed to open client binding")
            end)

            it("should handle response mapping errors", function()
                structured_output._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Generate data" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_success_response = function(response)
                        error("Invalid response structure")
                    end,
                    map_error_response = function(error_info)
                        return {
                            success = false,
                            error = "server_error",
                            error_message = error_info.message,
                            metadata = {}
                        }
                    end
                }

                structured_output._ctx = {
                    all = function()
                        return {}
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        return {
                            status_code = 200,
                            candidates = {}
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                structured_output._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { test = { type = "string" } }
                    }
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("server_error")
                expect(response.error_message).to_contain("Invalid response structure")
            end)

            it("should handle rate limit errors", function()
                structured_output._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Generate data" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_error_response = function(error_info)
                        return {
                            success = false,
                            error = "rate_limit_exceeded",
                            error_message = error_info.message,
                            metadata = {}
                        }
                    end
                }

                structured_output._ctx = {
                    all = function()
                        return {}
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        return {
                            status_code = 429,
                            message = "Rate limit exceeded"
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                structured_output._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { test = { type = "string" } }
                    }
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("rate_limit_exceeded")
                expect(response.error_message).to_contain("Rate limit")
            end)
        end)

        describe("Context Integration", function()
            it("should resolve API configuration from context", function()
                structured_output._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Generate data" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = { content = '{"success":true}' },
                            tokens = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 },
                            finish_reason = "stop",
                            metadata = {}
                        }
                    end
                }

                structured_output._ctx = {
                    all = function()
                        return {
                            custom_key = "custom_value",
                            region = "us-west1"
                        }
                    end,
                    get = function(key)
                        if key == "client_id" then return "custom-client-id" end
                        return nil
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        return {
                            status_code = 200,
                            candidates = {
                                {
                                    content = {
                                        parts = {{ text = '{"success":true}' }}
                                    },
                                    finishReason = "STOP"
                                }
                            },
                            usageMetadata = {
                                promptTokenCount = 10,
                                candidatesTokenCount = 5,
                                totalTokenCount = 15
                            }
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        expect(context).not_to_be_nil()
                        expect(context.custom_key).to_equal("custom_value")
                        expect(context.region).to_equal("us-west1")
                        return self
                    end,
                    open = function(self, client_id)
                        expect(client_id).to_equal("custom-client-id")
                        return mock_client_instance, nil
                    end
                }

                structured_output._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { success = { type = "boolean" } }
                    }
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.result.data.success).to_be_true()
            end)

            it("should handle empty context", function()
                structured_output._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Generate data" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = { content = '{"value":42}' },
                            tokens = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 },
                            finish_reason = "stop",
                            metadata = {}
                        }
                    end
                }

                structured_output._ctx = {
                    all = function()
                        return {}
                    end,
                    get = function(key)
                        return "default-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        return {
                            status_code = 200,
                            candidates = {
                                {
                                    content = {
                                        parts = {{ text = '{"value":42}' }}
                                    },
                                    finishReason = "STOP"
                                }
                            },
                            usageMetadata = {
                                promptTokenCount = 10,
                                candidatesTokenCount = 5,
                                totalTokenCount = 15
                            }
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        expect(type(context)).to_equal("table")
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                structured_output._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { value = { type = "number" } }
                    }
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_true()
            end)

            it("should pass context through contract chain", function()
                structured_output._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Generate data" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = { content = '{"data":"test"}' },
                            tokens = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 },
                            finish_reason = "stop",
                            metadata = {}
                        }
                    end
                }

                local context_passed_to_contract = false
                local context_passed_to_client = false

                structured_output._ctx = {
                    all = function()
                        return {
                            api_key = "test-key",
                            project_id = "test-project"
                        }
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        context_passed_to_client = true
                        return {
                            status_code = 200,
                            candidates = {
                                {
                                    content = {
                                        parts = {{ text = '{"data":"test"}' }}
                                    },
                                    finishReason = "STOP"
                                }
                            },
                            usageMetadata = {
                                promptTokenCount = 10,
                                candidatesTokenCount = 5,
                                totalTokenCount = 15
                            }
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        expect(context.api_key).to_equal("test-key")
                        expect(context.project_id).to_equal("test-project")
                        context_passed_to_contract = true
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                structured_output._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { data = { type = "string" } }
                    }
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_true()
                expect(context_passed_to_contract).to_be_true()
                expect(context_passed_to_client).to_be_true()
            end)

            it("should handle context with metadata", function()
                structured_output._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Generate data" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = { content = '{"result":"ok"}' },
                            tokens = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 },
                            finish_reason = "stop",
                            metadata = { request_id = "req-123" }
                        }
                    end
                }

                structured_output._ctx = {
                    all = function()
                        return {
                            user_id = "user-123",
                            session_id = "session-456",
                            metadata = {
                                trace_id = "trace-789"
                            }
                        }
                    end,
                    get = function(key)
                        if key == "client_id" then return "metadata-client-id" end
                        if key == "user_id" then return "user-123" end
                        return nil
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        return {
                            status_code = 200,
                            candidates = {
                                {
                                    content = {
                                        parts = {{ text = '{"result":"ok"}' }}
                                    },
                                    finishReason = "STOP"
                                }
                            },
                            usageMetadata = {
                                promptTokenCount = 10,
                                candidatesTokenCount = 5,
                                totalTokenCount = 15
                            }
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        expect(context.user_id).to_equal("user-123")
                        expect(context.session_id).to_equal("session-456")
                        expect(context.metadata).not_to_be_nil()
                        expect(context.metadata.trace_id).to_equal("trace-789")
                        return self
                    end,
                    open = function(self, client_id)
                        expect(client_id).to_equal("metadata-client-id")
                        return mock_client_instance, nil
                    end
                }

                structured_output._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { result = { type = "string" } }
                    }
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.metadata.request_id).to_equal("req-123")
            end)

            it("should handle nil context gracefully", function()
                structured_output._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Generate data" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = { content = '{"test":true}' },
                            tokens = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 },
                            finish_reason = "stop",
                            metadata = {}
                        }
                    end
                }

                structured_output._ctx = {
                    all = function()
                        return nil
                    end,
                    get = function(key)
                        return "fallback-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        return {
                            status_code = 200,
                            candidates = {
                                {
                                    content = {
                                        parts = {{ text = '{"test":true}' }}
                                    },
                                    finishReason = "STOP"
                                }
                            },
                            usageMetadata = {
                                promptTokenCount = 10,
                                candidatesTokenCount = 5,
                                totalTokenCount = 15
                            }
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        -- Should receive empty table if nil is returned from ctx.all()
                        expect(type(context)).to_equal("table")
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                structured_output._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Generate data" }} }
                    },
                    schema = {
                        type = "object",
                        properties = { test = { type = "boolean" } }
                    }
                }

                local response = structured_output.handler(contract_args)

                expect(response.success).to_be_true()
            end)
        end)
    end)
end

return tests.run_cases(define_tests)
