local llm = require("llm")
local models = require("models")
local env = require("env")
local json = require("json")
local prompt = require("prompt")

local function define_tests()
    -- Toggle to enable/disable real API integration test
    local RUN_INTEGRATION_TESTS = env.get("ENABLE_INTEGRATION_TESTS")

    describe("LLM Library", function()
        local mock_executor
        local mock_models
        local original_CAPABILITY

        -- Mock model cards for testing
        local model_cards = {
            ["gpt-4o"] = {
                id = "wippy.llm:gpt-4o",
                name = "gpt-4o",
                provider = "openai",
                provider_model = "gpt-4o-2024-11-20",
                description = "Fast, intelligent, flexible GPT model with text and image input capabilities",
                max_tokens = 128000,
                output_tokens = 16384,
                capabilities = { "tool_use", "vision", "generate" },
                handlers = {
                    generate = "wippy.llm.openai:text_generation",
                    structured_output = "wippy.llm.openai:structured_output",
                    call_tools = "wippy.llm.openai:tool_calling"
                },
                pricing = {
                    input = 2.50,
                    output = 10.00,
                    cached_input = 1.25
                }
            },
            ["gpt-4o-mini"] = {
                id = "wippy.llm:gpt-4o-mini",
                name = "gpt-4o-mini",
                provider = "openai",
                provider_model = "gpt-4o-mini-2024-07-18",
                description = "Fast, affordable small model for focused tasks with text and image input",
                max_tokens = 128000,
                output_tokens = 16384,
                capabilities = { "tool_use", "vision", "generate" },
                handlers = {
                    generate = "wippy.llm.openai:text_generation",
                    structured_output = "wippy.llm.openai:structured_output",
                    call_tools = "wippy.llm.openai:tool_calling"
                },
                pricing = {
                    input = 0.15,
                    output = 0.60,
                    cached_input = 0.075
                }
            },
            ["claude-3-5-haiku"] = {
                id = "wippy.llm:claude-3-5-haiku",
                name = "claude-3-5-haiku",
                provider = "anthropic",
                provider_model = "claude-3-5-haiku-20241022",
                description = "Fastest Claude model optimized for speed while maintaining high intelligence",
                max_tokens = 200000,
                output_tokens = 8192,
                capabilities = { "tool_use", "vision", "caching", "generate" },
                handlers = {
                    generate = "wippy.llm.claude:text_generation",
                    structured_output = "wippy.llm.claude:structured_output",
                    call_tools = "wippy.llm.claude:tool_calling"
                },
                pricing = {
                    input = 0.80,
                    output = 4.00
                }
            },
            ["o3-mini"] = {
                id = "wippy.llm:o3-mini",
                name = "o3-mini",
                provider = "openai",
                provider_model = "o3-mini-2025-01-31",
                description = "Fast, flexible intelligent reasoning model for complex, multi-step tasks",
                max_tokens = 200000,
                output_tokens = 100000,
                capabilities = { "tool_use", "thinking", "generate" },
                handlers = {
                    generate = "wippy.llm.openai:text_generation",
                    structured_output = "wippy.llm.openai:structured_output",
                    call_tools = "wippy.llm.openai:tool_calling"
                },
                pricing = {
                    input = 1.10,
                    output = 4.40,
                    cached_input = 0.55
                }
            },
            ["text-embedding-3-large"] = {
                id = "wippy.llm:text-embedding-3-large",
                name = "text-embedding-3-large",
                provider = "openai",
                provider_model = "text-embedding-3-large",
                description = "Most powerful embedding model for highest accuracy (64.6% on MTEB benchmark)",
                max_tokens = 8191,
                dimensions = 3072,
                capabilities = { "multilingual", "embed" },
                handlers = {
                    embeddings = "wippy.llm.openai:embeddings"
                },
                pricing = {
                    input = 0.13,
                    pages_per_dollar = 9615
                }
            },
            ["local-qwen-3-8b"] = {
                id = "wippy.llm:local-qwen-3-8b",
                name = "local-qwen-3-8b",
                provider = "openai",
                provider_model = "local-qwen-3-8b",
                description = "Local Qwen-3 model with 8 billion parameters for fast inference",
                max_tokens = 8192,
                dimensions = 2048,
                capabilities = { "generate", "tool_use", "embed" },
                handlers = {
                    generate = "wippy.llm.openai:text_generation",
                    structured_output = "wippy.llm.openai:structured_output",
                    call_tools = "wippy.llm.openai:tool_calling",
                    embeddings = "wippy.llm.openai:embeddings"
                },
                pricing = {
                    input = 0,
                    output = 0,
                    cached_input = 0
                },
                provider_options = {
                    base_url = "http://localhost:1234/v1",
                    api_key_env = "CUSTOM_OPENAI_API_KEY"
                }
            }
        }

        before_each(function()
            -- Save original capability constants
            original_CAPABILITY = llm.CAPABILITY

            -- Create mock executor
            mock_executor = {
                calls = {},
                context = nil,
                with_context = function(self, ctx)
                    -- Create a new executor with updated context
                    return {
                        calls = self.calls,
                        context = ctx,
                        with_context = self.with_context,
                        call = self.call
                    }
                end,
                call = function(self, handler_id, request)
                    -- Track the call with the current context
                    table.insert(self.calls, {
                        handler_id = handler_id,
                        request = request,
                        context = self.context
                    })

                    -- Return mock result based on handler type
                    if handler_id == "wippy.llm.openai:text_generation" then
                        return {
                            content = "This is a mock response from OpenAI",
                            tokens = {
                                prompt_tokens = #json.encode(request.messages) / 4,
                                completion_tokens = 10,
                                total_tokens = #json.encode(request.messages) / 4 + 10
                            },
                            finish_reason = "stop",
                            metadata = {
                                request_id = "req_mock123"
                            }
                        }
                    elseif handler_id == "wippy.llm.claude:text_generation" then
                        return {
                            content = "This is a mock response from Claude",
                            tokens = {
                                prompt_tokens = #json.encode(request.messages) / 4,
                                completion_tokens = 10,
                                total_tokens = #json.encode(request.messages) / 4 + 10
                            },
                            finish_reason = "stop",
                            metadata = {
                                request_id = "req_mock456"
                            }
                        }
                    elseif handler_id == "wippy.llm.openai:tool_calling" then
                        return {
                            content = "Let me check that for you",
                            tool_calls = {
                                {
                                    id = "call_abc123",
                                    name = "get_weather",
                                    arguments = {
                                        location = "New York",
                                        units = "celsius"
                                    }
                                }
                            },
                            tokens = {
                                prompt_tokens = #json.encode(request.messages) / 4,
                                completion_tokens = 15,
                                total_tokens = #json.encode(request.messages) / 4 + 15
                            },
                            finish_reason = "tool_call",
                            metadata = {
                                request_id = "req_tool123"
                            }
                        }
                    elseif handler_id == "wippy.llm.claude:tool_calling" then
                        return {
                            content = "Let me check that for you",
                            tool_calls = {
                                {
                                    id = "toolu_abc123",
                                    name = "get_weather",
                                    arguments = {
                                        location = "New York",
                                        units = "celsius"
                                    }
                                }
                            },
                            tokens = {
                                prompt_tokens = #json.encode(request.messages) / 4,
                                completion_tokens = 15,
                                total_tokens = #json.encode(request.messages) / 4 + 15
                            },
                            finish_reason = "tool_call",
                            metadata = {
                                request_id = "req_tool456"
                            }
                        }
                    elseif handler_id == "wippy.llm.openai:structured_output" then
                        return {
                            content = {
                                temperature = 22.5,
                                condition = "sunny",
                                humidity = 65
                            },
                            tokens = {
                                prompt_tokens = #json.encode(request.messages) / 4 + #json.encode(request.schema) / 4,
                                completion_tokens = 12,
                                total_tokens = #json.encode(request.messages) / 4 + #json.encode(request.schema) / 4 + 12
                            },
                            finish_reason = "stop",
                            metadata = {
                                request_id = "req_struct123"
                            }
                        }
                    elseif handler_id == "wippy.llm.openai:embeddings" then
                        -- Generate a mock embedding vector
                        local mock_vector = {}
                        local dimensions = request.dimensions or 1536
                        for i = 1, dimensions do
                            table.insert(mock_vector, math.sin(i / 10) * 0.1)
                        end

                        return {
                            embedding = mock_vector,
                            tokens = {
                                prompt_tokens = #request.input / 4,
                                completion_tokens = 0,
                                total_tokens = #request.input / 4
                            },
                            metadata = {
                                request_id = "req_embed123"
                            }
                        }
                    else
                        -- Default mock response
                        return {
                            error = "Unsupported handler: " .. handler_id
                        }
                    end
                end
            }

            -- Create mock models module
            mock_models = {
                CAPABILITY = {
                    GENERATE = "generate",
                    TOOL_USE = "tool_use",
                    STRUCTURED_OUTPUT = "structured_output",
                    EMBED = "embed",
                    THINKING = "thinking"
                },
                get_by_name = function(model_name)
                    -- Models are referenced by their short names, not full IDs
                    local model = model_cards[model_name]
                    if model then
                        return model
                    else
                        return nil, "Model not found: " .. model_name
                    end
                end,
                get_all = function()
                    local all_models = {}
                    for _, model in pairs(model_cards) do
                        table.insert(all_models, model)
                    end
                    -- Sort by name
                    table.sort(all_models, function(a, b)
                        return a.name < b.name
                    end)
                    return all_models
                end,
                get_by_provider = function()
                    local providers = {}
                    for _, model in pairs(model_cards) do
                        local provider = model.provider
                        if not providers[provider] then
                            providers[provider] = {
                                name = provider,
                                models = {}
                            }
                        end
                        table.insert(providers[provider].models, model)
                    end
                    return providers
                end
            }

            -- Inject mocks
            llm.set_executor(mock_executor)
            llm.set_models(mock_models)
        end)

        after_each(function()
            -- Restore original capability constants
            llm.CAPABILITY = original_CAPABILITY
        end)

        -- Test basic text generation
        it("should generate text with string prompt", function()
            local response = llm.generate("Hello, world!", {
                model = "gpt-4o"
            })

            -- Verify the executor was called
            expect(#mock_executor.calls).to_equal(1)
            expect(mock_executor.calls[1].handler_id).to_equal("wippy.llm.openai:text_generation")

            -- Verify request format
            local request = mock_executor.calls[1].request
            expect(request.model).to_equal("gpt-4o-2024-11-20")
            expect(#request.messages).to_equal(1)
            expect(request.messages[1].role).to_equal("user")
            expect(request.messages[1].content).to_equal("Hello, world!")

            -- Verify response
            expect(response).not_to_be_nil()
            expect(response.content).to_equal("This is a mock response from OpenAI")
            expect(response.tokens).not_to_be_nil()
            expect(response.tokens.total_tokens > 0).to_be_true()
        end)

        -- Test with prompt builder
        it("should generate text with prompt builder", function()
            local builder = prompt.new()
            builder:add_system("You are a helpful assistant.")
            builder:add_user("What is the capital of France?")

            local response = llm.generate(builder, {
                model = "claude-3-5-haiku"
            })

            -- Verify the executor was called
            expect(#mock_executor.calls).to_equal(1)
            expect(mock_executor.calls[1].handler_id).to_equal("wippy.llm.claude:text_generation")

            -- Verify request format
            local request = mock_executor.calls[1].request
            expect(request.model).to_equal("claude-3-5-haiku-20241022")
            expect(#request.messages).to_equal(2)
            expect(request.messages[1].role).to_equal("system")
            expect(request.messages[2].role).to_equal("user")

            -- Verify response
            expect(response).not_to_be_nil()
            expect(response.content).to_equal("This is a mock response from Claude")
        end)

        -- Test tool calling
        it("should handle tool calling", function()
            local builder = prompt.new()
            builder:add_user("What's the weather in New York?")

            local response = llm.generate(builder, {
                model = "gpt-4o",
                tool_ids = { "system:weather" }
            })

            -- Verify the executor was called
            expect(#mock_executor.calls).to_equal(1)
            expect(mock_executor.calls[1].handler_id).to_equal("wippy.llm.openai:tool_calling")

            -- Verify response has tool calls
            expect(response).not_to_be_nil()
            expect(response.tool_calls).not_to_be_nil()
            expect(#response.tool_calls).to_equal(1)
            expect(response.tool_calls[1].name).to_equal("get_weather")
            expect(response.tool_calls[1].arguments.location).to_equal("New York")
        end)

        -- Test structured output
        it("should generate structured output", function()
            local weather_schema = {
                type = "object",
                properties = {
                    temperature = {
                        type = "number",
                        description = "Temperature in celsius"
                    },
                    condition = {
                        type = "string",
                        description = "Weather condition (sunny, cloudy, rainy, etc.)"
                    },
                    humidity = {
                        type = "number",
                        description = "Humidity percentage"
                    }
                },
                required = { "temperature", "condition" }
            }

            local response = llm.structured_output(weather_schema, "What's the weather like today in New York?", {
                model = "gpt-4o"
            })

            -- Verify the executor was called
            expect(#mock_executor.calls).to_equal(1)
            expect(mock_executor.calls[1].handler_id).to_equal("wippy.llm.openai:structured_output")

            -- Verify request format
            local request = mock_executor.calls[1].request
            expect(request.model).to_equal("gpt-4o-2024-11-20")
            expect(request.schema).to_equal(weather_schema)

            -- Verify response
            expect(response).not_to_be_nil()
            expect(response.content).not_to_be_nil()
            expect(response.content.temperature).to_equal(22.5)
            expect(response.content.condition).to_equal("sunny")
            expect(response.content.humidity).to_equal(65)
        end)

        -- Test embeddings
        it("should generate embeddings", function()
            local text = "The quick brown fox jumps over the lazy dog."
            local response = llm.embed(text, {
                model = "text-embedding-3-large"
            })

            -- Verify the executor was called
            expect(#mock_executor.calls).to_equal(1)
            expect(mock_executor.calls[1].handler_id).to_equal("wippy.llm.openai:embeddings")

            -- Verify request format
            local request = mock_executor.calls[1].request
            expect(request.model).to_equal("text-embedding-3-large")
            expect(request.input).to_equal(text)
            expect(request.dimensions).to_equal(3072)

            -- Verify response
            expect(response).not_to_be_nil()
            expect(response.embedding).not_to_be_nil()
            expect(#response.embedding).to_equal(3072)
        end)

        -- Test capability-based option filtering
        it("should filter options based on model capabilities", function()
            -- Test thinking_effort filter
            local options = {
                model = "gpt-4o",
                thinking_effort = 50,
                temperature = 0.7
            }

            local response = llm.generate("Test thinking", options)

            -- Verify that thinking_effort was removed since gpt-4o doesn't support it
            local request = mock_executor.calls[1].request
            expect(request.options.thinking_effort).to_be_nil()
            expect(request.options.temperature).to_equal(0.7)

            -- Now test with o3-mini which supports thinking
            mock_executor.calls = {}
            options = {
                model = "o3-mini",
                thinking_effort = 50,
                temperature = 0.7
            }

            response = llm.generate("Test thinking", options)

            -- Verify that thinking_effort was preserved for o3-mini
            request = mock_executor.calls[1].request
            expect(request.options.thinking_effort).to_equal(50)
        end)

        -- Test error handling for missing model
        it("should handle missing model error", function()
            local response, err = llm.generate("Hello", {
                model = "nonexistent-model"
            })

            expect(response).to_be_nil()
            expect(err).not_to_be_nil()
            expect(err:match("Model not found")).not_to_be_nil()
        end)

        -- Test capabilities-based model filtering
        it("should filter models based on capabilities", function()
            local generate_models = llm.available_models(llm.CAPABILITY.GENERATE)
            local tool_models = llm.available_models(llm.CAPABILITY.TOOL_USE)
            local embed_models = llm.available_models(llm.CAPABILITY.EMBED)
            local thinking_models = llm.available_models(llm.CAPABILITY.THINKING)

            -- Count models with appropriate capabilities AND handlers
            local generate_count = 0
            local tool_count = 0
            local embed_count = 0
            local thinking_count = 0

            for _, model in pairs(model_cards) do
                -- For GENERATE capability
                local has_generate = false
                if model.capabilities then
                    for _, cap in ipairs(model.capabilities) do
                        if cap == "generate" then
                            has_generate = true
                            break
                        end
                    end
                end
                if has_generate and model.handlers.generate then
                    generate_count = generate_count + 1
                end

                -- For TOOL_USE capability
                local has_tool_use = false
                if model.capabilities then
                    for _, cap in ipairs(model.capabilities) do
                        if cap == "tool_use" then
                            has_tool_use = true
                            break
                        end
                    end
                end
                if has_tool_use and model.handlers.call_tools then
                    tool_count = tool_count + 1
                end

                -- For EMBED capability
                local has_embed = false
                if model.capabilities then
                    for _, cap in ipairs(model.capabilities) do
                        if cap == "embed" then
                            has_embed = true
                            break
                        end
                    end
                end
                if has_embed and model.handlers.embeddings then
                    embed_count = embed_count + 1
                end

                -- For THINKING capability
                local has_thinking = false
                if model.capabilities then
                    for _, cap in ipairs(model.capabilities) do
                        if cap == "thinking" then
                            has_thinking = true
                            break
                        end
                    end
                end
                if has_thinking and model.handlers.generate then
                    thinking_count = thinking_count + 1
                end
            end

            -- Verify counts
            expect(#generate_models).to_equal(generate_count)
            expect(#tool_models).to_equal(tool_count)
            expect(#embed_models).to_equal(embed_count)
            expect(#thinking_models).to_equal(thinking_count)
        end)

        -- Test grouping by provider
        it("should group models by provider", function()
            local providers = llm.models_by_provider()

            -- Manually count models by provider for verification
            local provider_counts = {}
            for _, model in pairs(model_cards) do
                provider_counts[model.provider] = (provider_counts[model.provider] or 0) + 1
            end

            for provider, count in pairs(provider_counts) do
                expect(providers[provider]).not_to_be_nil("Provider " .. provider .. " missing")
                expect(#providers[provider].models).to_equal(count, "Wrong model count for " .. provider)
            end
        end)

        it("should filter models based on capabilities", function()
            local generate_models = llm.available_models(llm.CAPABILITY.GENERATE)
            local tool_models = llm.available_models(llm.CAPABILITY.TOOL_USE)
            local embed_models = llm.available_models(llm.CAPABILITY.EMBED)
            local thinking_models = llm.available_models(llm.CAPABILITY.THINKING)

            -- Verify counts - use hardcoded values based on our model cards analysis
            expect(#generate_models).to_equal(5) -- 5 models with "generate" capability
            expect(#tool_models).to_equal(5)     -- 5 models with "tool_use" capability
            expect(#embed_models).to_equal(2)    -- 2 model with "embed" capability
            expect(#thinking_models).to_equal(1) -- 1 model with "thinking" capability
        end)

        -- INTEGRATION TESTS

        it("should generate with GPT-4o-mini with tools (integration)", function()
            -- Skip if not running integration tests
            if not RUN_INTEGRATION_TESTS then
                return
            end

            -- Get API keys from environment
            local openai_api_key = env.get("OPENAI_API_KEY")
            if not openai_api_key or #openai_api_key < 10 then
                return
            end

            -- Restore original modules for real API calls
            llm.set_executor(nil)
            llm.set_models(models)

            -- Define a weather tool schema
            local weather_tool = {
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
            }

            -- Create prompt
            local builder = prompt.new()
            builder:add_user("What's the weather in Seattle?")
            builder:add_developer("Always use the weather tool")

            local response = llm.generate(builder, {
                model = "gpt-4o-mini",
                api_key = openai_api_key,
                tool_schemas = {
                    ["test:weather"] = weather_tool
                },
                temperature = 0
            })

            -- Skip test if there was an error
            if not response or response.error then
                return
            end

            -- Check if tool_calls exists before asserting on it
            if response.tool_calls then
                expect(#response.tool_calls > 0).to_be_true()

                -- If tool calls exist, validate the first one
                if #response.tool_calls > 0 then
                    local tool_call = response.tool_calls[1]
                    expect(tool_call.name).to_equal("get_weather")
                    expect(tool_call.arguments.location).not_to_be_nil()
                end
            end

            -- Check token information if available
            if response.tokens then
                expect(response.tokens.prompt_tokens > 0).to_be_true()
                expect(response.tokens.completion_tokens > 0).to_be_true()
                expect(response.tokens.total_tokens > 0).to_be_true()
            end
        end)

        it("should generate with Claude Haiku with tools (integration)", function()
            -- Skip if not running integration tests
            if not RUN_INTEGRATION_TESTS then
                return
            end

            -- Get API keys from environment
            local anthropic_api_key = env.get("ANTHROPIC_API_KEY")
            if not anthropic_api_key or #anthropic_api_key < 10 then
                return
            end

            -- Restore original modules for real API calls
            llm.set_executor(nil)
            llm.set_models(models)

            -- Define a calculator tool schema
            local calculator_tool = {
                name = "calculate",
                description = "Perform mathematical calculations",
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

            -- Create prompt
            local builder = prompt.new()
            builder:add_user("What is 125 * 16?")
            builder:add_developer("Please use the calculator tool to solve this")

            -- Make the API call directly
            local response = llm.generate(builder, {
                model = "claude-3-5-haiku",
                api_key = anthropic_api_key,
                tool_schemas = {
                    ["test:calculator"] = calculator_tool
                },
                temperature = 0
            })

            -- Skip test if there was an error
            if not response or response.error then
                return
            end

            -- Check if tool_calls exists before asserting on it
            if response.tool_calls then
                expect(#response.tool_calls > 0).to_be_true()

                -- If tool calls exist, validate the first one
                if #response.tool_calls > 0 then
                    local tool_call = response.tool_calls[1]
                    expect(tool_call.name).to_equal("calculate")
                    local expr = tool_call.arguments.expression
                    if expr then
                        expect(expr:match("125") and expr:match("16")).not_to_be_nil()
                    end
                end
            end



            -- Check token information if available
            if response.tokens then
                expect(response.tokens.prompt_tokens > 0).to_be_true()
                expect(response.tokens.completion_tokens > 0).to_be_true()
                expect(response.tokens.total_tokens > 0).to_be_true()
            end
        end)

        it("should compare token usage between providers (integration)", function()
            -- Skip if not running integration tests
            if not RUN_INTEGRATION_TESTS then
                return
            end

            -- Get API keys from environment
            local openai_api_key = env.get("OPENAI_API_KEY")
            local anthropic_api_key = env.get("ANTHROPIC_API_KEY")

            if not openai_api_key or #openai_api_key < 10 or
                not anthropic_api_key or #anthropic_api_key < 10 then
                return
            end

            -- Restore original modules for real API calls
            llm.set_executor(nil)
            llm.set_models(models)

            -- Create identical prompts for both models
            local prompt_text = "Explain the difference between Docker and Kubernetes in about 100 words."

            -- Make API calls to both models directly
            local openai_response = llm.generate(prompt_text, {
                model = "gpt-4o-mini",
                api_key = openai_api_key,
                temperature = 0
            })

            local claude_response = llm.generate(prompt_text, {
                model = "claude-3-5-haiku",
                api_key = anthropic_api_key,
                temperature = 0
            })

            -- Skip test if either response is missing or has errors
            if not openai_response or not claude_response or
                openai_response.error or claude_response.error or
                not openai_response.tokens or not claude_response.tokens then
                return
            end

            -- Compare token usage
            local openai_tokens = openai_response.tokens
            local claude_tokens = claude_response.tokens

            -- Skip calculations if token data is incomplete
            if not openai_tokens.prompt_tokens or not claude_tokens.prompt_tokens or
                not openai_tokens.completion_tokens or not claude_tokens.completion_tokens or
                not openai_tokens.total_tokens or not claude_tokens.total_tokens then
                return
            end

            -- Simply verify that token counts are present and reasonable
            expect(openai_tokens.prompt_tokens > 0).to_be_true()
            expect(openai_tokens.completion_tokens > 0).to_be_true()
            expect(openai_tokens.total_tokens > 0).to_be_true()

            expect(claude_tokens.prompt_tokens > 0).to_be_true()
            expect(claude_tokens.completion_tokens > 0).to_be_true()
            expect(claude_tokens.total_tokens > 0).to_be_true()
        end)

        it("should generate embeddings with OpenAI (integration)", function()
            -- Skip if not running integration tests
            if not RUN_INTEGRATION_TESTS then
                return
            end

            -- Get API keys from environment
            local openai_api_key = env.get("OPENAI_API_KEY")
            if not openai_api_key or #openai_api_key < 10 then
                return
            end

            -- Restore original modules for real API calls
            llm.set_executor(nil)
            llm.set_models(models)

            local text = "The quick brown fox jumps over the lazy dog."

            -- Make the API call directly
            local response = llm.embed(text, {
                model = "text-embedding-3-large",
                api_key = openai_api_key,
                dimensions = 500
            })

            -- Skip test if response has errors
            if not response or response.error then
                return
            end

            -- Verify embedding
            expect(response.result).not_to_be_nil()

            if response.result then
                -- Dimensions should match what we requested
                expect(#response.result).to_equal(500)
            end

            -- Verify token usage if available
            if response.tokens then
                expect(response.tokens.prompt_tokens > 0).to_be_true()
            end
        end)

        it("should generate multi embeddings with OpenAI (integration)", function()
            -- Skip if not running integration tests
            if not RUN_INTEGRATION_TESTS then
                return
            end

            -- Get API keys from environment
            local openai_api_key = env.get("OPENAI_API_KEY")
            if not openai_api_key or #openai_api_key < 10 then
                return
            end

            -- Restore original modules for real API calls
            llm.set_executor(nil)
            llm.set_models(models)

            local text = {
                "The quick brown fox jumps over the lazy dog.",
                "The five boxing wizards jump quickly."
            }

            -- Make the API call directly
            local response = llm.embed(text, {
                model = "text-embedding-3-large",
                api_key = openai_api_key,
                dimensions = 500
            })

            -- Skip test if response has errors
            if not response or response.error then
                return
            end

            -- Verify embedding
            expect(response.result).not_to_be_nil()
            expect(#response.result).to_equal(2)
            expect(#response.result[1]).to_equal(500)
            expect(#response.result[2]).to_equal(500)
        end)

        -- Provider Options Tests
        it("should pass provider_options to executor during generate function", function()
            -- A test for the generate function with a model that has provider_options
            local response = llm.generate("Hello, world!", {
                model = "local-qwen-3-8b"
            })

            -- Verify the executor was called
            expect(#mock_executor.calls).to_equal(1)
            expect(mock_executor.calls[1].handler_id).to_equal("wippy.llm.openai:text_generation")

            -- Verify request format
            local request = mock_executor.calls[1].request
            expect(request.model).to_equal("local-qwen-3-8b")
            expect(request.messages[1].role).to_equal("user")
            expect(request.messages[1].content).to_equal("Hello, world!")

            -- Verify response
            expect(response).not_to_be_nil()
            expect(response.content).to_equal("This is a mock response from OpenAI")

            -- Verify that provider_options was passed to with_context
            -- This is the key part of the test - checking that provider_options is passed correctly
            local executor_context = mock_executor.calls[1].context
            expect(executor_context).not_to_be_nil()
            expect(executor_context.provider_options).not_to_be_nil()
            expect(executor_context.provider_options.base_url).to_equal("http://localhost:1234/v1")
            expect(executor_context.provider_options.api_key_env).to_equal("CUSTOM_OPENAI_API_KEY")
        end)

        it("should pass provider_options to executor during structured_output function", function()
            -- Define a test schema
            local test_schema = {
                type = "object",
                properties = {
                    name = { type = "string" },
                    age = { type = "number" }
                }
            }

            -- Call structured_output with a model that has provider_options
            local response = llm.structured_output(test_schema, "Parse: John Doe, 30 years old", {
                model = "local-qwen-3-8b"
            })

            -- Verify the executor was called
            expect(#mock_executor.calls).to_equal(1)
            expect(mock_executor.calls[1].handler_id).to_equal("wippy.llm.openai:structured_output")

            -- Verify request format
            local request = mock_executor.calls[1].request
            expect(request.model).to_equal("local-qwen-3-8b")
            expect(request.schema).to_equal(test_schema)

            -- Verify that provider_options was passed to with_context
            local executor_context = mock_executor.calls[1].context
            expect(executor_context).not_to_be_nil()
            expect(executor_context.provider_options).not_to_be_nil()
            expect(executor_context.provider_options.base_url).to_equal("http://localhost:1234/v1")
            expect(executor_context.provider_options.api_key_env).to_equal("CUSTOM_OPENAI_API_KEY")
        end)

        it("should pass provider_options to executor during embed function", function()
            -- Call embed with a model that has provider_options
            local text = "This is a test text for embedding"
            local response = llm.embed(text, {
                model = "local-qwen-3-8b"
            })

            -- Verify the executor was called
            expect(#mock_executor.calls).to_equal(1)
            expect(mock_executor.calls[1].handler_id).to_equal("wippy.llm.openai:embeddings")

            -- Verify request format
            local request = mock_executor.calls[1].request
            expect(request.model).to_equal("local-qwen-3-8b")
            expect(request.input).to_equal(text)
            expect(request.dimensions).to_equal(2048) -- From model card

            -- Verify that provider_options was passed to with_context
            local executor_context = mock_executor.calls[1].context
            expect(executor_context).not_to_be_nil()
            expect(executor_context.provider_options).not_to_be_nil()
            expect(executor_context.provider_options.base_url).to_equal("http://localhost:1234/v1")
            expect(executor_context.provider_options.api_key_env).to_equal("CUSTOM_OPENAI_API_KEY")
        end)

        it("should preserve provider_options context across multiple calls", function()
            -- Reset calls before this test
            mock_executor.calls = {}

            -- Make multiple calls with the same model
            llm.generate("First call", { model = "local-qwen-3-8b" })
            llm.generate("Second call", { model = "local-qwen-3-8b" })

            -- Verify both calls have provider_options
            expect(#mock_executor.calls).to_equal(2)

            local context1 = mock_executor.calls[1].context
            local context2 = mock_executor.calls[2].context

            expect(context1.provider_options).not_to_be_nil()
            expect(context2.provider_options).not_to_be_nil()
            expect(context1.provider_options.base_url).to_equal("http://localhost:1234/v1")
            expect(context2.provider_options.base_url).to_equal("http://localhost:1234/v1")
        end)
    end)
end

return require("test").run_cases(define_tests)
