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
                    classify_error = function(http_err)
                        return "invalid_request", http_err and http_err.message or "Error", {}
                    end
                }

                local contract_args = {
                    messages = {
                        { role = "user", content = {{ type = "text", text = "Hello" }} }
                    }
                }

                local response, err = generate.handler(contract_args)

                tests.is_nil(response)
                tests.not_nil(err)
                tests.eq(err:kind(), "Invalid")
                tests.eq(err:message(), "Model is required")
            end)

            it("should require messages parameter", function()
                generate._mapper = {
                    classify_error = function(http_err)
                        return "invalid_request", http_err and http_err.message or "Error", {}
                    end
                }

                local contract_args = {
                    model = "gemini-pro"
                }

                local response, err = generate.handler(contract_args)

                tests.is_nil(response)
                tests.not_nil(err)
                tests.eq(err:kind(), "Invalid")
                tests.eq(err:message(), "Messages are required")
            end)

            it("should reject empty messages array", function()
                generate._mapper = {
                    classify_error = function(http_err)
                        return "invalid_request", http_err and http_err.message or "Error", {}
                    end
                }

                local contract_args = {
                    model = "gemini-pro",
                    messages = {}
                }

                local response, err = generate.handler(contract_args)

                tests.is_nil(response)
                tests.not_nil(err)
                tests.eq(err:kind(), "Invalid")
                tests.eq(err:message(), "Messages are required")
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
                        tests.eq(args.endpoint_path, "generateContent")
                        tests.eq(args.model, "gemini-1.5-pro")
                        tests.not_nil(args.payload.contents)

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

                tests.is_true(response.success)
                assert(response.success)
                tests.eq(response.result.content, "Hello! How can I help you today?")
                tests.eq(response.tokens.prompt_tokens, 10)
                tests.eq(response.tokens.completion_tokens, 8)
                tests.eq(response.finish_reason, "stop")
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
                        tests.not_nil(args.payload.generationConfig)
                        tests.eq(args.payload.generationConfig.temperature, 0.7)
                        tests.eq(args.payload.generationConfig.maxOutputTokens, 100)
                        tests.eq(args.payload.generationConfig.topP, 0.9)
                        tests.eq(args.payload.generationConfig.topK, 40)

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

                tests.is_true(response.success)
                assert(response.success)
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
                        tests.not_nil(args.payload.systemInstruction)
                        tests.not_nil(args.payload.systemInstruction.parts)
                        tests.eq(#args.payload.systemInstruction.parts, 1)
                        tests.eq(args.payload.systemInstruction.parts[1].text, "You are a helpful assistant")

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

                tests.is_true(response.success)
                assert(response.success)
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
                        tests.is_nil(args.payload.generationConfig)

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
                        tests.not_nil(args.payload.tools)
                        tests.not_nil(args.payload.tools.functionDeclarations)
                        tests.eq(#args.payload.tools.functionDeclarations, 1)
                        tests.eq(args.payload.tools.functionDeclarations[1].name, "calculate")
                        tests.not_nil(args.payload.toolConfig)
                        tests.not_nil(args.payload.toolConfig.functionCallingConfig)

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

                tests.is_true(response.success)
                assert(response.success)
                tests.not_nil(response.result.tool_calls)
                assert(response.result.tool_calls and response.result.tool_calls[1])
                tests.eq(#response.result.tool_calls, 1)
                tests.eq(response.result.tool_calls[1].name, "calculate")
                tests.eq(response.finish_reason, "tool_call")
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
                        tests.eq(tool_choice, "calculate")
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
                        tests.eq(args.payload.toolConfig.functionCallingConfig.mode, "ANY")
                        tests.eq(args.payload.toolConfig.functionCallingConfig.allowedFunctionNames[1], "calculate")

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

                tests.is_true(response.success)
                assert(response.success)
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
                    classify_error = function(http_err)
                        return "invalid_request", http_err and http_err.message or "Error", {}
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

                local response, err = generate.handler(contract_args)

                tests.is_nil(response)
                tests.not_nil(err)
                tests.eq(err:kind(), "Invalid")
                tests.contains(err:message(), "not found in tools list")
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
                        tests.eq(args.options.timeout, 180)

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

            it("should forward retry to client request", function()
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

                local captured_options = nil
                local mock_client_instance = {
                    request = function(self, args)
                        captured_options = args.options

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
                    retry = { attempts = 2, backoff_ms = 0 }
                }

                generate.handler(contract_args)

                local options = captured_options :: any
                tests.eq(options.retry.attempts, 2)
                tests.eq(options.retry.backoff_ms, 0)
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
                    classify_error = function(http_err)
                        return "server_error", http_err and http_err.message or "Error", {}
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

                local response, err = generate.handler(contract_args)

                tests.is_nil(response)
                tests.not_nil(err)
                tests.eq(err:kind(), "Unavailable")
                tests.contains(err:message(), "Failed to get client contract")
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
                    classify_error = function(http_err)
                        return "server_error", http_err and http_err.message or "Error", {}
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

                local response, err = generate.handler(contract_args)

                tests.is_nil(response)
                tests.not_nil(err)
                tests.eq(err:kind(), "Unavailable")
                tests.contains(err:message(), "Failed to open client binding")
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
                    classify_error = function(http_err)
                        return "authentication_error", http_err and http_err.message or "API key is invalid", {}
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

                local response, err = generate.handler(contract_args)

                tests.is_nil(response)
                tests.not_nil(err)
                tests.eq(err:kind(), "PermissionDenied")
                tests.contains(err:message(), "API key is invalid")
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
                    classify_error = function(http_err)
                        return "server_error", http_err and http_err.message or "Failed", {}
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

                local response, err = generate.handler(contract_args)

                tests.is_nil(response)
                tests.not_nil(err)
                tests.eq(err:kind(), "Unavailable")
                tests.contains(err:message(), "Invalid response structure")
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
                        tests.eq(context.api_key, "test-key")
                        tests.eq(context.project_id, "test-project")
                        context_passed = true
                        return self
                    end,
                    open = function(self, client_id)
                        tests.eq(client_id, "test-client-id")
                        return mock_client_instance, nil
                    end
                }

                generate._contract = {
                    get = function(contract_id)
                        tests.eq(contract_id, require("google_config").CLIENT_CONTRACT_ID)
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

                tests.is_true(context_passed)
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
                        tests.not_nil(context)
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

                tests.is_true(response.success)
                assert(response.success)
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
                        tests.eq(args.payload.generationConfig.temperature, 0.5)
                        tests.is_nil(args.payload.generationConfig.maxOutputTokens)
                        tests.eq(args.payload.generationConfig.topP, 0.8)
                        tests.is_nil(args.payload.generationConfig.topK)

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
                        tests.is_nil(args.payload.systemInstruction)

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

                local response, err = generate.handler(contract_args)

                tests.is_nil(response)
                tests.not_nil(err)
            end)
        end)

        describe("Stream fallback signals", function()
            local function answer_with(response_table)
                generate._mapper = {
                    map_messages = function()
                        return { { role = "user", parts = { { text = "Hi" } } } }, {}
                    end,
                    map_options = function()
                        return {}
                    end,
                    classify_error = function(http_err)
                        local kind = http_err.status_code == 429 and "rate_limit_exceeded" or "server_error"
                        return kind, http_err.message, { status_code = http_err.status_code }
                    end
                }
                generate._ctx = {
                    all = function() return {} end,
                    get = function() return "test-client-id" end
                }
                local client_instance = {
                    request = function()
                        return response_table
                    end
                }
                local client_contract = {
                    with_context = function(self) return self end,
                    open = function() return client_instance, nil end
                }
                generate._contract = {
                    get = function() return client_contract, nil end
                }
            end

            local function call(streaming: boolean)
                local args: { [string]: any } = {
                    model = "gemini-2.5-pro",
                    messages = { { role = "user", content = { { type = "text", text = "Hi" } } } }
                }
                if streaming then
                    args.stream = { reply_to = "test-process", topic = "test_stream" }
                end
                return generate.handler(args)
            end

            it("should mark a request error on a streaming call as not started", function()
                answer_with({ status_code = 429, message = "quota", stream_started = false })
                local response, err = call(true)
                tests.is_nil(response)
                local details = (err :: any):details()
                tests.is_false(details.stream_started)
                tests.eq(details.error_type, "rate_limit_exceeded")
                tests.eq(details.status_code, 429)
                tests.is_nil(details.deferred_error_type)
            end)

            it("should leave stream_started unset when the client reports no stream flag", function()
                answer_with({ status_code = 500, message = "Failed to create streamer" })
                local _, err = call(true)
                local details = (err :: any):details()
                tests.is_nil(details.stream_started)
                tests.eq(details.error_type, "server_error")
            end)

            it("should carry the held-back error chunk of a stream that failed before sending", function()
                answer_with({
                    status_code = 500,
                    message = "Stream processing failed: quota exceeded",
                    stream_started = false,
                    deferred_error_type = "server_error",
                    deferred_error_message = "quota exceeded"
                })
                local _, err = call(true)
                local details = (err :: any):details()
                tests.is_false(details.stream_started)
                tests.eq(details.deferred_error_type, "server_error")
                tests.eq(details.deferred_error_message, "quota exceeded")
            end)

            it("should report a stream that already sent chunks as started", function()
                answer_with({
                    status_code = 500,
                    message = "Stream processing failed: reset",
                    stream_started = true
                })
                local _, err = call(true)
                local details = (err :: any):details()
                tests.is_true(details.stream_started)
                tests.is_nil(details.deferred_error_type)
            end)

            it("should leave stream_started unset without streaming", function()
                answer_with({ status_code = 503, message = "unavailable" })
                local _, err = call(false)
                tests.is_nil((err :: any):details().stream_started)
                tests.eq((err :: any):details().error_type, "server_error")
            end)
        end)
    end)
end

return tests.run_cases(define_tests)
