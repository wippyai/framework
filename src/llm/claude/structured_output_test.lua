local structured_output = require("structured_output")
local claude_client = require("claude_client")
local output = require("output")
local json = require("json")
local env = require("env")
local prompt = require("prompt")

local function define_tests()
    -- Toggle to enable/disable real API integration test
    local RUN_INTEGRATION_TESTS = env.get("ENABLE_INTEGRATION_TESTS")

    describe("Claude Structured Output Handler", function()
        local actual_api_key = nil

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
        end)

        it("should validate required parameters", function()
            -- Test missing model
            local response = structured_output.handler({
                schema = {
                    type = "object",
                    properties = {},
                    additionalProperties = false,
                    required = {}
                }
            })

            expect(response.error).to_equal(output.ERROR_TYPE.INVALID_REQUEST)
            expect(response.error_message).to_contain("Model is required")

            -- Test missing messages
            local response2 = structured_output.handler({
                model = "claude-3-5-sonnet-20240229",
                schema = {
                    type = "object",
                    properties = {},
                    additionalProperties = false,
                    required = {}
                }
            })

            expect(response2.error).to_equal(output.ERROR_TYPE.INVALID_REQUEST)
            expect(response2.error_message).to_contain("No messages provided")

            -- Test missing schema
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Test")

            local response3 = structured_output.handler({
                model = "claude-3-5-sonnet-20240229",
                messages = promptBuilder:get_messages()
            })

            expect(response3.error).to_equal(output.ERROR_TYPE.INVALID_REQUEST)
            expect(response3.error_message).to_contain("Schema is required")
        end)

        it("should validate schema requirements", function()
            -- Create proper prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Test")

            -- Schema without object type
            local response = structured_output.handler({
                model = "claude-3-5-sonnet-20240229",
                messages = promptBuilder:get_messages(),
                schema = {
                    type = "array",
                    items = {}
                }
            })

            expect(response.error).to_equal(output.ERROR_TYPE.INVALID_REQUEST)
            expect(response.error_message).to_contain("Root schema must be an object type")

            -- Schema without additionalProperties: false
            local response2 = structured_output.handler({
                model = "claude-3-5-sonnet-20240229",
                messages = promptBuilder:get_messages(),
                schema = {
                    type = "object",
                    properties = {
                        name = { type = "string" }
                    },
                    required = { "name" }
                }
            })

            expect(response2.error).to_equal(output.ERROR_TYPE.INVALID_REQUEST)
            expect(response2.error_message).to_contain("additionalProperties: false")

            -- Schema with missing required properties
            local response3 = structured_output.handler({
                model = "claude-3-5-sonnet-20240229",
                messages = promptBuilder:get_messages(),
                schema = {
                    type = "object",
                    properties = {
                        name = { type = "string" },
                        age = { type = "number" }
                    },
                    required = { "name" },
                    additionalProperties = false
                }
            })

            expect(response3.error).to_equal(output.ERROR_TYPE.INVALID_REQUEST)
            expect(response3.error_message).to_contain("properties must be marked as required")
        end)

        it("should successfully generate structured output with mocked client", function()
            -- Create proper prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Get me basic information about John")

            -- Test schema
            local test_schema = {
                type = "object",
                properties = {
                    name = { type = "string" },
                    age = { type = "number" },
                    city = { type = "string" }
                },
                required = { "name", "age", "city" },
                additionalProperties = false
            }

            -- Mock validation function to bypass validation
            mock(structured_output, "validate_schema", function(schema)
                return true, {}
            end)

            -- Mock the client create_message function
            mock(claude_client, "create_message", function(options)
                -- Verify tools are properly configured
                expect(options.tool_choice).not_to_be_nil("Tool choice should be configured")
                expect(options.tool_choice.type).to_equal("tool")
                expect(options.tool_choice.name).to_equal("structured_output")

                local tool = options.tools[1]
                expect(tool.name).to_equal("structured_output")
                expect(tool.input_schema).not_to_be_nil("Tool should have input_schema field")

                -- Return mock successful response with a tool_use in content
                return {
                    content = {
                        {
                            type = "tool_use",
                            name = "structured_output",
                            input = {
                                name = "John",
                                age = 30,
                                city = "New York"
                            },
                            id = "call_123456"
                        }
                    },
                    stop_reason = "tool_use",
                    usage = {
                        input_tokens = 20,
                        output_tokens = 15
                    },
                    metadata = {
                        request_id = "req_mockstructured123",
                        processing_ms = 180
                    }
                }
            end)

            -- Call with valid schema
            local response = structured_output.handler({
                model = "claude-3-5-sonnet-20240229",
                messages = promptBuilder:get_messages(),
                schema = test_schema
            })

            -- Verify the response structure
            expect(response.error).to_be_nil("Expected no error")
            expect(response.result).not_to_be_nil("Expected result object")

            -- Test specific properties if response was successful
            if response.result then
                expect(response.result.name).to_equal("John")
                expect(response.result.age).to_equal(30)
                expect(response.result.city).to_equal("New York")
            end

            -- Verify token usage
            expect(response.tokens).not_to_be_nil("Expected token information")
            if response.tokens then
                expect(response.tokens.prompt_tokens).to_equal(20)
                expect(response.tokens.completion_tokens).to_equal(15)
                expect(response.tokens.total_tokens).to_equal(35)
            end

            -- Verify metadata
            expect(response.metadata).not_to_be_nil("Expected metadata")
            expect(response.metadata.request_id).to_equal("req_mockstructured123")
            expect(response.finish_reason).to_equal("tool_call")
            expect(response.provider).to_equal("anthropic")
            expect(response.model).to_equal("claude-3-5-sonnet-20240229")
        end)

        it("should return error when no tool call is present", function()
            -- Create proper prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Get me basic information about Sarah")

            -- Test schema
            local test_schema = {
                type = "object",
                properties = {
                    name = { type = "string" },
                    age = { type = "number" },
                    city = { type = "string" }
                },
                required = { "name", "age", "city" },
                additionalProperties = false
            }

            -- Mock validation function
            mock(structured_output, "validate_schema", function(schema)
                return true, {}
            end)

            -- Mock the client create_message function to return content without tool call
            mock(claude_client, "create_message", function(options)
                -- Return a mock response with content containing text but no tool_use
                return {
                    content = {
                        {
                            type = "text",
                            text =
                            'Here is the information about Sarah in JSON format: {"name":"Sarah","age":35,"city":"Boston"}'
                        }
                    },
                    stop_reason = "end_turn",
                    usage = {
                        input_tokens = 25,
                        output_tokens = 20
                    },
                    metadata = {
                        request_id = "req_mockfallback123",
                        processing_ms = 160
                    }
                }
            end)

            -- Call with valid schema
            local response = structured_output.handler({
                model = "claude-3-5-sonnet-20240229",
                messages = promptBuilder:get_messages(),
                schema = test_schema
            })

            -- Verify error is returned when no tool call is present
            expect(response.error).to_equal(output.ERROR_TYPE.SERVER_ERROR)
            expect(response.error_message).to_contain("failed to use the structured_output tool")
        end)

        it("should handle tool call errors properly", function()
            -- Create prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Get me basic information about a person")

            -- Test schema
            local test_schema = {
                type = "object",
                properties = {
                    name = { type = "string" },
                    age = { type = "number" },
                    city = { type = "string" }
                },
                required = { "name", "age", "city" },
                additionalProperties = false
            }

            -- Mock validation function
            mock(structured_output, "validate_schema", function(schema)
                return true, {}
            end)

            -- Mock the client create_message function to return an invalid tool call
            mock(claude_client, "create_message", function(options)
                -- Verify tool_choice format
                expect(options.tool_choice.type).to_equal("tool")
                expect(options.tool_choice.name).to_equal("structured_output")

                -- Return a mock response with an empty tool_use input
                return {
                    content = {
                        {
                            type = "tool_use",
                            name = "structured_output",
                            input = nil, -- No input provided
                            id = "call_invalid"
                        }
                    },
                    stop_reason = "tool_use",
                    usage = {
                        input_tokens = 18,
                        output_tokens = 10
                    },
                    metadata = {
                        request_id = "req_mockerror123",
                        processing_ms = 150
                    }
                }
            end)

            -- Call with valid schema but expect error due to nil input
            local response = structured_output.handler({
                model = "claude-3-5-sonnet-20240229",
                messages = promptBuilder:get_messages(),
                schema = test_schema
            })

            -- Verify error has the right format
            expect(response.error).to_equal(output.ERROR_TYPE.SERVER_ERROR)
            expect(response.error_message).to_contain("does not contain input")
        end)

        it("should handle real Claude API calls with structured output", function()
            -- Skip if integration tests are disabled
            if not RUN_INTEGRATION_TESTS then
                return
            end

            -- Create prompt
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Provide me with information about a fictional company called TechNova Inc.")

            -- Create schema
            local company_schema = {
                type = "object",
                properties = {
                    name = { type = "string" },
                    industry = { type = "string" },
                    founded_year = { type = "number" },
                    headquarters = { type = "string" },
                    employees = { type = "number" },
                    products = {
                        type = "array",
                        items = { type = "string" }
                    },
                    description = { type = "string" }
                },
                required = { "name", "industry", "founded_year", "headquarters", "employees", "products", "description" },
                additionalProperties = false
            }

            -- Make the real API call
            local response = structured_output.handler({
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages(),
                schema = company_schema,
                api_key = actual_api_key,
                options = {
                    temperature = 0 -- For deterministic results
                }
            })

            expect(response.error).to_be_nil("API request failed: " .. (response.error_message or "unknown error"))

            -- Rest of checks only if response succeeded
            if response.error then return end

            -- Verify schema compliance
            expect(response.result).not_to_be_nil("No result received from Claude API")
            if response.result then
                expect(response.result.name).to_contain("TechNova")
                expect(response.result.industry).not_to_be_nil()
                expect(response.result.founded_year).not_to_be_nil()
                expect(type(response.result.products)).to_equal("table")
            end

            -- Verify token information
            expect(response.tokens).not_to_be_nil("Expected token information")
            expect(response.tokens.prompt_tokens > 0).to_be_true("Expected non-zero prompt tokens")
            expect(response.tokens.completion_tokens > 0).to_be_true("Expected non-zero completion tokens")

            -- Print result for manual verification
            print("Structured output test response:")
            print(json.encode(response.result))
        end)

        it("should handle complex nested schemas correctly", function()
            -- Skip if integration tests are disabled
            if not RUN_INTEGRATION_TESTS then
                return
            end

            -- Create prompt
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Extract key points from this travel review: 'I visited Paris last summer. " ..
                "The Eiffel Tower was magnificent but crowded. The food was excellent, " ..
                "especially the pastries. Hotel prices were high, but public transportation was affordable. " ..
                "Weather was perfect with sunny days. Would definitely recommend!'")

            -- Complex nested schema
            local review_schema = {
                type = "object",
                properties = {
                    destination = { type = "string" },
                    visit_time = { type = "string" },
                    highlights = {
                        type = "array",
                        items = { type = "string" }
                    },
                    ratings = {
                        type = "object",
                        properties = {
                            accommodation = { type = "number", minimum = 1, maximum = 5 },
                            food = { type = "number", minimum = 1, maximum = 5 },
                            attractions = { type = "number", minimum = 1, maximum = 5 },
                            value = { type = "number", minimum = 1, maximum = 5 },
                            overall = { type = "number", minimum = 1, maximum = 5 }
                        },
                        required = { "accommodation", "food", "attractions", "value", "overall" },
                        additionalProperties = false
                    },
                    pros = {
                        type = "array",
                        items = { type = "string" }
                    },
                    cons = {
                        type = "array",
                        items = { type = "string" }
                    },
                    overall_sentiment = {
                        type = "string",
                        enum = { "positive", "neutral", "negative", "mixed" }
                    }
                },
                required = { "destination", "visit_time", "highlights", "ratings", "pros", "cons", "overall_sentiment" },
                additionalProperties = false
            }

            -- Make the real API call
            local response = structured_output.handler({
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages(),
                schema = review_schema,
                api_key = actual_api_key,
                options = {
                    temperature = 0,     -- For deterministic results
                    thinking_effort = 20 -- Add some thinking effort
                }
            })

            expect(response.error).to_be_nil("API request failed: " .. (response.error_message or "unknown error"))

            -- Rest of checks only if response succeeded
            if response.error then return end

            -- Verify schema compliance
            expect(response.result).not_to_be_nil("No result received from Claude API")
            if response.result then
                expect(response.result.destination).to_equal("Paris")
                expect(type(response.result.highlights)).to_equal("table")
                expect(response.result.overall_sentiment).to_equal("positive")

                -- Check nested object structure
                expect(type(response.result.ratings)).to_equal("table")
                expect(response.result.ratings.food >= 1 and response.result.ratings.food <= 5).to_be_true(
                    "Food rating should be between 1-5")
            end

            -- Print result for manual verification
            print("Complex schema test response:")
            print(json.encode(response.result))
        end)

        it("should handle authentication errors correctly", function()
            -- Create prompt
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Test message")

            -- Test schema
            local test_schema = {
                type = "object",
                properties = {
                    message = { type = "string" }
                },
                required = { "message" },
                additionalProperties = false
            }

            -- Mock validation
            mock(structured_output, "validate_schema", function(schema)
                return true, {}
            end)

            -- Mock the client.create_message to return an auth error
            mock(claude_client, "create_message", function(options)
                return nil, {
                    status_code = 401,
                    message = "Invalid API key"
                }
            end)

            -- Mock the map_error function
            mock(claude_client, "map_error", function(err)
                expect(err.status_code).to_equal(401)
                return {
                    error = output.ERROR_TYPE.AUTHENTICATION,
                    error_message = "Invalid API key"
                }
            end)

            -- Call with invalid API key
            local response = structured_output.handler({
                model = "claude-3-5-sonnet-20240229",
                messages = promptBuilder:get_messages(),
                schema = test_schema,
                api_key = "invalid-key"
            })

            -- Verify the error type
            expect(response.error).to_equal(output.ERROR_TYPE.AUTHENTICATION)
            expect(response.error_message).to_contain("Invalid API key")
        end)
    end)
end

return require("test").run_cases(define_tests)
