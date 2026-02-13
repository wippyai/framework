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
                    return (trait_entries :: any)[id]
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

            test.is_nil(err)
            test.not_nil(trait)
            test.eq(trait.id, "wippy.agents:conversational")
            test.eq(trait.name, "Conversational")
            test.eq(trait.description, "Trait that makes agents conversational and friendly.")
            test.contains(trait.prompt, "You are a friendly, conversational assistant")
            test.not_nil(trait.tools)
            test.eq(#trait.tools, 0)
            test.is_nil(trait.build_func_id) -- No build function
            test.is_nil(trait.prompt_func_id) -- No prompt function
            test.is_nil(trait.step_func_id) -- No step function
            test.not_nil(trait.context)
            test.is_nil(next(trait.context)) -- Empty context
        end)

        it("should get trait with old format tools", function()
            local trait, err = traits.get_by_id("wippy.agents:search_trait")

            test.is_nil(err)
            test.not_nil(trait)
            test.eq(trait.id, "wippy.agents:search_trait")
            test.eq(#trait.tools, 2)

            -- Check first tool (old format)
            test.eq(trait.tools[1].id, "wippy.tools:search_web")
            test.is_nil(trait.tools[1].context)

            -- Check second tool (old format)
            test.eq(trait.tools[2].id, "wippy.tools:browse_url")
            test.is_nil(trait.tools[2].context)
        end)

        it("should get trait with build_func_id and context", function()
            local trait, err = traits.get_by_id("mcp.traits:filesystem")

            test.is_nil(err)
            test.not_nil(trait)
            test.eq(trait.id, "mcp.traits:filesystem")
            test.eq(trait.name, "MCP Filesystem")
            test.eq(trait.build_func_id, "init_filesystem_mcp")
            test.is_nil(trait.prompt_func_id) -- No prompt function
            test.is_nil(trait.step_func_id) -- No step function

            -- Check context
            test.not_nil(trait.context)
            test.eq(trait.context.default_timeout, 30)
            test.eq(trait.context.default_encoding, "utf-8")
            test.eq(trait.context.max_file_size, "10MB")
        end)

        it("should get trait with new format tools", function()
            local trait, err = traits.get_by_id("wippy.agents:database_trait")

            test.is_nil(err)
            test.not_nil(trait)
            test.eq(#trait.tools, 2)

            -- Check first tool (new format)
            test.eq(trait.tools[1].id, "db.tools:execute_query")
            test.not_nil(trait.tools[1].context)
            test.eq(trait.tools[1].context.database_type, "postgresql")
            test.eq(trait.tools[1].context.max_query_time, 60)

            -- Check second tool (new format)
            test.eq(trait.tools[2].id, "db.tools:describe_table")
            test.not_nil(trait.tools[2].context)
            test.is_true(trait.tools[2].context.include_indexes)
        end)

        it("should handle mixed tool formats and all function types", function()
            local trait, err = traits.get_by_id("wippy.agents:mixed_tools_trait")

            test.is_nil(err)
            test.not_nil(trait)
            test.eq(#trait.tools, 4)
            test.eq(trait.build_func_id, "init_mixed_tools")
            test.eq(trait.prompt_func_id, "generate_context_prompt")
            test.eq(trait.step_func_id, "enhance_tool_results")
            test.eq(trait.context.global_timeout, 45)

            -- Check old format tools
            test.eq(trait.tools[1].id, "wippy.tools:calculator")
            test.eq(trait.tools[3].id, "wippy.tools:translator")

            -- Check new format tools
            test.eq(trait.tools[2].id, "wippy.tools:weather")
            test.eq(trait.tools[2].context.api_key, "weather_api_key")
            test.eq(trait.tools[2].context.units, "metric")

            test.eq(trait.tools[4].id, "wippy.tools:code_analyzer")
            test.eq(trait.tools[4].context.max_file_size, "5MB")
            test.eq(#trait.tools[4].context.language_support, 3)
        end)

        it("should handle context-aware trait with runtime functions", function()
            local trait, err = traits.get_by_id("wippy.agents:context_aware_trait")

            test.is_nil(err)
            test.not_nil(trait)
            test.eq(trait.id, "wippy.agents:context_aware_trait")
            test.eq(trait.name, "Context Aware")
            test.is_nil(trait.build_func_id) -- No build function
            test.eq(trait.prompt_func_id, "generate_context_aware_prompt")
            test.eq(trait.step_func_id, "modify_context_response")
            test.eq(trait.context.adaptation_level, "high")
            test.is_true(trait.context.context_sensitivity)
        end)

        it("should handle time-aware trait like the real implementation", function()
            local trait, err = traits.get_by_id("wippy.agent.traits:time_aware")

            test.is_nil(err)
            test.not_nil(trait)
            test.eq(trait.id, "wippy.agent.traits:time_aware")
            test.eq(trait.name, "Time Aware")
            test.eq(trait.build_func_id, "wippy.agent.traits:init_time_aware")
            test.is_nil(trait.prompt_func_id) -- No runtime prompt function
            test.is_nil(trait.step_func_id) -- No step function
            test.eq(trait.prompt, "") -- No static prompt
            test.eq(trait.context.time_interval, 15)
            test.eq(trait.context.timezone, "UTC")
        end)

        it("should handle trait not found by ID", function()
            local trait, err = traits.get_by_id("nonexistent")

            test.is_nil(trait)
            test.not_nil(err)
            test.not_nil(err:match("No trait found"))
        end)

        it("should validate entry is a trait when getting by ID", function()
            local trait, err = traits.get_by_id("wippy.agents:non_trait_entry")

            test.is_nil(trait)
            test.not_nil(err)
            test.not_nil(err:match("Entry is not a trait"))
        end)

        it("should get trait by name with features", function()
            local trait, err = traits.get_by_name("MCP Filesystem")

            test.is_nil(err)
            test.not_nil(trait)
            test.eq(trait.name, "MCP Filesystem")
            test.eq(trait.id, "mcp.traits:filesystem")
            test.eq(trait.build_func_id, "init_filesystem_mcp")
            test.is_nil(trait.prompt_func_id)
            test.is_nil(trait.step_func_id)
        end)

        it("should get all available traits with processing", function()
            local all_traits = traits.get_all()

            -- Should find all valid traits (excluding non-trait entry)
            test.eq(#all_traits, 7)

            -- Check that all traits have required fields
            for _, trait in ipairs(all_traits) do
                test.not_nil(trait.id)
                test.not_nil(trait.tools)
                test.not_nil(trait.context)

                -- Function IDs can be nil or string
                if trait.build_func_id then
                    test.eq(type(trait.build_func_id), "string")
                end
                if trait.prompt_func_id then
                    test.eq(type(trait.prompt_func_id), "string")
                end
                if trait.step_func_id then
                    test.eq(type(trait.step_func_id), "string")
                end
            end
        end)

        it("should handle empty tools properly", function()
            local trait, err = traits.get_by_id("wippy.agents:conversational")

            test.is_nil(err)
            test.not_nil(trait.tools)
            test.eq(#trait.tools, 0)
            test.eq(type(trait.tools), "table")
        end)

        it("should require parameter for get_by_id", function()
            local trait, err = traits.get_by_id(nil :: string)

            test.is_nil(trait)
            test.eq(err, "Trait ID is required")
        end)

        it("should require parameter for get_by_name", function()
            local trait, err = traits.get_by_name(nil :: string)

            test.is_nil(trait)
            test.eq(err, "Trait name is required")
        end)

        it("should handle empty result when getting all traits", function()
            -- Create a mock registry that returns empty results
            traits._registry = {
                find = function(query)
                    return {}
                end
            }

            local all_traits = traits.get_all()
            test.eq(#all_traits, 0)
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

            test.is_nil(err)
            test.not_nil(trait)
            test.eq(#trait.tools, 2)  -- Only valid tools included
            test.eq(trait.tools[1].id, "valid:tool")
            test.eq(trait.tools[2].id, "valid:new_tool")
        end)

        it("should handle trait with only runtime functions", function()
            local trait, err = traits.get_by_id("wippy.agents:context_aware_trait")

            test.is_nil(err)
            test.not_nil(trait)
            test.is_nil(trait.build_func_id) -- No compile-time function
            test.not_nil(trait.prompt_func_id) -- Has runtime prompt function
            test.not_nil(trait.step_func_id) -- Has runtime step function
            test.eq(#trait.tools, 0) -- No tools
        end)

        it("should preserve all function IDs in trait specs", function()
            local trait, err = traits.get_by_id("wippy.agents:mixed_tools_trait")

            test.is_nil(err)
            test.not_nil(trait)

            -- All three function types should be preserved
            test.eq(trait.build_func_id, "init_mixed_tools")
            test.eq(trait.prompt_func_id, "generate_context_prompt")
            test.eq(trait.step_func_id, "enhance_tool_results")
        end)
    end)
end

return require("test").run_cases(define_tests)