local traits = require("traits")

local function define_tests()
    describe("Traits Library", function()
        -- Sample trait registry entries for testing
        local trait_entries = {
            -- Basic trait (old format)
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

            -- Trait with old format tools
            ["wippy.agents:search_trait"] = {
                id = "wippy.agents:search_trait",
                kind = "registry.entry",
                meta = {
                    type = "agent.trait",
                    name = "Search Capability",
                    comment = "Trait that adds search capabilities to agents."
                },
                data = {
                    prompt = "You can search for information on the web using tools.",
                    tools = {
                        "wippy.tools:search_web",
                        "wippy.tools:browse_url"
                    }
                }
            },

            -- Enhanced trait with build_func_id and context
            ["mcp.traits:filesystem"] = {
                id = "mcp.traits:filesystem",
                kind = "registry.entry",
                meta = {
                    type = "agent.trait",
                    name = "MCP Filesystem",
                    comment = "Trait that provides filesystem access via MCP."
                },
                data = {
                    prompt = "You have filesystem access capabilities.",
                    build_func_id = "init_filesystem_mcp",
                    context = {
                        default_timeout = 30,
                        default_encoding = "utf-8",
                        max_file_size = "10MB"
                    }
                }
            },

            -- Trait with new format tools
            ["wippy.agents:database_trait"] = {
                id = "wippy.agents:database_trait",
                kind = "registry.entry",
                meta = {
                    type = "agent.trait",
                    name = "Database Access",
                    comment = "Trait that provides database access with contexts."
                },
                data = {
                    prompt = "You can query databases.",
                    tools = {
                        {
                            id = "db.tools:execute_query",
                            context = {
                                database_type = "postgresql",
                                max_query_time = 60
                            }
                        },
                        {
                            id = "db.tools:describe_table",
                            context = {
                                include_indexes = true
                            }
                        }
                    }
                }
            },

            -- Trait with mixed tool formats and all function types
            ["wippy.agents:mixed_tools_trait"] = {
                id = "wippy.agents:mixed_tools_trait",
                kind = "registry.entry",
                meta = {
                    type = "agent.trait",
                    name = "Mixed Tools",
                    comment = "Trait with both old and new tool formats and all function types."
                },
                data = {
                    prompt = "You have access to various tools.",
                    tools = {
                        "wippy.tools:calculator",  -- Old format
                        {
                            id = "wippy.tools:weather",  -- New format
                            context = {
                                api_key = "weather_api_key",
                                units = "metric"
                            }
                        },
                        "wippy.tools:translator",  -- Old format again
                        {
                            id = "wippy.tools:code_analyzer",  -- New format again
                            context = {
                                language_support = {"python", "javascript", "lua"},
                                max_file_size = "5MB"
                            }
                        }
                    },
                    build_func_id = "init_mixed_tools",
                    prompt_func_id = "generate_context_prompt",
                    step_func_id = "enhance_tool_results",
                    context = {
                        global_timeout = 45
                    }
                }
            },

            -- Context-aware trait with runtime functions
            ["wippy.agents:context_aware_trait"] = {
                id = "wippy.agents:context_aware_trait",
                kind = "registry.entry",
                meta = {
                    type = "agent.trait",
                    name = "Context Aware",
                    comment = "Trait that adapts behavior based on runtime context."
                },
                data = {
                    prompt = "You adapt your responses based on the current context.",
                    prompt_func_id = "generate_context_aware_prompt",
                    step_func_id = "modify_context_response",
                    context = {
                        adaptation_level = "high",
                        context_sensitivity = true
                    }
                }
            },

            -- Time-aware trait (like the real one)
            ["wippy.agent.traits:time_aware"] = {
                id = "wippy.agent.traits:time_aware",
                kind = "registry.entry",
                meta = {
                    type = "agent.trait",
                    name = "Time Aware",
                    comment = "Adds current time context to agent for time-aware responses with cache stability."
                },
                data = {
                    build_func_id = "wippy.agent.traits:init_time_aware",
                    context = {
                        time_interval = 15,
                        timezone = "UTC"
                    }
                }
            },

            -- Non-trait entry for validation
            ["wippy.agents:non_trait_entry"] = {
                id = "wippy.agents:non_trait_entry",
                kind = "registry.entry",
                meta = {
                    type = "something.else",
                    name = "Not A Trait",
                    comment = "This is not a trait entry."
                },
                data = {
                    some_field = "some value"
                }
            }
        }

        local mock_registry

        before_each(function()
            -- Create mock registry for testing
            mock_registry = {
                get = function(id)
                    return trait_entries[id]
                end,
                find = function(query)
                    local results = {}

                    for _, entry in pairs(trait_entries) do
                        local matches = true

                        -- Match on kind
                        if query[".kind"] and entry.kind ~= query[".kind"] then
                            matches = false
                        end

                        -- Match on meta.type
                        if query["meta.type"] and entry.meta.type ~= query["meta.type"] then
                            matches = false
                        end

                        -- Match on meta.name
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

            -- Inject mock registry
            traits._registry = mock_registry
        end)

        after_each(function()
            -- Reset the injected registry
            traits._registry = nil
        end)

        -- Basic functionality tests
        it("should get a basic trait by ID", function()
            local trait, err = traits.get_by_id("wippy.agents:conversational")

            expect(err).to_be_nil()
            expect(trait).not_to_be_nil()
            expect(trait.id).to_equal("wippy.agents:conversational")
            expect(trait.name).to_equal("Conversational")
            expect(trait.description).to_equal("Trait that makes agents conversational and friendly.")
            expect(trait.prompt).to_contain("You are a friendly, conversational assistant")
            expect(trait.tools).not_to_be_nil()
            expect(#trait.tools).to_equal(0)
            expect(trait.build_func_id).to_be_nil() -- No build function
            expect(trait.prompt_func_id).to_be_nil() -- No prompt function
            expect(trait.step_func_id).to_be_nil() -- No step function
            expect(trait.context).not_to_be_nil()
            expect(next(trait.context)).to_be_nil() -- Empty context
        end)

        it("should get trait with old format tools", function()
            local trait, err = traits.get_by_id("wippy.agents:search_trait")

            expect(err).to_be_nil()
            expect(trait).not_to_be_nil()
            expect(trait.id).to_equal("wippy.agents:search_trait")
            expect(#trait.tools).to_equal(2)

            -- Check first tool (old format)
            expect(trait.tools[1].id).to_equal("wippy.tools:search_web")
            expect(trait.tools[1].context).to_be_nil()

            -- Check second tool (old format)
            expect(trait.tools[2].id).to_equal("wippy.tools:browse_url")
            expect(trait.tools[2].context).to_be_nil()
        end)

        it("should get trait with build_func_id and context", function()
            local trait, err = traits.get_by_id("mcp.traits:filesystem")

            expect(err).to_be_nil()
            expect(trait).not_to_be_nil()
            expect(trait.id).to_equal("mcp.traits:filesystem")
            expect(trait.name).to_equal("MCP Filesystem")
            expect(trait.build_func_id).to_equal("init_filesystem_mcp")
            expect(trait.prompt_func_id).to_be_nil() -- No prompt function
            expect(trait.step_func_id).to_be_nil() -- No step function

            -- Check context
            expect(trait.context).not_to_be_nil()
            expect(trait.context.default_timeout).to_equal(30)
            expect(trait.context.default_encoding).to_equal("utf-8")
            expect(trait.context.max_file_size).to_equal("10MB")
        end)

        it("should get trait with new format tools", function()
            local trait, err = traits.get_by_id("wippy.agents:database_trait")

            expect(err).to_be_nil()
            expect(trait).not_to_be_nil()
            expect(#trait.tools).to_equal(2)

            -- Check first tool (new format)
            expect(trait.tools[1].id).to_equal("db.tools:execute_query")
            expect(trait.tools[1].context).not_to_be_nil()
            expect(trait.tools[1].context.database_type).to_equal("postgresql")
            expect(trait.tools[1].context.max_query_time).to_equal(60)

            -- Check second tool (new format)
            expect(trait.tools[2].id).to_equal("db.tools:describe_table")
            expect(trait.tools[2].context).not_to_be_nil()
            expect(trait.tools[2].context.include_indexes).to_be_true()
        end)

        it("should handle mixed tool formats and all function types", function()
            local trait, err = traits.get_by_id("wippy.agents:mixed_tools_trait")

            expect(err).to_be_nil()
            expect(trait).not_to_be_nil()
            expect(#trait.tools).to_equal(4)
            expect(trait.build_func_id).to_equal("init_mixed_tools")
            expect(trait.prompt_func_id).to_equal("generate_context_prompt")
            expect(trait.step_func_id).to_equal("enhance_tool_results")
            expect(trait.context.global_timeout).to_equal(45)

            -- Check old format tools
            expect(trait.tools[1].id).to_equal("wippy.tools:calculator")
            expect(trait.tools[3].id).to_equal("wippy.tools:translator")

            -- Check new format tools
            expect(trait.tools[2].id).to_equal("wippy.tools:weather")
            expect(trait.tools[2].context.api_key).to_equal("weather_api_key")
            expect(trait.tools[2].context.units).to_equal("metric")

            expect(trait.tools[4].id).to_equal("wippy.tools:code_analyzer")
            expect(trait.tools[4].context.max_file_size).to_equal("5MB")
            expect(#trait.tools[4].context.language_support).to_equal(3)
        end)

        it("should handle context-aware trait with runtime functions", function()
            local trait, err = traits.get_by_id("wippy.agents:context_aware_trait")

            expect(err).to_be_nil()
            expect(trait).not_to_be_nil()
            expect(trait.id).to_equal("wippy.agents:context_aware_trait")
            expect(trait.name).to_equal("Context Aware")
            expect(trait.build_func_id).to_be_nil() -- No build function
            expect(trait.prompt_func_id).to_equal("generate_context_aware_prompt")
            expect(trait.step_func_id).to_equal("modify_context_response")
            expect(trait.context.adaptation_level).to_equal("high")
            expect(trait.context.context_sensitivity).to_be_true()
        end)

        it("should handle time-aware trait like the real implementation", function()
            local trait, err = traits.get_by_id("wippy.agent.traits:time_aware")

            expect(err).to_be_nil()
            expect(trait).not_to_be_nil()
            expect(trait.id).to_equal("wippy.agent.traits:time_aware")
            expect(trait.name).to_equal("Time Aware")
            expect(trait.build_func_id).to_equal("wippy.agent.traits:init_time_aware")
            expect(trait.prompt_func_id).to_be_nil() -- No runtime prompt function
            expect(trait.step_func_id).to_be_nil() -- No step function
            expect(trait.prompt).to_equal("") -- No static prompt
            expect(trait.context.time_interval).to_equal(15)
            expect(trait.context.timezone).to_equal("UTC")
        end)

        it("should handle trait not found by ID", function()
            local trait, err = traits.get_by_id("nonexistent")

            expect(trait).to_be_nil()
            expect(err).not_to_be_nil()
            expect(err:match("No trait found")).not_to_be_nil()
        end)

        it("should validate entry is a trait when getting by ID", function()
            local trait, err = traits.get_by_id("wippy.agents:non_trait_entry")

            expect(trait).to_be_nil()
            expect(err).not_to_be_nil()
            expect(err:match("Entry is not a trait")).not_to_be_nil()
        end)

        it("should get trait by name with features", function()
            local trait, err = traits.get_by_name("MCP Filesystem")

            expect(err).to_be_nil()
            expect(trait).not_to_be_nil()
            expect(trait.name).to_equal("MCP Filesystem")
            expect(trait.id).to_equal("mcp.traits:filesystem")
            expect(trait.build_func_id).to_equal("init_filesystem_mcp")
            expect(trait.prompt_func_id).to_be_nil()
            expect(trait.step_func_id).to_be_nil()
        end)

        it("should get all available traits with processing", function()
            local all_traits = traits.get_all()

            -- Should find all valid traits (excluding non-trait entry)
            expect(#all_traits).to_equal(7)

            -- Check that all traits have required fields
            for _, trait in ipairs(all_traits) do
                expect(trait.id).not_to_be_nil()
                expect(trait.tools).not_to_be_nil()
                expect(trait.context).not_to_be_nil()

                -- Function IDs can be nil or string
                if trait.build_func_id then
                    expect(type(trait.build_func_id)).to_equal("string")
                end
                if trait.prompt_func_id then
                    expect(type(trait.prompt_func_id)).to_equal("string")
                end
                if trait.step_func_id then
                    expect(type(trait.step_func_id)).to_equal("string")
                end
            end
        end)

        it("should handle empty tools properly", function()
            local trait, err = traits.get_by_id("wippy.agents:conversational")

            expect(err).to_be_nil()
            expect(trait.tools).not_to_be_nil()
            expect(#trait.tools).to_equal(0)
            expect(type(trait.tools)).to_equal("table")
        end)

        it("should require parameter for get_by_id", function()
            local trait, err = traits.get_by_id(nil)

            expect(trait).to_be_nil()
            expect(err).to_equal("Trait ID is required")
        end)

        it("should require parameter for get_by_name", function()
            local trait, err = traits.get_by_name(nil)

            expect(trait).to_be_nil()
            expect(err).to_equal("Trait name is required")
        end)

        it("should handle empty result when getting all traits", function()
            -- Create a mock registry that returns empty results
            traits._registry = {
                find = function(query)
                    return {}
                end
            }

            local all_traits = traits.get_all()
            expect(#all_traits).to_equal(0)
        end)

        it("should handle malformed tool objects", function()
            -- Add a trait with malformed tool object (missing id)
            trait_entries["test:malformed"] = {
                id = "test:malformed",
                kind = "registry.entry",
                meta = {
                    type = "agent.trait",
                    name = "Malformed Tools"
                },
                data = {
                    prompt = "Test",
                    tools = {
                        "valid:tool",  -- Valid old format
                        { context = { key = "value" } },  -- Missing id - should be skipped
                        { id = "valid:new_tool", context = {} }  -- Valid new format
                    }
                }
            }

            local trait, err = traits.get_by_id("test:malformed")

            expect(err).to_be_nil()
            expect(trait).not_to_be_nil()
            expect(#trait.tools).to_equal(2)  -- Only valid tools included
            expect(trait.tools[1].id).to_equal("valid:tool")
            expect(trait.tools[2].id).to_equal("valid:new_tool")
        end)

        it("should handle trait with only runtime functions", function()
            local trait, err = traits.get_by_id("wippy.agents:context_aware_trait")

            expect(err).to_be_nil()
            expect(trait).not_to_be_nil()
            expect(trait.build_func_id).to_be_nil() -- No compile-time function
            expect(trait.prompt_func_id).not_to_be_nil() -- Has runtime prompt function
            expect(trait.step_func_id).not_to_be_nil() -- Has runtime step function
            expect(#trait.tools).to_equal(0) -- No tools
        end)

        it("should preserve all function IDs in trait specs", function()
            local trait, err = traits.get_by_id("wippy.agents:mixed_tools_trait")

            expect(err).to_be_nil()
            expect(trait).not_to_be_nil()

            -- All three function types should be preserved
            expect(trait.build_func_id).to_equal("init_mixed_tools")
            expect(trait.prompt_func_id).to_equal("generate_context_prompt")
            expect(trait.step_func_id).to_equal("enhance_tool_results")
        end)
    end)
end

return require("test").run_cases(define_tests)