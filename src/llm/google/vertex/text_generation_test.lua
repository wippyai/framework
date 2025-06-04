local text_generation = require("text_generation")
local vertex = require("vertex_client")
local output = require("output")
local json = require("json")
local env = require("env")
local prompt = require("prompt")
local prompt_mapper = require("prompt_mapper")

local function define_tests()
    -- Toggle to enable/disable real API integration test
    local RUN_INTEGRATION_TESTS = env.get("ENABLE_INTEGRATION_TESTS")

    describe("Vertex AI Text Generation Handler", function()
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

        it("should successfully generate text with mocked client", function()
            -- Mock the prompt mapper function
            mock(prompt_mapper, "map_to_vertex", function(messages)
                -- Return a properly formatted Vertex AI message
                return {
                    {
                        role = "user",
                        parts = {
                            {
                                text = "Say hello world"
                            }
                        }
                    }
                }
            end)

            -- Mock the client request function
            mock(vertex, "request", function(endpoint_path, model, payload, options)
                -- Validate the request
                expect(endpoint_path).to_equal(vertex.DEFAULT_GENERATE_CONTENT_ENDPOINT)
                expect(model).to_equal("gemini-1.5-pro")
                expect(payload.contents[1].role).to_equal("user")
                expect(payload.contents[1].parts[1].text).to_equal("Say hello world")

                -- Return mock successful response
                return {
                    candidates = {
                        {
                            content = {
                                parts = {
                                    {
                                        text = "Hello, world!"
                                    }
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
                    metadata = {
                        request_id = "req_mocktest123"
                    }
                }
            end)

            -- Create proper prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Say hello world")

            -- Call with a properly built prompt
            local response = text_generation.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages()
            })

            -- Verify the response structure
            expect(response.error).to_be_nil("Expected no error")
            expect(response.result).to_equal("Hello, world!")
            expect(response.tokens).not_to_be_nil("Expected token information")
            expect(response.tokens.prompt_tokens).to_equal(10)
            expect(response.tokens.completion_tokens).to_equal(5)
            expect(response.tokens.total_tokens).to_equal(15)
            expect(response.metadata).not_to_be_nil("Expected metadata")
            expect(response.metadata.request_id).to_equal("req_mocktest123")
            expect(response.finish_reason).to_equal("stop") -- Should be mapped to lowercase
            expect(response.provider).to_equal("vertex")
            expect(response.model).to_equal("gemini-1.5-pro")
        end)

        it("should handle missing required parameters", function()
            -- Test missing model
            local response = text_generation.handler({})

            expect(response.error).to_equal(output.ERROR_TYPE.INVALID_REQUEST)
            expect(response.error_message).to_contain("Model is required")

            -- Test missing messages
            local response2 = text_generation.handler({
                model = "gemini-1.5-pro"
            })

            expect(response2.error).to_equal(output.ERROR_TYPE.INVALID_REQUEST)
            expect(response2.error_message).to_contain("No messages provided")
        end)

        it("should handle model errors correctly with mocked client", function()
            -- Mock the prompt mapper function
            mock(prompt_mapper, "map_to_vertex", function(messages)
                return messages
            end)

            -- Mock the client request function to simulate a model error
            mock(vertex, "request", function(endpoint_path, model, payload, options)
                -- Return a model-related error
                return nil, {
                    status = 404,
                    message = "The model 'nonexistent-model' does not exist or you do not have access to it.",
                    body = { error = "Model not found" }
                }
            end)

            -- Mock error mapping function
            mock(vertex, "map_error", function(err)
                return {
                    error = output.ERROR_TYPE.MODEL_ERROR,
                    error_message = "Vertex AI error: " .. err.message,
                    provider_error = err.body
                }
            end)

            -- Create proper prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("This is a test message")

            -- Call with a non-existent model
            local response = text_generation.handler({
                model = "nonexistent-model",
                messages = promptBuilder:get_messages()
            })

            -- Verify the mapped error type
            expect(response.error).to_equal(output.ERROR_TYPE.MODEL_ERROR)
            expect(response.error_message).to_contain("does not exist")
        end)

        it("should handle invalid response structures", function()
            -- Mock the prompt mapper function
            mock(prompt_mapper, "map_to_vertex", function(messages)
                return messages
            end)

            -- Mock the client request function to return empty response
            mock(vertex, "request", function(endpoint_path, model, payload, options)
                -- Return a response with missing candidates
                return {
                    metadata = {
                        request_id = "req_empty123"
                    }
                }
            end)

            -- Create proper prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Test message")

            -- Call with valid parameters but mock empty response
            local response = text_generation.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages()
            })

            -- Verify error handling
            expect(response.error).to_equal(output.ERROR_TYPE.SERVER_ERROR)
            expect(response.error_message).to_contain("Invalid response structure")
        end)

        it("should handle empty content in response", function()
            -- Mock the prompt mapper function
            mock(prompt_mapper, "map_to_vertex", function(messages)
                return messages
            end)

            -- Mock the client request function to return empty content
            mock(vertex, "request", function(endpoint_path, model, payload, options)
                -- Return a response with empty content
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
                    },
                    usageMetadata = {
                        promptTokenCount = 5,
                        candidatesTokenCount = 0,
                        totalTokenCount = 5
                    }
                }
            end)

            -- Create proper prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Test message")

            -- Call with valid parameters but mock empty content
            local response = text_generation.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages()
            })

            -- Verify error handling
            expect(response.error).to_equal(output.ERROR_TYPE.SERVER_ERROR)
            expect(response.error_message).to_contain("No content in Vertex AI response")
        end)

        it("should connect to real Vertex AI with gemini-1.5-pro model", function()
            -- Skip test if integration tests are disabled
            if not RUN_INTEGRATION_TESTS then
                print("Skipping integration test - not enabled")
                return
            end

            -- Create proper prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Reply with exactly the text 'Integration test successful'")

            -- Make a real API call with gemini-1.5-pro
            local response = text_generation.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages(),
                project = actual_project_id,
                location = actual_location,
                options = {
                    temperature = 0, -- Deterministic output
                    max_tokens = 15  -- Short response
                }
            })

            -- Verify response
            expect(response.error).to_be_nil("API request failed: " ..
                (response.error_message or "unknown error"))
            expect(response.result).not_to_be_nil("No response received from API")

            -- Should contain our expected phrase
            expect(response.result:find("Integration test successful")).not_to_be_nil(
                "Expected phrase not found in response: " .. response.result
            )

            -- Should have token usage
            expect(response.tokens).not_to_be_nil("No token usage information received")
            expect(response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens reported")
            expect(response.tokens.completion_tokens > 0).to_be_true("No completion tokens reported")
            expect(response.tokens.total_tokens > 0).to_be_true("No total tokens reported")
        end)

        it("should correctly handle multiple content parts in response", function()
            -- Mock the prompt mapper function
            mock(prompt_mapper, "map_to_vertex", function(messages)
                return messages
            end)

            -- Mock the client request function
            mock(vertex, "request", function(endpoint_path, model, payload, options)
                -- Return mock response with multiple content parts
                return {
                    candidates = {
                        {
                            content = {
                                parts = {
                                    { text = "Hello, " },
                                    { text = "world!" }
                                }
                            },
                            finishReason = "STOP"
                        }
                    },
                    usageMetadata = {
                        promptTokenCount = 10,
                        candidatesTokenCount = 5,
                        totalTokenCount = 15
                    }
                }
            end)

            -- Create proper prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Say hello world")

            -- Call with a properly built prompt
            local response = text_generation.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages()
            })

            -- Verify the concatenated response
            expect(response.error).to_be_nil("Expected no error")
            expect(response.result).to_equal("Hello, world!")
        end)

        it("should correctly handle multiple candidates in response", function()
            -- Mock the prompt mapper function
            mock(prompt_mapper, "map_to_vertex", function(messages)
                return messages
            end)

            -- Mock the client request function
            mock(vertex, "request", function(endpoint_path, model, payload, options)
                -- Return mock response with multiple candidates
                return {
                    candidates = {
                        {
                            content = {
                                parts = {
                                    { text = "First candidate response" }
                                }
                            },
                            finishReason = "STOP"
                        },
                        {
                            content = {
                                parts = {
                                    { text = "Second candidate response" }
                                }
                            },
                            finishReason = "STOP"
                        }
                    },
                    usageMetadata = {
                        promptTokenCount = 10,
                        candidatesTokenCount = 10,
                        totalTokenCount = 20
                    }
                }
            end)

            -- Create proper prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Generate multiple responses")

            -- Call with a properly built prompt
            local response = text_generation.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages()
            })

            -- Verify we get both candidates concatenated
            expect(response.error).to_be_nil("Expected no error")
            expect(response.result).to_equal("First candidate responseSecond candidate response")
        end)

        it("should handle finish reason mapping correctly", function()
            -- Mock the prompt mapper function
            mock(prompt_mapper, "map_to_vertex", function(messages)
                return messages
            end)

            -- Define test cases for different finish reasons
            local finish_reason_tests = {
                { vertex_reason = "STOP", expected_reason = "stop" },
                { vertex_reason = "MAX_TOKENS", expected_reason = "length" },
                { vertex_reason = "SAFETY", expected_reason = "content_filter" },
                { vertex_reason = "RECITATION", expected_reason = "content_filter" },
                { vertex_reason = "OTHER", expected_reason = "OTHER" } -- Unmapped reason should pass through
            }

            -- Run tests for each finish reason
            for _, test_case in ipairs(finish_reason_tests) do
                -- Mock the vertex.FINISH_REASON_MAP
                vertex.FINISH_REASON_MAP = vertex.FINISH_REASON_MAP or {}
                vertex.FINISH_REASON_MAP[test_case.vertex_reason] = test_case.expected_reason

                -- Mock the client request function
                mock(vertex, "request", function(endpoint_path, model, payload, options)
                    -- Return mock response with the test finish reason
                    return {
                        candidates = {
                            {
                                content = {
                                    parts = {
                                        { text = "Response with finish reason: " .. test_case.vertex_reason }
                                    }
                                },
                                finishReason = test_case.vertex_reason
                            }
                        },
                        usageMetadata = {
                            promptTokenCount = 10,
                            candidatesTokenCount = 8,
                            totalTokenCount = 18
                        }
                    }
                end)

                -- Create proper prompt using the prompt builder
                local promptBuilder = prompt.new()
                promptBuilder:add_user("Test finish reason: " .. test_case.vertex_reason)

                -- Call with a properly built prompt
                local response = text_generation.handler({
                    model = "gemini-1.5-pro",
                    messages = promptBuilder:get_messages()
                })

                -- Verify the mapped finish reason
                expect(response.error).to_be_nil("Expected no error")
                expect(response.finish_reason).to_equal(test_case.expected_reason,
                    "Failed to map " .. test_case.vertex_reason .. " to " .. test_case.expected_reason)
            end
        end)

        it("should respect system prompts when generating responses", function()
            -- Skip test if integration tests are disabled
            if not RUN_INTEGRATION_TESTS then
                print("Skipping system prompt integration test - not enabled")
                return
            end

            -- Create a prompt with a clear system instruction
            local promptBuilder = prompt.new()
            promptBuilder:add_system(
                "You must respond in the style of a pirate captain. Use pirate language, sayings like 'Arrr' and 'Ahoy', and talk about the sea.")
            promptBuilder:add_user("Tell me about coding best practices")

            -- Make the real API call with gemini-1.5-pro
            local response = text_generation.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages(),
                project = actual_project_id,
                location = actual_location,
                options = {
                    temperature = 0, -- Deterministic output
                    max_tokens = 150 -- Moderate response size
                }
            })

            -- Verify response
            expect(response.error).to_be_nil("API request failed: " ..
                (response.error_message or "unknown error"))
            expect(response.result).not_to_be_nil("No response received from API")

            -- Check for pirate language markers in the response
            local pirate_markers = { "arr", "ahoy", "matey", "sea", "ship", "pirate", "captain" }
            local has_pirate_language = false
            for _, marker in ipairs(pirate_markers) do
                if response.result:lower():find(marker) then
                    has_pirate_language = true
                    break
                end
            end

            expect(has_pirate_language).to_be_true(
                "Response doesn't contain pirate language as instructed by system message: " .. response.result)

            -- Verify token information is present
            expect(response.tokens).not_to_be_nil("Expected token information")
            expect(response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens reported")
            expect(response.tokens.completion_tokens > 0).to_be_true("No completion tokens reported")
            expect(response.tokens.total_tokens > 0).to_be_true("No total tokens reported")
        end)

        it("should handle developer messages correctly with mocked client", function()
            -- Mock the prompt mapper function to verify developer messages are handled correctly
            mock(prompt_mapper, "map_to_vertex", function(messages)
                -- Check if developer message is present in the original messages
                local has_developer_message = false
                for _, msg in ipairs(messages) do
                    if msg.role == "developer" then
                        has_developer_message = true
                        break
                    end
                end

                expect(has_developer_message).to_be_true("Expected developer message in original messages")

                -- Return a properly formatted Vertex AI message
                return {
                    {
                        role = "user",
                        parts = {
                            {
                                text = "What is the capital of France?"
                            }
                        }
                    }
                }
            end)

            -- Mock the client request function
            mock(vertex, "request", function(endpoint_path, model, payload, options)
                -- Return mock successful response
                return {
                    candidates = {
                        {
                            content = {
                                parts = {
                                    {
                                        text = "Paris"
                                    }
                                }
                            },
                            finishReason = "STOP"
                        }
                    },
                    usageMetadata = {
                        promptTokenCount = 15,
                        candidatesTokenCount = 1,
                        totalTokenCount = 16
                    },
                    metadata = {
                        request_id = "req_devmsgtest123"
                    }
                }
            end)

            -- Create prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("What is the capital of France?")
            promptBuilder:add_developer("Provide a concise answer")

            -- Call with the properly built prompt
            local response = text_generation.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages()
            })

            -- Verify the response structure
            expect(response.error).to_be_nil("Expected no error")
            expect(response.result).to_equal("Paris")
            expect(response.tokens).not_to_be_nil("Expected token information")
            expect(response.tokens.prompt_tokens).to_equal(15)
            expect(response.tokens.completion_tokens).to_equal(1)
            expect(response.tokens.total_tokens).to_equal(16)
        end)

        it("should follow developer message language instructions with real API", function()
            -- Skip test if integration tests are disabled
            if not RUN_INTEGRATION_TESTS then
                print("Skipping integration test - not enabled")
                return
            end

            -- Create proper prompt using the prompt builder with language-specific instruction
            local promptBuilder = prompt.new()
            promptBuilder:add_user("What is the capital of France?")
            promptBuilder:add_developer("Reply in Spanish only, keep it short")

            -- Make a real API call with gemini-1.5-pro
            local response = text_generation.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages(),
                project = actual_project_id,
                location = actual_location,
                options = {
                    temperature = 0, -- Deterministic output
                    max_tokens = 20  -- Short response
                }
            })

            -- Verify response
            expect(response.error).to_be_nil("API request failed: " ..
                (response.error_message or "unknown error"))
            expect(response.result).not_to_be_nil("No response received from API")

            -- Check that the response contains Spanish text (common Spanish words)
            local spanish_words = { "París", "es", "la", "capital", "de", "Francia" }
            local is_spanish = false
            for _, word in ipairs(spanish_words) do
                if response.result:lower():find(word:lower()) then
                    is_spanish = true
                    break
                end
            end

            expect(is_spanish).to_be_true("Response does not appear to be in Spanish: " .. response.result)

            -- Should have token usage
            expect(response.tokens).not_to_be_nil("No token usage information received")
            expect(response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens reported")
            expect(response.tokens.completion_tokens > 0).to_be_true("No completion tokens reported")
            expect(response.tokens.total_tokens > 0).to_be_true("No total tokens reported")
        end)

        it("should handle length finish reason correctly with real API", function()
            -- Skip test if integration tests are disabled
            if not RUN_INTEGRATION_TESTS then
                print("Skipping integration test - not enabled")
                return
            end

            -- Create prompt
            local promptBuilder = prompt.new()
            promptBuilder:add_user(
                "Write a detailed explanation of quantum computing that is at least 100 sentences long. Make sure to cover quantum bits, quantum gates, quantum entanglement, quantum algorithms, quantum supremacy, and the future of quantum computing.")

            -- Call with a very small max_tokens to ensure we hit the length limit
            local response = text_generation.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages(),
                project = actual_project_id,
                location = actual_location,
                options = {
                    max_tokens = 15, -- Very small to ensure we hit length limit
                    temperature = 0  -- For consistency
                }
            })

            -- Verify no error
            expect(response.error).to_be_nil("API request failed: " ..
                (response.error_message or "unknown error"))

            -- Check tokens usage
            expect(response.tokens).not_to_be_nil("Expected token information")

            -- Verify tokens are close to our requested max
            expect(response.tokens.completion_tokens <= 20).to_be_true("Expected completion tokens near our max")

            -- Verify finish reason is length (mapped from MAX_TOKENS)
            expect(response.finish_reason).to_equal(output.FINISH_REASON.LENGTH)
        end)

        it("should handle context length exceeded error with mocked client", function()
            -- Mock the prompt mapper function
            mock(prompt_mapper, "map_to_vertex", function(messages)
                return messages
            end)

            -- Mock the client request function to simulate context length error
            mock(vertex, "request", function(endpoint_path, model, payload, options)
                -- Return nil and an error for context length exceeded
                return nil, {
                    status = 400,
                    message = "Content size 128100 exceeds the max content size limit of 128000",
                    body = { error = "Content too large" }
                }
            end)

            -- Mock error mapping function
            mock(vertex, "map_error", function(err)
                -- Customize error mapping for context length errors
                if err and err.message and err.message:match("exceeds the max content size") then
                    return {
                        error = output.ERROR_TYPE.CONTEXT_LENGTH,
                        error_message = "Vertex AI error: " .. err.message,
                        provider_error = err.body
                    }
                end

                -- Default error mapping
                return {
                    error = output.ERROR_TYPE.SERVER_ERROR,
                    error_message = "Vertex AI error: " .. (err.message or "Unknown error"),
                    provider_error = err.body
                }
            end)

            -- Create a prompt builder with a very large content
            local promptBuilder = prompt.new()

            -- Add a large user message
            local largeMessage = string.rep("This is a test message to exceed the context length. ", 6000)
            promptBuilder:add_user(largeMessage)

            -- Call with the large message
            local response = text_generation.handler({
                model = "gemini-1.5-pro",
                messages = promptBuilder:get_messages()
            })

            -- Verify the error type
            expect(response.error).to_equal(output.ERROR_TYPE.CONTEXT_LENGTH)
            expect(response.error_message).to_contain("exceeds the max content size")
        end)
    end)
end

return require("test").run_cases(define_tests)
