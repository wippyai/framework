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

        local spec_with_tool_wrapper_trait = {
            id = "test:tool_wrapper",
            name = "Agent With Tool Wrapper Trait",
            description = "Agent whose trait wraps tool execution",
            model = "gpt-4o-mini",
            prompt = "You are an agent with tool wrappers.",
            context = {
                agent_setting = "agent_value",
                shared_setting = "agent_overrides_trait"
            },
            agent_options = {
                compact = {
                    strict = true
                },
                checkpoint = {
                    token_threshold = 96000
                }
            },
            traits = {
                {
                    id = "tool_wrapper_trait",
                    context = {
                        trait_instance_setting = "instance_value",
                        shared_setting = "instance_overrides_agent"
                    },
                    agent_options = {
                        compact = {
                            token_threshold = 16000
                        },
                        checkpoint = {
                            function_id = "agent.checkpoint:instance"
                        }
                    }
                },
                "legacy_runtime_provider_trait",
                "invalid_tool_wrapper_trait"
            }
        }

        local spec_with_contract_traits = {
            id = "test:contract_traits",
            name = "Agent With Contract Traits",
            description = "Agent whose traits own memory, lifecycle, and checkpoint bindings",
            model = "gpt-4o-mini",
            prompt = "You are an agent with trait-owned contracts.",
            context = {
                workspace = "/repo",
                namespace = "agent_context",
                shared_setting = "agent_context_wins"
            },
            traits = {
                {
                    id = "memory_contract_trait",
                    context = {
                        namespace = "ops",
                        shard = "primary",
                        shared_setting = "attachment_context"
                    },
                    options = {
                        recall = {
                            max_items = 5
                        },
                        compact = {
                            token_threshold = 32000
                        }
                    }
                },
                "audit_lifecycle_trait"
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
            },
            tool_wrapper_trait = {
                id = "tool_wrapper_trait",
                name = "Tool Wrapper Trait",
                description = "Trait with tool wrapper specs",
                prompt = "",
                tools = {},
                context = {
                    memory_profile = "default",
                    shared_setting = "trait_default"
                },
                agent_options = {
                    compact = {
                        token_threshold = 32000,
                        function_id = "agent.compact:default",
                        max_memory_chars = 8192
                    },
                    checkpoint = {
                        token_threshold = 64000
                    }
                },
                tool_wrappers = {
                    {
                        id = "audit_after",
                        phase = "after_execute",
                        binding = "test.wrapper:audit",
                        priority = 20,
                        strict = true,
                        context = {
                            slot = "audit"
                        },
                        options = {
                            include_results = true
                        }
                    },
                    {
                        id = "guard_before",
                        phases = { "before_execute" },
                        binding = "test.wrapper:guard",
                        priority = 10,
                        options = {
                            max_calls = 4
                        }
                    }
                }
            },
            legacy_runtime_provider_trait = {
                id = "legacy_runtime_provider_trait",
                name = "Legacy Runtime Provider Trait",
                description = "Trait with old runtime and notify fields that must not map to tool wrappers",
                prompt = "",
                tools = {},
                context = {},
                runtime_hook = {
                    id = "legacy_checkpoint",
                    phase = "checkpoint",
                    binding_id = "test.runtime:legacy_provider",
                    options = {
                        token_threshold = 64000
                    }
                },
                notify_hook = {
                    id = "legacy_notify",
                    event = "turn.failed",
                    binding_id = "test.notify:legacy",
                    priority = 35,
                    options = {
                        severity = "error"
                    }
                }
            },
            invalid_tool_wrapper_trait = {
                id = "invalid_tool_wrapper_trait",
                name = "Invalid Tool Wrapper Trait",
                description = "Trait with malformed tool wrapper specs",
                prompt = "",
                tools = {},
                context = {},
                tool_wrappers = {
                    {
                        id = "missing_target",
                        phase = "before_execute"
                    },
                    {
                        id = "unsupported_phase",
                        phase = "around_execute",
                        binding = "test.wrapper:invalid"
                    }
                }
            },
            memory_contract_trait = {
                id = "memory_contract_trait",
                name = "Memory Contract Trait",
                description = "Trait that owns memory, lifecycle, and checkpoint bindings",
                prompt = "Use durable memory when relevant.",
                tools = {},
                context = {
                    namespace = "default",
                    shard = "default",
                    shared_setting = "trait_default"
                },
                options = {
                    recall = {
                        enabled = true,
                        max_items = 2,
                        max_length = 1000
                    },
                    compact = {
                        enabled = true,
                        token_threshold = 24000,
                        max_memory_chars = 8192
                    },
                    checkpoint = {
                        token_threshold = 48000
                    }
                },
                bindings = {
                    memory = {
                        id = "memory",
                        contract = "wippy.agent:memory",
                        binding = "test.memory:store",
                        context = {
                            slot = "memory"
                        },
                        options = {
                            recall = {
                                max_length = 2000
                            }
                        }
                    },
                    lifecycle = {
                        id = "memory_lifecycle",
                        contract = "wippy.agent:lifecycle",
                        binding = "test.memory:lifecycle",
                        phases = { "activate", "deactivate", "after_step" },
                        priority = 30,
                        context = {
                            hook = "memory"
                        }
                    },
                    checkpoint = {
                        id = "memory_checkpoint",
                        contract = "wippy.agent:checkpoint",
                        binding = "test.memory:checkpoint",
                        priority = 20,
                        context = {
                            mode = "memory"
                        }
                    }
                }
            },
            audit_lifecycle_trait = {
                id = "audit_lifecycle_trait",
                name = "Audit Lifecycle Trait",
                description = "Second lifecycle binding for ordering tests",
                prompt = "",
                tools = {},
                context = {},
                options = {
                    audit = {
                        level = "standard"
                    }
                },
                bindings = {
                    lifecycle = {
                        id = "audit_lifecycle",
                        contract = "wippy.agent:lifecycle",
                        binding = "test.audit:lifecycle",
                        phases = { "after_step" },
                        priority = 10,
                        options = {
                            audit = {
                                include_tools = true
                            }
                        }
                    }
                }
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
                    local trait_def = (trait_definitions :: any)[trait_id]
                    if trait_def then
                        return trait_def
                    else
                        return nil, "No trait found with ID: " .. trait_id
                    end
                end,
                get_by_name = function(trait_name)
                    local trait_def = (trait_names :: any)[trait_name]
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
                                local ns = (id :: any):match("^([^:]+):")
                                if ns == target_namespace then
                                    table.insert(results, entry)
                                end
                            end
                        end
                    end
                    return results
                end,

                get_tool_schema = function(tool_id)
                    local entry = (tool_registry :: any)[tool_id]
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
                end,

                run_input_schema_processors = function(schema, tool_id, tool_name)
                    return schema
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

            test.is_nil(err)
            test.not_nil(compiled_spec)
            test.eq(compiled_spec.id, "test:minimal")
            test.eq(compiled_spec.name, "Minimal Agent")
            test.eq(compiled_spec.prompt, "You are a test agent.")
            test.not_nil(compiled_spec.tools)
            test.eq(count_tools(compiled_spec.tools), 0)
            test.not_nil(compiled_spec.prompt_funcs)
            test.not_nil(compiled_spec.step_funcs)
            test.eq(#compiled_spec.prompt_funcs, 0)
            test.eq(#compiled_spec.step_funcs, 0)
        end)

        it("should handle nil spec", function()
            local compiled_spec, err = compiler.compile(nil)

            test.is_nil(compiled_spec)
            test.eq(err, "Raw spec is required")
        end)

        describe("Runtime Trait Function Collection", function()
            it("should collect traits with prompt functions", function()
                local compiled_spec, err = compiler.compile(spec_with_runtime_traits)

                test.is_nil(err)
                test.not_nil(compiled_spec)

                test.eq(#compiled_spec.prompt_funcs, 1)
                local prompt_trait = compiled_spec.prompt_funcs[1]
                test.eq(prompt_trait.trait_id, "context_aware_trait")
                test.eq(prompt_trait.func_id, "generate_context_prompt")
                test.eq(prompt_trait.context.adaptation_level, "high")
            end)

            it("should collect traits with step functions", function()
                local compiled_spec, err = compiler.compile(spec_with_runtime_traits)

                test.is_nil(err)
                test.not_nil(compiled_spec)

                test.eq(#compiled_spec.step_funcs, 2)

                local trait_map = {}
                for _, trait in ipairs(compiled_spec.step_funcs) do
                    trait_map[trait.trait_id] = trait
                end

                test.not_nil(trait_map["context_aware_trait"])
                test.eq(trait_map["context_aware_trait"].func_id, "modify_context_response")
                test.eq(trait_map["context_aware_trait"].context.adaptation_level, "high")

                test.not_nil(trait_map["step_modifying_trait"])
                test.eq(trait_map["step_modifying_trait"].func_id, "enhance_step_results")
                test.is_true(trait_map["step_modifying_trait"].context.enhance_results)
            end)

            it("should handle mixed trait function combinations", function()
                local compiled_spec, err = compiler.compile(spec_with_mixed_trait_functions)

                test.is_nil(err)
                test.not_nil(compiled_spec)

                test.eq(#compiled_spec.prompt_funcs, 2)
                test.eq(#compiled_spec.step_funcs, 1)

                local prompt_trait_map = {}
                for _, trait in ipairs(compiled_spec.prompt_funcs) do
                    prompt_trait_map[trait.trait_id] = trait
                end

                test.not_nil(prompt_trait_map["context_aware_trait"])
                test.not_nil(prompt_trait_map["prompt_only_trait"])
                test.eq(prompt_trait_map["prompt_only_trait"].func_id, "generate_dynamic_prompt")

                local step_trait_map = {}
                for _, trait in ipairs(compiled_spec.step_funcs) do
                    step_trait_map[trait.trait_id] = trait
                end

                test.not_nil(step_trait_map["context_aware_trait"])
                test.eq(step_trait_map["context_aware_trait"].func_id, "modify_context_response")
            end)

            it("should preserve trait contexts in runtime function collections", function()
                local compiled_spec, err = compiler.compile(spec_with_runtime_traits)

                test.is_nil(err)
                test.not_nil(compiled_spec)

                for _, trait in ipairs(compiled_spec.prompt_funcs) do
                    test.not_nil(trait.context)
                    if trait.trait_id == "context_aware_trait" then
                        test.eq(trait.context.adaptation_level, "high")
                    end
                end

                for _, trait in ipairs(compiled_spec.step_funcs) do
                    test.not_nil(trait.context)
                    if trait.trait_id == "step_modifying_trait" then
                        test.is_true(trait.context.enhance_results)
                    end
                end
            end)

            it("should handle empty extension lists for agents without dynamic traits", function()
                local compiled_spec, err = compiler.compile(minimal_spec)

                test.is_nil(err)
                test.not_nil(compiled_spec)
                test.not_nil(compiled_spec.prompt_funcs)
                test.not_nil(compiled_spec.step_funcs)
                test.not_nil(compiled_spec.tool_wrappers)
                test.eq(#compiled_spec.prompt_funcs, 0)
                test.eq(#compiled_spec.step_funcs, 0)
                test.eq(#compiled_spec.tool_wrappers, 0)
            end)

            it("should not include traits without wrappers in wrapper collections", function()
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

                test.is_nil(err)
                test.not_nil(compiled_spec)
                test.eq(#compiled_spec.prompt_funcs, 0)
                test.eq(#compiled_spec.step_funcs, 0)
                test.eq(#compiled_spec.tool_wrappers, 0)
            end)

            it("should collect trait-owned tool wrapper specs", function()
                local compiled_spec, err = compiler.compile(spec_with_tool_wrapper_trait)

                test.is_nil(err)
                test.not_nil(compiled_spec)
                test.not_nil(compiled_spec.tool_wrappers)
                test.eq(#compiled_spec.tool_wrappers, 2)

                local first = compiled_spec.tool_wrappers[1]
                test.eq(first.id, "guard_before")
                test.eq(first.trait_id, "tool_wrapper_trait")
                test.eq(first.binding, "test.wrapper:guard")
                test.eq(first.phases[1], "before_execute")
                test.eq(first.priority, 10)
                test.eq(first.options.max_calls, 4)

                local second = compiled_spec.tool_wrappers[2]
                test.eq(second.id, "audit_after")
                test.eq(second.trait_id, "tool_wrapper_trait")
                test.eq(second.binding, "test.wrapper:audit")
                test.eq(second.phases[1], "after_execute")
                test.eq(second.priority, 20)
                test.is_true(second.strict)
                test.is_true(second.options.include_results)
            end)

            it("should merge trait agent options with attachment and agent overrides", function()
                local compiled_spec, err = compiler.compile(spec_with_tool_wrapper_trait)

                test.is_nil(err)
                test.not_nil(compiled_spec)
                test.not_nil(compiled_spec.agent_options)

                test.eq(compiled_spec.agent_options.compact.token_threshold, 16000,
                    "attachment option overrides trait default")
                test.eq(compiled_spec.agent_options.compact.function_id, "agent.compact:default",
                    "trait option preserved when not overridden")
                test.eq(compiled_spec.agent_options.compact.max_memory_chars, 8192)
                test.is_true(compiled_spec.agent_options.compact.strict,
                    "agent-level option overlays trait and attachment options")
                test.eq(compiled_spec.agent_options.checkpoint.token_threshold, 96000,
                    "agent-level checkpoint threshold wins last")
                test.eq(compiled_spec.agent_options.checkpoint.function_id, "agent.checkpoint:instance",
                    "attachment checkpoint function is preserved")
            end)

            it("should merge trait instance, agent, and wrapper context for tool wrappers", function()
                local compiled_spec, err = compiler.compile(spec_with_tool_wrapper_trait)

                test.is_nil(err)
                test.not_nil(compiled_spec)

                local wrapper = compiled_spec.tool_wrappers[2]
                test.eq(wrapper.context.memory_profile, "default")
                test.eq(wrapper.context.agent_setting, "agent_value")
                test.eq(wrapper.context.shared_setting, "agent_overrides_trait")
                test.eq(wrapper.context.trait_instance_setting, "instance_value")
                test.eq(wrapper.context.slot, "audit")
                test.eq(wrapper.context.agent_id, "test:tool_wrapper")
                test.eq(wrapper.context.trait_id, "tool_wrapper_trait")
            end)

            it("should ignore old runtime/notify fields and malformed tool wrappers", function()
                local compiled_spec, err = compiler.compile(spec_with_tool_wrapper_trait)

                test.is_nil(err)
                test.not_nil(compiled_spec)

                test.eq(#compiled_spec.tool_wrappers, 2)
                for _, wrapper in ipairs(compiled_spec.tool_wrappers) do
                    test.is_false(wrapper.id == "legacy_checkpoint")
                    test.is_false(wrapper.id == "legacy_notify")
                    test.is_false(wrapper.id == "missing_target")
                    test.is_false(wrapper.id == "unsupported_phase")
                end
            end)

            it("should normalize trait-owned contract bindings into a compiled binding plan", function()
                local compiled_spec, err = compiler.compile(spec_with_contract_traits)

                test.is_nil(err)
                test.not_nil(compiled_spec)
                test.not_nil(compiled_spec.bindings)

                test.eq(#compiled_spec.bindings.memory, 1)
                test.eq(#compiled_spec.bindings.lifecycle, 2)
                test.eq(#compiled_spec.bindings.checkpoint, 1)

                local memory = compiled_spec.bindings.memory[1]
                test.eq(memory.kind, "memory")
                test.eq(memory.contract, "wippy.agent:memory")
                test.eq(memory.binding, "test.memory:store")
                test.eq(memory.context.agent_id, "test:contract_traits")
                test.eq(memory.context.trait_id, "memory_contract_trait")
                test.eq(memory.context.slot, "memory")
            end)

            it("should merge trait defaults, binding options, and attachment options into binding context options", function()
                local compiled_spec, err = compiler.compile(spec_with_contract_traits)

                test.is_nil(err)
                test.not_nil(compiled_spec)

                local memory = compiled_spec.bindings.memory[1]
                test.eq(memory.context.namespace, "agent_context", "agent context still follows existing context merge order")
                test.eq(memory.context.shard, "primary")
                test.eq(memory.context.shared_setting, "agent_context_wins")
                test.is_true(memory.context.options.recall.enabled)
                test.eq(memory.context.options.recall.max_items, 5,
                    "trait attachment options override trait defaults")
                test.eq(memory.context.options.recall.max_length, 2000,
                    "binding-local options refine trait defaults")
                test.eq(memory.context.options.compact.token_threshold, 32000,
                    "attachment compact option overrides trait default")
                test.eq(memory.context.options.compact.max_memory_chars, 8192)
                test.eq(memory.options.recall.max_items, 5)
                test.eq(memory.options.recall.max_length, 2000)
            end)

            it("should order multiple bindings of the same kind by priority then declaration order", function()
                local compiled_spec, err = compiler.compile(spec_with_contract_traits)

                test.is_nil(err)
                test.not_nil(compiled_spec)

                local lifecycle = compiled_spec.bindings.lifecycle
                test.eq(#lifecycle, 2)
                test.eq(lifecycle[1].id, "audit_lifecycle")
                test.eq(lifecycle[1].binding, "test.audit:lifecycle")
                test.eq(lifecycle[1].phases[1], "after_step")
                test.eq(lifecycle[1].context.options.audit.level, "standard")
                test.is_true(lifecycle[1].context.options.audit.include_tools)

                test.eq(lifecycle[2].id, "memory_lifecycle")
                test.eq(lifecycle[2].binding, "test.memory:lifecycle")
                test.eq(lifecycle[2].phases[1], "activate")
                test.eq(lifecycle[2].phases[2], "deactivate")
                test.eq(lifecycle[2].phases[3], "after_step")
            end)

            it("should let a trait provide checkpoint behavior through a checkpoint binding", function()
                local compiled_spec, err = compiler.compile(spec_with_contract_traits)

                test.is_nil(err)
                test.not_nil(compiled_spec)

                local checkpoint = compiled_spec.bindings.checkpoint[1]
                test.eq(checkpoint.contract, "wippy.agent:checkpoint")
                test.eq(checkpoint.binding, "test.memory:checkpoint")
                test.eq(checkpoint.context.mode, "memory")
                test.eq(checkpoint.context.options.compact.enabled, true)
                test.eq(checkpoint.context.options.compact.token_threshold, 32000)
                test.eq(checkpoint.context.options.checkpoint.token_threshold, 48000)
            end)
        end)

        describe("Unified Tool Structure Support", function()
            it("should handle basic inline tool schemas in unified structure", function()
                local compiled_spec, err = compiler.compile(spec_with_inline_tools)

                test.is_nil(err)
                test.not_nil(compiled_spec)

                test.is_true(tool_exists(compiled_spec.tools, "finish"))
                test.is_true(tool_exists(compiled_spec.tools, "custom_calculator"))

                local finish_tool = assert(compiled_spec.tools["finish"])
                test.eq(finish_tool.name, "finish")
                test.eq(finish_tool.description, "Complete the task with final answer")
                test.eq(finish_tool.schema.type, "object")
                test.not_nil(finish_tool.schema.properties.final_answer)
                test.not_nil(finish_tool.schema.properties.reasoning)
                test.not_nil(finish_tool.schema.properties.tools_used)
                test.eq(#finish_tool.schema.required, 1)
                test.eq(finish_tool.schema.required[1], "final_answer")
                test.eq(finish_tool.registry_id, "finish")

                local calc_tool = assert(compiled_spec.tools["custom_calculator"])
                test.eq(calc_tool.name, "custom_calculator")
                test.eq(calc_tool.description, "Custom inline calculator tool")
                test.not_nil(calc_tool.schema.properties.operation)
                test.not_nil(calc_tool.schema.properties.operands)
                test.eq(calc_tool.registry_id, "custom_calculator")

                test.not_nil(finish_tool.context)
                test.is_true(finish_tool.context.is_exit_tool)
                test.eq(finish_tool.context.priority, "high")
                test.eq(finish_tool.context.agent_id, "test:inline_tools")
            end)

            it("should handle mixed registry and inline tools in unified structure", function()
                local compiled_spec, err = compiler.compile(spec_with_mixed_tools)

                test.is_nil(err)
                test.not_nil(compiled_spec)

                test.is_true(tool_exists(compiled_spec.tools, "tool"))
                test.is_true(tool_exists(compiled_spec.tools, "exit_tool"))

                local registry_tool = assert(compiled_spec.tools["tool"])
                test.not_nil(registry_tool.registry_id)

                local inline_tool = assert(compiled_spec.tools["exit_tool"])
                test.eq(inline_tool.registry_id, "exit_tool")
                test.not_nil(inline_tool.schema.properties.result)
                test.not_nil(inline_tool.schema.properties.success)

                test.eq(inline_tool.context.exit_context, "value")
                test.eq(inline_tool.context.agent_id, "test:mixed_tools")
            end)

            it("should handle aliased inline tools in unified structure", function()
                local compiled_spec, err = compiler.compile(spec_with_alias_and_inline)

                test.is_nil(err)
                test.not_nil(compiled_spec)

                test.is_true(tool_exists(compiled_spec.tools, "simple_name"))

                local aliased_tool = assert(compiled_spec.tools["simple_name"])
                test.eq(aliased_tool.name, "simple_name")
                test.eq(aliased_tool.description, "Complex tool with simple alias")
                test.not_nil(aliased_tool.schema.properties.input)
                test.not_nil(aliased_tool.schema.properties.config)

                test.not_nil(aliased_tool.context)
                test.is_true(aliased_tool.context.aliased)
                test.eq(aliased_tool.context.agent_id, "test:alias_inline")
            end)

            it("should handle inline tools without schemas gracefully in unified structure", function()
                local compiled_spec, err = compiler.compile(spec_with_incomplete_inline)

                test.is_nil(err)
                test.not_nil(compiled_spec)

                test.is_true(tool_exists(compiled_spec.tools, "missing_schema"))
                test.is_true(tool_exists(compiled_spec.tools, "with_schema"))

                local with_schema_tool = assert(compiled_spec.tools["with_schema"])
                test.not_nil(with_schema_tool.schema)
                test.not_nil(with_schema_tool.schema.properties.input)

                local missing_schema_tool = assert(compiled_spec.tools["missing_schema"])
                test.is_nil(missing_schema_tool.schema)
                test.not_nil(missing_schema_tool.context)
                test.eq(missing_schema_tool.context.agent_id, "test:incomplete_inline")
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

                test.is_nil(err)
                test.not_nil(compiled_spec)

                local tool = assert(compiled_spec.tools["tool"])
                test.not_nil(tool)
                test.eq(tool.description, "Overridden description")
                test.not_nil(tool.schema.properties.custom_prop)
                test.is_nil(tool.schema.properties.input)
                test.eq(tool.registry_id, "basic:tool")
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

                test.is_nil(err)
                test.not_nil(compiled_spec)

                local tool = assert(compiled_spec.tools["complex_tool"])
                test.not_nil(tool)
                test.not_nil(tool.schema.properties.config)
                test.not_nil(tool.schema.properties.config.properties.mode)
                test.not_nil(tool.schema.properties.config.properties.options)
                test.not_nil(tool.schema.properties.data)
                test.not_nil(tool.schema.properties.data.items.properties.id)
                test.eq(#tool.schema.required, 2)
            end)

            it("should preserve agent_id in inline tool contexts in unified structure", function()
                local compiled_spec, err = compiler.compile(spec_with_inline_tools)

                test.is_nil(err)
                test.not_nil(compiled_spec)

                for tool_name, tool_data in pairs(compiled_spec.tools) do
                    test.eq(tool_data.context.agent_id, "test:inline_tools")
                end

                test.eq(compiled_spec.tools["finish"].context.agent_id, "test:inline_tools")
                test.eq(compiled_spec.tools["custom_calculator"].context.agent_id, "test:inline_tools")
            end)
        end)

        it("should compile agent with trait names (get_by_name fallback)", function()
            local compiled_spec, err = compiler.compile(spec_with_trait_names)

            test.is_nil(err)
            test.not_nil(compiled_spec)

            test.contains(compiled_spec.prompt, "You are a test agent with trait names.")
            test.contains(compiled_spec.prompt, "You have static capabilities.")
            test.contains(compiled_spec.prompt, "You have dynamic capabilities.")

            test.is_true(tool_exists(compiled_spec.tools, "tool"))
            test.is_true(tool_exists(compiled_spec.tools, "generated_tool"))
        end)

        it("should compile agent with static traits", function()
            local compiled_spec, err = compiler.compile(spec_with_traits)

            test.is_nil(err)
            test.not_nil(compiled_spec)

            test.contains(compiled_spec.prompt, "You are a test agent with traits.")
            test.contains(compiled_spec.prompt, "You have static capabilities.")
            test.contains(compiled_spec.prompt, "You have dynamic capabilities.")
            test.contains(compiled_spec.prompt, "Dynamic prompt for agent test:with_traits: instance_value")

            test.is_true(tool_exists(compiled_spec.tools, "tool"))
            test.is_true(tool_exists(compiled_spec.tools, "generated_tool"))

            local tool_data = compiled_spec.tools["tool"]
            test.not_nil(tool_data)
            test.eq(tool_data.context.agent_setting, "agent_value")
            test.eq(tool_data.context.shared_setting, "agent_overrides_trait")

            local generated_tool_data = compiled_spec.tools["generated_tool"]
            test.not_nil(generated_tool_data)
            test.is_true(generated_tool_data.context.generated)
            test.eq(generated_tool_data.context.agent_id, "test:with_traits")
        end)

        it("should collect tool schemas from trait build methods in unified structure", function()
            local compiled_spec, err = compiler.compile(spec_with_tool_schemas)

            test.is_nil(err)
            test.not_nil(compiled_spec)

            test.is_true(tool_exists(compiled_spec.tools, "api_client"))
            test.is_true(tool_exists(compiled_spec.tools, "data_processor"))

            local api_tool = compiled_spec.tools["api_client"]
            test.eq(api_tool.name, "api_client")
            test.eq(api_tool.description, "Call external API with dynamic configuration")
            test.eq(api_tool.schema.type, "object")
            test.not_nil(api_tool.schema.properties.endpoint)
            test.not_nil(api_tool.schema.properties.data)
            test.eq(#api_tool.schema.required, 1)
            test.eq(api_tool.schema.required[1], "endpoint")

            test.not_nil(api_tool.context)
            test.eq(api_tool.context.api_endpoint, "https://api.example.com")
            test.eq(api_tool.context.agent_id, "test:with_tool_schemas")

            test.contains(compiled_spec.prompt, "You can call external APIs and process data dynamically.")
        end)

        it("should compile agent with delegates in unified tool structure", function()
            local config = {
                delegates = {
                    generate_tool_schemas = true,
                    description_suffix = ", this will end your response"
                }
            }

            local compiled_spec, err = compiler.compile(spec_with_delegates, config)

            test.is_nil(err)
            test.not_nil(compiled_spec)

            test.is_true(tool_exists(compiled_spec.tools, "to_specialist"))
            test.is_true(tool_exists(compiled_spec.tools, "to_helper"))

            test.is_true(has_delegate_tool(compiled_spec.tools, "to_specialist"))
            test.is_true(has_delegate_tool(compiled_spec.tools, "to_helper"))

            local specialist_tool = compiled_spec.tools["to_specialist"]
            test.eq(specialist_tool.agent_id, "specialist:agent")
            test.contains(specialist_tool.description, "Forward complex questions to specialist")
            test.contains(specialist_tool.description, ", this will end your response")

            local helper_tool = compiled_spec.tools["to_helper"]
            test.eq(helper_tool.agent_id, "helper:agent")
            test.contains(helper_tool.description, "Forward simple questions to helper")
        end)

        it("should not generate delegate tool schemas when disabled", function()
            local config = {
                delegates = {
                    generate_tool_schemas = false
                }
            }

            local compiled_spec, err = compiler.compile(spec_with_delegates, config)

            test.is_nil(err)
            test.not_nil(compiled_spec)

            test.is_false(tool_exists(compiled_spec.tools, "to_specialist"))
            test.is_false(tool_exists(compiled_spec.tools, "to_helper"))
        end)

        it("should resolve wildcard tools in unified structure", function()
            local compiled_spec, err = compiler.compile(spec_with_wildcards)

            test.is_nil(err)
            test.not_nil(compiled_spec)

            test.is_true(tool_exists(compiled_spec.tools, "tool"))
            test.is_true(tool_exists(compiled_spec.tools, "calculator"))
            test.is_true(tool_exists(compiled_spec.tools, "validator"))
            test.is_true(tool_exists(compiled_spec.tools, "tool1"))
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

            test.is_nil(err)
            test.not_nil(compiled_spec)

            test.is_true(tool_exists(compiled_spec.tools, "to_data_analyst"))
            test.is_true(tool_exists(compiled_spec.tools, "to_coder"))

            test.is_true(has_delegate_tool(compiled_spec.tools, "to_data_analyst"))
            test.is_true(has_delegate_tool(compiled_spec.tools, "to_coder"))

            local data_analyst_tool = compiled_spec.tools["to_data_analyst"]
            test.eq(data_analyst_tool.agent_id, "specialist:data_analyst")
            test.contains(data_analyst_tool.description, "test:enabled_features")

            local coder_tool = compiled_spec.tools["to_coder"]
            test.eq(coder_tool.agent_id, "specialist:coder")

            test.is_true(tool_exists(compiled_spec.tools, "tracker"))
        end)

        it("should handle complex agent with multiple dynamic traits", function()
            local config = {
                delegates = {
                    generate_tool_schemas = true,
                    description_suffix = " (auto-generated)"
                }
            }

            local compiled_spec, err = compiler.compile(spec_with_complex_traits, config)

            test.is_nil(err)
            test.not_nil(compiled_spec)

            test.contains(compiled_spec.prompt, "You are a complex agent.")
            test.contains(compiled_spec.prompt, "You have dynamic capabilities.")
            test.contains(compiled_spec.prompt, "You can delegate tasks to specialists based on context.")
            test.contains(compiled_spec.prompt, "You can call external APIs and process data dynamically.")
            test.contains(compiled_spec.prompt, "Dynamic prompt for agent test:complex")

            test.is_true(tool_exists(compiled_spec.tools, "generated_tool"))
            test.is_true(tool_exists(compiled_spec.tools, "tracker"))
            test.is_true(tool_exists(compiled_spec.tools, "api_client"))
            test.is_true(tool_exists(compiled_spec.tools, "data_processor"))

            test.is_true(tool_exists(compiled_spec.tools, "to_static"))
            test.is_true(tool_exists(compiled_spec.tools, "to_data_analyst"))
            test.is_true(tool_exists(compiled_spec.tools, "to_coder"))

            test.is_true(has_delegate_tool(compiled_spec.tools, "to_static"))
            test.is_true(has_delegate_tool(compiled_spec.tools, "to_data_analyst"))
            test.is_true(has_delegate_tool(compiled_spec.tools, "to_coder"))

            test.eq(compiled_spec.tools["generated_tool"].context.agent_id, "test:complex")
            test.eq(compiled_spec.tools["tracker"].context.agent_id, "test:complex")
            test.eq(compiled_spec.tools["api_client"].context.agent_id, "test:complex")
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

            test.is_nil(err)
            test.not_nil(compiled_spec)

            test.contains(compiled_spec.prompt, "Dynamic prompt for agent test:context_agent")
            test.eq(compiled_spec.tools["generated_tool"].context.agent_id, "test:context_agent")
        end)

        describe("Agent ID Propagation", function()
            it("should add agent_id to all tool contexts during compilation in unified structure", function()
                local compiled_spec, err = compiler.compile(spec_for_agent_id_tests)

                test.is_nil(err)
                test.not_nil(compiled_spec)

                for tool_name, tool_data in pairs(compiled_spec.tools) do
                    test.eq(tool_data.context.agent_id, "test:agent_id_verification")
                end

                test.eq(compiled_spec.tools["tool"].context.agent_id, "test:agent_id_verification")
                test.eq(compiled_spec.tools["generated_tool"].context.agent_id, "test:agent_id_verification")

                test.eq(compiled_spec.tools["calculator"].context.agent_id, "test:agent_id_verification")
                test.eq(compiled_spec.tools["validator"].context.agent_id, "test:agent_id_verification")
            end)

            it("should preserve existing context while adding agent_id in unified structure", function()
                local compiled_spec, err = compiler.compile(spec_for_agent_id_tests)

                test.is_nil(err)
                test.not_nil(compiled_spec)

                local tool_data = compiled_spec.tools["tool"]
                test.eq(tool_data.context.test_setting, "test_value")
                test.eq(tool_data.context.agent_id, "test:agent_id_verification")

                local generated_data = compiled_spec.tools["generated_tool"]
                test.is_true(generated_data.context.generated)
                test.eq(generated_data.context.workspace, "/default")
                test.eq(generated_data.context.agent_id, "test:agent_id_verification")
            end)

            it("should add agent_id to minimal spec with no tools", function()
                local compiled_spec, err = compiler.compile(minimal_spec)

                test.is_nil(err)
                test.not_nil(compiled_spec)

                test.not_nil(compiled_spec.tools)
                test.is_nil(next(compiled_spec.tools))
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

                test.is_nil(err)
                test.not_nil(compiled_spec)

                for tool_name, tool_data in pairs(compiled_spec.tools) do
                    test.is_true(tool_data.context.custom_merger_called)
                    test.eq(tool_data.context.agent_id, "test:agent_id_verification")
                end
            end)

            it("should add agent_id to tool contexts from trait-contributed tools in unified structure", function()
                local compiled_spec, err = compiler.compile(spec_with_complex_traits)

                test.is_nil(err)
                test.not_nil(compiled_spec)

                test.eq(compiled_spec.tools["generated_tool"].context.agent_id, "test:complex")
                test.eq(compiled_spec.tools["tracker"].context.agent_id, "test:complex")
                test.eq(compiled_spec.tools["api_client"].context.agent_id, "test:complex")
                test.eq(compiled_spec.tools["data_processor"].context.agent_id, "test:complex")
            end)

            it("should add agent_id to wildcard-resolved tools in unified structure", function()
                local compiled_spec, err = compiler.compile(spec_with_wildcards)

                test.is_nil(err)
                test.not_nil(compiled_spec)

                test.eq(compiled_spec.tools["tool"].context.agent_id, "test:wildcards")
                test.eq(compiled_spec.tools["calculator"].context.agent_id, "test:wildcards")
                test.eq(compiled_spec.tools["validator"].context.agent_id, "test:wildcards")
                test.eq(compiled_spec.tools["tool1"].context.agent_id, "test:wildcards")
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

                    test.is_nil(err)
                    test.not_nil(compiled_spec)
                    test.eq(compiled_spec.tools["tool"].context.agent_id, test_case.expected)
                end
            end)

            it("should add agent_id to inline tool contexts in unified structure", function()
                local compiled_spec, err = compiler.compile(spec_with_inline_tools)

                test.is_nil(err)
                test.not_nil(compiled_spec)

                test.eq(compiled_spec.tools["finish"].context.agent_id, "test:inline_tools")
                test.eq(compiled_spec.tools["custom_calculator"].context.agent_id, "test:inline_tools")

                test.is_true(compiled_spec.tools["finish"].context.is_exit_tool)
                test.eq(compiled_spec.tools["finish"].context.priority, "high")
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

            test.is_nil(err)
            test.not_nil(compiled_spec)
            test.eq(compiled_spec.prompt, "Test prompt")
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

            test.is_nil(err)
            test.not_nil(compiled_spec)

            test.contains(compiled_spec.prompt, "You have static capabilities.")
            test.contains(compiled_spec.prompt, "You have dynamic capabilities.")

            test.is_true(tool_exists(compiled_spec.tools, "tool"))
            test.is_true(tool_exists(compiled_spec.tools, "generated_tool"))
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

            test.is_nil(err)
            test.not_nil(compiled_spec)

            local has_delegate_tools = false
            for tool_name, tool_data in pairs(compiled_spec.tools) do
                if tool_data.agent_id then
                    has_delegate_tools = true
                    break
                end
            end
            test.is_false(has_delegate_tools)
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

            test.is_nil(err)
            test.not_nil(compiled_spec)
            test.contains(compiled_spec.prompt, "Test prompt")
            test.contains(compiled_spec.prompt, "Base prompt")
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

            test.is_nil(err)
            test.not_nil(compiled_spec)

            test.is_true(compiled_spec.tools["tool"].context.custom_merger)
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
                    context = { setting = "value" },
                    options = {
                        max_items = 4,
                        max_length = 3000
                    }
                }
            }

            local compiled_spec, err = compiler.compile(full_spec)

            test.is_nil(err)
            test.not_nil(compiled_spec)
            test.eq(compiled_spec.id, "test:full")
            test.eq(compiled_spec.name, "Full Agent")
            test.eq(compiled_spec.description, "A complete agent spec")
            test.eq(compiled_spec.model, "gpt-4o-mini")
            test.eq(compiled_spec.max_tokens, 8192)
            test.eq(compiled_spec.temperature, 0.8)
            test.eq(compiled_spec.thinking_effort, 50)
            test.eq(#compiled_spec.memory, 2)
            test.eq(compiled_spec.memory[1], "memory:item1")
            test.not_nil(compiled_spec.memory_contract)
            test.eq(compiled_spec.memory_contract.implementation_id, "memory:impl")
            test.not_nil(compiled_spec.bindings)
            test.eq(#compiled_spec.bindings.memory, 1)
            test.eq(compiled_spec.bindings.memory[1].source, "legacy_memory_contract")
            test.eq(compiled_spec.bindings.memory[1].contract, "wippy.agent:memory")
            test.eq(compiled_spec.bindings.memory[1].binding, "memory:impl")
            test.eq(compiled_spec.bindings.memory[1].context.setting, "value")
            test.eq(compiled_spec.bindings.memory[1].context.options.max_items, 4)
            test.eq(compiled_spec.bindings.memory[1].options.max_length, 3000)

            test.eq(compiled_spec.tools["tool"].context.agent_id, "test:full")
        end)

        describe("Delegate Tool Integration", function()
            it("should integrate delegate tools into unified structure", function()
                local config = {
                    delegates = {
                        generate_tool_schemas = true
                    }
                }

                local compiled_spec, err = compiler.compile(spec_with_delegates, config)

                test.is_nil(err)
                test.not_nil(compiled_spec)

                test.is_true(tool_exists(compiled_spec.tools, "to_specialist"))
                test.is_true(tool_exists(compiled_spec.tools, "to_helper"))

                local specialist_tool = compiled_spec.tools["to_specialist"]
                test.eq(specialist_tool.agent_id, "specialist:agent")
                test.eq(specialist_tool.name, "to_specialist")
                test.not_nil(specialist_tool.schema)
                test.eq(specialist_tool.schema.type, "object")
                test.not_nil(specialist_tool.schema.properties.message)

                local helper_tool = compiled_spec.tools["to_helper"]
                test.eq(helper_tool.agent_id, "helper:agent")
                test.eq(helper_tool.name, "to_helper")
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

                test.is_nil(err)
                test.not_nil(compiled_spec)

                test.is_true(tool_exists(compiled_spec.tools, "tool"))
                test.is_true(tool_exists(compiled_spec.tools, "to_specialist"))

                test.is_false(has_delegate_tool(compiled_spec.tools, "tool"))
                test.is_true(has_delegate_tool(compiled_spec.tools, "to_specialist"))

                test.is_nil(compiled_spec.tools["tool"].agent_id)
                test.eq(compiled_spec.tools["to_specialist"].agent_id, "specialist:agent")
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

                test.is_nil(err)
                test.not_nil(compiled_spec)

                local delegate_tool = compiled_spec.tools["to_specialist"]
                test.eq(delegate_tool.context.agent_setting, "agent_value")
                test.eq(delegate_tool.context.delegate_setting, "delegate_value")
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

                test.is_nil(err)
                test.not_nil(compiled_spec)

                test.eq(compiled_spec.id, "test:comprehensive")
                test.eq(compiled_spec.max_tokens, 4096)
                test.eq(compiled_spec.temperature, 0.7)
                test.eq(compiled_spec.thinking_effort, 25)

                test.contains(compiled_spec.prompt, "You are a comprehensive agent.")
                test.contains(compiled_spec.prompt, "You have static capabilities.")
                test.contains(compiled_spec.prompt, "You have dynamic capabilities.")

                test.is_true(tool_exists(compiled_spec.tools, "tool"))
                test.is_true(tool_exists(compiled_spec.tools, "calculator"))
                test.is_true(tool_exists(compiled_spec.tools, "validator"))
                test.is_true(tool_exists(compiled_spec.tools, "generated_tool"))
                test.is_true(tool_exists(compiled_spec.tools, "inline_finish"))
                test.is_true(tool_exists(compiled_spec.tools, "to_helper"))

                test.is_true(has_delegate_tool(compiled_spec.tools, "to_helper"))
                test.is_false(has_delegate_tool(compiled_spec.tools, "tool"))

                test.eq(#compiled_spec.memory, 1)
                test.eq(compiled_spec.memory_contract.implementation_id, "mem:impl")

                test.eq(#compiled_spec.prompt_funcs, 1)
                test.eq(#compiled_spec.step_funcs, 1)

                for tool_name, tool_data in pairs(compiled_spec.tools) do
                    if not tool_data.agent_id then
                        test.eq(tool_data.context.agent_id, "test:comprehensive")
                    end
                end
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
