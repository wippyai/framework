local llm = require("llm")
local json = require("json")
local security = require("security")

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
                calls = { generate = 0, structured_output = 0 },
                -- Mirrors discovery/providers.lua: only the OpenAI driver
                -- declares the legacy reasoning_model_request flag.
                driver_declares_legacy_reasoning_flag = function(provider_id)
                    return provider_id == "wippy.llm.openai:provider"
                end,
                last_structured_output_args = nil,
                last_embed_args = nil,
                last_status_args = nil,
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
                            mock_providers.calls.generate = mock_providers.calls.generate + 1
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
                            mock_providers.calls.structured_output = mock_providers.calls.structured_output + 1
                            mock_providers.last_structured_output_args = args
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

                        instance.status = function(self, args)
                            mock_providers.last_status_args = args
                            return {
                                available = true,
                                latency = 12,
                                model = args.model
                            }
                        end

                        instance.embed = function(self, args)
                            mock_providers.last_embed_args = args
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

        describe("Route request facts", function()
            local schema = { type = "object", properties = {}, required = {}, additionalProperties = false }

            local function call(method, options)
                if method == "generate" then return llm.generate("Hello", options) end
                return llm.structured_output(schema, "Hello", options)
            end

            for _, method in ipairs({ "generate", "structured_output" }) do
                for _, source in ipairs({ "registry", "resolver", "direct" }) do
                    it("delivers and adjusts " .. method .. " facts from " .. source, function()
                        local ref = { id = "wippy.llm.openai:provider", provider_model = "wire-model",
                            thinking = "none", sampling = false, forced_tool_choice = false,
                            options = { temperature = 0.2, model_profile = { forced_tool_choice = true } } }
                        local card = { name = "route-model", providers = { ref } }
                        if source == "registry" then
                            mock_models.get_by_name = function() return card end
                        elseif source == "resolver" then
                            llm._model_resolver = { resolve = function() return card end }
                        end
                        local sent
                        mock_providers.open = function()
                            return { [method] = function(_, args)
                                sent = args
                                return { success = true, result = { content = "ok", data = {} },
                                    metadata = { adjusted = { other = { requested = 2, sent = 1 } },
                                        tool_choice = { requested = "any", sent = "auto" } } }
                            end }
                        end
                        local options = { model = "route-model", temperature = 0.7, top_p = 0.8,
                            top_k = 5, thinking_effort = 50, reasoning_model_request = true,
                            model_profile = { forced_tool_choice = true }, strict = false }
                        if source == "direct" then
                            options.provider_id = ref.id
                            options.accepts = { thinking = "none", sampling = false, forced_tool_choice = false }
                        end
                        local result, err = call(method, options)
                        test.is_nil(err)
                        test.eq(sent.accepts.thinking, "none")
                        test.is_false(sent.accepts.sampling)
                        test.is_false(sent.accepts.forced_tool_choice)
                        for _, key in ipairs({ "temperature", "top_p", "top_k", "thinking_effort" }) do
                            test.is_nil(sent.options[key])
                            test.eq(result.metadata.adjusted[key].requested, options[key])
                            test.is_nil(result.metadata.adjusted[key].sent)
                        end
                        for _, key in ipairs({ "accepts", "model_profile", "reasoning_model_request", "strict" }) do
                            test.is_nil(sent.options[key])
                        end
                        test.eq(result.metadata.adjusted.other.sent, 1)
                        test.eq(result.metadata.tool_choice.sent, "auto")
                        test.eq(options.temperature, 0.7)
                        test.eq(ref.options.temperature, 0.2)
                    end)
                end

                it("rejects strict adjustments before sending " .. method, function()
                    local result, err = call(method, { model = "wire", provider_id = "wippy.llm.openai:provider",
                        accepts = { sampling = false, thinking = "none" }, temperature = 0.4,
                        top_p = 0.8, top_k = 5, thinking_effort = 10, strict = true })
                    test.is_nil(result)
                    for _, key in ipairs({ "temperature", "top_p", "top_k", "thinking_effort" }) do
                        test.contains(err, key)
                    end
                    test.eq(mock_providers.calls.generate, 0)
                    test.eq(mock_providers.calls.structured_output, 0)
                end)

                it("rejects caller accepts on resolved " .. method, function()
                    local result, err = call(method, { model = "gpt-4o", accepts = { sampling = true } })
                    test.is_nil(result)
                    test.contains(err, "accepts")
                end)
            end

            it("enforces forced_tool_choice against a plain mock provider, proving the rule is provider-agnostic", function()
                local tools = { { name = "finish", description = "Finish", schema = { type = "object" } } }

                local result, err = llm.generate("Answer", { model = "wire", provider_id = "wippy.llm.openai:provider",
                    accepts = { forced_tool_choice = false }, tools = tools, tool_choice = "any" })
                test.is_nil(result)
                test.contains(err, "forced_tool_choice")
                test.eq(mock_providers.calls.generate, 0)

                local result2, err2 = llm.generate("Answer", { model = "wire", provider_id = "wippy.llm.openai:provider",
                    accepts = { forced_tool_choice = false }, tools = tools, tool_choice = "any",
                    tool_choice_fallback = "auto" })
                test.is_nil(err2)
                test.eq(mock_providers.last_generate_args.tool_choice, "auto")
                test.eq(result2.metadata.tool_choice.requested, "any")
                test.eq(result2.metadata.tool_choice.sent, "auto")
            end)

            it("normalizes legacy registry and per-call reasoning flags", function()
                for _, source in ipairs({ "route", "caller", "direct" }) do
                    local ref = { id = "wippy.llm.openai:provider", provider_model = "wire", options = {} }
                    mock_models.get_by_name = function() return { name = "legacy", providers = { ref } } end
                    local options = { model = "legacy", temperature = 0.3 }
                    if source == "route" then ref.options.reasoning_model_request = true
                    else options.reasoning_model_request = true end
                    if source == "direct" then options.provider_id = ref.id end
                    local result, err = llm.generate("Hello", options)
                    test.is_nil(err)
                    test.eq(mock_providers.last_generate_args.accepts.thinking, "adaptive")
                    test.is_false(mock_providers.last_generate_args.accepts.sampling)
                    test.is_nil(mock_providers.last_generate_args.options.reasoning_model_request)
                    test.eq(result.metadata.adjusted.temperature.requested, 0.3)
                end
            end)

            it("ignores the legacy reasoning flag on a driver that does not declare it", function()
                for _, source in ipairs({ "route", "caller", "direct" }) do
                    local ref = { id = "wippy.llm.provider:anthropic", provider_model = "wire", options = {} }
                    mock_models.get_by_name = function() return { name = "legacy-claude", providers = { ref } } end
                    local options = { model = "legacy-claude", temperature = 0.4 }
                    if source == "route" then ref.options.reasoning_model_request = true
                    else options.reasoning_model_request = true end
                    if source == "direct" then options.provider_id = ref.id end
                    local sent
                    mock_providers.open = function()
                        return { generate = function(_, args)
                            sent = args
                            return { success = true, result = { content = "ok" } }
                        end }
                    end
                    local result, err = llm.generate("Hello", options)
                    test.is_nil(err)
                    test.is_nil(sent.accepts.thinking)
                    test.is_nil(sent.accepts.sampling)
                    test.is_nil(sent.options.reasoning_model_request)
                    test.eq(sent.options.temperature, 0.4)
                    test.is_nil(result.metadata.adjusted)
                end
            end)
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

        describe("Public Model Resolution", function()
            it("should resolve a model card by name", function()
                local card, err = llm.resolve_model("gpt-4o")

                test.is_nil(err)
                test.eq(card.name, "gpt-4o")
            end)

            it("should resolve a model card by class name and class: syntax", function()
                local by_class, err = llm.resolve_model("coder")
                test.is_nil(err)
                test.eq(by_class.name, "claude-4-sonnet")

                local by_prefix, prefix_err = llm.resolve_model("class:frontier")
                test.is_nil(prefix_err)
                test.eq(by_prefix.name, "gpt-4o")
            end)

            it("should return an error for an unknown model", function()
                local card, err = llm.resolve_model("nonexistent")

                test.is_nil(card)
                test.contains(err, "Model or class not found")
            end)

            it("should prefer the model resolver contract when bound", function()
                llm._model_resolver = {
                    resolve = function(self, args)
                        return { id = "custom:m", name = "custom-m", max_tokens = 64000 }
                    end
                }

                local card, err = llm.resolve_model("anything")

                test.is_nil(err)
                test.eq(card.name, "custom-m")
                test.eq(card.max_tokens, 64000)
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
                test.is_false(mock_providers.last_generate_args.accepts.forced_tool_choice)
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

            it("should report context_tokens as uncached plus cached input", function()
                local open = mock_providers.open
                mock_providers.open = function(provider_id, options)
                    local instance = open(provider_id, options)
                    instance.generate = function(self, args)
                        return {
                            success = true,
                            result = { content = "ok", tool_calls = {} },
                            tokens = {
                                prompt_tokens = 10,
                                completion_tokens = 4,
                                total_tokens = 14,
                                cache_read_tokens = 30,
                                cache_write_tokens = 5
                            },
                            finish_reason = "stop"
                        }
                    end
                    return instance
                end

                local result, err = llm.generate("Hello", { model = "gpt-4o" })

                test.is_nil(err)
                test.eq(result.tokens.prompt_tokens, 10)
                test.eq(result.tokens.context_tokens, 45)
            end)

            it("should report context_tokens from provider-specific cache field names", function()
                local open = mock_providers.open
                mock_providers.open = function(provider_id, options)
                    local instance = open(provider_id, options)
                    instance.generate = function(self, args)
                        return {
                            success = true,
                            result = { content = "ok", tool_calls = {} },
                            tokens = {
                                prompt_tokens = 7,
                                completion_tokens = 1,
                                cache_read_input_tokens = 100,
                                cache_creation_input_tokens = 20
                            },
                            finish_reason = "stop"
                        }
                    end
                    return instance
                end

                local result, err = llm.generate("Hello", { model = "gpt-4o" })

                test.is_nil(err)
                test.eq(result.tokens.context_tokens, 127)
            end)

            it("should report context_tokens equal to prompt_tokens without caching", function()
                local result, err = llm.generate("Hello", { model = "gpt-4o" })

                test.is_nil(err)
                test.eq(result.tokens.context_tokens, 20)
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
                test.eq(llm.ERROR_TYPE.TIMEOUT, "timeout_error")
                test.eq(llm.ERROR_TYPE.MODEL_ERROR, "model_error")
            end)

            it("should use the error types drivers report", function()
                -- content_filter never matched an emitted error: drivers report content_filtered.
                test.eq(llm.ERROR_TYPE.CONTENT_FILTER, "content_filtered")
                test.eq(llm.ERROR_TYPE.NETWORK_ERROR, "network_error")
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

        describe("Caller Options Ownership", function()
            local function shallow_copy(t)
                local copy = {}
                for k, v in pairs(t) do
                    copy[k] = v
                end
                return copy
            end

            local function assert_unchanged(before, after)
                local before_count = 0
                for k, v in pairs(before) do
                    before_count = before_count + 1
                    test.eq(after[k], v, "caller option changed: " .. tostring(k))
                end

                local after_count = 0
                for _ in pairs(after) do
                    after_count = after_count + 1
                end
                test.eq(after_count, before_count, "caller options table gained or lost keys")
            end

            local questions = {
                resolved = { type = "predicate", instructions = "The customer considers the issue closed" }
            }

            it("should not write into the caller's options table in generate", function()
                local actor = assert(security.actor(), "test runner must install an ambient actor")
                local actor_id = actor:id()

                local options = { model = "gpt-4o", temperature = 0.4 }
                local before = shallow_copy(options)

                local result, err = llm.generate("Hello", options)

                test.is_nil(err)
                assert_unchanged(before, options)
                test.eq(mock_providers.last_generate_args.options.user, actor_id)
            end)

            it("should not write into the caller's options table in structured_output", function()
                local actor = assert(security.actor(), "test runner must install an ambient actor")
                local actor_id = actor:id()

                local schema = { type = "object", properties = { name = { type = "string" } } }
                local options = { model = "gpt-4o" }
                local before = shallow_copy(options)

                local result, err = llm.structured_output(schema, "Create person", options)

                test.is_nil(err)
                assert_unchanged(before, options)
                test.eq(mock_providers.last_structured_output_args.options.user, actor_id)
            end)

            it("should not write into the caller's options table in embed", function()
                local actor = assert(security.actor(), "test runner must install an ambient actor")
                local actor_id = actor:id()

                local options = { model = "text-embedding-3-small" }
                local before = shallow_copy(options)

                local result, err = llm.embed("Test text", options)

                test.is_nil(err)
                assert_unchanged(before, options)
                test.eq(mock_providers.last_embed_args.options.user, actor_id)
            end)

            it("should not write into the caller's options table in evaluate", function()
                local actor = assert(security.actor(), "test runner must install an ambient actor")
                local actor_id = actor:id()

                local options = { model = "jev" }
                local before = shallow_copy(options)

                local result, err = llm.evaluate("I was charged twice", questions, options)

                test.is_nil(err)
                assert_unchanged(before, options)
                test.eq(mock_providers.last_evaluate_args.options.user, actor_id)
            end)

            it("should not write into the caller's options table in status", function()
                local actor = assert(security.actor(), "test runner must install an ambient actor")
                local actor_id = actor:id()

                local options = { model = "gpt-4o" }
                local before = shallow_copy(options)

                local result, err = llm.status(options)

                test.is_nil(err)
                assert_unchanged(before, options)
                test.eq(mock_providers.last_status_args.options.user, actor_id)
            end)

            it("should reuse one caller options table across repeated calls", function()
                local options = { model = "gpt-4o" }
                local before = shallow_copy(options)

                local first_result, first_err = llm.generate("Hello", options)
                test.is_nil(first_err)
                assert_unchanged(before, options)

                local second_result, second_err = llm.generate("Hello again", options)
                test.is_nil(second_err)
                assert_unchanged(before, options)
            end)
        end)

        describe("Fallback chain", function()
            local cards
            local behaviour
            local opened
            local calls
            local resolutions

            local function answer(text: string, method: string): any
                local result: any = { content = text, tool_calls = {} }
                if method == "structured_output" then
                    result = { data = { answer = text } }
                elseif method == "embed" then
                    result = { embeddings = { { 0.1 } } }
                elseif method == "evaluate" then
                    result = { readings = { resolved = { type = "predicate", probability = 0.5 } } }
                end
                return {
                    success = true,
                    result = result,
                    tokens = { prompt_tokens = 3, completion_tokens = 2, total_tokens = 5 },
                    metadata = {}
                }
            end

            local function failure(error_type: string?, extra: { [string]: any }?): any
                local details: { [string]: any } = {}
                if error_type then
                    details.error_type = error_type
                end
                for key, value in pairs(extra or {}) do
                    details[key] = value
                end
                return errors.new({ message = tostring(error_type or "untyped") .. " failure", kind = errors.UNAVAILABLE, details = details })
            end

            local function fail_with(error_type: string?, extra: { [string]: any }?)
                return function()
                    return nil, failure(error_type, extra)
                end
            end

            local function card(name: string, routes: {any}, extra: { [string]: any }?): any
                local result: { [string]: any } = { id = "app.models:" .. name, name = name, capabilities = { "generate" }, providers = routes }
                for key, value in pairs(extra or {}) do
                    result[key] = value
                end
                return result
            end

            local function called_models(): string
                local names = {}
                for _, entry in ipairs(calls) do
                    table.insert(names, tostring(entry.args.model))
                end
                return table.concat(names, ",")
            end

            before_each(function()
                cards = {}
                behaviour = {}
                opened = {}
                calls = {}
                resolutions = {}
                llm._model_resolver = {
                    resolve = function(_, args)
                        table.insert(resolutions, args.model)
                        return cards[args.model]
                    end
                }
                mock_providers.open = function(provider_id, context)
                    table.insert(opened, { provider_id = provider_id, context = context })
                    if provider_id == "p.closed" then
                        return nil, "binding denied"
                    end
                    local instance = {}
                    for _, method in ipairs({ "generate", "structured_output", "embed", "evaluate" }) do
                        instance[method] = function(_, args)
                            table.insert(calls, { method = method, args = args, provider_id = provider_id })
                            local respond = behaviour[args.model]
                            if respond then
                                return respond(args)
                            end
                            return answer("from " .. tostring(args.model), method)
                        end
                    end
                    return instance
                end
            end)

            after_each(function()
                llm._clock = nil
            end)

            describe("switching", function()
                it("answers from the primary and reports the route", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } }, { fallback = { "backup" } })

                    local result, err = llm.generate("Hi", { model = "primary" })

                    test.is_nil(err)
                    test.eq(result.result, "from a-1")
                    test.eq(result.metadata.route.model, "primary")
                    test.eq(result.metadata.route.provider_id, "p.a")
                    test.eq(result.metadata.route.provider_model, "a-1")
                    test.is_nil(result.metadata.fallbacks)
                    test.eq(mock_usage_tracker.last_model_id, "primary")
                    test.eq(table.concat(resolutions, ","), "primary")
                end)

                it("falls back to the next model on a transient error and records why", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } }, { fallback = { "backup" } })
                    cards.backup = card("backup", { { id = "p.b", provider_model = "b-1" } })
                    behaviour["a-1"] = fail_with("rate_limit_exceeded")

                    local result, err = llm.generate("Hi", { model = "primary" })

                    test.is_nil(err)
                    test.eq(result.result, "from b-1")
                    test.eq(called_models(), "a-1,b-1")
                    test.eq(result.metadata.route.model, "backup")
                    test.eq(#result.metadata.fallbacks, 1)
                    local first = result.metadata.fallbacks[1]
                    test.eq(first.model, "primary")
                    test.eq(first.provider_id, "p.a")
                    test.eq(first.provider_model, "a-1")
                    test.eq(first.error_type, "rate_limit_exceeded")
                    test.eq(first.message, "rate_limit_exceeded failure")
                    test.eq(mock_usage_tracker.last_model_id, "backup")
                end)

                it("switches on every default transient type", function()
                    for _, error_type in ipairs({ "rate_limit_exceeded", "server_error", "timeout_error", "network_error" }) do
                        calls = {}
                        cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } }, { fallback = { "backup" } })
                        cards.backup = card("backup", { { id = "p.b", provider_model = "b-1" } })
                        behaviour["a-1"] = fail_with(error_type)
                        local result, err = llm.generate("Hi", { model = "primary" })
                        test.is_nil(err, error_type)
                        test.eq(result.result, "from b-1", error_type)
                    end
                end)

                it("tries the routes of the card by priority before fallback models", function()
                    cards.primary = card("primary", {
                        { id = "p.a", provider_model = "low", priority = 1 },
                        { id = "p.b", provider_model = "high", priority = 9 },
                    }, { fallback = { "backup" } })
                    cards.backup = card("backup", { { id = "p.c", provider_model = "c-1" } })
                    behaviour["high"] = fail_with("server_error")

                    local result, err = llm.generate("Hi", { model = "primary" })

                    test.is_nil(err)
                    test.eq(called_models(), "high,low")
                    test.eq(result.metadata.route.model, "primary")
                    test.eq(result.metadata.route.provider_model, "low")
                end)

                it("does not switch away from the primary on a request error", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } }, { fallback = { "backup" } })
                    cards.backup = card("backup", { { id = "p.b", provider_model = "b-1" } })
                    behaviour["a-1"] = fail_with("invalid_request")

                    local result, err = llm.generate("Hi", { model = "primary" })

                    test.is_nil(result)
                    test.eq(err, "invalid_request failure")
                    test.eq(called_models(), "a-1")
                end)

                it("does not switch on an error without a type", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } }, { fallback = { "backup" } })
                    cards.backup = card("backup", { { id = "p.b", provider_model = "b-1" } })
                    behaviour["a-1"] = function() return nil, errors.new("plain failure") end

                    local result, err = llm.generate("Hi", { model = "primary" })

                    test.is_nil(result)
                    test.eq(err, "plain failure")
                    test.eq(called_models(), "a-1")
                end)

                it("switches away from the primary on exactly the types its card lists", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } },
                        { fallback = { "backup" }, fallback_on = { "authentication_error" } })
                    cards.backup = card("backup", { { id = "p.b", provider_model = "b-1" } })

                    behaviour["a-1"] = fail_with("authentication_error")
                    local switched, switch_err = llm.generate("Hi", { model = "primary" })
                    test.is_nil(switch_err)
                    test.eq(switched.result, "from b-1")

                    calls = {}
                    behaviour["a-1"] = fail_with("server_error")
                    local stopped, stop_err = llm.generate("Hi", { model = "primary" })
                    test.is_nil(stopped)
                    test.eq(stop_err, "server_error failure")
                    test.eq(called_models(), "a-1")
                end)

                it("skips a fallback candidate that cannot serve the request", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } }, { fallback = { "backup", "third" } })
                    cards.backup = card("backup", { { id = "p.b", provider_model = "b-1" } })
                    cards.third = card("third", { { id = "p.c", provider_model = "c-1" } })
                    behaviour["a-1"] = fail_with("server_error")
                    behaviour["b-1"] = fail_with("authentication_error")

                    local result, err = llm.generate("Hi", { model = "primary" })

                    test.is_nil(err)
                    test.eq(result.result, "from c-1")
                    test.eq(called_models(), "a-1,b-1,c-1")
                    test.eq(#result.metadata.fallbacks, 2)
                    test.eq(result.metadata.fallbacks[2].error_type, "authentication_error")
                end)

                it("moves past fallback candidates on missing models and short context windows", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } }, { fallback = { "backup", "third", "fourth" } })
                    cards.backup = card("backup", { { id = "p.b", provider_model = "b-1" } })
                    cards.third = card("third", { { id = "p.c", provider_model = "c-1" } })
                    cards.fourth = card("fourth", { { id = "p.d", provider_model = "d-1" } })
                    behaviour["a-1"] = fail_with("timeout_error")
                    behaviour["b-1"] = fail_with("model_error")
                    behaviour["c-1"] = fail_with("context_length_exceeded")

                    local result, err = llm.generate("Hi", { model = "primary" })

                    test.is_nil(err)
                    test.eq(result.result, "from d-1")
                end)

                it("stops at a fallback candidate that rejects the request itself", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } }, { fallback = { "backup", "third" } })
                    cards.backup = card("backup", { { id = "p.b", provider_model = "b-1" } })
                    cards.third = card("third", { { id = "p.c", provider_model = "c-1" } })
                    behaviour["a-1"] = fail_with("server_error")
                    behaviour["b-1"] = fail_with("content_filtered")

                    local result, err = llm.generate("Hi", { model = "primary" })

                    test.is_nil(result)
                    test.eq(called_models(), "a-1,b-1")
                    test.eq(err, "content_filtered failure (fallback: primary via p.a: server_error; "
                        .. "backup via p.b: content_filtered)")
                end)

                it("reports every candidate when the chain runs out", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } }, { fallback = { "backup" } })
                    cards.backup = card("backup", { { id = "p.b", provider_model = "b-1" } })
                    behaviour["a-1"] = fail_with("server_error")
                    behaviour["b-1"] = fail_with("rate_limit_exceeded")

                    local result, err = llm.generate("Hi", { model = "primary" })

                    test.is_nil(result)
                    test.eq(err, "rate_limit_exceeded failure (fallback: primary via p.a: server_error; "
                        .. "backup via p.b: rate_limit_exceeded)")
                end)

                it("keeps the plain message when the primary was the only candidate", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } })
                    behaviour["a-1"] = fail_with("server_error")

                    local result, err = llm.generate("Hi", { model = "primary" })

                    test.is_nil(result)
                    test.eq(err, "server_error failure")
                end)
            end)

            describe("candidates", function()
                it("skips fallback references that do not resolve and records them", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } }, { fallback = { "missing", "backup" } })
                    cards.backup = card("backup", { { id = "p.b", provider_model = "b-1" } })
                    behaviour["a-1"] = fail_with("server_error")

                    local result, err = llm.generate("Hi", { model = "primary" })

                    test.is_nil(err)
                    test.eq(result.result, "from b-1")
                    local skipped = result.metadata.fallbacks[2]
                    test.eq(skipped.model, "missing")
                    test.is_true(skipped.skipped)
                    test.contains(skipped.message, "missing")
                end)

                it("resolves fallback references only when the chain reaches them", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } }, { fallback = { "backup", "third" } })
                    cards.backup = card("backup", { { id = "p.b", provider_model = "b-1" } })
                    cards.third = card("third", { { id = "p.c", provider_model = "c-1" } })
                    behaviour["a-1"] = fail_with("server_error")

                    local _, err = llm.generate("Hi", { model = "primary" })

                    test.is_nil(err)
                    test.eq(table.concat(resolutions, ","), "primary,backup")
                end)

                it("tries a card once and does not follow the fallback list of a fallback card", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } }, { fallback = { "backup", "primary" } })
                    cards.backup = card("backup", { { id = "p.b", provider_model = "b-1" } }, { fallback = { "third" } })
                    cards.third = card("third", { { id = "p.c", provider_model = "c-1" } })
                    behaviour["a-1"] = fail_with("server_error")
                    behaviour["b-1"] = fail_with("server_error")

                    local result, err = llm.generate("Hi", { model = "primary" })

                    test.is_nil(result)
                    test.not_nil(err)
                    test.eq(called_models(), "a-1,b-1")
                end)

                it("skips a class reference that resolves to the primary itself", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } }, { fallback = { "class:fast", "backup" } })
                    cards["class:fast"] = cards.primary
                    cards.backup = card("backup", { { id = "p.b", provider_model = "b-1" } })
                    behaviour["a-1"] = fail_with("server_error")

                    local result, err = llm.generate("Hi", { model = "primary" })

                    test.is_nil(err)
                    test.eq(called_models(), "a-1,b-1")
                    test.eq(#result.metadata.fallbacks, 1)
                end)

                it("caps the number of candidates per call", function()
                    cards.primary = card("primary", {
                        { id = "p.a", provider_model = "a-1" },
                        { id = "p.a", provider_model = "a-2" },
                        { id = "p.a", provider_model = "a-3" },
                    }, { fallback = { "backup" } })
                    cards.backup = card("backup", { { id = "p.b", provider_model = "b-1" }, { id = "p.b", provider_model = "b-2" } })
                    for _, model in ipairs({ "a-1", "a-2", "a-3", "b-1", "b-2" }) do
                        behaviour[model] = fail_with("server_error")
                    end

                    local result, err = llm.generate("Hi", { model = "primary" })

                    test.is_nil(result)
                    test.not_nil(err)
                    test.eq(called_models(), "a-1,a-2,a-3,b-1")
                end)

                it("uses the fallback list of the call over the card's", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } }, { fallback = { "backup" } })
                    cards.backup = card("backup", { { id = "p.b", provider_model = "b-1" } })
                    cards.third = card("third", { { id = "p.c", provider_model = "c-1" } })
                    behaviour["a-1"] = fail_with("server_error")

                    local result, err = llm.generate("Hi", { model = "primary", fallback = { "third" } })

                    test.is_nil(err)
                    test.eq(called_models(), "a-1,c-1")
                    test.eq(result.metadata.route.model, "third")
                end)

                it("disables fallback for the call, including other routes of the card", function()
                    cards.primary = card("primary", {
                        { id = "p.a", provider_model = "a-1" },
                        { id = "p.b", provider_model = "a-2" },
                    }, { fallback = { "backup" } })
                    cards.backup = card("backup", { { id = "p.c", provider_model = "b-1" } })
                    behaviour["a-1"] = fail_with("server_error")

                    local result, err = llm.generate("Hi", { model = "primary", fallback = false })

                    test.is_nil(result)
                    test.eq(err, "server_error failure")
                    test.eq(called_models(), "a-1")
                end)

                it("skips a fallback candidate whose provider cannot be opened", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } }, { fallback = { "backup", "third" } })
                    cards.backup = card("backup", { { id = "p.closed", provider_model = "b-1" } })
                    cards.third = card("third", { { id = "p.c", provider_model = "c-1" } })
                    behaviour["a-1"] = fail_with("server_error")

                    local result, err = llm.generate("Hi", { model = "primary" })

                    test.is_nil(err)
                    test.eq(result.result, "from c-1")
                    local skipped = result.metadata.fallbacks[2]
                    test.eq(skipped.model, "backup")
                    test.is_true(skipped.skipped)
                    test.eq(skipped.message, "Failed to open provider: binding denied")
                end)

                it("fails the call when the primary provider cannot be opened", function()
                    cards.primary = card("primary", { { id = "p.closed", provider_model = "a-1" } }, { fallback = { "backup" } })
                    cards.backup = card("backup", { { id = "p.b", provider_model = "b-1" } })

                    local result, err = llm.generate("Hi", { model = "primary" })

                    test.is_nil(result)
                    test.eq(err, "Failed to open provider: binding denied")
                    test.eq(#calls, 0)
                end)

                it("skips a fallback candidate whose route facts reject the call", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } }, { fallback = { "backup", "third" } })
                    cards.backup = card("backup", { { id = "p.b", provider_model = "b-1", sampling = false } })
                    cards.third = card("third", { { id = "p.c", provider_model = "c-1" } })
                    behaviour["a-1"] = fail_with("server_error")

                    local result, err = llm.generate("Hi", { model = "primary", temperature = 0.4, strict = true })

                    test.is_nil(err)
                    test.eq(called_models(), "a-1,c-1")
                    test.is_true(result.metadata.fallbacks[2].skipped)
                    test.contains(result.metadata.fallbacks[2].message, "temperature")
                end)
            end)

            describe("candidate isolation", function()
                it("opens each candidate with its own context and request defaults", function()
                    cards.primary = card("primary", { {
                        id = "p.a", provider_model = "a-1",
                        context = { api_key = "key-a", timeout = 30 }, options = { thinking_effort = 60 }
                    } }, { fallback = { "backup" } })
                    cards.backup = card("backup", { {
                        id = "p.b", provider_model = "b-1",
                        context = { api_key = "key-b" }, options = { temperature = 0.2 }
                    } })
                    behaviour["a-1"] = fail_with("server_error")

                    local _, err = llm.generate("Hi", { model = "primary", max_tokens = 100 })

                    test.is_nil(err)
                    test.eq(opened[1].context.api_key, "key-a")
                    test.eq(opened[2].context.api_key, "key-b")
                    test.eq(calls[1].args.options.thinking_effort, 60)
                    test.eq(calls[1].args.timeout, 30)
                    local backup_args = calls[2].args
                    test.is_nil(backup_args.options.thinking_effort)
                    test.is_nil(backup_args.timeout)
                    test.eq(backup_args.options.temperature, 0.2)
                    test.eq(backup_args.options.max_tokens, 100)
                    test.eq(backup_args._provider_id, "p.b")
                end)

                it("normalizes route facts for each candidate", function()
                    cards.primary = card("primary", { { id = "p.claude", provider_model = "claude-x", thinking = "adaptive", sampling = false } },
                        { fallback = { "backup" } })
                    cards.backup = card("backup", { { id = "p.gemini", provider_model = "gemini-x", thinking = "none" } })
                    behaviour["claude-x"] = fail_with("server_error")

                    local result, err = llm.generate("Hi", { model = "primary", temperature = 0.5, thinking_effort = 50 })

                    test.is_nil(err)
                    local primary_args = calls[1].args
                    test.eq(primary_args.accepts.thinking, "adaptive")
                    test.is_false(primary_args.accepts.sampling)
                    test.is_nil(primary_args.options.temperature)
                    test.eq(primary_args.options.thinking_effort, 50)
                    local backup_args = calls[2].args
                    test.eq(backup_args.accepts.thinking, "none")
                    test.is_nil(backup_args.accepts.sampling)
                    test.eq(backup_args.options.temperature, 0.5)
                    test.is_nil(backup_args.options.thinking_effort)
                    test.eq(result.metadata.adjusted.thinking_effort.requested, 50)
                    test.is_nil(result.metadata.adjusted.temperature)
                end)

                it("keeps call options away from the driver", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } })

                    local _, err = llm.generate("Hi", { model = "primary", fallback = { "backup" }, deadline_ms = 60000,
                        temperature = 0.3 })

                    test.is_nil(err)
                    local args = calls[1].args
                    test.is_nil(args.options.fallback)
                    test.is_nil(args.options.deadline_ms)
                    test.is_nil(args.options.route)
                    test.eq(args.options.temperature, 0.3)
                end)

                it("keeps call options away from a direct provider call", function()
                    local _, err = llm.generate("Hi", { model = "wire-model", provider_id = "p.direct",
                        fallback = { "backup" }, deadline_ms = 60000 })

                    test.is_nil(err)
                    local args = calls[1].args
                    test.eq(args.model, "wire-model")
                    test.is_nil(args.options.fallback)
                    test.is_nil(args.options.deadline_ms)
                    test.eq(args._provider_id, "p.direct")
                end)

                it("falls back for structured output with the schema on every candidate", function()
                    local schema = { type = "object", properties = { answer = { type = "string" } } }
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } }, { fallback = { "backup" } })
                    cards.backup = card("backup", { { id = "p.b", provider_model = "b-1" } })
                    behaviour["a-1"] = fail_with("server_error")

                    local result, err = llm.structured_output(schema, "Extract", { model = "primary" })

                    test.is_nil(err)
                    test.eq(result.result.answer, "from b-1")
                    test.eq(calls[2].args.schema, schema)
                    test.eq(calls[2].method, "structured_output")
                end)
            end)

            describe("streaming", function()
                local sent
                local stream = { reply_to = "pid-1", topic = "chat" }

                before_each(function()
                    sent = {}
                    mock("process.send", function(pid, topic, payload)
                        table.insert(sent, { pid = pid, topic = topic, payload = payload })
                        return true
                    end)
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } }, { fallback = { "backup" } })
                    cards.backup = card("backup", { { id = "p.b", provider_model = "b-1" } })
                end)

                it("falls back when the driver reports that nothing was sent", function()
                    behaviour["a-1"] = fail_with("server_error", { stream_started = false })

                    local result, err = llm.generate("Hi", { model = "primary", stream = stream })

                    test.is_nil(err)
                    test.eq(result.result, "from b-1")
                    test.eq(calls[2].args.stream.reply_to, "pid-1")
                    test.eq(#sent, 0)
                end)

                it("does not fall back once the stream started", function()
                    behaviour["a-1"] = fail_with("server_error", { stream_started = true })

                    local result, err = llm.generate("Hi", { model = "primary", stream = stream })

                    test.is_nil(result)
                    test.eq(err, "server_error failure")
                    test.eq(called_models(), "a-1")
                end)

                it("does not fall back when the driver does not report stream_started", function()
                    behaviour["a-1"] = fail_with("server_error")

                    local result, err = llm.generate("Hi", { model = "primary", stream = stream })

                    test.is_nil(result)
                    test.eq(called_models(), "a-1")
                end)

                it("emits the held-back error chunk when the whole call fails", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } })
                    behaviour["a-1"] = fail_with("server_error", { stream_started = false,
                        deferred_error_type = "Unavailable", deferred_error_message = "Overloaded" })

                    local result, err = llm.generate("Hi", { model = "primary", stream = stream })

                    test.is_nil(result)
                    test.eq(err, "server_error failure")
                    test.eq(#sent, 1)
                    test.eq(sent[1].pid, "pid-1")
                    test.eq(sent[1].topic, "chat")
                    test.eq(sent[1].payload.type, "error")
                    test.eq(sent[1].payload.error.type, "Unavailable")
                    test.eq(sent[1].payload.error.message, "Overloaded")
                end)

                it("does not emit a held-back chunk when a fallback answers", function()
                    behaviour["a-1"] = fail_with("server_error", { stream_started = false,
                        deferred_error_type = "Unavailable", deferred_error_message = "Overloaded" })

                    local result, err = llm.generate("Hi", { model = "primary", stream = stream })

                    test.is_nil(err)
                    test.not_nil(result)
                    test.eq(#sent, 0)
                end)

                it("emits only the held-back chunk of the last candidate", function()
                    behaviour["a-1"] = fail_with("server_error", { stream_started = false,
                        deferred_error_type = "Unavailable", deferred_error_message = "Overloaded" })
                    behaviour["b-1"] = fail_with("rate_limit_exceeded", { stream_started = false })

                    local result, err = llm.generate("Hi", { model = "primary", stream = stream })

                    test.is_nil(result)
                    test.not_nil(err)
                    test.eq(#sent, 0)
                end)

                it("emits the held-back chunk of a failed direct call", function()
                    behaviour["wire-model"] = fail_with("server_error", { stream_started = false,
                        deferred_error_type = "Unavailable", deferred_error_message = "Overloaded" })

                    local result, err = llm.generate("Hi", { model = "wire-model", provider_id = "p.direct", stream = stream })

                    test.is_nil(result)
                    test.eq(err, "server_error failure")
                    test.eq(#sent, 1)
                    test.eq(sent[1].payload.error.message, "Overloaded")
                end)
            end)

            describe("call budget", function()
                local clock_ms

                before_each(function()
                    clock_ms = 1000000
                    llm._clock = function() return clock_ms end
                end)

                it("caps the request timeout and passes the deadline to the provider", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1", context = { timeout = 600 } } })

                    local _, err = llm.generate("Hi", { model = "primary", deadline_ms = 30000 })

                    test.is_nil(err)
                    test.eq(calls[1].args.timeout, 30)
                    test.eq(opened[1].context.deadline_at, 1030000)
                end)

                it("leaves the request untouched without a budget", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1", context = { timeout = 600 } } })

                    local _, err = llm.generate("Hi", { model = "primary" })

                    test.is_nil(err)
                    test.eq(calls[1].args.timeout, 600)
                    test.is_nil(opened[1].context.deadline_at)
                end)

                it("gives a fallback candidate only the budget that is left", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } }, { fallback = { "backup" } })
                    cards.backup = card("backup", { { id = "p.b", provider_model = "b-1" } })
                    behaviour["a-1"] = function()
                        clock_ms = clock_ms + 20000
                        return nil, failure("server_error")
                    end

                    local _, err = llm.generate("Hi", { model = "primary", deadline_ms = 30000 })

                    test.is_nil(err)
                    test.eq(calls[2].args.timeout, 10)
                end)

                it("does not start a fallback candidate with too little budget left", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } }, { fallback = { "backup" } })
                    cards.backup = card("backup", { { id = "p.b", provider_model = "b-1" } })
                    behaviour["a-1"] = function()
                        clock_ms = clock_ms + 27000
                        return nil, failure("server_error")
                    end

                    local result, err = llm.generate("Hi", { model = "primary", deadline_ms = 30000 })

                    test.is_nil(result)
                    test.eq(called_models(), "a-1")
                    test.contains(err, "backup via p.b: skipped, call budget exhausted")
                end)

                it("applies the budget to a direct provider call", function()
                    local _, err = llm.generate("Hi", { model = "wire-model", provider_id = "p.direct", deadline_ms = 45000 })

                    test.is_nil(err)
                    test.eq(calls[1].args.timeout, 45)
                    test.eq(opened[1].context.deadline_at, 1045000)
                end)
            end)

            describe("pinned route", function()
                before_each(function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } }, { fallback = { "backup" } })
                    cards.backup = card("backup", {
                        { id = "p.b", provider_model = "b-1" },
                        { id = "p.b", provider_model = "b-2" },
                    }, { fallback = { "third" } })
                    cards.third = card("third", { { id = "p.c", provider_model = "c-1" } })
                end)

                it("calls exactly the pinned route", function()
                    local result, err = llm.generate("Hi", { model = "primary", route = { model = "backup", provider_id = "p.b" } })

                    test.is_nil(err)
                    test.eq(called_models(), "b-1")
                    test.eq(result.metadata.route.model, "backup")
                    test.eq(mock_usage_tracker.last_model_id, "backup")
                end)

                it("narrows the pinned route by provider model", function()
                    local result, err = llm.generate("Hi", { model = "primary",
                        route = { model = "backup", provider_id = "p.b", provider_model = "b-2" } })

                    test.is_nil(err)
                    test.eq(called_models(), "b-2")
                    test.eq(result.metadata.route.provider_model, "b-2")
                end)

                it("does not fall back from a pinned route", function()
                    behaviour["b-1"] = fail_with("server_error")

                    local result, err = llm.generate("Hi", { model = "primary", route = { model = "backup", provider_id = "p.b" } })

                    test.is_nil(result)
                    test.eq(err, "server_error failure")
                    test.eq(called_models(), "b-1")
                end)

                it("accepts the route metadata of a previous answer as the pin", function()
                    behaviour["a-1"] = fail_with("server_error")
                    local first, first_err = llm.generate("Hi", { model = "primary" })
                    test.is_nil(first_err)

                    calls = {}
                    local second, second_err = llm.generate("Again", { model = "primary", route = first.metadata.route })
                    test.is_nil(second_err)
                    test.eq(called_models(), "b-1")
                    test.eq(second.metadata.route.model, "backup")
                end)

                it("rejects an incomplete pin", function()
                    local result, err = llm.generate("Hi", { model = "primary", route = { model = "backup" } })

                    test.is_nil(result)
                    test.eq(err, "options.route requires model and provider_id")
                end)

                it("rejects a pin together with a direct provider call", function()
                    local result, err = llm.generate("Hi", { model = "wire-model", provider_id = "p.direct",
                        route = { model = "backup", provider_id = "p.b" } })

                    test.is_nil(result)
                    test.eq(err, "options.route cannot be combined with provider_id")
                    test.eq(#calls, 0)
                    test.eq(#opened, 0)
                end)

                it("reports a pinned route that does not exist", function()
                    local result, err = llm.generate("Hi", { model = "primary", route = { model = "backup", provider_id = "p.z" } })

                    test.is_nil(result)
                    test.eq(err, "Route not found: backup via p.z")
                end)
            end)

            describe("embeddings and evaluation", function()
                it("never falls back to another model for embeddings", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "embed-a" } },
                        { capabilities = { "embed" }, fallback = { "backup" } })
                    cards.backup = card("backup", { { id = "p.b", provider_model = "embed-b" } }, { capabilities = { "embed" } })
                    behaviour["embed-a"] = fail_with("server_error")

                    local result, err = llm.embed("text", { model = "primary" })

                    test.is_nil(result)
                    test.eq(err, "server_error failure")
                    test.eq(called_models(), "embed-a")
                end)

                it("moves between routes of the same embedding model", function()
                    cards.primary = card("primary", {
                        { id = "p.a", provider_model = "embed-a" },
                        { id = "p.b", provider_model = "embed-a-mirror" },
                    }, { capabilities = { "embed" }, dimensions = 256 })
                    behaviour["embed-a"] = fail_with("rate_limit_exceeded")

                    local result, err = llm.embed("text", { model = "primary" })

                    test.is_nil(err)
                    test.eq(called_models(), "embed-a,embed-a-mirror")
                    test.eq(result.model, "embed-a-mirror")
                    test.eq(calls[2].args.options.dimensions, 256)
                end)

                it("skips fallback models that do not declare the evaluate capability", function()
                    local questions = { resolved = { type = "predicate", instructions = "Closed" } }
                    cards.primary = card("primary", { { id = "p.a", provider_model = "eval-a" } },
                        { capabilities = { "evaluate" }, fallback = { "plain", "evaluator" } })
                    cards.plain = card("plain", { { id = "p.b", provider_model = "chat-b" } })
                    cards.evaluator = card("evaluator", { { id = "p.c", provider_model = "eval-c" } }, { capabilities = { "evaluate" } })
                    behaviour["eval-a"] = fail_with("server_error")

                    local result, err = llm.evaluate("text", questions, { model = "primary" })

                    test.is_nil(err)
                    test.eq(called_models(), "eval-a,eval-c")
                    test.eq(result.metadata.route.model, "evaluator")
                    local skipped = result.metadata.fallbacks[2]
                    test.eq(skipped.model, "plain")
                    test.is_true(skipped.skipped)
                end)
            end)

            describe("fallback_on", function()
                it("treats an empty list as the default set", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } },
                        { fallback = { "backup" }, fallback_on = {} })
                    cards.backup = card("backup", { { id = "p.b", provider_model = "b-1" } })

                    behaviour["a-1"] = fail_with("server_error")
                    local switched, switch_err = llm.generate("Hi", { model = "primary" })
                    test.is_nil(switch_err)
                    test.eq(switched.result, "from b-1")

                    calls = {}
                    behaviour["a-1"] = fail_with("authentication_error")
                    local stopped, stop_err = llm.generate("Hi", { model = "primary" })
                    test.is_nil(stopped)
                    test.eq(stop_err, "authentication_error failure")
                    test.eq(called_models(), "a-1")
                end)

                it("treats a list without usable entries as the default set", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } },
                        { fallback = { "backup" }, fallback_on = { 429, "" } })
                    cards.backup = card("backup", { { id = "p.b", provider_model = "b-1" } })
                    behaviour["a-1"] = fail_with("rate_limit_exceeded")

                    local result, err = llm.generate("Hi", { model = "primary" })

                    test.is_nil(err)
                    test.eq(result.result, "from b-1")
                end)
            end)

            describe("output limit", function()
                it("lowers max_tokens to the output limit of the card and reports it", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } }, { output_tokens = 4096 })

                    local result, err = llm.generate("Hi", { model = "primary", max_tokens = 8000 })

                    test.is_nil(err)
                    test.eq(calls[1].args.options.max_tokens, 4096)
                    test.eq(result.metadata.adjusted.max_tokens.requested, 8000)
                    test.eq(result.metadata.adjusted.max_tokens.sent, 4096)
                end)

                it("leaves max_tokens alone within the limit", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } }, { output_tokens = 4096 })

                    local result, err = llm.generate("Hi", { model = "primary", max_tokens = 1000 })

                    test.is_nil(err)
                    test.eq(calls[1].args.options.max_tokens, 1000)
                    test.is_nil(result.metadata.adjusted)
                end)

                it("leaves max_tokens alone when the card declares no output limit", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } }, { output_tokens = 0 })
                    cards.bare = card("bare", { { id = "p.b", provider_model = "b-1" } })

                    local first, first_err = llm.generate("Hi", { model = "primary", max_tokens = 8000 })
                    test.is_nil(first_err)
                    test.eq(calls[1].args.options.max_tokens, 8000)
                    test.is_nil(first.metadata.adjusted)

                    local second, second_err = llm.generate("Hi", { model = "bare", max_tokens = 8000 })
                    test.is_nil(second_err)
                    test.eq(calls[2].args.options.max_tokens, 8000)
                    test.is_nil(second.metadata.adjusted)
                end)

                it("applies the limit of each candidate", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } },
                        { output_tokens = 8000, fallback = { "backup" } })
                    cards.backup = card("backup", { { id = "p.b", provider_model = "b-1" } }, { output_tokens = 1000 })
                    behaviour["a-1"] = fail_with("server_error")

                    local result, err = llm.generate("Hi", { model = "primary", max_tokens = 5000 })

                    test.is_nil(err)
                    test.eq(calls[1].args.options.max_tokens, 5000)
                    test.eq(calls[2].args.options.max_tokens, 1000)
                    test.eq(result.metadata.adjusted.max_tokens.requested, 5000)
                    test.eq(result.metadata.adjusted.max_tokens.sent, 1000)
                end)

                it("caps the route default as well as the caller's value", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1", options = { max_tokens = 9000 } } },
                        { output_tokens = 4096 })

                    local _, err = llm.generate("Hi", { model = "primary" })

                    test.is_nil(err)
                    test.eq(calls[1].args.options.max_tokens, 4096)
                end)

                it("rejects a request above the limit under strict", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } }, { output_tokens = 4096 })

                    local result, err = llm.generate("Hi", { model = "primary", max_tokens = 8000, strict = true })

                    test.is_nil(result)
                    test.eq(err, "route p.a requires adjustments to: max_tokens")
                    test.eq(#calls, 0)
                end)

                it("skips a fallback candidate that would need the cap under strict", function()
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } },
                        { output_tokens = 8000, fallback = { "backup", "third" } })
                    cards.backup = card("backup", { { id = "p.b", provider_model = "b-1" } }, { output_tokens = 1000 })
                    cards.third = card("third", { { id = "p.c", provider_model = "c-1" } }, { output_tokens = 8000 })
                    behaviour["a-1"] = fail_with("server_error")

                    local result, err = llm.generate("Hi", { model = "primary", max_tokens = 5000, strict = true })

                    test.is_nil(err)
                    test.eq(called_models(), "a-1,c-1")
                    test.is_true(result.metadata.fallbacks[2].skipped)
                    test.contains(result.metadata.fallbacks[2].message, "max_tokens")
                end)

                it("caps structured output too", function()
                    local schema = { type = "object", properties = { answer = { type = "string" } } }
                    cards.primary = card("primary", { { id = "p.a", provider_model = "a-1" } }, { output_tokens = 4096 })

                    local result, err = llm.structured_output(schema, "Extract", { model = "primary", max_tokens = 8000 })

                    test.is_nil(err)
                    test.eq(calls[1].args.options.max_tokens, 4096)
                    test.eq(result.metadata.adjusted.max_tokens.sent, 4096)
                end)

                it("does not cap a direct provider call", function()
                    local _, err = llm.generate("Hi", { model = "wire-model", provider_id = "p.direct", max_tokens = 8000 })

                    test.is_nil(err)
                    test.eq(calls[1].args.options.max_tokens, 8000)
                end)
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
