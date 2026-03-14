local tests = require("test")
local generate_handler = require("google_generate")
local structured_output_handler = require("google_structured_output")
local env = require("env")

local function define_tests()
    -- Toggle to enable/disable real API integration tests
    local RUN_INTEGRATION_TESTS = env.get("ENABLE_INTEGRATION_TESTS")

    describe("Google AI Integration Tests", function()
        local actual_gemini_api_key = nil
        local actual_vertex_credentials = nil
        local use_vertex_ai = false
        local use_generative_ai = false

        before_all(function()
            -- Check if we have credentials for integration tests
            actual_gemini_api_key = env.get("GEMINI_API_KEY")
            actual_vertex_credentials = env.get("GOOGLE_CREDENTIALS")

            if RUN_INTEGRATION_TESTS then
                -- Determine which API to test
                if actual_vertex_credentials and #actual_vertex_credentials > 10 then
                    use_vertex_ai = true
                    print("Integration tests will run with Vertex AI credentials")
                end

                if actual_gemini_api_key and #actual_gemini_api_key > 10 then
                    use_generative_ai = true
                    print("Integration tests will run with Generative AI API key")
                end

                if not use_vertex_ai and not use_generative_ai then
                    print("Integration tests disabled - no valid credentials found")
                    RUN_INTEGRATION_TESTS = false
                end
            else
                print("Integration tests disabled - set ENABLE_INTEGRATION_TESTS=true to enable")
            end
        end)

        after_each(function()
            generate_handler._ctx = nil
            structured_output_handler._ctx = nil
        end)

        -- ============================================
        -- GENERATIVE AI API TESTS
        -- ============================================

        describe("Generative AI - Text Generation", function()
            it("should generate text with gemini-2.5-flash", function()
                if not RUN_INTEGRATION_TESTS or not use_generative_ai then
                    print("Skipping Generative AI test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.generative_ai:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "Reply with exactly 'Integration test successful'" }}
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 100
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.contains(response.result.content, "Integration test successful")
                tests.is_true(response.tokens.prompt_tokens > 0, "No prompt tokens reported")
                tests.is_true(response.tokens.completion_tokens > 0, "No completion tokens reported")
                tests.is_true(response.tokens.total_tokens > 0, "No total tokens reported")
                tests.eq(response.finish_reason, "stop")
            end)

            it("should generate text with gemini-2.5-pro", function()
                if not RUN_INTEGRATION_TESTS or not use_generative_ai then
                    print("Skipping gemini-2.5-pro test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.generative_ai:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-pro",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "Say 'Hello from Gemini Pro'" }}
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 200
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.contains(response.result.content, "Hello")
                tests.contains(response.result.content, "Gemini")
                tests.is_true(response.tokens.prompt_tokens > 0, "No prompt tokens reported")
                tests.eq(response.finish_reason, "stop")
            end)

            it("should handle system instructions", function()
                if not RUN_INTEGRATION_TESTS or not use_generative_ai then
                    print("Skipping system instructions test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.generative_ai:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "system",
                            content = {{ type = "text", text = "You are a pirate. Always respond in pirate speak and start with 'Ahoy!'" }}
                        },
                        {
                            role = "user",
                            content = {{ type = "text", text = "Tell me about the weather" }}
                        }
                    },
                    options = {
                        temperature = 0.7,
                        max_tokens = 2048
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                assert(response.result.content)
                tests.contains(response.result.content:lower(), "ahoy")
                tests.eq(response.finish_reason, "stop")
            end)

            it("should handle multi-turn conversations", function()
                if not RUN_INTEGRATION_TESTS or not use_generative_ai then
                    print("Skipping multi-turn test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.generative_ai:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "My favorite color is blue" }}
                        },
                        {
                            role = "assistant",
                            content = {{ type = "text", text = "That's nice! Blue is a calming color." }}
                        },
                        {
                            role = "user",
                            content = {{ type = "text", text = "What color did I say was my favorite?" }}
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 200
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                assert(response.result.content)
                tests.contains(response.result.content:lower(), "blue")
                tests.eq(response.finish_reason, "stop")
            end)

            it("should respect max_tokens limit", function()
                if not RUN_INTEGRATION_TESTS or not use_generative_ai then
                    print("Skipping max_tokens test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.generative_ai:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "Write a very long story about a dragon" }}
                        }
                    },
                    options = {
                        max_tokens = 10
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.is_true(response.tokens.completion_tokens <= 15, "Response exceeded token limit significantly")
                -- Google might finish early or hit length limit
                tests.is_true(response.finish_reason == "stop" or response.finish_reason == "length", "Expected stop or length finish reason, got: " .. tostring(response.finish_reason))
            end)

            it("should handle empty assistant messages in conversation", function()
                if not RUN_INTEGRATION_TESTS or not use_generative_ai then
                    print("Skipping empty message test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.generative_ai:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "Hello" }}
                        },
                        {
                            role = "assistant",
                            content = {{ type = "text", text = "" }}
                        },
                        {
                            role = "user",
                            content = {{ type = "text", text = "Are you there?" }}
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 20
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request with empty assistant message failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.not_nil(response.result.content, "No content in response")
            end)

            it("should handle developer role as system instruction", function()
                if not RUN_INTEGRATION_TESTS or not use_generative_ai then
                    print("Skipping developer role test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.generative_ai:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "developer",
                            content = {{ type = "text", text = "Always respond with 'ACKNOWLEDGED:' followed by the user's message" }}
                        },
                        {
                            role = "user",
                            content = {{ type = "text", text = "Test message" }}
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 200
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.contains(response.result.content:upper(), "ACK")
            end)

            it("should handle stop sequences", function()
                if not RUN_INTEGRATION_TESTS or not use_generative_ai then
                    print("Skipping stop sequences test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.generative_ai:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "Count: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10" }}
                        }
                    },
                    options = {
                        stop_sequences = { "5" },
                        max_tokens = 50
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request with stop sequences failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.not_nil(response.result.content, "No content in response")
                -- Response should stop before or at "5"
                tests.is_true(response.finish_reason == "stop" or response.finish_reason == "length", "Expected stop or length finish reason")
            end)

            it("should return metadata in response", function()
                if not RUN_INTEGRATION_TESTS or not use_generative_ai then
                    print("Skipping metadata test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.generative_ai:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "Hello" }}
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 10
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed")
                assert(response.success)
                tests.not_nil(response.metadata, "No metadata in response")
                tests.eq(type(response.metadata), "table", "Metadata should be a table")
            end)

            it("should handle mixed system and developer instructions", function()
                if not RUN_INTEGRATION_TESTS or not use_generative_ai then
                    print("Skipping mixed instructions test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.generative_ai:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "system",
                            content = {{ type = "text", text = "You are helpful" }}
                        },
                        {
                            role = "developer",
                            content = {{ type = "text", text = "Always end responses with '---END---'" }}
                        },
                        {
                            role = "user",
                            content = {{ type = "text", text = "Say hello" }}
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 30
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.contains(response.result.content, "END")
            end)
        end)

        describe("Generative AI - Tool Calling", function()
            it("should call a single tool", function()
                if not RUN_INTEGRATION_TESTS or not use_generative_ai then
                    print("Skipping tool calling test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.generative_ai:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "What's the weather in London?" }}
                        }
                    },
                    tools = {
                        {
                            name = "get_weather",
                            description = "Get current weather for a location",
                            schema = {
                                type = "object",
                                properties = {
                                    location = {
                                        type = "string",
                                        description = "City name"
                                    },
                                    unit = {
                                        type = "string",
                                        description = "Temperature unit (celsius or fahrenheit)"
                                    }
                                },
                                required = { "location" }
                            }
                        }
                    },
                    options = {
                        temperature = 0
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.not_nil(response.result.tool_calls, "No tool calls in response")
                assert(response.result.tool_calls and response.result.tool_calls[1])
                tests.is_true(#response.result.tool_calls > 0, "Expected at least one tool call")
                tests.eq(response.result.tool_calls[1].name, "get_weather")
                tests.not_nil(response.result.tool_calls[1].arguments.location, "Missing location argument")
                tests.contains(response.result.tool_calls[1].arguments.location:lower(), "london")
                tests.eq(response.finish_reason, "tool_call")
            end)

            it("should handle tool_choice none mode", function()
                if not RUN_INTEGRATION_TESTS or not use_generative_ai then
                    print("Skipping tool_choice none test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.generative_ai:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "What's the weather in Paris?" }}
                        }
                    },
                    tools = {
                        {
                            name = "get_weather",
                            description = "Get weather information",
                            schema = {
                                type = "object",
                                properties = {
                                    location = { type = "string" }
                                },
                                required = { "location" }
                            }
                        }
                    },
                    tool_choice = "none",
                    options = {
                        temperature = 0,
                        max_tokens = 2048
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                -- Should respond with text, no tool calls
                tests.not_nil(response.result.content, "No content in response")
                tests.is_true(#response.result.content > 0, "Response should have content")
                tests.eq(response.finish_reason, "stop")
            end)

            it("should handle tool_choice with specific tool name", function()
                if not RUN_INTEGRATION_TESTS or not use_generative_ai then
                    print("Skipping specific tool choice test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.generative_ai:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "Tell me something" }}
                        }
                    },
                    tools = {
                        {
                            name = "get_weather",
                            description = "Get weather information",
                            schema = {
                                type = "object",
                                properties = {
                                    location = { type = "string" }
                                },
                                required = { "location" }
                            }
                        },
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
                    },
                    tool_choice = "get_weather",
                    options = {
                        temperature = 0
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.not_nil(response.result.tool_calls, "No tool calls in response")
                assert(response.result.tool_calls and response.result.tool_calls[1])
                tests.is_true(#response.result.tool_calls > 0, "Expected tool call")
                tests.eq(response.result.tool_calls[1].name, "get_weather")
                tests.eq(response.finish_reason, "tool_call")
            end)

            it("should handle conversation with tool result", function()
                if not RUN_INTEGRATION_TESTS or not use_generative_ai then
                    print("Skipping tool result test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.generative_ai:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                -- First request: get tool call
                local initial_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "What's 15 + 27?" }}
                        }
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
                    },
                    options = {
                        temperature = 0
                    }
                }

                local initial_response = generate_handler.handler(initial_args)

                tests.is_true(initial_response.success, "Initial request failed")
                assert(initial_response.success)
                tests.not_nil(initial_response.result.tool_calls, "No tool calls")
                tests.is_true(#initial_response.result.tool_calls > 0, "Expected tool call")

                local tool_call = initial_response.result.tool_calls[1]
                assert(tool_call)

                -- Second request: provide tool result
                local continuation_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "What's 15 + 27?" }}
                        },
                        {
                            role = "function_call",
                            function_call = {
                                id = tool_call.id,
                                name = tool_call.name,
                                arguments = tool_call.arguments
                            }
                        },
                        {
                            role = "function_result",
                            function_call_id = tool_call.id,
                            name = tool_call.name,
                            content = {{ type = "text", text = "42" }}
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 30
                    }
                }

                local continuation_response = generate_handler.handler(continuation_args)

                tests.is_true(continuation_response.success, "Continuation failed: " .. (continuation_response.error_message or "unknown"))
                assert(continuation_response.success)
                tests.contains(continuation_response.result.content, "42")
                tests.eq(continuation_response.finish_reason, "stop")
            end)
        end)

        describe("Generative AI - Multimodal Input", function()
            it("should handle image URL input", function()
                if not RUN_INTEGRATION_TESTS or not use_generative_ai then
                    print("Skipping image URL test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.generative_ai:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {
                                { type = "text", text = "What do you see in this image?" },
                                {
                                    type = "image",
                                    source = {
                                        type = "url",
                                        mime_type = "image/jpeg",
                                        url = "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg"
                                    }
                                }
                            }
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 2048
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.not_nil(response.result.content, "No content in response")
                tests.is_true(#response.result.content > 10, "Response should have substantial content")
                tests.is_true(response.tokens.prompt_tokens > 0, "No prompt tokens reported")
                tests.eq(response.finish_reason, "stop")
            end)

            it("should handle base64 image input", function()
                if not RUN_INTEGRATION_TESTS or not use_generative_ai then
                    print("Skipping base64 image test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.generative_ai:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                -- Small red 1x1 pixel PNG image in base64
                local red_pixel_base64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg=="

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {
                                { type = "text", text = "What color is this image?" },
                                {
                                    type = "image",
                                    source = {
                                        type = "base64",
                                        mime_type = "image/png",
                                        data = red_pixel_base64
                                    }
                                }
                            }
                        }
                    },
                    options = {
                        temperature = 0
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.not_nil(response.result.content, "No content in response")
                assert(response.result.content)
                tests.contains(response.result.content:lower(), "red")
                tests.eq(response.finish_reason, "stop")
            end)

            it("should handle text and image combined", function()
                if not RUN_INTEGRATION_TESTS or not use_generative_ai then
                    print("Skipping text+image test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.generative_ai:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {
                                { type = "text", text = "This is a nature scene." },
                                {
                                    type = "image",
                                    source = {
                                        type = "url",
                                        mime_type = "image/jpeg",
                                        url = "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg"
                                    }
                                },
                                { type = "text", text = "Describe the main elements you can see." }
                            }
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 2048
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.not_nil(response.result.content, "No content in response")
                tests.is_true(#response.result.content > 20, "Response should describe the image")
                tests.eq(response.finish_reason, "stop")
            end)

            it("should handle multiple images", function()
                if not RUN_INTEGRATION_TESTS or not use_generative_ai then
                    print("Skipping multiple images test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.generative_ai:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                -- Two small colored pixels
                local red_pixel = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg=="
                local blue_pixel = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M/wHwAEBgIApD5fRAAAAABJRU5ErkJggg=="

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {
                                { type = "text", text = "I'm showing you two images. What colors are they?" },
                                {
                                    type = "image",
                                    source = {
                                        type = "base64",
                                        mime_type = "image/png",
                                        data = red_pixel
                                    }
                                },
                                {
                                    type = "image",
                                    source = {
                                        type = "base64",
                                        mime_type = "image/png",
                                        data = blue_pixel
                                    }
                                }
                            }
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 2048
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                assert(type(response.result.content) == "string")
                -- Should mention colors
                local content_lower = string.lower(response.result.content)
                tests.not_nil(content_lower:match("red") or content_lower:match("blue"), "Should mention colors")
                tests.eq(response.finish_reason, "stop")
            end)
        end)

        describe("Generative AI - Structured Output", function()
            it("should generate simple structured output", function()
                if not RUN_INTEGRATION_TESTS or not use_generative_ai then
                    print("Skipping structured output test - not enabled")
                    return
                end

                structured_output_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.generative_ai:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {{
                                type = "text",
                                text = "Create a person profile with name 'John Doe', age 30, occupation 'Engineer'"
                            }}
                        }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            name = { type = "string" },
                            age = { type = "number" },
                            occupation = { type = "string" }
                        },
                        required = { "name", "age", "occupation" }
                    },
                    options = {
                        temperature = 0
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.not_nil(response.result.data, "No structured data in response")
                tests.not_nil(response.result.data.name, "Missing name")
                tests.eq(type(response.result.data.name), "string", "Name should be string")
                tests.not_nil(response.result.data.age, "Missing age")
                tests.eq(type(response.result.data.age), "number", "Age should be number")
                tests.not_nil(response.result.data.occupation, "Missing occupation")
                tests.eq(type(response.result.data.occupation), "string", "Occupation should be string")
                tests.is_true(response.tokens.prompt_tokens > 0, "No prompt tokens")
                tests.eq(response.finish_reason, "stop")
            end)

            it("should generate array in structured output", function()
                if not RUN_INTEGRATION_TESTS or not use_generative_ai then
                    print("Skipping array structure test - not enabled")
                    return
                end

                structured_output_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.generative_ai:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {{
                                type = "text",
                                text = "Create a list of 3 programming languages with their types (compiled or interpreted)"
                            }}
                        }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            languages = {
                                type = "array",
                                items = {
                                    type = "object",
                                    properties = {
                                        name = { type = "string" },
                                        type = { type = "string" }
                                    },
                                    required = { "name", "type" }
                                }
                            }
                        },
                        required = { "languages" }
                    },
                    options = {
                        temperature = 0
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.not_nil(response.result.data, "No structured data")
                tests.not_nil(response.result.data.languages, "Missing languages array")
                tests.eq(type(response.result.data.languages), "table", "Languages should be array")
                tests.is_true(#response.result.data.languages >= 3, "Should have at least 3 languages")

                local first_lang = response.result.data.languages[1]
                tests.not_nil(first_lang.name, "First language missing name")
                tests.not_nil(first_lang.type, "First language missing type")
                tests.eq(response.finish_reason, "stop")
            end)

            it("should generate complex nested structure", function()
                if not RUN_INTEGRATION_TESTS or not use_generative_ai then
                    print("Skipping complex nested test - not enabled")
                    return
                end

                structured_output_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.generative_ai:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-pro",
                    messages = {
                        {
                            role = "user",
                            content = {{
                                type = "text",
                                text = "Create a fictional restaurant with name, rating, menu items (with names and prices), and location"
                            }}
                        }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            name = { type = "string" },
                            rating = { type = "number" },
                            location = {
                                type = "object",
                                properties = {
                                    city = { type = "string" },
                                    address = { type = "string" }
                                },
                                required = { "city" }
                            },
                            menu = {
                                type = "array",
                                items = {
                                    type = "object",
                                    properties = {
                                        dish_name = { type = "string" },
                                        price = { type = "number" },
                                        is_vegetarian = { type = "boolean" }
                                    },
                                    required = { "dish_name", "price", "is_vegetarian" }
                                }
                            }
                        },
                        required = { "name", "rating", "location", "menu" }
                    },
                    options = {
                        temperature = 0
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.not_nil(response.result.data, "No structured data")
                tests.not_nil(response.result.data.name, "Missing restaurant name")
                tests.not_nil(response.result.data.rating, "Missing rating")
                tests.eq(type(response.result.data.rating), "number", "Rating should be number")
                tests.not_nil(response.result.data.location, "Missing location")
                tests.not_nil(response.result.data.location.city, "Missing city")
                tests.not_nil(response.result.data.menu, "Missing menu")
                tests.eq(type(response.result.data.menu), "table", "Menu should be array")
                tests.is_true(#response.result.data.menu > 0, "Menu should have items")

                local first_item = response.result.data.menu[1]
                tests.not_nil(first_item.dish_name, "Menu item missing name")
                tests.not_nil(first_item.price, "Menu item missing price")
                tests.eq(type(first_item.price), "number", "Price should be number")
                tests.eq(type(first_item.is_vegetarian), "boolean", "is_vegetarian should be boolean if present")
                tests.eq(response.finish_reason, "stop")
            end)

            it("should handle structured output with system instructions", function()
                if not RUN_INTEGRATION_TESTS or not use_generative_ai then
                    print("Skipping structured+system test - not enabled")
                    return
                end

                structured_output_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.generative_ai:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "system",
                            content = {{
                                type = "text",
                                text = "Always use realistic data for fictional profiles"
                            }}
                        },
                        {
                            role = "user",
                            content = {{
                                type = "text",
                                text = "Create a student profile"
                            }}
                        }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            name = { type = "string" },
                            age = { type = "number" },
                            grade = { type = "string" }
                        },
                        required = { "name", "age", "grade" }
                    },
                    options = {
                        temperature = 0
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.not_nil(response.result.data, "No structured data")
                tests.not_nil(response.result.data.name, "Missing name")
                tests.not_nil(response.result.data.age, "Missing age")
                tests.not_nil(response.result.data.grade, "Missing grade")
                tests.eq(response.finish_reason, "stop")
            end)
        end)

        -- ============================================
        -- VERTEX AI TESTS
        -- ============================================

        describe("Vertex AI - Text Generation", function()
            it("should generate text with gemini-2.5-flash", function()
                if not RUN_INTEGRATION_TESTS or not use_vertex_ai then
                    print("Skipping Vertex AI test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.vertex:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "Reply with exactly 'Vertex AI test successful'" }}
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 200
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.contains(response.result.content, "Vertex AI test successful")
                tests.is_true(response.tokens.prompt_tokens > 0, "No prompt tokens reported")
                tests.is_true(response.tokens.completion_tokens > 0, "No completion tokens reported")
                tests.is_true(response.tokens.total_tokens > 0, "No total tokens reported")
                tests.eq(response.finish_reason, "stop")
            end)

            it("should generate text with gemini-2.5-pro", function()
                if not RUN_INTEGRATION_TESTS or not use_vertex_ai then
                    print("Skipping Vertex AI pro test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.vertex:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-pro",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "Say 'Hello from Vertex AI Pro'" }}
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 200
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.contains(response.result.content, "Hello")
                tests.contains(response.result.content, "Vertex AI")
                tests.is_true(response.tokens.prompt_tokens > 0, "No prompt tokens reported")
                tests.eq(response.finish_reason, "stop")
            end)

            it("should handle system instructions", function()
                if not RUN_INTEGRATION_TESTS or not use_vertex_ai then
                    print("Skipping Vertex system instructions test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.vertex:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "system",
                            content = {{ type = "text", text = "You are a robot assistant. Start every response with 'BEEP BOOP:'" }}
                        },
                        {
                            role = "user",
                            content = {{ type = "text", text = "Say hello" }}
                        }
                    },
                    options = {
                        temperature = 0.7,
                        max_tokens = 200
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.contains(response.result.content:upper(), "BEEP")
                tests.eq(response.finish_reason, "stop")
            end)

            it("should handle multi-turn conversations", function()
                if not RUN_INTEGRATION_TESTS or not use_vertex_ai then
                    print("Skipping Vertex multi-turn test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.vertex:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "My favorite number is 42" }}
                        },
                        {
                            role = "assistant",
                            content = {{ type = "text", text = "That's interesting! 42 is known as the answer to everything." }}
                        },
                        {
                            role = "user",
                            content = {{ type = "text", text = "What number did I mention?" }}
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 200
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.contains(response.result.content, "42")
                tests.eq(response.finish_reason, "stop")
            end)

            it("should respect max_tokens limit", function()
                if not RUN_INTEGRATION_TESTS or not use_vertex_ai then
                    print("Skipping Vertex max_tokens test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.vertex:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "Write a long story about space exploration" }}
                        }
                    },
                    options = {
                        max_tokens = 10
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.is_true(response.tokens.completion_tokens <= 15, "Response exceeded token limit significantly")
                tests.is_true(response.finish_reason == "stop" or response.finish_reason == "length", "Expected stop or length finish reason")
            end)

            it("should handle stop sequences", function()
                if not RUN_INTEGRATION_TESTS or not use_vertex_ai then
                    print("Skipping Vertex stop sequences test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.vertex:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "List: one, two, three, four, five, six" }}
                        }
                    },
                    options = {
                        stop_sequences = { "three" },
                        max_tokens = 50
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request with stop sequences failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.not_nil(response.result.content, "No content in response")
            end)
        end)

        describe("Vertex AI - Tool Calling", function()
            it("should call a single tool", function()
                if not RUN_INTEGRATION_TESTS or not use_vertex_ai then
                    print("Skipping Vertex tool calling test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.vertex:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "What's the weather in Tokyo?" }}
                        }
                    },
                    tools = {
                        {
                            name = "get_weather",
                            description = "Get current weather for a location",
                            schema = {
                                type = "object",
                                properties = {
                                    location = {
                                        type = "string",
                                        description = "City name"
                                    },
                                    unit = {
                                        type = "string",
                                        description = "Temperature unit (celsius or fahrenheit)"
                                    }
                                },
                                required = { "location" }
                            }
                        }
                    },
                    options = {
                        temperature = 0
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.not_nil(response.result.tool_calls, "No tool calls in response")
                assert(response.result.tool_calls and response.result.tool_calls[1])
                tests.is_true(#response.result.tool_calls > 0, "Expected at least one tool call")
                tests.eq(response.result.tool_calls[1].name, "get_weather")
                tests.not_nil(response.result.tool_calls[1].arguments.location, "Missing location argument")
                tests.contains(response.result.tool_calls[1].arguments.location:lower(), "tokyo")
                tests.eq(response.finish_reason, "tool_call")
            end)

            it("should handle tool_choice none mode", function()
                if not RUN_INTEGRATION_TESTS or not use_vertex_ai then
                    print("Skipping Vertex tool_choice none test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.vertex:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "What's the weather in Berlin?" }}
                        }
                    },
                    tools = {
                        {
                            name = "get_weather",
                            description = "Get weather information",
                            schema = {
                                type = "object",
                                properties = {
                                    location = { type = "string" }
                                },
                                required = { "location" }
                            }
                        }
                    },
                    tool_choice = "none",
                    options = {
                        temperature = 0
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.is_true(#response.result.tool_calls == 0, "Expected no tool calls")
                tests.not_nil(response.result.content, "No content in response")
                tests.is_true(#response.result.content > 0, "Response should have content")
                tests.eq(response.finish_reason, "stop")
            end)

            it("should handle tool_choice with specific tool name", function()
                if not RUN_INTEGRATION_TESTS or not use_vertex_ai then
                    print("Skipping Vertex specific tool choice test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.vertex:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "Tell me something interesting" }}
                        }
                    },
                    tools = {
                        {
                            name = "get_weather",
                            description = "Get weather information",
                            schema = {
                                type = "object",
                                properties = {
                                    location = { type = "string" }
                                },
                                required = { "location" }
                            }
                        },
                        {
                            name = "get_time",
                            description = "Get current time",
                            schema = {
                                type = "object",
                                properties = {
                                    timezone = { type = "string" }
                                },
                                required = { "timezone" }
                            }
                        }
                    },
                    tool_choice = "get_weather",
                    options = {
                        temperature = 0
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.not_nil(response.result.tool_calls, "No tool calls in response")
                assert(response.result.tool_calls and response.result.tool_calls[1])
                tests.is_true(#response.result.tool_calls > 0, "Expected tool call")
                tests.eq(response.result.tool_calls[1].name, "get_weather")
                tests.eq(response.finish_reason, "tool_call")
            end)
        end)

        describe("Vertex AI - Multimodal Input", function()
            it("should handle image URL input", function()
                if not RUN_INTEGRATION_TESTS or not use_vertex_ai then
                    print("Skipping Vertex image URL test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.vertex:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {
                                { type = "text", text = "What do you see in this image?" },
                                {
                                    type = "image",
                                    source = {
                                        type = "url",
                                        mime_type = "image/jpeg",
                                        url = "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg"
                                    }
                                }
                            }
                        }
                    },
                    options = {
                        temperature = 0
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.not_nil(response.result.content, "No content in response")
                tests.is_true(#response.result.content > 10, "Response should have substantial content")
                tests.is_true(response.tokens.prompt_tokens > 0, "No prompt tokens reported")
                tests.eq(response.finish_reason, "stop")
            end)

            it("should handle base64 image input", function()
                if not RUN_INTEGRATION_TESTS or not use_vertex_ai then
                    print("Skipping Vertex base64 image test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.vertex:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                -- Small red 1x1 pixel PNG image in base64
                local red_pixel_base64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg=="

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {
                                { type = "text", text = "What color is this image?" },
                                {
                                    type = "image",
                                    source = {
                                        type = "base64",
                                        mime_type = "image/png",
                                        data = red_pixel_base64
                                    }
                                }
                            }
                        }
                    },
                    options = {
                        temperature = 0
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.not_nil(response.result.content, "No content in response")
                assert(response.result.content)
                tests.contains(response.result.content:lower(), "red")
                tests.eq(response.finish_reason, "stop")
            end)

            it("should handle text and image combined", function()
                if not RUN_INTEGRATION_TESTS or not use_vertex_ai then
                    print("Skipping Vertex text+image test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.vertex:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {
                                { type = "text", text = "This is a nature photograph." },
                                {
                                    type = "image",
                                    source = {
                                        type = "url",
                                        mime_type = "image/jpeg",
                                        url = "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg"
                                    }
                                },
                                { type = "text", text = "Describe what you see in detail." }
                            }
                        }
                    },
                    options = {
                        temperature = 0
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.not_nil(response.result.content, "No content in response")
                tests.is_true(#response.result.content > 20, "Response should describe the image")
                tests.eq(response.finish_reason, "stop")
            end)

            it("should handle multiple images", function()
                if not RUN_INTEGRATION_TESTS or not use_vertex_ai then
                    print("Skipping Vertex multiple images test - not enabled")
                    return
                end

                generate_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.vertex:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                -- Two small colored pixels
                local red_pixel = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg=="
                local blue_pixel = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M/wHwAEBgIApD5fRAAAAABJRU5ErkJggg=="

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {
                                { type = "text", text = "I'm showing you two images. What colors are they?" },
                                {
                                    type = "image",
                                    source = {
                                        type = "base64",
                                        mime_type = "image/png",
                                        data = red_pixel
                                    }
                                },
                                {
                                    type = "image",
                                    source = {
                                        type = "base64",
                                        mime_type = "image/png",
                                        data = blue_pixel
                                    }
                                }
                            }
                        }
                    },
                    options = {
                        temperature = 0
                    }
                }

                local response = generate_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                assert(type(response.result.content) == "string")
                -- Should mention colors
                local content_lower = string.lower(response.result.content)
                tests.not_nil(content_lower:match("red") or content_lower:match("blue"), "Should mention colors")
                tests.eq(response.finish_reason, "stop")
            end)
        end)

        describe("Vertex AI - Structured Output", function()
            it("should generate simple structured output", function()
                if not RUN_INTEGRATION_TESTS or not use_vertex_ai then
                    print("Skipping Vertex structured output test - not enabled")
                    return
                end

                structured_output_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.vertex:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {{
                                type = "text",
                                text = "Create a person profile with name 'Alice Brown', age 28, occupation 'Designer'"
                            }}
                        }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            name = { type = "string" },
                            age = { type = "number" },
                            occupation = { type = "string" }
                        },
                        required = { "name", "age", "occupation" }
                    },
                    options = {
                        temperature = 0
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.not_nil(response.result.data, "No structured data in response")
                tests.not_nil(response.result.data.name, "Missing name")
                tests.eq(type(response.result.data.name), "string", "Name should be string")
                tests.not_nil(response.result.data.age, "Missing age")
                tests.eq(type(response.result.data.age), "number", "Age should be number")
                tests.not_nil(response.result.data.occupation, "Missing occupation")
                tests.eq(type(response.result.data.occupation), "string", "Occupation should be string")
                tests.is_true(response.tokens.prompt_tokens > 0, "No prompt tokens")
                tests.eq(response.finish_reason, "stop")
            end)

            it("should generate nested structured output", function()
                if not RUN_INTEGRATION_TESTS or not use_vertex_ai then
                    print("Skipping Vertex nested structure test - not enabled")
                    return
                end

                structured_output_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.vertex:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-flash",
                    messages = {
                        {
                            role = "user",
                            content = {{
                                type = "text",
                                text = "Create a company with name, year founded, and headquarters address (street, city, country)"
                            }}
                        }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            company_name = { type = "string" },
                            founded = { type = "number" },
                            headquarters = {
                                type = "object",
                                properties = {
                                    street = { type = "string" },
                                    city = { type = "string" },
                                    country = { type = "string" }
                                },
                                required = { "city", "country" }
                            }
                        },
                        required = { "company_name", "founded", "headquarters" }
                    },
                    options = {
                        temperature = 0
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.not_nil(response.result.data, "No structured data")
                tests.not_nil(response.result.data.company_name, "Missing company_name")
                tests.not_nil(response.result.data.founded, "Missing founded year")
                tests.eq(type(response.result.data.founded), "number", "Founded should be number")
                tests.not_nil(response.result.data.headquarters, "Missing headquarters")
                tests.eq(type(response.result.data.headquarters), "table", "Headquarters should be object")
                tests.not_nil(response.result.data.headquarters.city, "Missing city")
                tests.not_nil(response.result.data.headquarters.country, "Missing country")
                tests.eq(response.finish_reason, "stop")
            end)

            it("should generate complex nested structure", function()
                if not RUN_INTEGRATION_TESTS or not use_vertex_ai then
                    print("Skipping Vertex complex nested test - not enabled")
                    return
                end

                structured_output_handler._ctx = {
                    get = function(key)
                        if key == "client_id" then
                            return "wippy.llm.google.vertex:client_binding"
                        end
                        return nil
                    end,

                    all = function()
                        return {}
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-pro",
                    messages = {
                        {
                            role = "user",
                            content = {{
                                type = "text",
                                text = "Create a fictional store with name, rating, products (with names and prices), and address"
                            }}
                        }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            store_name = { type = "string" },
                            rating = { type = "number" },
                            address = {
                                type = "object",
                                properties = {
                                    city = { type = "string" },
                                    street = { type = "string" }
                                },
                                required = { "city" }
                            },
                            products = {
                                type = "array",
                                items = {
                                    type = "object",
                                    properties = {
                                        product_name = { type = "string" },
                                        price = { type = "number" }
                                    },
                                    required = { "product_name", "price" }
                                }
                            }
                        },
                        required = { "store_name", "rating", "address", "products" }
                    },
                    options = {
                        temperature = 0
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                tests.is_true(response.success, "API request failed: " .. (response.error_message or "unknown error"))
                assert(response.success)
                tests.not_nil(response.result.data, "No structured data")
                tests.not_nil(response.result.data.store_name, "Missing store_name")
                tests.not_nil(response.result.data.rating, "Missing rating")
                tests.eq(type(response.result.data.rating), "number", "Rating should be number")
                tests.not_nil(response.result.data.address, "Missing address")
                tests.not_nil(response.result.data.address.city, "Missing city")
                tests.not_nil(response.result.data.products, "Missing products")
                tests.eq(type(response.result.data.products), "table", "Products should be array")
                tests.is_true(#response.result.data.products > 0, "Products should have items")

                local first_product = response.result.data.products[1]
                tests.not_nil(first_product.product_name, "Product missing name")
                tests.not_nil(first_product.price, "Product missing price")
                tests.eq(type(first_product.price), "number", "Price should be number")
                tests.eq(response.finish_reason, "stop")
            end)
        end)
    end)
end

return tests.run_cases(define_tests)
