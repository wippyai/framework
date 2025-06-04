local tool_calling = require("tool_calling")
local claude_client = require("claude_client")
local output = require("output")
local tools = require("tools")
local json = require("json")
local env = require("env")
local prompt = require("prompt")

local function define_tests()
    -- Toggle to enable/disable real API integration test
    local RUN_INTEGRATION_TESTS = env.get("ENABLE_INTEGRATION_TESTS")

    describe("Claude Tool Calling Handler", function()
        local actual_api_key = nil

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
            -- Check if we have a real API key for integration tests
            actual_api_key = env.get("ANTHROPIC_API_KEY")

            if RUN_INTEGRATION_TESTS then
                if actual_api_key and #actual_api_key > 10 then
                    print("Integration tests will run with real API key")
                else
                    print("Integration tests disabled - no valid API key found")
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
                model = "claude-3-5-haiku-20241022"
            })

            expect(response2.error).to_equal(output.ERROR_TYPE.INVALID_REQUEST)
            expect(response2.error_message).to_contain("No messages provided")
        end)

        it("should handle text generation without tools", function()
            -- Mock the client request function instead of create_message
            mock(claude_client, "request", function(endpoint_path, payload, options)
                -- Validate the request has appropriate fields
                expect(endpoint_path).to_equal(claude_client.API_ENDPOINTS.MESSAGES)
                expect(payload.model).to_equal("claude-3-5-haiku-20241022")
                expect(payload.messages).not_to_be_nil("Expected messages array")
                expect(#payload.messages).to_equal(1, "Expected 1 message")

                -- Ensure no tools are set
                expect(payload.tools).to_be_nil()

                -- Return mock successful response with text content
                return {
                    content = {
                        {
                            type = "text",
                            text = "Hello! How can I assist you today?"
                        }
                    },
                    id = "msg_notools123",
                    model = "claude-3-5-haiku-20241022",
                    role = "assistant",
                    stop_reason = "end_turn",
                    stop_sequence = nil,
                    type = "message",
                    usage = {
                        input_tokens = 10,
                        output_tokens = 8
                    },
                    metadata = {
                        request_id = "req_mock123"
                    }
                }
            end)

            -- Create proper prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Hello world")

            -- Call handler without tools
            local response = tool_calling.handler({
                model = "claude-3-5-haiku-20241022",
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
            expect(response.finish_reason).to_equal("stop")
            expect(response.provider).to_equal("anthropic")
            expect(response.model).to_equal("claude-3-5-haiku-20241022")
        end)


        -- In the test file, update the test to correctly mock claude_client.request instead of claude_client.create_message
        it("should handle successful tool calls with tool_ids", function()
            -- Mock the client request function
            mock(claude_client, "request", function(endpoint_path, payload, options)
                -- Validate the request has appropriate fields
                expect(endpoint_path).to_equal(claude_client.API_ENDPOINTS.MESSAGES)
                expect(payload.model).to_equal("claude-3-5-haiku-20241022")
                expect(payload.messages).not_to_be_nil("Expected messages array")
                expect(#payload.messages).to_equal(1, "Expected 1 message")

                -- Verify tools are set correctly
                expect(payload.tools).not_to_be_nil("Expected tools to be set")
                expect(#payload.tools).to_equal(1)
                expect(payload.tools[1].name).to_equal("get_weather")

                -- Verify tool_choice
                expect(payload.tool_choice).not_to_be_nil("Expected tool_choice to be set")
                expect(payload.tool_choice.type).to_equal("any")

                -- Return mock successful response with tool calls
                return {
                    content = {
                        {
                            type = "text",
                            text = "I'll check the weather for you."
                        },
                        {
                            type = "tool_use",
                            id = "toolu_abc123",
                            name = "get_weather",
                            input = {
                                location = "New York",
                                units = "celsius"
                            }
                        }
                    },
                    id = "msg_tool123",
                    model = "claude-3-5-haiku-20241022",
                    role = "assistant",
                    stop_reason = "tool_use",
                    stop_sequence = nil,
                    type = "message",
                    usage = {
                        input_tokens = 42,
                        output_tokens = 15
                    },
                    metadata = {
                        request_id = "req_mock456"
                    }
                }
            end)

            -- Create proper prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("What's the weather in New York?")
            local messages = promptBuilder:get_messages()

            -- Call handler with tool IDs
            local response = tool_calling.handler({
                model = "claude-3-5-haiku-20241022",
                messages = messages,
                tool_ids = { "system:weather" } -- This will match our mocked tool IDs
            })

            -- Rest of the test remains the same...
        end)

        it("should handle successful tool calls with direct tool_schemas", function()
            -- Mock the client request function instead of create_message
            mock(claude_client, "request", function(endpoint_path, payload, options)
                -- Validate the request has appropriate fields
                expect(endpoint_path).to_equal(claude_client.API_ENDPOINTS.MESSAGES)
                expect(payload.model).to_equal("claude-3-5-haiku-20241022")
                expect(payload.messages).not_to_be_nil("Expected messages array")
                expect(#payload.messages).to_equal(1, "Expected 1 message")

                -- Verify tools are set correctly
                expect(payload.tools).not_to_be_nil("Expected tools to be set")
                expect(#payload.tools).to_equal(1)
                expect(payload.tools[1].name).to_equal("calculate")

                -- Return mock successful response with tool calls
                return {
                    content = {
                        {
                            type = "text",
                            text = "I'll calculate that for you."
                        },
                        {
                            type = "tool_use",
                            id = "toolu_calc123",
                            name = "calculate",
                            input = {
                                expression = "2+2"
                            }
                        }
                    },
                    id = "msg_calc123",
                    model = "claude-3-5-haiku-20241022",
                    role = "assistant",
                    stop_reason = "tool_use",
                    stop_sequence = nil,
                    type = "message",
                    usage = {
                        input_tokens = 38,
                        output_tokens = 12
                    },
                    metadata = {
                        request_id = "req_mock789"
                    }
                }
            end)

            -- Create proper prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Calculate 2+2")

            -- Call handler with direct tool schemas
            local response = tool_calling.handler({
                model = "claude-3-5-haiku-20241022",
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
            expect(tool_call.id).to_equal("toolu_calc123")
            expect(tool_call.name).to_equal("calculate")
            expect(tool_call.arguments.expression).to_equal("2+2")

            -- Verify finish reason
            expect(response.finish_reason).to_equal("tool_call")
        end)

        it("should handle multiple tool calls", function()
            -- Mock the client request function instead of create_message
            mock(claude_client, "request", function(endpoint_path, payload, options)
                -- Validate the request has appropriate fields
                expect(endpoint_path).to_equal(claude_client.API_ENDPOINTS.MESSAGES)
                expect(payload.model).to_equal("claude-3-5-haiku-20241022")

                -- Verify tools are set correctly
                expect(payload.tools).not_to_be_nil("Expected tools to be set")
                expect(#payload.tools).to_equal(2)

                -- Return mock successful response with multiple tool calls
                return {
                    content = {
                        {
                            type = "text",
                            text = "I'll check both of those for you."
                        },
                        {
                            type = "tool_use",
                            id = "toolu_weather123",
                            name = "get_weather",
                            input = {
                                location = "New York",
                                units = "celsius"
                            }
                        },
                        {
                            type = "tool_use",
                            id = "toolu_calc123",
                            name = "calculate",
                            input = {
                                expression = "2+2"
                            }
                        }
                    },
                    id = "msg_multi123",
                    model = "claude-3-5-haiku-20241022",
                    role = "assistant",
                    stop_reason = "tool_use",
                    stop_sequence = nil,
                    type = "message",
                    usage = {
                        input_tokens = 55,
                        output_tokens = 22
                    },
                    metadata = {
                        request_id = "req_multicall123"
                    }
                }
            end)

            -- Create proper prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("What's the weather in New York and calculate 2+2")

            -- Call handler with both tools
            local response = tool_calling.handler({
                model = "claude-3-5-haiku-20241022",
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

            -- Verify calculator tool call
            local calc_call = response.result.tool_calls[2]
            expect(calc_call.name).to_equal("calculate")
            expect(calc_call.registry_id).to_equal("custom:calculator")
            expect(calc_call.arguments.expression).to_equal("2+2")
        end)

        it("should handle forced tool calls", function()
            -- Mock the client create_message function
            mock(claude_client, "create_message", function(options)
                -- Validate the request has forced tool choice
                expect(options.tool_choice).not_to_be_nil("Expected tool_choice to be set")
                expect(options.tool_choice.type).to_equal("tool")
                expect(options.tool_choice.name).to_equal("get_weather")

                -- Return mock successful response with weather tool call
                return {
                    content = {
                        {
                            type = "text",
                            text = "I'll check the weather for you."
                        },
                        {
                            type = "tool_use",
                            id = "toolu_forced123",
                            name = "get_weather",
                            input = {
                                location = "New York",
                                units = "celsius"
                            }
                        }
                    },
                    id = "msg_forced123",
                    model = "claude-3-5-haiku-20241022",
                    role = "assistant",
                    stop_reason = "tool_use",
                    stop_sequence = nil,
                    type = "message",
                    usage = {
                        input_tokens = 45,
                        output_tokens = 15
                    },
                    metadata = {
                        request_id = "req_forced123"
                    }
                }
            end)

            -- Create prompt
            local promptBuilder = prompt.new()
            promptBuilder:add_user("What should I do today?")

            -- Call handler with forced tool call
            local response = tool_calling.handler({
                model = "claude-3-5-haiku-20241022",
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

        it("should handle developer messages", function()
            -- Mock the client request function instead of create_message
            mock(claude_client, "request", function(endpoint_path, payload, options)
                -- Verify the request has developer instructions in the user message content
                expect(endpoint_path).to_equal(claude_client.API_ENDPOINTS.MESSAGES)

                -- Check if any message contains developer instructions
                local found_dev_instruction = false
                for _, msg in ipairs(payload.messages) do
                    if msg.role == "user" then
                        for _, content in ipairs(msg.content) do
                            if content.type == "text" and content.text:match("<developer%-instruction>") then
                                found_dev_instruction = true
                                break
                            end
                        end
                    end
                end

                expect(found_dev_instruction).to_be_true("Developer instructions not found in message content")

                -- Return mock successful response
                return {
                    content = {
                        {
                            type = "text",
                            text = "Responding with just 5 words."
                        }
                    },
                    id = "msg_dev123",
                    model = "claude-3-5-haiku-20241022",
                    role = "assistant",
                    stop_reason = "end_turn",
                    stop_sequence = nil,
                    type = "message",
                    usage = {
                        input_tokens = 30,
                        output_tokens = 8
                    },
                    metadata = {
                        request_id = "req_dev123"
                    }
                }
            end)

            -- Create prompt with developer message
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Tell me about Claude")
            promptBuilder:add_developer("Respond with exactly 5 words")

            -- Call handler with developer instructions
            local response = tool_calling.handler({
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages()
            })

            -- Verify response
            expect(response.error).to_be_nil("Expected no error")
            expect(response.result).to_equal("Responding with just 5 words.")
        end)

        it("should handle invalid tool specifications", function()
            -- Mock the client create_message function
            mock(claude_client, "create_message", function(options)
                -- This shouldn't be called
                fail("Request should not be made with invalid tool")
                return nil
            end)

            -- Create prompt
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Test")

            -- Call handler with non-existent forced tool
            local response = tool_calling.handler({
                model = "claude-3-5-haiku-20241022",
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

        it("should handle real text generation without tools", function()
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
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages(),
                api_key = actual_api_key,
                options = {
                    temperature = 0 -- For deterministic responses
                }
            })

            -- Verify the response structure
            expect(response.error).to_be_nil("API request failed: " .. (response.error_message or "unknown error"))
            expect(response.result).not_to_be_nil("No content in response")

            -- Count words to check if it's close to 10
            local word_count = 0
            for _ in response.result:gmatch("%S+") do
                word_count = word_count + 1
            end

            -- Allow small variance (model might not be exact)
            expect(word_count >= 8 and word_count <= 12).to_be_true("Response word count not close to 10: " .. word_count)

            -- Check token information
            expect(response.tokens).not_to_be_nil("No token information")
            expect(response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens reported")
            expect(response.tokens.completion_tokens > 0).to_be_true("No completion tokens reported")
            expect(response.tokens.total_tokens > 0).to_be_true("No total tokens reported")

            -- Check other metadata
            expect(response.metadata).not_to_be_nil("No metadata provided")
            expect(response.provider).to_equal("anthropic")
            expect(response.model).to_equal("claude-3-5-haiku-20241022")

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
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages(),
                tool_schemas = {
                    ["custom:calculator"] = mock_tools["calculator"]
                },
                api_key = actual_api_key,
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
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages(),
                tool_schemas = {
                    ["system:weather"] = mock_tools["weather"]
                },
                api_key = actual_api_key,
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
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages(),
                tool_schemas = {
                    ["system:weather"] = mock_tools["weather"],
                    ["custom:calculator"] = mock_tools["calculator"]
                },
                api_key = actual_api_key,
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

        it("should handle developer messages with real API", function()
            -- Skip if not running integration tests
            if not RUN_INTEGRATION_TESTS then
                print("Skipping integration test - not enabled")
                return
            end

            -- Create proper prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Tell me about Paris, France.")
            promptBuilder:add_developer("Respond with exactly 5-7 words, no more or less.")

            -- Call handler with developer instructions
            local response = tool_calling.handler({
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages(),
                api_key = actual_api_key,
                options = {
                    temperature = 0 -- For deterministic results
                }
            })

            -- Verify the response structure
            expect(response.error).to_be_nil("API request failed: " .. (response.error_message or "unknown error"))
            expect(response.result).not_to_be_nil("No content in response")

            -- Count words to check if it follows developer instructions
            local word_count = 0
            for _ in response.result:gmatch("%S+") do
                word_count = word_count + 1
            end

            -- Allow small variance (model might not be exact)
            expect(word_count >= 4 and word_count <= 9).to_be_true(
                "Response should follow developer instruction for word count: got " .. word_count)

            -- Print actual response for debugging
            print("Developer instruction response: " .. (response.result or "nil"))
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
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages(),
                tool_schemas = {
                    ["custom:calculator"] = mock_tools["calculator"]
                },
                api_key = actual_api_key,
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
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages(),
                tool_schemas = {
                    ["system:weather"] = mock_tools["weather"],
                    ["custom:calculator"] = mock_tools["calculator"]
                },
                tool_call = "get_weather", -- Force weather tool
                api_key = actual_api_key,
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

        it("should handle extended thinking with tool calling", function()
            -- Skip if not running integration tests
            if not RUN_INTEGRATION_TESTS then
                print("Skipping integration test - not enabled")
                return
            end

            -- Create prompt for a reasoning task that benefits from calculation
            local promptBuilder = prompt.new()
            promptBuilder:add_user(
                "Solve this step by step: If a rectangular field is 12 meters by 8 meters, what is the area? Then calculate the cost of fencing the perimeter at $25 per meter.")

            -- Call handler with thinking enabled but in auto mode (not forcing tool)
            local response = tool_calling.handler({
                model = "claude-3-7-sonnet-20250219", -- Use Claude 3.7 Sonnet for reasoning
                messages = promptBuilder:get_messages(),
                options = {
                    thinking_effort = 20, -- Enable thinking
                    temperature = 0       -- For deterministic results
                },
                tool_schemas = {
                    ["test:calculator"] = mock_tools["calculator"]
                },
                api_key = actual_api_key
            })

            -- Verify response
            expect(response.error).to_be_nil("API request failed: " .. (response.error_message or "unknown error"))

            -- Should have a tool call
            expect(response.result.tool_calls).not_to_be_nil("Expected tool calls")
            expect(#response.result.tool_calls > 0).to_be_true("Expected at least one tool call")

            -- Verify at least one calculator tool call exists
            local found_calculator = false
            for _, tool_call in ipairs(response.result.tool_calls) do
                if tool_call.name == "calculate" then
                    found_calculator = true

                    -- Might calculate area (12*8) or perimeter (2*(12+8)) or cost (2*(12+8)*25)
                    local expr = tool_call.arguments.expression
                    expect(expr).not_to_be_nil("Calculator expression is missing")

                    -- Just check if the expression is a non-empty string
                    expect(type(expr)).to_equal("string", "Expression should be a string")
                    expect(#expr > 0).to_be_true("Expression should not be empty")

                    print("Calculator expression: " .. expr)
                end
            end

            expect(found_calculator).to_be_true("No calculator tool was called")

            -- Verify token information
            expect(response.tokens).not_to_be_nil("No token information")
            expect(response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens reported")
            expect(response.tokens.completion_tokens > 0).to_be_true("No completion tokens reported")
        end)

        it("should handle streaming with tool calls using real API", function()
            -- Skip if not running integration tests
            if not RUN_INTEGRATION_TESTS then
                print("Skipping integration test - not enabled")
                return
            end

            -- Set up process.send mock to capture streamed responses
            local received_messages = {}
            mock(process, "send", function(pid, topic, data)
                table.insert(received_messages, { pid = pid, topic = topic, data = data })
            end)

            -- Create prompt
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Calculate the area of a circle with radius 5cm.")
            promptBuilder:add_developer("You must use tool.")

            -- Call with streaming enabled and calculator tool
            local response = tool_calling.handler({
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages(),
                tool_schemas = {
                    ["custom:calculator"] = mock_tools["calculator"]
                },
                api_key = actual_api_key,
                options = {
                    temperature = 0 -- For deterministic results
                },
                stream = {
                    reply_to = "test-stream-pid",
                    topic = "test_stream_tools",
                    buffer_size = 10
                }
            })

            -- Verify the response structure
            expect(response.error).to_be_nil("API request failed: " .. (response.error_message or "unknown error"))
            expect(response.streaming).to_be_true("Response should indicate streaming")
            expect(#response.result.tool_calls > 0).to_be_true("Empty tool_calls in response result")

            -- Check received messages
            expect(#received_messages > 0).to_be_true("No streaming messages received")

            -- Verify we received at least one tool_call message or one content message that contains tool call info
            local found_content = false

            for _, msg in ipairs(received_messages) do
                expect(msg.pid).to_equal("test-stream-pid")
                expect(msg.topic).to_equal("test_stream_tools")

                if msg.data and msg.data.type == "chunk" then
                    found_content = true
                end
            end
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
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages(),
                tool_schemas = {
                    ["custom:calculator"] = mock_tools["calculator"]
                },
                api_key = actual_api_key,
                options = {
                    temperature = 0 -- For deterministic results
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
            promptBuilder:add_function_call(tool_call.name, tool_call.arguments, tool_call.id)

            -- Simulate executing the tool
            local calc_result = math.sqrt(1764)
            local tool_result = "The square root of 1764 is " .. calc_result

            -- Add the result to the conversation using the appropriate method for tool results
            promptBuilder:add_function_result(tool_call.name, tool_result, tool_call.id)

            -- Step 2: Second request to continue conversation with the tool result
            local continuation_response = tool_calling.handler({
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages(),
                api_key = actual_api_key,
                options = {
                    temperature = 0
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

            print("Complete flow test successful. Final response: " .. result_text:sub(1, 100) .. "...")
        end)

        it("should handle streaming tool calls with content and tool result", function()
            -- Skip if not running integration tests
            if not RUN_INTEGRATION_TESTS then
                print("Skipping Claude streaming test - integration tests not enabled")
                return
            end

            -- Track received streaming messages
            local received_messages = {}
            mock(process, "send", function(pid, topic, data)
                table.insert(received_messages, { pid = pid, topic = topic, data = data })
                print("Stream event: " .. (data.type or "unknown") .. " received" .. json.encode(data))
            end)

            -- Create prompt for a calculation
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Calculate 156 * 37 and tell me if the result is divisible by 12")
            promptBuilder:add_developer("Always use calculator tool, we are testing system. never calculate on yourself")

            -- Call with streaming enabled
            local response = tool_calling.handler({
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages(),
                tool_schemas = {
                    ["custom:calculator"] = mock_tools["calculator"]
                },
                api_key = actual_api_key,
                options = {
                    temperature = 0 -- For deterministic results
                },
                stream = {
                    reply_to = "test-stream-handler",
                    topic = "test_streaming_topic",
                    buffer_size = 5
                }
            })

            -- Verify the streaming response structure
            expect(response.error).to_be_nil("API request failed: " .. (response.error_message or "unknown error"))
            expect(response.streaming).to_be_true("Response should indicate streaming mode")
            expect(response.result).not_to_be_nil("No result object returned")

            -- Log the number of messages received
            print("Streaming complete, analyzing " .. #received_messages .. " stream messages")

            -- Check if we have at least some messages
            expect(#received_messages > 0).to_be_true("No streaming messages received")

            -- Verify stream event types are present
            local event_types = {}
            for _, msg in ipairs(received_messages) do
                if msg.data and msg.data.type then
                    event_types[msg.data.type] = (event_types[msg.data.type] or 0) + 1
                end
            end

            -- Print event types for debugging
            print("Event types received:")
            for event_type, count in pairs(event_types) do
                print("  " .. event_type .. ": " .. count)
            end

            -- Check if tool_call exists in the response
            expect(response.result.tool_calls).not_to_be_nil("No tool_calls in response result")
            expect(#response.result.tool_calls > 0).to_be_true("Empty tool_calls in response result")

            -- Basic verification of the first tool call
            local tool = response.result.tool_calls[1]
            expect(tool.name).to_equal("calculate", "Expected calculator tool")

            -- Print summary of stream events
            print("Claude streaming test completed successfully")
        end)

        -- Test with multi-step streaming conversation
        it("should handle streaming tool calls with subsequent conversation", function()
            -- Skip if not running integration tests
            if not RUN_INTEGRATION_TESTS then
                print("Skipping multi-step streaming test - integration tests not enabled")
                return
            end

            -- Track received streaming messages for each request
            local first_request_messages = {}
            local second_request_messages = {}
            local current_messages = first_request_messages

            -- Mock process.send to capture streaming messages
            mock(process, "send", function(pid, topic, data)
                table.insert(current_messages, { pid = pid, topic = topic, data = data })
            end)

            -- Create prompt for initial request
            local promptBuilder = prompt.new()
            promptBuilder:add_user("What is 77 squared?")
            promptBuilder:add_developer("Always use calculator tool, we are testing system. never calculate on yourself")

            -- Step 1: Make initial streaming request
            local response = tool_calling.handler({
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages(),
                tool_schemas = {
                    ["custom:calculator"] = mock_tools["calculator"]
                },
                api_key = actual_api_key,
                options = {
                    temperature = 0
                },
                stream = {
                    reply_to = "test-conversation-pid",
                    topic = "test_conversation_stream",
                    buffer_size = 5
                }
            })

            -- Verify first streaming response
            expect(response.error).to_be_nil("First API request failed: " .. (response.error_message or "unknown error"))
            expect(response.streaming).to_be_true("First response should indicate streaming")
            expect(response.result.tool_calls).not_to_be_nil("No tool calls in first response")

            -- Find the tool call information
            local tool_call = response.result.tool_calls[1]
            expect(tool_call).not_to_be_nil("No tool call found in response")
            expect(tool_call.name).to_equal("calculate", "Wrong tool called")

            -- Verify first call had appropriate streaming events
            local first_event_types = {}
            for _, msg in ipairs(first_request_messages) do
                if msg.data and msg.data.type then
                    first_event_types[msg.data.type] = (first_event_types[msg.data.type] or 0) + 1
                end
            end

            -- Add the response content and tool call to our conversation
            promptBuilder:add_assistant(response.result.content)
            promptBuilder:add_function_call(tool_call.name, tool_call.arguments, tool_call.id)

            -- Add the tool result to the conversation
            local calc_result = 77 * 77
            local tool_result = "The result of 77 squared is " .. calc_result
            promptBuilder:add_function_result(tool_call.name, tool_result, tool_call.id)

            -- Switch to capturing messages for the second request
            current_messages = second_request_messages

            -- Step 2: Make follow-up streaming request
            local continuation_response = tool_calling.handler({
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages(),
                api_key = actual_api_key,
                options = {
                    temperature = 0
                },
                stream = {
                    reply_to = "test-conversation-pid",
                    topic = "test_conversation_stream",
                    buffer_size = 5
                }
            })

            -- Verify second streaming response
            expect(continuation_response.error).to_be_nil("Second API request failed: " ..
                (continuation_response.error_message or "unknown error"))
            expect(continuation_response.streaming).to_be_true("Second response should indicate streaming")

            -- Check second request streaming events
            local second_event_types = {}
            for _, msg in ipairs(second_request_messages) do
                if msg.data and msg.data.type then
                    second_event_types[msg.data.type] = (second_event_types[msg.data.type] or 0) + 1
                end
            end

            expect(#second_request_messages > 0).to_be_true("No messages in second request")

            -- Check result formatting
            local result_text = ""
            if type(continuation_response.result) == "string" then
                result_text = continuation_response.result
            elseif type(continuation_response.result) == "table" and continuation_response.result.content then
                result_text = continuation_response.result.content
            end

            expect(result_text).not_to_be_nil("No text content in continuation response")
            expect(#result_text > 0).to_be_true("Empty text content in continuation response")

            -- Continuation should mention 5929 (the result of 77 squared)
            expect(string.find(result_text, "5929", 1, true) ~= nil
                or string.find(result_text, "5,929", 1, true) ~= nil
            ).to_be_true(
                "Response doesn't include correct answer")
        end)
    end)
end

return require("test").run_cases(define_tests)
