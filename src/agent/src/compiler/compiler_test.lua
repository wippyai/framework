local compiler = require("compiler")

local function define_tests()
    describe("Agent Compiler", function()
        local mock_traits
        local mock_tools
        local mock_funcs

        local minimal_spec = {
            id = "test:minimal",
            name = "Minimal Agent",
            description = "A minimal test agent",
            model = "gpt-4o-mini",
            prompt = "You are a test agent."
        }

        local spec_with_traits = {
            id = "test:with_traits",
            name = "Agent With Traits",
            description = "Agent with trait processing",
            model = "gpt-4o-mini",
            prompt = "You are a test agent with traits.",
            context = {
                agent_setting = "agent_value",
                shared_setting = "agent_overrides_trait"
            },
            traits = {
                "static_trait",
                {
                    id = "dynamic_trait",
                    context = {
                        trait_instance_setting = "instance_value",
                        shared_setting = "instance_overrides_all"
                    }
                }
            },
            tools = {
                "basic:tool",
                {
                    id = "advanced:tool",
                    context = { tool_setting = "tool_value" }
                }
            }
        }

        local spec_with_trait_names = {
            id = "test:trait_names",
            name = "Agent With Trait Names",
            description = "Agent with trait names instead of IDs",
            model = "gpt-4o-mini",
            prompt = "You are a test agent with trait names.",
            traits = {
                "Static Trait",
                "Dynamic Trait"
            }
        }

        local spec_with_tool_schemas = {
            id = "test:with_tool_schemas",
            name = "Agent With Tool Schemas",
            description = "Agent with trait-generated tool schemas",
            model = "gpt-4o-mini",
            prompt = "You are a test agent with dynamic tool schemas.",
            traits = {
                "schema_generating_trait"
            }
        }

        local spec_with_delegates = {
            id = "test:with_delegates",
            name = "Agent With Delegates",
            description = "Agent with delegate processing",
            model = "gpt-4o-mini",
            prompt = "You are a test agent with delegates.",
            delegates = {
                {
                    id = "specialist:agent",
                    name = "to_specialist",
                    rule = "Forward complex questions to specialist"
                },
                {
                    id = "helper:agent",
                    name = "to_helper",
                    rule = "Forward simple questions to helper"
                }
            }
        }

        local spec_with_wildcards = {
            id = "test:wildcards",
            name = "Agent With Wildcards",
            description = "Agent with wildcard tools",
            model = "gpt-4o-mini",
            prompt = "You are a test agent with wildcard tools.",
            tools = {
                "regular:*",
                "special:tool1"
            }
        }

        local spec_with_dynamic_delegates = {
            id = "test:dynamic_delegates",
            name = "Agent With Dynamic Delegates",
            description = "Agent with trait-generated delegates",
            model = "gpt-4o-mini",
            prompt = "You are a coordinator agent.",
            traits = {
                "delegate_generating_trait"
            }
        }

        local spec_with_complex_traits = {
            id = "test:complex",
            name = "Complex Agent",
            description = "Agent with multiple dynamic traits",
            model = "gpt-4o-mini",
            prompt = "You are a complex agent.",
            context = {
                enable_data_analysis = true,
                enable_coding = true,
                workspace = "/complex/workspace"
            },
            traits = {
                "dynamic_trait",
                "delegate_generating_trait",
                "schema_generating_trait"
            },
            delegates = {
                {
                    id = "static:delegate",
                    name = "to_static",
                    rule = "Static delegate rule"
                }
            }
        }

        local spec_for_agent_id_tests = {
            id = "test:agent_id_verification",
            name = "Agent ID Verification Agent",
            description = "Agent for testing agent_id propagation",
            model = "gpt-4o-mini",
            prompt = "You are an agent for testing agent_id.",
            context = {
                test_setting = "test_value"
            },
            traits = {
                "static_trait",
                "dynamic_trait"
            },
            tools = {
                "basic:tool",
                {
                    id = "advanced:tool",
                    context = { tool_specific = "tool_value" }
                },
                "regular:*"
            }
        }

        local spec_with_inline_tools = {
            id = "test:inline_tools",
            name = "Agent With Inline Tools",
            description = "Agent with inline tool schemas",
            model = "gpt-4o-mini",
            prompt = "You are an agent with inline tools.",
            tools = {
                {
                    id = "finish",
                    name = "finish",
                    description = "Complete the task with final answer",
                    context = {
                        is_exit_tool = true,
                        priority = "high"
                    },
                    schema = {
                        type = "object",
                        properties = {
                            final_answer = {
                                type = "string",
                                description = "Your complete final answer"
                            },
                            reasoning = {
                                type = "string",
                                description = "Brief explanation of reasoning"
                            },
                            tools_used = {
                                type = "array",
                                items = { type = "string" },
                                description = "List of tools used"
                            }
                        },
                        required = { "final_answer" }
                    }
                },
                {
                    id = "custom_calculator",
                    description = "Custom inline calculator tool",
                    schema = {
                        type = "object",
                        properties = {
                            operation = {
                                type = "string",
                                enum = {"add", "subtract", "multiply", "divide"}
                            },
                            operands = {
                                type = "array",
                                items = { type = "number" },
                                minItems = 2
                            }
                        },
                        required = {"operation", "operands"}
                    }
                }
            }
        }

        local spec_with_mixed_tools = {
            id = "test:mixed_tools",
            name = "Agent With Mixed Tools",
            description = "Agent with both registry and inline tools",
            model = "gpt-4o-mini",
            prompt = "You are an agent with mixed tool types.",
            tools = {
                "basic:tool",
                {
                    id = "exit_tool",
                    description = "Inline exit tool",
                    context = { exit_context = "value" },
                    schema = {
                        type = "object",
                        properties = {
                            result = { type = "string" },
                            success = { type = "boolean", default = true }
                        },
                        required = {"result"}
                    }
                },
                "advanced:tool"
            }
        }

        local spec_with_alias_and_inline = {
            id = "test:alias_inline",
            name = "Agent With Alias and Inline",
            description = "Agent with aliased inline tools",
            model = "gpt-4o-mini",
            prompt = "You are an agent with aliased inline tools.",
            tools = {
                {
                    id = "complex_inline_tool",
                    alias = "simple_name",
                    description = "Complex tool with simple alias",
                    context = { aliased = true },
                    schema = {
                        type = "object",
                        properties = {
                            input = { type = "string" },
                            config = {
                                type = "object",
                                properties = {
                                    mode = { type = "string", enum = {"fast", "accurate"} }
                                }
                            }
                        },
                        required = {"input"}
                    }
                }
            }
        }

        local spec_with_incomplete_inline = {
            id = "test:incomplete_inline",
            name = "Agent With Incomplete Inline Tools",
            description = "Agent with inline tools missing schemas",
            model = "gpt-4o-mini",
            prompt = "You are an agent with incomplete inline tools.",
            tools = {
                {
                    id = "missing_schema",
                    description = "Tool without schema"
                },
                {
                    id = "with_schema",
                    schema = {
                        type = "object",
                        properties = { input = { type = "string" } }
                    }
                }
            }
        }

        local spec_with_runtime_traits = {
            id = "test:runtime_traits",
            name = "Agent With Runtime Traits",
            description = "Agent with runtime prompt and step functions",
            model = "gpt-4o-mini",
            prompt = "You are an agent with runtime traits.",
            traits = {
                "context_aware_trait",
                "step_modifying_trait"
            }
        }

        local spec_with_mixed_trait_functions = {
            id = "test:mixed_trait_functions",
            name = "Agent With Mixed Trait Functions",
            description = "Agent with traits having different function combinations",
            model = "gpt-4o-mini",
            prompt = "You are an agent with mixed trait functions.",
            traits = {
                "static_trait",
                "dynamic_trait",
                "context_aware_trait",
                "prompt_only_trait"
            }
        }

        local trait_definitions = {
            static_trait = {
                id = "static_trait",
                name = "Static Trait",
                description = "A static trait",
                prompt = "You have static capabilities.",
                tools = {
                    { id = "static:tool", context = { static_setting = "static_value" } }
                },
                context = {
                    trait_setting = "trait_value",
                    shared_setting = "trait_default"
                },
                build_func_id = nil
            },
            dynamic_trait = {
                id = "dynamic_trait",
                name = "Dynamic Trait",
                description = "A dynamic trait with build method",
                prompt = "You have dynamic capabilities.",
                tools = {},
                context = {
                    dynamic_default = "default_value"
                },
                build_func_id = "init_dynamic_trait"
            },
            schema_generating_trait = {
                id = "schema_generating_trait",
                name = "Schema Generating Trait",
                description = "A trait that generates custom tool schemas",
                prompt = "You have custom tools.",
                tools = {},
                context = {},
                build_func_id = "init_schema_generating_trait"
            },
            delegate_generating_trait = {
                id = "delegate_generating_trait",
                name = "Delegate Generating Trait",
                description = "A trait that generates dynamic delegates",
                prompt = "You can delegate tasks dynamically.",
                tools = {},
                context = {},
                build_func_id = "init_delegate_generating_trait"
            },
            context_aware_trait = {
                id = "context_aware_trait",
                name = "Context Aware Trait",
                description = "A trait with runtime functions",
                prompt = "You adapt based on context.",
                tools = {},
                context = {
                    adaptation_level = "high"
                },
                prompt_func_id = "generate_context_prompt",
                step_func_id = "modify_context_response"
            },
            step_modifying_trait = {
                id = "step_modifying_trait",
                name = "Step Modifying Trait",
                description = "A trait that only modifies step results",
                prompt = "",
                tools = {},
                context = {
                    enhance_results = true
                },
                step_func_id = "enhance_step_results"
            },
            prompt_only_trait = {
                id = "prompt_only_trait",
                name = "Prompt Only Trait",
                description = "A trait with only prompt generation",
                prompt = "",
                tools = {},
                context = {
                    dynamic_prompts = true
                },
                prompt_func_id = "generate_dynamic_prompt"
            }
        }

        local trait_names = {
            ["Static Trait"] = trait_definitions.static_trait,
            ["Dynamic Trait"] = trait_definitions.dynamic_trait,
            ["Schema Generating Trait"] = trait_definitions.schema_generating_trait,
            ["Delegate Generating Trait"] = trait_definitions.delegate_generating_trait,
            ["Context Aware Trait"] = trait_definitions.context_aware_trait,
            ["Step Modifying Trait"] = trait_definitions.step_modifying_trait,
            ["Prompt Only Trait"] = trait_definitions.prompt_only_trait
        }

        local tool_registry = {
            ["basic:tool"] = { id = "basic:tool", meta = { type = "tool" } },
            ["advanced:tool"] = { id = "advanced:tool", meta = { type = "tool" } },
            ["static:tool"] = { id = "static:tool", meta = { type = "tool" } },
            ["regular:tool"] = { id = "regular:tool", meta = { type = "tool" } },
            ["regular:calculator"] = { id = "regular:calculator", meta = { type = "tool" } },
            ["regular:validator"] = { id = "regular:validator", meta = { type = "tool" } },
            ["special:tool1"] = { id = "special:tool1", meta = { type = "tool" } },
            ["special:tool2"] = { id = "special:tool2", meta = { type = "tool" } },
            ["db:query"] = { id = "db:query", meta = { type = "tool" } },
            ["fs:read"] = { id = "fs:read", meta = { type = "tool" } }
        }

        before_each(function()
            mock_traits = {
                get_by_id = function(trait_id)
                    local trait_def = trait_definitions[trait_id]
                    if trait_def then
                        return trait_def
                    else
                        return nil, "No trait found with ID: " .. trait_id
                    end
                end,
                get_by_name = function(trait_name)
                    local trait_def = trait_names[trait_name]
                    if trait_def then
                        return trait_def
                    else
                        return nil, "No trait found with name: " .. trait_name
                    end
                end
            }

            mock_tools = {
                find_tools = function(query)
                    local results = {}
                    if query.namespace then
                        local target_namespace = query.namespace
                        for id, entry in pairs(tool_registry) do
                            if entry.meta.type == "tool" then
                                local ns = id:match("^([^:]+):")
                                if ns == target_namespace then
                                    table.insert(results, entry)
                                end
                            end
                        end
                    end
                    return results
                end,

                get_tool_schema = function(tool_id)
                    local entry = tool_registry[tool_id]
                    if not entry then
                        return nil, "Tool not found: " .. tool_id
                    end

                    local parts = {}
                    for part in string.gmatch(tool_id, "[^:]+") do
                        table.insert(parts, part)
                    end
                    local name = #parts >= 2 and parts[#parts] or tool_id
                    name = name:gsub("[^%w]", "_"):gsub("([A-Z])", function(c) return "_" .. c:lower() end)
                    name = name:gsub("__+", "_"):gsub("^_", "")

                    return {
                        id = tool_id,
                        registry_id = tool_id,
                        name = name,
                        description = "Mock description for " .. tool_id,
                        schema = {
                            type = "object",
                            properties = {
                                input = {
                                    type = "string",
                                    description = "Mock input parameter"
                                }
                            },
                            required = {"input"}
                        }
                    }
                end
            }

            mock_funcs = {
                new = function()
                    return {
                        with_context = function(self, context)
                            return {
                                call = function(self, method_name, base_prompt, merged_context)
                                    if not merged_context.agent_id then
                                        return nil, "agent_id not found in context"
                                    end

                                    if method_name == "init_dynamic_trait" then
                                        return {
                                            tools = {
                                                {
                                                    id = "dynamic:generated_tool",
                                                    context = {
                                                        generated = true,
                                                        workspace = merged_context.workspace or "/default",
                                                        agent_id = merged_context.agent_id
                                                    }
                                                }
                                            },
                                            prompt = "Dynamic prompt for agent " .. merged_context.agent_id .. ": " .. (merged_context.trait_instance_setting or "none"),
                                            context = {
                                                trait_wide_setting = "from_init"
                                            }
                                        }
                                    elseif method_name == "init_schema_generating_trait" then
                                        return {
                                            tools = {
                                                {
                                                    id = "custom:api_client",
                                                    description = "Call external API with dynamic configuration",
                                                    context = {
                                                        api_endpoint = "https://api.example.com",
                                                        agent_id = merged_context.agent_id
                                                    },
                                                    schema = {
                                                        type = "object",
                                                        properties = {
                                                            endpoint = {
                                                                type = "string",
                                                                description = "API endpoint to call"
                                                            },
                                                            data = {
                                                                type = "object",
                                                                description = "Data to send"
                                                            }
                                                        },
                                                        required = { "endpoint" }
                                                    }
                                                },
                                                {
                                                    id = "custom:data_processor",
                                                    description = "Process data with custom schema",
                                                    schema = {
                                                        type = "object",
                                                        properties = {
                                                            operation = {
                                                                type = "string",
                                                                enum = {"filter", "transform", "aggregate"}
                                                            },
                                                            input_data = {
                                                                type = "array",
                                                                items = { type = "object" }
                                                            }
                                                        },
                                                        required = { "operation", "input_data" }
                                                    }
                                                }
                                            },
                                            prompt = "You can call external APIs and process data dynamically."
                                        }
                                    elseif method_name == "init_delegate_generating_trait" then
                                        local delegates = {}

                                        if merged_context.enable_data_analysis then
                                            table.insert(delegates, {
                                                id = "specialist:data_analyst",
                                                name = "to_data_analyst",
                                                rule = "Forward data analysis and visualization requests for agent " .. merged_context.agent_id
                                            })
                                        end

                                        if merged_context.enable_coding then
                                            table.insert(delegates, {
                                                id = "specialist:coder",
                                                name = "to_coder",
                                                rule = "Forward programming tasks to coding specialist"
                                            })
                                        end

                                        return {
                                            prompt = "You can delegate tasks to specialists based on context.",
                                            delegates = delegates,
                                            tools = {
                                                {
                                                    id = "delegation:tracker",
                                                    context = {
                                                        track_delegations = true,
                                                        agent_id = merged_context.agent_id
                                                    }
                                                }
                                            }
                                        }
                                    elseif method_name == "failing_init_method" then
                                        return nil, "Init method failed"
                                    else
                                        return {
                                            tools = {},
                                            prompt = "Default init response for " .. merged_context.agent_id
                                        }
                                    end
                                end
                            }
                        end
                    }
                end
            }

            compiler._traits = mock_traits
            compiler._tools = mock_tools
            compiler._funcs = mock_funcs
        end)

        after_each(function()
            compiler._traits = nil
            compiler._tools = nil
            compiler._funcs = nil
        end)

        local function count_tools(tools_table)
            local count = 0
            for _ in pairs(tools_table) do
                count = count + 1
            end
            return count
        end

        local function tool_exists(tools_table, canonical_name)
            return tools_table[canonical_name] ~= nil
        end

        local function has_delegate_tool(tools_table, tool_name)
            local tool = tools_table[tool_name]
            return tool and tool.agent_id ~= nil
        end

        it("should compile minimal agent spec", function()
            local compiled_spec, err = compiler.compile(minimal_spec)

            expect(err).to_be_nil()
            expect(compiled_spec).not_to_be_nil()
            expect(compiled_spec.id).to_equal("test:minimal")
            expect(compiled_spec.name).to_equal("Minimal Agent")
            expect(compiled_spec.prompt).to_equal("You are a test agent.")
            expect(compiled_spec.tools).not_to_be_nil()
            expect(count_tools(compiled_spec.tools)).to_equal(0)
            expect(compiled_spec.prompt_funcs).not_to_be_nil()
            expect(compiled_spec.step_funcs).not_to_be_nil()
            expect(#compiled_spec.prompt_funcs).to_equal(0)
            expect(#compiled_spec.step_funcs).to_equal(0)
        end)

        it("should handle nil spec", function()
            local compiled_spec, err = compiler.compile(nil)

            expect(compiled_spec).to_be_nil()
            expect(err).to_equal("Raw spec is required")
        end)

        describe("Runtime Trait Function Collection", function()
            it("should collect traits with prompt functions", function()
                local compiled_spec, err = compiler.compile(spec_with_runtime_traits)

                expect(err).to_be_nil()
                expect(compiled_spec).not_to_be_nil()

                expect(#compiled_spec.prompt_funcs).to_equal(1)
                local prompt_trait = compiled_spec.prompt_funcs[1]
                expect(prompt_trait.trait_id).to_equal("context_aware_trait")
                expect(prompt_trait.func_id).to_equal("generate_context_prompt")
                expect(prompt_trait.context.adaptation_level).to_equal("high")
            end)

            it("should collect traits with step functions", function()
                local compiled_spec, err = compiler.compile(spec_with_runtime_traits)

                expect(err).to_be_nil()
                expect(compiled_spec).not_to_be_nil()

                expect(#compiled_spec.step_funcs).to_equal(2)

                local trait_map = {}
                for _, trait in ipairs(compiled_spec.step_funcs) do
                    trait_map[trait.trait_id] = trait
                end

                expect(trait_map["context_aware_trait"]).not_to_be_nil()
                expect(trait_map["context_aware_trait"].func_id).to_equal("modify_context_response")
                expect(trait_map["context_aware_trait"].context.adaptation_level).to_equal("high")

                expect(trait_map["step_modifying_trait"]).not_to_be_nil()
                expect(trait_map["step_modifying_trait"].func_id).to_equal("enhance_step_results")
                expect(trait_map["step_modifying_trait"].context.enhance_results).to_be_true()
            end)

            it("should handle mixed trait function combinations", function()
                local compiled_spec, err = compiler.compile(spec_with_mixed_trait_functions)

                expect(err).to_be_nil()
                expect(compiled_spec).not_to_be_nil()

                expect(#compiled_spec.prompt_funcs).to_equal(2)
                expect(#compiled_spec.step_funcs).to_equal(1)

                local prompt_trait_map = {}
                for _, trait in ipairs(compiled_spec.prompt_funcs) do
                    prompt_trait_map[trait.trait_id] = trait
                end

                expect(prompt_trait_map["context_aware_trait"]).not_to_be_nil()
                expect(prompt_trait_map["prompt_only_trait"]).not_to_be_nil()
                expect(prompt_trait_map["prompt_only_trait"].func_id).to_equal("generate_dynamic_prompt")

                local step_trait_map = {}
                for _, trait in ipairs(compiled_spec.step_funcs) do
                    step_trait_map[trait.trait_id] = trait
                end

                expect(step_trait_map["context_aware_trait"]).not_to_be_nil()
                expect(step_trait_map["context_aware_trait"].func_id).to_equal("modify_context_response")
            end)

            it("should preserve trait contexts in runtime function collections", function()
                local compiled_spec, err = compiler.compile(spec_with_runtime_traits)

                expect(err).to_be_nil()
                expect(compiled_spec).not_to_be_nil()

                for _, trait in ipairs(compiled_spec.prompt_funcs) do
                    expect(trait.context).not_to_be_nil()
                    if trait.trait_id == "context_aware_trait" then
                        expect(trait.context.adaptation_level).to_equal("high")
                    end
                end

                for _, trait in ipairs(compiled_spec.step_funcs) do
                    expect(trait.context).not_to_be_nil()
                    if trait.trait_id == "step_modifying_trait" then
                        expect(trait.context.enhance_results).to_be_true()
                    end
                end
            end)

            it("should handle empty runtime function lists for agents without runtime traits", function()
                local compiled_spec, err = compiler.compile(minimal_spec)

                expect(err).to_be_nil()
                expect(compiled_spec).not_to_be_nil()
                expect(compiled_spec.prompt_funcs).not_to_be_nil()
                expect(compiled_spec.step_funcs).not_to_be_nil()
                expect(#compiled_spec.prompt_funcs).to_equal(0)
                expect(#compiled_spec.step_funcs).to_equal(0)
            end)

            it("should not include traits without runtime functions in runtime collections", function()
                local spec_with_static_traits = {
                    id = "test:static_only",
                    name = "Static Traits Only",
                    model = "gpt-4o-mini",
                    prompt = "Test agent",
                    traits = {
                        "static_trait",
                        "dynamic_trait"
                    }
                }

                local compiled_spec, err = compiler.compile(spec_with_static_traits)

                expect(err).to_be_nil()
                expect(compiled_spec).not_to_be_nil()
                expect(#compiled_spec.prompt_funcs).to_equal(0)
                expect(#compiled_spec.step_funcs).to_equal(0)
            end)
        end)

        describe("Unified Tool Structure Support", function()
            it("should handle basic inline tool schemas in unified structure", function()
                local compiled_spec, err = compiler.compile(spec_with_inline_tools)

                expect(err).to_be_nil()
                expect(compiled_spec).not_to_be_nil()

                expect(tool_exists(compiled_spec.tools, "finish")).to_be_true()
                expect(tool_exists(compiled_spec.tools, "custom_calculator")).to_be_true()

                local finish_tool = compiled_spec.tools["finish"]
                expect(finish_tool.name).to_equal("finish")
                expect(finish_tool.description).to_equal("Complete the task with final answer")
                expect(finish_tool.schema.type).to_equal("object")
                expect(finish_tool.schema.properties.final_answer).not_to_be_nil()
                expect(finish_tool.schema.properties.reasoning).not_to_be_nil()
                expect(finish_tool.schema.properties.tools_used).not_to_be_nil()
                expect(#finish_tool.schema.required).to_equal(1)
                expect(finish_tool.schema.required[1]).to_equal("final_answer")
                expect(finish_tool.registry_id).to_be_nil()

                local calc_tool = compiled_spec.tools["custom_calculator"]
                expect(calc_tool.name).to_equal("custom_calculator")
                expect(calc_tool.description).to_equal("Custom inline calculator tool")
                expect(calc_tool.schema.properties.operation).not_to_be_nil()
                expect(calc_tool.schema.properties.operands).not_to_be_nil()
                expect(calc_tool.registry_id).to_be_nil()

                expect(finish_tool.context).not_to_be_nil()
                expect(finish_tool.context.is_exit_tool).to_be_true()
                expect(finish_tool.context.priority).to_equal("high")
                expect(finish_tool.context.agent_id).to_equal("test:inline_tools")
            end)

            it("should handle mixed registry and inline tools in unified structure", function()
                local compiled_spec, err = compiler.compile(spec_with_mixed_tools)

                expect(err).to_be_nil()
                expect(compiled_spec).not_to_be_nil()

                expect(tool_exists(compiled_spec.tools, "tool")).to_be_true()
                expect(tool_exists(compiled_spec.tools, "exit_tool")).to_be_true()

                local registry_tool = compiled_spec.tools["tool"]
                expect(registry_tool.registry_id).not_to_be_nil()

                local inline_tool = compiled_spec.tools["exit_tool"]
                expect(inline_tool.registry_id).to_be_nil()
                expect(inline_tool.schema.properties.result).not_to_be_nil()
                expect(inline_tool.schema.properties.success).not_to_be_nil()

                expect(inline_tool.context.exit_context).to_equal("value")
                expect(inline_tool.context.agent_id).to_equal("test:mixed_tools")
            end)

            it("should handle aliased inline tools in unified structure", function()
                local compiled_spec, err = compiler.compile(spec_with_alias_and_inline)

                expect(err).to_be_nil()
                expect(compiled_spec).not_to_be_nil()

                expect(tool_exists(compiled_spec.tools, "simple_name")).to_be_true()

                local aliased_tool = compiled_spec.tools["simple_name"]
                expect(aliased_tool.name).to_equal("simple_name")
                expect(aliased_tool.description).to_equal("Complex tool with simple alias")
                expect(aliased_tool.schema.properties.input).not_to_be_nil()
                expect(aliased_tool.schema.properties.config).not_to_be_nil()

                expect(aliased_tool.context).not_to_be_nil()
                expect(aliased_tool.context.aliased).to_be_true()
                expect(aliased_tool.context.agent_id).to_equal("test:alias_inline")
            end)

            it("should handle inline tools without schemas gracefully in unified structure", function()
                local compiled_spec, err = compiler.compile(spec_with_incomplete_inline)

                expect(err).to_be_nil()
                expect(compiled_spec).not_to_be_nil()

                expect(tool_exists(compiled_spec.tools, "missing_schema")).to_be_true()
                expect(tool_exists(compiled_spec.tools, "with_schema")).to_be_true()

                local with_schema_tool = compiled_spec.tools["with_schema"]
                expect(with_schema_tool.schema).not_to_be_nil()
                expect(with_schema_tool.schema.properties.input).not_to_be_nil()

                local missing_schema_tool = compiled_spec.tools["missing_schema"]
                expect(missing_schema_tool.schema).to_be_nil()
                expect(missing_schema_tool.context).not_to_be_nil()
                expect(missing_schema_tool.context.agent_id).to_equal("test:incomplete_inline")
            end)

            it("should prioritize inline schemas over registry lookups in unified structure", function()
                local spec_with_override = {
                    id = "test:override",
                    name = "Override Test",
                    model = "gpt-4o-mini",
                    prompt = "Test override behavior",
                    tools = {
                        {
                            id = "basic:tool",
                            description = "Overridden description",
                            schema = {
                                type = "object",
                                properties = {
                                    custom_prop = { type = "string" }
                                }
                            }
                        }
                    }
                }

                local compiled_spec, err = compiler.compile(spec_with_override)

                expect(err).to_be_nil()
                expect(compiled_spec).not_to_be_nil()

                local tool = compiled_spec.tools["tool"]
                expect(tool).not_to_be_nil()
                expect(tool.description).to_equal("Overridden description")
                expect(tool.schema.properties.custom_prop).not_to_be_nil()
                expect(tool.schema.properties.input).to_be_nil()
                expect(tool.registry_id).to_be_nil()
            end)

            it("should handle complex inline schemas with nested objects in unified structure", function()
                local spec_with_complex_schema = {
                    id = "test:complex_schema",
                    name = "Complex Schema Test",
                    model = "gpt-4o-mini",
                    prompt = "Test complex schemas",
                    tools = {
                        {
                            id = "complex_tool",
                            description = "Tool with complex nested schema",
                            schema = {
                                type = "object",
                                properties = {
                                    config = {
                                        type = "object",
                                        properties = {
                                            mode = { type = "string", enum = {"fast", "accurate", "balanced"} },
                                            options = {
                                                type = "object",
                                                properties = {
                                                    timeout = { type = "integer", minimum = 0 },
                                                    retries = { type = "integer", default = 3 }
                                                }
                                            }
                                        },
                                        required = {"mode"}
                                    },
                                    data = {
                                        type = "array",
                                        items = {
                                            type = "object",
                                            properties = {
                                                id = { type = "string" },
                                                value = { type = "number" }
                                            },
                                            required = {"id", "value"}
                                        }
                                    }
                                },
                                required = {"config", "data"}
                            }
                        }
                    }
                }

                local compiled_spec, err = compiler.compile(spec_with_complex_schema)

                expect(err).to_be_nil()
                expect(compiled_spec).not_to_be_nil()

                local tool = compiled_spec.tools["complex_tool"]
                expect(tool).not_to_be_nil()
                expect(tool.schema.properties.config).not_to_be_nil()
                expect(tool.schema.properties.config.properties.mode).not_to_be_nil()
                expect(tool.schema.properties.config.properties.options).not_to_be_nil()
                expect(tool.schema.properties.data).not_to_be_nil()
                expect(tool.schema.properties.data.items.properties.id).not_to_be_nil()
                expect(#tool.schema.required).to_equal(2)
            end)

            it("should preserve agent_id in inline tool contexts in unified structure", function()
                local compiled_spec, err = compiler.compile(spec_with_inline_tools)

                expect(err).to_be_nil()
                expect(compiled_spec).not_to_be_nil()

                for tool_name, tool_data in pairs(compiled_spec.tools) do
                    expect(tool_data.context.agent_id).to_equal("test:inline_tools")
                end

                expect(compiled_spec.tools["finish"].context.agent_id).to_equal("test:inline_tools")
                expect(compiled_spec.tools["custom_calculator"].context.agent_id).to_equal("test:inline_tools")
            end)
        end)

        it("should compile agent with trait names (get_by_name fallback)", function()
            local compiled_spec, err = compiler.compile(spec_with_trait_names)

            expect(err).to_be_nil()
            expect(compiled_spec).not_to_be_nil()

            expect(compiled_spec.prompt).to_contain("You are a test agent with trait names.")
            expect(compiled_spec.prompt).to_contain("You have static capabilities.")
            expect(compiled_spec.prompt).to_contain("You have dynamic capabilities.")

            expect(tool_exists(compiled_spec.tools, "tool")).to_be_true()
            expect(tool_exists(compiled_spec.tools, "generated_tool")).to_be_true()
        end)

        it("should compile agent with static traits", function()
            local compiled_spec, err = compiler.compile(spec_with_traits)

            expect(err).to_be_nil()
            expect(compiled_spec).not_to_be_nil()

            expect(compiled_spec.prompt).to_contain("You are a test agent with traits.")
            expect(compiled_spec.prompt).to_contain("You have static capabilities.")
            expect(compiled_spec.prompt).to_contain("You have dynamic capabilities.")
            expect(compiled_spec.prompt).to_contain("Dynamic prompt for agent test:with_traits: instance_value")

            expect(tool_exists(compiled_spec.tools, "tool")).to_be_true()
            expect(tool_exists(compiled_spec.tools, "generated_tool")).to_be_true()

            local tool_data = compiled_spec.tools["tool"]
            expect(tool_data).not_to_be_nil()
            expect(tool_data.context.agent_setting).to_equal("agent_value")
            expect(tool_data.context.shared_setting).to_equal("agent_overrides_trait")

            local generated_tool_data = compiled_spec.tools["generated_tool"]
            expect(generated_tool_data).not_to_be_nil()
            expect(generated_tool_data.context.generated).to_be_true()
            expect(generated_tool_data.context.agent_id).to_equal("test:with_traits")
        end)

        it("should collect tool schemas from trait build methods in unified structure", function()
            local compiled_spec, err = compiler.compile(spec_with_tool_schemas)

            expect(err).to_be_nil()
            expect(compiled_spec).not_to_be_nil()

            expect(tool_exists(compiled_spec.tools, "api_client")).to_be_true()
            expect(tool_exists(compiled_spec.tools, "data_processor")).to_be_true()

            local api_tool = compiled_spec.tools["api_client"]
            expect(api_tool.name).to_equal("api_client")
            expect(api_tool.description).to_equal("Call external API with dynamic configuration")
            expect(api_tool.schema.type).to_equal("object")
            expect(api_tool.schema.properties.endpoint).not_to_be_nil()
            expect(api_tool.schema.properties.data).not_to_be_nil()
            expect(#api_tool.schema.required).to_equal(1)
            expect(api_tool.schema.required[1]).to_equal("endpoint")

            expect(api_tool.context).not_to_be_nil()
            expect(api_tool.context.api_endpoint).to_equal("https://api.example.com")
            expect(api_tool.context.agent_id).to_equal("test:with_tool_schemas")

            expect(compiled_spec.prompt).to_contain("You can call external APIs and process data dynamically.")
        end)

        it("should compile agent with delegates in unified tool structure", function()
            local config = {
                delegates = {
                    generate_tool_schemas = true,
                    description_suffix = ", this will end your response"
                }
            }

            local compiled_spec, err = compiler.compile(spec_with_delegates, config)

            expect(err).to_be_nil()
            expect(compiled_spec).not_to_be_nil()

            expect(tool_exists(compiled_spec.tools, "to_specialist")).to_be_true()
            expect(tool_exists(compiled_spec.tools, "to_helper")).to_be_true()

            expect(has_delegate_tool(compiled_spec.tools, "to_specialist")).to_be_true()
            expect(has_delegate_tool(compiled_spec.tools, "to_helper")).to_be_true()

            local specialist_tool = compiled_spec.tools["to_specialist"]
            expect(specialist_tool.agent_id).to_equal("specialist:agent")
            expect(specialist_tool.description).to_contain("Forward complex questions to specialist")
            expect(specialist_tool.description).to_contain(", this will end your response")

            local helper_tool = compiled_spec.tools["to_helper"]
            expect(helper_tool.agent_id).to_equal("helper:agent")
            expect(helper_tool.description).to_contain("Forward simple questions to helper")
        end)

        it("should not generate delegate tool schemas when disabled", function()
            local config = {
                delegates = {
                    generate_tool_schemas = false
                }
            }

            local compiled_spec, err = compiler.compile(spec_with_delegates, config)

            expect(err).to_be_nil()
            expect(compiled_spec).not_to_be_nil()

            expect(tool_exists(compiled_spec.tools, "to_specialist")).to_be_false()
            expect(tool_exists(compiled_spec.tools, "to_helper")).to_be_false()
        end)

        it("should resolve wildcard tools in unified structure", function()
            local compiled_spec, err = compiler.compile(spec_with_wildcards)

            expect(err).to_be_nil()
            expect(compiled_spec).not_to_be_nil()

            expect(tool_exists(compiled_spec.tools, "tool")).to_be_true()
            expect(tool_exists(compiled_spec.tools, "calculator")).to_be_true()
            expect(tool_exists(compiled_spec.tools, "validator")).to_be_true()
            expect(tool_exists(compiled_spec.tools, "tool1")).to_be_true()
        end)

        it("should create dynamic delegates based on context", function()
            local spec_with_enabled_features = {
                id = "test:enabled_features",
                name = "Enabled Features Agent",
                model = "gpt-4o-mini",
                prompt = "You are a dynamic agent.",
                context = {
                    enable_data_analysis = true,
                    enable_coding = true
                },
                traits = {
                    "delegate_generating_trait"
                }
            }

            local config = {
                delegates = {
                    generate_tool_schemas = true
                }
            }

            local compiled_spec, err = compiler.compile(spec_with_enabled_features, config)

            expect(err).to_be_nil()
            expect(compiled_spec).not_to_be_nil()

            expect(tool_exists(compiled_spec.tools, "to_data_analyst")).to_be_true()
            expect(tool_exists(compiled_spec.tools, "to_coder")).to_be_true()

            expect(has_delegate_tool(compiled_spec.tools, "to_data_analyst")).to_be_true()
            expect(has_delegate_tool(compiled_spec.tools, "to_coder")).to_be_true()

            local data_analyst_tool = compiled_spec.tools["to_data_analyst"]
            expect(data_analyst_tool.agent_id).to_equal("specialist:data_analyst")
            expect(data_analyst_tool.description).to_contain("test:enabled_features")

            local coder_tool = compiled_spec.tools["to_coder"]
            expect(coder_tool.agent_id).to_equal("specialist:coder")

            expect(tool_exists(compiled_spec.tools, "tracker")).to_be_true()
        end)

        it("should handle complex agent with multiple dynamic traits", function()
            local config = {
                delegates = {
                    generate_tool_schemas = true,
                    description_suffix = " (auto-generated)"
                }
            }

            local compiled_spec, err = compiler.compile(spec_with_complex_traits, config)

            expect(err).to_be_nil()
            expect(compiled_spec).not_to_be_nil()

            expect(compiled_spec.prompt).to_contain("You are a complex agent.")
            expect(compiled_spec.prompt).to_contain("You have dynamic capabilities.")
            expect(compiled_spec.prompt).to_contain("You can delegate tasks to specialists based on context.")
            expect(compiled_spec.prompt).to_contain("You can call external APIs and process data dynamically.")
            expect(compiled_spec.prompt).to_contain("Dynamic prompt for agent test:complex")

            expect(tool_exists(compiled_spec.tools, "generated_tool")).to_be_true()
            expect(tool_exists(compiled_spec.tools, "tracker")).to_be_true()
            expect(tool_exists(compiled_spec.tools, "api_client")).to_be_true()
            expect(tool_exists(compiled_spec.tools, "data_processor")).to_be_true()

            expect(tool_exists(compiled_spec.tools, "to_static")).to_be_true()
            expect(tool_exists(compiled_spec.tools, "to_data_analyst")).to_be_true()
            expect(tool_exists(compiled_spec.tools, "to_coder")).to_be_true()

            expect(has_delegate_tool(compiled_spec.tools, "to_static")).to_be_true()
            expect(has_delegate_tool(compiled_spec.tools, "to_data_analyst")).to_be_true()
            expect(has_delegate_tool(compiled_spec.tools, "to_coder")).to_be_true()

            expect(compiled_spec.tools["generated_tool"].context.agent_id).to_equal("test:complex")
            expect(compiled_spec.tools["tracker"].context.agent_id).to_equal("test:complex")
            expect(compiled_spec.tools["api_client"].context.agent_id).to_equal("test:complex")
        end)

        it("should pass agent_id to trait build methods", function()
            local spec_with_context_sensitive_trait = {
                id = "test:context_agent",
                name = "Context Sensitive Agent",
                model = "gpt-4o-mini",
                prompt = "You are a context-sensitive agent.",
                traits = {
                    "dynamic_trait"
                }
            }

            local compiled_spec, err = compiler.compile(spec_with_context_sensitive_trait)

            expect(err).to_be_nil()
            expect(compiled_spec).not_to_be_nil()

            expect(compiled_spec.prompt).to_contain("Dynamic prompt for agent test:context_agent")
            expect(compiled_spec.tools["generated_tool"].context.agent_id).to_equal("test:context_agent")
        end)

        describe("Agent ID Propagation", function()
            it("should add agent_id to all tool contexts during compilation in unified structure", function()
                local compiled_spec, err = compiler.compile(spec_for_agent_id_tests)

                expect(err).to_be_nil()
                expect(compiled_spec).not_to_be_nil()

                for tool_name, tool_data in pairs(compiled_spec.tools) do
                    expect(tool_data.context.agent_id).to_equal("test:agent_id_verification")
                end

                expect(compiled_spec.tools["tool"].context.agent_id).to_equal("test:agent_id_verification")
                expect(compiled_spec.tools["generated_tool"].context.agent_id).to_equal("test:agent_id_verification")

                expect(compiled_spec.tools["calculator"].context.agent_id).to_equal("test:agent_id_verification")
                expect(compiled_spec.tools["validator"].context.agent_id).to_equal("test:agent_id_verification")
            end)

            it("should preserve existing context while adding agent_id in unified structure", function()
                local compiled_spec, err = compiler.compile(spec_for_agent_id_tests)

                expect(err).to_be_nil()
                expect(compiled_spec).not_to_be_nil()

                local tool_data = compiled_spec.tools["tool"]
                expect(tool_data.context.test_setting).to_equal("test_value")
                expect(tool_data.context.agent_id).to_equal("test:agent_id_verification")

                local generated_data = compiled_spec.tools["generated_tool"]
                expect(generated_data.context.generated).to_be_true()
                expect(generated_data.context.workspace).to_equal("/default")
                expect(generated_data.context.agent_id).to_equal("test:agent_id_verification")
            end)

            it("should add agent_id to minimal spec with no tools", function()
                local compiled_spec, err = compiler.compile(minimal_spec)

                expect(err).to_be_nil()
                expect(compiled_spec).not_to_be_nil()

                expect(compiled_spec.tools).not_to_be_nil()
                expect(next(compiled_spec.tools)).to_be_nil()
            end)

            it("should handle agent_id with custom context merger in unified structure", function()
                local custom_config = {
                    context_merger = function(trait_ctx, agent_ctx, tool_ctx)
                        local merged = {}
                        for k, v in pairs(trait_ctx or {}) do merged[k] = v end
                        for k, v in pairs(agent_ctx or {}) do merged[k] = v end
                        for k, v in pairs(tool_ctx or {}) do merged[k] = v end
                        merged.custom_merger_called = true
                        return merged
                    end
                }

                local compiled_spec, err = compiler.compile(spec_for_agent_id_tests, custom_config)

                expect(err).to_be_nil()
                expect(compiled_spec).not_to_be_nil()

                for tool_name, tool_data in pairs(compiled_spec.tools) do
                    expect(tool_data.context.custom_merger_called).to_be_true()
                    expect(tool_data.context.agent_id).to_equal("test:agent_id_verification")
                end
            end)

            it("should add agent_id to tool contexts from trait-contributed tools in unified structure", function()
                local compiled_spec, err = compiler.compile(spec_with_complex_traits)

                expect(err).to_be_nil()
                expect(compiled_spec).not_to_be_nil()

                expect(compiled_spec.tools["generated_tool"].context.agent_id).to_equal("test:complex")
                expect(compiled_spec.tools["tracker"].context.agent_id).to_equal("test:complex")
                expect(compiled_spec.tools["api_client"].context.agent_id).to_equal("test:complex")
                expect(compiled_spec.tools["data_processor"].context.agent_id).to_equal("test:complex")
            end)

            it("should add agent_id to wildcard-resolved tools in unified structure", function()
                local compiled_spec, err = compiler.compile(spec_with_wildcards)

                expect(err).to_be_nil()
                expect(compiled_spec).not_to_be_nil()

                expect(compiled_spec.tools["tool"].context.agent_id).to_equal("test:wildcards")
                expect(compiled_spec.tools["calculator"].context.agent_id).to_equal("test:wildcards")
                expect(compiled_spec.tools["validator"].context.agent_id).to_equal("test:wildcards")
                expect(compiled_spec.tools["tool1"].context.agent_id).to_equal("test:wildcards")
            end)

            it("should ensure agent_id matches the raw spec id exactly", function()
                local test_specs = {
                    { id = "simple:agent", expected = "simple:agent" },
                    { id = "complex:namespace:with:colons", expected = "complex:namespace:with:colons" },
                    { id = "agent_with_underscores", expected = "agent_with_underscores" },
                    { id = "AgentWithCamelCase", expected = "AgentWithCamelCase" },
                    { id = "123:numeric:agent", expected = "123:numeric:agent" }
                }

                for _, test_case in ipairs(test_specs) do
                    local spec = {
                        id = test_case.id,
                        name = "Test Agent",
                        model = "gpt-4o-mini",
                        prompt = "Test prompt",
                        tools = { "basic:tool" }
                    }

                    local compiled_spec, err = compiler.compile(spec)

                    expect(err).to_be_nil()
                    expect(compiled_spec).not_to_be_nil()
                    expect(compiled_spec.tools["tool"].context.agent_id).to_equal(test_case.expected)
                end
            end)

            it("should add agent_id to inline tool contexts in unified structure", function()
                local compiled_spec, err = compiler.compile(spec_with_inline_tools)

                expect(err).to_be_nil()
                expect(compiled_spec).not_to_be_nil()

                expect(compiled_spec.tools["finish"].context.agent_id).to_equal("test:inline_tools")
                expect(compiled_spec.tools["custom_calculator"].context.agent_id).to_equal("test:inline_tools")

                expect(compiled_spec.tools["finish"].context.is_exit_tool).to_be_true()
                expect(compiled_spec.tools["finish"].context.priority).to_equal("high")
            end)
        end)

        it("should handle missing traits gracefully", function()
            local spec_with_missing_trait = {
                id = "test:missing_trait",
                name = "Test Missing Trait",
                model = "gpt-4o-mini",
                prompt = "Test prompt",
                traits = {
                    "nonexistent_trait"
                }
            }

            local compiled_spec, err = compiler.compile(spec_with_missing_trait)

            expect(err).to_be_nil()
            expect(compiled_spec).not_to_be_nil()
            expect(compiled_spec.prompt).to_equal("Test prompt")
        end)

        it("should handle trait ID vs name lookup properly", function()
            local spec_with_mixed_trait_references = {
                id = "test:mixed_traits",
                name = "Mixed Trait References Agent",
                model = "gpt-4o-mini",
                prompt = "Test prompt",
                traits = {
                    "static_trait",
                    "Dynamic Trait",
                    "nonexistent:trait",
                    "Nonexistent Trait"
                }
            }

            local compiled_spec, err = compiler.compile(spec_with_mixed_trait_references)

            expect(err).to_be_nil()
            expect(compiled_spec).not_to_be_nil()

            expect(compiled_spec.prompt).to_contain("You have static capabilities.")
            expect(compiled_spec.prompt).to_contain("You have dynamic capabilities.")

            expect(tool_exists(compiled_spec.tools, "tool")).to_be_true()
            expect(tool_exists(compiled_spec.tools, "generated_tool")).to_be_true()
        end)

        it("should handle delegate without name gracefully", function()
            local spec_with_bad_delegate = {
                id = "test:bad_delegate",
                name = "Test Bad Delegate",
                model = "gpt-4o-mini",
                prompt = "Test prompt",
                delegates = {
                    {
                        id = "some:agent",
                        rule = "Some rule"
                    }
                }
            }

            local config = {
                delegates = {
                    generate_tool_schemas = true
                }
            }

            local compiled_spec, err = compiler.compile(spec_with_bad_delegate, config)

            expect(err).to_be_nil()
            expect(compiled_spec).not_to_be_nil()

            local has_delegate_tools = false
            for tool_name, tool_data in pairs(compiled_spec.tools) do
                if tool_data.agent_id then
                    has_delegate_tools = true
                    break
                end
            end
            expect(has_delegate_tools).to_be_false()
        end)

        it("should handle failing trait build methods gracefully", function()
            local failing_trait = {
                id = "failing_trait",
                name = "Failing Trait",
                description = "A trait with failing build method",
                prompt = "Base prompt",
                tools = {},
                context = {},
                build_func_id = "failing_init_method"
            }

            trait_definitions.failing_trait = failing_trait

            local spec_with_failing_trait = {
                id = "test:failing_trait",
                name = "Test Failing Trait",
                model = "gpt-4o-mini",
                prompt = "Test prompt",
                traits = {
                    "failing_trait"
                }
            }

            local compiled_spec, err = compiler.compile(spec_with_failing_trait)

            expect(err).to_be_nil()
            expect(compiled_spec).not_to_be_nil()
            expect(compiled_spec.prompt).to_contain("Test prompt")
            expect(compiled_spec.prompt).to_contain("Base prompt")
        end)

        it("should use custom context merger in unified structure", function()
            local custom_config = {
                context_merger = function(trait_ctx, agent_ctx, tool_ctx)
                    local merged = {}
                    for k, v in pairs(trait_ctx or {}) do merged[k] = v end
                    for k, v in pairs(agent_ctx or {}) do merged[k] = v end
                    for k, v in pairs(tool_ctx or {}) do merged[k] = v end
                    merged.custom_merger = true
                    return merged
                end
            }

            local compiled_spec, err = compiler.compile(spec_with_traits, custom_config)

            expect(err).to_be_nil()
            expect(compiled_spec).not_to_be_nil()

            expect(compiled_spec.tools["tool"].context.custom_merger).to_be_true()
        end)

        it("should preserve all original spec fields", function()
            local full_spec = {
                id = "test:full",
                name = "Full Agent",
                description = "A complete agent spec",
                model = "gpt-4o-mini",
                max_tokens = 8192,
                temperature = 0.8,
                thinking_effort = 50,
                prompt = "You are a full agent.",
                tools = { "basic:tool" },
                memory = { "memory:item1", "memory:item2" },
                delegates = {},
                memory_contract = {
                    implementation_id = "memory:impl",
                    context = { setting = "value" }
                }
            }

            local compiled_spec, err = compiler.compile(full_spec)

            expect(err).to_be_nil()
            expect(compiled_spec).not_to_be_nil()
            expect(compiled_spec.id).to_equal("test:full")
            expect(compiled_spec.name).to_equal("Full Agent")
            expect(compiled_spec.description).to_equal("A complete agent spec")
            expect(compiled_spec.model).to_equal("gpt-4o-mini")
            expect(compiled_spec.max_tokens).to_equal(8192)
            expect(compiled_spec.temperature).to_equal(0.8)
            expect(compiled_spec.thinking_effort).to_equal(50)
            expect(#compiled_spec.memory).to_equal(2)
            expect(compiled_spec.memory[1]).to_equal("memory:item1")
            expect(compiled_spec.memory_contract).not_to_be_nil()
            expect(compiled_spec.memory_contract.implementation_id).to_equal("memory:impl")

            expect(compiled_spec.tools["tool"].context.agent_id).to_equal("test:full")
        end)

        describe("Delegate Tool Integration", function()
            it("should integrate delegate tools into unified structure", function()
                local config = {
                    delegates = {
                        generate_tool_schemas = true
                    }
                }

                local compiled_spec, err = compiler.compile(spec_with_delegates, config)

                expect(err).to_be_nil()
                expect(compiled_spec).not_to_be_nil()

                expect(tool_exists(compiled_spec.tools, "to_specialist")).to_be_true()
                expect(tool_exists(compiled_spec.tools, "to_helper")).to_be_true()

                local specialist_tool = compiled_spec.tools["to_specialist"]
                expect(specialist_tool.agent_id).to_equal("specialist:agent")
                expect(specialist_tool.name).to_equal("to_specialist")
                expect(specialist_tool.schema).not_to_be_nil()
                expect(specialist_tool.schema.type).to_equal("object")
                expect(specialist_tool.schema.properties.message).not_to_be_nil()

                local helper_tool = compiled_spec.tools["to_helper"]
                expect(helper_tool.agent_id).to_equal("helper:agent")
                expect(helper_tool.name).to_equal("to_helper")
            end)

            it("should distinguish delegate tools from regular tools", function()
                local config = {
                    delegates = {
                        generate_tool_schemas = true
                    }
                }

                local spec_mixed = {
                    id = "test:mixed_delegation",
                    name = "Mixed Delegation Test",
                    model = "gpt-4o-mini",
                    prompt = "Test mixed tools and delegates",
                    tools = {
                        "basic:tool"
                    },
                    delegates = {
                        {
                            id = "specialist:agent",
                            name = "to_specialist",
                            rule = "Forward to specialist"
                        }
                    }
                }

                local compiled_spec, err = compiler.compile(spec_mixed, config)

                expect(err).to_be_nil()
                expect(compiled_spec).not_to_be_nil()

                expect(tool_exists(compiled_spec.tools, "tool")).to_be_true()
                expect(tool_exists(compiled_spec.tools, "to_specialist")).to_be_true()

                expect(has_delegate_tool(compiled_spec.tools, "tool")).to_be_false()
                expect(has_delegate_tool(compiled_spec.tools, "to_specialist")).to_be_true()

                expect(compiled_spec.tools["tool"].agent_id).to_be_nil()
                expect(compiled_spec.tools["to_specialist"].agent_id).to_equal("specialist:agent")
            end)

            it("should handle delegate context merging", function()
                local config = {
                    delegates = {
                        generate_tool_schemas = true
                    }
                }

                local spec_with_delegate_context = {
                    id = "test:delegate_context",
                    name = "Delegate Context Test",
                    model = "gpt-4o-mini",
                    prompt = "Test delegate context",
                    context = {
                        agent_setting = "agent_value"
                    },
                    delegates = {
                        {
                            id = "specialist:agent",
                            name = "to_specialist",
                            rule = "Forward to specialist",
                            context = {
                                delegate_setting = "delegate_value"
                            }
                        }
                    }
                }

                local compiled_spec, err = compiler.compile(spec_with_delegate_context, config)

                expect(err).to_be_nil()
                expect(compiled_spec).not_to_be_nil()

                local delegate_tool = compiled_spec.tools["to_specialist"]
                expect(delegate_tool.context.agent_setting).to_equal("agent_value")
                expect(delegate_tool.context.delegate_setting).to_equal("delegate_value")
            end)
        end)

        describe("Comprehensive Integration Tests", function()
            it("should handle agent with all features enabled", function()
                local comprehensive_spec = {
                    id = "test:comprehensive",
                    name = "Comprehensive Agent",
                    description = "Agent with all features",
                    model = "gpt-4o-mini",
                    max_tokens = 4096,
                    temperature = 0.7,
                    thinking_effort = 25,
                    prompt = "You are a comprehensive agent.",
                    context = {
                        workspace = "/comprehensive",
                        enable_all = true
                    },
                    traits = {
                        "static_trait",
                        "dynamic_trait",
                        "context_aware_trait"
                    },
                    tools = {
                        "basic:tool",
                        "regular:*",
                        {
                            id = "inline_finish",
                            description = "Inline finish tool",
                            schema = {
                                type = "object",
                                properties = {
                                    result = { type = "string" }
                                }
                            }
                        }
                    },
                    delegates = {
                        {
                            id = "helper:agent",
                            name = "to_helper",
                            rule = "Forward simple tasks"
                        }
                    },
                    memory = { "mem:item1" },
                    memory_contract = {
                        implementation_id = "mem:impl",
                        context = { mem_setting = "mem_value" }
                    }
                }

                local config = {
                    delegates = {
                        generate_tool_schemas = true,
                        description_suffix = " (generated)"
                    }
                }

                local compiled_spec, err = compiler.compile(comprehensive_spec, config)

                expect(err).to_be_nil()
                expect(compiled_spec).not_to_be_nil()

                expect(compiled_spec.id).to_equal("test:comprehensive")
                expect(compiled_spec.max_tokens).to_equal(4096)
                expect(compiled_spec.temperature).to_equal(0.7)
                expect(compiled_spec.thinking_effort).to_equal(25)

                expect(compiled_spec.prompt).to_contain("You are a comprehensive agent.")
                expect(compiled_spec.prompt).to_contain("You have static capabilities.")
                expect(compiled_spec.prompt).to_contain("You have dynamic capabilities.")

                expect(tool_exists(compiled_spec.tools, "tool")).to_be_true()
                expect(tool_exists(compiled_spec.tools, "calculator")).to_be_true()
                expect(tool_exists(compiled_spec.tools, "validator")).to_be_true()
                expect(tool_exists(compiled_spec.tools, "generated_tool")).to_be_true()
                expect(tool_exists(compiled_spec.tools, "inline_finish")).to_be_true()
                expect(tool_exists(compiled_spec.tools, "to_helper")).to_be_true()

                expect(has_delegate_tool(compiled_spec.tools, "to_helper")).to_be_true()
                expect(has_delegate_tool(compiled_spec.tools, "tool")).to_be_false()

                expect(#compiled_spec.memory).to_equal(1)
                expect(compiled_spec.memory_contract.implementation_id).to_equal("mem:impl")

                expect(#compiled_spec.prompt_funcs).to_equal(1)
                expect(#compiled_spec.step_funcs).to_equal(1)

                for tool_name, tool_data in pairs(compiled_spec.tools) do
                    if not tool_data.agent_id then
                        expect(tool_data.context.agent_id).to_equal("test:comprehensive")
                    end
                end
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)