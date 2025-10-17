local mapper = require("google_mapper")
local tests = require("test")

local function define_tests()
    describe("Google Mapper", function()

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

                local google_messages, system_instructions = mapper.map_messages(contract_messages)

                expect(#google_messages).to_equal(2)
                expect(#system_instructions).to_equal(1)
                expect(system_instructions[1].text).to_equal("You are a helpful assistant")
                expect(google_messages[1].role).to_equal("user")
                expect(google_messages[1].parts[1].text).to_equal("Hello")
                expect(google_messages[2].role).to_equal("model")
                expect(google_messages[2].parts.text).to_equal("Hi there!")
            end)

            it("should convert string content to parts format", function()
                local contract_messages = {
                    {
                        role = "user",
                        content = "Simple string message"
                    }
                }

                local google_messages, system_instructions = mapper.map_messages(contract_messages)

                expect(#google_messages).to_equal(1)
                expect(google_messages[1].role).to_equal("user")
                expect(google_messages[1].parts[1].text).to_equal("Simple string message")
            end)

            it("should handle developer role as system instruction", function()
                local contract_messages = {
                    {
                        role = "developer",
                        content = {{ type = "text", text = "Debug mode enabled" }}
                    },
                    {
                        role = "user",
                        content = {{ type = "text", text = "Test" }}
                    }
                }

                local google_messages, system_instructions = mapper.map_messages(contract_messages)

                expect(#system_instructions).to_equal(1)
                expect(system_instructions[1].text).to_equal("Debug mode enabled")
                expect(#google_messages).to_equal(1)
                expect(google_messages[1].role).to_equal("user")
            end)

            it("should convert image content to Google format (URL)", function()
                local contract_messages = {
                    {
                        role = "user",
                        content = {
                            { type = "text", text = "What's in this image?" },
                            {
                                type = "image",
                                source = {
                                    type = "url",
                                    url = "https://example.com/image.jpg",
                                    mime_type = "image/jpeg"
                                }
                            }
                        }
                    }
                }

                local google_messages, _ = mapper.map_messages(contract_messages)

                expect(#google_messages).to_equal(1)
                expect(google_messages[1].parts[1].text).to_equal("What's in this image?")
                expect(google_messages[1].parts[2].fileData).not_to_be_nil()
                expect(google_messages[1].parts[2].fileData.fileUri).to_equal("https://example.com/image.jpg")
            end)

            it("should convert image content to Google format (base64)", function()
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

                local google_messages, _ = mapper.map_messages(contract_messages)

                expect(#google_messages).to_equal(1)
                expect(google_messages[1].parts[1].inlineData).not_to_be_nil()
                expect(google_messages[1].parts[1].inlineData.mimeType).to_equal("image/jpeg")
                expect(google_messages[1].parts[1].inlineData.data).to_contain("iVBORw0KGgo")
            end)

            it("should convert function_call messages to model with functionCall", function()
                local contract_messages = {
                    {
                        role = "function_call",
                        function_call = {
                            name = "get_weather",
                            arguments = { location = "New York" }
                        }
                    }
                }

                local google_messages, _ = mapper.map_messages(contract_messages)

                expect(#google_messages).to_equal(1)
                expect(google_messages[1].role).to_equal("model")
                expect(google_messages[1].parts.functionCall).not_to_be_nil()
                expect(google_messages[1].parts.functionCall.name).to_equal("get_weather")
                expect(google_messages[1].parts.functionCall.args.location).to_equal("New York")
            end)

            it("should handle string arguments in function_call", function()
                local contract_messages = {
                    {
                        role = "function_call",
                        function_call = {
                            name = "test_func",
                            arguments = '{"key": "value"}'
                        }
                    }
                }

                local google_messages, _ = mapper.map_messages(contract_messages)

                expect(#google_messages).to_equal(1)
                expect(google_messages[1].parts.functionCall.args.key).to_equal("value")
            end)

            it("should convert function_result to user with functionResponse", function()
                local contract_messages = {
                    {
                        role = "function_result",
                        name = "get_weather",
                        content = {{ type = "text", text = "The weather is sunny" }}
                    }
                }

                local google_messages, _ = mapper.map_messages(contract_messages)

                expect(#google_messages).to_equal(1)
                expect(google_messages[1].role).to_equal("user")
                expect(google_messages[1].parts[1].functionResponse).not_to_be_nil()
                expect(google_messages[1].parts[1].functionResponse.name).to_equal("get_weather")
                expect(google_messages[1].parts[1].functionResponse.response.content).to_equal("The weather is sunny")
            end)

            it("should handle string content in function_result", function()
                local contract_messages = {
                    {
                        role = "function_result",
                        name = "test_func",
                        content = "Simple string result"
                    }
                }

                local google_messages, _ = mapper.map_messages(contract_messages)

                expect(#google_messages).to_equal(1)
                expect(google_messages[1].parts[1].functionResponse.response.content).to_equal("Simple string result")
            end)

            it("should handle JSON string content in function_result", function()
                local contract_messages = {
                    {
                        role = "function_result",
                        name = "test_func",
                        content = '{"result": "success", "value": 42}'
                    }
                }

                local google_messages, _ = mapper.map_messages(contract_messages)

                expect(#google_messages).to_equal(1)
                local response_content = google_messages[1].parts[1].functionResponse.response.content
                expect(response_content.result).to_equal("success")
                expect(response_content.value).to_equal(42)
            end)

            it("should handle table content in function_result", function()
                local contract_messages = {
                    {
                        role = "function_result",
                        name = "test_func",
                        content = { status = "ok", count = 5 }
                    }
                }

                local google_messages, _ = mapper.map_messages(contract_messages)

                expect(#google_messages).to_equal(1)
                local response_content = google_messages[1].parts[1].functionResponse.response.content
                expect(response_content.status).to_equal("ok")
                expect(response_content.count).to_equal(5)
            end)

            it("should handle nil content in function_result", function()
                local contract_messages = {
                    {
                        role = "function_result",
                        name = "test_func",
                        content = nil
                    }
                }

                local google_messages, _ = mapper.map_messages(contract_messages)

                expect(#google_messages).to_equal(1)
                expect(google_messages[1].parts[1].functionResponse.response.content).to_equal("")
            end)

            it("should handle empty string content", function()
                local contract_messages = {
                    {
                        role = "user",
                        content = ""
                    }
                }

                local google_messages, _ = mapper.map_messages(contract_messages)

                expect(#google_messages).to_equal(1)
                expect(google_messages[1].parts[1].text).to_equal("")
            end)

            it("should skip assistant messages with empty content", function()
                local contract_messages = {
                    {
                        role = "assistant",
                        content = ""
                    },
                    {
                        role = "user",
                        content = "Hello"
                    }
                }

                local google_messages, _ = mapper.map_messages(contract_messages)

                expect(#google_messages).to_equal(1)
                expect(google_messages[1].role).to_equal("user")
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

                local google_messages, _ = mapper.map_messages(contract_messages)

                expect(#google_messages).to_equal(1)
                expect(google_messages[1].role).to_equal("user")
                expect(google_messages[1].parts[1].text).to_equal("This should be kept")
            end)

            it("should handle nested text structures", function()
                local contract_messages = {
                    {
                        role = "user",
                        content = {
                            {
                                type = "text",
                                text = { text = { text = "Deeply nested" } }
                            }
                        }
                    }
                }

                local google_messages, _ = mapper.map_messages(contract_messages)

                expect(#google_messages).to_equal(1)
                expect(google_messages[1].parts[1].text).to_equal("Deeply nested")
            end)

            it("should clear metadata from messages", function()
                local contract_messages = {
                    {
                        role = "user",
                        content = "Test",
                        metadata = { some = "data" }
                    }
                }

                local google_messages, _ = mapper.map_messages(contract_messages)

                expect(#google_messages).to_equal(1)
                expect(google_messages[1].metadata).to_be_nil()
            end)
        end)

        describe("Tool Mapping", function()
            it("should map contract tools to Google format", function()
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

                local google_tools = mapper.map_tools(contract_tools)

                expect(#google_tools).to_equal(2)
                expect(google_tools[1].name).to_equal("get_weather")
                expect(google_tools[1].description).to_equal("Get weather information")
                expect(google_tools[1].parameters.type).to_equal("object")
                expect(google_tools[1].parameters.properties.location.type).to_equal("string")
                expect(google_tools[1].parameters.required[1]).to_equal("location")

                expect(google_tools[2].name).to_equal("calculate")
                expect(google_tools[2].description).to_equal("Perform calculations")
            end)

            it("should filter out multipleOf from schema", function()
                local contract_tools = {
                    {
                        name = "test_tool",
                        description = "Test",
                        schema = {
                            type = "object",
                            properties = {
                                count = {
                                    type = "number",
                                    multipleOf = 5
                                }
                            }
                        }
                    }
                }

                local google_tools = mapper.map_tools(contract_tools)

                expect(#google_tools).to_equal(1)
                expect(google_tools[1].parameters.properties.count.multipleOf).to_be_nil()
                expect(google_tools[1].parameters.properties.count.type).to_equal("number")
            end)

            it("should filter out examples from schema", function()
                local contract_tools = {
                    {
                        name = "test_tool",
                        description = "Test",
                        schema = {
                            type = "object",
                            examples = { "example1", "example2" },
                            properties = {
                                value = { type = "string" }
                            }
                        }
                    }
                }

                local google_tools = mapper.map_tools(contract_tools)

                expect(#google_tools).to_equal(1)
                expect(google_tools[1].parameters.examples).to_be_nil()
                expect(google_tools[1].parameters.properties.value.type).to_equal("string")
            end)

            it("should recursively filter unsupported properties", function()
                local contract_tools = {
                    {
                        name = "test_tool",
                        description = "Test",
                        schema = {
                            type = "object",
                            properties = {
                                nested = {
                                    type = "object",
                                    multipleOf = 10,
                                    properties = {
                                        inner = {
                                            type = "number",
                                            multipleOf = 2
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                local google_tools = mapper.map_tools(contract_tools)

                expect(#google_tools).to_equal(1)
                expect(google_tools[1].parameters.properties.nested.multipleOf).to_be_nil()
                expect(google_tools[1].parameters.properties.nested.properties.inner.multipleOf).to_be_nil()
                expect(google_tools[1].parameters.properties.nested.properties.inner.type).to_equal("number")
            end)

            it("should handle empty tools array", function()
                local google_tools = mapper.map_tools({})

                expect(google_tools).to_be_nil()
            end)

            it("should handle nil tools", function()
                local google_tools = mapper.map_tools(nil)

                expect(google_tools).to_be_nil()
            end)

            it("should skip tools with missing required fields", function()
                local contract_tools = {
                    {
                        name = "valid_tool",
                        description = "Valid tool",
                        schema = { type = "object" }
                    },
                    {
                        name = "invalid_tool_1"
                        -- Missing description and schema
                    },
                    {
                        name = "invalid_tool_2",
                        description = "No schema"
                        -- Missing schema
                    },
                    {
                        description = "No name",
                        schema = { type = "object" }
                        -- Missing name
                    }
                }

                local google_tools = mapper.map_tools(contract_tools)

                expect(#google_tools).to_equal(1)
                expect(google_tools[1].name).to_equal("valid_tool")
            end)

            it("should preserve all supported schema properties", function()
                local contract_tools = {
                    {
                        name = "complex_tool",
                        description = "Complex tool",
                        schema = {
                            type = "object",
                            properties = {
                                text = {
                                    type = "string",
                                    minLength = 1,
                                    maxLength = 100,
                                    pattern = "^[a-z]+$"
                                },
                                number = {
                                    type = "number",
                                    minimum = 0,
                                    maximum = 100,
                                    exclusiveMinimum = true
                                },
                                array = {
                                    type = "array",
                                    items = { type = "string" },
                                    minItems = 1,
                                    maxItems = 10,
                                    uniqueItems = true
                                }
                            },
                            required = { "text" },
                            additionalProperties = false
                        }
                    }
                }

                local google_tools = mapper.map_tools(contract_tools)

                expect(#google_tools).to_equal(1)
                local params = google_tools[1].parameters

                expect(params.properties.text.minLength).to_equal(1)
                expect(params.properties.text.maxLength).to_equal(100)
                expect(params.properties.text.pattern).to_equal("^[a-z]+$")

                expect(params.properties.number.minimum).to_equal(0)
                expect(params.properties.number.maximum).to_equal(100)
                expect(params.properties.number.exclusiveMinimum).to_be_true()

                expect(params.properties.array.minItems).to_equal(1)
                expect(params.properties.array.maxItems).to_equal(10)
                expect(params.properties.array.uniqueItems).to_be_true()

                expect(params.required[1]).to_equal("text")
                expect(params.additionalProperties).to_be_nil() -- Google does not support this, so should be filtered out
            end)

            it("should handle schema with nested objects", function()
                local contract_tools = {
                    {
                        name = "nested_tool",
                        description = "Nested structure",
                        schema = {
                            type = "object",
                            properties = {
                                address = {
                                    type = "object",
                                    properties = {
                                        street = { type = "string" },
                                        city = { type = "string" },
                                        coordinates = {
                                            type = "object",
                                            properties = {
                                                lat = { type = "number" },
                                                lng = { type = "number" }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                local google_tools = mapper.map_tools(contract_tools)

                expect(#google_tools).to_equal(1)
                local address = google_tools[1].parameters.properties.address
                expect(address.type).to_equal("object")
                expect(address.properties.street.type).to_equal("string")
                expect(address.properties.coordinates.properties.lat.type).to_equal("number")
            end)
        end)

        describe("Tool Config Mapping", function()
            local test_tools = {
                { name = "get_weather" },
                { name = "calculate" }
            }

            it("should map auto tool choice", function()
                local config, error = mapper.map_tool_config("auto", test_tools)

                expect(error).to_be_nil()
                expect(config.mode).to_equal("AUTO")
            end)

            it("should map nil tool choice to AUTO", function()
                local config, error = mapper.map_tool_config(nil, test_tools)

                expect(error).to_be_nil()
                expect(config.mode).to_equal("AUTO")
            end)

            it("should map none tool choice", function()
                local config, error = mapper.map_tool_config("none", test_tools)

                expect(error).to_be_nil()
                expect(config.mode).to_equal("NONE")
            end)

            it("should map any tool choice to AUTO", function()
                local config, error = mapper.map_tool_config("any", test_tools)

                expect(error).to_be_nil()
                expect(config.mode).to_equal("AUTO")
            end)

            it("should map specific tool name", function()
                local config, error = mapper.map_tool_config("get_weather", test_tools)

                expect(error).to_be_nil()
                expect(config.mode).to_equal("ANY")
                expect(config.allowedFunctionNames).not_to_be_nil()
                expect(#config.allowedFunctionNames).to_equal(1)
                expect(config.allowedFunctionNames[1]).to_equal("get_weather")
            end)

            it("should error on non-existent tool", function()
                local config, error = mapper.map_tool_config("nonexistent_tool", test_tools)

                expect(config).to_be_nil()
                expect(error).not_to_be_nil()
                expect(error).to_contain("not found")
                expect(error).to_contain("nonexistent_tool")
            end)

            it("should handle empty tools array with specific tool name", function()
                local config, error = mapper.map_tool_config("some_tool", {})

                expect(config).to_be_nil()
                expect(error).not_to_be_nil()
                expect(error).to_contain("not found")
            end)

            it("should handle nil tools array with specific tool name", function()
                local config, error = mapper.map_tool_config("some_tool", nil)

                expect(config).to_be_nil()
                expect(error).not_to_be_nil()
                expect(error).to_contain("not found")
            end)

            it("should be case-sensitive for tool names", function()
                local config, error = mapper.map_tool_config("Get_Weather", test_tools)

                expect(config).to_be_nil()
                expect(error).not_to_be_nil()
                expect(error).to_contain("not found")
            end)

            it("should handle tool name with exact match", function()
                local tools_with_similar_names = {
                    { name = "get_weather" },
                    { name = "get_weather_forecast" }
                }

                local config, error = mapper.map_tool_config("get_weather", tools_with_similar_names)

                expect(error).to_be_nil()
                expect(config.mode).to_equal("ANY")
                expect(#config.allowedFunctionNames).to_equal(1)
                expect(config.allowedFunctionNames[1]).to_equal("get_weather")
            end)

            it("should return AUTO for empty string", function()
                local config, error = mapper.map_tool_config("", test_tools)

                expect(error).to_be_nil()
                expect(config.mode).to_equal("AUTO")
            end)
        end)

        describe("Options Mapping", function()
            it("should map standard options", function()
                local contract_options = {
                    temperature = 0.7,
                    max_tokens = 150,
                    top_p = 0.9,
                    seed = 42,
                    presence_penalty = 0.3,
                    frequency_penalty = 0.5,
                    stop_sequences = {"STOP", "END"}
                }

                local google_options = mapper.map_options(contract_options)

                expect(google_options.temperature).to_equal(0.7)
                expect(google_options.maxOutputTokens).to_equal(150)
                expect(google_options.topP).to_equal(0.9)
                expect(google_options.seed).to_equal(42)
                expect(google_options.presencePenalty).to_equal(0.3)
                expect(google_options.frequencyPenalty).to_equal(0.5)
                expect(google_options.stopSequences).not_to_be_nil()
                expect(#google_options.stopSequences).to_equal(2)
                expect(google_options.stopSequences[1]).to_equal("STOP")
                expect(google_options.stopSequences[2]).to_equal("END")
            end)

            it("should handle nil options", function()
                local google_options = mapper.map_options(nil)

                expect(next(google_options)).to_be_nil()
            end)

            it("should handle empty options", function()
                local google_options = mapper.map_options({})

                expect(next(google_options)).to_be_nil()
            end)

            it("should handle partial options", function()
                local contract_options = {
                    temperature = 0.5,
                    max_tokens = 100
                }

                local google_options = mapper.map_options(contract_options)

                expect(google_options.temperature).to_equal(0.5)
                expect(google_options.maxOutputTokens).to_equal(100)
                expect(google_options.topP).to_be_nil()
                expect(google_options.seed).to_be_nil()
            end)

            it("should handle temperature of 0", function()
                local contract_options = {
                    temperature = 0
                }

                local google_options = mapper.map_options(contract_options)

                expect(google_options.temperature).to_equal(0)
            end)

            it("should handle max temperature", function()
                local contract_options = {
                    temperature = 2.0
                }

                local google_options = mapper.map_options(contract_options)

                expect(google_options.temperature).to_equal(2.0)
            end)

            it("should handle top_p edge values", function()
                local test_cases = {
                    { top_p = 0, expected = 0 },
                    { top_p = 0.5, expected = 0.5 },
                    { top_p = 1.0, expected = 1.0 }
                }

                for _, case in ipairs(test_cases) do
                    local contract_options = { top_p = case.top_p }
                    local google_options = mapper.map_options(contract_options)
                    expect(google_options.topP).to_equal(case.expected)
                end
            end)

            it("should handle penalty values", function()
                local contract_options = {
                    presence_penalty = -2.0,
                    frequency_penalty = 2.0
                }

                local google_options = mapper.map_options(contract_options)

                expect(google_options.presencePenalty).to_equal(-2.0)
                expect(google_options.frequencyPenalty).to_equal(2.0)
            end)

            it("should handle empty stop_sequences array", function()
                local contract_options = {
                    stop_sequences = {}
                }

                local google_options = mapper.map_options(contract_options)

                expect(google_options.stopSequences).not_to_be_nil()
                expect(#google_options.stopSequences).to_equal(0)
            end)

            it("should handle single stop sequence", function()
                local contract_options = {
                    stop_sequences = {"STOP"}
                }

                local google_options = mapper.map_options(contract_options)

                expect(#google_options.stopSequences).to_equal(1)
                expect(google_options.stopSequences[1]).to_equal("STOP")
            end)

            it("should preserve nil values for unset options", function()
                local contract_options = {
                    temperature = 0.7
                    -- Other options not set
                }

                local google_options = mapper.map_options(contract_options)

                expect(google_options.temperature).to_equal(0.7)
                expect(google_options.maxOutputTokens).to_be_nil()
                expect(google_options.topP).to_be_nil()
                expect(google_options.seed).to_be_nil()
                expect(google_options.presencePenalty).to_be_nil()
                expect(google_options.frequencyPenalty).to_be_nil()
                expect(google_options.stopSequences).to_be_nil()
            end)

            it("should not include unsupported options", function()
                local contract_options = {
                    temperature = 0.7,
                    unsupported_option = "value",
                    another_unsupported = 123
                }

                local google_options = mapper.map_options(contract_options)

                expect(google_options.temperature).to_equal(0.7)
                expect(google_options.unsupported_option).to_be_nil()
                expect(google_options.another_unsupported).to_be_nil()
            end)

            it("should handle all options at once", function()
                local contract_options = {
                    temperature = 0.8,
                    max_tokens = 200,
                    top_p = 0.95,
                    seed = 999,
                    presence_penalty = 0.1,
                    frequency_penalty = 0.2,
                    stop_sequences = {"END", "FINISH", "DONE"}
                }

                local google_options = mapper.map_options(contract_options)

                expect(google_options.temperature).to_equal(0.8)
                expect(google_options.maxOutputTokens).to_equal(200)
                expect(google_options.topP).to_equal(0.95)
                expect(google_options.seed).to_equal(999)
                expect(google_options.presencePenalty).to_equal(0.1)
                expect(google_options.frequencyPenalty).to_equal(0.2)
                expect(#google_options.stopSequences).to_equal(3)
            end)
        end)

        describe("Tool Calls Response Mapping", function()
            it("should map Google function calls to contract format", function()
                local google_function_calls = {
                    {
                        name = "get_weather",
                        args = { location = "New York", units = "celsius" }
                    },
                    {
                        name = "calculate",
                        args = { expression = "2+2" }
                    }
                }

                local contract_tool_calls = mapper.map_tool_calls(google_function_calls)

                expect(#contract_tool_calls).to_equal(2)

                expect(contract_tool_calls[1].name).to_equal("get_weather")
                expect(contract_tool_calls[1].arguments.location).to_equal("New York")
                expect(contract_tool_calls[1].arguments.units).to_equal("celsius")
                expect(contract_tool_calls[1].id).not_to_be_nil()
                expect(contract_tool_calls[1].id).to_contain("get_weather_")

                expect(contract_tool_calls[2].name).to_equal("calculate")
                expect(contract_tool_calls[2].arguments.expression).to_equal("2+2")
                expect(contract_tool_calls[2].id).not_to_be_nil()
                expect(contract_tool_calls[2].id).to_contain("calculate_")
            end)

            it("should generate unique IDs for each tool call", function()
                local google_function_calls = {
                    { name = "tool1", args = {} },
                    { name = "tool2", args = {} },
                    { name = "tool3", args = {} }
                }

                local contract_tool_calls = mapper.map_tool_calls(google_function_calls)

                expect(#contract_tool_calls).to_equal(3)

                local ids = {}
                for _, call in ipairs(contract_tool_calls) do
                    expect(ids[call.id]).to_be_nil() -- ID should be unique
                    ids[call.id] = true
                end
            end)

            it("should handle empty args", function()
                local google_function_calls = {
                    {
                        name = "no_args_tool",
                        args = {}
                    }
                }

                local contract_tool_calls = mapper.map_tool_calls(google_function_calls)

                expect(#contract_tool_calls).to_equal(1)
                expect(contract_tool_calls[1].name).to_equal("no_args_tool")
                expect(contract_tool_calls[1].arguments).not_to_be_nil()
                expect(next(contract_tool_calls[1].arguments)).to_be_nil()
            end)

            it("should handle nil args", function()
                local google_function_calls = {
                    {
                        name = "nil_args_tool",
                        args = nil
                    }
                }

                local contract_tool_calls = mapper.map_tool_calls(google_function_calls)

                expect(#contract_tool_calls).to_equal(1)
                expect(contract_tool_calls[1].name).to_equal("nil_args_tool")
                expect(contract_tool_calls[1].arguments).not_to_be_nil()
                expect(next(contract_tool_calls[1].arguments)).to_be_nil()
            end)

            it("should handle complex nested arguments", function()
                local google_function_calls = {
                    {
                        name = "complex_tool",
                        args = {
                            simple = "value",
                            nested = {
                                key1 = "value1",
                                key2 = {
                                    deep = "nested"
                                }
                            },
                            array = { "item1", "item2", "item3" }
                        }
                    }
                }

                local contract_tool_calls = mapper.map_tool_calls(google_function_calls)

                expect(#contract_tool_calls).to_equal(1)
                expect(contract_tool_calls[1].arguments.simple).to_equal("value")
                expect(contract_tool_calls[1].arguments.nested.key1).to_equal("value1")
                expect(contract_tool_calls[1].arguments.nested.key2.deep).to_equal("nested")
                expect(#contract_tool_calls[1].arguments.array).to_equal(3)
                expect(contract_tool_calls[1].arguments.array[1]).to_equal("item1")
            end)

            it("should handle nil function calls", function()
                local contract_tool_calls = mapper.map_tool_calls(nil)

                expect(#contract_tool_calls).to_equal(0)
            end)

            it("should handle empty function calls array", function()
                local contract_tool_calls = mapper.map_tool_calls({})

                expect(#contract_tool_calls).to_equal(0)
            end)

            it("should handle function call with only name", function()
                local google_function_calls = {
                    {
                        name = "simple_tool"
                        -- No args field
                    }
                }

                local contract_tool_calls = mapper.map_tool_calls(google_function_calls)

                expect(#contract_tool_calls).to_equal(1)
                expect(contract_tool_calls[1].name).to_equal("simple_tool")
                expect(contract_tool_calls[1].arguments).not_to_be_nil()
                expect(next(contract_tool_calls[1].arguments)).to_be_nil()
            end)

            it("should handle various argument types", function()
                local google_function_calls = {
                    {
                        name = "typed_args",
                        args = {
                            string_arg = "text",
                            number_arg = 42,
                            float_arg = 3.14,
                            bool_arg = true,
                            null_arg = nil,
                            array_arg = {1, 2, 3},
                            object_arg = { key = "value" }
                        }
                    }
                }

                local contract_tool_calls = mapper.map_tool_calls(google_function_calls)

                expect(#contract_tool_calls).to_equal(1)
                local args = contract_tool_calls[1].arguments
                expect(args.string_arg).to_equal("text")
                expect(args.number_arg).to_equal(42)
                expect(args.float_arg).to_equal(3.14)
                expect(args.bool_arg).to_be_true()
                expect(#args.array_arg).to_equal(3)
                expect(args.object_arg.key).to_equal("value")
            end)

            it("should generate ID with timestamp component", function()
                local google_function_calls = {
                    { name = "test_tool", args = {} }
                }

                local contract_tool_calls = mapper.map_tool_calls(google_function_calls)

                expect(#contract_tool_calls).to_equal(1)
                -- ID format: name_timestamp
                local id = contract_tool_calls[1].id
                expect(id).to_contain("test_tool_")
            end)

            it("should handle function call with missing name gracefully", function()
                local google_function_calls = {
                    {
                        args = { key = "value" }
                        -- Missing name
                    }
                }

                local contract_tool_calls = mapper.map_tool_calls(google_function_calls)

                expect(#contract_tool_calls).to_equal(1)
                expect(contract_tool_calls[1].id).to_contain("func_")
                expect(contract_tool_calls[1].arguments.key).to_equal("value")
            end)
        end)

        describe("Finish Reason Mapping", function()
            it("should map STOP to stop", function()
                local result = mapper.map_finish_reason("STOP")
                expect(result).to_equal("stop")
            end)

            it("should map MAX_TOKENS to length", function()
                local result = mapper.map_finish_reason("MAX_TOKENS")
                expect(result).to_equal("length")
            end)

            it("should map SAFETY to filtered", function()
                local result = mapper.map_finish_reason("SAFETY")
                expect(result).to_equal("filtered")
            end)

            it("should map RECITATION to filtered", function()
                local result = mapper.map_finish_reason("RECITATION")
                expect(result).to_equal("filtered")
            end)

            it("should map LANGUAGE to filtered", function()
                local result = mapper.map_finish_reason("LANGUAGE")
                expect(result).to_equal("filtered")
            end)

            it("should map BLOCKLIST to filtered", function()
                local result = mapper.map_finish_reason("BLOCKLIST")
                expect(result).to_equal("filtered")
            end)

            it("should map PROHIBITED_CONTENT to filtered", function()
                local result = mapper.map_finish_reason("PROHIBITED_CONTENT")
                expect(result).to_equal("filtered")
            end)

            it("should map SPII to filtered", function()
                local result = mapper.map_finish_reason("SPII")
                expect(result).to_equal("filtered")
            end)

            it("should map IMAGE_SAFETY to filtered", function()
                local result = mapper.map_finish_reason("IMAGE_SAFETY")
                expect(result).to_equal("filtered")
            end)

            it("should map MALFORMED_FUNCTION_CALL to error", function()
                local result = mapper.map_finish_reason("MALFORMED_FUNCTION_CALL")
                expect(result).to_equal("error")
            end)

            it("should map OTHER to error", function()
                local result = mapper.map_finish_reason("OTHER")
                expect(result).to_equal("error")
            end)

            it("should map unknown reason to error", function()
                local result = mapper.map_finish_reason("UNKNOWN_REASON")
                expect(result).to_equal("error")
            end)

            it("should map nil to error", function()
                local result = mapper.map_finish_reason(nil)
                expect(result).to_equal("error")
            end)

            it("should map empty string to error", function()
                local result = mapper.map_finish_reason("")
                expect(result).to_equal("error")
            end)

            it("should be case-sensitive", function()
                local result = mapper.map_finish_reason("stop")
                expect(result).to_equal("error")
            end)

            it("should map all content filter reasons consistently", function()
                local filter_reasons = {
                    "SAFETY",
                    "RECITATION",
                    "LANGUAGE",
                    "BLOCKLIST",
                    "PROHIBITED_CONTENT",
                    "SPII",
                    "IMAGE_SAFETY"
                }

                for _, reason in ipairs(filter_reasons) do
                    local result = mapper.map_finish_reason(reason)
                    expect(result).to_equal("filtered")
                end
            end)

            it("should handle all valid Google finish reasons", function()
                local test_cases = {
                    { google = "STOP", expected = "stop" },
                    { google = "MAX_TOKENS", expected = "length" },
                    { google = "SAFETY", expected = "filtered" },
                    { google = "RECITATION", expected = "filtered" },
                    { google = "LANGUAGE", expected = "filtered" },
                    { google = "BLOCKLIST", expected = "filtered" },
                    { google = "PROHIBITED_CONTENT", expected = "filtered" },
                    { google = "SPII", expected = "filtered" },
                    { google = "IMAGE_SAFETY", expected = "filtered" },
                    { google = "MALFORMED_FUNCTION_CALL", expected = "error" },
                    { google = "OTHER", expected = "error" }
                }

                for _, case in ipairs(test_cases) do
                    local result = mapper.map_finish_reason(case.google)
                    expect(result).to_equal(case.expected)
                end
            end)
        end)

        describe("Token Usage Mapping", function()
            it("should map standard token usage", function()
                local google_usage = {
                    promptTokenCount = 100,
                    candidatesTokenCount = 50,
                    totalTokenCount = 150
                }

                local contract_tokens = mapper.map_tokens(google_usage)

                expect(contract_tokens.prompt_tokens).to_equal(100)
                expect(contract_tokens.completion_tokens).to_equal(50)
                expect(contract_tokens.total_tokens).to_equal(150)
                expect(contract_tokens.cache_write_tokens).to_equal(0)
                expect(contract_tokens.cache_read_tokens).to_equal(0)
            end)

            it("should map thinking tokens", function()
                local google_usage = {
                    promptTokenCount = 100,
                    candidatesTokenCount = 80,
                    totalTokenCount = 200,
                    thoughtsTokenCount = 20
                }

                local contract_tokens = mapper.map_tokens(google_usage)

                expect(contract_tokens.thinking_tokens).to_equal(20)
                expect(contract_tokens.prompt_tokens).to_equal(100)
                expect(contract_tokens.completion_tokens).to_equal(80)
                expect(contract_tokens.total_tokens).to_equal(200)
            end)

            it("should map cache tokens", function()
                local google_usage = {
                    promptTokenCount = 100,
                    candidatesTokenCount = 50,
                    totalTokenCount = 150,
                    cachedContentTokenCount = 30
                }

                local contract_tokens = mapper.map_tokens(google_usage)

                expect(contract_tokens.cache_read_tokens).to_equal(30)
                expect(contract_tokens.cache_write_tokens).to_equal(70)
                expect(contract_tokens.prompt_tokens).to_equal(70)
                expect(contract_tokens.completion_tokens).to_equal(50)
            end)

            it("should handle nil usage", function()
                local contract_tokens = mapper.map_tokens(nil)

                expect(contract_tokens).to_be_nil()
            end)

            it("should handle partial usage data", function()
                local google_usage = {
                    promptTokenCount = 50
                    -- Missing other fields
                }

                local contract_tokens = mapper.map_tokens(google_usage)

                expect(contract_tokens.prompt_tokens).to_equal(50)
                expect(contract_tokens.completion_tokens).to_equal(0)
                expect(contract_tokens.total_tokens).to_equal(0)
                expect(contract_tokens.thinking_tokens).to_be_nil()
            end)

            it("should handle zero token counts", function()
                local google_usage = {
                    promptTokenCount = 0,
                    candidatesTokenCount = 0,
                    totalTokenCount = 0
                }

                local contract_tokens = mapper.map_tokens(google_usage)

                expect(contract_tokens.prompt_tokens).to_equal(0)
                expect(contract_tokens.completion_tokens).to_equal(0)
                expect(contract_tokens.total_tokens).to_equal(0)
            end)

            it("should calculate cache write tokens correctly", function()
                local google_usage = {
                    promptTokenCount = 200,
                    candidatesTokenCount = 50,
                    totalTokenCount = 250,
                    cachedContentTokenCount = 150
                }

                local contract_tokens = mapper.map_tokens(google_usage)

                expect(contract_tokens.cache_read_tokens).to_equal(150)
                expect(contract_tokens.cache_write_tokens).to_equal(50)
                expect(contract_tokens.prompt_tokens).to_equal(50)
            end)

            it("should handle cache tokens equal to prompt tokens", function()
                local google_usage = {
                    promptTokenCount = 100,
                    candidatesTokenCount = 50,
                    totalTokenCount = 150,
                    cachedContentTokenCount = 100
                }

                local contract_tokens = mapper.map_tokens(google_usage)

                expect(contract_tokens.cache_read_tokens).to_equal(100)
                expect(contract_tokens.cache_write_tokens).to_equal(0)
                expect(contract_tokens.prompt_tokens).to_equal(0)
            end)

            it("should handle all token types together", function()
                local google_usage = {
                    promptTokenCount = 200,
                    candidatesTokenCount = 100,
                    totalTokenCount = 350,
                    cachedContentTokenCount = 50,
                    thoughtsTokenCount = 25
                }

                local contract_tokens = mapper.map_tokens(google_usage)

                expect(contract_tokens.prompt_tokens).to_equal(150)
                expect(contract_tokens.completion_tokens).to_equal(100)
                expect(contract_tokens.total_tokens).to_equal(350)
                expect(contract_tokens.cache_read_tokens).to_equal(50)
                expect(contract_tokens.cache_write_tokens).to_equal(150)
                expect(contract_tokens.thinking_tokens).to_equal(25)
            end)

            it("should handle missing optional token fields", function()
                local google_usage = {
                    promptTokenCount = 100,
                    candidatesTokenCount = 50,
                    totalTokenCount = 150
                    -- No cachedContentTokenCount or thoughtsTokenCount
                }

                local contract_tokens = mapper.map_tokens(google_usage)

                expect(contract_tokens.cache_read_tokens).to_equal(0)
                expect(contract_tokens.cache_write_tokens).to_equal(0)
                expect(contract_tokens.thinking_tokens).to_be_nil()
            end)

            it("should default to 0 for missing core token fields", function()
                local google_usage = {}

                local contract_tokens = mapper.map_tokens(google_usage)

                expect(contract_tokens.prompt_tokens).to_equal(0)
                expect(contract_tokens.completion_tokens).to_equal(0)
                expect(contract_tokens.total_tokens).to_equal(0)
            end)

            it("should handle nil thinking tokens separately", function()
                local google_usage = {
                    promptTokenCount = 100,
                    candidatesTokenCount = 50,
                    totalTokenCount = 150,
                    thoughtsTokenCount = nil
                }

                local contract_tokens = mapper.map_tokens(google_usage)

                expect(contract_tokens.thinking_tokens).to_be_nil()
                expect(contract_tokens.prompt_tokens).to_equal(100)
            end)

            it("should handle zero thinking tokens", function()
                local google_usage = {
                    promptTokenCount = 100,
                    candidatesTokenCount = 50,
                    totalTokenCount = 150,
                    thoughtsTokenCount = 0
                }

                local contract_tokens = mapper.map_tokens(google_usage)

                expect(contract_tokens.thinking_tokens).to_equal(0)
            end)
        end)

        describe("Success Response Mapping", function()
            it("should map text-only response", function()
                local google_response = {
                    candidates = {
                        {
                            content = {
                                parts = {
                                    { text = "Hello, world!" }
                                }
                            },
                            finishReason = "STOP"
                        }
                    },
                    usageMetadata = {
                        promptTokenCount = 10,
                        candidatesTokenCount = 5,
                        totalTokenCount = 15
                    },
                    metadata = { request_id = "req_test123" }
                }

                local contract_response = mapper.map_success_response(google_response)

                expect(contract_response.success).to_be_true()
                expect(contract_response.result.content).to_equal("Hello, world!")
                expect(contract_response.result.tool_calls).not_to_be_nil()
                expect(#contract_response.result.tool_calls).to_equal(0)
                expect(contract_response.finish_reason).to_equal("stop")
                expect(contract_response.tokens.prompt_tokens).to_equal(10)
                expect(contract_response.metadata.request_id).to_equal("req_test123")
            end)

            it("should map tool call response", function()
                local google_response = {
                    candidates = {
                        {
                            content = {
                                parts = {
                                    { text = "I'll help with that." },
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
                    usageMetadata = {
                        promptTokenCount = 20,
                        candidatesTokenCount = 10,
                        totalTokenCount = 30
                    }
                }

                local contract_response = mapper.map_success_response(google_response)

                expect(contract_response.success).to_be_true()
                expect(contract_response.result.content).to_equal("I'll help with that.")
                expect(#contract_response.result.tool_calls).to_equal(1)
                expect(contract_response.result.tool_calls[1].name).to_equal("calculate")
                expect(contract_response.result.tool_calls[1].arguments.expression).to_equal("2+2")
                expect(contract_response.finish_reason).to_equal("tool_call")
            end)

            it("should map multiple tool calls", function()
                local google_response = {
                    candidates = {
                        {
                            content = {
                                parts = {
                                    {
                                        functionCall = {
                                            name = "get_weather",
                                            args = { location = "NYC" }
                                        }
                                    },
                                    {
                                        functionCall = {
                                            name = "calculate",
                                            args = { expression = "5*5" }
                                        }
                                    }
                                }
                            },
                            finishReason = "STOP"
                        }
                    },
                    usageMetadata = {
                        promptTokenCount = 30,
                        candidatesTokenCount = 15,
                        totalTokenCount = 45
                    }
                }

                local contract_response = mapper.map_success_response(google_response)

                expect(contract_response.success).to_be_true()
                expect(#contract_response.result.tool_calls).to_equal(2)
                expect(contract_response.result.tool_calls[1].name).to_equal("get_weather")
                expect(contract_response.result.tool_calls[2].name).to_equal("calculate")
                expect(contract_response.finish_reason).to_equal("tool_call")
            end)

            it("should concatenate multiple text parts", function()
                local google_response = {
                    candidates = {
                        {
                            content = {
                                parts = {
                                    { text = "Hello " },
                                    { text = "world" },
                                    { text = "!" }
                                }
                            },
                            finishReason = "STOP"
                        }
                    },
                    usageMetadata = {
                        promptTokenCount = 5,
                        candidatesTokenCount = 3,
                        totalTokenCount = 8
                    }
                }

                local contract_response = mapper.map_success_response(google_response)

                expect(contract_response.success).to_be_true()
                expect(contract_response.result.content).to_equal("Hello world!")
            end)

            it("should handle empty content", function()
                local google_response = {
                    candidates = {
                        {
                            content = {
                                parts = {}
                            },
                            finishReason = "STOP"
                        }
                    },
                    usageMetadata = {
                        promptTokenCount = 10,
                        candidatesTokenCount = 0,
                        totalTokenCount = 10
                    }
                }

                local contract_response = mapper.map_success_response(google_response)

                expect(contract_response.success).to_be_true()
                expect(contract_response.result.content).to_equal("")
                expect(#contract_response.result.tool_calls).to_equal(0)
            end)

            it("should handle missing content field", function()
                local google_response = {
                    candidates = {
                        {
                            finishReason = "STOP"
                        }
                    },
                    usageMetadata = {
                        promptTokenCount = 10,
                        candidatesTokenCount = 0,
                        totalTokenCount = 10
                    }
                }

                local contract_response = mapper.map_success_response(google_response)

                expect(contract_response.success).to_be_true()
                expect(contract_response.result.content).to_equal("")
                expect(#contract_response.result.tool_calls).to_equal(0)
            end)

            it("should error on invalid response structure", function()
                local google_response = {}

                local success, error = pcall(function()
                    mapper.map_success_response(google_response)
                end)

                expect(success).to_be_false()
                expect(error).to_contain("Invalid Google response structure")
            end)

            it("should error on empty candidates array", function()
                local google_response = {
                    candidates = {}
                }

                local success, error = pcall(function()
                    mapper.map_success_response(google_response)
                end)

                expect(success).to_be_false()
                expect(error).to_contain("Invalid Google response structure")
            end)

            it("should error on nil candidates", function()
                local google_response = {
                    candidates = nil
                }

                local success, error = pcall(function()
                    mapper.map_success_response(google_response)
                end)

                expect(success).to_be_false()
            end)

            it("should handle missing metadata", function()
                local google_response = {
                    candidates = {
                        {
                            content = {
                                parts = {
                                    { text = "Test" }
                                }
                            },
                            finishReason = "STOP"
                        }
                    },
                    usageMetadata = {
                        promptTokenCount = 5,
                        candidatesTokenCount = 2,
                        totalTokenCount = 7
                    }
                }

                local contract_response = mapper.map_success_response(google_response)

                expect(contract_response.success).to_be_true()
                expect(contract_response.metadata).not_to_be_nil()
                expect(next(contract_response.metadata)).to_be_nil()
            end)

            it("should handle missing usage metadata", function()
                local google_response = {
                    candidates = {
                        {
                            content = {
                                parts = {
                                    { text = "Test" }
                                }
                            },
                            finishReason = "STOP"
                        }
                    }
                }

                local contract_response = mapper.map_success_response(google_response)

                expect(contract_response.success).to_be_true()
                expect(contract_response.tokens).to_be_nil()
            end)

            it("should map different finish reasons correctly", function()
                local test_cases = {
                    { finish = "STOP", expected = "stop" },
                    { finish = "MAX_TOKENS", expected = "length" },
                    { finish = "SAFETY", expected = "filtered" },
                    { finish = "OTHER", expected = "error" }
                }

                for _, case in ipairs(test_cases) do
                    local google_response = {
                        candidates = {
                            {
                                content = {
                                    parts = {
                                        { text = "Test" }
                                    }
                                },
                                finishReason = case.finish
                            }
                        },
                        usageMetadata = {
                            promptTokenCount = 5,
                            candidatesTokenCount = 2,
                            totalTokenCount = 7
                        }
                    }

                    local contract_response = mapper.map_success_response(google_response)

                    expect(contract_response.finish_reason).to_equal(case.expected)
                end
            end)

            it("should handle text and tool calls together", function()
                local google_response = {
                    candidates = {
                        {
                            content = {
                                parts = {
                                    { text = "Let me calculate that: " },
                                    {
                                        functionCall = {
                                            name = "calculate",
                                            args = { expression = "10+20" }
                                        }
                                    },
                                    { text = " Done!" }
                                }
                            },
                            finishReason = "STOP"
                        }
                    },
                    usageMetadata = {
                        promptTokenCount = 15,
                        candidatesTokenCount = 8,
                        totalTokenCount = 23
                    }
                }

                local contract_response = mapper.map_success_response(google_response)

                expect(contract_response.success).to_be_true()
                expect(contract_response.result.content).to_equal("Let me calculate that:  Done!")
                expect(#contract_response.result.tool_calls).to_equal(1)
                expect(contract_response.finish_reason).to_equal("tool_call")
            end)

            it("should preserve metadata from response", function()
                local google_response = {
                    candidates = {
                        {
                            content = {
                                parts = {
                                    { text = "Test" }
                                }
                            },
                            finishReason = "STOP"
                        }
                    },
                    usageMetadata = {
                        promptTokenCount = 5,
                        candidatesTokenCount = 2,
                        totalTokenCount = 7
                    },
                    metadata = {
                        request_id = "req_123",
                        model_version = "gemini-1.5-pro-001",
                        custom_field = "custom_value"
                    }
                }

                local contract_response = mapper.map_success_response(google_response)

                expect(contract_response.success).to_be_true()
                expect(contract_response.metadata.request_id).to_equal("req_123")
                expect(contract_response.metadata.model_version).to_equal("gemini-1.5-pro-001")
                expect(contract_response.metadata.custom_field).to_equal("custom_value")
            end)

            it("should handle missing finishReason", function()
                local google_response = {
                    candidates = {
                        {
                            content = {
                                parts = {
                                    { text = "Test" }
                                }
                            }
                            -- Missing finishReason
                        }
                    },
                    usageMetadata = {
                        promptTokenCount = 5,
                        candidatesTokenCount = 2,
                        totalTokenCount = 7
                    }
                }

                local contract_response = mapper.map_success_response(google_response)

                expect(contract_response.success).to_be_true()
                expect(contract_response.finish_reason).to_equal("error")
            end)
        end)

        describe("Error Response Mapping", function()
            it("should map errors by status code", function()
                local test_cases = {
                    { status = 400, error_type = "invalid_request", message = "Bad request" },
                    { status = 401, error_type = "authentication_error", message = "Unauthorized" },
                    { status = 403, error_type = "authentication_error", message = "Forbidden" },
                    { status = 404, error_type = "model_error", message = "Not found" },
                    { status = 429, error_type = "rate_limit_exceeded", message = "Rate limit" },
                    { status = 500, error_type = "server_error", message = "Internal error" },
                    { status = 503, error_type = "server_error", message = "Service unavailable" }
                }

                for _, case in ipairs(test_cases) do
                    local google_error = {
                        status_code = case.status,
                        message = case.message
                    }

                    local contract_response = mapper.map_error_response(google_error)

                    expect(contract_response.success).to_be_false()
                    expect(contract_response.error).to_equal(case.error_type)
                    expect(contract_response.error_message).to_equal(case.message)
                end
            end)

            it("should map context length errors by message content", function()
                local test_cases = {
                    "context length exceeded",
                    "maximum context length is 8192 tokens",
                    "string too long",
                    "Context length EXCEEDED",
                    "Maximum 4096 tokens allowed"
                }

                for _, message in ipairs(test_cases) do
                    local google_error = {
                        status_code = 400,
                        message = message
                    }

                    local contract_response = mapper.map_error_response(google_error)

                    expect(contract_response.success).to_be_false()
                    expect(contract_response.error).to_equal("context_length_exceeded")
                end
            end)

            it("should map content filter errors by message content", function()
                local test_cases = {
                    "content policy violation",
                    "content filter triggered",
                    "Content Policy issue",
                    "blocked by content filter"
                }

                for _, message in ipairs(test_cases) do
                    local google_error = {
                        status_code = 400,
                        message = message
                    }

                    local contract_response = mapper.map_error_response(google_error)

                    expect(contract_response.success).to_be_false()
                    expect(contract_response.error).to_equal("content_filtered")
                end
            end)

            it("should map timeout errors by message content", function()
                local test_cases = {
                    "request timeout",
                    "connection timed out",
                    "Timeout occurred",
                    "Request TIMED OUT"
                }

                for _, message in ipairs(test_cases) do
                    local google_error = {
                        status_code = 500,
                        message = message
                    }

                    local contract_response = mapper.map_error_response(google_error)

                    expect(contract_response.success).to_be_false()
                    expect(contract_response.error).to_equal("timeout_error")
                end
            end)

            it("should map network errors by message content", function()
                local test_cases = {
                    "network error occurred",
                    "connection failed",
                    "Network issue detected",
                    "lost CONNECTION to server"
                }

                for _, message in ipairs(test_cases) do
                    local google_error = {
                        status_code = 500,
                        message = message
                    }

                    local contract_response = mapper.map_error_response(google_error)

                    expect(contract_response.success).to_be_false()
                    expect(contract_response.error).to_equal("network_error")
                end
            end)

            it("should handle nil error", function()
                local contract_response = mapper.map_error_response(nil)

                expect(contract_response.success).to_be_false()
                expect(contract_response.error).to_equal("server_error")
                expect(contract_response.error_message).to_equal("Unknown Google error")
                expect(contract_response.metadata).not_to_be_nil()
            end)

            it("should handle error without message", function()
                local google_error = {
                    status_code = 500
                }

                local contract_response = mapper.map_error_response(google_error)

                expect(contract_response.success).to_be_false()
                expect(contract_response.error).to_equal("server_error")
                expect(contract_response.error_message).to_equal("Google API error")
            end)

            it("should handle error without status code", function()
                local google_error = {
                    message = "Something went wrong"
                }

                local contract_response = mapper.map_error_response(google_error)

                expect(contract_response.success).to_be_false()
                expect(contract_response.error).to_equal("server_error")
                expect(contract_response.error_message).to_equal("Something went wrong")
            end)

            it("should preserve metadata from error", function()
                local google_error = {
                    status_code = 429,
                    message = "Rate limit exceeded",
                    metadata = {
                        request_id = "req_error_123",
                        retry_after = 60
                    }
                }

                local contract_response = mapper.map_error_response(google_error)

                expect(contract_response.success).to_be_false()
                expect(contract_response.metadata.request_id).to_equal("req_error_123")
                expect(contract_response.metadata.retry_after).to_equal(60)
            end)

            it("should handle missing metadata in error", function()
                local google_error = {
                    status_code = 400,
                    message = "Bad request"
                }

                local contract_response = mapper.map_error_response(google_error)

                expect(contract_response.success).to_be_false()
                expect(contract_response.metadata).not_to_be_nil()
                expect(next(contract_response.metadata)).to_be_nil()
            end)

            it("should prioritize message patterns over status code", function()
                local google_error = {
                    status_code = 500,
                    message = "context length exceeded"
                }

                local contract_response = mapper.map_error_response(google_error)

                expect(contract_response.success).to_be_false()
                expect(contract_response.error).to_equal("context_length_exceeded")
            end)

            it("should be case-insensitive for message matching", function()
                local google_error = {
                    status_code = 400,
                    message = "CONTEXT LENGTH EXCEEDED"
                }

                local contract_response = mapper.map_error_response(google_error)

                expect(contract_response.success).to_be_false()
                expect(contract_response.error).to_equal("context_length_exceeded")
            end)

            it("should handle empty message", function()
                local google_error = {
                    status_code = 400,
                    message = ""
                }

                local contract_response = mapper.map_error_response(google_error)

                expect(contract_response.success).to_be_false()
                expect(contract_response.error).to_equal("invalid_request")
                expect(contract_response.error_message).to_equal("")
            end)

            it("should map 401 and 403 to authentication error", function()
                local codes = { 401, 403 }

                for _, code in ipairs(codes) do
                    local google_error = {
                        status_code = code,
                        message = "Auth failed"
                    }

                    local contract_response = mapper.map_error_response(google_error)

                    expect(contract_response.error).to_equal("authentication_error")
                end
            end)

            it("should map all 5xx codes to server error", function()
                local codes = { 500, 502, 503, 504 }

                for _, code in ipairs(codes) do
                    local google_error = {
                        status_code = code,
                        message = "Server error"
                    }

                    local contract_response = mapper.map_error_response(google_error)

                    expect(contract_response.error).to_equal("server_error")
                end
            end)

            it("should handle complex error messages with multiple keywords", function()
                local google_error = {
                    status_code = 400,
                    message = "Request failed: context length exceeded and content filter triggered"
                }

                local contract_response = mapper.map_error_response(google_error)

                expect(contract_response.success).to_be_false()
                -- Should match first pattern (context length)
                expect(contract_response.error).to_equal("context_length_exceeded")
            end)
        end)

        describe("Content Standardization", function()
            it("should return string content as-is", function()
                local content = "Simple string content"

                local result = mapper.standardize_content(content)

                expect(result).to_equal("Simple string content")
            end)

            it("should extract text from array content", function()
                local content = {
                    { type = "text", text = "Hello " },
                    { type = "text", text = "world" }
                }

                local result = mapper.standardize_content(content)

                expect(result).to_equal("Hello world")
            end)

            it("should ignore non-text parts", function()
                local content = {
                    { type = "text", text = "Text part" },
                    { type = "image", source = { url = "image.jpg" } },
                    { type = "text", text = " continues" }
                }

                local result = mapper.standardize_content(content)

                expect(result).to_equal("Text part continues")
            end)

            it("should handle empty string", function()
                local content = ""

                local result = mapper.standardize_content(content)

                expect(result).to_equal("")
            end)

            it("should handle nil content", function()
                local content = nil

                local result = mapper.standardize_content(content)

                expect(result).to_equal("")
            end)

            it("should handle empty array", function()
                local content = {}

                local result = mapper.standardize_content(content)

                expect(result).to_equal("")
            end)

            it("should handle array with only non-text parts", function()
                local content = {
                    { type = "image", source = { url = "image1.jpg" } },
                    { type = "image", source = { url = "image2.jpg" } }
                }

                local result = mapper.standardize_content(content)

                expect(result).to_equal("")
            end)

            it("should handle array with empty text", function()
                local content = {
                    { type = "text", text = "" }
                }

                local result = mapper.standardize_content(content)

                expect(result).to_equal("")
            end)

            it("should concatenate multiple text parts without separator", function()
                local content = {
                    { type = "text", text = "Part1" },
                    { type = "text", text = "Part2" },
                    { type = "text", text = "Part3" }
                }

                local result = mapper.standardize_content(content)

                expect(result).to_equal("Part1Part2Part3")
            end)

            it("should preserve whitespace in text", function()
                local content = {
                    { type = "text", text = "  Leading and trailing  " }
                }

                local result = mapper.standardize_content(content)

                expect(result).to_equal("  Leading and trailing  ")
            end)

            it("should handle text with newlines", function()
                local content = {
                    { type = "text", text = "Line 1\nLine 2\nLine 3" }
                }

                local result = mapper.standardize_content(content)

                expect(result).to_equal("Line 1\nLine 2\nLine 3")
            end)

            it("should handle special characters", function()
                local content = {
                    { type = "text", text = "Special: @#$%^&*(){}[]<>|\\/" }
                }

                local result = mapper.standardize_content(content)

                expect(result).to_equal("Special: @#$%^&*(){}[]<>|\\/")
            end)

            it("should handle unicode characters", function()
                local content = {
                    { type = "text", text = "Unicode: 你好 🌍 مرحبا" }
                }

                local result = mapper.standardize_content(content)

                expect(result).to_equal("Unicode: 你好 🌍 مرحبا")
            end)

            it("should handle mixed content types in order", function()
                local content = {
                    { type = "text", text = "Start " },
                    { type = "image", source = { url = "img.jpg" } },
                    { type = "text", text = "middle " },
                    { type = "unknown", data = "something" },
                    { type = "text", text = "end" }
                }

                local result = mapper.standardize_content(content)

                expect(result).to_equal("Start middle end")
            end)

            it("should handle very long text", function()
                local long_text = string.rep("a", 10000)
                local content = {
                    { type = "text", text = long_text }
                }

                local result = mapper.standardize_content(content)

                expect(result).to_equal(long_text)
                expect(#result).to_equal(10000)
            end)

            it("should handle content with nil text field", function()
                local content = {
                    { type = "text", text = nil }
                }

                local result = mapper.standardize_content(content)

                expect(result).to_equal("")
            end)

            it("should handle content with missing text field", function()
                local content = {
                    { type = "text" }
                }

                local result = mapper.standardize_content(content)

                expect(result).to_equal("")
            end)

            it("should handle non-table, non-string content", function()
                local test_cases = {
                    123,
                    true,
                    false
                }

                for _, content in ipairs(test_cases) do
                    local result = mapper.standardize_content(content)
                    expect(result).to_equal("")
                end
            end)

            it("should handle nested array structure", function()
                local content = {
                    {
                        type = "text",
                        text = "Outer text"
                    }
                }

                local result = mapper.standardize_content(content)

                expect(result).to_equal("Outer text")
            end)

            it("should handle content parts without type field", function()
                local content = {
                    { text = "Text without type" },
                    { type = "text", text = "Text with type" }
                }

                local result = mapper.standardize_content(content)

                expect(result).to_equal("Text with type")
            end)
        end)
    end)
end

return tests.run_cases(define_tests)
