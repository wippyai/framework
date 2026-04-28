local openai_mapper = require("openai_mapper")
local output = require("output")
local json = require("json")
local test = require("test")

local function define_tests()
    describe("OpenAI Mapper", function()

        describe("Message Mapping", function()
            it("should map standard user, assistant, system messages", function()
                local contract_messages = {
                    {
                        role = "system",
                        content = {{ type = "text", text = "You are a helpful assistant" }}
                    },
                    {
                        role = "user",
                        content = {{ type = "text", text = "Hello" }}
                    },
                    {
                        role = "assistant",
                        content = {{ type = "text", text = "Hi there!" }}
                    }
                }

                -- Responses API: system → instructions (separate field), user/assistant → input items
                local instructions = openai_mapper.extract_instructions(contract_messages)
                test.eq(instructions, "You are a helpful assistant")

                local input_items = openai_mapper.map_messages(contract_messages)
                test.eq(#input_items, 2)

                test.eq(input_items[1].type, "message")
                test.eq(input_items[1].role, "user")
                local usr_content = input_items[1].content :: any
                test.eq(usr_content[1].type, "input_text")
                test.eq(usr_content[1].text, "Hello")

                test.eq(input_items[2].type, "message")
                test.eq(input_items[2].role, "assistant")
                local asst_content = input_items[2].content :: any
                test.eq(asst_content[1].type, "output_text")
                test.eq(asst_content[1].text, "Hi there!")
            end)

            it("should convert string content to processed format", function()
                local contract_messages = {
                    {
                        role = "user",
                        content = "Simple string message"
                    }
                }

                local input_items = openai_mapper.map_messages(contract_messages)

                test.eq(#input_items, 1)
                local msg_content = input_items[1].content :: any
                test.eq(msg_content[1].type, "input_text")
                test.eq(msg_content[1].text, "Simple string message")
            end)

            it("should convert image content to OpenAI format", function()
                local contract_messages = {
                    {
                        role = "user",
                        content = {
                            { type = "text", text = "What's in this image?" },
                            {
                                type = "image",
                                source = {
                                    type = "url",
                                    url = "https://example.com/image.jpg"
                                }
                            }
                        }
                    }
                }

                local input_items = openai_mapper.map_messages(contract_messages)

                test.eq(#input_items, 1)
                local img_content = input_items[1].content :: any
                test.eq(img_content[1].type, "input_text")
                test.eq(img_content[2].type, "input_image")
                test.eq(img_content[2].image_url, "https://example.com/image.jpg")
            end)

            it("should convert base64 image content with mime type", function()
                local contract_messages = {
                    {
                        role = "user",
                        content = {
                            {
                                type = "image",
                                source = {
                                    type = "base64",
                                    mime_type = "image/jpeg",
                                    data = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
                                }
                            }
                        }
                    }
                }

                local input_items = openai_mapper.map_messages(contract_messages)

                test.eq(#input_items, 1)
                local b64_content = input_items[1].content :: any
                test.eq(b64_content[1].type, "input_image")
                test.contains(tostring(b64_content[1].image_url), "data:image/jpeg;base64,")
                test.contains(tostring(b64_content[1].image_url), "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==")
            end)

            it("should emit function_call messages as standalone items", function()
                -- Responses API: each function_call is its own top-level item, not nested under an assistant message.
                local contract_messages = {
                    {
                        role = "function_call",
                        function_call = {
                            id = "call_123",
                            name = "get_weather",
                            arguments = { location = "New York" }
                        }
                    },
                    {
                        role = "function_call",
                        function_call = {
                            id = "call_456",
                            name = "calculate",
                            arguments = { expression = "2+2" }
                        }
                    }
                }

                local input_items = openai_mapper.map_messages(contract_messages)

                test.eq(#input_items, 2)

                test.eq(input_items[1].type, "function_call")
                test.eq(input_items[1].call_id, "call_123")
                test.eq(input_items[1].name, "get_weather")
                local args1 = json.decode(tostring(input_items[1].arguments))
                test.eq(args1.location, "New York")

                test.eq(input_items[2].type, "function_call")
                test.eq(input_items[2].call_id, "call_456")
                test.eq(input_items[2].name, "calculate")
                local args2 = json.decode(tostring(input_items[2].arguments))
                test.eq(args2.expression, "2+2")
            end)

            it("should handle interleaved function_call and function_result after assistant", function()
                local contract_messages = {
                    { role = "user", content = "Show me containers and images" },
                    {
                        role = "assistant",
                        content = {{ type = "text", text = "Let me look that up." }}
                    },
                    {
                        role = "function_call",
                        function_call = {
                            id = "call_AAA",
                            name = "ListContainers",
                            arguments = {}
                        }
                    },
                    {
                        role = "function_result",
                        content = "3 containers found",
                        function_call_id = "call_AAA",
                        name = "ListContainers"
                    },
                    {
                        role = "function_call",
                        function_call = {
                            id = "call_BBB",
                            name = "ListImages",
                            arguments = {}
                        }
                    },
                    {
                        role = "function_result",
                        content = "5 images found",
                        function_call_id = "call_BBB",
                        name = "ListImages"
                    }
                }

                -- Responses API: user msg, assistant msg, fc(AAA), fco(AAA), fc(BBB), fco(BBB)
                local input_items = openai_mapper.map_messages(contract_messages)
                test.eq(#input_items, 6)

                test.eq(input_items[1].type, "message")
                test.eq(input_items[1].role, "user")

                test.eq(input_items[2].type, "message")
                test.eq(input_items[2].role, "assistant")

                test.eq(input_items[3].type, "function_call")
                test.eq(input_items[3].call_id, "call_AAA")
                test.eq(input_items[3].name, "ListContainers")

                test.eq(input_items[4].type, "function_call_output")
                test.eq(input_items[4].call_id, "call_AAA")
                test.eq(input_items[4].output, "3 containers found")

                test.eq(input_items[5].type, "function_call")
                test.eq(input_items[5].call_id, "call_BBB")
                test.eq(input_items[5].name, "ListImages")

                test.eq(input_items[6].type, "function_call_output")
                test.eq(input_items[6].call_id, "call_BBB")
                test.eq(input_items[6].output, "5 images found")
            end)

            it("should handle three interleaved tool calls after assistant", function()
                local contract_messages = {
                    {
                        role = "assistant",
                        content = ""
                    },
                    {
                        role = "function_call",
                        function_call = { id = "call_1", name = "ToolA", arguments = { x = 1 } }
                    },
                    {
                        role = "function_result",
                        content = "result_A",
                        function_call_id = "call_1"
                    },
                    {
                        role = "function_call",
                        function_call = { id = "call_2", name = "ToolB", arguments = { y = 2 } }
                    },
                    {
                        role = "function_result",
                        content = "result_B",
                        function_call_id = "call_2"
                    },
                    {
                        role = "function_call",
                        function_call = { id = "call_3", name = "ToolC", arguments = { z = 3 } }
                    },
                    {
                        role = "function_result",
                        content = "result_C",
                        function_call_id = "call_3"
                    },
                    {
                        role = "assistant",
                        content = "Here are the results."
                    }
                }

                -- Responses API: empty assistant msg dropped, then fc/fco x3, then final assistant msg
                local input_items = openai_mapper.map_messages(contract_messages)
                test.eq(#input_items, 7)

                test.eq(input_items[1].type, "function_call")
                test.eq(input_items[1].call_id, "call_1")
                test.eq(input_items[2].type, "function_call_output")
                test.eq(input_items[2].call_id, "call_1")

                test.eq(input_items[3].type, "function_call")
                test.eq(input_items[3].call_id, "call_2")
                test.eq(input_items[4].type, "function_call_output")
                test.eq(input_items[4].call_id, "call_2")

                test.eq(input_items[5].type, "function_call")
                test.eq(input_items[5].call_id, "call_3")
                test.eq(input_items[6].type, "function_call_output")
                test.eq(input_items[6].call_id, "call_3")

                test.eq(input_items[7].type, "message")
                test.eq(input_items[7].role, "assistant")
                local final_content = input_items[7].content :: any
                test.eq(final_content[1].type, "output_text")
                test.eq(final_content[1].text, "Here are the results.")
            end)

            it("should handle interleaved calls followed by user message", function()
                local contract_messages = {
                    {
                        role = "assistant",
                        content = ""
                    },
                    {
                        role = "function_call",
                        function_call = { id = "call_X", name = "Navigate", arguments = { page = "home" } }
                    },
                    {
                        role = "function_result",
                        content = "navigated",
                        function_call_id = "call_X"
                    },
                    {
                        role = "function_call",
                        function_call = { id = "call_Y", name = "GetData", arguments = {} }
                    },
                    {
                        role = "function_result",
                        content = "data fetched",
                        function_call_id = "call_Y"
                    },
                    {
                        role = "user",
                        content = "Thanks"
                    }
                }

                local input_items = openai_mapper.map_messages(contract_messages)
                -- empty assistant dropped, fc(X), fco(X), fc(Y), fco(Y), user
                test.eq(#input_items, 5)

                test.eq(input_items[1].type, "function_call")
                test.eq(input_items[1].call_id, "call_X")
                test.eq(input_items[2].type, "function_call_output")
                test.eq(input_items[2].call_id, "call_X")
                test.eq(input_items[3].type, "function_call")
                test.eq(input_items[3].call_id, "call_Y")
                test.eq(input_items[4].type, "function_call_output")
                test.eq(input_items[4].call_id, "call_Y")

                test.eq(input_items[5].type, "message")
                test.eq(input_items[5].role, "user")
            end)

            it("should preserve user messages after assistant without tool calls", function()
                local contract_messages = {
                    {
                        role = "user",
                        content = {{ type = "text", text = "Do you see this file?" }}
                    },
                    {
                        role = "assistant",
                        content = {{ type = "text", text = "Yes, I see the file." }}
                    },
                    {
                        role = "user",
                        content = {{ type = "text", text = "Build me a data model" }}
                    },
                    {
                        role = "assistant",
                        content = {{ type = "text", text = "Sure, here is the model." }}
                    },
                    {
                        role = "user",
                        content = {{ type = "text", text = "Use your tools" }}
                    }
                }

                local input_items = openai_mapper.map_messages(contract_messages)
                test.eq(#input_items, 5)

                test.eq(input_items[1].role, "user")
                local u1 = input_items[1].content :: any
                test.eq(u1[1].text, "Do you see this file?")

                test.eq(input_items[2].role, "assistant")
                local a1 = input_items[2].content :: any
                test.eq(a1[1].text, "Yes, I see the file.")

                test.eq(input_items[3].role, "user")
                local u2 = input_items[3].content :: any
                test.eq(u2[1].text, "Build me a data model")

                test.eq(input_items[4].role, "assistant")
                local a2 = input_items[4].content :: any
                test.eq(a2[1].text, "Sure, here is the model.")

                test.eq(input_items[5].role, "user")
                local u3 = input_items[5].content :: any
                test.eq(u3[1].text, "Use your tools")
            end)

            it("should skip function_call messages without id", function()
                local contract_messages = {
                    {
                        role = "function_call",
                        function_call = {
                            name = "get_weather",
                            arguments = { location = "New York" }
                            -- Missing id
                        }
                    }
                }

                local input_items = openai_mapper.map_messages(contract_messages)
                test.eq(#input_items, 0)
            end)

            it("should convert function_result messages to function_call_output items", function()
                local contract_messages = {
                    {
                        role = "function_result",
                        content = {{ type = "text", text = "The weather is sunny" }},
                        function_call_id = "call_123",
                        name = "get_weather"
                    }
                }

                local input_items = openai_mapper.map_messages(contract_messages)

                test.eq(#input_items, 1)
                local item = input_items[1] :: any
                test.eq(item.type, "function_call_output")
                test.eq(item.call_id, "call_123")
                test.eq(item.output, "The weather is sunny")
            end)

            it("should handle string content in function_result", function()
                local contract_messages = {
                    {
                        role = "function_result",
                        content = "Simple string result",
                        function_call_id = "call_123"
                    }
                }

                local input_items = openai_mapper.map_messages(contract_messages)

                test.eq(#input_items, 1)
                test.eq(input_items[1].type, "function_call_output")
                test.eq(input_items[1].output, "Simple string result")
            end)

            it("should fold developer messages into instructions", function()
                -- Responses API: developer/system messages → instructions field
                local contract_messages = {
                    {
                        role = "developer",
                        content = {{ type = "text", text = "Debug: Use detailed explanations" }}
                    }
                }

                local instructions = openai_mapper.extract_instructions(contract_messages)
                test.eq(instructions, "Debug: Use detailed explanations")

                local input_items = openai_mapper.map_messages(contract_messages)
                test.eq(#input_items, 0)
            end)

            it("should handle developer messages for o-series models with no previous user message", function()
                local contract_messages = {
                    {
                        role = "developer",
                        content = {{ type = "text", text = "Be precise" }}
                    }
                }

                local instructions = openai_mapper.extract_instructions(contract_messages)
                test.eq(instructions, "Be precise")

                local input_items = openai_mapper.map_messages(contract_messages, { model = "o1-mini" })
                test.eq(#input_items, 0)
            end)

            it("should skip unknown message roles", function()
                local contract_messages = {
                    {
                        role = "unknown_role",
                        content = {{ type = "text", text = "This should be skipped" }}
                    },
                    {
                        role = "user",
                        content = {{ type = "text", text = "This should be kept" }}
                    }
                }

                local input_items = openai_mapper.map_messages(contract_messages)

                test.eq(#input_items, 1)
                test.eq(input_items[1].role, "user")
                local kept_content = input_items[1].content :: any
                test.eq(kept_content[1].text, "This should be kept")
            end)
        end)

        describe("Tool Mapping", function()
            it("should map contract tools to Responses API format", function()
                local contract_tools = {
                    {
                        name = "get_weather",
                        description = "Get weather information",
                        schema = {
                            type = "object",
                            properties = {
                                location = { type = "string" },
                                units = { type = "string", enum = {"celsius", "fahrenheit"} }
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
                }

                local tools, tool_map = openai_mapper.map_tools(contract_tools)

                -- Responses API: name, description, parameters live at the top level (no nested .function)
                test.eq(#tools, 2)
                test.eq(tools[1].type, "function")
                test.eq(tools[1].name, "get_weather")
                test.eq(tools[1].description, "Get weather information")
                test.eq(tools[1].parameters.type, "object")
                test.eq(tools[1].parameters.properties.location.type, "string")
                test.is_nil(tools[1]["function"])
                -- strict defaults to false (back-compat with non-strict schemas)
                test.eq(tools[1].strict, false)

                test.not_nil(tool_map["get_weather"])
                test.not_nil(tool_map["calculate"])
            end)

            it("should set strict true when explicitly requested", function()
                local tools, _ = openai_mapper.map_tools({
                    {
                        name = "f",
                        description = "d",
                        schema = { type = "object", properties = {}, required = {}, additionalProperties = false }
                    }
                }, { strict_default = true })
                test.eq(tools[1].strict, true)
            end)

            it("should handle empty tools array", function()
                local tools, tool_map = openai_mapper.map_tools({})

                test.is_nil(tools)
                test.is_nil(next(tool_map))
            end)

            it("should handle nil tools", function()
                local tools, tool_map = openai_mapper.map_tools(nil)

                test.is_nil(tools)
                test.is_nil(next(tool_map))
            end)

            it("should skip tools with missing required fields", function()
                local contract_tools = {
                    {
                        name = "valid_tool",
                        description = "Valid tool",
                        schema = { type = "object" }
                    },
                    {
                        name = "invalid_tool"
                        -- Missing description and schema
                    }
                }

                local tools, tool_map = openai_mapper.map_tools(contract_tools)

                test.eq(#tools, 1)
                test.eq(tools[1].name, "valid_tool")
                test.not_nil(tool_map["valid_tool"])
                test.is_nil(tool_map["invalid_tool"])
            end)
        end)

        describe("Tool Choice Mapping", function()
            local test_tools = {
                { name = "get_weather" },
                { name = "calculate" }
            }

            it("should map auto tool choice", function()
                local choice, error = openai_mapper.map_tool_choice("auto", test_tools)

                test.is_nil(error)
                test.eq(choice, "auto")
            end)

            it("should map none tool choice", function()
                local choice, error = openai_mapper.map_tool_choice("none", test_tools)

                test.is_nil(error)
                test.eq(choice, "none")
            end)

            it("should map any tool choice to required", function()
                local choice, error = openai_mapper.map_tool_choice("any", test_tools)

                test.is_nil(error)
                test.eq(choice, "required")
            end)

            it("should map specific tool name", function()
                local choice, error = openai_mapper.map_tool_choice("get_weather", test_tools)

                -- Responses API tool_choice: { type = "function", name = "..." } (no nested .function)
                test.is_nil(error)
                local c = choice :: any
                test.eq(c.type, "function")
                test.eq(c.name, "get_weather")
                test.is_nil(c["function"])
            end)

            it("should error on non-existent tool", function()
                local choice, error = openai_mapper.map_tool_choice("nonexistent_tool", test_tools)

                test.is_nil(choice)
                test.contains(tostring(error), "not found")
            end)

            it("should default to auto for nil input", function()
                local choice, error = openai_mapper.map_tool_choice(nil, test_tools)

                test.is_nil(error)
                test.eq(choice, "auto")
            end)
        end)

        describe("Options Mapping", function()
            it("should map standard options (Responses API supports temperature, top_p, max_output_tokens, user)", function()
                local contract_options = {
                    temperature = 0.7,
                    max_tokens = 150,
                    top_p = 0.9,
                    user = "test-user"
                }

                local opts = openai_mapper.map_options(contract_options)

                test.eq(opts.temperature, 0.7)
                -- Responses API uses max_output_tokens (not max_tokens / max_completion_tokens)
                test.eq(opts.max_output_tokens, 150)
                test.is_nil(opts.max_tokens)
                test.is_nil(opts.max_completion_tokens)
                test.eq(opts.top_p, 0.9)
                test.eq(opts.user, "test-user")
            end)

            it("should ignore Chat-Completions-only sampling options (frequency_penalty, presence_penalty, stop, seed)", function()
                -- Responses API does not accept these — verify they are filtered out by the mapper.
                local contract_options = {
                    frequency_penalty = 0.5,
                    presence_penalty = 0.3,
                    stop_sequences = {"STOP", "END"},
                    seed = 42,
                    max_tokens = 100
                }

                local opts = openai_mapper.map_options(contract_options)

                test.eq(opts.max_output_tokens, 100)
                test.is_nil(opts.frequency_penalty)
                test.is_nil(opts.presence_penalty)
                test.is_nil(opts.stop)
                test.is_nil(opts.stop_sequences)
                test.is_nil(opts.seed)
            end)

            it("should handle reasoning model options (reasoning.effort, no temperature/top_p)", function()
                local contract_options = {
                    reasoning_model_request = true,
                    thinking_effort = 50,
                    max_tokens = 100,
                    temperature = 0.5,  -- Should be ignored for reasoning models
                    top_p = 0.9         -- Should be ignored for reasoning models
                }

                local opts = openai_mapper.map_options(contract_options)

                test.eq(opts.max_output_tokens, 100)
                test.is_nil(opts.max_tokens)
                test.is_nil(opts.max_completion_tokens)
                local reasoning = opts.reasoning :: any
                test.eq(reasoning.effort, "medium")
                test.is_nil(opts.reasoning_effort)
                test.is_nil(opts.temperature)
                test.is_nil(opts.top_p)
            end)

            it("should map thinking effort levels including minimal and xhigh", function()
                local test_cases = {
                    { effort = 0,   expected = "minimal" },
                    { effort = 10,  expected = "low" },
                    { effort = 24,  expected = "low" },
                    { effort = 25,  expected = "medium" },
                    { effort = 50,  expected = "medium" },
                    { effort = 59,  expected = "medium" },
                    { effort = 60,  expected = "high" },
                    { effort = 89,  expected = "high" },
                    { effort = 90,  expected = "xhigh" },
                    { effort = 100, expected = "xhigh" }
                }

                for _, case in ipairs(test_cases) do
                    local opts = openai_mapper.map_options({
                        reasoning_model_request = true,
                        thinking_effort = case.effort
                    })
                    local reasoning = opts.reasoning :: any
                    test.eq(reasoning.effort, case.expected)
                end
            end)

            it("should forward Responses-API-specific options: previous_response_id, store, parallel_tool_calls", function()
                local opts = openai_mapper.map_options({
                    previous_response_id = "resp_abc",
                    store = false,
                    parallel_tool_calls = false
                })
                test.eq(opts.previous_response_id, "resp_abc")
                test.eq(opts.store, false)
                test.eq(opts.parallel_tool_calls, false)
            end)

            it("should default reasoning persistence to previous_response (no payload changes)", function()
                local opts = openai_mapper.map_options({ reasoning_model_request = true })
                test.is_nil(opts.include)
                test.is_nil(opts.store)
            end)

            it("should auto-set store=false and include encrypted_content when persistence=encrypted_content", function()
                local opts = openai_mapper.map_options({
                    reasoning_model_request = true,
                    reasoning_persistence = "encrypted_content"
                })
                test.eq(opts.store, false)
                test.not_nil(opts.include)
                local found = false
                for _, v in ipairs(opts.include) do
                    if v == "reasoning.encrypted_content" then found = true; break end
                end
                test.is_true(found)
            end)

            it("should respect explicit store override even with encrypted_content persistence", function()
                local opts = openai_mapper.map_options({
                    reasoning_model_request = true,
                    reasoning_persistence = "encrypted_content",
                    store = true
                })
                test.eq(opts.store, true)
            end)

            it("should not set include for persistence=none", function()
                local opts = openai_mapper.map_options({
                    reasoning_model_request = true,
                    reasoning_persistence = "none"
                })
                test.is_nil(opts.include)
            end)
        end)

        describe("Encrypted Reasoning Persistence", function()
            it("should attach encrypted_reasoning from output[] to tool_calls.provider_metadata", function()
                local resp = {
                    id = "resp_enc_1",
                    status = "completed",
                    output = {
                        {
                            type = "reasoning",
                            id = "rs_1",
                            encrypted_content = "ENCBLOB1",
                            summary = {}
                        },
                        {
                            type = "function_call",
                            call_id = "call_xyz",
                            name = "lookup",
                            arguments = "{}"
                        }
                    },
                    usage = { input_tokens = 1, output_tokens = 1 }
                }

                local result = openai_mapper.map_success_response(resp, { tool_name_map = {} }) :: any
                test.eq(#result.result.tool_calls, 1)
                local pm = result.result.tool_calls[1].provider_metadata :: any
                test.not_nil(pm)
                test.eq(pm.encrypted_reasoning, "ENCBLOB1")
            end)

            it("should also surface encrypted_reasoning at response.metadata level", function()
                local resp = {
                    id = "resp_enc_2",
                    status = "completed",
                    output = {
                        { type = "reasoning", id = "rs_1", encrypted_content = "BLOB", summary = {} },
                        {
                            type = "message",
                            role = "assistant",
                            content = { { type = "output_text", text = "ok" } }
                        }
                    }
                }

                local result = openai_mapper.map_success_response(resp, { tool_name_map = {} }) :: any
                test.eq(result.metadata.encrypted_reasoning, "BLOB")
            end)

            it("should serialize function_call.provider_metadata.encrypted_reasoning into a reasoning input item", function()
                local items = openai_mapper.map_messages({
                    {
                        role = "function_call",
                        function_call = {
                            id = "call_1",
                            name = "f",
                            arguments = {},
                            provider_metadata = { encrypted_reasoning = "BLOBX" }
                        }
                    }
                })

                test.eq(#items, 2)
                test.eq(items[1].type, "reasoning")
                test.eq(items[1].encrypted_content, "BLOBX")
                test.eq(items[2].type, "function_call")
                test.eq(items[2].call_id, "call_1")
            end)

            it("should not emit a reasoning input item when encrypted_reasoning is missing", function()
                local items = openai_mapper.map_messages({
                    {
                        role = "function_call",
                        function_call = { id = "call_1", name = "f", arguments = {} }
                    }
                })
                test.eq(#items, 1)
                test.eq(items[1].type, "function_call")
            end)

            it("should handle nil options", function()
                local opts = openai_mapper.map_options(nil)

                test.is_nil(next(opts))
            end)

            it("should handle empty options", function()
                local opts = openai_mapper.map_options({})

                test.is_nil(next(opts))
            end)
        end)

        describe("Tool Calls Response Mapping", function()
            it("should map Responses API function_call items to contract format", function()
                -- map_tool_calls now consumes function_call items from output[]
                local function_call_items = {
                    {
                        type = "function_call",
                        call_id = "call_123",
                        name = "get_weather",
                        arguments = '{"location": "New York", "units": "celsius"}'
                    },
                    {
                        type = "function_call",
                        call_id = "call_456",
                        name = "calculate",
                        arguments = '{"expression": "2+2"}'
                    }
                }

                local contract_tool_calls = openai_mapper.map_tool_calls(function_call_items)

                test.eq(#contract_tool_calls, 2)

                local tc1 = contract_tool_calls[1]
                if tc1 then
                    test.eq(tc1.id, "call_123")
                    test.eq(tc1.name, "get_weather")
                    test.eq(tc1.arguments.location, "New York")
                    test.eq(tc1.arguments.units, "celsius")
                end

                local tc2 = contract_tool_calls[2]
                if tc2 then
                    test.eq(tc2.id, "call_456")
                    test.eq(tc2.name, "calculate")
                    test.eq(tc2.arguments.expression, "2+2")
                end
            end)

            it("should handle invalid JSON arguments", function()
                local function_call_items = {
                    {
                        type = "function_call",
                        call_id = "call_123",
                        name = "test_tool",
                        arguments = 'invalid json {'
                    }
                }

                local contract_tool_calls = openai_mapper.map_tool_calls(function_call_items)

                test.eq(#contract_tool_calls, 1)
                local tc = contract_tool_calls[1]
                if tc then
                    test.eq(tc.id, "call_123")
                    test.eq(tc.name, "test_tool")
                    test.not_nil(tc.arguments)
                    test.is_nil(next(tc.arguments))
                end
            end)

            it("should handle empty arguments", function()
                local function_call_items = {
                    {
                        type = "function_call",
                        call_id = "call_123",
                        name = "test_tool",
                        arguments = ""
                    }
                }

                local contract_tool_calls = openai_mapper.map_tool_calls(function_call_items)

                test.eq(#contract_tool_calls, 1)
                local tc = contract_tool_calls[1]
                if tc then
                    test.not_nil(tc.arguments)
                    test.is_nil(next(tc.arguments))
                end
            end)

            it("should handle nil tool calls", function()
                local contract_tool_calls = openai_mapper.map_tool_calls(nil)

                test.eq(#contract_tool_calls, 0)
            end)
        end)

        describe("Finish Reason Mapping", function()
            -- Responses API signature: map_finish_reason(status, has_tool_calls, incomplete_reason)
            it("should map all Responses API status values correctly", function()
                local test_cases = {
                    { status = "completed", has_tool_calls = false, incomplete_reason = nil, expected = "stop" },
                    { status = "completed", has_tool_calls = true,  incomplete_reason = nil, expected = "tool_call" },
                    { status = "incomplete", has_tool_calls = false, incomplete_reason = "max_output_tokens", expected = "length" },
                    { status = "incomplete", has_tool_calls = false, incomplete_reason = "content_filter", expected = "filtered" },
                    { status = "incomplete", has_tool_calls = false, incomplete_reason = nil, expected = "length" },
                    { status = "failed",    has_tool_calls = false, incomplete_reason = nil, expected = "error" },
                    { status = "cancelled", has_tool_calls = false, incomplete_reason = nil, expected = "error" }
                }

                for _, case in ipairs(test_cases) do
                    local result = openai_mapper.map_finish_reason(case.status, case.has_tool_calls, case.incomplete_reason)
                    test.eq(result, case.expected)
                end
            end)

            it("should default to stop when status is unknown", function()
                test.eq(openai_mapper.map_finish_reason(nil, false, nil), "stop")
                test.eq(openai_mapper.map_finish_reason("weird", false, nil), "stop")
            end)

            it("should prefer incomplete reason over tool_call when truncated mid-call", function()
                -- A response that hit max_output_tokens while emitting a function_call
                -- must surface as length, not tool_call (the tool args may be truncated).
                test.eq(openai_mapper.map_finish_reason("incomplete", true, "max_output_tokens"), "length")
                test.eq(openai_mapper.map_finish_reason("incomplete", true, "content_filter"), "filtered")
            end)
        end)

        describe("Token Usage Mapping", function()
            it("should map standard token usage (input_tokens / output_tokens)", function()
                local usage = {
                    input_tokens = 100,
                    output_tokens = 50,
                    total_tokens = 150
                }

                local tokens = openai_mapper.map_tokens(usage)

                test.eq(tokens.prompt_tokens, 100)
                test.eq(tokens.completion_tokens, 50)
                test.eq(tokens.total_tokens, 150)
                test.eq(tokens.cache_creation_input_tokens, 0)
                test.eq(tokens.cache_read_input_tokens, 0)
                test.eq(tokens.thinking_tokens, 0)
            end)

            it("should map reasoning tokens from output_tokens_details", function()
                local usage = {
                    input_tokens = 100,
                    output_tokens = 80,
                    total_tokens = 200,
                    output_tokens_details = {
                        reasoning_tokens = 20
                    }
                }

                local tokens = openai_mapper.map_tokens(usage)

                test.eq(tokens.thinking_tokens, 20)
                test.eq(tokens.prompt_tokens, 100)
                test.eq(tokens.completion_tokens, 80)
                test.eq(tokens.total_tokens, 200)
            end)

            it("should map cache tokens from input_tokens_details", function()
                local usage = {
                    input_tokens = 100,
                    output_tokens = 50,
                    total_tokens = 150,
                    input_tokens_details = {
                        cached_tokens = 30
                    }
                }

                local tokens = openai_mapper.map_tokens(usage)

                test.eq(tokens.cache_read_input_tokens, 30)
                test.eq(tokens.cache_creation_input_tokens, 70)
                test.eq(tokens.prompt_tokens, 70) -- adjusted: input_tokens minus cached
                test.eq(tokens.completion_tokens, 50)
            end)

            it("should handle nil usage", function()
                local tokens = openai_mapper.map_tokens(nil)

                test.is_nil(tokens)
            end)

            it("should handle partial usage data", function()
                local usage = {
                    input_tokens = 50
                    -- Missing other fields
                }

                local tokens = openai_mapper.map_tokens(usage)

                test.eq(tokens.prompt_tokens, 50)
                test.eq(tokens.completion_tokens, 0)
                test.eq(tokens.total_tokens, 50)
                test.eq(tokens.thinking_tokens, 0)
            end)
        end)

        describe("Success Response Mapping", function()
            it("should map text-only response", function()
                local api_response = {
                    id = "resp_text",
                    status = "completed",
                    output = {
                        {
                            type = "message",
                            role = "assistant",
                            content = { { type = "output_text", text = "Hello, world!" } }
                        }
                    },
                    usage = {
                        input_tokens = 10,
                        output_tokens = 5,
                        total_tokens = 15
                    },
                    metadata = { request_id = "req_test123" }
                }

                local context = { tool_name_map = {} }
                local response = openai_mapper.map_success_response(api_response, context) :: any

                test.is_true(response.success)
                test.eq(response.result.content, "Hello, world!")
                test.not_nil(response.result.tool_calls)
                test.eq(#response.result.tool_calls, 0)
                test.eq(response.finish_reason, "stop")
                test.eq(response.tokens.prompt_tokens, 10)
                test.eq(response.metadata.response_id, "resp_text")
            end)

            it("should map tool call response", function()
                local api_response = {
                    id = "resp_tool",
                    status = "completed",
                    output = {
                        {
                            type = "message",
                            role = "assistant",
                            content = { { type = "output_text", text = "I'll help with that." } }
                        },
                        {
                            type = "function_call",
                            call_id = "call_123",
                            name = "calculate",
                            arguments = '{"expression": "2+2"}'
                        }
                    },
                    usage = {
                        input_tokens = 20,
                        output_tokens = 10,
                        total_tokens = 30
                    },
                    metadata = { request_id = "req_tool123" }
                }

                local context = {
                    tool_name_map = {
                        ["calculate"] = { name = "calculate" }
                    }
                }

                local response = openai_mapper.map_success_response(api_response, context) :: any

                test.is_true(response.success)
                test.eq(response.result.content, "I'll help with that.")
                local tc = response.result.tool_calls :: any
                test.eq(#tc, 1)
                test.eq(tc[1].name, "calculate")
                test.eq(response.finish_reason, "tool_call")
            end)

            it("should handle refusal responses", function()
                local api_response = {
                    id = "resp_refusal",
                    status = "completed",
                    output = {
                        {
                            type = "message",
                            role = "assistant",
                            content = {
                                { type = "refusal", refusal = "I cannot assist with that request." }
                            }
                        }
                    },
                    usage = {
                        input_tokens = 15,
                        output_tokens = 8,
                        total_tokens = 23
                    },
                    metadata = { request_id = "req_refusal123" }
                }

                local err_builder = output.errors.generate("openai")
                    :classifier(openai_mapper.classify_error)
                local context = { tool_name_map = {}, err = err_builder }
                local response, err = openai_mapper.map_success_response(api_response, context)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Invalid")
                test.contains(tostring(err:message()), "refused")
                test.contains(tostring(err:message()), "I cannot assist with that request.")
            end)

            it("should collect reasoning summary into metadata.thinking", function()
                local api_response = {
                    id = "resp_reason",
                    status = "completed",
                    output = {
                        {
                            type = "reasoning",
                            id = "rs_1",
                            summary = {
                                { type = "summary_text", text = "step1" },
                                { type = "summary_text", text = " step2" }
                            }
                        },
                        {
                            type = "message",
                            role = "assistant",
                            content = { { type = "output_text", text = "ok" } }
                        }
                    },
                    usage = { input_tokens = 1, output_tokens = 1, output_tokens_details = { reasoning_tokens = 42 } }
                }

                local response = openai_mapper.map_success_response(api_response, { tool_name_map = {} }) :: any
                test.eq(response.metadata.thinking, "step1 step2")
                test.eq(response.tokens.thinking_tokens, 42)
            end)
        end)

        describe("Error Classification", function()
            -- classify_error is a pure function that returns (kind, message, details).
            -- Wrapping into an `errors` object happens in the fluent builder.

            it("should classify errors by status code", function()
                local test_cases = {
                    { status = 401, kind = "authentication_error",   message = "Invalid API key" },
                    { status = 404, kind = "model_error",            message = "Model not found" },
                    { status = 429, kind = "rate_limit_exceeded",    message = "Rate limit exceeded" },
                    { status = 500, kind = "server_error",           message = "Internal server error" }
                }

                for _, case in ipairs(test_cases) do
                    local k, m, d = openai_mapper.classify_error({
                        status_code = case.status,
                        message = case.message
                    })

                    test.eq(k, case.kind)
                    test.eq(m, case.message)
                    test.not_nil(d)
                    test.eq(d.status_code, case.status)
                end
            end)

            it("should classify errors by message content", function()
                local test_cases = {
                    { message = "context length exceeded",            kind = "context_length_exceeded" },
                    { message = "maximum context length is 4096 tokens", kind = "context_length_exceeded" },
                    { message = "string too long",                    kind = "context_length_exceeded" },
                    { message = "content policy violation",           kind = "content_filtered" },
                    { message = "content filter triggered",           kind = "content_filtered" }
                }

                for _, case in ipairs(test_cases) do
                    local k = openai_mapper.classify_error({
                        status_code = 400,
                        message = case.message
                    })

                    test.eq(k, case.kind)
                end
            end)

            it("should handle nil error", function()
                local k, m = openai_mapper.classify_error(nil)
                test.eq(k, "server_error")
                test.eq(m, "Unknown OpenAI error")
            end)

            it("should expose status_code, code, type, param in details", function()
                local _, _, d = openai_mapper.classify_error({
                    status_code = 400,
                    message = "Bad",
                    code = "invalid_param",
                    type = "invalid_request_error",
                    param = "model"
                })
                test.eq(d.status_code, 400)
                test.eq(d.code, "invalid_param")
                test.eq(d.type, "invalid_request_error")
                test.eq(d.param, "model")
            end)

            it("should expose request_id and organization from metadata", function()
                local _, _, d = openai_mapper.classify_error({
                    status_code = 401,
                    message = "Bad",
                    metadata = { request_id = "req_x", organization = "org_y" }
                })
                test.eq(d.request_id, "req_x")
                test.eq(d.organization, "org_y")
            end)
        end)

        describe("Error Builder Integration", function()
            -- End-to-end through output.errors.<op>(...) builder, verifying that
            -- (kind, retryable, details with provider/operation/model) all flow through.

            it("should build a structured error with provider context for HTTP errors", function()
                local err = output.errors.generate("openai")
                    :with_contract({ model = "gpt-5.4" })
                    :classifier(openai_mapper.classify_error)
                    :from({ status_code = 401, message = "Invalid API key" })
                    :build()

                test.eq(err:kind(), "PermissionDenied")
                test.eq(err:message(), "Invalid API key")
                test.eq(err:retryable(), false)
                local d = err:details() :: any
                test.eq(d.provider, "openai")
                test.eq(d.operation, "generate")
                test.eq(d.model, "gpt-5.4")
                test.eq(d.status_code, 401)
            end)

            it("should build a structured error with explicit kind/message", function()
                local err = output.errors.generate("openai")
                    :with_contract({ model = "gpt-5.4" })
                    :kind(output.ERROR_TYPE.INVALID_REQUEST)
                    :message("Model is required")
                    :build()

                test.eq(err:kind(), "Invalid")
                test.eq(err:message(), "Model is required")
                local d = err:details() :: any
                test.eq(d.provider, "openai")
                test.eq(d.operation, "generate")
            end)

            it("should mark 429 as retryable through the builder", function()
                local err = output.errors.generate("openai")
                    :classifier(openai_mapper.classify_error)
                    :from({ status_code = 429, message = "Rate limited" })
                    :build()
                test.eq(err:kind(), "RateLimited")
                test.eq(err:retryable(), true)
            end)

            it("should reset per-call state between :build() calls", function()
                local err = output.errors.generate("openai"):with_contract({ model = "m" })

                local e1 = err:kind(output.ERROR_TYPE.INVALID_REQUEST):message("first"):build()
                test.eq(e1:message(), "first")
                test.eq(e1:kind(), "Invalid")

                local e2 = err:kind(output.ERROR_TYPE.SERVER_ERROR):message("second"):build()
                test.eq(e2:message(), "second")
                test.eq(e2:kind(), "Unavailable")
            end)
        end)

        describe("Finish Reason Preservation", function()
            it("should preserve LENGTH finish_reason when response is incomplete with tool_calls", function()
                -- Responses API: status=incomplete + function_call items still surfaces as length, not tool_call
                local api_response = {
                    id = "resp_length",
                    status = "incomplete",
                    incomplete_details = { reason = "max_output_tokens" },
                    output = {
                        {
                            type = "message",
                            role = "assistant",
                            content = { { type = "output_text", text = "I will call..." } }
                        },
                        {
                            type = "function_call",
                            call_id = "call_1",
                            name = "test_tool",
                            arguments = "{}"
                        }
                    },
                    usage = { input_tokens = 100, output_tokens = 4096, total_tokens = 4196 }
                }

                local result = openai_mapper.map_success_response(api_response, { tool_name_map = {} })
                test.eq(result.finish_reason, "length")
            end)

            it("should map status=completed with function_call items to TOOL_CALL", function()
                local api_response = {
                    id = "resp_tc",
                    status = "completed",
                    output = {
                        {
                            type = "function_call",
                            call_id = "call_1",
                            name = "test_tool",
                            arguments = "{}"
                        }
                    },
                    usage = { input_tokens = 50, output_tokens = 100, total_tokens = 150 }
                }

                local result = openai_mapper.map_success_response(api_response, { tool_name_map = {} })
                test.eq(result.finish_reason, "tool_call")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
