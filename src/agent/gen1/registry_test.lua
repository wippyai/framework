local agent_registry = require("agent_registry")
local traits = require("traits")

local function define_tests()
    describe("Agent Registry", function()
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
                    traits = {
                        "Conversational"
                    },
                    tools = {
                        "wippy.tools:calculator"
                    },
                    memory = {
                        "wippy.memory:conversation_history",
                        "file://memory/general_knowledge.txt"
                    }
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
                    traits = {
                        "Thinking Tag (User)"
                    },
                    tools = {
                        "wippy.tools:code_interpreter"
                    },
                    memory = {
                        "file://memory/coding_best_practices.txt"
                    },
                    inherit = {
                        "wippy.agents:basic_assistant"
                    }
                }
            },
            ["wippy.agents:code_tools"] = {
                id = "wippy.agents:code_tools",
                kind = "registry.entry",
                meta = {
                    type = "agent.gen1",
                    name = "Code Tools",
                    comment = "Collection of code-related tools for agents"
                },
                data = {
                    tools = {
                        "wippy.tools:git_helper",
                        "wippy.tools:linter"
                    }
                }
            },
            ["wippy.agents:advanced_assistant"] = {
                id = "wippy.agents:advanced_assistant",
                kind = "registry.entry",
                meta = {
                    type = "agent.gen1",
                    name = "Advanced Assistant",
                    comment = "Advanced assistant with extensive tools"
                },
                data = {
                    model = "claude-3-7-sonnet",
                    prompt = "You are an advanced assistant with extensive capabilities.",
                    max_tokens = 8192,
                    temperature = 0.6,
                    traits = {
                        "Multilingual"
                    },
                    tools = {
                        "wippy.tools:knowledge_base"
                    },
                    delegate = {
                        ["wippy.agents:code_tools"] = {
                            name = "to_code_tools",
                            rule = "Forward to this agent when coding help is needed"
                        }
                    },
                    inherit = {
                        "wippy.agents:coding_assistant"
                    }
                }
            },
            ["wippy.agents:non_agent_entry"] = {
                id = "wippy.agents:non_agent_entry",
                kind = "registry.entry",
                meta = {
                    type = "something.else",
                    name = "Not An Agent",
                    comment = "This is not an agent entry."
                },
                data = {
                    some_field = "some value"
                }
            }
        }

        -- Sample trait entries for testing
        local trait_entries = {
            ["wippy.agents:conversational"] = {
                id = "wippy.agents:conversational",
                kind = "registry.entry",
                meta = {
                    type = "agent.trait",
                    name = "Conversational",
                    comment = "Trait that makes agents conversational and friendly."
                },
                data = {
                    prompt = "You are a friendly, conversational assistant.\nAlways respond in a natural, engaging way."
                }
            },
            ["wippy.agents:thinking_tag_user"] = {
                id = "wippy.agents:thinking_tag_user",
                kind = "registry.entry",
                meta = {
                    type = "agent.trait",
                    name = "Thinking Tag (User)",
                    comment = "Trait that adds structured thinking tags for user visibility."
                },
                data = {
                    prompt = "When tackling complex problems, use <thinking> tags to show your reasoning process."
                }
            },
            ["wippy.agents:multilingual"] = {
                id = "wippy.agents:multilingual",
                kind = "registry.entry",
                meta = {
                    type = "agent.trait",
                    name = "Multilingual",
                    comment = "Trait that adds multilingual capabilities."
                },
                data = {
                    prompt = "You can respond in the same language the user uses to communicate with you."
                }
            }
        }

        local mock_registry
        local mock_traits

        before_each(function()
            -- Create mock registry for testing
            mock_registry = {
                get = function(id)
                    return agent_entries[id] or trait_entries[id]
                end,
                find = function(query)
                    local results = {}

                    local source = nil

                    -- Determine which collection to search based on meta.type
                    if query["meta.type"] == "agent.gen1" then
                        source = agent_entries
                    elseif query["meta.type"] == "agent.trait" then
                        source = trait_entries
                    else
                        -- If no specific type is requested, search in all entries
                        source = {}
                        for k, v in pairs(agent_entries) do
                            source[k] = v
                        end
                        for k, v in pairs(trait_entries) do
                            source[k] = v
                        end
                    end

                    for _, entry in pairs(source) do
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

                    return results
                end
            }

            -- Create mock traits library
            mock_traits = {
                get_by_name = function(name)
                    for _, entry in pairs(trait_entries) do
                        if entry.meta and entry.meta.name == name then
                            return {
                                id = entry.id,
                                name = entry.meta.name,
                                description = entry.meta.comment,
                                prompt = entry.data.prompt
                            }
                        end
                    end
                    return nil, "No trait found with name: " .. name
                end,
                get_all = function()
                    local result = {}
                    for _, entry in pairs(trait_entries) do
                        table.insert(result, {
                            id = entry.id,
                            name = entry.meta.name,
                            description = entry.meta.comment,
                            prompt = entry.data.prompt
                        })
                    end
                    return result
                end
            }

            -- Inject mock dependencies
            agent_registry._registry = mock_registry
            agent_registry._traits = mock_traits
        end)

        after_each(function()
            -- Reset the injected dependencies
            agent_registry._registry = nil
            agent_registry._traits = nil
        end)

        it("should get an agent by ID", function()
            local agent, err = agent_registry.get_by_id("wippy.agents:basic_assistant")

            expect(err).to_be_nil()
            expect(agent).not_to_be_nil()
            expect(agent.id).to_equal("wippy.agents:basic_assistant")
            expect(agent.name).to_equal("Basic Assistant")
            expect(agent.description).to_equal("A simple, helpful assistant")
            expect(agent.model).to_equal("claude-3-7-sonnet")
            expect(agent.max_tokens).to_equal(4096)
            expect(agent.temperature).to_equal(0.7)
            expect(#agent.traits).to_equal(1)
            expect(agent.traits[1]).to_equal("Conversational")
            expect(#agent.tools).to_equal(1)
            expect(agent.tools[1]).to_equal("wippy.tools:calculator")
            expect(#agent.memory).to_equal(2)
            expect(agent.memory[1]).to_equal("wippy.memory:conversation_history")
        end)

        it("should handle agent not found by ID", function()
            local agent, err = agent_registry.get_by_id("nonexistent")

            expect(agent).to_be_nil()
            expect(err).not_to_be_nil()
            expect(err:match("No agent found")).not_to_be_nil()
        end)

        it("should validate entry is an agent when getting by ID", function()
            local agent, err = agent_registry.get_by_id("wippy.agents:non_agent_entry")

            expect(agent).to_be_nil()
            expect(err).not_to_be_nil()
            expect(err:match("Entry is not a gen1 agent")).not_to_be_nil()
        end)

        it("should get an agent by name", function()
            local agent, err = agent_registry.get_by_name("Basic Assistant")

            expect(err).to_be_nil()
            expect(agent).not_to_be_nil()
            expect(agent.name).to_equal("Basic Assistant")
            expect(agent.id).to_equal("wippy.agents:basic_assistant")
        end)

        it("should handle agent not found by name", function()
            local agent, err = agent_registry.get_by_name("NonexistentAgent")

            expect(agent).to_be_nil()
            expect(err).not_to_be_nil()
            expect(err:match("No agent found with name")).not_to_be_nil()
        end)

        it("should inherit parent agent tools and memory", function()
            local agent, err = agent_registry.get_by_id("wippy.agents:coding_assistant")

            expect(err).to_be_nil()
            expect(agent).not_to_be_nil()

            -- Tools from self and parent
            expect(#agent.tools).to_equal(2)
            local has_calculator = false
            local has_code_interpreter = false

            for _, tool in ipairs(agent.tools) do
                if tool == "wippy.tools:calculator" then
                    has_calculator = true
                elseif tool == "wippy.tools:code_interpreter" then
                    has_code_interpreter = true
                end
            end

            expect(has_calculator).to_be_true()
            expect(has_code_interpreter).to_be_true()

            -- Memory from self and parent
            expect(#agent.memory).to_equal(3)
            local has_conversation_history = false
            local has_general_knowledge = false
            local has_coding_practices = false

            for _, memory in ipairs(agent.memory) do
                if memory == "wippy.memory:conversation_history" then
                    has_conversation_history = true
                elseif memory == "file://memory/general_knowledge.txt" then
                    has_general_knowledge = true
                elseif memory == "file://memory/coding_best_practices.txt" then
                    has_coding_practices = true
                end
            end

            expect(has_conversation_history).to_be_true()
            expect(has_general_knowledge).to_be_true()
            expect(has_coding_practices).to_be_true()
        end)

        it("should inherit parent agent traits", function()
            local agent, err = agent_registry.get_by_id("wippy.agents:coding_assistant")

            expect(err).to_be_nil()
            expect(agent).not_to_be_nil()

            -- Traits from self and parent
            expect(#agent.traits).to_equal(2)
            local has_conversational = false
            local has_thinking_tag = false

            for _, trait in ipairs(agent.traits) do
                if trait == "Conversational" then
                    has_conversational = true
                elseif trait == "Thinking Tag (User)" then
                    has_thinking_tag = true
                end
            end

            expect(has_conversational).to_be_true()
            expect(has_thinking_tag).to_be_true()

            -- Check that trait prompts are incorporated
            expect(agent.prompt).to_contain("You are a coding assistant")
            expect(agent.prompt).to_contain("You are a friendly, conversational assistant")
            expect(agent.prompt).to_contain("use <thinking> tags")
        end)

        it("should register delegates with the new format", function()
            local agent, err = agent_registry.get_by_id("wippy.agents:advanced_assistant")

            expect(err).to_be_nil()
            expect(agent).not_to_be_nil()

            -- Should have tools from self and parent, but NOT from delegate
            expect(#agent.tools).to_equal(3)

            -- Verify specific tools are present
            local tool_map = {}
            for _, tool in ipairs(agent.tools) do
                tool_map[tool] = true
            end

            expect(tool_map["wippy.tools:knowledge_base"]).to_be_true() -- From self
            expect(tool_map["wippy.tools:code_interpreter"]).to_be_true() -- From parent
            expect(tool_map["wippy.tools:calculator"]).to_be_true() -- From grandparent

            -- Should NOT have tools from delegate
            expect(tool_map["wippy.tools:git_helper"]).to_be_nil()
            expect(tool_map["wippy.tools:linter"]).to_be_nil()

            -- Verify delegate metadata is recorded
            expect(#agent.delegates).to_equal(1)
            expect(agent.delegates[1].id).to_equal("wippy.agents:code_tools")
            expect(agent.delegates[1].name).to_equal("to_code_tools")
            expect(agent.delegates[1].rule).to_equal("Forward to this agent when coding help is needed")
            -- No description field anymore
        end)

        it("should multi-level inherit traits", function()
            local agent, err = agent_registry.get_by_id("wippy.agents:advanced_assistant")

            expect(err).to_be_nil()
            expect(agent).not_to_be_nil()

            -- Should have traits from self and all ancestors
            expect(#agent.traits).to_equal(3)

            -- Verify specific traits are present
            local trait_map = {}
            for _, trait in ipairs(agent.traits) do
                trait_map[trait] = true
            end

            expect(trait_map["Multilingual"]).to_be_true() -- From self
            expect(trait_map["Thinking Tag (User)"]).to_be_true() -- From parent
            expect(trait_map["Conversational"]).to_be_true() -- From grandparent

            -- Verify trait prompts are incorporated in the combined prompt
            expect(agent.prompt).to_contain("You are an advanced assistant")
            expect(agent.prompt).to_contain("use <thinking> tags")
            expect(agent.prompt).to_contain("You can respond in the same language")
        end)

        it("should avoid duplicate tools, traits, and memories", function()
            -- Create a test entry with duplicate traits, tools, and memories
            agent_entries["wippy.agents:duplicate_test"] = {
                id = "wippy.agents:duplicate_test",
                kind = "registry.entry",
                meta = {
                    type = "agent.gen1",
                    name = "Duplicate Test",
                    comment = "Agent for testing duplicate handling"
                },
                data = {
                    model = "claude-3-7-sonnet",
                    prompt = "Test prompt",
                    traits = {
                        "Conversational",
                        "Conversational" -- Duplicate trait
                    },
                    tools = {
                        "wippy.tools:calculator",
                        "wippy.tools:calculator" -- Duplicate tool
                    },
                    memory = {
                        "wippy.memory:conversation_history",
                        "wippy.memory:conversation_history" -- Duplicate memory
                    },
                    inherit = {
                        "wippy.agents:basic_assistant" -- Which also has the same tools, traits, and memories
                    }
                }
            }

            local agent, err = agent_registry.get_by_id("wippy.agents:duplicate_test")

            expect(err).to_be_nil()
            expect(agent).not_to_be_nil()

            -- Verify no duplicates in traits
            expect(#agent.traits).to_equal(1)

            -- Verify no duplicates in tools
            expect(#agent.tools).to_equal(1)

            -- Verify no duplicates in memories
            expect(#agent.memory).to_equal(2) -- Should have both conversation_history and general_knowledge.txt
        end)

        it("should prevent recursive inheritance", function()
            -- Create a set of agents with circular inheritance
            agent_entries["wippy.agents:recursive1"] = {
                id = "wippy.agents:recursive1",
                kind = "registry.entry",
                meta = {
                    type = "agent.gen1",
                    name = "Recursive 1",
                    comment = "First recursive agent"
                },
                data = {
                    model = "claude-3-7-sonnet",
                    tools = { "wippy.tools:tool_a" },
                    traits = { "Conversational" },
                    inherit = {
                        "wippy.agents:recursive2" -- Creates a cycle
                    }
                }
            }

            agent_entries["wippy.agents:recursive2"] = {
                id = "wippy.agents:recursive2",
                kind = "registry.entry",
                meta = {
                    type = "agent.gen1",
                    name = "Recursive 2",
                    comment = "Second recursive agent"
                },
                data = {
                    model = "claude-3-7-sonnet",
                    tools = { "wippy.tools:tool_b" },
                    traits = { "Thinking Tag (User)" },
                    inherit = {
                        "wippy.agents:recursive1" -- Creates a cycle
                    }
                }
            }

            -- This should complete without an infinite loop
            local agent, err = agent_registry.get_by_id("wippy.agents:recursive1")

            -- Should still get a valid agent
            expect(agent).not_to_be_nil()

            -- Should have both tools (its own and from the other agent)
            local tools = {}
            for _, tool in ipairs(agent.tools) do
                tools[tool] = true
            end

            expect(tools["wippy.tools:tool_a"]).to_be_true()
            expect(tools["wippy.tools:tool_b"]).to_be_true()

            -- Check that we don't have infinite recursion using a valid assertion
            -- Replace the invalid to_be_less_than with a valid assertion
            expect(#agent.tools <= 4).to_be_true() -- Just a sanity check
        end)

        it("should require parameter for get_by_id", function()
            local agent, err = agent_registry.get_by_id(nil)

            expect(agent).to_be_nil()
            expect(err).to_equal("Agent ID is required")
        end)

        it("should require parameter for get_by_name", function()
            local agent, err = agent_registry.get_by_name(nil)

            expect(agent).to_be_nil()
            expect(err).to_equal("Agent name is required")
        end)
    end)
end

return require("test").run_cases(define_tests)