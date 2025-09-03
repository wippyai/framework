local llm = require("llm")
local json = require("json")

local function define_tests()
    describe("LLM Library Unit Tests", function()
        local mock_models
        local mock_providers
        local mock_usage_tracker

        before_each(function()
            -- Create mock models module
            mock_models = {
                get_by_name = function(name)
                    if name == "gpt-4o" then
                        return {
                            id = "app.models:gpt-4o",
                            name = "gpt-4o",
                            title = "GPT-4o",
                            capabilities = { "tool_use", "vision", "generate" },
                            classes = { "frontier", "multimodal" },
                            priority = 100,
                            max_tokens = 128000,
                            providers = {
                                {
                                    id = "wippy.llm.openai:provider",
                                    provider_model = "gpt-4o-2024-11-20",
                                    pricing = { input = 2.5, output = 10 },
                                    options = {}
                                }
                            }
                        }
                    elseif name == "claude-4-sonnet" then
                        return {
                            id = "app.models:claude-4-sonnet",
                            name = "claude-4-sonnet",
                            title = "Claude 4 Sonnet",
                            capabilities = { "tool_use", "thinking", "generate" },
                            classes = { "coder", "chat" },
                            priority = 95,
                            max_tokens = 200000,
                            providers = {
                                {
                                    id = "wippy.llm.provider:anthropic",
                                    provider_model = "claude-sonnet-4-20250514",
                                    pricing = { input = 3, output = 15 },
                                    options = {}
                                }
                            }
                        }
                    elseif name == "text-embedding-3-small" then
                        return {
                            id = "app.models:text-embedding-3-small",
                            name = "text-embedding-3-small",
                            title = "Text Embedding 3 Small",
                            capabilities = { "embed" },
                            classes = { "embedding" },
                            priority = 90,
                            dimensions = 1536,
                            providers = {
                                {
                                    id = "wippy.llm.openai:provider",
                                    provider_model = "text-embedding-3-small",
                                    pricing = { input = 0.02, output = 0 },
                                    options = {}
                                }
                            }
                        }
                    else
                        return nil, "Model not found: " .. name
                    end
                end,

                get_by_class = function(class_name)
                    local results = {}

                    if class_name == "coder" then
                        table.insert(results, {
                            id = "app.models:claude-4-sonnet",
                            name = "claude-4-sonnet",
                            title = "Claude 4 Sonnet",
                            capabilities = { "tool_use", "thinking", "generate" },
                            classes = { "coder", "chat" },
                            priority = 95,
                            providers = {
                                {
                                    id = "wippy.llm.provider:anthropic",
                                    provider_model = "claude-sonnet-4-20250514",
                                    pricing = { input = 3, output = 15 },
                                    options = {}
                                }
                            }
                        })
                    elseif class_name == "frontier" then
                        table.insert(results, {
                            id = "app.models:gpt-4o",
                            name = "gpt-4o",
                            title = "GPT-4o",
                            capabilities = { "tool_use", "vision", "generate" },
                            classes = { "frontier", "multimodal" },
                            priority = 100,
                            providers = {
                                {
                                    id = "wippy.llm.openai:provider",
                                    provider_model = "gpt-4o-2024-11-20",
                                    pricing = { input = 2.5, output = 10 },
                                    options = {}
                                }
                            }
                        })
                    elseif class_name == "embedding" then
                        table.insert(results, {
                            id = "app.models:text-embedding-3-small",
                            name = "text-embedding-3-small",
                            title = "Text Embedding 3 Small",
                            capabilities = { "embed" },
                            classes = { "embedding" },
                            priority = 90,
                            dimensions = 1536,
                            providers = {
                                {
                                    id = "wippy.llm.openai:provider",
                                    provider_model = "text-embedding-3-small",
                                    pricing = { input = 0.02, output = 0 },
                                    options = {}
                                }
                            }
                        })
                    end

                    table.sort(results, function(a, b)
                        return (a.priority or 0) > (b.priority or 0)
                    end)

                    return results
                end,

                get_all = function()
                    local all_models = {}
                    table.insert(all_models, {
                        id = "app.models:gpt-4o",
                        name = "gpt-4o",
                        title = "GPT-4o",
                        capabilities = { "tool_use", "vision", "generate" },
                        classes = { "frontier", "multimodal" },
                        priority = 100
                    })
                    table.insert(all_models, {
                        id = "app.models:claude-4-sonnet",
                        name = "claude-4-sonnet",
                        title = "Claude 4 Sonnet",
                        capabilities = { "tool_use", "thinking", "generate" },
                        classes = { "coder", "chat" },
                        priority = 95
                    })
                    table.insert(all_models, {
                        id = "app.models:text-embedding-3-small",
                        name = "text-embedding-3-small",
                        title = "Text Embedding 3 Small",
                        capabilities = { "embed" },
                        classes = { "embedding" },
                        priority = 90
                    })
                    return all_models
                end,

                get_all_classes = function()
                    local classes = {}
                    table.insert(classes,
                        { id = "app.models:frontier", name = "frontier", title = "Frontier Models", description =
                        "State-of-the-art models" })
                    table.insert(classes,
                        { id = "app.models:coder", name = "coder", title = "Coding Models", description =
                        "Programming-optimized models" })
                    table.insert(classes,
                        { id = "app.models:chat", name = "chat", title = "Chat Models", description =
                        "Conversation-optimized models" })
                    table.insert(classes,
                        { id = "app.models:multimodal", name = "multimodal", title = "Vision Models", description =
                        "Image processing models" })
                    table.insert(classes,
                        { id = "app.models:embedding", name = "embedding", title = "Embedding Models", description =
                        "Text embedding models" })
                    return classes
                end
            }

            -- Create mock providers module
            mock_providers = {
                open = function(provider_id, options)
                    options = options or {}

                    local instance = {
                        _provider_id = provider_id,
                        _options = options
                    }

                    if provider_id == "wippy.llm.openai:provider" then
                        instance.generate = function(self, args)
                            return {
                                success = true,
                                result = {
                                    content = "Mock response from OpenAI",
                                    tool_calls = args.tools and {
                                        {
                                            id = "call_123",
                                            name = "test_tool",
                                            arguments = { param = "value" }
                                        }
                                    } or {}
                                },
                                tokens = {
                                    prompt_tokens = 20,
                                    completion_tokens = 15,
                                    total_tokens = 35
                                },
                                finish_reason = "stop",
                                metadata = { request_id = "req_openai_123" }
                            }
                        end

                        instance.structured_output = function(self, args)
                            return {
                                success = true,
                                result = {
                                    data = { name = "John", age = 30 }
                                },
                                tokens = {
                                    prompt_tokens = 25,
                                    completion_tokens = 10,
                                    total_tokens = 35
                                },
                                finish_reason = "stop"
                            }
                        end

                        instance.embed = function(self, args)
                            local input = args.input
                            local embeddings
                            if type(input) == "table" then
                                embeddings = {}
                                for i = 1, #input do
                                    local vec = {}
                                    for j = 1, 1536 do
                                        table.insert(vec, math.sin(i + j) * 0.1)
                                    end
                                    table.insert(embeddings, vec)
                                end
                            else
                                embeddings = {}
                                for i = 1, 1536 do
                                    table.insert(embeddings, math.sin(i) * 0.1)
                                end
                            end

                            return {
                                success = true,
                                result = {
                                    embeddings = type(input) == "table" and embeddings or { embeddings }
                                },
                                tokens = {
                                    prompt_tokens = type(input) == "table" and (#input * 5) or 5,
                                    total_tokens = type(input) == "table" and (#input * 5) or 5
                                }
                            }
                        end
                    elseif provider_id == "wippy.llm.provider:anthropic" then
                        instance.generate = function(self, args)
                            return {
                                success = true,
                                result = {
                                    content = "Mock response from Claude",
                                    tool_calls = args.tools and {
                                        {
                                            id = "toolu_123",
                                            name = "test_tool",
                                            arguments = { param = "value" }
                                        }
                                    } or {}
                                },
                                tokens = {
                                    prompt_tokens = 22,
                                    completion_tokens = 18,
                                    thinking_tokens = 5,
                                    total_tokens = 45
                                },
                                finish_reason = "stop",
                                metadata = { request_id = "req_claude_123" }
                            }
                        end

                        instance.structured_output = function(self, args)
                            return {
                                success = true,
                                result = {
                                    data = { name = "Jane", age = 25 }
                                },
                                tokens = {
                                    prompt_tokens = 20,
                                    completion_tokens = 12,
                                    total_tokens = 32
                                },
                                finish_reason = "stop"
                            }
                        end
                    else
                        return nil, "Unknown provider: " .. provider_id
                    end

                    return instance
                end
            }

            -- Create mock usage tracker
            mock_usage_tracker = {
                track_usage = function(self, model_id, prompt_tokens, completion_tokens, thinking_tokens,
                                       cache_read_tokens, cache_write_tokens, options)
                    return "usage_" .. tostring(math.random(1000, 9999))
                end
            }

            -- Inject mocks
            llm._models = mock_models
            llm._providers = mock_providers
            llm._usage_tracker = mock_usage_tracker
        end)

        after_each(function()
            -- Reset dependencies
            llm._models = nil
            llm._providers = nil
            llm._usage_tracker = nil
        end)

        describe("Smart Model Resolution", function()
            it("should resolve model by exact name", function()
                local result, err = llm.generate("Hello", { model = "gpt-4o" })

                expect(err).to_be_nil()
                expect(result.result).to_equal("Mock response from OpenAI")
                expect(result.tokens.prompt_tokens).to_equal(20)
            end)

            it("should resolve model by class name", function()
                local result, err = llm.generate("Hello", { model = "coder" })

                expect(err).to_be_nil()
                expect(result.result).to_equal("Mock response from Claude")
                expect(result.tokens.thinking_tokens).to_equal(5)
            end)

            it("should resolve model using class: syntax", function()
                local result, err = llm.generate("Hello", { model = "class:frontier" })

                expect(err).to_be_nil()
                expect(result.result).to_equal("Mock response from OpenAI")
            end)

            it("should fail for unknown model or class", function()
                local result, err = llm.generate("Hello", { model = "nonexistent" })

                expect(result).to_be_nil()
                expect(err).to_contain("Model or class not found")
            end)

            it("should fail for empty class", function()
                local result, err = llm.generate("Hello", { model = "class:nonexistent" })

                expect(result).to_be_nil()
                expect(err).to_contain("No models found for class")
            end)
        end)

        describe("Direct Provider Calls", function()
            it("should support direct provider_id calls", function()
                local result, err = llm.generate("Hello", {
                    model = "custom-model-name",
                    provider_id = "wippy.llm.openai:provider"
                })

                expect(err).to_be_nil()
                expect(result.result).to_equal("Mock response from OpenAI")
                expect(result.tokens.prompt_tokens).to_equal(20)
            end)

            it("should handle direct provider calls for structured output", function()
                local schema = { type = "object", properties = { test = { type = "string" } } }
                local result, err = llm.structured_output(schema, "Generate data", {
                    model = "custom-model",
                    provider_id = "wippy.llm.openai:provider"
                })

                expect(err).to_be_nil()
                expect(result.result.name).to_equal("John")
                expect(result.result.age).to_equal(30)
            end)

            it("should handle direct provider calls for embeddings", function()
                local result, err = llm.embed("Test text", {
                    model = "custom-embed-model",
                    provider_id = "wippy.llm.openai:provider"
                })

                expect(err).to_be_nil()
                expect(result.result).not_to_be_nil()
                expect(#result.result).to_equal(1)
                expect(#result.result[1]).to_equal(1536)
            end)
        end)

        describe("Text Generation", function()
            it("should generate text with string prompt", function()
                local result, err = llm.generate("Hello world", { model = "gpt-4o" })

                expect(err).to_be_nil()
                expect(result.result).to_equal("Mock response from OpenAI")
                expect(result.tokens.prompt_tokens).to_equal(20)
                expect(result.tokens.completion_tokens).to_equal(15)
                expect(result.tokens.total_tokens).to_equal(35)
                expect(result.finish_reason).to_equal("stop")
            end)

            it("should generate text with message array", function()
                local messages = {
                    { role = "user", content = { { type = "text", text = "Hello" } } }
                }

                local result, err = llm.generate(messages, { model = "gpt-4o" })

                expect(err).to_be_nil()
                expect(result.result).to_equal("Mock response from OpenAI")
            end)

            it("should generate text with prompt object", function()
                local prompt = {
                    messages = {
                        { role = "user", content = { { type = "text", text = "Hello" } } }
                    }
                }

                local result, err = llm.generate(prompt, { model = "gpt-4o" })

                expect(err).to_be_nil()
                expect(result.result).to_equal("Mock response from OpenAI")
            end)

            it("should handle tool calls", function()
                local result, err = llm.generate("Calculate", {
                    model = "gpt-4o",
                    tools = { { name = "calc", description = "Calculate", schema = { type = "object" } } }
                })

                expect(err).to_be_nil()
                expect(result.tool_calls).not_to_be_nil()
                expect(#result.tool_calls).to_equal(1)
                expect(result.tool_calls[1].name).to_equal("test_tool")
            end)

            it("should require model parameter", function()
                local result, err = llm.generate("Hello", {})

                expect(result).to_be_nil()
                expect(err).to_equal("Model is required in options")
            end)

            it("should handle provider errors", function()
                mock_providers.open = function(provider_id, options)
                    return nil, "Provider unavailable"
                end

                local result, err = llm.generate("Hello", { model = "gpt-4o" })

                expect(result).to_be_nil()
                expect(err).to_contain("Failed to open provider")
            end)
        end)

        describe("Structured Output", function()
            it("should generate structured output", function()
                local schema = {
                    type = "object",
                    properties = {
                        name = { type = "string" },
                        age = { type = "number" }
                    }
                }

                local result, err = llm.structured_output(schema, "Create person", { model = "gpt-4o" })

                expect(err).to_be_nil()
                expect(result.result.name).to_equal("John")
                expect(result.result.age).to_equal(30)
                expect(result.tokens.prompt_tokens).to_equal(25)
            end)

            it("should require schema parameter", function()
                local result, err = llm.structured_output(nil, "Create data", { model = "gpt-4o" })

                expect(result).to_be_nil()
                expect(err).to_equal("Schema is required")
            end)

            it("should require model parameter", function()
                local schema = { type = "object" }
                local result, err = llm.structured_output(schema, "Create data", {})

                expect(result).to_be_nil()
                expect(err).to_equal("Model is required in options")
            end)

            it("should handle contract errors", function()
                mock_providers.open = function(provider_id, options)
                    return {
                        structured_output = function(self, args)
                            return nil, "Schema validation failed"
                        end
                    }
                end

                local schema = { type = "object" }
                local result, err = llm.structured_output(schema, "Test", { model = "gpt-4o" })

                expect(result).to_be_nil()
                expect(err).to_equal("Schema validation failed")
            end)
        end)

        describe("Embeddings", function()
            it("should generate single embedding", function()
                local result, err = llm.embed("Test text", { model = "text-embedding-3-small" })

                expect(err).to_be_nil()
                expect(result.result).not_to_be_nil()
                expect(#result.result).to_equal(1)
                expect(#result.result[1]).to_equal(1536)
                expect(result.tokens.prompt_tokens).to_equal(5)
            end)

            it("should generate multiple embeddings", function()
                local result, err = llm.embed({ "Text 1", "Text 2" }, { model = "text-embedding-3-small" })

                expect(err).to_be_nil()
                expect(result.result).not_to_be_nil()
                expect(#result.result).to_equal(2)
                expect(#result.result[1]).to_equal(1536)
                expect(#result.result[2]).to_equal(1536)
                expect(result.tokens.prompt_tokens).to_equal(10)
            end)

            it("should require model parameter", function()
                local result, err = llm.embed("Test", {})

                expect(result).to_be_nil()
                expect(err).to_equal("Model is required in options")
            end)
        end)

        describe("Model Discovery", function()
            it("should return all available models", function()
                local models_result, err = llm.available_models()

                expect(err).to_be_nil()
                expect(models_result).not_to_be_nil()
                expect(#models_result).to_equal(3)
                expect(models_result[1].name).to_equal("gpt-4o")
            end)

            it("should filter models by capability", function()
                local models_result, err = llm.available_models("embed")

                expect(err).to_be_nil()
                expect(models_result).not_to_be_nil()
                expect(#models_result).to_equal(1)
                expect(models_result[1].name).to_equal("text-embedding-3-small")
            end)

            it("should return empty array for non-existent capability", function()
                local models_result, err = llm.available_models("nonexistent")

                expect(err).to_be_nil()
                expect(models_result).not_to_be_nil()
                expect(#models_result).to_equal(0)
            end)

            it("should handle models module errors", function()
                mock_models.get_all = function()
                    return nil, "Models unavailable"
                end

                local models_result, err = llm.available_models()

                expect(models_result).to_be_nil()
                expect(err).to_equal("Models unavailable")
            end)
        end)

        describe("Class Discovery", function()
            it("should return all classes", function()
                local classes, err = llm.get_classes()

                expect(err).to_be_nil()
                expect(classes).not_to_be_nil()
                expect(#classes).to_equal(5)
                expect(classes[1].name).to_equal("frontier")
                expect(classes[1].title).to_equal("Frontier Models")
            end)

            it("should handle classes module errors", function()
                mock_models.get_all_classes = function()
                    return nil, "Classes unavailable"
                end

                local classes, err = llm.get_classes()

                expect(classes).to_be_nil()
                expect(err).to_equal("Classes unavailable")
            end)
        end)

        describe("Usage Tracking", function()
            it("should track usage when tracker is available", function()
                local response = {
                    tokens = {
                        prompt_tokens = 10,
                        completion_tokens = 5,
                        thinking_tokens = 2,
                        cache_read_input_tokens = 3,
                        cache_creation_input_tokens = 1
                    }
                }

                local usage_id, err = llm.track_usage(response, "gpt-4o", {})

                expect(err).to_be_nil()
                expect(usage_id).not_to_be_nil()
                expect(usage_id).to_contain("usage_")
            end)
        end)

        describe("Constants Backward Compatibility", function()
            it("should preserve CAPABILITY constants", function()
                expect(llm.CAPABILITY.GENERATE).to_equal("generate")
                expect(llm.CAPABILITY.TOOL_USE).to_equal("tool_use")
                expect(llm.CAPABILITY.STRUCTURED_OUTPUT).to_equal("structured_output")
                expect(llm.CAPABILITY.EMBED).to_equal("embed")
                expect(llm.CAPABILITY.THINKING).to_equal("thinking")
                expect(llm.CAPABILITY.VISION).to_equal("vision")
                expect(llm.CAPABILITY.CACHING).to_equal("caching")
            end)

            it("should preserve ERROR_TYPE constants", function()
                expect(llm.ERROR_TYPE.INVALID_REQUEST).to_equal("invalid_request")
                expect(llm.ERROR_TYPE.AUTHENTICATION).to_equal("authentication_error")
                expect(llm.ERROR_TYPE.RATE_LIMIT).to_equal("rate_limit_exceeded")
                expect(llm.ERROR_TYPE.SERVER_ERROR).to_equal("server_error")
                expect(llm.ERROR_TYPE.CONTEXT_LENGTH).to_equal("context_length_exceeded")
                expect(llm.ERROR_TYPE.CONTENT_FILTER).to_equal("content_filter")
                expect(llm.ERROR_TYPE.TIMEOUT).to_equal("timeout_error")
                expect(llm.ERROR_TYPE.MODEL_ERROR).to_equal("model_error")
            end)

            it("should preserve FINISH_REASON constants", function()
                expect(llm.FINISH_REASON.STOP).to_equal("stop")
                expect(llm.FINISH_REASON.LENGTH).to_equal("length")
                expect(llm.FINISH_REASON.CONTENT_FILTER).to_equal("filtered")
                expect(llm.FINISH_REASON.TOOL_CALL).to_equal("tool_call")
                expect(llm.FINISH_REASON.ERROR).to_equal("error")
            end)
        end)

        describe("Response Integration", function()
            it("should include usage tracking in generate response", function()
                local result, err = llm.generate("Hello", { model = "gpt-4o" })

                expect(err).to_be_nil()
                expect(result.usage_record).not_to_be_nil()
                expect(result.usage_record.usage_id).not_to_be_nil()
                expect(result.usage_record.usage_id).to_contain("usage_")
            end)

            it("should include all expected response fields", function()
                local result, err = llm.generate("Hello", { model = "gpt-4o" })

                expect(err).to_be_nil()
                expect(result.result).not_to_be_nil()
                expect(result.tokens).not_to_be_nil()
                expect(result.finish_reason).not_to_be_nil()
                expect(result.metadata).not_to_be_nil()
                expect(result.tool_calls).not_to_be_nil()
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
