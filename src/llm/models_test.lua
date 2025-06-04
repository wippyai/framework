local models = require("models")

local function define_tests()
    describe("Models Library", function()
        -- Sample model registry entries for testing
        -- Structure matches the actual registry entries with "data" field
        local model_entries = {
            ["gpt-4o"] = {
                id = "wippy.llm:gpt-4o",
                kind = "registry.entry",
                meta = {
                    type = "llm.model",
                    name = "gpt-4o",
                    comment = "Fast, intelligent, flexible GPT model with text and image input capabilities",
                    capabilities = { "tool_use", "vision" }
                },
                data = {
                    provider_model = "gpt-4o-2024-11-20",
                    max_tokens = 128000,
                    output_tokens = 16384,
                    pricing = {
                        input = 2.50,
                        output = 10.00,
                        cached_input = 1.25
                    },
                    handlers = {
                        generate = "wippy.llm.openai:text_generation",
                        structured_output = "wippy.llm.openai:structured_output",
                        call_tools = "wippy.llm.openai:tool_calling"
                    }
                }
            },
            ["claude-3-7-sonnet"] = {
                id = "wippy.llm:claude-3-7-sonnet",
                kind = "registry.entry",
                meta = {
                    type = "llm.model",
                    name = "claude-3-7-sonnet",
                    comment = "Anthropic's most intelligent model with extended thinking capabilities",
                    capabilities = { "tool_use", "vision", "thinking", "caching" }
                },
                data = {
                    provider_model = "claude-3-7-sonnet-20250219",
                    max_tokens = 200000,
                    output_tokens = 4096,
                    pricing = {
                        input = 3.00,
                        output = 15.00
                    },
                    handlers = {
                        generate = "wippy.llm.claude:text_generation",
                        structured_output = "wippy.llm.claude:structured_output",
                        call_tools = "wippy.llm.claude:tool_calling"
                    }
                }
            },
            ["text-embedding-3-large"] = {
                id = "wippy.llm:text-embedding-3-large",
                kind = "registry.entry",
                meta = {
                    type = "llm.embedding",
                    name = "text-embedding-3-large",
                    comment = "Most powerful embedding model for highest accuracy",
                    capabilities = { "multilingual" }
                },
                data = {
                    provider_model = "text-embedding-3-large",
                    dimensions = 3072,
                    max_tokens = 8191,
                    mteb_performance = 64.6,
                    knowledge_cutoff = "September 2021",
                    model_family = "third-generation",
                    pricing = {
                        input = 0.13,
                        pages_per_dollar = 9615
                    },
                    handlers = {
                        embeddings = "wippy.llm.openai:embeddings"
                    }
                }
            }
        }

        local mock_registry

        before_each(function()
            -- Create mock registry for testing
            mock_registry = {
                find = function(query)
                    local results = {}

                    -- If query is looking for all registry entries
                    if query and query[".kind"] == "registry.entry" and not query["meta.name"] then
                        for _, entry in pairs(model_entries) do
                            table.insert(results, entry)
                        end
                        return results
                    end

                    -- If query is looking for a specific model by name
                    for _, entry in pairs(model_entries) do
                        local matches = true

                        -- Match on kind
                        if query[".kind"] and entry.kind ~= query[".kind"] then
                            matches = false
                        end

                        -- Match on name (default checks meta.name)
                        if query["meta.name"] and entry.meta.name ~= query["meta.name"] then
                            matches = false
                        end

                        if matches then
                            table.insert(results, entry)
                        end
                    end

                    return results
                end
            }

            -- Directly inject the mock registry into the models library
            models._registry = mock_registry
        end)

        after_each(function()
            -- Reset the registry module after each test
            models._registry = nil
        end)

        it("should get a model by name", function()
            local model, err = models.get_by_name("gpt-4o")

            expect(err).to_be_nil()
            expect(model).not_to_be_nil()
            expect(model.name).to_equal("gpt-4o")
            expect(model.provider_model).to_equal("gpt-4o-2024-11-20")
            expect(#model.capabilities).to_equal(2)
            expect(model.max_tokens).to_equal(128000)
            expect(model.output_tokens).to_equal(16384)
            expect(model.pricing.input).to_equal(2.50)
            expect(model.pricing.output).to_equal(10.00)
            expect(model.handlers.generate).to_equal("wippy.llm.openai:text_generation")
        end)

        it("should return error when model not found", function()
            local model, err = models.get_by_name("nonexistent-model")

            expect(model).to_be_nil()
            expect(err).not_to_be_nil()
            expect(err:match("No model found")).not_to_be_nil()
        end)

        it("should include all model metadata in cards", function()
            local embedding_model, err = models.get_by_name("text-embedding-3-large")

            expect(err).to_be_nil()
            expect(embedding_model).not_to_be_nil()
            expect(embedding_model.dimensions).to_equal(3072)
            expect(embedding_model.mteb_performance).to_equal(64.6)
            expect(embedding_model.model_family).to_equal("third-generation")
            expect(embedding_model.knowledge_cutoff).to_equal("September 2021")
            expect(embedding_model.pricing.input).to_equal(0.13)
            expect(embedding_model.pricing.pages_per_dollar).to_equal(9615)
        end)

        it("should properly include handlers in model cards", function()
            local claude_model, err = models.get_by_name("claude-3-7-sonnet")

            expect(err).to_be_nil()
            expect(claude_model).not_to_be_nil()
            expect(claude_model.handlers.generate).to_equal("wippy.llm.claude:text_generation")
            expect(claude_model.handlers.structured_output).to_equal("wippy.llm.claude:structured_output")
            expect(claude_model.handlers.call_tools).to_equal("wippy.llm.claude:tool_calling")
        end)

        it("should get all models", function()
            local all_models = models.get_all()

            expect(#all_models).to_equal(3)

            -- Check if models are sorted by name
            expect(all_models[1].name).to_equal("claude-3-7-sonnet")
            expect(all_models[2].name).to_equal("gpt-4o")
            expect(all_models[3].name).to_equal("text-embedding-3-large")

            -- Check that each model has complete information
            for _, model in ipairs(all_models) do
                expect(model.id).not_to_be_nil()
                expect(model.name).not_to_be_nil()
                expect(model.description).not_to_be_nil()
                expect(model.max_tokens).not_to_be_nil()
                expect(model.pricing).not_to_be_nil()
            end
        end)

        it("should group models by provider", function()
            local grouped = models.get_by_provider()

            expect(#grouped).to_equal(2) -- openai and claude providers

            -- Find the openai provider group
            local openai_group
            local claude_group

            for _, group in ipairs(grouped) do
                if group.name == "openai" then
                    openai_group = group
                elseif group.name == "claude" then
                    claude_group = group
                end
            end

            expect(openai_group).not_to_be_nil()
            expect(claude_group).not_to_be_nil()

            -- Check OpenAI models
            expect(#openai_group.models).to_equal(2) -- gpt-4o and text-embedding-3-large

            -- Check Claude models
            expect(#claude_group.models).to_equal(1) -- claude-3-7-sonnet
            expect(claude_group.models[1].name).to_equal("claude-3-7-sonnet")
        end)
    end)
end

return require("test").run_cases(define_tests)
