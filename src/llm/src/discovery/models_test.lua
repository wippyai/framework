local models = require("models")

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

                expect(err).to_be_nil()
                expect(model).not_to_be_nil()
                expect(model.name).to_equal("gpt-4o")
                expect(model.title).to_equal("GPT-4o")
                expect(model.description).to_equal(
                    "Fast, intelligent, flexible GPT model with text and image input capabilities")
                expect(#model.capabilities).to_equal(4)
                expect(#model.class).to_equal(2)
                expect(model.priority).to_equal(100)
                expect(model.max_tokens).to_equal(128000)
                expect(model.output_tokens).to_equal(16384)
                expect(model.pricing.input).to_equal(2.5)
                expect(model.pricing.output).to_equal(10)
                expect(model.pricing.cached_input).to_equal(1.25)
                expect(#model.providers).to_equal(1)
                expect(model.providers[1].id).to_equal("wippy.llm.openai:provider")
                expect(model.providers[1].context.model).to_equal("gpt-4o-2024-11-20")
            end)

            it("should return error when model not found", function()
                local model, err = models.get_by_name("nonexistent-model")

                expect(model).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err:match("No model found")).not_to_be_nil()
            end)

            it("should return error when name is nil", function()
                local model, err = models.get_by_name(nil)

                expect(model).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err).to_equal("Model name is required")
            end)

            it("should include all model metadata in cards", function()
                local claude_model, err = models.get_by_name("claude-4-sonnet")

                expect(err).to_be_nil()
                expect(claude_model).not_to_be_nil()
                expect(claude_model.name).to_equal("claude-4-sonnet")
                expect(claude_model.title).to_equal("Claude 4 Sonnet")
                expect(claude_model.description).to_equal(
                    "High-performance model with exceptional reasoning and coding capabilities")
                expect(#claude_model.capabilities).to_equal(6)
                expect(#claude_model.class).to_equal(2)
                expect(claude_model.priority).to_equal(95)
                expect(claude_model.max_tokens).to_equal(200000)
                expect(claude_model.output_tokens).to_equal(8192)
                expect(claude_model.pricing.input).to_equal(3)
                expect(claude_model.pricing.output).to_equal(15)
                expect(#claude_model.providers).to_equal(1)
            end)
        end)

        describe("get_by_class", function()
            it("should get models by class sorted by priority", function()
                local chat_models, err = models.get_by_class("chat")

                expect(err).to_be_nil()
                expect(chat_models).not_to_be_nil()
                expect(#chat_models).to_equal(2) -- claude-4-sonnet and gpt-4o-mini

                -- Should be sorted by priority descending (claude=95, mini=80)
                expect(chat_models[1].name).to_equal("claude-4-sonnet")
                expect(chat_models[1].priority).to_equal(95)
                expect(chat_models[2].name).to_equal("gpt-4o-mini")
                expect(chat_models[2].priority).to_equal(80)
            end)

            it("should get models by multimodal class", function()
                local multimodal_models, err = models.get_by_class("multimodal")

                expect(err).to_be_nil()
                expect(multimodal_models).not_to_be_nil()
                expect(#multimodal_models).to_equal(2) -- gpt-4o and gpt-4o-mini

                -- Should be sorted by priority descending (gpt-4o=100, mini=80)
                expect(multimodal_models[1].name).to_equal("gpt-4o")
                expect(multimodal_models[1].priority).to_equal(100)
                expect(multimodal_models[2].name).to_equal("gpt-4o-mini")
                expect(multimodal_models[2].priority).to_equal(80)
            end)

            it("should return empty array for non-existent class", function()
                local models_list, err = models.get_by_class("nonexistent")

                expect(err).to_be_nil()
                expect(models_list).not_to_be_nil()
                expect(#models_list).to_equal(0)
            end)

            it("should return error when class name is nil", function()
                local models_list, err = models.get_by_class(nil)

                expect(models_list).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err).to_equal("Class name is required")
            end)

            it("should get models by coder class", function()
                local coder_models, err = models.get_by_class("coder")

                expect(err).to_be_nil()
                expect(coder_models).not_to_be_nil()
                expect(#coder_models).to_equal(1) -- only claude-4-sonnet
                expect(coder_models[1].name).to_equal("claude-4-sonnet")
                expect(coder_models[1].priority).to_equal(95)
            end)
        end)

        describe("get_all", function()
            it("should get all models", function()
                local all_models, err = models.get_all()

                expect(err).to_be_nil()
                expect(all_models).not_to_be_nil()
                expect(#all_models).to_equal(3)

                -- Check if models are sorted by name
                expect(all_models[1].name).to_equal("claude-4-sonnet")
                expect(all_models[2].name).to_equal("gpt-4o")
                expect(all_models[3].name).to_equal("gpt-4o-mini")

                -- Check that each model has complete information including pricing
                for _, model in ipairs(all_models) do
                    expect(model.id).not_to_be_nil()
                    expect(model.name).not_to_be_nil()
                    expect(model.title).not_to_be_nil()
                    expect(model.description).not_to_be_nil()
                    expect(model.max_tokens).not_to_be_nil()
                    expect(model.pricing).not_to_be_nil()
                    expect(model.providers).not_to_be_nil()
                    expect(#model.providers).to_be_greater_than(0)
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

                expect(all_models).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err:match("Registry error")).not_to_be_nil()
            end)
        end)

        describe("get_all_classes", function()
            it("should get all classes with basic info", function()
                local all_classes, err = models.get_all_classes()

                expect(err).to_be_nil()
                expect(all_classes).not_to_be_nil()
                expect(#all_classes).to_equal(4)

                -- Check if classes are sorted by name
                expect(all_classes[1].name).to_equal("chat")
                expect(all_classes[2].name).to_equal("coder")
                expect(all_classes[3].name).to_equal("frontier")
                expect(all_classes[4].name).to_equal("multimodal")

                -- Check class structure
                local chat_class = all_classes[1]
                expect(chat_class.id).to_equal("app.models:chat")
                expect(chat_class.name).to_equal("chat")
                expect(chat_class.title).to_equal("Conversational Models")
                expect(chat_class.description).to_equal(
                    "Models optimized for natural conversation and general assistance")

                local coder_class = all_classes[2]
                expect(coder_class.name).to_equal("coder")
                expect(coder_class.title).to_equal("Coding Models")
                expect(coder_class.description).to_equal(
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

                expect(all_classes).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err:match("Registry error")).not_to_be_nil()
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

                expect(err).to_be_nil()
                expect(all_classes).not_to_be_nil()
                expect(#all_classes).to_equal(0)
            end)
        end)

        describe("_build_model_card", function()
            it("should build model card from registry entry", function()
                local entry = model_entries[1] -- gpt-4o
                local model_card = models._build_model_card(entry)

                expect(model_card).not_to_be_nil()
                expect(model_card.id).to_equal("app.models:gpt-4o")
                expect(model_card.name).to_equal("gpt-4o")
                expect(model_card.title).to_equal("GPT-4o")
                expect(model_card.description).to_equal(
                    "Fast, intelligent, flexible GPT model with text and image input capabilities")
                expect(#model_card.capabilities).to_equal(4)
                expect(#model_card.class).to_equal(2)
                expect(model_card.priority).to_equal(100)
                expect(model_card.max_tokens).to_equal(128000)
                expect(model_card.output_tokens).to_equal(16384)
                expect(model_card.pricing.input).to_equal(2.5)
                expect(model_card.pricing.output).to_equal(10)
                expect(#model_card.providers).to_equal(1)
            end)

            it("should handle entry with minimal data", function()
                local minimal_entry = {
                    id = "test:minimal",
                    meta = {
                        name = "minimal-model"
                    }
                }

                local model_card = models._build_model_card(minimal_entry)

                expect(model_card).not_to_be_nil()
                expect(model_card.id).to_equal("test:minimal")
                expect(model_card.name).to_equal("minimal-model")
                expect(model_card.title).to_equal("")
                expect(model_card.description).to_equal("")
                expect(#model_card.capabilities).to_equal(0)
                expect(#model_card.class).to_equal(0)
                expect(model_card.priority).to_equal(0)
                expect(model_card.max_tokens).to_equal(0)
                expect(model_card.output_tokens).to_equal(0)
                expect(#model_card.pricing).to_equal(0)
                expect(#model_card.providers).to_equal(0)
            end)

            it("should return nil for nil entry", function()
                local model_card = models._build_model_card(nil)
                expect(model_card).to_be_nil()
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

                expect(model_card).not_to_be_nil()
                expect(model_card.dimensions).to_equal(1536)
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
