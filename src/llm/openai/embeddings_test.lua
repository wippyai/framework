local embeddings = require("embeddings")
local openai_client = require("openai_client")
local output = require("output")
local json = require("json")
local env = require("env")

local function define_tests()
    -- Toggle to enable/disable real API integration test
    local RUN_INTEGRATION_TESTS = env.get("ENABLE_INTEGRATION_TESTS")

    describe("OpenAI Embeddings Handler", function()
        local actual_api_key = nil

        before_all(function()
            -- Check if we have a real API key for integration tests
            actual_api_key = env.get("OPENAI_API_KEY")

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
            local response = embeddings.handler({
                input = "Test input"
            })

            expect(response.error).to_equal(output.ERROR_TYPE.INVALID_REQUEST)
            expect(response.error_message).to_contain("Model is required")

            -- Test missing input
            local response2 = embeddings.handler({
                model = "text-embedding-3-large"
            })

            expect(response2.error).to_equal(output.ERROR_TYPE.INVALID_REQUEST)
            expect(response2.error_message).to_contain("Input text is required")
        end)

        it("should successfully get embeddings with mocked client", function()
            -- Mock the client request function
            mock(openai_client, "request", function(endpoint_path, payload, options)
                -- Validate the request
                expect(endpoint_path).to_equal(openai_client.DEFAULT_EMBEDDING_ENDPOINT)
                expect(payload.model).to_equal("text-embedding-3-large")
                expect(payload.input).to_equal("Test text for embedding")

                -- Mock dimensions if specified
                if payload.dimensions then
                    expect(payload.dimensions).to_equal(768)
                end

                -- Return mock successful response
                return {
                    data = {
                        {
                            embedding = { 0.123, -0.456, 0.789, -0.012, 0.345 },
                            index = 0,
                            object = "embedding"
                        }
                    },
                    model = "text-embedding-3-large",
                    object = "list",
                    usage = {
                        prompt_tokens = 5,
                        total_tokens = 5
                    },
                    metadata = {
                        request_id = "req_mockembed123",
                        processing_ms = 50
                    }
                }
            end)

            -- Call embeddings handler
            local response = embeddings.handler({
                model = "text-embedding-3-large",
                input = "Test text for embedding",
                dimensions = 768
            })

            -- Verify the response structure
            expect(response.error).to_be_nil("Expected no error")
            expect(response.result).not_to_be_nil("Expected result array")
            expect(#response.result).to_equal(5, "Expected 5 dimensions in embedding")
            expect(response.result[1]).to_equal(0.123)
            expect(response.result[2]).to_equal(-0.456)

            -- Verify token usage
            expect(response.tokens).not_to_be_nil("Expected token information")
            expect(response.tokens.prompt_tokens).to_equal(5)
            expect(response.tokens.total_tokens).to_equal(5)

            -- Verify metadata
            expect(response.metadata).not_to_be_nil("Expected metadata")
            expect(response.metadata.request_id).to_equal("req_mockembed123")
            expect(response.metadata.processing_ms).to_equal(50)

            -- Verify provider info
            expect(response.provider).to_equal("openai")
            expect(response.model).to_equal("text-embedding-3-large")
        end)

        it("should handle array of inputs with mocked client", function()
            -- Mock the client request function
            mock(openai_client, "request", function(endpoint_path, payload, options)
                -- Validate the request
                expect(endpoint_path).to_equal(openai_client.DEFAULT_EMBEDDING_ENDPOINT)
                expect(payload.model).to_equal("text-embedding-3-large")

                -- Verify array of inputs
                expect(type(payload.input)).to_equal("table")
                expect(#payload.input).to_equal(2)
                expect(payload.input[1]).to_equal("First text")
                expect(payload.input[2]).to_equal("Second text")

                -- Return mock successful response with multiple embeddings
                return {
                    data = {
                        {
                            embedding = { 0.111, -0.222, 0.333 },
                            index = 0,
                            object = "embedding"
                        },
                        {
                            embedding = { 0.444, -0.555, 0.666 },
                            index = 1,
                            object = "embedding"
                        }
                    },
                    model = "text-embedding-3-large",
                    object = "list",
                    usage = {
                        prompt_tokens = 8,
                        total_tokens = 8
                    },
                    metadata = {
                        request_id = "req_mockmultiple123",
                        processing_ms = 65
                    }
                }
            end)

            -- Call embeddings handler with array of inputs
            local response = embeddings.handler({
                model = "text-embedding-3-large",
                input = { "First text", "Second text" }
            })

            -- Verify the response structure
            expect(response.error).to_be_nil("Expected no error")
            expect(response.result).not_to_be_nil("Expected result array")

            -- Should have array of arrays
            expect(#response.result).to_equal(2, "Expected 2 embeddings")
            expect(#response.result[1]).to_equal(3, "Expected 3 dimensions in first embedding")
            expect(#response.result[2]).to_equal(3, "Expected 3 dimensions in second embedding")

            -- Check values of first embedding
            expect(response.result[1][1]).to_equal(0.111)
            expect(response.result[1][2]).to_equal(-0.222)
            expect(response.result[1][3]).to_equal(0.333)

            -- Check values of second embedding
            expect(response.result[2][1]).to_equal(0.444)
            expect(response.result[2][2]).to_equal(-0.555)
            expect(response.result[2][3]).to_equal(0.666)

            -- Verify token usage
            expect(response.tokens.prompt_tokens).to_equal(8)
            expect(response.tokens.total_tokens).to_equal(8)
        end)

        it("should handle model errors correctly with mocked client", function()
            -- Mock the client request function to simulate a model error
            mock(openai_client, "request", function(endpoint_path, payload, options)
                -- Return an error with the correct error type from real API
                return nil, {
                    type = "invalid_request_error",
                    message = "The model 'nonexistent-embedding-model' does not exist or you do not have access to it.",
                    status_code = 404
                }
            end)

            -- Call with a non-existent model
            local response = embeddings.handler({
                model = "nonexistent-embedding-model",
                input = "Test input"
            })

            -- Verify the mapped error type
            expect(response.error).to_equal(output.ERROR_TYPE.MODEL_ERROR)
            expect(response.error_message).to_contain("does not exist")
        end)

        it("should connect to real OpenAI API with text-embedding-3-small model", function()
            -- Skip test if integration tests are disabled
            if not RUN_INTEGRATION_TESTS then
                print("Skipping integration test - not enabled")
                return
            end

            -- Make a real API call with text-embedding-3-small
            local response = embeddings.handler({
                model = "text-embedding-3-small",
                input = "This is a test for embedding API integration",
                api_key = actual_api_key
            })

            -- Verify response
            expect(response.error).to_be_nil("API request failed: " ..
                (response.error_message or "unknown error"))
            expect(response.result).not_to_be_nil("No embedding received from API")

            -- Check embedding structure
            expect(type(response.result)).to_equal("table", "Result should be an array")
            expect(#response.result >= 100).to_be_true("Embedding should have multiple dimensions")

            -- Sanity check on first few values - they should be floating point numbers
            for i = 1, 5 do
                if response.result[i] then
                    expect(type(response.result[i])).to_equal("number", "Embedding values should be numbers")
                end
            end

            -- Check token usage
            expect(response.tokens).not_to_be_nil("No token usage information received")
            expect(response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens reported")
            expect(response.tokens.total_tokens > 0).to_be_true("No total tokens reported")

            -- Check provider info
            expect(response.provider).to_equal("openai")
            expect(response.model).to_equal("text-embedding-3-small")
        end)

        it("should handle multiple inputs with real OpenAI API", function()
            -- Skip test if integration tests are disabled
            if not RUN_INTEGRATION_TESTS then
                print("Skipping integration test - not enabled")
                return
            end

            -- Make a real API call with multiple inputs
            local response = embeddings.handler({
                model = "text-embedding-3-small",
                input = {
                    "First test sentence for embedding.",
                    "Second completely different sentence."
                },
                api_key = actual_api_key
            })

            -- Verify response
            expect(response.error).to_be_nil("API request failed: " ..
                (response.error_message or "unknown error"))
            expect(response.result).not_to_be_nil("No embeddings received from API")

            -- Check multiple embeddings structure
            expect(type(response.result)).to_equal("table", "Result should be an array")
            expect(#response.result).to_equal(2, "Should have 2 embeddings")
            expect(type(response.result[1])).to_equal("table", "First result should be an array")
            expect(type(response.result[2])).to_equal("table", "Second result should be an array")

            -- Check dimensions of both embeddings - they should be the same
            expect(#response.result[1] > 0).to_be_true("First embedding should have dimensions")
            expect(#response.result[2] > 0).to_be_true("Second embedding should have dimensions")
            expect(#response.result[1]).to_equal(#response.result[2], "Both embeddings should have same dimensions")

            -- Check token usage
            expect(response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens reported")
            expect(response.tokens.total_tokens > 0).to_be_true("No total tokens reported")
        end)

        it("should handle wrong model errors correctly with real API", function()
            -- Skip test if integration tests are disabled
            if not RUN_INTEGRATION_TESTS then
                print("Skipping integration test - not enabled")
                return
            end

            -- Call with a deliberately incorrect model name
            local response = embeddings.handler({
                model = "nonexistent-embedding-model",
                input = "Test input for error handling",
                api_key = actual_api_key
            })

            -- Verify error handling with real API
            expect(response.error).to_equal(output.ERROR_TYPE.MODEL_ERROR)
            expect(response.error_message).to_contain("does not exist")
        end)

        it("should respect the dimensions parameter with real API", function()
            -- Skip test if integration tests are disabled
            if not RUN_INTEGRATION_TESTS then
                print("Skipping integration test - not enabled")
                return
            end

            -- Make two API calls with different dimensions
            local response1 = embeddings.handler({
                model = "text-embedding-3-small",
                input = "Test input for dimension testing",
                dimensions = 256, -- Request reduced dimensions
                api_key = actual_api_key
            })

            local response2 = embeddings.handler({
                model = "text-embedding-3-small",
                input = "Test input for dimension testing",
                dimensions = 512, -- Request different dimensions
                api_key = actual_api_key
            })

            -- Verify both responses succeeded
            expect(response1.error).to_be_nil("First API request failed")
            expect(response2.error).to_be_nil("Second API request failed")

            -- Check that dimensions parameter was respected
            expect(#response1.result).to_equal(256, "First response should have 256 dimensions")
            expect(#response2.result).to_equal(512, "Second response should have 512 dimensions")
        end)
    end)
end

return require("test").run_cases(define_tests)