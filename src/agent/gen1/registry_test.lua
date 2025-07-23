local agent_registry = require("agent_registry")
-- traits module is injected, not directly required here for testing

local function define_tests()
    describe("Agent Registry", function()
        -- Sample agent registry entries for testing
        local agent_entries = {
            ["wippy.agents:basic_assistant"] = {
                id = "wippy.agents:basic_assistant",
                kind = "registry.entry",
                meta = { type = "agent.gen1", name = "Basic Assistant", comment = "A simple, helpful assistant" },
                data = {
                    model = "claude-3-7-sonnet",
                    prompt = "You are a helpful assistant that provides concise, accurate answers.",
                    max_tokens = 4096,
                    temperature = 0.7,
                    traits = { "Conversational" },
                    tools = { "wippy.tools:calculator" },
                    memory = { "wippy.memory:conversation_history", "file://memory/general_knowledge.txt" }
                }
            },
            ["wippy.agents:coding_assistant"] = {
                id = "wippy.agents:coding_assistant",
                kind = "registry.entry",
                meta = { type = "agent.gen1", name = "Coding Assistant", comment = "Specialized assistant for programming tasks" },
                data = {
                    model = "gpt-4o",
                    prompt = "You are a coding assistant specialized in helping with programming tasks.",
                    max_tokens = 8192,
                    temperature = 0.5,
                    traits = { "Thinking Tag (User)", "wippy.traits:search_capability" },
                    tools = { "wippy.tools:code_interpreter" },
                    memory = { "file://memory/coding_best_practices.txt" }
                }
            },
            ["wippy.agents:code_tools"] = {
                id = "wippy.agents:code_tools",
                kind = "registry.entry",
                meta = { type = "agent.gen1", name = "Code Tools", comment = "Collection of code-related tools for agents" },
                data = { tools = { "wippy.tools:git_helper", "wippy.tools:linter" } }
            },
            ["wippy.agents:advanced_assistant"] = {
                id = "wippy.agents:advanced_assistant",
                kind = "registry.entry",
                meta = { type = "agent.gen1", name = "Advanced Assistant", comment = "Advanced assistant with extensive tools" },
                data = {
                    model = "claude-3-7-sonnet",
                    prompt = "You are an advanced assistant with extensive capabilities.",
                    max_tokens = 8192,
                    temperature = 0.6,
                    traits = { "Multilingual", "wippy.traits:file_management" },
                    tools = { "wippy.tools:knowledge_base" },
                    delegate = { ["wippy.agents:code_tools"] = { name = "to_code_tools", rule = "Forward to this agent when coding help is needed" } }
                }
            },
            ["wippy.agents:research_assistant_for_trait_tools"] = {
                id = "wippy.agents:research_assistant_for_trait_tools",
                kind = "registry.entry",
                meta = { type = "agent.gen1", name = "Research Trait Tool Assistant", comment = "An assistant that can search and manage files via traits." },
                data = {
                    model = "claude-3-opus",
                    prompt = "You are a research assistant using trait tools.",
                    traits = { "Search Capability", "wippy.traits:file_management" },
                    tools = { "wippy.tools:summarizer" }
                }
            },
            ["wippy.agents:non_agent_entry"] = {
                id = "wippy.agents:non_agent_entry",
                kind = "registry.entry",
                meta = { type = "something.else", name = "Not An Agent", comment = "This is not an agent entry." },
                data = { some_field = "some value" }
            }
        }

        -- Sample trait entries for testing (captured by closure in mock functions)
        local trait_entries = {
            ["wippy.agents:conversational"] = {
                id = "wippy.agents:conversational",
                kind = "registry.entry",
                meta = { type = "agent.trait", name = "Conversational", comment = "Trait that makes agents conversational and friendly." },
                data = { prompt = "You are a friendly, conversational assistant.\nAlways respond in a natural, engaging way." }
            },
            ["wippy.agents:thinking_tag_user"] = {
                id = "wippy.agents:thinking_tag_user",
                kind = "registry.entry",
                meta = { type = "agent.trait", name = "Thinking Tag (User)", comment = "Trait that adds structured thinking tags for user visibility." },
                data = { prompt = "When tackling complex problems, use <thinking> tags to show your reasoning process." }
            },
            ["wippy.agents:multilingual"] = {
                id = "wippy.agents:multilingual",
                kind = "registry.entry",
                meta = { type = "agent.trait", name = "Multilingual", comment = "Trait that adds multilingual capabilities." },
                data = { prompt = "You can respond in the same language the user uses to communicate with you." }
            },
            ["wippy.traits:search_capability"] = {
                id = "wippy.traits:search_capability",
                kind = "registry.entry",
                meta = { type = "agent.trait", name = "Search Capability", comment = "Trait that adds search tools." },
                data = {
                    prompt = "You can search for information using available tools.",
                    tools = { "wippy.tools:search_web", "wippy.tools:browse_url" }
                }
            },
            ["wippy.traits:file_management"] = {
                id = "wippy.traits:file_management",
                kind = "registry.entry",
                meta = { type = "agent.trait", name = "File Management", comment = "Trait that adds file management tools." },
                data = {
                    prompt = "You can manage files using your tools.",
                    tools = { "wippy.tools:files:*" }
                }
            }
        }

        local tool_registry_entries = {
            ["wippy.tools:files:read"] = { id = "wippy.tools:files:read", kind = "registry.entry", meta = { type = "tool", name = "ReadFile" }, data = {} },
            ["wippy.tools:files:write"] = { id = "wippy.tools:files:write", kind = "registry.entry", meta = { type = "tool", name = "WriteFile" }, data = {} },
            ["wippy.tools:other_ns:tool1"] = { id = "wippy.tools:other_ns:tool1", kind = "registry.entry", meta = { type = "tool", name = "OtherTool" }, data = {} }
        }


        local mock_registry
        local mock_traits

        -- Pre-define mock trait functions to avoid direct anonymous functions in table constructor
        local mock_trait_get_by_name_func = function(name)
            for id_key, entry in pairs(trait_entries) do -- Renamed 'id' to 'id_key' to avoid conflict if 'id' is used as var name
                if entry.meta and entry.meta.name == name and entry.meta.type == "agent.trait" then
                    return {
                        id = entry.id,
                        name = entry.meta.name,
                        description = entry.meta.comment,
                        prompt = (entry.data and entry.data.prompt) or "",
                        tools = (entry.data and entry.data.tools) or {}
                    }
                end
            end
            return nil, "No trait found with name: " .. name
        end

        local mock_trait_get_by_id_func = function(id_to_find)
            local entry = trait_entries[id_to_find]
            if entry and entry.meta and entry.meta.type == "agent.trait" then
                return {
                    id = entry.id,
                    name = (entry.meta and entry.meta.name) or "",
                    description = (entry.meta and entry.meta.comment) or "",
                    prompt = (entry.data and entry.data.prompt) or "",
                    tools = (entry.data and entry.data.tools) or {}
                }
            end
            return nil, "No trait found with ID: " .. tostring(id_to_find)
        end

        local mock_trait_get_all_func = function()
            local result = {}
            for id_key, entry in pairs(trait_entries) do -- Renamed 'id' to 'id_key'
                if entry.meta and entry.meta.type == "agent.trait" then
                    table.insert(result, {
                        id = entry.id,
                        name = entry.meta.name,
                        description = entry.meta.comment,
                        prompt = (entry.data and entry.data.prompt) or "",
                        tools = (entry.data and entry.data.tools) or {}
                    })
                end
            end
            return result
        end

        before_each(function()
            mock_registry = {
                get = function(id)
                    return agent_entries[id] or trait_entries[id] or tool_registry_entries[id]
                end,
                find = function(query)
                    local results = {}
                    local source_map = {}
                    for k, v in pairs(agent_entries) do source_map[k] = v end
                    for k, v in pairs(trait_entries) do source_map[k] = v end
                    for k, v in pairs(tool_registry_entries) do source_map[k] = v end

                    for _, entry in pairs(source_map) do
                        local matches = true
                        if query[".kind"] and entry.kind ~= query[".kind"] then matches = false end
                        if query["meta.type"] and (not entry.meta or entry.meta.type ~= query["meta.type"]) then matches = false end
                        if query["meta.name"] and (not entry.meta or entry.meta.name ~= query["meta.name"]) then matches = false end
                        if query[".ns"] then
                            if not entry.id or type(entry.id) ~= "string" then
                                matches = false
                            else
                                local entry_ns = entry.id:match("^(.-):[^:]+$")
                                if not entry_ns or entry_ns ~= query[".ns"] then
                                    matches = false
                                end
                            end
                        end
                        if matches then table.insert(results, entry) end
                    end
                    return results
                end
            }

            -- Assign pre-defined functions to mock_traits table
            mock_traits = {
                get_by_name = mock_trait_get_by_name_func,
                get_by_id = mock_trait_get_by_id_func,
                get_all = mock_trait_get_all_func
            }

            agent_registry._registry = mock_registry
            agent_registry._traits = mock_traits
        end)

        after_each(function()
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

        it("should correctly process agent's own tools, memory, and traits (no inheritance)", function()
            local agent, err = agent_registry.get_by_id("wippy.agents:coding_assistant")
            expect(err).to_be_nil()
            expect(agent).not_to_be_nil()

            expect(#agent.tools).to_equal(3)
            local tool_map = {}
            for _, tool in ipairs(agent.tools) do tool_map[tool] = true end

            expect(tool_map["wippy.tools:code_interpreter"]).to_be_true()
            expect(tool_map["wippy.tools:search_web"]).to_be_true()
            expect(tool_map["wippy.tools:browse_url"]).to_be_true()
            expect(tool_map["wippy.tools:calculator"]).to_be_nil()

            expect(#agent.memory).to_equal(1)
            expect(agent.memory[1]).to_equal("file://memory/coding_best_practices.txt")
        end)

        it("should correctly process agent's own traits and combine prompts (no inheritance)", function()
            local agent, err = agent_registry.get_by_id("wippy.agents:coding_assistant")
            expect(err).to_be_nil()
            expect(agent).not_to_be_nil()

            expect(#agent.traits).to_equal(2)
            local trait_id_map = {}
            for _, trait_identifier in ipairs(agent.traits) do trait_id_map[trait_identifier] = true end
            expect(trait_id_map["Thinking Tag (User)"]).to_be_true()
            expect(trait_id_map["wippy.traits:search_capability"]).to_be_true()
            expect(trait_id_map["Conversational"]).to_be_nil()

            expect(agent.prompt).to_contain("You are a coding assistant")
            expect(agent.prompt).to_contain("use <thinking> tags")
            expect(agent.prompt).to_contain("You can search for information using available tools.")
        end)

        it("should register delegates, and tool count reflects self and traits (no inheritance)", function()
            local agent, err = agent_registry.get_by_id("wippy.agents:advanced_assistant")
            expect(err).to_be_nil()
            expect(agent).not_to_be_nil()

            expect(#agent.tools).to_equal(3)

            local tool_map = {}
            for _, tool in ipairs(agent.tools) do tool_map[tool] = true end
            expect(tool_map["wippy.tools:knowledge_base"]).to_be_true()
            expect(tool_map["wippy.tools:files:read"]).to_be_true()
            expect(tool_map["wippy.tools:files:write"]).to_be_true()
            expect(tool_map["wippy.tools:code_interpreter"]).to_be_nil()
            expect(tool_map["wippy.tools:search_web"]).to_be_nil()
            expect(tool_map["wippy.tools:calculator"]).to_be_nil()
            expect(tool_map["wippy.tools:git_helper"]).to_be_nil()

            expect(#agent.delegates).to_equal(1)
            expect(agent.delegates[1].id).to_equal("wippy.agents:code_tools")
            expect(agent.delegates[1].name).to_equal("to_code_tools")
        end)

        it("should correctly incorporate tools from traits, including wildcard resolution", function()
            local agent, err = agent_registry.get_by_id("wippy.agents:research_assistant_for_trait_tools")
            expect(err).to_be_nil()
            expect(agent).not_to_be_nil()

            expect(#agent.tools).to_equal(5)
            local tool_map = {}
            for _, tool_id in ipairs(agent.tools) do tool_map[tool_id] = true end
            expect(tool_map["wippy.tools:summarizer"]).to_be_true()
            expect(tool_map["wippy.tools:search_web"]).to_be_true()
            expect(tool_map["wippy.tools:browse_url"]).to_be_true()
            expect(tool_map["wippy.tools:files:read"]).to_be_true()
            expect(tool_map["wippy.tools:files:write"]).to_be_true()

            expect(agent.prompt).to_contain("You are a research assistant using trait tools.")
            expect(agent.prompt).to_contain("You can search for information using available tools.")
            expect(agent.prompt).to_contain("You can manage files using your tools.")
        end)

        it("should avoid duplicate tools, traits, and memories from self and traits (no inheritance)", function()
            agent_entries["wippy.agents:duplicate_test"] = {
                id = "wippy.agents:duplicate_test",
                kind = "registry.entry",
                meta = { type = "agent.gen1", name = "Duplicate Test", comment = "Agent for testing duplicate handling" },
                data = {
                    model = "claude-3-7-sonnet",
                    prompt = "Test prompt",
                    traits = { "Conversational", "Conversational", "wippy.traits:search_capability" },
                    tools = { "wippy.tools:calculator", "wippy.tools:calculator", "wippy.tools:search_web" },
                    memory = { "wippy.memory:conversation_history", "wippy.memory:conversation_history" }
                }
            }

            local agent, err = agent_registry.get_by_id("wippy.agents:duplicate_test")
            expect(err).to_be_nil()
            expect(agent).not_to_be_nil()

            expect(#agent.traits).to_equal(2)

            expect(#agent.tools).to_equal(3)
            local tool_map = {}
            for _, tool in ipairs(agent.tools) do tool_map[tool] = true end
            expect(tool_map["wippy.tools:calculator"]).to_be_true()
            expect(tool_map["wippy.tools:search_web"]).to_be_true()
            expect(tool_map["wippy.tools:browse_url"]).to_be_true()

            expect(#agent.memory).to_equal(1)
            expect(agent.memory[1]).to_equal("wippy.memory:conversation_history")
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

        it("should list agents by class and include full data", function()
            agent_entries["wippy.agents:math_bot"] = {
                id   = "wippy.agents:math_bot",
                kind = "registry.entry",
                meta = {
                    type = "agent.gen1",
                    name = "Math Bot",
                    class = { "assistant.coding", "assistant.math" }
                },
                data = { prompt = "I can do maths." }
            }

            local list = agent_registry.list_by_class("assistant.coding")
            expect(#list).to_be_greater_than(0)

            local found = false
            for _, entry in ipairs(list) do
                if entry.id == "wippy.agents:math_bot" then
                    found = true
                    expect(entry.data.prompt).to_equal("I can do maths.")
                end
            end
            expect(found).to_be_true()
        end)
    end)
end

return require("test").run_cases(define_tests)