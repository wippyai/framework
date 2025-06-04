local text_generation = require("text_generation")
local claude_client = require("claude_client")
local output = require("output")
local json = require("json")
local env = require("env")
local prompt = require("prompt")
local time = require("time")

local function define_tests()
    -- Toggle to enable/disable real API integration test
    local RUN_INTEGRATION_TESTS = env.get("ENABLE_INTEGRATION_TESTS")

    describe("Claude Text Generation Handler", function()
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

        it("should successfully generate text with mocked client", function()
            -- Mock the claude.request function
            mock(claude_client, "request", function(endpoint_path, payload, options)
                -- Validate the request
                expect(endpoint_path).to_equal(claude_client.API_ENDPOINTS.MESSAGES)
                expect(payload.model).to_equal("claude-3-5-haiku-20241022")

                -- Check messages array
                local found_user_message = false
                for _, msg in ipairs(payload.messages) do
                    if msg.role == "user" then
                        -- Look for the expected message content
                        if type(msg.content) == "table" then
                            for _, content in ipairs(msg.content) do
                                if content.type == "text" and content.text == "Say hello world" then
                                    found_user_message = true
                                    break
                                end
                            end
                        end
                    end
                end
                expect(found_user_message).to_be_true("Expected user message with 'Say hello world' content")

                -- Return mock successful response
                return {
                    content = {
                        {
                            type = "text",
                            text = "Hello, world!"
                        }
                    },
                    id = "msg_mock123",
                    model = "claude-3-5-haiku-20241022",
                    role = "assistant",
                    stop_reason = "end_turn",
                    stop_sequence = nil,
                    type = "message",
                    usage = {
                        input_tokens = 10,
                        output_tokens = 5
                    },
                    -- Add metadata to match new client expectations
                    metadata = {
                        request_id = "req_mock123",
                        processing_ms = 150
                    }
                }
            end)

            -- Create proper prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Say hello world")

            -- Call with a properly built prompt
            local response = text_generation.handler({
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages()
            })

            -- Verify the response structure
            expect(response.error).to_be_nil("Expected no error")
            expect(response.result).to_equal("Hello, world!")
            expect(response.tokens).not_to_be_nil("Expected token information")
            expect(response.tokens.prompt_tokens).to_equal(10)
            expect(response.tokens.completion_tokens).to_equal(5)
            expect(response.tokens.total_tokens).to_equal(15)
            expect(response.finish_reason).to_equal("stop") -- Mapped from "end_turn"
            expect(response.metadata).not_to_be_nil("Expected metadata in response")
            expect(response.metadata.request_id).to_equal("req_mock123")
        end)

        it("should handle wrong model errors correctly with mocked client", function()
            -- Mock the claude.request function to simulate a model error
            mock(claude_client, "request", function(endpoint_path, payload, options)
                -- Return a model-related error with the correct error type from real API
                return nil, {
                    status_code = 404,
                    message = "The model 'nonexistent-model' does not exist or you do not have access to it."
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
            expect(response.error).to_equal(output.ERROR_TYPE.MODEL_ERROR,
                "Expected MODEL_ERROR but got: " .. (response.error or "nil"))
            expect(response.error_message).to_contain("does not exist",
                "Error message didn't contain expected text: " .. (response.error_message or "nil"))

            -- Verify error mapping was called correctly
            -- This is implicitly checked by the response error type
        end)

        it("should connect to real Claude API with claude-3-5-haiku model", function()
            -- Skip test if integration tests are disabled
            if not RUN_INTEGRATION_TESTS then
                print("Skipping integration test - not enabled")
                return
            end

            -- Create proper prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Reply with exactly the text 'Integration test successful'")

            -- Make a real API call with claude-3-5-haiku
            local response = text_generation.handler({
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages(),
                options = {
                    temperature = 0, -- Deterministic output
                    max_tokens = 15  -- Short response
                },
                api_key = actual_api_key
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

            -- Should have metadata
            expect(response.metadata).not_to_be_nil("No metadata received from API")
            expect(response.metadata.request_id).not_to_be_nil("No request ID in metadata")
        end)

        it("should handle wrong model errors correctly with real API", function()
            -- Skip test if integration tests are disabled
            if not RUN_INTEGRATION_TESTS then
                print("Skipping integration test - not enabled")
                return
            end

            -- Create proper prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("This is an integration test message")

            -- Call with a deliberately incorrect model name
            local response = text_generation.handler({
                model = "nonexistent-model",
                messages = promptBuilder:get_messages(),
                api_key = actual_api_key -- Use the real API key
            })

            print(response.error_message)

            -- Verify error handling with real API
            expect(response.error).to_equal(output.ERROR_TYPE.MODEL_ERROR)
            expect(response.error_message).to_contain("nonexistent-model")
        end)

        it("should handle length stop reason correctly with mocked client", function()
            -- Mock the client request function
            mock(claude_client, "request", function(endpoint_path, payload, options)
                -- Validate the request
                expect(endpoint_path).to_equal(claude_client.API_ENDPOINTS.MESSAGES)
                expect(payload.model).to_equal("claude-3-5-haiku-20241022")
                expect(payload.max_tokens).to_equal(8) -- Verify max_tokens is passed

                -- Return a response with max_tokens as finish reason
                return {
                    content = {
                        {
                            type = "text",
                            text = "Here's a comprehensive response that will aim"
                        }
                    },
                    id = "msg_mock456",
                    model = "claude-3-5-haiku-20241022",
                    role = "assistant",
                    stop_reason = "max_tokens",
                    stop_sequence = nil,
                    type = "message",
                    usage = {
                        input_tokens = 10,
                        output_tokens = 8
                    },
                    -- Add metadata to match new client expectations
                    metadata = {
                        request_id = "req_mock456",
                        processing_ms = 150
                    }
                }
            end)

            -- Create prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Generate a long response that should hit the max tokens limit")

            -- Call with a small max_tokens setting
            local response = text_generation.handler({
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages(),
                options = {
                    max_tokens = 8 -- Deliberately small to trigger max_tokens
                }
            })

            -- Verify finish reason mapping
            expect(response.finish_reason).to_equal(output.FINISH_REASON.LENGTH)
            expect(response.result).to_equal("Here's a comprehensive response that will aim")

            -- Verify token usage info is passed through
            expect(response.tokens).not_to_be_nil("Expected token information")
            expect(response.tokens.prompt_tokens).to_equal(10)
            expect(response.tokens.completion_tokens).to_equal(8)
            expect(response.tokens.total_tokens).to_equal(18)

            -- Verify metadata is included
            expect(response.metadata).not_to_be_nil("Expected metadata in response")
            expect(response.metadata.request_id).to_equal("req_mock456")
        end)

        it("should handle context length exceeded error with mocked client", function()
            -- Mock the client request function to simulate context length error
            mock(claude_client, "request", function(endpoint_path, payload, options)
                -- Return nil and an error for context length exceeded
                return nil, {
                    status_code = 400,
                    message =
                    "This model's maximum context length is 128000 tokens. However, your message resulted in 130000 tokens. Please reduce the length of the messages."
                }
            end)

            -- We no longer need to mock map_error since that's part of the actual code we're testing
            -- The real map_error function should handle this error type correctly

            -- Create a prompt builder with a very large content
            local promptBuilder = prompt.new()

            -- Add a large user message
            local largeMessage = string.rep("This is a test message to exceed the context length. ", 6000)
            promptBuilder:add_user(largeMessage)

            -- Call with the large message
            local response = text_generation.handler({
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages()
            })

            -- Verify the error type
            expect(response.error).to_equal(output.ERROR_TYPE.CONTEXT_LENGTH)
            expect(response.error_message).to_contain("maximum context length")

            -- Optionally, add more specific checks on the exact error message
            expect(response.error_message).to_contain("128000 tokens")
            expect(response.error_message).to_contain("130000 tokens")
        end)

        it("should handle length finish reason correctly with real API", function()
            -- Skip if not running integration tests
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
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages(),
                options = {
                    max_tokens = 15, -- Very small to ensure we hit length limit
                    temperature = 0  -- For consistency
                },
                api_key = actual_api_key
            })

            -- Verify no error
            expect(response.error).to_be_nil("API request failed: " ..
                (response.error_message or "unknown error"))

            -- Check tokens usage
            expect(response.tokens).not_to_be_nil("Expected token information")

            -- Verify tokens are close to our requested max
            expect(response.tokens.completion_tokens <= 20).to_be_true("Expected completion tokens near our max")

            -- Verify finish reason is length
            expect(response.finish_reason).to_equal(output.FINISH_REASON.LENGTH)
        end)

        it("should handle context length errors correctly with real API", function()
            -- Skip if not running integration tests
            if not RUN_INTEGRATION_TESTS then
                print("Skipping integration test - not enabled")
                return
            end

            -- Create a prompt builder with extremely large content
            local promptBuilder = prompt.new()

            -- Generate a message that will exceed Claude's context window
            -- Haiku has a 200K token context, so we need to create something huge
            -- Each repetition is about 15 tokens, so 14,000 repetitions should be over 210K tokens
            local largeMessage = string.rep("This is a test message to exceed the context length of Claude 3.5 Haiku. ",
                14000)

            -- Add the large message as user input
            promptBuilder:add_user(largeMessage)

            -- Call Claude API with the large message
            local response = text_generation.handler({
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages(),
                api_key = actual_api_key
            })

            -- Verify the error type matches what we expect for context length exceeded
            expect(response.error).to_equal(output.ERROR_TYPE.CONTEXT_LENGTH,
                "Expected CONTEXT_LENGTH error but got: " .. (response.error or "nil"))

            -- The exact error message might vary, but should mention tokens or size
            expect(response.error_message).to_match("token",
                "Error should mention tokens but got: " .. (response.error_message or "nil"))
        end)

        it("should correctly handle extended thinking with claude-3-7-sonnet", function()
            -- Skip if not running integration tests
            if not RUN_INTEGRATION_TESTS then
                print("Skipping integration test - not enabled")
                return
            end

            -- Create prompt for a reasoning task
            local promptBuilder = prompt.new()
            promptBuilder:add_user(
                "Solve this step by step: If a train travels at 60 mph for 2.5 hours, then slows down to 40 mph for 1.5 hours, what is the total distance traveled?")

            -- Print test info
            print("Running extended thinking test with Claude 3.7 Sonnet")

            -- Call with thinking enabled
            local response = text_generation.handler({
                model = "claude-3-7-sonnet-20250219", -- Use Claude 3.7 Sonnet
                messages = promptBuilder:get_messages(),
                options = {
                    thinking_effort = 20, -- Enable thinking
                    temperature = 0       -- For consistent results
                },
                api_key = actual_api_key
            })

            -- Log full response for debugging
            print("Response error: " .. (response.error or "nil"))
            print("Response error_message: " .. (response.error_message or "nil"))

            -- If we got an error, log it but continue the test
            if response.error then
                print("TEST WARNING: Got error from API: " .. response.error .. " - " .. (response.error_message or ""))
                print("This might be expected if the model doesn't support thinking")

                -- Check if this is a "thinking not supported" error
                if response.error == "invalid_request" and
                    response.error_message and
                    (response.error_message:match("thinking") or response.error_message:match("not supported")) then
                    print("Skipping remaining assertions because thinking is not supported")
                    return
                end
            end

            -- Verify no error (this will now fail if we get an error)
            expect(response.error).to_be_nil("API request failed: " ..
                (response.error_message or "unknown error"))

            -- Verify response has token information
            expect(response.tokens).not_to_be_nil("Expected token information")
            expect(response.tokens.prompt_tokens > 0).to_be_true("Expected non-zero prompt tokens")
            expect(response.tokens.completion_tokens > 0).to_be_true("Expected non-zero completion tokens")

            -- Verify we got a reasonable answer containing the correct numbers
            expect(response.result).to_contain("150") -- 60 mph * 2.5 hours = 150 miles
            expect(response.result).to_contain("60")  -- 40 mph * 1.5 hours = 60 miles
            expect(response.result).to_contain("210") -- 150 + 60 = 210 miles

            -- Check if thinking content was returned
            if response.thinking then
                print("Thinking content received, length: " .. #response.thinking)
                expect(#response.thinking > 0).to_be_true("Expected non-empty thinking content")
            else
                print("No thinking content received in the response")
            end
        end)

        it("should correctly handle extended thinking with mocked client", function()
            -- Mock the client request function
            mock(claude_client, "request", function(endpoint_path, payload, options)
                -- Verify that thinking is enabled for Claude 3.7 models
                if payload.model:match("claude%-3%-7") or payload.model:match("claude%-3%.7") then
                    expect(payload.thinking).not_to_be_nil("Expected thinking to be enabled")
                    expect(payload.thinking.type).to_equal("enabled")
                    expect(payload.thinking.budget_tokens >= 1024).to_be_true("Expected thinking budget >= 1024")
                else
                    -- For non-3.7 models, thinking should not be set
                    expect(payload.thinking).to_be_nil("Thinking should not be enabled for non-3.7 models")
                end

                -- Return a mock response with thinking
                return {
                    content = {
                        {
                            type = "text",
                            text =
                            "To solve this problem, I'll calculate the distance traveled in each segment and add them together.\n\nFor the first segment:\nDistance = Speed × Time\nDistance = 60 mph × 2.5 hours = 150 miles\n\nFor the second segment:\nDistance = 40 mph × 1.5 hours = 60 miles\n\nTotal distance = 150 miles + 60 miles = 210 miles"
                        }
                    },
                    id = "msg_thinking123",
                    model = payload.model,
                    role = "assistant",
                    stop_reason = "end_turn",
                    stop_sequence = nil,
                    type = "message",
                    usage = {
                        input_tokens = 30,
                        output_tokens = 80
                    },
                    metadata = {
                        request_id = "req_mock123",
                        processing_ms = 150
                    }
                }
            end)

            -- Create prompt
            local promptBuilder = prompt.new()
            promptBuilder:add_user(
                "Solve this step by step: If a train travels at 60 mph for 2.5 hours, then slows down to 40 mph for 1.5 hours, what is the total distance traveled?")

            -- Call with thinking enabled for Claude 3.7
            local response = text_generation.handler({
                model = "claude-3-7-sonnet-20250219", -- Model that supports thinking
                messages = promptBuilder:get_messages(),
                options = {
                    thinking_effort = 20 -- Enable thinking
                }
            })

            -- Verify the response structure
            expect(response.error).to_be_nil("Expected no error")
            expect(response.result).to_contain("210 miles")

            -- Verify token usage info
            expect(response.tokens.prompt_tokens).to_equal(30)
            expect(response.tokens.completion_tokens).to_equal(80)
            expect(response.tokens.total_tokens).to_equal(110)

            -- Now test with a model that doesn't support thinking
            local response2 = text_generation.handler({
                model = "claude-3-5-haiku-20241022", -- Model that doesn't support thinking
                messages = promptBuilder:get_messages(),
                options = {
                    thinking_effort = 20 -- Enable thinking, but it should be ignored
                }
            })

            -- Verify still successful
            expect(response2.error).to_be_nil("Expected no error with unsupported model")
            expect(response2.result).to_contain("210 miles")
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

            -- Make a real API call
            local response = text_generation.handler({
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages(),
                options = {
                    temperature = 0, -- Deterministic output
                    max_tokens = 20  -- Short response
                },
                api_key = actual_api_key
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
        end)

        it("should handle developer messages correctly with mocked client", function()
            -- Mock the claude.request function
            mock(claude_client, "request", function(endpoint_path, payload, options)
                -- Validate the request
                expect(endpoint_path).to_equal(claude_client.API_ENDPOINTS.MESSAGES)
                expect(payload.model).to_equal("claude-3-5-haiku-20241022")

                -- Check that the user message contains the developer instructions
                local found_dev_content = false

                for _, msg in ipairs(payload.messages) do
                    if msg.role == "user" then
                        for _, content_part in ipairs(msg.content) do
                            -- Print the content for debugging
                            print("Content part:", content_part.type, content_part.text)

                            if content_part.type == "text" and
                                type(content_part.text) == "string" and
                                content_part.text:find("<developer%-instruction>") then
                                found_dev_content = true
                                break
                            end
                        end
                    end
                end

                expect(found_dev_content).to_be_true("Developer message not appended to user message")

                -- Return mock successful response
                return {
                    content = {
                        {
                            type = "text",
                            text = "Paris"
                        }
                    },
                    id = "msg_devmsg123",
                    model = "claude-3-5-haiku-20241022",
                    role = "assistant",
                    stop_reason = "end_turn",
                    stop_sequence = nil,
                    type = "message",
                    usage = {
                        input_tokens = 15,
                        output_tokens = 1
                    },
                    metadata = {
                        request_id = "req_mock456",
                        processing_ms = 120
                    }
                }
            end)

            -- Create prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("What is the capital of France?")
            promptBuilder:add_developer("Provide a concise answer")

            -- Call with the properly built prompt
            local response = text_generation.handler({
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages()
            })

            -- Verify the response structure
            expect(response.error).to_be_nil("Expected no error")
            expect(response.result).to_equal("Paris")
            expect(response.tokens).not_to_be_nil("Expected token information")
            expect(response.tokens.prompt_tokens).to_equal(15)
            expect(response.tokens.completion_tokens).to_equal(1)
            expect(response.tokens.total_tokens).to_equal(16)
            expect(response.finish_reason).to_equal("stop")
        end)

        it("should handle multiple system messages correctly with mocked client", function()
            -- Mock the client request function
            mock(claude_client, "request", function(endpoint_path, payload, options)
                -- Validate the request
                expect(endpoint_path).to_equal(claude_client.API_ENDPOINTS.MESSAGES)
                expect(payload.model).to_equal("claude-3-5-haiku-20241022")

                -- Check that system content has multiple blocks
                expect(payload.system).not_to_be_nil("Expected system content")

                -- Check specific content in system blocks
                local found_first_instruction = false
                local found_second_instruction = false

                for _, block in ipairs(payload.system) do
                    if block.type == "text" and block.text:match("Be concise") then
                        found_first_instruction = true
                    end
                    if block.type == "text" and block.text:match("Use bullet points") then
                        found_second_instruction = true
                    end
                end

                expect(found_first_instruction).to_be_true("First system instruction not found")
                expect(found_second_instruction).to_be_true("Second system instruction not found")

                -- Return mock successful response
                return {
                    content = {
                        {
                            type = "text",
                            text = "• Paris is the capital of France\n• It's known as the City of Light"
                        }
                    },
                    id = "msg_sysmsgs123",
                    model = "claude-3-5-haiku-20241022",
                    role = "assistant",
                    stop_reason = "end_turn",
                    stop_sequence = nil,
                    type = "message",
                    usage = {
                        input_tokens = 25,
                        output_tokens = 15
                    },
                    metadata = {
                        request_id = "req_mock789",
                        processing_ms = 130
                    }
                }
            end)

            -- Create prompt with system and user messages
            local promptBuilder = prompt.new()
            promptBuilder:add_system("Be concise and to the point.")
            promptBuilder:add_system("Use bullet points in your response.")
            promptBuilder:add_user("Tell me about Paris, France")

            -- Call with the properly built prompt
            local response = text_generation.handler({
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages()
            })

            -- Verify the response structure
            expect(response.error).to_be_nil("Expected no error")
            expect(response.result).to_contain("Paris is the capital of France")
            expect(response.result).to_contain("• ") -- Contains bullet points
            expect(response.tokens).not_to_be_nil("Expected token information")
            expect(response.tokens.prompt_tokens).to_equal(25)
            expect(response.tokens.completion_tokens).to_equal(15)
            expect(response.tokens.total_tokens).to_equal(40)
            expect(response.finish_reason).to_equal("stop")
        end)

        it("should handle multiple system messages with real API", function()
            -- Skip test if integration tests are disabled
            if not RUN_INTEGRATION_TESTS then
                print("Skipping integration test - not enabled")
                return
            end

            -- Create prompt with multiple system messages and user message
            local promptBuilder = prompt.new()
            -- Add first system message as text
            promptBuilder:add_system("Be extremely concise - use 15 words or fewer.")

            -- Add second system message using the content block approach through a custom message
            promptBuilder:add_message(
                prompt.ROLE.SYSTEM,
                {
                    {
                        type = "text",
                        text = "Format your response as a haiku poem."
                    }
                }
            )

            promptBuilder:add_user("Describe the concept of time")

            -- Make a real API call with the properly built prompt
            local response = text_generation.handler({
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages(),
                options = {
                    temperature = 0, -- Deterministic output
                    max_tokens = 30  -- Short response
                },
                api_key = actual_api_key
            })

            -- Verify response
            expect(response.error).to_be_nil("API request failed: " ..
                (response.error_message or "unknown error"))
            expect(response.result).not_to_be_nil("No response received from API")

            -- Verify it's a haiku (3 lines) and concise
            local line_count = 0
            for _ in response.result:gmatch("\n") do
                line_count = line_count + 1
            end

            -- Count words (approximately - splitting by space)
            local word_count = 0
            for _ in response.result:gmatch("%S+") do
                word_count = word_count + 1
            end

            -- A haiku should have 3 lines
            expect(line_count >= 2).to_be_true("Response should be formatted as a haiku with at least 3 lines")

            -- Should be concise (15 words or fewer)
            expect(word_count <= 17).to_be_true("Response should be concise (15 words or fewer): " .. response.result)
        end)

        -- Fixed test for developer messages
        it("should handle developer messages correctly with mocked client", function()
            -- Mock the claude.request function
            mock(claude_client, "request", function(endpoint_path, payload, options)
                -- Validate the request
                expect(endpoint_path).to_equal(claude_client.API_ENDPOINTS.MESSAGES)
                expect(payload.model).to_equal("claude-3-5-haiku-20241022")

                -- With the current design, developer instructions are appended to the previous message
                -- Check that the user message contains the developer instructions
                local found_dev_content = false

                for _, msg in ipairs(payload.messages) do
                    if msg.role == "user" then
                        for _, content_part in ipairs(msg.content) do
                            if content_part.type == "text" and
                                content_part.text:match("<developer%-instruction>.*concise answer.*</developer%-instruction>") then
                                found_dev_content = true
                                break
                            end
                        end
                    end
                end

                expect(found_dev_content).to_be_true("Developer message not appended to user message")

                -- Return mock successful response
                return {
                    content = {
                        {
                            type = "text",
                            text = "Paris"
                        }
                    },
                    id = "msg_devmsg123",
                    model = "claude-3-5-haiku-20241022",
                    role = "assistant",
                    stop_reason = "end_turn",
                    stop_sequence = nil,
                    type = "message",
                    usage = {
                        input_tokens = 15,
                        output_tokens = 1
                    },
                    metadata = {
                        request_id = "req_mock456",
                        processing_ms = 120
                    }
                }
            end)

            -- Create prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("What is the capital of France?")
            promptBuilder:add_developer("Provide a concise answer")

            -- Call with the properly built prompt
            local response = text_generation.handler({
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages()
            })

            -- Verify the response structure
            expect(response.error).to_be_nil("Expected no error")
            expect(response.result).to_equal("Paris")
            expect(response.tokens).not_to_be_nil("Expected token information")
            expect(response.tokens.prompt_tokens).to_equal(15)
            expect(response.tokens.completion_tokens).to_equal(1)
            expect(response.tokens.total_tokens).to_equal(16)
            expect(response.finish_reason).to_equal("stop")
        end)

        -- Fixed test for combining developer messages with system messages
        it("should combine developer messages with system messages correctly with mocked client", function()
            -- Mock the claude.request function
            mock(claude_client, "request", function(endpoint_path, payload, options)
                -- Validate the request
                expect(endpoint_path).to_equal(claude_client.API_ENDPOINTS.MESSAGES)

                -- Check system content exists
                expect(payload.system).not_to_be_nil("Expected system content")

                -- Find system content with historian instructions
                local found_system_content = false
                for _, block in ipairs(payload.system) do
                    if block.type == "text" and block.text:match("Speak like a historian") then
                        found_system_content = true
                        break
                    end
                end
                expect(found_system_content).to_be_true("System content not found")

                -- With the current design, developer instructions are appended to the user message
                local found_dev_content = false
                for _, msg in ipairs(payload.messages) do
                    if msg.role == "user" then
                        for _, content_part in ipairs(msg.content) do
                            if content_part.type == "text" and
                                type(content_part.text) == "string" and
                                content_part.text:find("<developer%-instruction>") then
                                found_dev_content = true
                                break
                            end
                        end
                    end
                end
                expect(found_dev_content).to_be_true("Developer message not appended to user message")

                -- Return mock successful response
                return {
                    content = {
                        {
                            type = "text",
                            text =
                            "The Battle of Hastings occurred on October 14, 1066, when William, Duke of Normandy defeated King Harold II of England."
                        }
                    },
                    id = "msg_combined123",
                    model = "claude-3-5-haiku-20241022",
                    role = "assistant",
                    stop_reason = "end_turn",
                    stop_sequence = nil,
                    type = "message",
                    usage = {
                        input_tokens = 40,
                        output_tokens = 25
                    },
                    metadata = {
                        request_id = "req_mock321",
                        processing_ms = 140
                    }
                }
            end)

            -- Create prompt with system message and developer message
            local promptBuilder = prompt.new()
            promptBuilder:add_system("Speak like a historian focusing on medieval Europe.")
            promptBuilder:add_user("Tell me about the Battle of Hastings")
            promptBuilder:add_developer("Include exact dates for historical events")

            -- Call with the properly built prompt - USING text_generation HANDLER, not tool_calling
            local response = text_generation.handler({
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages()
            })

            -- Verify the response structure
            expect(response.error).to_be_nil("Expected no error")
            expect(response.result).to_contain("1066")       -- Contains exact date
            expect(response.result).to_contain("October 14") -- More exact date
            expect(response.tokens).not_to_be_nil("Expected token information")
        end)

        it("should combine multiple system messages and developer messages with real API", function()
            -- Skip test if integration tests are disabled
            if not RUN_INTEGRATION_TESTS then
                print("Skipping integration test - not enabled")
                return
            end

            -- Create system messages with specific formatting instructions
            local system_messages = {
                "You are a technical writer creating documentation.",
                {
                    type = "text",
                    text = "All responses must be formatted with bullet points."
                }
            }

            -- Create prompt with specific query and developer instructions
            local promptBuilder = prompt.new()
            promptBuilder:add_user("List benefits of cloud computing")
            -- Developer instruction that adds specific constraints
            promptBuilder:add_developer("Include EXACTLY 3 bullet points. No more, no less.")

            -- Make a real API call
            local response = text_generation.handler({
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages(),
                system = system_messages,
                options = {
                    temperature = 0 -- Deterministic output
                },
                api_key = actual_api_key
            })

            -- Verify response
            expect(response.error).to_be_nil("API request failed: " ..
                (response.error_message or "unknown error"))
            expect(response.result).not_to_be_nil("No response received from API")

            -- Verify it follows the system instruction to use bullet points
            local bullet_point_count = 0
            for _ in response.result:gmatch("•") do
                bullet_point_count = bullet_point_count + 1
            end

            if bullet_point_count == 0 then
                -- Alternative bullet point format
                for _ in response.result:gmatch("%-") do
                    bullet_point_count = bullet_point_count + 1
                end
            end

            expect(bullet_point_count).to_equal(3,
                "Response should contain exactly 3 bullet points as specified in developer instructions")

            -- Verify it follows the system instruction to be a technical writer
            local has_technical_terms = false
            if response.result:match("infrastructure") or
                response.result:match("scalability") or
                response.result:match("flexibility") or
                response.result:match("efficiency") then
                has_technical_terms = true
            end

            expect(has_technical_terms).to_be_true(
                "Response should include technical terminology as instructed in system message")
        end)

        it("should handle streaming text generation with real Claude API", function()
            -- Skip test if integration tests are disabled
            if not RUN_INTEGRATION_TESTS then
                print("Skipping integration test - not enabled")
                return
            end

            -- Set up process.send mock to capture streamed responses
            local received_messages = {}
            mock(process, "send", function(pid, topic, data)
                table.insert(received_messages, { pid = pid, topic = topic, data = data })
            end)

            -- Create prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user(
                "Summarize the advantages of streaming LLM responses in exactly 3 bullet points. Keep it short and concise.")

            -- Call with streaming enabled and real API key
            local response = text_generation.handler({
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages(),
                options = {
                    temperature = 0, -- Deterministic output
                    max_tokens = 150 -- Moderate response size
                },
                api_key = actual_api_key,
                stream = {
                    reply_to = "integration-test-pid",
                    topic = "integration_stream_test",
                    buffer_size = 10 -- Small buffer to ensure multiple chunks
                }
            })

            -- Verify the response structure for streaming
            expect(response.error).to_be_nil("API request failed: " ..
                (response.error_message or "unknown error"))
            expect(response.streaming).to_be_true("Response should indicate streaming")
            expect(response.result).not_to_be_nil("Should have complete response content")

            -- Verify streamed messages - should have at least one
            expect(#received_messages > 0).to_be_true("Should have received stream messages")

            -- Check for content messages
            local content_count = 0
            local complete_text = ""

            for _, msg in ipairs(received_messages) do
                expect(msg.pid).to_equal("integration-test-pid")
                expect(msg.topic).to_equal("integration_stream_test")

                if msg.data.type == "chunk" then
                    content_count = content_count + 1
                    complete_text = complete_text .. (msg.data.content or "")
                end
            end

            -- Should have at least one content message
            expect(content_count > 0).to_be_true("Should have received content messages")

            -- Verify the response contains actual content
            expect(#response.result > 10).to_be_true("Response should have meaningful content")

            -- Check for multiple paragraphs or bullet points in general, without specific formatting expectations
            local has_structured_content = false
            if response.result:find("\n") or response.result:find("•") or response.result:find("-") or response.result:find("%d%.") then
                has_structured_content = true
            end
            expect(has_structured_content).to_be_true(
                "Response should contain structured content (paragraphs or bullet points)")

            -- Final response from handler should match assembled content from stream
            expect(response.result).to_equal(complete_text)
        end)


        it("should handle streaming text generation with mocked client", function()
            -- Set up process.send mock to capture streamed responses
            local received_messages = {}
            mock(process, "send", function(pid, topic, data)
                table.insert(received_messages, { pid = pid, topic = topic, data = data })
            end)

            -- Mock the process_stream function
            mock(claude_client, "process_stream", function(stream_response, callbacks)
                -- Call the callbacks in sequence to simulate streaming
                callbacks.on_content("Hello")
                callbacks.on_content(", ")
                callbacks.on_content("world!")

                -- Return the full content
                return "Hello, world!", nil, {
                    content = "Hello, world!",
                    finish_reason = "end_turn",
                    usage = {
                        input_tokens = 25,
                        output_tokens = 15
                    }
                }
            end)

            -- Mock the request function to return a streamable response
            mock(claude_client, "request", function(endpoint_path, payload, options)
                -- Validate the request has streaming enabled
                expect(options.stream).to_be_true("Stream option should be enabled")

                -- Return a mock streaming response
                return {
                    status_code = 200,
                    stream = {}, -- Just needs to exist
                    headers = {
                        ["x-request-id"] = "req_streamtest123",
                        ["processing-ms"] = "200"
                    },
                    metadata = {
                        request_id = "req_streamtest123",
                        processing_ms = 200
                    }
                }
            end)

            -- Create proper prompt using the prompt builder
            local promptBuilder = prompt.new()
            promptBuilder:add_user("Tell me a greeting")

            -- Call with streaming enabled
            local response = text_generation.handler({
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages(),
                stream = {
                    reply_to = "test-process-id",
                    topic = "test_stream"
                }
            })

            -- Verify the response structure for streaming
            expect(response.error).to_be_nil("Expected no error")
            expect(response.streaming).to_be_true("Response should indicate streaming")
            expect(response.result).to_equal("Hello, world!")

            -- Check for content messages
            local content_count = 0

            for _, msg in ipairs(received_messages) do
                expect(msg.pid).to_equal("test-process-id")
                expect(msg.topic).to_equal("test_stream")

                if msg.data.type == "chunk" then
                    content_count = content_count + 1
                end
            end

            expect(content_count > 0).to_be_true("Should have content messages")
        end)

        it("should respect system prompts when generating responses", function()
            -- Skip test if integration tests are disabled
            if not RUN_INTEGRATION_TESTS then
                print("Skipping system prompt integration test - not enabled")
                return
            end

            -- Create a prompt with system and user messages
            local promptBuilder = prompt.new()
            promptBuilder:add_system(
                "You must respond in the style of a pirate captain. Use pirate language, sayings like 'Arrr' and 'Ahoy', and talk about the sea.")
            promptBuilder:add_user("Tell me about coding best practices")

            -- Make the real API call
            local response = text_generation.handler({
                model = "claude-3-5-haiku-20241022",
                messages = promptBuilder:get_messages(),
                options = {
                    temperature = 0, -- Deterministic output
                    max_tokens = 150 -- Moderate response size
                },
                api_key = actual_api_key
            })

            -- Verify response
            expect(response.error).to_be_nil("API request failed")
            expect(response.result).not_to_be_nil("No response received from API")

            -- Check for pirate language markers in the response
            local pirate_markers = { "arr", "ahoy", "matey", "sea", "ship", "pirate", "captain" }
            local has_pirate_language = false
            for _, marker in ipairs(pirate_markers) do
                if string.find(string.lower(response.result), marker) then
                    has_pirate_language = true
                    break
                end
            end

            expect(has_pirate_language).to_be_true(
                "Response doesn't contain pirate language as instructed by system message: " .. response.result)

            -- Print response for manual verification
            print("System prompt test response: " .. string.sub(response.result, 1, 100) .. "...")
        end)

        it("should handle cache control with real API", function()
            -- Skip if not running integration tests
            if not RUN_INTEGRATION_TESTS then
                print("Skipping integration test - not enabled")
                return
            end

            -- Get current timestamp to ensure uniqueness in this cache test run
            local timestamp = tostring(time.now():unix())
            print("Current test timestamp: " .. timestamp)

            -- Create a large system prompt with timestamp to exceed the minimum cacheable size
            -- The timestamp ensures we're always creating a new cache
            local large_system_prompt = [[
            Test timestamp: ]] .. timestamp .. [[

            Lua (/ˈluːə/ LOO-ə; from Portuguese: lua [ˈlu(w)ɐ] meaning moon) is a lightweight, high-level, multi-paradigm programming language designed mainly for embedded use in applications. Lua is cross-platform software, since the interpreter of compiled bytecode is written in ANSI C, and Lua has a relatively simple C application programming interface (API) to embed it into applications.

            Lua originated in 1993 as a language for extending software applications to meet the increasing demand for customization at the time. It provided the basic facilities of most procedural programming languages, but more complicated or domain-specific features were not included; rather, it included mechanisms for extending the language, allowing programmers to implement such features.

            Lua was created by Roberto Ierusalimschy, Luiz Henrique de Figueiredo and Waldemar Celes, members of the Computer Graphics Technology Group (Tecgraf) at the Pontifical Catholic University of Rio de Janeiro, in Brazil.

            Lua 1.0 was designed in such a way that its object constructors incorporated the data-description syntax of SOL (hence the name Lua: Sol meaning "Sun" in Portuguese, and Lua meaning "Moon"). Lua syntax for control structures was mostly borrowed from Modula (if, while, repeat/until), but also had taken influence from CLU (multiple assignments and multiple returns from function calls), C++ (variable declaration locality), SNOBOL and AWK (associative arrays).
            Lua semantics have been increasingly influenced by Scheme over time, especially with the introduction of anonymous functions and full lexical scoping. Several features were added in new Lua versions.

            Versions of Lua prior to version 5.0 were released under a license similar to the BSD license. From version 5.0 onwards, Lua has been licensed under the MIT License.

            Lua is commonly described as a "multi-paradigm" language, providing a small set of general features that can be extended to fit different problem types. Lua does not contain explicit support for inheritance, but allows it to be implemented with metatables. Similarly, Lua allows programmers to implement namespaces, classes and other related features using its single table implementation.

            Lua semantics have been increasingly influenced by Scheme over time, especially with the introduction of anonymous functions and full lexical scoping. Several features were added in new Lua versions.

            Versions of Lua prior to version 5.0 were released under a license similar to the BSD license. From version 5.0 onwards, Lua has been licensed under the MIT License.

            Lua is commonly described as a "multi-paradigm" language, providing a small set of general features that can be extended to fit different problem types. Lua does not contain explicit support for inheritance, but allows it to be implemented with metatables. Similarly, Lua allows programmers to implement namespaces, classes and other related features using its single table implementation.

            As a dynamically typed language intended for use as an extension language or scripting language, Lua is compact enough to fit on a variety of host platforms. It supports only a small number of atomic data structures such as Boolean values, numbers (double-precision floating point and 64-bit integers by default) and strings.

            Typical data structures such as arrays, sets, lists and records can be represented using Lua's single native data structure, the table, which is essentially a heterogeneous associative array.

            Lua implements a small set of advanced features such as first-class functions, garbage collection, closures, proper tail calls, coercion (automatic conversion between string and number values at run time), coroutines (cooperative multitasking) and dynamic module loading.

            In general, Lua strives to provide simple, flexible meta-features that can be extended as needed, rather than supply a feature-set specific to one programming paradigm. As a result, the base language is light; the full reference interpreter is only about 247 kB compiled and easily adaptable to a broad range of applications.

            When using Lua for numerical calculations, remember that:
            1. Multiplication is denoted by *
            2. Division is denoted by /
            3. Addition is denoted by +
            4. Subtraction is denoted by -
            5. Exponentiation is denoted by ^

            For any calculation question, provide only the direct answer without explanation. For example, if asked "What's 25 times 32?", respond with exactly "25 × 32 = 800" and nothing else.
            ]]

            print("Large system prompt length: " .. #large_system_prompt)

            -- Create prompt with system message and cache marker
            local promptBuilder = prompt.new()
            promptBuilder:add_system(large_system_prompt)
            -- Add cache marker to indicate caching should be used
            promptBuilder:add_cache_marker() -- Using default marker (no ID needed)
            promptBuilder:add_user("What's 25 times 32?")

            -- First call to create the cache
            local response1 = text_generation.handler({
                model = "claude-3-5-sonnet-latest",
                messages = promptBuilder:get_messages(),
                options = {
                    temperature = 0 -- Deterministic output
                },
                api_key = actual_api_key
            })

            -- Verify response
            expect(response1.error).to_be_nil("API request failed: " ..
                (response1.error_message or "unknown error"))
            expect(response1.result).not_to_be_nil("No response received from API")
            expect(response1.tokens).not_to_be_nil("No token information")

            -- First, check if tokens object exists
            expect(response1.tokens).not_to_be_nil("Tokens object should exist")
            expect(type(response1.tokens)).to_equal("table", "Tokens should be a table")

            -- Verify caching-related fields are present in the token count
            if response1.tokens.cache_creation_input_tokens then
                print("First call successfully created cache with " ..
                    response1.tokens.cache_creation_input_tokens .. " tokens")
                expect(response1.tokens.cache_creation_input_tokens > 0).to_be_true(
                    "Expected non-zero cache creation tokens"
                )
            else
                print("Warning: No cache_creation_input_tokens in response")
            end

            -- Wait to ensure cache is available
            time.sleep("2s")

            -- Second call with the same prompt and cache marker - should use cache
            -- We need to create a new prompt builder with the same content
            local promptBuilder2 = prompt.new()
            promptBuilder2:add_system(large_system_prompt)
            promptBuilder2:add_cache_marker() -- Same default cache marker
            promptBuilder2:add_user("What's 25 times 32?")

            local response2 = text_generation.handler({
                model = "claude-3-5-sonnet-latest",
                messages = promptBuilder2:get_messages(),
                options = {
                    temperature = 0 -- Deterministic output
                },
                api_key = actual_api_key
            })

            -- Verify response
            expect(response2.error).to_be_nil("API request failed: " ..
                (response2.error_message or "unknown error"))
            expect(response2.result).not_to_be_nil("No response received from API")
            expect(response2.tokens).not_to_be_nil("No token information")

            -- First, check if tokens object exists
            expect(response2.tokens).not_to_be_nil("Tokens object should exist")
            expect(type(response2.tokens)).to_equal("table", "Tokens should be a table")

            -- Verify cache hit occurred
            if response2.tokens.cache_read_input_tokens then
                print("Second call successfully read from cache: " ..
                    response2.tokens.cache_read_input_tokens .. " tokens")
                expect(response2.tokens.cache_read_input_tokens > 0).to_be_true(
                    "Expected non-zero cache read tokens"
                )
            else
                print("Warning: No cache_read_input_tokens in response, cache hit may not have occurred")
            end

            -- Verify cache creation not needed for second call
            expect(response2.tokens.cache_creation_input_tokens or 0).to_equal(0,
                "Second call should not create new cache"
            )

            -- Print full token information for both calls
            print("First call token info:")
            print(string.format("  Prompt tokens: %d", response1.tokens.prompt_tokens or 0))
            print(string.format("  Completion tokens: %d", response1.tokens.completion_tokens or 0))
            print(string.format("  Total tokens: %d", response1.tokens.total_tokens or 0))
            print(string.format("  Cache creation tokens: %d", response1.tokens.cache_creation_input_tokens or 0))
            print(string.format("  Cache read tokens: %d", response1.tokens.cache_read_input_tokens or 0))

            print("Second call token info:")
            print(string.format("  Prompt tokens: %d", response2.tokens.prompt_tokens or 0))
            print(string.format("  Completion tokens: %d", response2.tokens.completion_tokens or 0))
            print(string.format("  Total tokens: %d", response2.tokens.total_tokens or 0))
            print(string.format("  Cache creation tokens: %d", response2.tokens.cache_creation_input_tokens or 0))
            print(string.format("  Cache read tokens: %d", response2.tokens.cache_read_input_tokens or 0))

            -- Instead of exact string match, check that both responses contain "800"
            -- which is the correct answer for 25 * 32
            expect(response1.result:find("800")).not_to_be_nil("First response should include the correct answer (800)")
            expect(response2.result:find("800")).not_to_be_nil("Second response should include the correct answer (800)")

            -- Verify cache tokens behave as expected
            if response1.tokens.cache_creation_input_tokens then
                expect(response1.tokens.cache_creation_input_tokens > 0).to_be_true(
                    "First call should create cache with non-zero tokens")
            else
                print("WARNING: First call cache_creation_input_tokens is nil")
            end

            if response2.tokens.cache_read_input_tokens then
                expect(response2.tokens.cache_read_input_tokens > 0).to_be_true(
                    "Second call should read from cache with non-zero tokens")
            else
                print("WARNING: Second call cache_read_input_tokens is nil")
            end
        end)

        it("should stream thinking content with real API", function()
            -- Skip if not running integration tests
            if not RUN_INTEGRATION_TESTS then
                print("Skipping integration test - not enabled")
                return
            end

            -- Skip test if using unsuitable model
            local model = "claude-3-7-sonnet-20250219" -- Only 3.7 models support thinking
            print("Running thinking streaming test with " .. model)

            -- Set up process.send mock to capture streamed responses
            local received_messages = {}
            mock(process, "send", function(pid, topic, data)
                table.insert(received_messages, { pid = pid, topic = topic, data = data })
                if data.type then
                    print("Received stream message: " .. data.type) -- Print for debugging
                end
            end)

            -- Create prompt for a reasoning task
            local promptBuilder = prompt.new()
            promptBuilder:add_user(
                "Solve this step by step: If 5 workers can build a wall in 8 days, how many workers would be needed to build the same wall in 2 days? Show your reasoning.")

            -- Call with streaming and thinking enabled
            local response = text_generation.handler({
                model = model,
                messages = promptBuilder:get_messages(),
                options = {
                    thinking_effort = 1,
                    temperature = 0
                },
                api_key = actual_api_key,
                stream = {
                    reply_to = "thinking-stream-test-pid",
                    topic = "thinking_stream_test",
                    buffer_size = 10 -- Small buffer to ensure multiple chunks
                }
            })

            -- Verify the response structure for streaming
            expect(response.error).to_be_nil("API request failed: " ..
                (response.error_message or "unknown error"))
            expect(response.streaming).to_be_true("Response should indicate streaming")
            expect(response.result).not_to_be_nil("Should have complete response content")

            -- Verify thinking content is in final response
            if not response.thinking or #response.thinking == 0 then
                print("WARNING: No thinking content in final response - model may not support thinking")
            else
                print("Thinking content length: " .. #response.thinking)
                expect(#response.thinking > 0).to_be_true("Expected non-empty thinking content")
            end

            -- Verify streamed messages - should have at least some
            expect(#received_messages > 0).to_be_true("Should have received stream messages")

            -- Track message types
            local content_count = 0
            local thinking_count = 0

            for _, msg in ipairs(received_messages) do
                expect(msg.pid).to_equal("thinking-stream-test-pid")
                expect(msg.topic).to_equal("thinking_stream_test")

                if msg.data.type == "chunk" then
                    content_count = content_count + 1
                elseif msg.data.type == "thinking" then
                    thinking_count = thinking_count + 1
                end
            end

            -- Should have at least some content messages
            expect(content_count > 0).to_be_true("Should have received content messages")

            -- May have thinking messages if model supports it
            if thinking_count == 0 then
                print("WARNING: No thinking messages received - model may not support thinking or has changed")
            else
                print("Received " .. thinking_count .. " thinking messages")
            end

            -- Verify the response contains the correct numerical answer (20 workers)
            expect(response.result:match("20")).not_to_be_nil("Response should contain the correct answer (20 workers)")
        end)
    end)
end

return require("test").run_cases(define_tests)
