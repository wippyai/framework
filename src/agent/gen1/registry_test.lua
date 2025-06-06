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
                    traits = { "Thinking Tag (User)", "wippy.traits:search_capability" }, -- UPDATED: Added trait with tools by ID
                    tools = { "wippy.tools:code_interpreter" },
                    memory = { "file://memory/coding_best_practices.txt" },
                    inherit = { "wippy.agents:basic_assistant" }
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
                    traits = { "Multilingual", "wippy.traits:file_management" }, -- UPDATED: Added trait with wildcard tool by ID
                    tools = { "wippy.tools:knowledge_base" },
                    delegate = { ["wippy.agents:code_tools"] = { name = "to_code_tools", rule = "Forward to this agent when coding help is needed" } },
                    inherit = { "wippy.agents:coding_assistant" }
                }
            },
            ["wippy.agents:research_assistant_for_trait_tools"] = { -- NEW: Agent specifically for testing trait tools
                id = "wippy.agents:research_assistant_for_trait_tools",
                kind = "registry.entry",
                meta = { type = "agent.gen1", name = "Research Trait Tool Assistant", comment = "An assistant that can search and manage files via traits." },
                data = {
                    model = "claude-3-opus",
                    prompt = "You are a research assistant using trait tools.",
                    traits = { "Search Capability", "wippy.traits:file_management" }, -- Reference new traits by name or ID
                    tools = { "wippy.tools:summarizer" }                              -- Agent's own tool
                }
            },
            ["wippy.agents:non_agent_entry"] = {
                id = "wippy.agents:non_agent_entry",
                kind = "registry.entry",
                meta = { type = "something.else", name = "Not An Agent", comment = "This is not an agent entry." },
                data = { some_field = "some value" }
            }
        }

        -- Sample trait entries for testing
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
            ["wippy.traits:search_capability"] = { -- NEW: Trait with its own tools
                id = "wippy.traits:search_capability",
                kind = "registry.entry",
                meta = { type = "agent.trait", name = "Search Capability", comment = "Trait that adds search tools." },
                data = {
                    prompt = "You can search for information using available tools.",
                    tools = { "wippy.tools:search_web", "wippy.tools:browse_url" }
                }
            },
            ["wippy.traits:file_management"] = { -- NEW: Trait with a wildcard tool
                id = "wippy.traits:file_management",
                kind = "registry.entry",
                meta = { type = "agent.trait", name = "File Management", comment = "Trait that adds file management tools." },
                data = {
                    prompt = "You can manage files using your tools.",
                    tools = { "wippy.tools:files:*" }
                }
            }
        }

        -- NEW: Sample tool entries for wildcard resolution testing
        local tool_registry_entries = {
            ["wippy.tools:files:read"] = { id = "wippy.tools:files:read", kind = "registry.entry", meta = { type = "tool", name = "ReadFile" }, data = {} },
            ["wippy.tools:files:write"] = { id = "wippy.tools:files:write", kind = "registry.entry", meta = { type = "tool", name = "WriteFile" }, data = {} },
            ["wippy.tools:other_ns:tool1"] = { id = "wippy.tools:other_ns:tool1", kind = "registry.entry", meta = { type = "tool", name = "OtherTool" }, data = {} }
        }


        local mock_registry
        local mock_traits

        before_each(function()
            -- Create mock registry for testing
            mock_registry = {
                get = function(id)
                    -- UPDATED: Include tool_registry_entries in get
                    return agent_entries[id] or trait_entries[id] or tool_registry_entries[id]
                end,
                find = function(query)
                    -- UPDATED: Enhanced find to handle combined sources and .ns queries
                    local results = {}
                    local source_map = {} -- Combine all mock entries for find
                    for k, v in pairs(agent_entries) do source_map[k] = v end
                    for k, v in pairs(trait_entries) do source_map[k] = v end
                    for k, v in pairs(tool_registry_entries) do source_map[k] = v end

                    for _, entry in pairs(source_map) do
                        local matches = true
                        if query[".kind"] and entry.kind ~= query[".kind"] then matches = false end
                        if query["meta.type"] and (not entry.meta or entry.meta.type ~= query["meta.type"]) then matches = false end
                        if query["meta.name"] and (not entry.meta or entry.meta.name ~= query["meta.name"]) then matches = false end
                        -- Handle .ns query for wildcard resolution
                        if query[".ns"] then
                            if not entry.id or type(entry.id) ~= "string" then -- Ensure entry.id is a string
                                matches = false
                            else
                                local entry_ns = entry.id:match("^(.-):[^:]+$") -- Basic namespace extraction
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

            -- Create mock traits library
            -- UPDATED: mock_traits now handles 'tools' and has get_by_id
            mock_traits = {
                get_by_name = function(name)
                    for id, entry in pairs(trait_entries) do
                        if entry.meta and entry.meta.name == name and entry.meta.type == "agent.trait" then
                            return {
                                id = entry.id,
                                name = entry.meta.name,
                                description = entry.meta.comment,
                                prompt = (entry.data and entry.data.prompt) or "",
                                tools = (entry.data and entry.data.tools) or {} -- Include tools
                            }
                        end
                    end
                    return nil, "No trait found with name: " .. name
                end,
                get_by_id = function(id_to_find) -- Added get_by_id to mock_traits
                    local entry = trait_entries[id_to_find]
                    if entry and entry.meta and entry.meta.type == "agent.trait" then
                        return {
                            id = entry.id,
                            name = (entry.meta and entry.meta.name) or "",
                            description = (entry.meta and entry.meta.comment) or "",
                            prompt = (entry.data and entry.data.prompt) or "",
                            tools = (entry.data and entry.data.tools) or {} -- Include tools
                        }
                    end
                    return nil, "No trait found with ID: " .. tostring(id_to_find)
                end,
                get_all = function()                         -- Kept original get_all structure, updated to include tools
                    local result = {}
                    for id, entry in pairs(trait_entries) do -- Iterate over 'id, entry'
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
            expect(#agent.tools).to_equal(1) -- Only its own tool, "Conversational" trait has no tools
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

        it("should inherit parent agent tools and memory, and include tools from traits", function()
            -- UPDATED test body
            local agent, err = agent_registry.get_by_id("wippy.agents:coding_assistant")
            expect(err).to_be_nil()
            expect(agent).not_to_be_nil()

            -- Tools from self: "wippy.tools:code_interpreter"
            -- Tools from parent (basic_assistant): "wippy.tools:calculator"
            -- Tools from self trait ("wippy.traits:search_capability"): "wippy.tools:search_web", "wippy.tools:browse_url"
            -- Expected unique tools: 4
            expect(#agent.tools).to_equal(4)
            local tool_map = {}
            for _, tool in ipairs(agent.tools) do tool_map[tool] = true end

            expect(tool_map["wippy.tools:calculator"]).to_be_true()
            expect(tool_map["wippy.tools:code_interpreter"]).to_be_true()
            expect(tool_map["wippy.tools:search_web"]).to_be_true()
            expect(tool_map["wippy.tools:browse_url"]).to_be_true()

            -- Memory from self and parent (unchanged logic for memory itself)
            expect(#agent.memory).to_equal(3)
            local has_conversation_history = false
            local has_general_knowledge = false
            local has_coding_practices = false
            for _, memory_item in ipairs(agent.memory) do
                if memory_item == "wippy.memory:conversation_history" then
                    has_conversation_history = true
                elseif memory_item == "file://memory/general_knowledge.txt" then
                    has_general_knowledge = true
                elseif memory_item == "file://memory/coding_best_practices.txt" then
                    has_coding_practices = true
                end
            end
            expect(has_conversation_history).to_be_true()
            expect(has_general_knowledge).to_be_true()
            expect(has_coding_practices).to_be_true()
        end)

        it("should inherit parent agent traits and combine prompts, including prompts from traits with tools", function()
            -- UPDATED test body
            local agent, err = agent_registry.get_by_id("wippy.agents:coding_assistant")
            expect(err).to_be_nil()
            expect(agent).not_to_be_nil()

            -- Traits from self: "Thinking Tag (User)", "wippy.traits:search_capability"
            -- Traits from parent (basic_assistant): "Conversational"
            -- Expected unique trait identifiers: 3
            expect(#agent.traits).to_equal(3)
            local trait_id_map = {} -- Check by ID or name as appropriate
            for _, trait_identifier in ipairs(agent.traits) do trait_id_map[trait_identifier] = true end
            expect(trait_id_map["Thinking Tag (User)"]).to_be_true()
            expect(trait_id_map["wippy.traits:search_capability"]).to_be_true() -- This trait is now identified by its ID
            expect(trait_id_map["Conversational"]).to_be_true()

            -- Check that trait prompts are incorporated
            expect(agent.prompt).to_contain("You are a coding assistant")
            expect(agent.prompt).to_contain("You are a friendly, conversational assistant")          -- from inherited Conversational
            expect(agent.prompt).to_contain("use <thinking> tags")                                   -- from Thinking Tag
            expect(agent.prompt).to_contain("You can search for information using available tools.") -- from Search Capability
        end)

        it("should register delegates with the new format, and tool count reflects all sources", function()
            -- UPDATED test body
            local agent, err = agent_registry.get_by_id("wippy.agents:advanced_assistant")
            expect(err).to_be_nil()
            expect(agent).not_to_be_nil()

            -- Tools:
            -- Self: "wippy.tools:knowledge_base"
            -- Self trait "wippy.traits:file_management": "wippy.tools:files:*" -> files:read, files:write
            -- Inherited from coding_assistant:
            --   Tool: "wippy.tools:code_interpreter"
            --   Trait "wippy.traits:search_capability": search_web, browse_url
            -- Inherited from basic_assistant (via coding_assistant):
            --   Tool: "wippy.tools:calculator"
            -- Expected unique tools: knowledge_base, files:read, files:write, code_interpreter, search_web, browse_url, calculator (7 tools)
            expect(#agent.tools).to_equal(7)

            local tool_map = {}
            for _, tool in ipairs(agent.tools) do tool_map[tool] = true end
            expect(tool_map["wippy.tools:knowledge_base"]).to_be_true()
            expect(tool_map["wippy.tools:files:read"]).to_be_true()
            expect(tool_map["wippy.tools:files:write"]).to_be_true()
            expect(tool_map["wippy.tools:code_interpreter"]).to_be_true()
            expect(tool_map["wippy.tools:search_web"]).to_be_true()
            expect(tool_map["wippy.tools:browse_url"]).to_be_true()
            expect(tool_map["wippy.tools:calculator"]).to_be_true()
            -- Should NOT have tools from delegate
            expect(tool_map["wippy.tools:git_helper"]).to_be_nil()
            expect(tool_map["wippy.tools:linter"]).to_be_nil()

            -- Verify delegate metadata is recorded (original logic)
            expect(#agent.delegates).to_equal(1)
            expect(agent.delegates[1].id).to_equal("wippy.agents:code_tools")
            expect(agent.delegates[1].name).to_equal("to_code_tools")
            expect(agent.delegates[1].rule).to_equal("Forward to this agent when coding help is needed")
        end)

        it("should multi-level inherit traits and prompts", function()
            -- UPDATED test body
            local agent, err = agent_registry.get_by_id("wippy.agents:advanced_assistant")
            expect(err).to_be_nil()
            expect(agent).not_to_be_nil()

            -- Traits: "Multilingual", "wippy.traits:file_management", "Thinking Tag (User)", "wippy.traits:search_capability", "Conversational"
            expect(#agent.traits).to_equal(5)
            local trait_id_map = {}
            for _, trait_identifier in ipairs(agent.traits) do trait_id_map[trait_identifier] = true end

            expect(trait_id_map["Multilingual"]).to_be_true()
            expect(trait_id_map["wippy.traits:file_management"]).to_be_true()
            expect(trait_id_map["Thinking Tag (User)"]).to_be_true()
            expect(trait_id_map["wippy.traits:search_capability"]).to_be_true()
            expect(trait_id_map["Conversational"]).to_be_true()

            -- Verify trait prompts are incorporated in the combined prompt
            expect(agent.prompt).to_contain("You are an advanced assistant")
            expect(agent.prompt).to_contain("You can manage files using your tools.")                -- from file_management
            expect(agent.prompt).to_contain("You can respond in the same language")                  -- from Multilingual
            expect(agent.prompt).to_contain("use <thinking> tags")                                   -- from inherited Thinking Tag
            expect(agent.prompt).to_contain("You can search for information using available tools.") -- from inherited Search Capability
            expect(agent.prompt).to_contain("You are a friendly, conversational assistant")          -- from inherited Conversational
        end)

        -- NEW TEST METHOD
        it("should correctly incorporate tools from traits, including wildcard resolution", function()
            local agent, err = agent_registry.get_by_id("wippy.agents:research_assistant_for_trait_tools")
            expect(err).to_be_nil()
            expect(agent).not_to_be_nil()

            -- Agent's own tool: "wippy.tools:summarizer"
            -- Trait "Search Capability" tools: "wippy.tools:search_web", "wippy.tools:browse_url"
            -- Trait "File Management" tools ("wippy.tools:files:*"): "wippy.tools:files:read", "wippy.tools:files:write"
            -- Expected unique tools: 5
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

        it("should avoid duplicate tools, traits, and memories from all sources", function()
            -- UPDATED agent definition and assertions
            agent_entries["wippy.agents:duplicate_test"] = {
                id = "wippy.agents:duplicate_test",
                kind = "registry.entry",
                meta = { type = "agent.gen1", name = "Duplicate Test", comment = "Agent for testing duplicate handling" },
                data = {
                    model = "claude-3-7-sonnet",
                    prompt = "Test prompt",
                    traits = { "Conversational", "Conversational", "wippy.traits:search_capability" },        -- search_capability provides search_web, browse_url
                    tools = { "wippy.tools:calculator", "wippy.tools:calculator", "wippy.tools:search_web" }, -- search_web is also from trait
                    memory = { "wippy.memory:conversation_history", "wippy.memory:conversation_history" },
                    inherit = { "wippy.agents:basic_assistant" }                                              -- basic_assistant has "Conversational" trait and "calculator" tool
                }
            }

            local agent, err = agent_registry.get_by_id("wippy.agents:duplicate_test")
            expect(err).to_be_nil()
            expect(agent).not_to_be_nil()

            -- Traits: "Conversational", "wippy.traits:search_capability" (2 unique)
            expect(#agent.traits).to_equal(2)

            -- Tools:
            -- Self: "wippy.tools:calculator", "wippy.tools:search_web"
            -- Trait "wippy.traits:search_capability": "wippy.tools:search_web", "wippy.tools:browse_url"
            -- Inherited from basic_assistant: "wippy.tools:calculator"
            -- Unique: calculator, search_web, browse_url (3 unique)
            expect(#agent.tools).to_equal(3)
            local tool_map = {}
            for _, tool in ipairs(agent.tools) do tool_map[tool] = true end
            expect(tool_map["wippy.tools:calculator"]).to_be_true()
            expect(tool_map["wippy.tools:search_web"]).to_be_true()
            expect(tool_map["wippy.tools:browse_url"]).to_be_true()

            -- Memory (unchanged logic): conversation_history, general_knowledge.txt (2 unique)
            expect(#agent.memory).to_equal(2)
            -- Preserving original memory checks
            local has_conversation_history = false
            local has_general_knowledge = false
            for _, memory_item in ipairs(agent.memory) do
                if memory_item == "wippy.memory:conversation_history" then
                    has_conversation_history = true
                elseif memory_item == "file://memory/general_knowledge.txt" then
                    has_general_knowledge = true
                end
            end
            expect(has_conversation_history).to_be_true()
            expect(has_general_knowledge).to_be_true()
        end)

        it("should prevent recursive inheritance, including traits and tools from recursion", function()
            -- UPDATED agent definitions and assertions
            agent_entries["wippy.agents:recursive1"] = {
                id = "wippy.agents:recursive1",
                kind = "registry.entry",
                meta = { type = "agent.gen1", name = "Recursive 1" },
                data = { tools = { "r_tool_a" }, traits = { "Conversational", "wippy.traits:search_capability" }, inherit = { "wippy.agents:recursive2" } }
            }
            agent_entries["wippy.agents:recursive2"] = {
                id = "wippy.agents:recursive2",
                kind = "registry.entry",
                meta = { type = "agent.gen1", name = "Recursive 2" },
                data = { tools = { "r_tool_b" }, traits = { "Thinking Tag (User)" }, inherit = { "wippy.agents:recursive1" } }
            }

            local agent, err = agent_registry.get_by_id("wippy.agents:recursive1")
            expect(err).to_be_nil()
            expect(agent).not_to_be_nil()

            -- Traits: "Conversational", "wippy.traits:search_capability", "Thinking Tag (User)" (3 unique)
            expect(#agent.traits).to_equal(3)

            -- Tools:
            -- r1: "r_tool_a"
            -- r1 trait "search_capability": "search_web", "browse_url"
            -- r2: "r_tool_b"
            -- Unique: r_tool_a, search_web, browse_url, r_tool_b (4 unique)
            expect(#agent.tools).to_equal(4)
            local tool_map = {}
            for _, tool in ipairs(agent.tools) do tool_map[tool] = true end
            expect(tool_map["r_tool_a"]).to_be_true()
            expect(tool_map["wippy.tools:search_web"]).to_be_true()
            expect(tool_map["wippy.tools:browse_url"]).to_be_true()
            expect(tool_map["r_tool_b"]).to_be_true()

            expect(#agent.tools <= 5).to_be_true() -- Original sanity check was <=4, updated for trait tools
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
            -- sample agent with a class label
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
