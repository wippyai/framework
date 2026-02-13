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
                    return (agent_entries :: any)[id]
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

            test.is_nil(err)
            test.not_nil(spec)
            test.eq(spec.id, "wippy.agents:basic_assistant")
            test.eq(spec.name, "Basic Assistant")
            test.eq(spec.description, "A simple, helpful assistant")
            test.eq(spec.model, "claude-3-7-sonnet")
            test.eq(spec.max_tokens, 4096)
            test.eq(spec.temperature, 0.7)

            -- Raw arrays without processing
            test.eq(#spec.traits, 1)
            test.eq(spec.traits[1], "Conversational")
            test.eq(#spec.tools, 1)
            test.eq(spec.tools[1], "wippy.tools:calculator")
            test.eq(#spec.memory, 2)
            test.eq(spec.memory[1], "wippy.memory:conversation_history")

            -- Context should be preserved
            test.not_nil(spec.context)
            test.eq(spec.context.workspace, "/tmp")
        end)

        it("should handle missing fields gracefully", function()
            local spec, err = agent_registry.get_by_id("wippy.agents:minimal")

            test.is_nil(err)
            test.not_nil(spec)
            test.eq(spec.id, "wippy.agents:minimal")
            test.eq(spec.name, "Minimal Agent")
            test.eq(spec.description, "") -- Default empty
            test.is_nil(spec.model)        -- Not set
            test.eq(spec.prompt, "You are a minimal agent.")

            -- Arrays default to empty
            test.eq(#spec.traits, 0)
            test.eq(#spec.tools, 0)
            test.eq(#spec.memory, 0)
            test.eq(#spec.delegates, 0)
            test.is_nil(next(spec.context)) -- Empty context
        end)

        it("should preserve delegates without processing", function()
            local spec, err = agent_registry.get_by_id("wippy.agents:coding_assistant")

            test.is_nil(err)
            test.not_nil(spec)
            test.eq(#spec.delegates, 1)
            test.eq(spec.delegates[1].id, "data-analyst-id")
            test.eq(spec.delegates[1].name, "to_data_analyst")
            test.eq(spec.delegates[1].rule, "Forward to this agent when data analysis questions are detected")
        end)

        it("should handle agent not found by ID", function()
            local spec, err = agent_registry.get_by_id("nonexistent")

            test.is_nil(spec)
            test.not_nil(err)
            test.not_nil(err:match("No agent found"))
        end)

        it("should validate entry is an agent when getting by ID", function()
            local spec, err = agent_registry.get_by_id("wippy.agents:non_agent_entry")

            test.is_nil(spec)
            test.not_nil(err)
            test.not_nil(err:match("Entry is not a gen1 agent"))
        end)

        it("should get raw agent spec by name", function()
            local spec, err = agent_registry.get_by_name("Basic Assistant")

            test.is_nil(err)
            test.not_nil(spec)
            test.eq(spec.name, "Basic Assistant")
            test.eq(spec.id, "wippy.agents:basic_assistant")

            -- Should be raw, unprocessed
            test.eq(#spec.traits, 1)
            test.eq(spec.traits[1], "Conversational")
        end)

        it("should handle agent not found by name", function()
            local spec, err = agent_registry.get_by_name("NonexistentAgent")

            test.is_nil(spec)
            test.not_nil(err)
            test.not_nil(err:match("No agent found with name"))
        end)

        it("should require parameter for get_by_id", function()
            local spec, err = agent_registry.get_by_id(nil :: string)

            test.is_nil(spec)
            test.eq(err, "Agent ID is required")
        end)

        it("should require parameter for get_by_name", function()
            local spec, err = agent_registry.get_by_name(nil :: string)

            test.is_nil(spec)
            test.eq(err, "Agent name is required")
        end)

        it("should list agents by class and return raw specs", function()
            local specs = agent_registry.list_by_class("assistant.coding")

            test.eq(#specs, 1)
            test.eq(specs[1].id, "wippy.agents:class_test")
            test.eq(specs[1].name, "Class Test Agent")
            test.eq(specs[1].prompt, "I can do coding and math.")
        end)

        it("should list agents by class with raw_entries option", function()
            local entries = agent_registry.list_by_class("assistant.coding", { raw_entries = true })

            test.eq(#entries, 1)
            test.eq(entries[1].id, "wippy.agents:class_test")
            test.eq(entries[1].kind, "registry.entry") -- Raw entry includes kind
            test.not_nil(entries[1].meta)
            test.not_nil(entries[1].data)
        end)

        it("should require class_name for list_by_class", function()
            local specs, err = agent_registry.list_by_class(nil :: string)

            test.is_nil(specs)
            test.eq(err, "class_name required")
        end)

        it("should handle empty class results", function()
            local specs = agent_registry.list_by_class("nonexistent.class")

            test.not_nil(specs)
            test.eq(#specs, 0)
        end)
    end)
end

return require("test").run_cases(define_tests)
