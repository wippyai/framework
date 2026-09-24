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
                    elseif name == "jev" then
                        return {
                            id = "app.models:jev",
                            name = "jev",
                            title = "Jev System One",
                            capabilities = { "evaluate" },
                            class = { "evaluate" },
                            priority = 100,
                            providers = {
                                {
                                    id = "wippy.llm.typesafe:provider",
                                    provider_model = "jev-2026-01",
                                    options = { calibration = "platt" }
                                }
                            }
                        }
                    elseif name == "jev-undeclared" then
                        return {
                            id = "app.models:jev-undeclared",
                            name = "jev-undeclared",
                            title = "Jev Without Declared Capabilities",
                            capabilities = {},
                            class = {},
                            priority = 90,
                            providers = {
                                {
                                    id = "wippy.llm.typesafe:provider",
                                    provider_model = "jev-undeclared-2026-01",
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
                last_open = nil,
                last_evaluate_args = nil,
                last_generate_args = nil,
                open = function(provider_id, options)
                    options = options or {}
                    mock_providers.last_open = {
                        provider_id = provider_id,
                        options = options,
                    }

                    local instance = {
                        _provider_id = provider_id,
                        _options = options
                    }

                    if provider_id == "wippy.llm.openai:provider" then
                        instance.generate = function(self, args)
                            mock_providers.last_generate_args = args
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
                    elseif provider_id == "wippy.llm.typesafe:provider" then
                        instance.evaluate = function(self, args)
                            mock_providers.last_evaluate_args = args
                            return {
                                success = true,
                                result = {
                                    readings = {
                                        intent = {
                                            type = "choice",
                                            choice = "technical",
                                            probabilities = { billing = 0.08, technical = 0.85, sales = 0.07 },
                                            confidence = 0.82
                                        },
                                        resolved = {
                                            type = "predicate",
                                            probability = 0.92
                                        },
                                        mood = {
                                            type = "score",
                                            score = 2.6,
                                            level = 3,
                                            probabilities = { 0.05, 0.3, 0.65 }
                                        }
                                    }
                                },
                                tokens = {
                                    prompt_tokens = 120,
                                    completion_tokens = 0,
                                    total_tokens = 120
                                },
                                metadata = { request_id = "req_typesafe_123" }
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
                last_model_id = nil,
                track_usage = function(self, model_id, prompt_tokens, completion_tokens, thinking_tokens,
                                       cache_read_tokens, cache_write_tokens, options)
                    self.last_model_id = model_id
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
            llm._model_resolver = nil
        end)

        describe("Smart Model Resolution", function()
            it("should resolve model by exact name", function()
                local result, err = llm.generate("Hello", { model = "gpt-4o" })

                test.is_nil(err)
                test.eq(result.result, "Mock response from OpenAI")
                test.eq(result.tokens.prompt_tokens, 20)
                test.eq(mock_usage_tracker.last_model_id, "gpt-4o")
            end)

            it("should resolve model by class name", function()
                local result, err = llm.generate("Hello", { model = "coder" })

                test.is_nil(err)
                test.eq(result.result, "Mock response from Claude")
                test.eq(result.tokens.thinking_tokens, 5)
                test.eq(mock_usage_tracker.last_model_id, "claude-4-sonnet")
            end)

            it("should resolve model using class: syntax", function()
                local result, err = llm.generate("Hello", { model = "class:frontier" })

                test.is_nil(err)
                test.eq(result.result, "Mock response from OpenAI")
                test.eq(mock_usage_tracker.last_model_id, "gpt-4o")
            end)

            it("should fail for unknown model or class", function()
                local result, err = llm.generate("Hello", { model = "nonexistent" })

                test.is_nil(result)
                test.contains(err, "Model or class not found")
            end)

            it("should fail for empty class", function()
                local result, err = llm.generate("Hello", { model = "class:nonexistent" })

                test.is_nil(result)
                test.contains(err, "No models found for class")
            end)
        end)

        describe("Optional Model Resolver Contract", function()
            type ResolvedProvider = {
                id: string,
                provider_model: string?,
                context: { [string]: any }?,
                options: { [string]: any }?,
            }
            type ResolvedCard = {
                id: string,
                name: string,
                title: string?,
                priority: number?,
                max_tokens: number?,
                providers: { ResolvedProvider }?,
            }

            local custom_card: ResolvedCard = {
                id = "custom:via-resolver",
                name = "custom-via-resolver",
                title = "Custom Resolved Model",
                priority = 100,
                max_tokens = 128000,
                providers = {
                    {
                        id = "wippy.llm.openai:provider",
                        provider_model = "gpt-4o-2024-11-20",
                        options = {}
                    }
                }
            }

            it("should resolve via the bound resolver, bypassing discovery", function()
                -- "custom-via-resolver" is unknown to discovery; only the resolver knows it.
                llm._model_resolver = {
                    resolve = function(self, args: { model: string }): ResolvedCard
                        return custom_card
                    end
                }

                local result, err = llm.generate("Hello", { model = "custom-via-resolver" })

                test.is_nil(err)
                test.eq(result.result, "Mock response from OpenAI")
                test.eq(mock_usage_tracker.last_model_id, "custom-via-resolver")
            end)

            it("should pass resolver provider context when opening the provider", function()
                llm._model_resolver = {
                    resolve = function(self, args: { model: string }): ResolvedCard
                        return {
                            id = "custom:with-context",
                            name = "custom-with-context",
                            providers = {
                                {
                                    id = "wippy.llm.openai:provider",
                                    provider_model = "gpt-4o-2024-11-20",
                                    context = {
                                        api_key = "stored-profile-key",
                                        base_url = "https://profile.example/v1",
                                        timeout = 30,
                                    },
                                    options = {
                                        timeout = 60,
                                    },
                                },
                            },
                        }
                    end,
                }

                local result, err = llm.generate("Hello", { model = "custom-with-context" })

                test.is_nil(err)
                test.eq(result.result, "Mock response from OpenAI")
                test.eq(mock_providers.last_open.provider_id, "wippy.llm.openai:provider")
                test.eq(mock_providers.last_open.options.api_key, "stored-profile-key")
                test.eq(mock_providers.last_open.options.base_url, "https://profile.example/v1")
                test.eq(mock_providers.last_open.options.timeout, 60)
            end)

            it("should deliver resolver provider retry through the provider context", function()
                llm._model_resolver = {
                    resolve = function(self, args: { model: string }): ResolvedCard
                        return {
                            id = "custom:with-retry",
                            name = "custom-with-retry",
                            providers = {
                                {
                                    id = "wippy.llm.openai:provider",
                                    provider_model = "gpt-4o-2024-11-20",
                                    context = {
                                        retry = { attempts = 3, backoff_ms = 50 },
                                    },
                                    options = {},
                                },
                            },
                        }
                    end,
                }

                local result, err = llm.generate("Hello", { model = "custom-with-retry" })

                test.is_nil(err)
                test.eq(result.result, "Mock response from OpenAI")
                test.eq(mock_providers.last_open.options.retry.attempts, 3)
                test.eq(mock_providers.last_open.options.retry.backoff_ms, 50)
                test.is_nil(mock_providers.last_generate_args.retry)
            end)

            it("should keep the configured model_profile when a caller passes its own", function()
                llm._model_resolver = {
                    resolve = function(self, args: { model: string }): ResolvedCard
                        return {
                            id = "custom:profiled",
                            name = "custom-profiled",
                            providers = {
                                {
                                    id = "wippy.llm.openai:provider",
                                    provider_model = "gpt-4o-2024-11-20",
                                    options = { model_profile = { forced_tool_choice = false } },
                                },
                            },
                        }
                    end,
                }

                local result, err = llm.generate("Hello", {
                    model = "custom-profiled",
                    model_profile = { forced_tool_choice = true },
                    tool_choice_fallback = "auto",
                })

                test.is_nil(err)
                test.eq(result.result, "Mock response from OpenAI")
                test.is_false(mock_providers.last_generate_args.options.model_profile.forced_tool_choice)
                test.eq(mock_providers.last_generate_args.options.tool_choice_fallback, "auto")
            end)

            it("should forward per-call retry to the provider call", function()
                llm._model_resolver = {
                    resolve = function(self, args: { model: string }): ResolvedCard
                        return {
                            id = "custom:per-call-retry",
                            name = "custom-per-call-retry",
                            providers = {
                                {
                                    id = "wippy.llm.openai:provider",
                                    provider_model = "gpt-4o-2024-11-20",
                                    context = {
                                        retry = { attempts = 3, backoff_ms = 50 },
                                    },
                                    options = {},
                                },
                            },
                        }
                    end,
                }

                local result, err = llm.generate("Hello", {
                    model = "custom-per-call-retry",
                    retry = { attempts = 5 },
                })

                test.is_nil(err)
                test.eq(result.result, "Mock response from OpenAI")
                test.eq(mock_providers.last_generate_args.retry.attempts, 5)
                test.is_nil(mock_providers.last_generate_args.options.retry)
            end)

            it("should fall back to discovery when the resolver returns no card", function()
                llm._model_resolver = {
                    resolve = function(self, args: { model: string }): ResolvedCard?
                        return nil
                    end
                }

                local result, err = llm.generate("Hello", { model = "gpt-4o" })

                test.is_nil(err)
                test.eq(result.result, "Mock response from OpenAI")
                test.eq(mock_usage_tracker.last_model_id, "gpt-4o")
            end)

            it("should use discovery unchanged when no resolver is bound", function()
                -- No resolver set (default). This is the path every other test exercises.
                test.is_nil(llm._model_resolver)

                local result, err = llm.generate("Hello", { model = "gpt-4o" })

                test.is_nil(err)
                test.eq(result.result, "Mock response from OpenAI")

                local unknown_result, unknown_err = llm.generate("Hello", { model = "custom-via-resolver" })
                test.is_nil(unknown_result, "discovery does not know the resolver-only model")
                test.contains(unknown_err, "Model or class not found")
            end)

            it("should fall back to discovery when the resolver returns an error", function()
                llm._model_resolver = {
                    resolve = function(self, args: { model: string }): (ResolvedCard?, string?)
                        return nil, "resolver backend unavailable"
                    end
                }

                local result, err = llm.generate("Hello", { model = "gpt-4o" })

                test.is_nil(err, "resolver error does not propagate; discovery is used")
                test.eq(result.result, "Mock response from OpenAI")
                test.eq(mock_usage_tracker.last_model_id, "gpt-4o")
            end)

            it("should let discovery handle class: syntax the resolver declines", function()
                llm._model_resolver = {
                    resolve = function(self, args: { model: string }): ResolvedCard?
                        return nil
                    end
                }

                local result, err = llm.generate("Hello", { model = "class:frontier" })

                test.is_nil(err)
                test.eq(result.result, "Mock response from OpenAI")
                test.eq(mock_usage_tracker.last_model_id, "gpt-4o")
            end)

            it("should surface a missing-providers error for a malformed resolver card", function()
                llm._model_resolver = {
                    resolve = function(self, args: { model: string }): ResolvedCard
                        return { id = "custom:bad", name = "custom-no-providers" }
                    end
                }

                local result, err = llm.generate("Hello", { model = "custom-no-providers" })

                test.is_nil(result)
                test.contains(err, "Model has no configured providers")
            end)

            it("should apply the resolver to structured_output as well as generate", function()
                llm._model_resolver = {
                    resolve = function(self, args: { model: string }): ResolvedCard
                        return custom_card
                    end
                }

                local schema = {
                    type = "object",
                    additionalProperties = false,
                    properties = { name = { type = "string" } },
                    required = { "name" }
                }
                local result, err = llm.structured_output(schema, "Extract", { model = "custom-via-resolver" })

                test.is_nil(err)
                test.not_nil(result)
                test.eq(mock_usage_tracker.last_model_id, "custom-via-resolver")
            end)
        end)

        describe("Direct Provider Calls", function()
            it("should support direct provider_id calls", function()
                local result, err = llm.generate("Hello", {
                    model = "custom-model-name",
                    provider_id = "wippy.llm.openai:provider"
                })

                test.is_nil(err)
                test.eq(result.result, "Mock response from OpenAI")
                test.eq(result.tokens.prompt_tokens, 20)
            end)

            it("should handle direct provider calls for structured output", function()
                local schema = { type = "object", properties = { test = { type = "string" } } }
                local result, err = llm.structured_output(schema, "Generate data", {
                    model = "custom-model",
                    provider_id = "wippy.llm.openai:provider"
                })

                test.is_nil(err)
                test.eq(result.result.name, "John")
                test.eq(result.result.age, 30)
            end)

            it("should handle direct provider calls for embeddings", function()
                local result, err = llm.embed("Test text", {
                    model = "custom-embed-model",
                    provider_id = "wippy.llm.openai:provider"
                })

                test.is_nil(err)
                test.not_nil(result.result)
                test.eq(#result.result, 1)
                test.eq(#result.result[1], 1536)
            end)

            it("should report the requested model for direct provider embed calls", function()
                local result, err = llm.embed("Test text", {
                    model = "custom-embed-model",
                    provider_id = "wippy.llm.openai:provider"
                })

                test.is_nil(err)
                test.eq(result.model, "custom-embed-model")
            end)
        end)

        describe("Text Generation", function()
            it("should generate text with string prompt", function()
                local result, err = llm.generate("Hello world", { model = "gpt-4o" })

                test.is_nil(err)
                test.eq(result.result, "Mock response from OpenAI")
                test.eq(result.tokens.prompt_tokens, 20)
                test.eq(result.tokens.completion_tokens, 15)
                test.eq(result.tokens.total_tokens, 35)
                test.eq(result.finish_reason, "stop")
            end)

            it("should generate text with message array", function()
                local messages = {
                    { role = "user", content = { { type = "text", text = "Hello" } } }
                }

                local result, err = llm.generate(messages, { model = "gpt-4o" })

                test.is_nil(err)
                test.eq(result.result, "Mock response from OpenAI")
            end)

            it("should generate text with prompt object", function()
                local prompt = {
                    messages = {
                        { role = "user", content = { { type = "text", text = "Hello" } } }
                    }
                }

                local result, err = llm.generate(prompt, { model = "gpt-4o" })

                test.is_nil(err)
                test.eq(result.result, "Mock response from OpenAI")
            end)

            it("should handle tool calls", function()
                local result, err = llm.generate("Calculate", {
                    model = "gpt-4o",
                    tools = { { name = "calc", description = "Calculate", schema = { type = "object" } } }
                })

                test.is_nil(err)
                test.not_nil(result.tool_calls)
                test.eq(#result.tool_calls, 1)
                test.eq(result.tool_calls[1].name, "test_tool")
            end)

            it("should require model parameter", function()
                local result, err = llm.generate("Hello", {})

                test.is_nil(result)
                test.eq(err, "Model is required in options")
            end)

            it("should handle provider errors", function()
                mock_providers.open = function(provider_id, options)
                    return nil, "Provider unavailable"
                end

                local result, err = llm.generate("Hello", { model = "gpt-4o" })

                test.is_nil(result)
                test.contains(err, "Failed to open provider")
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

                test.is_nil(err)
                test.eq(result.result.name, "John")
                test.eq(result.result.age, 30)
                test.eq(result.tokens.prompt_tokens, 25)
            end)

            it("should require schema parameter", function()
                local result, err = llm.structured_output(nil, "Create data", { model = "gpt-4o" })

                test.is_nil(result)
                test.eq(err, "Schema is required")
            end)

            it("should require model parameter", function()
                local schema = { type = "object" }
                local result, err = llm.structured_output(schema, "Create data", {})

                test.is_nil(result)
                test.eq(err, "Model is required in options")
            end)

            it("should handle contract errors", function()
                mock_providers.open = function(provider_id, options)
                    return {
                        structured_output = function(self, args)
                            return nil, errors.new("Schema validation failed")
                        end
                    }
                end

                local schema = { type = "object" }
                local result, err = llm.structured_output(schema, "Test", { model = "gpt-4o" })

                test.is_nil(result)
                test.eq(err, "Schema validation failed")
            end)
        end)

        describe("Embeddings", function()
            it("should generate single embedding", function()
                local result, err = llm.embed("Test text", { model = "text-embedding-3-small" })

                test.is_nil(err)
                test.not_nil(result.result)
                test.eq(#result.result, 1)
                test.eq(#result.result[1], 1536)
                test.eq(result.tokens.prompt_tokens, 5)
            end)

            it("should generate multiple embeddings", function()
                local result, err = llm.embed({ "Text 1", "Text 2" }, { model = "text-embedding-3-small" })

                test.is_nil(err)
                test.not_nil(result.result)
                test.eq(#result.result, 2)
                test.eq(#result.result[1], 1536)
                test.eq(#result.result[2], 1536)
                test.eq(result.tokens.prompt_tokens, 10)
            end)

            it("should require model parameter", function()
                local result, err = llm.embed("Test", {})

                test.is_nil(result)
                test.eq(err, "Model is required in options")
            end)

            it("should report the resolved provider model, not the class alias", function()
                local result, err = llm.embed("Test text", { model = "class:embedding" })

                test.is_nil(err)
                test.eq(result.model, "text-embedding-3-small")
            end)

            it("should report the provider model when the card name differs and the provider is silent", function()
                local get_by_name = mock_models.get_by_name
                mock_models.get_by_name = function(name)
                    if name == "local-embed" then
                        return {
                            id = "app.models:local-embed",
                            name = "local-embed",
                            capabilities = { "embed" },
                            class = { "embedding" },
                            dimensions = 768,
                            providers = {
                                {
                                    id = "wippy.llm.openai:provider",
                                    provider_model = "nomic-embed-text-v1.5",
                                    options = {}
                                }
                            }
                        }
                    end
                    return get_by_name(name)
                end

                local result, err = llm.embed("Test text", { model = "local-embed" })

                test.is_nil(err)
                test.eq(result.model, "nomic-embed-text-v1.5")
            end)

            it("should keep the provider-reported model over the resolved name", function()
                mock_providers.open = function(provider_id, options)
                    return {
                        embed = function(self, args)
                            return {
                                success = true,
                                result = { embeddings = { { 0.1, 0.2, 0.3 } } },
                                model = "text-embedding-3-small-002",
                                tokens = { prompt_tokens = 5, total_tokens = 5 }
                            }
                        end
                    }
                end

                local result, err = llm.embed("Test text", { model = "text-embedding-3-small" })

                test.is_nil(err)
                test.eq(result.model, "text-embedding-3-small-002")
            end)
        end)

        describe("Model Discovery", function()
            it("should return all available models", function()
                local models_result, err = llm.available_models()

                test.is_nil(err)
                assert(models_result)
                test.eq(#models_result, 3)
                local first = assert(models_result[1])
                test.eq(first.name, "gpt-4o")
            end)

            it("should filter models by capability", function()
                local models_result, err = llm.available_models("embed")

                test.is_nil(err)
                assert(models_result)
                test.eq(#models_result, 1)
                local first = assert(models_result[1])
                test.eq(first.name, "text-embedding-3-small")
            end)

            it("should return empty array for non-existent capability", function()
                local models_result, err = llm.available_models("nonexistent")

                test.is_nil(err)
                test.not_nil(models_result)
                test.eq(#models_result, 0)
            end)

            it("should handle models module errors", function()
                mock_models.get_all = function()
                    return nil, "Models unavailable"
                end

                local models_result, err = llm.available_models()

                test.is_nil(models_result)
                test.eq(err, "Models unavailable")
            end)
        end)

        describe("Class Discovery", function()
            it("should return all classes", function()
                local classes, err = llm.get_classes()

                test.is_nil(err)
                test.not_nil(classes)
                test.eq(#classes, 5)
                test.eq(classes[1].name, "frontier")
                test.eq(classes[1].title, "Frontier Models")
            end)

            it("should handle classes module errors", function()
                mock_models.get_all_classes = function()
                    return nil, "Classes unavailable"
                end

                local classes, err = llm.get_classes()

                test.is_nil(classes)
                test.eq(err, "Classes unavailable")
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

                test.is_nil(err)
                test.not_nil(usage_id)
                test.contains(usage_id, "usage_")
            end)
        end)

        describe("Constants Backward Compatibility", function()
            it("should preserve CAPABILITY constants", function()
                test.eq(llm.CAPABILITY.GENERATE, "generate")
                test.eq(llm.CAPABILITY.TOOL_USE, "tool_use")
                test.eq(llm.CAPABILITY.STRUCTURED_OUTPUT, "structured_output")
                test.eq(llm.CAPABILITY.EMBED, "embed")
                test.eq(llm.CAPABILITY.THINKING, "thinking")
                test.eq(llm.CAPABILITY.VISION, "vision")
                test.eq(llm.CAPABILITY.CACHING, "caching")
            end)

            it("should preserve ERROR_TYPE constants", function()
                test.eq(llm.ERROR_TYPE.INVALID_REQUEST, "invalid_request")
                test.eq(llm.ERROR_TYPE.AUTHENTICATION, "authentication_error")
                test.eq(llm.ERROR_TYPE.RATE_LIMIT, "rate_limit_exceeded")
                test.eq(llm.ERROR_TYPE.SERVER_ERROR, "server_error")
                test.eq(llm.ERROR_TYPE.CONTEXT_LENGTH, "context_length_exceeded")
                test.eq(llm.ERROR_TYPE.CONTENT_FILTER, "content_filter")
                test.eq(llm.ERROR_TYPE.TIMEOUT, "timeout_error")
                test.eq(llm.ERROR_TYPE.MODEL_ERROR, "model_error")
            end)

            it("should preserve FINISH_REASON constants", function()
                test.eq(llm.FINISH_REASON.STOP, "stop")
                test.eq(llm.FINISH_REASON.LENGTH, "length")
                test.eq(llm.FINISH_REASON.CONTENT_FILTER, "filtered")
                test.eq(llm.FINISH_REASON.TOOL_CALL, "tool_call")
                test.eq(llm.FINISH_REASON.ERROR, "error")
            end)
        end)

        describe("Response Integration", function()
            it("should include usage tracking in generate response", function()
                local result, err = llm.generate("Hello", { model = "gpt-4o" })

                test.is_nil(err)
                test.not_nil(result.usage_record)
                test.not_nil(result.usage_record.usage_id)
                test.contains(result.usage_record.usage_id, "usage_")
            end)

            it("should include all expected response fields", function()
                local result, err = llm.generate("Hello", { model = "gpt-4o" })

                test.is_nil(err)
                test.not_nil(result.result)
                test.not_nil(result.tokens)
                test.not_nil(result.finish_reason)
                test.not_nil(result.metadata)
                test.not_nil(result.tool_calls)
            end)
        end)
        describe("Evaluation", function()
            local questions = {
                intent = {
                    type = "choice",
                    instructions = "Which queue owns this conversation",
                    domain = {
                        billing = "Payments, refunds and invoices",
                        technical = "Bugs, outages and integrations"
                    }
                },
                resolved = {
                    type = "predicate",
                    instructions = "The customer considers the issue closed"
                },
                mood = {
                    type = "score",
                    instructions = "Emotional temperature of the customer",
                    domain = { "calm", "frustrated", "angry" }
                }
            }

            it("should require model parameter", function()
                local result, err = llm.evaluate("I was charged twice", questions, {})

                test.is_nil(result)
                test.eq(err, "Model is required in options")
            end)

            it("should reject a questions that is not a table", function()
                local result, err = llm.evaluate("text", "intent", { model = "jev" })

                test.is_nil(result)
                test.eq(err, "Questions must be a table")
            end)

            it("should reject an empty questions", function()
                local result, err = llm.evaluate("text", {}, { model = "jev" })

                test.is_nil(result)
                test.eq(err, "Questions must declare at least one slot")
            end)

            it("should reject non-string slot keys", function()
                local result, err = llm.evaluate("text", {
                    { type = "predicate", instructions = "Holds" }
                }, { model = "jev" })

                test.is_nil(result)
                test.eq(err, "Question keys must be nonempty strings")
            end)

            it("should reject a slot that is not a table", function()
                local result, err = llm.evaluate("text", { mood = "score" }, { model = "jev" })

                test.is_nil(result)
                test.eq(err, "Slot must be a table in slot: mood")
            end)

            it("should reject a slot without a type", function()
                local result, err = llm.evaluate("text", {
                    mood = { instructions = "Emotional temperature" }
                }, { model = "jev" })

                test.is_nil(result)
                test.eq(err, "Slot type is required in slot: mood")
            end)

            it("should reject an unknown slot type", function()
                local result, err = llm.evaluate("text", {
                    mood = { type = "ranking", instructions = "Emotional temperature" }
                }, { model = "jev" })

                test.is_nil(result)
                test.eq(err, "Unknown slot type 'ranking' in slot: mood")
            end)

            it("should reject a slot without instructions", function()
                local result, err = llm.evaluate("text", {
                    resolved = { type = "predicate" }
                }, { model = "jev" })

                test.is_nil(result)
                test.eq(err, "Instructions are required in slot: resolved")
            end)

            it("should reject empty instructions", function()
                local result, err = llm.evaluate("text", {
                    resolved = { type = "predicate", instructions = "" }
                }, { model = "jev" })

                test.is_nil(result)
                test.eq(err, "Instructions must not be empty in slot: resolved")
            end)

            it("should reject instructions that are neither a string nor a table", function()
                local result, err = llm.evaluate("text", {
                    resolved = { type = "predicate", instructions = 42 }
                }, { model = "jev" })

                test.is_nil(result)
                test.eq(err, "Instructions must be a JSON-compatible string or table in slot: resolved")
            end)

            it("should accept table instructions", function()
                local result, err = llm.evaluate("text", {
                    resolved = {
                        type = "predicate",
                        instructions = { question = "Is the issue closed", examples = { "yes", "no" } }
                    }
                }, { model = "jev" })

                test.is_nil(err)
                test.not_nil(result)
                test.eq(result.result.resolved.probability, 0.92)
            end)

            it("should reject unknown slot fields", function()
                local result, err = llm.evaluate("text", {
                    resolved = { type = "predicate", instructions = "Holds", weight = 2 }
                }, { model = "jev" })

                test.is_nil(result)
                test.eq(err, "Unknown slot field 'weight' in slot: resolved")
            end)

            it("should reject a choice slot without a domain", function()
                local result, err = llm.evaluate("text", {
                    intent = { type = "choice", instructions = "Which queue" }
                }, { model = "jev" })

                test.is_nil(result)
                test.eq(err, "Choice domain is required in slot: intent")
            end)

            it("should reject a choice domain with fewer than two options", function()
                local result, err = llm.evaluate("text", {
                    intent = { type = "choice", instructions = "Which queue", domain = { "billing" } }
                }, { model = "jev" })

                test.is_nil(result)
                test.eq(err, "Choice domain must declare at least two options in slot: intent")
            end)

            it("should reject a choice domain map with fewer than two options", function()
                local result, err = llm.evaluate("text", {
                    intent = {
                        type = "choice",
                        instructions = "Which queue",
                        domain = { billing = "Payments and refunds" }
                    }
                }, { model = "jev" })

                test.is_nil(result)
                test.eq(err, "Choice domain must declare at least two options in slot: intent")
            end)

            it("should reject a choice domain with non-string option names", function()
                local result, err = llm.evaluate("text", {
                    intent = { type = "choice", instructions = "Which queue", domain = { "billing", 7 } }
                }, { model = "jev" })

                test.is_nil(result)
                test.eq(err, "Choice domain options must be strings in slot: intent")
            end)

            it("should reject a choice domain with non-string descriptions", function()
                local result, err = llm.evaluate("text", {
                    intent = {
                        type = "choice",
                        instructions = "Which queue",
                        domain = { billing = "Payments and refunds", technical = true }
                    }
                }, { model = "jev" })

                test.is_nil(result)
                test.eq(err, "Choice domain descriptions must be strings in slot: intent")
            end)

            it("should reject a score slot without a domain", function()
                local result, err = llm.evaluate("text", {
                    mood = { type = "score", instructions = "Temperature" }
                }, { model = "jev" })

                test.is_nil(result)
                test.eq(err, "Score domain must be an ordered array of at least two level descriptions in slot: mood")
            end)

            it("should reject a score domain with fewer than two levels", function()
                local result, err = llm.evaluate("text", {
                    mood = { type = "score", instructions = "Temperature", domain = { "calm" } }
                }, { model = "jev" })

                test.is_nil(result)
                test.eq(err, "Score domain must be an ordered array of at least two level descriptions in slot: mood")
            end)

            it("should reject a score domain that is a map", function()
                local result, err = llm.evaluate("text", {
                    mood = {
                        type = "score",
                        instructions = "Temperature",
                        domain = { calm = "Relaxed", angry = "Shouting" }
                    }
                }, { model = "jev" })

                test.is_nil(result)
                test.eq(err, "Score domain must be an ordered array of at least two level descriptions in slot: mood")
            end)

            it("should reject a score domain with non-string levels", function()
                local result, err = llm.evaluate("text", {
                    mood = { type = "score", instructions = "Temperature", domain = { "calm", 3 } }
                }, { model = "jev" })

                test.is_nil(result)
                test.eq(err, "Score domain levels must be strings in slot: mood")
            end)

            it("should reject a predicate domain with keys other than yes and no", function()
                local result, err = llm.evaluate("text", {
                    resolved = {
                        type = "predicate",
                        instructions = "Holds",
                        domain = { yes = "Closed", maybe = "Unclear" }
                    }
                }, { model = "jev" })

                test.is_nil(result)
                test.eq(err, "Predicate domain accepts only the keys yes and no in slot: resolved")
            end)

            it("should reject a predicate domain with non-string descriptions", function()
                local result, err = llm.evaluate("text", {
                    resolved = {
                        type = "predicate",
                        instructions = "Holds",
                        domain = { yes = "Closed", no = 0 }
                    }
                }, { model = "jev" })

                test.is_nil(result)
                test.eq(err, "Predicate domain descriptions must be strings in slot: resolved")
            end)

            it("should accept a predicate domain describing both outcomes", function()
                local result, err = llm.evaluate("text", {
                    resolved = {
                        type = "predicate",
                        instructions = "Holds",
                        domain = { yes = "Customer is satisfied", no = "Customer is still waiting" }
                    }
                }, { model = "jev" })

                test.is_nil(err)
                test.not_nil(result)
                test.eq(result.result.resolved.probability, 0.92)
            end)

            it("should reject a state that is not a string or a table", function()
                local result, err = llm.evaluate(42, questions, { model = "jev" })

                test.is_nil(result)
                test.eq(err, "State must be a string or a table")
            end)

            it("should reject a nil state", function()
                local result, err = llm.evaluate(nil, questions, { model = "jev" })

                test.is_nil(result)
                test.eq(err, "State must be a string or a table")
                test.is_nil(mock_providers.last_evaluate_args)
            end)

            it("should accept a table state", function()
                local state = { thread = { "I was charged twice", "Still waiting" }, tier = "pro" }
                local result, err = llm.evaluate(state, questions, { model = "jev" })

                test.is_nil(err)
                test.eq(mock_providers.last_evaluate_args.state.tier, "pro")
                test.eq(#mock_providers.last_evaluate_args.state.thread, 2)
            end)

            it("should validate the questions before opening a provider", function()
                local result, err = llm.evaluate("text", { mood = { type = "score" } }, { model = "jev" })

                test.is_nil(result)
                test.eq(err, "Instructions are required in slot: mood")
                test.is_nil(mock_providers.last_open)
            end)

            it("should build contract arguments on the direct provider path", function()
                local result, err = llm.evaluate("I was charged twice", questions, {
                    model = "jev-custom",
                    provider_id = "wippy.llm.typesafe:provider"
                })

                test.is_nil(err)
                test.not_nil(result)

                local args = mock_providers.last_evaluate_args
                test.eq(args.state, "I was charged twice")
                test.eq(args.model, "jev-custom")
                test.eq(args._provider_id, "wippy.llm.typesafe:provider")
                test.eq(args.questions.intent.type, "choice")
                test.eq(args.questions.intent.domain.billing, "Payments, refunds and invoices")
                test.eq(args.questions.mood.domain[3], "angry")
                test.is_nil(args.options.model)
                test.is_nil(args.options.provider_id)
            end)

            it("should map provider_model and merge provider options on the resolved path", function()
                local result, err = llm.evaluate("I was charged twice", questions, { model = "jev" })

                test.is_nil(err)

                local args = mock_providers.last_evaluate_args
                test.eq(args.model, "jev-2026-01")
                test.eq(args._provider_id, "wippy.llm.typesafe:provider")
                test.eq(args.options.calibration, "platt")
            end)

            it("should reject a model that does not declare the evaluate capability", function()
                local result, err = llm.evaluate("text", questions, { model = "gpt-4o" })

                test.is_nil(result)
                test.eq(err, "Model does not declare the evaluate capability: gpt-4o")
            end)

            it("should reject a model card that declares no capabilities", function()
                local result, err = llm.evaluate("text", questions, { model = "jev-undeclared" })

                test.is_nil(result)
                test.eq(err, "Model does not declare the evaluate capability: jev-undeclared")
                test.is_nil(mock_providers.last_evaluate_args)
            end)

            it("should normalize a reading for every declared slot", function()
                local result, err = llm.evaluate("I was charged twice", questions, { model = "jev" })

                test.is_nil(err)

                local intent = result.result.intent
                test.eq(intent.type, "choice")
                test.eq(intent.choice, "technical")
                test.eq(intent.probabilities.technical, 0.85)
                test.eq(intent.probabilities.billing, 0.08)
                test.eq(intent.confidence, 0.82)

                local resolved = result.result.resolved
                test.eq(resolved.type, "predicate")
                test.eq(resolved.probability, 0.92)

                local mood = result.result.mood
                test.eq(mood.type, "score")
                test.eq(mood.score, 2.6)
                test.eq(mood.level, 3)

                local probabilities = mood.probabilities :: {number}
                test.eq(#probabilities, 3)
                test.eq(probabilities[1], 0.05)
                test.eq(probabilities[3], 0.65)
                test.is_nil(mood.confidence)
            end)

            it("should pass through tokens and metadata", function()
                local result, err = llm.evaluate("text", questions, { model = "jev" })

                test.is_nil(err)
                test.eq(result.tokens.prompt_tokens, 120)
                test.eq(result.tokens.total_tokens, 120)
                test.eq(result.metadata.request_id, "req_typesafe_123")
            end)

            it("should track usage under the resolved model name", function()
                local result, err = llm.evaluate("text", questions, { model = "jev" })

                test.is_nil(err)
                test.eq(mock_usage_tracker.last_model_id, "jev")
                test.not_nil(result.usage_record)
                test.contains(result.usage_record.usage_id, "usage_")
            end)

            it("should propagate provider errors", function()
                mock_providers.open = function(provider_id, options)
                    return {
                        evaluate = function(self, args)
                            return nil, errors.new("Questions rejected by model")
                        end
                    }
                end

                local result, err = llm.evaluate("text", questions, { model = "jev" })

                test.is_nil(result)
                test.eq(err, "Questions rejected by model")
            end)

            it("should hoist timeout and retry out of options", function()
                local result, err = llm.evaluate("text", questions, {
                    model = "jev-custom",
                    provider_id = "wippy.llm.typesafe:provider",
                    timeout = 30,
                    retry = { attempts = 2 }
                })

                test.is_nil(err)

                local args = mock_providers.last_evaluate_args
                test.eq(args.timeout, 30)
                test.eq(args.retry.attempts, 2)
                test.is_nil(args.options.timeout)
                test.is_nil(args.options.retry)
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
