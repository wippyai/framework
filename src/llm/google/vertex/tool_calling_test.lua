local tool_calling = require("tool_calling")
local vertex = require("vertex_client")
local output = require("output")
local tools = require("tools")
local json = require("json")
local env = require("env")
local prompt = require("prompt")
local prompt_mapper = require("prompt_mapper")

local function define_tests()
    -- Toggle to enable/disable real API integration test
    local RUN_INTEGRATION_TESTS = env.get("ENABLE_INTEGRATION_TESTS")

    describe("Vertex AI Tool Calling Handler", function()
        local actual_project_id = nil
        local actual_location = nil

        -- Mock tool schemas for testing
        local mock_tools = {
            ["weather"] = {
                name = "get_weather",
                description = "Get weather information for a location",
                schema = {
                    type = "object",
                    properties = {
                        location = {
                            type = "string",
                            description = "The city or location"
                        },
                        units = {
                            type = "string",
                            enum = { "celsius", "fahrenheit" },
                            default = "celsius"
                        }
                    },
                    required = { "location" }
                }
            },
            ["calculator"] = {
                name = "calculate",
                description = "Perform a calculation",
                schema = {
                    type = "object",
                    properties = {
                        expression = {
                            type = "string",
                            description = "The mathematical expression to evaluate"
                        }
                    },
                    required = { "expression" }
                }
            }
        }

        before_all(function()
            -- Check if we have the necessary environment variables for integration tests
            actual_project_id = env.get("VERTEX_AI_PROJECT")
            actual_location = env.get("VERTEX_AI_LOCATION") or "us-central1"

            if RUN_INTEGRATION_TESTS then
                if actual_project_id and #actual_project_id > 5 then
                    print("Integration tests will run with real Vertex AI project")
                else
                    print("Integration tests disabled - no valid project ID found")
                    RUN_INTEGRATION_TESTS = false
                end
            else
                print("Integration tests disabled - set ENABLE_INTEGRATION_TESTS=true to enable")
            end

            -- Mock the tools.get_tool_schemas function to return our test tools
            mock(tools, "get_tool_schemas", function(tool_ids)
                local result = {}
                local errors = {}

                for _, id in ipairs(tool_ids) do
                    local tool_name = id:match(":([^:]+)$") or id
                    if mock_tools[tool_name] then
                        result[id] = mock_tools[tool_name]
                    else
                        errors[id] = "Tool not found: " .. id
                    end
                end

                return result, next(errors) and errors or nil
            end)
        end)

        it("should validate required parameters", function()
            -- Test missing model
            local response = tool_calling.handler({
                messages = { { role = "user", content = "Hello" } }
            })

            expect(response.error).to_equal(output.ERROR_TYPE.INVALID_REQUEST)
            expect(response.error_message).to_contain("Model is required")

            -- Test missing messages
            local response2 = tool_calling.handler({
                model = "gemini-1.5-pro"
            })

            expect(response2.error).to_equal(output.ERROR_TYPE.INVALID_REQUEST)
            expect(response2.error_message).to_contain("No messages provided")
        end)

        it("should handle text generation without tools", function()
            -- Mock the prompt mapper function
            mock(prompt_mapper, "map_to_vertex", function(messages)
                -- Return properly formatted Vertex AI messages
                return {
                    {
                        role = "user",
                        parts = {
                            { text = "Hello world" }
                        }
                    }
                }
            end)

            -- Mock the client request function
            mock(vertex, "request", function(endpoint_path, model, payload, options)
                -- Validate the request
                expect(endpoint_path).to_equal(vertex.DEFAULT_GENERATE_CONTENT_ENDPOINT)
                expect(model).to_equal("gemini-1.5-pro")
                -- Check if contents array is present
                expect(payload.contents).not_to_be_nil("Expected contents array")
                expect(#payload.contents).to_equal(1, "Expected 1 message")
                expect(payload.contents[1].role).to_equal("user")

                -- Ensure no tools are set
                expect(payload.tools).to_be_nil()

                -- Return mock successful response with text content
                return {
                    candidates = {
                        {
                            content = {
                                parts = {
                                    { text = "Hello! How can I assist you today?" }
                                }
                            },
                            finishReason = "STOP"
                        }
                    },
                    usageMetadata = {
                        promptTokenCount = 10,
                        candidatesTokenCount = 8,
                        totalTokenCount = 18
                    },
                    metadata = {
                        request_id = "req_mocktext123"
                    }
                }
            end)

            -- Create proper prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Hello world")

            -- Call handler without tools
            local response = tool_calling.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages()
            })

            -- Verify the response structure
            expect(response.error).to_be_nil("Expected no error")
            expect(response.result).to_equal("Hello! How can I assist you today?")
            expect(response.tokens).not_to_be_nil("Expected token information")
            expect(response.tokens.prompt_tokens).to_equal(10)
            expect(response.tokens.completion_tokens).to_equal(8)
            expect(response.tokens.total_tokens).to_equal(18)
            expect(response.metadata).not_to_be_nil("Expected metadata")
            expect(response.metadata.request_id).to_equal("req_mocktext123")
            expect(response.finish_reason).to_equal("stop")
            expect(response.provider).to_equal("vertex")
            expect(response.model).to_equal("gemini-1.5-pro")
        end)

        it("should handle successful tool calls with tool_ids", function()
            -- Mock the prompt mapper function
            mock(prompt_mapper, "map_to_vertex", function(messages)
                -- Return properly formatted Vertex AI messages
                return {
                    {
                        role = "user",
                        parts = {
                            { text = "What's the weather in New York?" }
                        }
                    }
                }
            end)

            -- Mock the client request function
            mock(vertex, "request", function(endpoint_path, model, payload, options)
                -- Validate the request
                expect(endpoint_path).to_equal(vertex.DEFAULT_GENERATE_CONTENT_ENDPOINT)
                expect(model).to_equal("gemini-1.5-pro")

                -- Check if contents array is present
                expect(payload.contents).not_to_be_nil("Expected contents array")
                expect(#payload.contents).to_equal(1, "Expected 1 message")
                expect(payload.contents[1].role).to_equal("user")

                -- Verify tools are set correctly
                expect(payload.tools).not_to_be_nil("Expected tools to be set")
                expect(payload.tools.function_declarations).not_to_be_nil("Expected function_declarations")
                expect(#payload.tools.function_declarations).to_equal(1)
                expect(payload.tools.function_declarations[1].name).to_equal("get_weather")

                -- Verify toolConfig
                expect(payload.toolConfig).not_to_be_nil("Expected toolConfig")
                expect(payload.toolConfig.functionCallingConfig).not_to_be_nil("Expected functionCallingConfig")
                expect(payload.toolConfig.functionCallingConfig.mode).to_equal("AUTO")

                -- Return mock successful response with tool calls
                return {
                    candidates = {
                        {
                            content = {
                                parts = {
                                    { text = "I'll check the weather for you." },
                                    {
                                        functionCall = {
                                            name = "get_weather",
                                            args = {
                                                location = "New York",
                                                units = "celsius"
                                            }
                                        }
                                    }
                                }
                            },
                            finishReason = "STOP"
                        }
                    },
                    usageMetadata = {
                        promptTokenCount = 42,
                        candidatesTokenCount = 15,
                        totalTokenCount = 57
                    },
                    metadata = {
                        request_id = "req_mocktool123"
                    }
                }
            end)

            -- Create proper prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("What's the weather in New York?")

            -- Call handler with tool IDs
            local response = tool_calling.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages(),
                tool_ids = { "system:weather" } -- This will match our mocked tool IDs
            })

            -- Verify the response structure
            expect(response.error).to_be_nil("Expected no error")
            expect(response.result).not_to_be_nil("Expected result object")
            expect(response.result.content).to_equal("I'll check the weather for you.")
            expect(response.result.tool_calls).not_to_be_nil("Expected tool_calls array")
            expect(#response.result.tool_calls).to_equal(1)

            -- Verify first tool call
            local tool_call = response.result.tool_calls[1]
            expect(tool_call.name).to_equal("get_weather")
            expect(tool_call.arguments).not_to_be_nil("Expected parsed arguments")
            expect(tool_call.arguments.location).to_equal("New York")
            expect(tool_call.arguments.units).to_equal("celsius")

            -- Verify registry_id
            expect(tool_call.registry_id).to_equal("system:weather")

            -- Verify provider and metadata
            expect(response.tokens).not_to_be_nil("Expected token information")
            expect(response.tokens.prompt_tokens).to_equal(42)
            expect(response.tokens.completion_tokens).to_equal(15)
            expect(response.tokens.total_tokens).to_equal(57)
            expect(response.metadata).not_to_be_nil("Expected metadata")
            expect(response.metadata.request_id).to_equal("req_mocktool123")
            expect(response.finish_reason).to_equal("tool_call")
            expect(response.provider).to_equal("vertex")
            expect(response.model).to_equal("gemini-1.5-pro")
        end)

        it("should handle successful tool calls with direct tool_schemas", function()
            -- Mock the prompt mapper function
            mock(prompt_mapper, "map_to_vertex", function(messages)
                -- Return properly formatted Vertex AI messages
                return {
                    {
                        role = "user",
                        parts = {
                            { text = "Calculate 2+2" }
                        }
                    }
                }
            end)

            -- Mock the client request function
            mock(vertex, "request", function(endpoint_path, model, payload, options)
                -- Validate the request
                expect(endpoint_path).to_equal(vertex.DEFAULT_GENERATE_CONTENT_ENDPOINT)
                expect(model).to_equal("gemini-1.5-pro")
                -- Check if contents array is present
                expect(payload.contents).not_to_be_nil("Expected contents array")
                expect(#payload.contents).to_equal(1, "Expected 1 message")
                expect(payload.contents[1].role).to_equal("user")

                -- Verify tools are set correctly
                expect(payload.tools).not_to_be_nil("Expected tools to be set")
                expect(payload.tools.function_declarations).not_to_be_nil("Expected function_declarations")
                expect(#payload.tools.function_declarations).to_equal(1)
                expect(payload.tools.function_declarations[1].name).to_equal("calculate")

                -- Return mock successful response with tool calls
                return {
                    candidates = {
                        {
                            content = {
                                parts = {
                                    { text = "I'll calculate that for you." },
                                    {
                                        functionCall = {
                                            name = "calculate",
                                            args = {
                                                expression = "2+2"
                                            }
                                        }
                                    }
                                }
                            },
                            finishReason = "STOP"
                        }
                    },
                    usageMetadata = {
                        promptTokenCount = 38,
                        candidatesTokenCount = 12,
                        totalTokenCount = 50
                    }
                }
            end)

            -- Create proper prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Calculate 2+2")

            -- Call handler with direct tool schemas
            local response = tool_calling.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages(),
                tool_schemas = {
                    ["custom:calculator"] = mock_tools["calculator"]
                }
            })

            -- Verify the response structure
            expect(response.error).to_be_nil("Expected no error")
            expect(response.result).not_to_be_nil("Expected result object")
            expect(response.result.content).to_equal("I'll calculate that for you.")
            expect(response.result.tool_calls).not_to_be_nil("Expected tool_calls array")
            expect(#response.result.tool_calls).to_equal(1)

            -- Verify first tool call
            local tool_call = response.result.tool_calls[1]
            expect(tool_call.name).to_equal("calculate")
            expect(tool_call.arguments.expression).to_equal("2+2")

            -- Verify registry_id
            expect(tool_call.registry_id).to_equal("custom:calculator")

            -- Verify finish reason
            expect(response.finish_reason).to_equal("tool_call")
        end)

        it("should handle multiple tool calls", function()
            -- Mock the prompt mapper function
            mock(prompt_mapper, "map_to_vertex", function(messages)
                -- Return properly formatted Vertex AI messages
                return {
                    {
                        role = "user",
                        parts = {
                            { text = "What's the weather in New York and calculate 2+2" }
                        }
                    }
                }
            end)

            -- Mock the client request function
            mock(vertex, "request", function(endpoint_path, model, payload, options)
                -- Validate the request
                expect(endpoint_path).to_equal(vertex.DEFAULT_GENERATE_CONTENT_ENDPOINT)
                expect(model).to_equal("gemini-1.5-pro")

                -- Verify tools are set correctly
                expect(payload.tools).not_to_be_nil("Expected tools to be set")
                expect(payload.tools.function_declarations).not_to_be_nil("Expected function_declarations")
                expect(#payload.tools.function_declarations).to_equal(2)

                -- Return mock successful response with multiple tool calls
                return {
                    candidates = {
                        {
                            content = {
                                parts = {
                                    { text = "I'll check both of those for you." },
                                    {
                                        functionCall = {
                                            name = "get_weather",
                                            args = {
                                                location = "New York",
                                                units = "celsius"
                                            }
                                        }
                                    },
                                    {
                                        functionCall = {
                                            name = "calculate",
                                            args = {
                                                expression = "2+2"
                                            }
                                        }
                                    }
                                }
                            },
                            finishReason = "STOP"
                        }
                    },
                    usageMetadata = {
                        promptTokenCount = 55,
                        candidatesTokenCount = 22,
                        totalTokenCount = 77
                    }
                }
            end)

            -- Create proper prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("What's the weather in New York and calculate 2+2")

            -- Call handler with both tools
            local response = tool_calling.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages(),
                tool_schemas = {
                    ["system:weather"] = mock_tools["weather"],
                    ["custom:calculator"] = mock_tools["calculator"]
                }
            })

            -- Verify the response structure
            expect(response.error).to_be_nil("Expected no error")
            expect(response.result.tool_calls).not_to_be_nil("Expected tool_calls array")
            expect(#response.result.tool_calls).to_equal(2)

            -- Verify weather tool call
            local weather_call = response.result.tool_calls[1]
            expect(weather_call.name).to_equal("get_weather")
            expect(weather_call.arguments.location).to_equal("New York")
            expect(weather_call.registry_id).to_equal("system:weather")

            -- Verify calculator tool call
            local calc_call = response.result.tool_calls[2]
            expect(calc_call.name).to_equal("calculate")
            expect(calc_call.registry_id).to_equal("custom:calculator")
            expect(calc_call.arguments.expression).to_equal("2+2")
        end)

        it("should handle forced tool calls", function()
            -- Mock the prompt mapper function
            mock(prompt_mapper, "map_to_vertex", function(messages)
                -- Return properly formatted Vertex AI messages
                return {
                    {
                        role = "user",
                        parts = {
                            { text = "What should I do today?" }
                        }
                    }
                }
            end)

            -- Mock the client request function
            mock(vertex, "request", function(endpoint_path, model, payload, options)
                -- Validate the request has forced tool choice
                expect(payload.toolConfig).not_to_be_nil("Expected toolConfig to be set")
                expect(payload.toolConfig.functionCallingConfig).not_to_be_nil("Expected functionCallingConfig")
                expect(payload.toolConfig.functionCallingConfig.mode).to_equal("ANY")
                expect(payload.toolConfig.functionCallingConfig.allowedFunctionNames[1]).to_equal("get_weather")

                -- Return mock successful response with weather tool call
                return {
                    candidates = {
                        {
                            content = {
                                parts = {
                                    { text = "I'll check the weather for you." },
                                    {
                                        functionCall = {
                                            name = "get_weather",
                                            args = {
                                                location = "New York",
                                                units = "celsius"
                                            }
                                        }
                                    }
                                }
                            },
                            finishReason = "STOP"
                        }
                    },
                    usageMetadata = {
                        promptTokenCount = 45,
                        candidatesTokenCount = 15,
                        totalTokenCount = 60
                    }
                }
            end)

            -- Create prompt
            local promptBuilder = prompt.new()
            promptBuilder:add_user("What should I do today?")

            -- Call handler with forced tool call
            local response = tool_calling.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages(),
                tool_schemas = {
                    ["system:weather"] = mock_tools["weather"],
                    ["custom:calculator"] = mock_tools["calculator"]
                },
                tool_call = "get_weather" -- Force weather tool
            })

            -- Verify response
            expect(response.error).to_be_nil("Expected no error")
            expect(response.result.tool_calls[1].name).to_equal("get_weather")
        end)

        it("should handle invalid tool specifications", function()
            -- Mock the client request function
            mock(vertex, "request", function(endpoint_path, model, payload, options)
                -- This shouldn't be called
                fail("Request should not be made with invalid tool")
                return nil
            end)

            -- Create prompt
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Test")

            -- Call handler with non-existent forced tool
            local response = tool_calling.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages(),
                tool_schemas = {
                    ["system:weather"] = mock_tools["weather"]
                },
                tool_call = "nonexistent_tool" -- Force non-existent tool
            })

            -- Verify error
            expect(response.error).to_equal(output.ERROR_TYPE.INVALID_REQUEST)
            expect(response.error_message).to_contain("not found in available tools")
        end)

        it("should handle empty or invalid response structure", function()
            -- Mock the prompt mapper function
            mock(prompt_mapper, "map_to_vertex", function(messages)
                return messages
            end)

            -- Mock the client request function
            mock(vertex, "request", function(endpoint_path, model, payload, options)
                -- Return empty response
                return {
                    candidates = {}
                }
            end)

            -- Create prompt
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Test message")

            -- Call handler
            local response = tool_calling.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages()
            })

            -- Verify error handling
            expect(response.error).to_equal(output.ERROR_TYPE.SERVER_ERROR)
            expect(response.error_message).to_contain("Invalid response structure")
        end)

        it("should handle server errors correctly", function()
            -- Mock the prompt mapper function
            mock(prompt_mapper, "map_to_vertex", function(messages)
                return messages
            end)

            -- Mock the client request function to simulate a server error
            mock(vertex, "request", function(endpoint_path, model, payload, options)
                -- Return nil and an error
                return nil, {
                    status = 500,
                    message = "Internal server error",
                    code = "INTERNAL"
                }
            end)

            -- Create prompt
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Test")

            -- Call handler
            local response = tool_calling.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages()
            })

            -- Verify error
            expect(response.error).to_equal(output.ERROR_TYPE.SERVER_ERROR)
            expect(response.error_message).to_contain("Internal server error")
        end)

        it("should respect system messages when using tool calling", function()
            -- Mock the prompt mapper function
            mock(prompt_mapper, "map_to_vertex", function(messages)
                -- Check if system message is included
                expect(#messages >= 2).to_be_true("Expected at least 2 messages (system + user)")

                local has_system_msg = false
                for _, msg in ipairs(messages) do
                    if msg.role == "system" then
                        has_system_msg = true
                        break
                    end
                end

                expect(has_system_msg).to_be_true("System message should be present")

                -- Return properly formatted Vertex messages
                return {
                    {
                        role = "system",
                        parts = {
                            { text = "You are an assistant that should always use tools when available." }
                        }
                    },
                    {
                        role = "user",
                        parts = {
                            { text = "What's the weather in New York?" }
                        }
                    }
                }
            end)

            -- Mock the client request function
            mock(vertex, "request", function(endpoint_path, model, payload, options)
                -- Check if system message is included
                expect(#payload.contents).to_equal(2)
                expect(payload.contents[1].role).to_equal("system")

                -- Return mock response
                return {
                    candidates = {
                        {
                            content = {
                                parts = {
                                    { text = "I'll check the weather as instructed." },
                                    {
                                        functionCall = {
                                            name = "get_weather",
                                            args = {
                                                location = "New York",
                                                units = "celsius"
                                            }
                                        }
                                    }
                                }
                            },
                            finishReason = "STOP"
                        }
                    },
                    usageMetadata = {
                        promptTokenCount = 55,
                        candidatesTokenCount = 18,
                        totalTokenCount = 73
                    }
                }
            end)

            -- Create prompt with system message
            local promptBuilder = prompt.new()
            promptBuilder:add_system("You are an assistant that should always use tools when available.")
            promptBuilder:add_user("What's the weather in New York?")

            -- Call handler
            local response = tool_calling.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages(),
                tool_ids = { "system:weather" }
            })

            -- Verify response
            expect(response.error).to_be_nil("Expected no error")
            expect(response.result.content).to_equal("I'll check the weather as instructed.")
            expect(response.result.tool_calls[1].name).to_equal("get_weather")
        end)

        it("should handle tool calls with IDs correctly", function()
            -- Mock the prompt mapper function
            mock(prompt_mapper, "map_to_vertex", function(messages)
                return {
                    {
                        role = "user",
                        parts = {
                            { text = "Calculate 42 * 3" }
                        }
                    }
                }
            end)

            -- Mock the client request function
            mock(vertex, "request", function(endpoint_path, model, payload, options)
                -- Return mock response with tool call but no ID (Vertex doesn't provide IDs)
                return {
                    candidates = {
                        {
                            content = {
                                parts = {
                                    { text = "Let me calculate that for you." },
                                    {
                                        functionCall = {
                                            name = "calculate",
                                            args = {
                                                expression = "42 * 3"
                                            }
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
            end)

            -- Create prompt
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Calculate 42 * 3")

            -- Call handler
            local response = tool_calling.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages(),
                tool_schemas = {
                    ["custom:calculator"] = mock_tools["calculator"]
                }
            })

            -- Verify response
            expect(response.error).to_be_nil("Expected no error")
            expect(response.result.tool_calls[1].id).not_to_be_nil("Tool call should have an auto-generated ID")
            expect(response.result.tool_calls[1].name).to_equal("calculate")
            expect(response.result.tool_calls[1].arguments.expression).to_equal("42 * 3")
        end)

        it("should handle complex content structures", function()
            -- Mock the prompt mapper function
            mock(prompt_mapper, "map_to_vertex", function(messages)
                return {
                    {
                        role = "user",
                        parts = {
                            { text = "What's the weather and calculate something" }
                        }
                    }
                }
            end)

            -- Mock the client request function
            mock(vertex, "request", function(endpoint_path, model, payload, options)
                -- Return mock response with mixed text/function content
                return {
                    candidates = {
                        {
                            content = {
                                parts = {
                                    { text = "I'll help with those tasks." },
                                    {
                                        functionCall = {
                                            name = "get_weather",
                                            args = {
                                                location = "New York",
                                                units = "celsius"
                                            }
                                        }
                                    },
                                    { text = "And here's the calculation you asked for:" },
                                    {
                                        functionCall = {
                                            name = "calculate",
                                            args = {
                                                expression = "25 * 4"
                                            }
                                        }
                                    }
                                }
                            },
                            finishReason = "STOP"
                        }
                    },
                    usageMetadata = {
                        promptTokenCount = 30,
                        candidatesTokenCount = 25,
                        totalTokenCount = 55
                    }
                }
            end)

            -- Create prompt
            local promptBuilder = prompt.new()
            promptBuilder:add_user("What's the weather and calculate something")

            -- Call handler
            local response = tool_calling.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages(),
                tool_schemas = {
                    ["system:weather"] = mock_tools["weather"],
                    ["custom:calculator"] = mock_tools["calculator"]
                }
            })

            -- Verify response
            expect(response.error).to_be_nil("Expected no error")
            expect(response.result.content).to_equal("I'll help with those tasks.And here's the calculation you asked for:")
            expect(#response.result.tool_calls).to_equal(2, "Expected 2 tool calls")

            -- Verify first tool call (weather)
            expect(response.result.tool_calls[1].name).to_equal("get_weather")
            expect(response.result.tool_calls[1].arguments.location).to_equal("New York")

            -- Verify second tool call (calculator)
            expect(response.result.tool_calls[2].name).to_equal("calculate")
            expect(response.result.tool_calls[2].arguments.expression).to_equal("25 * 4")
        end)

        it("should connect to real Vertex AI without tools", function()
            -- Skip if not running integration tests
            if not RUN_INTEGRATION_TESTS then
                print("Skipping integration test - not enabled")
                return
            end

            -- Create proper prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Hello, please respond in exactly 10 words.")

            -- Call handler without tools using real API
            local response = tool_calling.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages(),
                project = actual_project_id,
                location = actual_location,
                options = {
                    temperature = 0 -- For deterministic results
                }
            })

            -- Verify the response structure
            expect(response.error).to_be_nil("API request failed: " .. (response.error_message or "unknown error"))
            expect(response.result).not_to_be_nil("No content in response")

            -- Check token information
            expect(response.tokens).not_to_be_nil("No token information")
            expect(response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens reported")
            expect(response.tokens.completion_tokens > 0).to_be_true("No completion tokens reported")
            expect(response.tokens.total_tokens > 0).to_be_true("No total tokens reported")

            -- Check other metadata
            expect(response.provider).to_equal("vertex")
            expect(response.model).to_equal("gemini-1.5-pro")

            -- Print actual response for debugging
            print("Response content: " .. (response.result or "nil"))
        end)

        it("should handle real tool calls with direct tool_schemas", function()
            -- Skip if not running integration tests
            if not RUN_INTEGRATION_TESTS then
                print("Skipping integration test - not enabled")
                return
            end

            -- Create proper prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Calculate 25 * 32")

            -- Call handler with direct tool schemas
            local response = tool_calling.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages(),
                tool_schemas = {
                    ["custom:calculator"] = mock_tools["calculator"]
                },
                project = actual_project_id,
                location = actual_location,
                options = {
                    temperature = 0 -- For deterministic results
                }
            })

            -- Verify the response structure
            expect(response.error).to_be_nil("API request failed: " .. (response.error_message or "unknown error"))
            expect(response.result).not_to_be_nil("Expected result object")
            expect(response.result.content).not_to_be_nil("No content in response")
            expect(response.result.tool_calls).not_to_be_nil("No tool calls in response")
            expect(#response.result.tool_calls > 0).to_be_true("Expected at least one tool call")

            -- Verify the tool call details
            local tool_call = response.result.tool_calls[1]
            expect(tool_call.name).to_equal("calculate")
            expect(tool_call.arguments).not_to_be_nil("No arguments in tool call")
            expect(tool_call.arguments.expression).not_to_be_nil("Missing expression in calculator arguments")

            -- The expression should be equivalent to 25 * 32 (might have spaces, etc.)
            local expression = tool_call.arguments.expression
            expect(expression:match("25") and expression:match("32") and
                (expression:match("%*") or expression:match("x"))).not_to_be_nil(
                "Expression doesn't match expected calculation: " .. expression)

            -- Verify finish reason
            expect(response.finish_reason).to_equal("tool_call")

            -- Print actual tool call for debugging
            print("Tool call: " .. json.encode(response.result.tool_calls[1]))
        end)

        it("should handle weather tool calls with real API", function()
            -- Skip if not running integration tests
            if not RUN_INTEGRATION_TESTS then
                print("Skipping integration test - not enabled")
                return
            end

            -- Create proper prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("What's the weather in New York?")

            -- Call handler with weather tool
            local response = tool_calling.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages(),
                tool_schemas = {
                    ["system:weather"] = mock_tools["weather"]
                },
                project = actual_project_id,
                location = actual_location,
                options = {
                    temperature = 0 -- For deterministic results
                }
            })

            -- Verify the response structure
            expect(response.error).to_be_nil("API request failed: " .. (response.error_message or "unknown error"))
            expect(response.result).not_to_be_nil("Expected result object")
            expect(response.result.tool_calls).not_to_be_nil("No tool calls in response")
            expect(#response.result.tool_calls > 0).to_be_true("Expected at least one tool call")

            -- Verify the weather tool call
            local tool_call = response.result.tool_calls[1]
            expect(tool_call.name).to_equal("get_weather")
            expect(tool_call.arguments).not_to_be_nil("No arguments in tool call")
            expect(tool_call.arguments.location).not_to_be_nil("Missing location in weather arguments")

            -- Should have New York in the location (case insensitive)
            local location = tool_call.arguments.location:lower()
            expect(location:match("new york")).not_to_be_nil("Location doesn't match expected: " .. location)

            -- Check for units (optional parameter)
            if tool_call.arguments.units then
                expect(tool_call.arguments.units == "celsius" or tool_call.arguments.units == "fahrenheit")
                    .to_be_true("Units not in expected values: " .. tool_call.arguments.units)
            end

            -- Print actual tool call for debugging
            print("Weather tool call: " .. json.encode(response.result.tool_calls[1]))
        end)

        it("should handle multiple tool calls with real API", function()
            -- Skip if not running integration tests
            if not RUN_INTEGRATION_TESTS then
                print("Skipping integration test - not enabled")
                return
            end

            -- Create proper prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("What's the weather in London and calculate 15 * 7?")

            -- Call handler with both tools
            local response = tool_calling.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages(),
                tool_schemas = {
                    ["system:weather"] = mock_tools["weather"],
                    ["custom:calculator"] = mock_tools["calculator"]
                },
                project = actual_project_id,
                location = actual_location,
                options = {
                    temperature = 0 -- For deterministic results
                }
            })

            -- Verify the response structure
            expect(response.error).to_be_nil("API request failed: " .. (response.error_message or "unknown error"))
            expect(response.result).not_to_be_nil("Expected result object")
            expect(response.result.tool_calls).not_to_be_nil("No tool calls in response")

            -- Might return both tool calls or just one depending on the model's decision
            -- Let's check if at least one valid tool call is present
            expect(#response.result.tool_calls > 0).to_be_true("Expected at least one tool call")

            -- Collect call types to verify at least one is present
            local has_weather = false
            local has_calculator = false

            for _, tool_call in ipairs(response.result.tool_calls) do
                if tool_call.name == "get_weather" then
                    has_weather = true
                    -- Verify weather params
                    expect(tool_call.arguments.location).not_to_be_nil("Missing location in weather arguments")
                    expect(tool_call.arguments.location:lower():match("london")).not_to_be_nil(
                        "Location doesn't match expected: " .. tool_call.arguments.location)
                elseif tool_call.name == "calculate" then
                    has_calculator = true
                    -- Verify calculator params
                    expect(tool_call.arguments.expression).not_to_be_nil("Missing expression in calculator arguments")
                    local expression = tool_call.arguments.expression
                    expect(expression:match("15") and expression:match("7") and
                        (expression:match("%*") or expression:match("x"))).not_to_be_nil(
                        "Expression doesn't match expected calculation: " .. expression)
                end
            end

            -- At least one tool should be used
            expect(has_weather or has_calculator).to_be_true("No valid tool calls found")

            -- Print actual tool calls for debugging
            print("Tool calls: " .. json.encode(response.result.tool_calls))
        end)

        it("should respect system prompts with tool calls using real API", function()
            -- Skip if not running integration tests
            if not RUN_INTEGRATION_TESTS then
                print("Skipping integration test - not enabled")
                return
            end

            -- Create a prompt with system message and user query
            local promptBuilder = prompt.new()
            promptBuilder:add_system("You are a helpful assistant who prefers to always use tools when available.")
            promptBuilder:add_user("What's 125 divided by 5?")

            -- Call handler with calculator tool
            local response = tool_calling.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages(),
                tool_schemas = {
                    ["custom:calculator"] = mock_tools["calculator"]
                },
                project = actual_project_id,
                location = actual_location,
                options = {
                    temperature = 0 -- For deterministic results
                }
            })

            -- Verify response
            expect(response.error).to_be_nil("API request failed: " .. (response.error_message or "unknown error"))
            expect(response.result).not_to_be_nil("No result returned")
            expect(response.result.tool_calls).not_to_be_nil("No tool calls in response")
            expect(#response.result.tool_calls > 0).to_be_true("Expected at least one tool call")

            -- Verify calculator was used
            local calculator_used = false
            for _, tool_call in ipairs(response.result.tool_calls) do
                if tool_call.name == "calculate" then
                    calculator_used = true
                    -- Verify expression contains our numbers
                    local expression = tool_call.arguments.expression
                    expect(expression:match("125") and
                        (expression:match("5") or expression:match("divide") or expression:match("/"))).not_to_be_nil(
                        "Expression doesn't match expected division: " .. expression)
                end
            end

            expect(calculator_used).to_be_true("Calculator tool wasn't used despite system prompt")
        end)

        it("should force specific tool call with real API", function()
            -- Skip if not running integration tests
            if not RUN_INTEGRATION_TESTS then
                print("Skipping integration test - not enabled")
                return
            end

            -- Create ambiguous prompt
            local promptBuilder = prompt.new()
            promptBuilder:add_user("What should I do today in Seattle?")

            -- Call handler with forced weather tool
            local response = tool_calling.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages(),
                tool_schemas = {
                    ["system:weather"] = mock_tools["weather"],
                    ["custom:calculator"] = mock_tools["calculator"]
                },
                tool_call = "get_weather", -- Force weather tool
                project = actual_project_id,
                location = actual_location,
                options = {
                    temperature = 0
                }
            })

            -- Verify response
            expect(response.error).to_be_nil("API request failed: " .. (response.error_message or "unknown error"))
            expect(response.result.tool_calls).not_to_be_nil("No tool calls in response")
            expect(#response.result.tool_calls).to_equal(1, "Expected exactly one tool call")
            expect(response.result.tool_calls[1].name).to_equal("get_weather", "Wrong tool was called")

            -- Verify weather has Seattle in the location
            expect(response.result.tool_calls[1].arguments.location:lower():match("seattle")).not_to_be_nil(
                "Location doesn't contain Seattle: " .. response.result.tool_calls[1].arguments.location)
        end)

        it("should handle complete tool call flow with real API", function()
            -- Skip if not running integration tests
            if not RUN_INTEGRATION_TESTS then
                print("Skipping integration test - not enabled")
                return
            end

            -- Create initial prompt with a clear calculator request
            local promptBuilder = prompt.new()
            promptBuilder:add_user("What is the square root of 1764?")
            promptBuilder:add_developer("Use the calculator tool to solve this. Don't solve it directly.")

            -- Step 1: Initial request with tool
            local response = tool_calling.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages(),
                tool_schemas = {
                    ["custom:calculator"] = mock_tools["calculator"]
                },
                project = actual_project_id,
                location = actual_location,
                options = {
                    temperature = 0, -- For deterministic results
                    top_p = 1       -- For reproducible results
                }
            })

            -- Verify the response structure
            expect(response.error).to_be_nil("API request failed: " .. (response.error_message or "unknown error"))
            expect(response.result).not_to_be_nil("No result returned")
            expect(response.result.tool_calls).not_to_be_nil("No tool calls in response")
            expect(#response.result.tool_calls > 0).to_be_true("Expected at least one tool call")

            -- Verify the calculator was used
            local tool_call = response.result.tool_calls[1]
            expect(tool_call.name).to_equal("calculate", "Expected calculator tool")
            expect(tool_call.id).not_to_be_nil("Tool call missing ID")
            expect(tool_call.arguments).not_to_be_nil("Tool call missing arguments")

            -- Use the actual content from the API response
            promptBuilder:add_assistant(response.result.content)

            -- Add the function call to the conversation using function_call format
            promptBuilder:add_function_call(tool_call.name, tool_call.arguments, tool_call.id)

            -- Simulate executing the tool
            local calc_result = math.sqrt(1764)
            local tool_result = "The square root of 1764 is " .. calc_result

            -- Add the result to the conversation
            promptBuilder:add_function_result(tool_call.name, tool_result, tool_call.id)

            -- Step 2: Second request to continue conversation with the tool result
            local continuation_response = tool_calling.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages(),
                project = actual_project_id,
                location = actual_location,
                options = {
                    temperature = 0, -- For deterministic results
                    top_p = 1       -- For reproducible results
                }
            })

            -- Verify the continuation response
            expect(continuation_response.error).to_be_nil("API request failed in continuation: " ..
                (continuation_response.error_message or "unknown error"))
            expect(continuation_response.result).not_to_be_nil("No continuation result returned")

            -- Result should be a text response with the answer
            local result_text = ""
            if type(continuation_response.result) == "string" then
                result_text = continuation_response.result
            elseif type(continuation_response.result) == "table" and continuation_response.result.content then
                result_text = continuation_response.result.content
            end

            expect(result_text).not_to_be_nil("No text content in continuation response")
            expect(#result_text > 0).to_be_true("Empty text content in continuation response")

            -- Response should mention the correct answer (42)
            expect(result_text:match("42") ~= nil).to_be_true("Response doesn't include correct answer")

            -- Verify token information
            expect(continuation_response.tokens).not_to_be_nil("No token information")
            expect(continuation_response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens reported")
            expect(continuation_response.tokens.completion_tokens > 0).to_be_true("No completion tokens reported")
            expect(continuation_response.tokens.total_tokens > 0).to_be_true("No total tokens reported")

            -- Verify provider info
            expect(continuation_response.provider).to_equal("vertex", "Wrong provider")
            expect(continuation_response.model).to_equal("gemini-1.5-pro", "Wrong model")

            print("Complete flow test successful. Final response: " .. result_text:sub(1, 100) .. "...")
        end)
    end)
end

return require("test").run_cases(define_tests)
