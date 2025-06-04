local structured_output = require("structured_output")
local vertex = require("vertex_client")
local output = require("output")
local json = require("json")
local env = require("env")
local prompt = require("prompt")
local prompt_mapper = require("prompt_mapper")

local function define_tests()
    -- Toggle to enable/disable real API integration test
    local RUN_INTEGRATION_TESTS = env.get("ENABLE_INTEGRATION_TESTS")

    describe("Vertex AI Structured Output Handler", function()
        local actual_project_id = nil
        local actual_location = nil

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
                model = "gemini-1.5-pro",
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
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages()
            })

            expect(response3.error).to_equal(output.ERROR_TYPE.INVALID_REQUEST)
            expect(response3.error_message).to_contain("Schema is required")
        end)

        it("should validate schema requirements", function()
            -- Create proper prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Test")

            -- Track which validation errors were caught
            local schema_validation_errors = {}

            -- Schema without object type
            local response = structured_output.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages(),
                schema = {
                    type = "array",
                    items = {}
                }
            })

            expect(response.error).to_equal(output.ERROR_TYPE.INVALID_REQUEST)
            if response.error_message:match("Root schema must be an object type") then
                schema_validation_errors["object_type"] = true
            end

            -- Schema without additionalProperties: false
            local response2 = structured_output.handler({
                model = "gemini-1.5-pro",
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
            if response2.error_message:match("additionalProperties: false") then
                schema_validation_errors["additional_properties"] = true
            end

            -- Schema with missing required properties
            local response3 = structured_output.handler({
                model = "gemini-1.5-pro",
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
            if response3.error_message:match("properties must be marked as required") then
                schema_validation_errors["required_props"] = true
            end
        end)

        it("should successfully generate structured output with mocked client", function()
            -- Create proper prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Get me basic information about John")

            -- Debug the current schema validation function to understand its behavior
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

            -- Mock schema validation function
            mock(structured_output, "validate_schema", function(schema)
                return true, {}
            end)

            -- Mock the prompt mapper function
            mock(prompt_mapper, "map_to_vertex", function(messages)
                -- Just return the messages in this mock since we're not testing that part
                return messages
            end)

            -- Mock the client request function
            mock(vertex, "request", function(endpoint_path, model, payload, options)
                -- Return mock successful response
                return {
                    candidates = {
                        {
                            content = {
                                parts = {
                                    { text = '{"name":"John","age":30,"city":"New York"}' }
                                }
                            },
                            finishReason = "STOP"
                        }
                    },
                    usageMetadata = {
                        promptTokenCount = 20,
                        candidatesTokenCount = 15,
                        totalTokenCount = 35
                    },
                    metadata = {
                        request_id = "req_mockvertexstructured123"
                    }
                }
            end)

            -- Call with valid schema
            local response = structured_output.handler({
                model = "gemini-1.5-pro",
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
            expect(response.finish_reason).to_equal("stop") -- Should be mapped to lowercase
            expect(response.provider).to_equal("vertex")
            expect(response.model).to_equal("gemini-1.5-pro")
        end)

        it("should handle empty content or parsing errors", function()
            -- Create prompt
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Get me basic information")

            -- Debug the current schema validation function to understand its behavior
            local test_schema = {
                type = "object",
                properties = {
                    info = { type = "string" }
                },
                required = { "info" },
                additionalProperties = false
            }

            -- Mock validation function
            mock(structured_output, "validate_schema", function(schema)
                return true, {}
            end)

            -- Mock the prompt mapper function
            mock(prompt_mapper, "map_to_vertex", function(messages)
                return messages
            end)

            -- First test: empty content
            mock(vertex, "request", function(endpoint_path, model, payload, options)
                return {
                    candidates = {
                        {
                            content = {
                                parts = {
                                    { text = "" }
                                }
                            },
                            finishReason = "STOP"
                        }
                    }
                }
            end)

            local response = structured_output.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages(),
                schema = test_schema
            })

            expect(response.error).to_equal(output.ERROR_TYPE.SERVER_ERROR)
            expect(response.error_message).to_contain("No content in Vertex AI response")

            -- Second test: invalid JSON
            mock(vertex, "request", function(endpoint_path, model, payload, options)
                return {
                    candidates = {
                        {
                            content = {
                                parts = {
                                    { text = "{invalid json}" }
                                }
                            },
                            finishReason = "STOP"
                        }
                    }
                }
            end)

            local response2 = structured_output.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages(),
                schema = test_schema
            })

            expect(response2.error).to_be_nil()
            expect(response2.result).to_equal("{invalid json}")
        end)

        it("should handle Vertex AI API errors", function()
            -- Create prompt
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Test")

            -- Setup mocks
            mock(structured_output, "validate_schema", function(schema)
                return true, {}
            end)

            mock(prompt_mapper, "map_to_vertex", function(messages)
                return messages
            end)

            -- Mock API error
            mock(vertex, "request", function(endpoint_path, model, payload, options)
                return nil, {
                    status = 400,
                    message = "Invalid request",
                    body = { error = "Bad Request" }
                }
            end)

            -- Mock error mapping function
            mock(vertex, "map_error", function(err)
                return {
                    error = output.ERROR_TYPE.INVALID_REQUEST,
                    error_message = "Vertex AI error: " .. err.message,
                    provider_error = err.body
                }
            end)

            local response = structured_output.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages(),
                schema = {
                    type = "object",
                    properties = { test = { type = "string" } },
                    required = { "test" },
                    additionalProperties = false
                }
            })

            expect(response.error).to_equal(output.ERROR_TYPE.INVALID_REQUEST)
            expect(response.error_message).to_contain("Vertex AI error: Invalid request")
        end)

        it("should handle real Vertex AI API calls with structured output", function()
            -- Skip if integration tests are disabled
            if not RUN_INTEGRATION_TESTS then
                return
            end

            -- Create prompt
            local promptBuilder = prompt.new()
            promptBuilder:add_system("You are a helpful assistant that outputs structured JSON data.")
            promptBuilder:add_user("Provide me with information about a fictional company called TechNova Inc.")

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

            -- Track original request function to see the full error
            local original_request = vertex.request
            mock(vertex, "request", function(endpoint_path, model, payload, options)
                local response, err = original_request(endpoint_path, model, payload, options)

                if err then
                    return response, err
                else
                    return response
                end
            end)

            -- Make actual API call
            local response = structured_output.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages(),
                schema = company_schema,
                project = actual_project_id,
                location = actual_location,
                options = {
                    temperature = 0 -- For deterministic results
                }
            })

            expect(response.error).to_be_nil("API request failed: " .. (response.error_message or "unknown error"))

            -- Rest of checks only if response succeeded
            if response.error then return end

            -- Verify schema compliance
            expect(response.result).not_to_be_nil("No result received from Vertex AI API")
            if response.result then
                expect(response.result.name).to_contain("TechNova")
                expect(response.result.industry).not_to_be_nil()
                expect(response.result.founded_year).not_to_be_nil()
                expect(type(response.result.products)).to_equal("table")
            end
        end)
    end)
end

return require("test").run_cases(define_tests)
