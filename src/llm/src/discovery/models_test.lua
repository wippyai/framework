local models = require("models")
local test = require("test")

local function define_tests()
    describe("Models Discovery Library", function()
        -- Sample registry entries for testing (corrected structure with data)
        local model_entries = {
            {
                id = "app.models:gpt-4o",
                kind = "registry.entry",
                name = "gpt-4o",
                meta = {
                    type = "llm.model",
                    name = "gpt-4o",
                    title = "GPT-4o",
                    comment = "Fast, intelligent, flexible GPT model with text and image input capabilities",
                    capabilities = { "tool_use", "vision", "generate", "structured_output" },
                    class = { "frontier", "multimodal" },
                    priority = 100,
                },
                data = {
                    max_tokens = 128000,
                    output_tokens = 16384,
                    pricing = {
                        cached_input = 1.25,
                        input = 2.5,
                        output = 10
                    },
                    providers = {
                        {
                            id = "wippy.llm.openai:provider",
                            context = {
                                model = "gpt-4o-2024-11-20"
                            }
                        }
                    }
                }
            },
            {
                id = "app.models:claude-4-sonnet",
                kind = "registry.entry",
                name = "claude-4-sonnet",
                meta = {
                    type = "llm.model",
                    name = "claude-4-sonnet",
                    title = "Claude 4 Sonnet",
                    comment = "High-performance model with exceptional reasoning and coding capabilities",
                    capabilities = { "tool_use", "vision", "thinking", "caching", "generate", "structured_output" },
                    class = { "coder", "chat" },
                    priority = 95,
                },
                data = {
                    max_tokens = 200000,
                    output_tokens = 8192,
                    pricing = {
                        input = 3,
                        output = 15
                    },
                    providers = {
                        {
                            id = "wippy.llm.providers:anthropic",
                            context = {
                                model = "claude-sonnet-4-20250514"
                            }
                        }
                    }
                }
            },
            {
                id = "app.models:gpt-4o-mini",
                kind = "registry.entry",
                name = "gpt-4o-mini",
                meta = {
                    type = "llm.model",
                    name = "gpt-4o-mini",
                    title = "GPT-4o Mini",
                    comment = "Fast, affordable small model for focused tasks",
                    capabilities = { "tool_use", "vision", "generate" },
                    class = { "chat", "multimodal" },
                    priority = 80,
                },
                data = {
                    max_tokens = 128000,
                    output_tokens = 16384,
                    pricing = {
                        input = 0.15,
                        output = 0.6
                    },
                    providers = {
                        {
                            id = "wippy.llm.openai:provider",
                            context = {
                                model = "gpt-4o-mini-2024-07-18"
                            }
                        }
                    }
                }
            }
        }

        local class_entries = {
            {
                id = "app.models:frontier",
                kind = "registry.entry",
                name = "frontier",
                meta = {
                    type = "llm.model.class",
                    name = "frontier",
                    title = "Frontier Models",
                    comment = "State-of-the-art models with advanced capabilities across all domains"
                }
            },
            {
                id = "app.models:coder",
                kind = "registry.entry",
                name = "coder",
                meta = {
                    type = "llm.model.class",
                    name = "coder",
                    title = "Coding Models",
                    comment = "Models optimized for programming, code generation, and technical tasks"
                }
            },
            {
                id = "app.models:chat",
                kind = "registry.entry",
                name = "chat",
                meta = {
                    type = "llm.model.class",
                    name = "chat",
                    title = "Conversational Models",
                    comment = "Models optimized for natural conversation and general assistance"
                }
            },
            {
                id = "app.models:multimodal",
                kind = "registry.entry",
                name = "multimodal",
                meta = {
                    type = "llm.model.class",
                    name = "multimodal",
                    title = "Vision Models",
                    comment = "Models optimized for understanding and processing images and visual content"
                }
            }
        }

        local all_entries = {}
        for _, entry in ipairs(model_entries) do
            table.insert(all_entries, entry)
        end
        for _, entry in ipairs(class_entries) do
            table.insert(all_entries, entry)
        end

        local mock_registry

        before_each(function()
            -- Create mock registry for testing
            mock_registry = {
                find = function(query)
                    local results = {}

                    -- Filter entries based on query criteria
                    for _, entry in ipairs(all_entries) do
                        local matches = true

                        -- Match on kind
                        if query[".kind"] and entry.kind ~= query[".kind"] then
                            matches = false
                        end

                        -- Match on meta.type
                        if query["meta.type"] and (not entry.meta or entry.meta.type ~= query["meta.type"]) then
                            matches = false
                        end

                        -- Match on meta.name
                        if query["meta.name"] and (not entry.meta or entry.meta.name ~= query["meta.name"]) then
                            matches = false
                        end

                        if matches then
                            table.insert(results, entry)
                        end
                    end

                    return results, nil
                end
            }

            -- Inject the mock registry
            models._registry = mock_registry
        end)

        after_each(function()
            -- Reset the registry after each test
            models._registry = require("registry")
        end)

        describe("get_by_name", function()
            it("should get a model by name", function()
                local model, err = models.get_by_name("gpt-4o")

                test.is_nil(err)
                test.not_nil(model)
                assert(model)
                test.eq(model.name, "gpt-4o")
                test.eq(model.title, "GPT-4o")
                test.eq(model.description,
                    "Fast, intelligent, flexible GPT model with text and image input capabilities")
                test.eq(#model.capabilities, 4)
                test.eq(#model.class, 2)
                test.eq(model.priority, 100)
                test.eq(model.max_tokens, 128000)
                test.eq(model.output_tokens, 16384)
                test.eq(model.pricing.input, 2.5)
                test.eq(model.pricing.output, 10)
                test.eq(model.pricing.cached_input, 1.25)
                test.eq(#model.providers, 1)
                local provider = assert(model.providers[1])
                test.eq(provider.id, "wippy.llm.openai:provider")
                test.eq(provider.context.model, "gpt-4o-2024-11-20")
            end)

            it("should return error when model not found", function()
                local model, err = models.get_by_name("nonexistent-model")

                test.is_nil(model)
                test.not_nil(err)
                test.not_nil(err:match("No model found"))
            end)

            it("should return error when name is nil", function()
                local model, err = models.get_by_name(nil)

                test.is_nil(model)
                test.not_nil(err)
                test.eq(err, "Model name is required")
            end)

            it("should include all model metadata in cards", function()
                local claude_model, err = models.get_by_name("claude-4-sonnet")

                test.is_nil(err)
                test.not_nil(claude_model)
                assert(claude_model)
                test.eq(claude_model.name, "claude-4-sonnet")
                test.eq(claude_model.title, "Claude 4 Sonnet")
                test.eq(claude_model.description,
                    "High-performance model with exceptional reasoning and coding capabilities")
                test.eq(#claude_model.capabilities, 6)
                test.eq(#claude_model.class, 2)
                test.eq(claude_model.priority, 95)
                test.eq(claude_model.max_tokens, 200000)
                test.eq(claude_model.output_tokens, 8192)
                test.eq(claude_model.pricing.input, 3)
                test.eq(claude_model.pricing.output, 15)
                test.eq(#claude_model.providers, 1)
            end)
        end)

        describe("get_by_class", function()
            it("should get models by class sorted by priority", function()
                local chat_models, err = models.get_by_class("chat")

                test.is_nil(err)
                assert(chat_models)
                test.eq(#chat_models, 2) -- claude-4-sonnet and gpt-4o-mini

                -- Should be sorted by priority descending (claude=95, mini=80)
                local first = assert(chat_models[1])
                local second = assert(chat_models[2])
                test.eq(first.name, "claude-4-sonnet")
                test.eq(first.priority, 95)
                test.eq(second.name, "gpt-4o-mini")
                test.eq(second.priority, 80)
            end)

            it("should get models by multimodal class", function()
                local multimodal_models, err = models.get_by_class("multimodal")

                test.is_nil(err)
                assert(multimodal_models)
                test.eq(#multimodal_models, 2) -- gpt-4o and gpt-4o-mini

                -- Should be sorted by priority descending (gpt-4o=100, mini=80)
                local first = assert(multimodal_models[1])
                local second = assert(multimodal_models[2])
                test.eq(first.name, "gpt-4o")
                test.eq(first.priority, 100)
                test.eq(second.name, "gpt-4o-mini")
                test.eq(second.priority, 80)
            end)

            it("should return empty array for non-existent class", function()
                local models_list, err = models.get_by_class("nonexistent")

                test.is_nil(err)
                test.not_nil(models_list)
                test.eq(#models_list, 0)
            end)

            it("should return error when class name is nil", function()
                local models_list, err = models.get_by_class(nil)

                test.is_nil(models_list)
                test.not_nil(err)
                test.eq(err, "Class name is required")
            end)

            it("should get models by coder class", function()
                local coder_models, err = models.get_by_class("coder")

                test.is_nil(err)
                assert(coder_models)
                test.eq(#coder_models, 1) -- only claude-4-sonnet
                local first = assert(coder_models[1])
                test.eq(first.name, "claude-4-sonnet")
                test.eq(first.priority, 95)
            end)
        end)

        describe("get_all", function()
            it("should get all models", function()
                local all_models, err = models.get_all()

                test.is_nil(err)
                assert(all_models)
                test.eq(#all_models, 3)

                -- Check if models are sorted by name
                local m1 = assert(all_models[1])
                local m2 = assert(all_models[2])
                local m3 = assert(all_models[3])
                test.eq(m1.name, "claude-4-sonnet")
                test.eq(m2.name, "gpt-4o")
                test.eq(m3.name, "gpt-4o-mini")

                -- Check that each model has complete information including pricing
                for _, model in ipairs(all_models) do
                    test.not_nil(model.id)
                    test.not_nil(model.name)
                    test.not_nil(model.title)
                    test.not_nil(model.description)
                    test.not_nil(model.max_tokens)
                    test.not_nil(model.pricing)
                    test.not_nil(model.providers)
                    test.gt(#model.providers, 0)
                end
            end)

            it("should handle registry error", function()
                -- Mock registry error
                models._registry = {
                    find = function(query)
                        return nil, "Registry connection failed"
                    end
                }

                local all_models, err = models.get_all()

                test.is_nil(all_models)
                test.not_nil(err)
                test.not_nil(err:match("Registry error"))
            end)
        end)

        describe("get_all_classes", function()
            it("should get all classes with basic info", function()
                local all_classes, err = models.get_all_classes()

                test.is_nil(err)
                test.not_nil(all_classes)
                test.eq(#all_classes, 4)

                -- Check if classes are sorted by name
                test.eq(all_classes[1].name, "chat")
                test.eq(all_classes[2].name, "coder")
                test.eq(all_classes[3].name, "frontier")
                test.eq(all_classes[4].name, "multimodal")

                -- Check class structure
                local chat_class = all_classes[1]
                test.eq(chat_class.id, "app.models:chat")
                test.eq(chat_class.name, "chat")
                test.eq(chat_class.title, "Conversational Models")
                test.eq(chat_class.description,
                    "Models optimized for natural conversation and general assistance")

                local coder_class = all_classes[2]
                test.eq(coder_class.name, "coder")
                test.eq(coder_class.title, "Coding Models")
                test.eq(coder_class.description,
                    "Models optimized for programming, code generation, and technical tasks")
            end)

            it("should handle registry error", function()
                -- Mock registry error
                models._registry = {
                    find = function(query)
                        return nil, "Registry connection failed"
                    end
                }

                local all_classes, err = models.get_all_classes()

                test.is_nil(all_classes)
                test.not_nil(err)
                test.not_nil(err:match("Registry error"))
            end)

            it("should return empty array when no classes exist", function()
                -- Mock registry with no classes
                models._registry = {
                    find = function(query)
                        if query["meta.type"] == "llm.model.class" then
                            return {}, nil
                        end
                        return all_entries, nil
                    end
                }

                local all_classes, err = models.get_all_classes()

                test.is_nil(err)
                test.not_nil(all_classes)
                test.eq(#all_classes, 0)
            end)
        end)

        describe("_build_model_card", function()
            it("should build model card from registry entry", function()
                local entry = model_entries[1] -- gpt-4o
                local model_card = models._build_model_card(entry)

                test.not_nil(model_card)
                test.eq(model_card.id, "app.models:gpt-4o")
                test.eq(model_card.name, "gpt-4o")
                test.eq(model_card.title, "GPT-4o")
                test.eq(model_card.description,
                    "Fast, intelligent, flexible GPT model with text and image input capabilities")
                test.eq(#model_card.capabilities, 4)
                test.eq(#model_card.class, 2)
                test.eq(model_card.priority, 100)
                test.eq(model_card.max_tokens, 128000)
                test.eq(model_card.output_tokens, 16384)
                test.eq(model_card.pricing.input, 2.5)
                test.eq(model_card.pricing.output, 10)
                test.eq(#model_card.providers, 1)
            end)

            it("should handle entry with minimal data", function()
                local minimal_entry = {
                    id = "test:minimal",
                    meta = {
                        name = "minimal-model"
                    }
                }

                local model_card = models._build_model_card(minimal_entry)

                test.not_nil(model_card)
                test.eq(model_card.id, "test:minimal")
                test.eq(model_card.name, "minimal-model")
                test.eq(model_card.title, "")
                test.eq(model_card.description, "")
                test.eq(#model_card.capabilities, 0)
                test.eq(#model_card.class, 0)
                test.eq(model_card.priority, 0)
                test.eq(model_card.max_tokens, 0)
                test.eq(model_card.output_tokens, 0)
                test.eq(#model_card.pricing, 0)
                test.eq(#model_card.providers, 0)
            end)

            it("should return nil for nil entry", function()
                local model_card = models._build_model_card(nil)
                test.is_nil(model_card)
            end)

            it("should handle entry with dimensions field", function()
                local embedding_entry = {
                    id = "test:embedding",
                    meta = {
                        name = "test-embedding"
                    },
                    data = {
                        dimensions = 1536
                    }
                }

                local model_card = models._build_model_card(embedding_entry)

                test.not_nil(model_card)
                test.eq(model_card.dimensions, 1536)
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
