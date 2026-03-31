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

                tests.eq(#google_messages, 2)
                tests.eq(#system_instructions, 1)
                tests.eq(system_instructions[1].text, "You are a helpful assistant")
                tests.eq(google_messages[1].role, "user")
                local user_parts = google_messages[1].parts :: any
                tests.eq(user_parts[1].text, "Hello")
                tests.eq(google_messages[2].role, "model")
                local model_parts = google_messages[2].parts :: any
                tests.eq(model_parts.text, "Hi there!")
            end)

            it("should convert string content to parts format", function()
                local contract_messages = {
                    {
                        role = "user",
                        content = "Simple string message"
                    }
                }

                local google_messages, system_instructions = mapper.map_messages(contract_messages)

                tests.eq(#google_messages, 1)
                tests.eq(google_messages[1].role, "user")
                local str_parts = google_messages[1].parts :: any
                tests.eq(str_parts[1].text, "Simple string message")
            end)

            it("should handle developer role as user role", function()
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

                tests.eq(#system_instructions, 0)
                tests.eq(#google_messages, 2)
                tests.eq(google_messages[1].role, "user")
                local dev_parts = google_messages[1].parts :: any
                tests.eq(dev_parts[1].text, "Debug mode enabled")
                tests.eq(google_messages[2].role, "user")
                local test_parts = google_messages[2].parts :: any
                tests.eq(test_parts[1].text, "Test")
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

                tests.eq(#google_messages, 1)
                local img_parts = google_messages[1].parts :: any
                tests.eq(img_parts[1].text, "What's in this image?")
                tests.not_nil(img_parts[2].fileData)
                tests.eq(img_parts[2].fileData.fileUri, "https://example.com/image.jpg")
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

                tests.eq(#google_messages, 1)
                local b64_parts = google_messages[1].parts :: any
                tests.not_nil(b64_parts[1].inlineData)
                tests.eq(b64_parts[1].inlineData.mimeType, "image/jpeg")
                tests.contains(tostring(b64_parts[1].inlineData.data), "iVBORw0KGgo")
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

                tests.eq(#google_messages, 1)
                tests.eq(google_messages[1].role, "model")
                local fc_parts = google_messages[1].parts :: any
                tests.not_nil(fc_parts.functionCall)
                tests.eq(fc_parts.functionCall.name, "get_weather")
                tests.eq(fc_parts.functionCall.args.location, "New York")
            end)

            it("should exclude empty arguments in function_call", function()
                local messages_empty_args, _ = mapper.map_messages({
                    {
                        role = "function_call",
                        function_call = {
                            name = "get_weather",
                            arguments = {}
                        }
                    }
                })

                tests.eq(#messages_empty_args, 1)
                tests.eq(messages_empty_args[1].role, "model")
                local empty_parts = messages_empty_args[1].parts :: any
                tests.not_nil(empty_parts.functionCall)
                tests.eq(empty_parts.functionCall.name, "get_weather")
                tests.is_nil(empty_parts.functionCall.args)

                local messages_nil_args, _ = mapper.map_messages({
                    {
                        role = "function_call",
                        function_call = {
                            name = "get_weather"
                        }
                    }
                })

                tests.eq(#messages_nil_args, 1)
                tests.eq(messages_nil_args[1].role, "model")
                local nil_parts = messages_nil_args[1].parts :: any
                tests.not_nil(nil_parts.functionCall)
                tests.eq(nil_parts.functionCall.name, "get_weather")
                tests.is_nil(nil_parts.functionCall.args)
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

                tests.eq(#google_messages, 1)
                local str_arg_parts = google_messages[1].parts :: any
                tests.eq(str_arg_parts.functionCall.args.key, "value")
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

                tests.eq(#google_messages, 1)
                tests.eq(google_messages[1].role, "user")
                local fr_parts = google_messages[1].parts :: any
                tests.not_nil(fr_parts[1].functionResponse)
                tests.eq(fr_parts[1].functionResponse.name, "get_weather")
                tests.eq(fr_parts[1].functionResponse.response.content, "The weather is sunny")
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

                tests.eq(#google_messages, 1)
                local str_fr_parts = google_messages[1].parts :: any
                tests.eq(str_fr_parts[1].functionResponse.response.content, "Simple string result")
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

                tests.eq(#google_messages, 1)
                local json_fr_parts = google_messages[1].parts :: any
                local response_content = json_fr_parts[1].functionResponse.response.content
                tests.eq(response_content.result, "success")
                tests.eq(response_content.value, 42)
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

                tests.eq(#google_messages, 1)
                local tbl_fr_parts = google_messages[1].parts :: any
                local response_content = tbl_fr_parts[1].functionResponse.response.content
                tests.eq(response_content.status, "ok")
                tests.eq(response_content.count, 5)
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

                tests.eq(#google_messages, 1)
                local nil_fr_parts = google_messages[1].parts :: any
                tests.eq(nil_fr_parts[1].functionResponse.response.content, "")
            end)

            it("should handle empty string content", function()
                local contract_messages = {
                    {
                        role = "user",
                        content = ""
                    }
                }

                local google_messages, _ = mapper.map_messages(contract_messages)

                tests.eq(#google_messages, 1)
                local empty_str_parts = google_messages[1].parts :: any
                tests.eq(empty_str_parts[1].text, "")
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

                tests.eq(#google_messages, 1)
                tests.eq(google_messages[1].role, "user")
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

                tests.eq(#google_messages, 1)
                tests.eq(google_messages[1].role, "user")
                local kept_parts = google_messages[1].parts :: any
                tests.eq(kept_parts[1].text, "This should be kept")
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

                tests.eq(#google_messages, 1)
                local nested_parts = google_messages[1].parts :: any
                tests.eq(nested_parts[1].text, "Deeply nested")
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

                tests.eq(#google_messages, 1)
                tests.is_nil((google_messages[1] :: any).metadata)
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

                tests.eq(#google_tools, 2)
                tests.eq(google_tools[1].name, "get_weather")
                tests.eq(google_tools[1].description, "Get weather information")
                tests.eq(google_tools[1].parameters.type, "object")
                tests.eq(google_tools[1].parameters.properties.location.type, "string")
                tests.eq(google_tools[1].parameters.required[1], "location")

                tests.eq(google_tools[2].name, "calculate")
                tests.eq(google_tools[2].description, "Perform calculations")
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

                tests.eq(#google_tools, 1)
                tests.is_nil(google_tools[1].parameters.properties.count.multipleOf)
                tests.eq(google_tools[1].parameters.properties.count.type, "number")
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

                tests.eq(#google_tools, 1)
                tests.is_nil(google_tools[1].parameters.examples)
                tests.eq(google_tools[1].parameters.properties.value.type, "string")
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

                tests.eq(#google_tools, 1)
                tests.is_nil(google_tools[1].parameters.properties.nested.multipleOf)
                tests.is_nil(google_tools[1].parameters.properties.nested.properties.inner.multipleOf)
                tests.eq(google_tools[1].parameters.properties.nested.properties.inner.type, "number")
            end)

            it("should handle empty tools array", function()
                local google_tools = mapper.map_tools({})

                tests.is_nil(google_tools)
            end)

            it("should handle nil tools", function()
                local google_tools = mapper.map_tools(nil)

                tests.is_nil(google_tools)
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

                tests.eq(#google_tools, 1)
                tests.eq(google_tools[1].name, "valid_tool")
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

                tests.eq(#google_tools, 1)
                local params = google_tools[1].parameters

                tests.eq(params.properties.text.minLength, 1)
                tests.eq(params.properties.text.maxLength, 100)
                tests.eq(params.properties.text.pattern, "^[a-z]+$")

                tests.eq(params.properties.number.minimum, 0)
                tests.eq(params.properties.number.maximum, 100)
                tests.is_true(params.properties.number.exclusiveMinimum)

                tests.eq(params.properties.array.minItems, 1)
                tests.eq(params.properties.array.maxItems, 10)
                tests.is_true(params.properties.array.uniqueItems)

                tests.eq(params.required[1], "text")
                tests.is_nil(params.additionalProperties) -- Google does not support this, so should be filtered out
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

                tests.eq(#google_tools, 1)
                local address = google_tools[1].parameters.properties.address
                tests.eq(address.type, "object")
                tests.eq(address.properties.street.type, "string")
                tests.eq(address.properties.coordinates.properties.lat.type, "number")
            end)
        end)

        describe("Tool Config Mapping", function()
            local test_tools = {
                { name = "get_weather" },
                { name = "calculate" }
            }

            it("should map auto tool choice", function()
                local config, error = mapper.map_tool_config("auto", test_tools)

                tests.is_nil(error)
                tests.eq(config.mode, "AUTO")
            end)

            it("should map nil tool choice to AUTO", function()
                local config, error = mapper.map_tool_config(nil, test_tools)

                tests.is_nil(error)
                tests.eq(config.mode, "AUTO")
            end)

            it("should map none tool choice", function()
                local config, error = mapper.map_tool_config("none", test_tools)

                tests.is_nil(error)
                tests.eq(config.mode, "NONE")
            end)

            it("should map any tool choice to AUTO", function()
                local config, error = mapper.map_tool_config("any", test_tools)

                tests.is_nil(error)
                tests.eq(config.mode, "AUTO")
            end)

            it("should map specific tool name", function()
                local config, error = mapper.map_tool_config("get_weather", test_tools)

                tests.is_nil(error)
                tests.eq(config.mode, "ANY")
                tests.not_nil(config.allowedFunctionNames)
                tests.eq(#config.allowedFunctionNames, 1)
                tests.eq(config.allowedFunctionNames[1], "get_weather")
            end)

            it("should error on non-existent tool", function()
                local config, error = mapper.map_tool_config("nonexistent_tool", test_tools)

                tests.is_nil(config)
                tests.not_nil(error)
                tests.contains(tostring(error), "not found")
                tests.contains(tostring(error), "nonexistent_tool")
            end)

            it("should handle empty tools array with specific tool name", function()
                local config, error = mapper.map_tool_config("some_tool", {})

                tests.is_nil(config)
                tests.not_nil(error)
                tests.contains(tostring(error), "not found")
            end)

            it("should handle nil tools array with specific tool name", function()
                local config, error = mapper.map_tool_config("some_tool", nil)

                tests.is_nil(config)
                tests.not_nil(error)
                tests.contains(tostring(error), "not found")
            end)

            it("should be case-sensitive for tool names", function()
                local config, error = mapper.map_tool_config("Get_Weather", test_tools)

                tests.is_nil(config)
                tests.not_nil(error)
                tests.contains(tostring(error), "not found")
            end)

            it("should handle tool name with exact match", function()
                local tools_with_similar_names = {
                    { name = "get_weather" },
                    { name = "get_weather_forecast" }
                }

                local config, error = mapper.map_tool_config("get_weather", tools_with_similar_names)

                tests.is_nil(error)
                tests.eq(config.mode, "ANY")
                tests.eq(#config.allowedFunctionNames, 1)
                tests.eq(config.allowedFunctionNames[1], "get_weather")
            end)

            it("should return AUTO for empty string", function()
                local config, error = mapper.map_tool_config("", test_tools)

                tests.is_nil(error)
                tests.eq(config.mode, "AUTO")
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

                tests.eq(google_options.temperature, 0.7)
                tests.eq(google_options.maxOutputTokens, 150)
                tests.eq(google_options.topP, 0.9)
                tests.eq(google_options.seed, 42)
                tests.eq(google_options.presencePenalty, 0.3)
                tests.eq(google_options.frequencyPenalty, 0.5)
                tests.not_nil(google_options.stopSequences)
                tests.eq(#google_options.stopSequences, 2)
                tests.eq(google_options.stopSequences[1], "STOP")
                tests.eq(google_options.stopSequences[2], "END")
            end)

            it("should handle nil options", function()
                local google_options = mapper.map_options(nil)

                tests.is_nil(next(google_options))
            end)

            it("should handle empty options", function()
                local google_options = mapper.map_options({})

                tests.is_nil(next(google_options))
            end)

            it("should handle partial options", function()
                local contract_options = {
                    temperature = 0.5,
                    max_tokens = 100
                }

                local google_options = mapper.map_options(contract_options)

                tests.eq(google_options.temperature, 0.5)
                tests.eq(google_options.maxOutputTokens, 100)
                tests.is_nil(google_options.topP)
                tests.is_nil(google_options.seed)
            end)

            it("should handle temperature of 0", function()
                local contract_options = {
                    temperature = 0
                }

                local google_options = mapper.map_options(contract_options)

                tests.eq(google_options.temperature, 0)
            end)

            it("should handle max temperature", function()
                local contract_options = {
                    temperature = 2.0
                }

                local google_options = mapper.map_options(contract_options)

                tests.eq(google_options.temperature, 2.0)
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
                    tests.eq(google_options.topP, case.expected)
                end
            end)

            it("should handle penalty values", function()
                local contract_options = {
                    presence_penalty = -2.0,
                    frequency_penalty = 2.0
                }

                local google_options = mapper.map_options(contract_options)

                tests.eq(google_options.presencePenalty, -2.0)
                tests.eq(google_options.frequencyPenalty, 2.0)
            end)

            it("should handle empty stop_sequences array", function()
                local contract_options = {
                    stop_sequences = {}
                }

                local google_options = mapper.map_options(contract_options)

                tests.not_nil(google_options.stopSequences)
                tests.eq(#google_options.stopSequences, 0)
            end)

            it("should handle single stop sequence", function()
                local contract_options = {
                    stop_sequences = {"STOP"}
                }

                local google_options = mapper.map_options(contract_options)

                tests.eq(#google_options.stopSequences, 1)
                tests.eq(google_options.stopSequences[1], "STOP")
            end)

            it("should preserve nil values for unset options", function()
                local contract_options = {
                    temperature = 0.7
                    -- Other options not set
                }

                local google_options = mapper.map_options(contract_options)

                tests.eq(google_options.temperature, 0.7)
                tests.is_nil(google_options.maxOutputTokens)
                tests.is_nil(google_options.topP)
                tests.is_nil(google_options.seed)
                tests.is_nil(google_options.presencePenalty)
                tests.is_nil(google_options.frequencyPenalty)
                tests.is_nil(google_options.stopSequences)
            end)

            it("should not include unsupported options", function()
                local contract_options = {
                    temperature = 0.7,
                    unsupported_option = "value",
                    another_unsupported = 123
                }

                local google_options = mapper.map_options(contract_options)

                tests.eq(google_options.temperature, 0.7)
                tests.is_nil((google_options :: any).unsupported_option)
                tests.is_nil((google_options :: any).another_unsupported)
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

                tests.eq(google_options.temperature, 0.8)
                tests.eq(google_options.maxOutputTokens, 200)
                tests.eq(google_options.topP, 0.95)
                tests.eq(google_options.seed, 999)
                tests.eq(google_options.presencePenalty, 0.1)
                tests.eq(google_options.frequencyPenalty, 0.2)
                tests.eq(#google_options.stopSequences, 3)
            end)
        end)

        describe("Tool Calls Response Mapping", function()
            it("should map Google function calls to contract format", function()
                local google_function_calls = {
                    {
                        functionCall = {
                            name = "get_weather",
                            args = { location = "New York", units = "celsius" }
                        }
                    },
                    {
                        functionCall = {
                            name = "calculate",
                            args = { expression = "2+2" }
                        }
                    }
                }

                local contract_tool_calls = mapper.map_tool_calls(google_function_calls)

                tests.eq(#contract_tool_calls, 2)

                tests.eq(contract_tool_calls[1].name, "get_weather")
                tests.eq(contract_tool_calls[1].arguments.location, "New York")
                tests.eq(contract_tool_calls[1].arguments.units, "celsius")
                tests.not_nil(contract_tool_calls[1].id)
                tests.contains(tostring(contract_tool_calls[1].id), "get_weather_")

                tests.eq(contract_tool_calls[2].name, "calculate")
                tests.eq(contract_tool_calls[2].arguments.expression, "2+2")
                tests.not_nil(contract_tool_calls[2].id)
                tests.contains(tostring(contract_tool_calls[2].id), "calculate_")
            end)

            it("should generate unique IDs for each tool call", function()
                local google_function_calls = {
                    { functionCall = { name = "tool1", args = {} } },
                    { functionCall = { name = "tool2", args = {} } },
                    { functionCall = { name = "tool3", args = {} } }
                }

                local contract_tool_calls = mapper.map_tool_calls(google_function_calls)

                tests.eq(#contract_tool_calls, 3)

                local ids = {}
                for _, call in ipairs(contract_tool_calls) do
                    tests.is_nil(ids[call.id])
                    ids[call.id] = true
                end
            end)

            it("should handle empty args", function()
                local google_function_calls = {
                    {
                        functionCall = {
                            name = "no_args_tool",
                            args = {}
                        }
                    }
                }

                local contract_tool_calls = mapper.map_tool_calls(google_function_calls)

                tests.eq(#contract_tool_calls, 1)
                tests.eq(contract_tool_calls[1].name, "no_args_tool")
                tests.not_nil(contract_tool_calls[1].arguments)
                tests.is_nil(next(contract_tool_calls[1].arguments))
            end)

            it("should handle nil args", function()
                local google_function_calls = {
                    {
                        functionCall = {
                            name = "nil_args_tool",
                            args = nil
                        }
                    }
                }

                local contract_tool_calls = mapper.map_tool_calls(google_function_calls)

                tests.eq(#contract_tool_calls, 1)
                tests.eq(contract_tool_calls[1].name, "nil_args_tool")
                tests.not_nil(contract_tool_calls[1].arguments)
                tests.is_nil(next(contract_tool_calls[1].arguments))
            end)

            it("should handle complex nested arguments", function()
                local google_function_calls = {
                    {
                        functionCall = {
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
                }

                local contract_tool_calls = mapper.map_tool_calls(google_function_calls)

                tests.eq(#contract_tool_calls, 1)
                tests.eq(contract_tool_calls[1].arguments.simple, "value")
                tests.eq(contract_tool_calls[1].arguments.nested.key1, "value1")
                tests.eq(contract_tool_calls[1].arguments.nested.key2.deep, "nested")
                tests.eq(#contract_tool_calls[1].arguments.array, 3)
                tests.eq(contract_tool_calls[1].arguments.array[1], "item1")
            end)

            it("should handle nil function calls", function()
                local contract_tool_calls = mapper.map_tool_calls(nil)

                tests.eq(#contract_tool_calls, 0)
            end)

            it("should handle empty function calls array", function()
                local contract_tool_calls = mapper.map_tool_calls({})

                tests.eq(#contract_tool_calls, 0)
            end)

            it("should handle function call with only name", function()
                local google_function_calls = {
                    {
                        functionCall = {
                            name = "simple_tool"
                        }
                    }
                }

                local contract_tool_calls = mapper.map_tool_calls(google_function_calls)

                tests.eq(#contract_tool_calls, 1)
                tests.eq(contract_tool_calls[1].name, "simple_tool")
                tests.not_nil(contract_tool_calls[1].arguments)
                tests.is_nil(next(contract_tool_calls[1].arguments))
            end)

            it("should handle various argument types", function()
                local google_function_calls = {
                    {
                        functionCall = {
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
                }

                local contract_tool_calls = mapper.map_tool_calls(google_function_calls)

                tests.eq(#contract_tool_calls, 1)
                local args = contract_tool_calls[1].arguments
                tests.eq(args.string_arg, "text")
                tests.eq(args.number_arg, 42)
                tests.eq(args.float_arg, 3.14)
                tests.is_true(args.bool_arg)
                tests.eq(#args.array_arg, 3)
                tests.eq(args.object_arg.key, "value")
            end)

            it("should generate ID with timestamp component", function()
                local google_function_calls = {
                    { functionCall = { name = "test_tool", args = {} } }
                }

                local contract_tool_calls = mapper.map_tool_calls(google_function_calls)

                tests.eq(#contract_tool_calls, 1)
                local id = contract_tool_calls[1].id
                tests.contains(tostring(id), "test_tool_")
            end)

            it("should handle function call with missing name gracefully", function()
                local google_function_calls = {
                    {
                        functionCall = {
                            args = { key = "value" }
                        }
                    }
                }

                local contract_tool_calls = mapper.map_tool_calls(google_function_calls)

                tests.eq(#contract_tool_calls, 1)
                tests.contains(tostring(contract_tool_calls[1].id), "func_")
                tests.eq(contract_tool_calls[1].arguments.key, "value")
            end)
        end)

        describe("Finish Reason Mapping", function()
            it("should map STOP to stop", function()
                local result = mapper.map_finish_reason("STOP")
                tests.eq(result, "stop")
            end)

            it("should map MAX_TOKENS to length", function()
                local result = mapper.map_finish_reason("MAX_TOKENS")
                tests.eq(result, "length")
            end)

            it("should map SAFETY to filtered", function()
                local result = mapper.map_finish_reason("SAFETY")
                tests.eq(result, "filtered")
            end)

            it("should map RECITATION to filtered", function()
                local result = mapper.map_finish_reason("RECITATION")
                tests.eq(result, "filtered")
            end)

            it("should map LANGUAGE to filtered", function()
                local result = mapper.map_finish_reason("LANGUAGE")
                tests.eq(result, "filtered")
            end)

            it("should map BLOCKLIST to filtered", function()
                local result = mapper.map_finish_reason("BLOCKLIST")
                tests.eq(result, "filtered")
            end)

            it("should map PROHIBITED_CONTENT to filtered", function()
                local result = mapper.map_finish_reason("PROHIBITED_CONTENT")
                tests.eq(result, "filtered")
            end)

            it("should map SPII to filtered", function()
                local result = mapper.map_finish_reason("SPII")
                tests.eq(result, "filtered")
            end)

            it("should map IMAGE_SAFETY to filtered", function()
                local result = mapper.map_finish_reason("IMAGE_SAFETY")
                tests.eq(result, "filtered")
            end)

            it("should map MALFORMED_FUNCTION_CALL to error", function()
                local result = mapper.map_finish_reason("MALFORMED_FUNCTION_CALL")
                tests.eq(result, "error")
            end)

            it("should map OTHER to error", function()
                local result = mapper.map_finish_reason("OTHER")
                tests.eq(result, "error")
            end)

            it("should map unknown reason to error", function()
                local result = mapper.map_finish_reason("UNKNOWN_REASON")
                tests.eq(result, "error")
            end)

            it("should map nil to error", function()
                local result = mapper.map_finish_reason(nil)
                tests.eq(result, "error")
            end)

            it("should map empty string to error", function()
                local result = mapper.map_finish_reason("")
                tests.eq(result, "error")
            end)

            it("should be case-sensitive", function()
                local result = mapper.map_finish_reason("stop")
                tests.eq(result, "error")
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
                    tests.eq(result, "filtered")
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
                    tests.eq(result, case.expected)
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

                tests.eq(contract_tokens.prompt_tokens, 100)
                tests.eq(contract_tokens.completion_tokens, 50)
                tests.eq(contract_tokens.total_tokens, 150)
                tests.eq(contract_tokens.cache_write_tokens, 0)
                tests.eq(contract_tokens.cache_read_tokens, 0)
            end)

            it("should map thinking tokens", function()
                local google_usage = {
                    promptTokenCount = 100,
                    candidatesTokenCount = 80,
                    totalTokenCount = 200,
                    thoughtsTokenCount = 20
                }

                local contract_tokens = mapper.map_tokens(google_usage)

                tests.eq(contract_tokens.thinking_tokens, 20)
                tests.eq(contract_tokens.prompt_tokens, 100)
                tests.eq(contract_tokens.completion_tokens, 80)
                tests.eq(contract_tokens.total_tokens, 200)
            end)

            it("should map cache tokens", function()
                local google_usage = {
                    promptTokenCount = 100,
                    candidatesTokenCount = 50,
                    totalTokenCount = 150,
                    cachedContentTokenCount = 30
                }

                local contract_tokens = mapper.map_tokens(google_usage)

                tests.eq(contract_tokens.cache_read_tokens, 30)
                tests.eq(contract_tokens.cache_write_tokens, 70)
                tests.eq(contract_tokens.prompt_tokens, 70)
                tests.eq(contract_tokens.completion_tokens, 50)
            end)

            it("should handle nil usage", function()
                local contract_tokens = mapper.map_tokens(nil)

                tests.is_nil(contract_tokens)
            end)

            it("should handle partial usage data", function()
                local google_usage = {
                    promptTokenCount = 50
                    -- Missing other fields
                }

                local contract_tokens = mapper.map_tokens(google_usage)

                tests.eq(contract_tokens.prompt_tokens, 50)
                tests.eq(contract_tokens.completion_tokens, 0)
                tests.eq(contract_tokens.total_tokens, 0)
                tests.is_nil(contract_tokens.thinking_tokens)
            end)

            it("should handle zero token counts", function()
                local google_usage = {
                    promptTokenCount = 0,
                    candidatesTokenCount = 0,
                    totalTokenCount = 0
                }

                local contract_tokens = mapper.map_tokens(google_usage)

                tests.eq(contract_tokens.prompt_tokens, 0)
                tests.eq(contract_tokens.completion_tokens, 0)
                tests.eq(contract_tokens.total_tokens, 0)
            end)

            it("should calculate cache write tokens correctly", function()
                local google_usage = {
                    promptTokenCount = 200,
                    candidatesTokenCount = 50,
                    totalTokenCount = 250,
                    cachedContentTokenCount = 150
                }

                local contract_tokens = mapper.map_tokens(google_usage)

                tests.eq(contract_tokens.cache_read_tokens, 150)
                tests.eq(contract_tokens.cache_write_tokens, 50)
                tests.eq(contract_tokens.prompt_tokens, 50)
            end)

            it("should handle cache tokens equal to prompt tokens", function()
                local google_usage = {
                    promptTokenCount = 100,
                    candidatesTokenCount = 50,
                    totalTokenCount = 150,
                    cachedContentTokenCount = 100
                }

                local contract_tokens = mapper.map_tokens(google_usage)

                tests.eq(contract_tokens.cache_read_tokens, 100)
                tests.eq(contract_tokens.cache_write_tokens, 0)
                tests.eq(contract_tokens.prompt_tokens, 0)
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

                tests.eq(contract_tokens.prompt_tokens, 150)
                tests.eq(contract_tokens.completion_tokens, 100)
                tests.eq(contract_tokens.total_tokens, 350)
                tests.eq(contract_tokens.cache_read_tokens, 50)
                tests.eq(contract_tokens.cache_write_tokens, 150)
                tests.eq(contract_tokens.thinking_tokens, 25)
            end)

            it("should handle missing optional token fields", function()
                local google_usage = {
                    promptTokenCount = 100,
                    candidatesTokenCount = 50,
                    totalTokenCount = 150
                    -- No cachedContentTokenCount or thoughtsTokenCount
                }

                local contract_tokens = mapper.map_tokens(google_usage)

                tests.eq(contract_tokens.cache_read_tokens, 0)
                tests.eq(contract_tokens.cache_write_tokens, 0)
                tests.is_nil(contract_tokens.thinking_tokens)
            end)

            it("should default to 0 for missing core token fields", function()
                local google_usage = {}

                local contract_tokens = mapper.map_tokens(google_usage)

                tests.eq(contract_tokens.prompt_tokens, 0)
                tests.eq(contract_tokens.completion_tokens, 0)
                tests.eq(contract_tokens.total_tokens, 0)
            end)

            it("should handle nil thinking tokens separately", function()
                local google_usage = {
                    promptTokenCount = 100,
                    candidatesTokenCount = 50,
                    totalTokenCount = 150,
                    thoughtsTokenCount = nil
                }

                local contract_tokens = mapper.map_tokens(google_usage)

                tests.is_nil(contract_tokens.thinking_tokens)
                tests.eq(contract_tokens.prompt_tokens, 100)
            end)

            it("should handle zero thinking tokens", function()
                local google_usage = {
                    promptTokenCount = 100,
                    candidatesTokenCount = 50,
                    totalTokenCount = 150,
                    thoughtsTokenCount = 0
                }

                local contract_tokens = mapper.map_tokens(google_usage)

                tests.eq(contract_tokens.thinking_tokens, 0)
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

                tests.is_true(contract_response.success)
                tests.eq(contract_response.result.content, "Hello, world!")
                tests.not_nil(contract_response.result.tool_calls)
                tests.eq(#contract_response.result.tool_calls, 0)
                tests.eq(contract_response.finish_reason, "stop")
                tests.eq(contract_response.tokens.prompt_tokens, 10)
                tests.eq(contract_response.metadata.request_id, "req_test123")
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

                local contract_response: any = mapper.map_success_response(google_response)

                tests.is_true(contract_response.success)
                tests.eq(contract_response.result.content, "I'll help with that.")
                tests.eq(#contract_response.result.tool_calls, 1)
                tests.eq(contract_response.result.tool_calls[1].name, "calculate")
                tests.eq(contract_response.result.tool_calls[1].arguments.expression, "2+2")
                tests.eq(contract_response.finish_reason, "tool_call")
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

                local contract_response: any = mapper.map_success_response(google_response)

                tests.is_true(contract_response.success)
                tests.eq(#contract_response.result.tool_calls, 2)
                tests.eq(contract_response.result.tool_calls[1].name, "get_weather")
                tests.eq(contract_response.result.tool_calls[2].name, "calculate")
                tests.eq(contract_response.finish_reason, "tool_call")
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

                tests.is_true(contract_response.success)
                tests.eq(contract_response.result.content, "Hello world!")
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

                tests.is_true(contract_response.success)
                tests.eq(contract_response.result.content, "")
                tests.eq(#contract_response.result.tool_calls, 0)
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

                tests.is_true(contract_response.success)
                tests.eq(contract_response.result.content, "")
                tests.eq(#contract_response.result.tool_calls, 0)
            end)

            it("should error on invalid response structure", function()
                local google_response = {}

                local success, error = pcall(function()
                    mapper.map_success_response(google_response)
                end)

                tests.is_false(success)
                tests.contains(tostring(error), "Invalid Google response structure")
            end)

            it("should error on empty candidates array", function()
                local google_response = {
                    candidates = {}
                }

                local success, error = pcall(function()
                    mapper.map_success_response(google_response)
                end)

                tests.is_false(success)
                tests.contains(tostring(error), "Invalid Google response structure")
            end)

            it("should error on nil candidates", function()
                local google_response = {
                    candidates = nil
                }

                local success, error = pcall(function()
                    mapper.map_success_response(google_response)
                end)

                tests.is_false(success)
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

                tests.is_true(contract_response.success)
                tests.not_nil(contract_response.metadata)
                tests.is_nil(next(contract_response.metadata))
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

                tests.is_true(contract_response.success)
                tests.is_nil(contract_response.tokens)
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

                    tests.eq(contract_response.finish_reason, case.expected)
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

                tests.is_true(contract_response.success)
                tests.eq(contract_response.result.content, "Let me calculate that:  Done!")
                tests.eq(#contract_response.result.tool_calls, 1)
                tests.eq(contract_response.finish_reason, "tool_call")
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
                        model_version = "gemini-2.5-pro-001",
                        custom_field = "custom_value"
                    }
                }

                local contract_response = mapper.map_success_response(google_response)

                tests.is_true(contract_response.success)
                tests.eq(contract_response.metadata.request_id, "req_123")
                tests.eq(contract_response.metadata.model_version, "gemini-2.5-pro-001")
                tests.eq(contract_response.metadata.custom_field, "custom_value")
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

                tests.is_true(contract_response.success)
                tests.eq(contract_response.finish_reason, "error")
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

                    tests.is_false(contract_response.success)
                    tests.eq(contract_response.error, case.error_type)
                    tests.eq(contract_response.error_message, case.message)
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

                    tests.is_false(contract_response.success)
                    tests.eq(contract_response.error, "context_length_exceeded")
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

                    tests.is_false(contract_response.success)
                    tests.eq(contract_response.error, "content_filtered")
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

                    tests.is_false(contract_response.success)
                    tests.eq(contract_response.error, "timeout_error")
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

                    tests.is_false(contract_response.success)
                    tests.eq(contract_response.error, "network_error")
                end
            end)

            it("should handle nil error", function()
                local contract_response = mapper.map_error_response(nil)

                tests.is_false(contract_response.success)
                tests.eq(contract_response.error, "server_error")
                tests.eq(contract_response.error_message, "Unknown Google error")
                tests.not_nil(contract_response.metadata)
            end)

            it("should handle error without message", function()
                local google_error = {
                    status_code = 500
                }

                local contract_response = mapper.map_error_response(google_error)

                tests.is_false(contract_response.success)
                tests.eq(contract_response.error, "server_error")
                tests.eq(contract_response.error_message, "Google API error")
            end)

            it("should handle error without status code", function()
                local google_error = {
                    message = "Something went wrong"
                }

                local contract_response = mapper.map_error_response(google_error)

                tests.is_false(contract_response.success)
                tests.eq(contract_response.error, "server_error")
                tests.eq(contract_response.error_message, "Something went wrong")
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

                tests.is_false(contract_response.success)
                tests.eq(contract_response.metadata.request_id, "req_error_123")
                tests.eq(contract_response.metadata.retry_after, 60)
            end)

            it("should handle missing metadata in error", function()
                local google_error = {
                    status_code = 400,
                    message = "Bad request"
                }

                local contract_response = mapper.map_error_response(google_error)

                tests.is_false(contract_response.success)
                tests.not_nil(contract_response.metadata)
                tests.is_nil(next(contract_response.metadata))
            end)

            it("should prioritize message patterns over status code", function()
                local google_error = {
                    status_code = 500,
                    message = "context length exceeded"
                }

                local contract_response = mapper.map_error_response(google_error)

                tests.is_false(contract_response.success)
                tests.eq(contract_response.error, "context_length_exceeded")
            end)

            it("should be case-insensitive for message matching", function()
                local google_error = {
                    status_code = 400,
                    message = "CONTEXT LENGTH EXCEEDED"
                }

                local contract_response = mapper.map_error_response(google_error)

                tests.is_false(contract_response.success)
                tests.eq(contract_response.error, "context_length_exceeded")
            end)

            it("should handle empty message", function()
                local google_error = {
                    status_code = 400,
                    message = ""
                }

                local contract_response = mapper.map_error_response(google_error)

                tests.is_false(contract_response.success)
                tests.eq(contract_response.error, "invalid_request")
                tests.eq(contract_response.error_message, "")
            end)

            it("should map 401 and 403 to authentication error", function()
                local codes = { 401, 403 }

                for _, code in ipairs(codes) do
                    local google_error = {
                        status_code = code,
                        message = "Auth failed"
                    }

                    local contract_response = mapper.map_error_response(google_error)

                    tests.eq(contract_response.error, "authentication_error")
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

                    tests.eq(contract_response.error, "server_error")
                end
            end)

            it("should handle complex error messages with multiple keywords", function()
                local google_error = {
                    status_code = 400,
                    message = "Request failed: context length exceeded and content filter triggered"
                }

                local contract_response = mapper.map_error_response(google_error)

                tests.is_false(contract_response.success)
                -- Should match first pattern (context length)
                tests.eq(contract_response.error, "context_length_exceeded")
            end)
        end)

        describe("Content Standardization", function()
            it("should return string content as-is", function()
                local content = "Simple string content"

                local result = mapper.standardize_content(content)

                tests.eq(result, "Simple string content")
            end)

            it("should extract text from array content", function()
                local content = {
                    { type = "text", text = "Hello " },
                    { type = "text", text = "world" }
                }

                local result = mapper.standardize_content(content)

                tests.eq(result, "Hello world")
            end)

            it("should ignore non-text parts", function()
                local content = {
                    { type = "text", text = "Text part" },
                    { type = "image", source = { url = "image.jpg" } },
                    { type = "text", text = " continues" }
                }

                local result = mapper.standardize_content(content)

                tests.eq(result, "Text part continues")
            end)

            it("should handle empty string", function()
                local content = ""

                local result = mapper.standardize_content(content)

                tests.eq(result, "")
            end)

            it("should handle nil content", function()
                local content = nil

                local result = mapper.standardize_content(content)

                tests.eq(result, "")
            end)

            it("should handle empty array", function()
                local content = {}

                local result = mapper.standardize_content(content)

                tests.eq(result, "")
            end)

            it("should handle array with only non-text parts", function()
                local content = {
                    { type = "image", source = { url = "image1.jpg" } },
                    { type = "image", source = { url = "image2.jpg" } }
                }

                local result = mapper.standardize_content(content)

                tests.eq(result, "")
            end)

            it("should handle array with empty text", function()
                local content = {
                    { type = "text", text = "" }
                }

                local result = mapper.standardize_content(content)

                tests.eq(result, "")
            end)

            it("should concatenate multiple text parts without separator", function()
                local content = {
                    { type = "text", text = "Part1" },
                    { type = "text", text = "Part2" },
                    { type = "text", text = "Part3" }
                }

                local result = mapper.standardize_content(content)

                tests.eq(result, "Part1Part2Part3")
            end)

            it("should preserve whitespace in text", function()
                local content = {
                    { type = "text", text = "  Leading and trailing  " }
                }

                local result = mapper.standardize_content(content)

                tests.eq(result, "  Leading and trailing  ")
            end)

            it("should handle text with newlines", function()
                local content = {
                    { type = "text", text = "Line 1\nLine 2\nLine 3" }
                }

                local result = mapper.standardize_content(content)

                tests.eq(result, "Line 1\nLine 2\nLine 3")
            end)

            it("should handle special characters", function()
                local content = {
                    { type = "text", text = "Special: @#$%^&*(){}[]<>|\\/" }
                }

                local result = mapper.standardize_content(content)

                tests.eq(result, "Special: @#$%^&*(){}[]<>|\\/")
            end)

            it("should handle unicode characters", function()
                local content = {
                    { type = "text", text = "Unicode: 你好 🌍 مرحبا" }
                }

                local result = mapper.standardize_content(content)

                tests.eq(result, "Unicode: 你好 🌍 مرحبا")
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

                tests.eq(result, "Start middle end")
            end)

            it("should handle very long text", function()
                local long_text = string.rep("a", 10000)
                local content = {
                    { type = "text", text = long_text }
                }

                local result = mapper.standardize_content(content)

                tests.eq(result, long_text)
                tests.eq(#result, 10000)
            end)

            it("should handle content with nil text field", function()
                local content = {
                    { type = "text", text = nil }
                }

                local result = mapper.standardize_content(content)

                tests.eq(result, "")
            end)

            it("should handle content with missing text field", function()
                local content = {
                    { type = "text" }
                }

                local result = mapper.standardize_content(content)

                tests.eq(result, "")
            end)

            it("should handle non-table, non-string content", function()
                local test_cases = {
                    123,
                    true,
                    false
                }

                for _, content in ipairs(test_cases) do
                    local result = mapper.standardize_content(content)
                    tests.eq(result, "")
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

                tests.eq(result, "Outer text")
            end)

            it("should handle content parts without type field", function()
                local content = {
                    { text = "Text without type" },
                    { type = "text", text = "Text with type" }
                }

                local result = mapper.standardize_content(content)

                tests.eq(result, "Text with type")
            end)
        end)

        describe("Finish Reason Preservation", function()
            it("should preserve LENGTH when finishReason is MAX_TOKENS with tool_calls", function()
                local google_response = {
                    candidates = {
                        {
                            content = {
                                parts = {
                                    { text = "I will call..." },
                                    { functionCall = { name = "test_tool", args = {} } }
                                }
                            },
                            finishReason = "MAX_TOKENS"
                        }
                    },
                    usageMetadata = { promptTokenCount = 100, candidatesTokenCount = 8000, totalTokenCount = 8100 }
                }

                local result = mapper.map_success_response(google_response)
                tests.eq(result.finish_reason, "length")
            end)

            it("should map STOP to TOOL_CALL when tool_calls are present", function()
                local google_response = {
                    candidates = {
                        {
                            content = {
                                parts = {
                                    { functionCall = { name = "test_tool", args = {} } }
                                }
                            },
                            finishReason = "STOP"
                        }
                    },
                    usageMetadata = { promptTokenCount = 50, candidatesTokenCount = 100, totalTokenCount = 150 }
                }

                local result = mapper.map_success_response(google_response)
                tests.eq(result.finish_reason, "tool_call")
            end)
        end)

        describe("Error Response Mapping", function()
            it("should return structured error for 429 rate limit", function()
                local response, err = mapper.map_error_response({
                    status_code = 429,
                    message = "Rate limited"
                })
                tests.eq(response.error, "rate_limit_exceeded")
                tests.not_nil(err)
                tests.eq(err:kind(), "RateLimited")
                tests.eq(err:retryable(), true)
            end)

            it("should return structured error for 500 server error", function()
                local response, err = mapper.map_error_response({
                    status_code = 500,
                    message = "Internal error"
                })
                tests.not_nil(err)
                tests.eq(err:kind(), "Unavailable")
                tests.eq(err:retryable(), true)
            end)

            it("should return non-retryable for 401 auth error", function()
                local _, err = mapper.map_error_response({
                    status_code = 401,
                    message = "Invalid credentials"
                })
                tests.not_nil(err)
                tests.eq(err:kind(), "PermissionDenied")
                tests.eq(err:retryable(), false)
            end)

            it("should return non-retryable for 404 model not found", function()
                local _, err = mapper.map_error_response({
                    status_code = 404,
                    message = "Model not found"
                })
                tests.not_nil(err)
                tests.eq(err:kind(), "NotFound")
                tests.eq(err:retryable(), false)
            end)

            it("should handle nil error", function()
                local response, err = mapper.map_error_response(nil)
                tests.eq(response.error, "server_error")
                tests.not_nil(err)
                tests.eq(err:kind(), "Unavailable")
                tests.eq(err:retryable(), true)
            end)
        end)
    end)
end

return tests.run_cases(define_tests)

