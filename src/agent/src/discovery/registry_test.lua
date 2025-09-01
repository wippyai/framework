local agent_registry = require("agent_registry")

local function define_tests()
    describe("Agent Registry (Simplified)", function()
        -- Sample agent registry entries for testing
        local agent_entries = {
            ["wippy.agents:basic_assistant"] = {
                id = "wippy.agents:basic_assistant",
                kind = "registry.entry",
                meta = {
                    type = "agent.gen1",
                    name = "Basic Assistant",
                    comment = "A simple, helpful assistant"
                },
                data = {
                    model = "claude-3-7-sonnet",
                    prompt = "You are a helpful assistant that provides concise, accurate answers.",
                    max_tokens = 4096,
                    temperature = 0.7,
                    traits = { "Conversational" },
                    tools = { "wippy.tools:calculator" },
                    memory = { "wippy.memory:conversation_history", "file://memory/general_knowledge.txt" },
                    context = { workspace = "/tmp" }
                }
            },
            ["wippy.agents:coding_assistant"] = {
                id = "wippy.agents:coding_assistant",
                kind = "registry.entry",
                meta = {
                    type = "agent.gen1",
                    name = "Coding Assistant",
                    comment = "Specialized assistant for programming tasks"
                },
                data = {
                    model = "gpt-4o",
                    prompt = "You are a coding assistant specialized in helping with programming tasks.",
                    max_tokens = 8192,
                    temperature = 0.5,
                    traits = { "Thinking Tag (User)", "wippy.traits:search_capability" },
                    tools = { "wippy.tools:code_interpreter" },
                    memory = { "file://memory/coding_best_practices.txt" },
                    delegates = {
                        {
                            id = "data-analyst-id",
                            name = "to_data_analyst",
                            rule = "Forward to this agent when data analysis questions are detected"
                        }
                    }
                }
            },
            ["wippy.agents:minimal"] = {
                id = "wippy.agents:minimal",
                kind = "registry.entry",
                meta = {
                    type = "agent.gen1",
                    name = "Minimal Agent"
                },
                data = {
                    prompt = "You are a minimal agent."
                }
            },
            ["wippy.agents:class_test"] = {
                id = "wippy.agents:class_test",
                kind = "registry.entry",
                meta = {
                    type = "agent.gen1",
                    name = "Class Test Agent",
                    class = { "assistant.coding", "assistant.math" }
                },
                data = {
                    prompt = "I can do coding and math."
                }
            },
            ["wippy.agents:non_agent_entry"] = {
                id = "wippy.agents:non_agent_entry",
                kind = "registry.entry",
                meta = {
                    type = "something.else",
                    name = "Not An Agent"
                },
                data = { some_field = "some value" }
            }
        }

        local mock_registry

        before_each(function()
            mock_registry = {
                get = function(id)
                    return agent_entries[id]
                end,
                find = function(query)
                    local results = {}
                    for _, entry in pairs(agent_entries) do
                        local matches = true

                        if query[".kind"] and entry.kind ~= query[".kind"] then
                            matches = false
                        end
                        if query["meta.type"] and (not entry.meta or entry.meta.type ~= query["meta.type"]) then
                            matches = false
                        end
                        if query["meta.name"] and (not entry.meta or entry.meta.name ~= query["meta.name"]) then
                            matches = false
                        end

                        if matches then
                            table.insert(results, entry)
                        end
                    end
                    return results
                end
            }

            agent_registry._registry = mock_registry
        end)

        after_each(function()
            agent_registry._registry = nil
        end)

        it("should get raw agent spec by ID", function()
            local spec, err = agent_registry.get_by_id("wippy.agents:basic_assistant")

            expect(err).to_be_nil()
            expect(spec).not_to_be_nil()
            expect(spec.id).to_equal("wippy.agents:basic_assistant")
            expect(spec.name).to_equal("Basic Assistant")
            expect(spec.description).to_equal("A simple, helpful assistant")
            expect(spec.model).to_equal("claude-3-7-sonnet")
            expect(spec.max_tokens).to_equal(4096)
            expect(spec.temperature).to_equal(0.7)

            -- Raw arrays without processing
            expect(#spec.traits).to_equal(1)
            expect(spec.traits[1]).to_equal("Conversational")
            expect(#spec.tools).to_equal(1)
            expect(spec.tools[1]).to_equal("wippy.tools:calculator")
            expect(#spec.memory).to_equal(2)
            expect(spec.memory[1]).to_equal("wippy.memory:conversation_history")

            -- Context should be preserved
            expect(spec.context).not_to_be_nil()
            expect(spec.context.workspace).to_equal("/tmp")
        end)

        it("should handle missing fields gracefully", function()
            local spec, err = agent_registry.get_by_id("wippy.agents:minimal")

            expect(err).to_be_nil()
            expect(spec).not_to_be_nil()
            expect(spec.id).to_equal("wippy.agents:minimal")
            expect(spec.name).to_equal("Minimal Agent")
            expect(spec.description).to_equal("") -- Default empty
            expect(spec.model).to_be_nil()        -- Not set
            expect(spec.prompt).to_equal("You are a minimal agent.")

            -- Arrays default to empty
            expect(#spec.traits).to_equal(0)
            expect(#spec.tools).to_equal(0)
            expect(#spec.memory).to_equal(0)
            expect(#spec.delegates).to_equal(0)
            expect(next(spec.context)).to_be_nil() -- Empty context
        end)

        it("should preserve delegates without processing", function()
            local spec, err = agent_registry.get_by_id("wippy.agents:coding_assistant")

            expect(err).to_be_nil()
            expect(spec).not_to_be_nil()
            expect(#spec.delegates).to_equal(1)
            expect(spec.delegates[1].id).to_equal("data-analyst-id")
            expect(spec.delegates[1].name).to_equal("to_data_analyst")
            expect(spec.delegates[1].rule).to_equal("Forward to this agent when data analysis questions are detected")
        end)

        it("should handle agent not found by ID", function()
            local spec, err = agent_registry.get_by_id("nonexistent")

            expect(spec).to_be_nil()
            expect(err).not_to_be_nil()
            expect(err:match("No agent found")).not_to_be_nil()
        end)

        it("should validate entry is an agent when getting by ID", function()
            local spec, err = agent_registry.get_by_id("wippy.agents:non_agent_entry")

            expect(spec).to_be_nil()
            expect(err).not_to_be_nil()
            expect(err:match("Entry is not a gen1 agent")).not_to_be_nil()
        end)

        it("should get raw agent spec by name", function()
            local spec, err = agent_registry.get_by_name("Basic Assistant")

            expect(err).to_be_nil()
            expect(spec).not_to_be_nil()
            expect(spec.name).to_equal("Basic Assistant")
            expect(spec.id).to_equal("wippy.agents:basic_assistant")

            -- Should be raw, unprocessed
            expect(#spec.traits).to_equal(1)
            expect(spec.traits[1]).to_equal("Conversational")
        end)

        it("should handle agent not found by name", function()
            local spec, err = agent_registry.get_by_name("NonexistentAgent")

            expect(spec).to_be_nil()
            expect(err).not_to_be_nil()
            expect(err:match("No agent found with name")).not_to_be_nil()
        end)

        it("should require parameter for get_by_id", function()
            local spec, err = agent_registry.get_by_id(nil)

            expect(spec).to_be_nil()
            expect(err).to_equal("Agent ID is required")
        end)

        it("should require parameter for get_by_name", function()
            local spec, err = agent_registry.get_by_name(nil)

            expect(spec).to_be_nil()
            expect(err).to_equal("Agent name is required")
        end)

        it("should list agents by class and return raw specs", function()
            local specs = agent_registry.list_by_class("assistant.coding")

            expect(#specs).to_equal(1)
            expect(specs[1].id).to_equal("wippy.agents:class_test")
            expect(specs[1].name).to_equal("Class Test Agent")
            expect(specs[1].prompt).to_equal("I can do coding and math.")
        end)

        it("should list agents by class with raw_entries option", function()
            local entries = agent_registry.list_by_class("assistant.coding", { raw_entries = true })

            expect(#entries).to_equal(1)
            expect(entries[1].id).to_equal("wippy.agents:class_test")
            expect(entries[1].kind).to_equal("registry.entry") -- Raw entry includes kind
            expect(entries[1].meta).not_to_be_nil()
            expect(entries[1].data).not_to_be_nil()
        end)

        it("should require class_name for list_by_class", function()
            local specs, err = agent_registry.list_by_class(nil)

            expect(specs).to_be_nil()
            expect(err).to_equal("class_name required")
        end)

        it("should handle empty class results", function()
            local specs = agent_registry.list_by_class("nonexistent.class")

            expect(specs).not_to_be_nil()
            expect(#specs).to_equal(0)
        end)
    end)
end

return require("test").run_cases(define_tests)
