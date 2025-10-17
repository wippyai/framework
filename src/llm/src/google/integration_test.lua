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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content).to_contain("Integration test successful")
                expect(response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens reported")
                expect(response.tokens.completion_tokens > 0).to_be_true("No completion tokens reported")
                expect(response.tokens.total_tokens > 0).to_be_true("No total tokens reported")
                expect(response.finish_reason).to_equal("stop")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content).to_contain("Hello")
                expect(response.result.content).to_contain("Gemini")
                expect(response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens reported")
                expect(response.finish_reason).to_equal("stop")
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
                        max_tokens = 200
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content:lower()).to_contain("ahoy")
                expect(response.finish_reason).to_equal("stop")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content:lower()).to_contain("blue")
                expect(response.finish_reason).to_equal("stop")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.tokens.completion_tokens <= 15).to_be_true("Response exceeded token limit significantly")
                -- Google might finish early or hit length limit
                expect(response.finish_reason == "stop" or response.finish_reason == "length").to_be_true(
                    "Expected stop or length finish reason, got: " .. tostring(response.finish_reason)
                )
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

                expect(response.success).to_be_true("API request with empty assistant message failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content).not_to_be_nil("No content in response")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content:upper()).to_contain("ACK")
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

                expect(response.success).to_be_true("API request with stop sequences failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content).not_to_be_nil("No content in response")
                -- Response should stop before or at "5"
                expect(response.finish_reason == "stop" or response.finish_reason == "length").to_be_true(
                    "Expected stop or length finish reason"
                )
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

                expect(response.success).to_be_true("API request failed")
                expect(response.metadata).not_to_be_nil("No metadata in response")
                expect(type(response.metadata)).to_equal("table", "Metadata should be a table")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content).to_contain("END")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.tool_calls).not_to_be_nil("No tool calls in response")
                expect(#response.result.tool_calls > 0).to_be_true("Expected at least one tool call")
                expect(response.result.tool_calls[1].name).to_equal("get_weather")
                expect(response.result.tool_calls[1].arguments.location).not_to_be_nil("Missing location argument")
                expect(response.result.tool_calls[1].arguments.location:lower()).to_contain("london")
                expect(response.finish_reason).to_equal("tool_call")
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
                        max_tokens = 50
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                -- Should respond with text, no tool calls
                expect(response.result.content).not_to_be_nil("No content in response")
                expect(#response.result.content > 0).to_be_true("Response should have content")
                expect(response.finish_reason).to_equal("stop")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.tool_calls).not_to_be_nil("No tool calls in response")
                expect(#response.result.tool_calls > 0).to_be_true("Expected tool call")
                expect(response.result.tool_calls[1].name).to_equal("get_weather")
                expect(response.finish_reason).to_equal("tool_call")
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

                expect(initial_response.success).to_be_true("Initial request failed")
                expect(initial_response.result.tool_calls).not_to_be_nil("No tool calls")
                expect(#initial_response.result.tool_calls > 0).to_be_true("Expected tool call")

                local tool_call = initial_response.result.tool_calls[1]

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

                expect(continuation_response.success).to_be_true("Continuation failed: " .. (continuation_response.error_message or "unknown"))
                expect(continuation_response.result.content).to_contain("42")
                expect(continuation_response.finish_reason).to_equal("stop")
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
                        max_tokens = 100
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content).not_to_be_nil("No content in response")
                expect(#response.result.content > 10).to_be_true("Response should have substantial content")
                expect(response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens reported")
                expect(response.finish_reason).to_equal("stop")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content).not_to_be_nil("No content in response")
                expect(response.result.content:lower()).to_contain("red")
                expect(response.finish_reason).to_equal("stop")
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
                        max_tokens = 100
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content).not_to_be_nil("No content in response")
                expect(#response.result.content > 20).to_be_true("Response should describe the image")
                expect(response.finish_reason).to_equal("stop")
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
                        max_tokens = 50
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content).not_to_be_nil("No content in response")
                -- Should mention colors
                local content_lower = response.result.content:lower()
                expect(content_lower:match("red") or content_lower:match("blue")).not_to_be_nil("Should mention colors")
                expect(response.finish_reason).to_equal("stop")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.data).not_to_be_nil("No structured data in response")
                expect(response.result.data.name).not_to_be_nil("Missing name")
                expect(type(response.result.data.name)).to_equal("string", "Name should be string")
                expect(response.result.data.age).not_to_be_nil("Missing age")
                expect(type(response.result.data.age)).to_equal("number", "Age should be number")
                expect(response.result.data.occupation).not_to_be_nil("Missing occupation")
                expect(type(response.result.data.occupation)).to_equal("string", "Occupation should be string")
                expect(response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens")
                expect(response.finish_reason).to_equal("stop")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.data).not_to_be_nil("No structured data")
                expect(response.result.data.languages).not_to_be_nil("Missing languages array")
                expect(type(response.result.data.languages)).to_equal("table", "Languages should be array")
                expect(#response.result.data.languages >= 3).to_be_true("Should have at least 3 languages")

                local first_lang = response.result.data.languages[1]
                expect(first_lang.name).not_to_be_nil("First language missing name")
                expect(first_lang.type).not_to_be_nil("First language missing type")
                expect(response.finish_reason).to_equal("stop")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.data).not_to_be_nil("No structured data")
                expect(response.result.data.name).not_to_be_nil("Missing restaurant name")
                expect(response.result.data.rating).not_to_be_nil("Missing rating")
                expect(type(response.result.data.rating)).to_equal("number", "Rating should be number")
                expect(response.result.data.location).not_to_be_nil("Missing location")
                expect(response.result.data.location.city).not_to_be_nil("Missing city")
                expect(response.result.data.menu).not_to_be_nil("Missing menu")
                expect(type(response.result.data.menu)).to_equal("table", "Menu should be array")
                expect(#response.result.data.menu > 0).to_be_true("Menu should have items")

                local first_item = response.result.data.menu[1]
                expect(first_item.dish_name).not_to_be_nil("Menu item missing name")
                expect(first_item.price).not_to_be_nil("Menu item missing price")
                expect(type(first_item.price)).to_equal("number", "Price should be number")
                expect(type(first_item.is_vegetarian)).to_equal("boolean", "is_vegetarian should be boolean if present")
                expect(response.finish_reason).to_equal("stop")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.data).not_to_be_nil("No structured data")
                expect(response.result.data.name).not_to_be_nil("Missing name")
                expect(response.result.data.age).not_to_be_nil("Missing age")
                expect(response.result.data.grade).not_to_be_nil("Missing grade")
                expect(response.finish_reason).to_equal("stop")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content).to_contain("Vertex AI test successful")
                expect(response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens reported")
                expect(response.tokens.completion_tokens > 0).to_be_true("No completion tokens reported")
                expect(response.tokens.total_tokens > 0).to_be_true("No total tokens reported")
                expect(response.finish_reason).to_equal("stop")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content).to_contain("Hello")
                expect(response.result.content).to_contain("Vertex AI")
                expect(response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens reported")
                expect(response.finish_reason).to_equal("stop")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content:upper()).to_contain("BEEP")
                expect(response.finish_reason).to_equal("stop")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content).to_contain("42")
                expect(response.finish_reason).to_equal("stop")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.tokens.completion_tokens <= 15).to_be_true("Response exceeded token limit significantly")
                expect(response.finish_reason == "stop" or response.finish_reason == "length").to_be_true(
                    "Expected stop or length finish reason"
                )
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

                expect(response.success).to_be_true("API request with stop sequences failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content).not_to_be_nil("No content in response")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.tool_calls).not_to_be_nil("No tool calls in response")
                expect(#response.result.tool_calls > 0).to_be_true("Expected at least one tool call")
                expect(response.result.tool_calls[1].name).to_equal("get_weather")
                expect(response.result.tool_calls[1].arguments.location).not_to_be_nil("Missing location argument")
                expect(response.result.tool_calls[1].arguments.location:lower()).to_contain("tokyo")
                expect(response.finish_reason).to_equal("tool_call")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(#response.result.tool_calls == 0).to_be_true("Expected no tool calls")
                expect(response.result.content).not_to_be_nil("No content in response")
                expect(#response.result.content > 0).to_be_true("Response should have content")
                expect(response.finish_reason).to_equal("stop")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.tool_calls).not_to_be_nil("No tool calls in response")
                expect(#response.result.tool_calls > 0).to_be_true("Expected tool call")
                expect(response.result.tool_calls[1].name).to_equal("get_weather")
                expect(response.finish_reason).to_equal("tool_call")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content).not_to_be_nil("No content in response")
                expect(#response.result.content > 10).to_be_true("Response should have substantial content")
                expect(response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens reported")
                expect(response.finish_reason).to_equal("stop")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content).not_to_be_nil("No content in response")
                expect(response.result.content:lower()).to_contain("red")
                expect(response.finish_reason).to_equal("stop")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content).not_to_be_nil("No content in response")
                expect(#response.result.content > 20).to_be_true("Response should describe the image")
                expect(response.finish_reason).to_equal("stop")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content).not_to_be_nil("No content in response")
                -- Should mention colors
                local content_lower = response.result.content:lower()
                expect(content_lower:match("red") or content_lower:match("blue")).not_to_be_nil("Should mention colors")
                expect(response.finish_reason).to_equal("stop")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.data).not_to_be_nil("No structured data in response")
                expect(response.result.data.name).not_to_be_nil("Missing name")
                expect(type(response.result.data.name)).to_equal("string", "Name should be string")
                expect(response.result.data.age).not_to_be_nil("Missing age")
                expect(type(response.result.data.age)).to_equal("number", "Age should be number")
                expect(response.result.data.occupation).not_to_be_nil("Missing occupation")
                expect(type(response.result.data.occupation)).to_equal("string", "Occupation should be string")
                expect(response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens")
                expect(response.finish_reason).to_equal("stop")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.data).not_to_be_nil("No structured data")
                expect(response.result.data.company_name).not_to_be_nil("Missing company_name")
                expect(response.result.data.founded).not_to_be_nil("Missing founded year")
                expect(type(response.result.data.founded)).to_equal("number", "Founded should be number")
                expect(response.result.data.headquarters).not_to_be_nil("Missing headquarters")
                expect(type(response.result.data.headquarters)).to_equal("table", "Headquarters should be object")
                expect(response.result.data.headquarters.city).not_to_be_nil("Missing city")
                expect(response.result.data.headquarters.country).not_to_be_nil("Missing country")
                expect(response.finish_reason).to_equal("stop")
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

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.data).not_to_be_nil("No structured data")
                expect(response.result.data.store_name).not_to_be_nil("Missing store_name")
                expect(response.result.data.rating).not_to_be_nil("Missing rating")
                expect(type(response.result.data.rating)).to_equal("number", "Rating should be number")
                expect(response.result.data.address).not_to_be_nil("Missing address")
                expect(response.result.data.address.city).not_to_be_nil("Missing city")
                expect(response.result.data.products).not_to_be_nil("Missing products")
                expect(type(response.result.data.products)).to_equal("table", "Products should be array")
                expect(#response.result.data.products > 0).to_be_true("Products should have items")

                local first_product = response.result.data.products[1]
                expect(first_product.product_name).not_to_be_nil("Product missing name")
                expect(first_product.price).not_to_be_nil("Product missing price")
                expect(type(first_product.price)).to_equal("number", "Price should be number")
                expect(response.finish_reason).to_equal("stop")
            end)
        end)
    end)
end

return tests.run_cases(define_tests)
