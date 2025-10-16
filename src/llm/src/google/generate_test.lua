local generate = require("google_generate")
local tests = require("test")

local function define_tests()
    describe("Google Generate Handler", function()

        after_each(function()
            generate._contract = nil
            generate._mapper = nil
            generate._ctx = nil
            generate._output = nil
        end)

        describe("Contract Argument Validation", function()
            it("should require model parameter", function()
                generate._mapper = {
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
                        { role = "user", content = {{ type = "text", text = "Hello" }} }
                    }
                }

                local response = generate.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_equal("Model is required")
            end)

            it("should require messages parameter", function()
                generate._mapper = {
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
                    model = "gemini-pro"
                }

                local response = generate.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_equal("Messages are required")
            end)

            it("should reject empty messages array", function()
                generate._mapper = {
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
                    model = "gemini-pro",
                    messages = {}
                }

                local response = generate.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_equal("Messages are required")
            end)
        end)

        describe("Text Generation", function()
            it("should handle successful text generation", function()
                generate._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Hello" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = {
                                content = "Hello! How can I help you today?"
                            },
                            tokens = {
                                prompt_tokens = 10,
                                completion_tokens = 8,
                                total_tokens = 18
                            },
                            finish_reason = "stop",
                            metadata = {}
                        }
                    end
                }

                generate._ctx = {
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
                        expect(args.payload.contents).not_to_be_nil()

                        return {
                            status_code = 200,
                            candidates = {
                                {
                                    content = {
                                        parts = {{ text = "Hello! How can I help you today?" }}
                                    },
                                    finishReason = "STOP"
                                }
                            },
                            usageMetadata = {
                                promptTokenCount = 10,
                                candidatesTokenCount = 8,
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

                generate._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Hello" }} }
                    }
                }

                local response = generate.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.result.content).to_equal("Hello! How can I help you today?")
                expect(response.tokens.prompt_tokens).to_equal(10)
                expect(response.tokens.completion_tokens).to_equal(8)
                expect(response.finish_reason).to_equal("stop")
            end)

            it("should handle options mapping", function()
                generate._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Test" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {
                            temperature = 0.7,
                            maxOutputTokens = 100,
                            topP = 0.9,
                            topK = 40
                        }
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = { content = "Response" },
                            tokens = { prompt_tokens = 5, completion_tokens = 5, total_tokens = 10 },
                            finish_reason = "stop",
                            metadata = {}
                        }
                    end
                }

                generate._ctx = {
                    all = function()
                        return {}
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        expect(args.payload.generationConfig).not_to_be_nil()
                        expect(args.payload.generationConfig.temperature).to_equal(0.7)
                        expect(args.payload.generationConfig.maxOutputTokens).to_equal(100)
                        expect(args.payload.generationConfig.topP).to_equal(0.9)
                        expect(args.payload.generationConfig.topK).to_equal(40)

                        return {
                            status_code = 200,
                            candidates = {{ content = { parts = {{ text = "Response" }} }, finishReason = "STOP" }},
                            usageMetadata = { promptTokenCount = 5, candidatesTokenCount = 5, totalTokenCount = 10 }
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

                generate._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Test" }} }
                    },
                    options = {
                        temperature = 0.7,
                        max_tokens = 100,
                        top_p = 0.9,
                        top_k = 40
                    }
                }

                local response = generate.handler(contract_args)

                expect(response.success).to_be_true()
            end)

            it("should handle system instructions", function()
                generate._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Hello" }} }
                        }, {
                            { text = "You are a helpful assistant" }
                        }
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = { content = "Response with system instruction" },
                            tokens = { prompt_tokens = 15, completion_tokens = 5, total_tokens = 20 },
                            finish_reason = "stop",
                            metadata = {}
                        }
                    end
                }

                generate._ctx = {
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
                        expect(args.payload.systemInstruction.parts).not_to_be_nil()
                        expect(#args.payload.systemInstruction.parts).to_equal(1)
                        expect(args.payload.systemInstruction.parts[1].text).to_equal("You are a helpful assistant")

                        return {
                            status_code = 200,
                            candidates = {{ content = { parts = {{ text = "Response with system instruction" }} }, finishReason = "STOP" }},
                            usageMetadata = { promptTokenCount = 15, candidatesTokenCount = 5, totalTokenCount = 20 }
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

                generate._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "system", content = {{ type = "text", text = "You are a helpful assistant" }} },
                        { role = "user", content = {{ type = "text", text = "Hello" }} }
                    }
                }

                local response = generate.handler(contract_args)

                expect(response.success).to_be_true()
            end)

            it("should not include generationConfig when empty", function()
                generate._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Test" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = { content = "Response" },
                            tokens = { prompt_tokens = 5, completion_tokens = 5, total_tokens = 10 },
                            finish_reason = "stop",
                            metadata = {}
                        }
                    end
                }

                generate._ctx = {
                    all = function()
                        return {}
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        expect(args.payload.generationConfig).to_be_nil()

                        return {
                            status_code = 200,
                            candidates = {{ content = { parts = {{ text = "Response" }} }, finishReason = "STOP" }},
                            usageMetadata = { promptTokenCount = 5, candidatesTokenCount = 5, totalTokenCount = 10 }
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

                generate._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Test" }} }
                    }
                }

                generate.handler(contract_args)
            end)
        end)

        describe("Tool Calling", function()
            it("should handle tools in request", function()
                generate._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Calculate 2+2" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_tools = function(tools)
                        return {
                            {
                                name = "calculate",
                                description = "Perform calculations",
                                parameters = {
                                    type = "object",
                                    properties = {
                                        expression = { type = "string" }
                                    },
                                    required = { "expression" }
                                }
                            }
                        }
                    end,
                    map_tool_config = function(tool_choice, tools)
                        return { mode = "AUTO" }, nil
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = {
                                content = "I'll calculate that for you",
                                tool_calls = {
                                    {
                                        name = "calculate",
                                        arguments = { expression = "2+2" },
                                        id = "call_123"
                                    }
                                }
                            },
                            tokens = { prompt_tokens = 20, completion_tokens = 10, total_tokens = 30 },
                            finish_reason = "tool_call",
                            metadata = {}
                        }
                    end
                }

                generate._ctx = {
                    all = function()
                        return {}
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        expect(args.payload.tools).not_to_be_nil()
                        expect(args.payload.tools.functionDeclarations).not_to_be_nil()
                        expect(#args.payload.tools.functionDeclarations).to_equal(1)
                        expect(args.payload.tools.functionDeclarations[1].name).to_equal("calculate")
                        expect(args.payload.toolConfig).not_to_be_nil()
                        expect(args.payload.toolConfig.functionCallingConfig).not_to_be_nil()

                        return {
                            status_code = 200,
                            candidates = {
                                {
                                    content = {
                                        parts = {
                                            { text = "I'll calculate that for you" },
                                            {
                                                functionCall = {
                                                    name = "calculate",
                                                    args = { expression = "2+2" }
                                                }
                                            }
                                        }
                                    },
                                    finishReason = "STOP"
                                }
                            },
                            usageMetadata = { promptTokenCount = 20, candidatesTokenCount = 10, totalTokenCount = 30 }
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

                generate._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Calculate 2+2" }} }
                    },
                    tools = {
                        {
                            name = "calculate",
                            description = "Perform calculations",
                            schema = {
                                type = "object",
                                properties = {
                                    expression = { type = "string" }
                                },
                                required = { "expression" }
                            }
                        }
                    }
                }

                local response = generate.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.result.tool_calls).not_to_be_nil()
                expect(#response.result.tool_calls).to_equal(1)
                expect(response.result.tool_calls[1].name).to_equal("calculate")
                expect(response.finish_reason).to_equal("tool_call")
            end)

            it("should handle tool_choice parameter", function()
                generate._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Test" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_tools = function(tools)
                        return {
                            { name = "calculate", description = "Calculate", parameters = { type = "object" } }
                        }
                    end,
                    map_tool_config = function(tool_choice, tools)
                        expect(tool_choice).to_equal("calculate")
                        return {
                            mode = "ANY",
                            allowedFunctionNames = { "calculate" }
                        }, nil
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = {
                                tool_calls = {
                                    { name = "calculate", arguments = {}, id = "call_forced" }
                                }
                            },
                            tokens = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 },
                            finish_reason = "tool_call",
                            metadata = {}
                        }
                    end
                }

                generate._ctx = {
                    all = function()
                        return {}
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        expect(args.payload.toolConfig.functionCallingConfig.mode).to_equal("ANY")
                        expect(args.payload.toolConfig.functionCallingConfig.allowedFunctionNames[1]).to_equal("calculate")

                        return {
                            status_code = 200,
                            candidates = {
                                {
                                    content = {
                                        parts = {
                                            {
                                                functionCall = {
                                                    name = "calculate",
                                                    args = {}
                                                }
                                            }
                                        }
                                    },
                                    finishReason = "STOP"
                                }
                            },
                            usageMetadata = { promptTokenCount = 10, candidatesTokenCount = 5, totalTokenCount = 15 }
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

                generate._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Test" }} }
                    },
                    tools = {
                        {
                            name = "calculate",
                            description = "Calculate",
                            schema = { type = "object" }
                        }
                    },
                    tool_choice = "calculate"
                }

                local response = generate.handler(contract_args)

                expect(response.success).to_be_true()
            end)

            it("should return error for invalid tool_choice", function()
                generate._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Test" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_tools = function(tools)
                        return {
                            { name = "calculate", description = "Calculate", parameters = { type = "object" } }
                        }
                    end,
                    map_tool_config = function(tool_choice, tools)
                        return nil, "Tool 'nonexistent' not found in tools list"
                    end,
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
                        { role = "user", content = {{ type = "text", text = "Test" }} }
                    },
                    tools = {
                        {
                            name = "calculate",
                            description = "Calculate",
                            schema = { type = "object" }
                        }
                    },
                    tool_choice = "nonexistent"
                }

                local response = generate.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_contain("not found in tools list")
            end)
        end)

        describe("Timeout Handling", function()
            it("should pass timeout to client request", function()
                generate._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Test" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = { content = "Response" },
                            tokens = { prompt_tokens = 5, completion_tokens = 5, total_tokens = 10 },
                            finish_reason = "stop",
                            metadata = {}
                        }
                    end
                }

                generate._ctx = {
                    all = function()
                        return {}
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        expect(args.options.timeout).to_equal(180)

                        return {
                            status_code = 200,
                            candidates = {{ content = { parts = {{ text = "Response" }} }, finishReason = "STOP" }},
                            usageMetadata = { promptTokenCount = 5, candidatesTokenCount = 5, totalTokenCount = 10 }
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

                generate._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Test" }} }
                    },
                    timeout = 180
                }

                generate.handler(contract_args)
            end)
        end)

        describe("Error Handling", function()
            it("should handle contract retrieval errors", function()
                generate._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Test" }} }
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

                generate._ctx = {
                    all = function()
                        return {}
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                generate._contract = {
                    get = function(contract_id)
                        return nil, "Contract not found"
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Test" }} }
                    }
                }

                local response = generate.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("server_error")
                expect(response.error_message).to_contain("Failed to get client contract")
            end)

            it("should handle client binding errors", function()
                generate._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Test" }} }
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

                generate._ctx = {
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

                generate._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Test" }} }
                    }
                }

                local response = generate.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("server_error")
                expect(response.error_message).to_contain("Failed to open client binding")
            end)

            it("should handle API error responses", function()
                generate._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Test" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_error_response = function(error_info)
                        return {
                            success = false,
                            error = "authentication_error",
                            error_message = error_info.message or "API key is invalid",
                            metadata = {}
                        }
                    end
                }

                generate._ctx = {
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

                generate._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Test" }} }
                    }
                }

                local response = generate.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("authentication_error")
                expect(response.error_message).to_contain("API key is invalid")
            end)

            it("should handle response mapping errors", function()
                generate._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Test" }} }
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

                generate._ctx = {
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

                generate._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Test" }} }
                    }
                }

                local response = generate.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("server_error")
                expect(response.error_message).to_contain("Invalid response structure")
            end)
        end)

        describe("Context Integration", function()
            it("should pass context to client contract", function()
                local context_passed = false

                generate._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Test" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = { content = "Response" },
                            tokens = { prompt_tokens = 5, completion_tokens = 5, total_tokens = 10 },
                            finish_reason = "stop",
                            metadata = {}
                        }
                    end
                }

                generate._ctx = {
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
                        return {
                            status_code = 200,
                            candidates = {{ content = { parts = {{ text = "Response" }} }, finishReason = "STOP" }},
                            usageMetadata = { promptTokenCount = 5, candidatesTokenCount = 5, totalTokenCount = 10 }
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        expect(context.api_key).to_equal("test-key")
                        expect(context.project_id).to_equal("test-project")
                        context_passed = true
                        return self
                    end,
                    open = function(self, client_id)
                        expect(client_id).to_equal("test-client-id")
                        return mock_client_instance, nil
                    end
                }

                generate._contract = {
                    get = function(contract_id)
                        expect(contract_id).to_equal(require("google_config").CLIENT_CONTRACT_ID)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Test" }} }
                    }
                }

                generate.handler(contract_args)

                expect(context_passed).to_be_true()
            end)

            it("should handle nil context gracefully", function()
                generate._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Test" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = { content = "Response" },
                            tokens = { prompt_tokens = 5, completion_tokens = 5, total_tokens = 10 },
                            finish_reason = "stop",
                            metadata = {}
                        }
                    end
                }

                generate._ctx = {
                    all = function()
                        return nil
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        return {
                            status_code = 200,
                            candidates = {{ content = { parts = {{ text = "Response" }} }, finishReason = "STOP" }},
                            usageMetadata = { promptTokenCount = 5, candidatesTokenCount = 5, totalTokenCount = 10 }
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        expect(context).not_to_be_nil()
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                generate._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Test" }} }
                    }
                }

                local response = generate.handler(contract_args)

                expect(response.success).to_be_true()
            end)
        end)

        describe("Edge Cases", function()
            it("should handle nil options in generationConfig", function()
                generate._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Test" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {
                            temperature = 0.5,
                            maxOutputTokens = nil,
                            topP = 0.8,
                            topK = nil
                        }
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = { content = "Response" },
                            tokens = { prompt_tokens = 5, completion_tokens = 5, total_tokens = 10 },
                            finish_reason = "stop",
                            metadata = {}
                        }
                    end
                }

                generate._ctx = {
                    all = function()
                        return {}
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        expect(args.payload.generationConfig.temperature).to_equal(0.5)
                        expect(args.payload.generationConfig.maxOutputTokens).to_be_nil()
                        expect(args.payload.generationConfig.topP).to_equal(0.8)
                        expect(args.payload.generationConfig.topK).to_be_nil()

                        return {
                            status_code = 200,
                            candidates = {{ content = { parts = {{ text = "Response" }} }, finishReason = "STOP" }},
                            usageMetadata = { promptTokenCount = 5, candidatesTokenCount = 5, totalTokenCount = 10 }
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

                generate._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Test" }} }
                    },
                    options = {
                        temperature = 0.5,
                        top_p = 0.8
                    }
                }

                generate.handler(contract_args)
            end)

            it("should handle empty system instructions", function()
                generate._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Test" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_success_response = function(response)
                        return {
                            success = true,
                            result = { content = "Response" },
                            tokens = { prompt_tokens = 5, completion_tokens = 5, total_tokens = 10 },
                            finish_reason = "stop",
                            metadata = {}
                        }
                    end
                }

                generate._ctx = {
                    all = function()
                        return {}
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        expect(args.payload.systemInstruction).to_be_nil()

                        return {
                            status_code = 200,
                            candidates = {{ content = { parts = {{ text = "Response" }} }, finishReason = "STOP" }},
                            usageMetadata = { promptTokenCount = 5, candidatesTokenCount = 5, totalTokenCount = 10 }
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

                generate._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Test" }} }
                    }
                }

                generate.handler(contract_args)
            end)

            it("should handle response with multiple status code ranges", function()
                generate._mapper = {
                    map_messages = function(messages, options)
                        return {
                            { role = "user", parts = {{ text = "Test" }} }
                        }, {}
                    end,
                    map_options = function(options)
                        return {}
                    end,
                    map_error_response = function(error_info)
                        return {
                            success = false,
                            error = "server_error",
                            error_message = "Request failed",
                            metadata = {}
                        }
                    end
                }

                generate._ctx = {
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
                            status_code = 503,
                            message = "Service unavailable"
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

                generate._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-1.5-pro",
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Test" }} }
                    }
                }

                local response = generate.handler(contract_args)

                expect(response.success).to_be_false()
            end)
        end)
    end)
end

return tests.run_cases(define_tests)
