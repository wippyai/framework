local agent_context = require("context")

local function define_tests()
    describe("Agent Context SDK", function()
        local mock_registry
        local mock_compiler
        local mock_agent
        local context

        local raw_agent_spec = {
            id = "test-agent",
            name = "Test Agent",
            description = "A test agent",
            model = "gpt-4o-mini",
            prompt = "You are a test agent.",
            tools = {"test:calculator"},
            context = {
                agent_type = "test"
            }
        }

        local compiled_agent_spec = {
            id = "test-agent",
            name = "Test Agent",
            description = "A test agent",
            model = "gpt-4o-mini",
            prompt = "You are a test agent.",
            tools = {"test:calculator"},
            tool_contexts = {},
            tool_schemas = {},
            delegate_tools = {},
            delegate_map = {}
        }

        local mock_agent_instance = {
            id = "test-agent",
            name = "Test Agent",
            model = "gpt-4o-mini",
            step = function(self, prompt_builder, runtime_options)
                return {
                    result = "Test response",
                    tokens = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 }
                }
            end
        }

        before_each(function()
            mock_registry = {
                get_by_id = function(agent_id)
                    if agent_id == "test-agent" then
                        return {
                            id = "test-agent",
                            name = "Test Agent",
                            description = "A test agent",
                            model = "gpt-4o-mini",
                            prompt = "You are a test agent.",
                            tools = {"test:calculator"},
                            context = {
                                agent_type = "test"
                            }
                        }, nil
                    elseif agent_id == "specialist-agent" then
                        return {
                            id = "specialist-agent",
                            name = "Specialist Agent",
                            model = "claude-sonnet",
                            prompt = "You are a specialist.",
                            tools = {}
                        }, nil
                    else
                        return nil, "Agent not found: " .. agent_id
                    end
                end,
                get_by_name = function(agent_name)
                    if agent_name == "test-agent" then
                        return {
                            id = "test-agent",
                            name = "Test Agent",
                            description = "A test agent",
                            model = "gpt-4o-mini",
                            prompt = "You are a test agent.",
                            tools = {"test:calculator"},
                            context = {
                                agent_type = "test"
                            }
                        }, nil
                    else
                        return nil, "Agent not found: " .. agent_name
                    end
                end
            }

            mock_compiler = {
                compile = function(raw_spec, config)
                    local compiled = {}
                    for k, v in pairs(raw_spec) do
                        compiled[k] = v
                    end
                    compiled.tool_contexts = {}
                    compiled.tool_schemas = {}
                    compiled.delegate_tools = {}
                    compiled.delegate_map = {}
                    return compiled, nil
                end
            }

            mock_agent = {
                new = function(compiled_spec)
                    local instance = {}
                    for k, v in pairs(mock_agent_instance) do
                        instance[k] = v
                    end
                    instance.id = compiled_spec.id
                    instance.name = compiled_spec.name
                    instance.model = compiled_spec.model
                    return instance, nil
                end
            }

            agent_context._agent_registry = mock_registry
            agent_context._compiler = mock_compiler
            agent_context._agent = mock_agent

            context = agent_context.new({
                context = {
                    user_id = "test-user",
                    environment = "test"
                }
            })
        end)

        after_each(function()
            agent_context._agent_registry = nil
            agent_context._compiler = nil
            agent_context._agent = nil
        end)

        describe("Construction", function()
            it("should create context with smart defaults", function()
                local default_context = agent_context.new()

                test.not_nil(default_context)
                test.eq(default_context.enable_cache, true)
                test.is_nil(next(default_context.base_context))
                test.is_nil(default_context.current_agent)
                test.is_nil(default_context.current_agent_id)
                test.is_nil(default_context.current_model)
                test.eq(#default_context.additional_tools, 0)
                test.eq(#default_context.additional_delegates, 0)
            end)

            it("should create context with custom config", function()
                local custom_context = agent_context.new({
                    enable_cache = false,
                    context = {
                        user_id = "test-user",
                        environment = "production"
                    },
                    delegate_tools = {
                        enabled = true,
                        description_suffix = " - specialist agent",
                        default_schema = {
                            type = "object",
                            properties = {
                                task = { type = "string" }
                            }
                        }
                    },
                    memory_contract = {
                        implementation_id = "vector_memory",
                        context = { collection = "test" }
                    }
                })

                test.not_nil(custom_context)
                test.eq(custom_context.enable_cache, true)
                test.eq(custom_context.base_context.user_id, "test-user")
                test.eq(custom_context.base_context.environment, "production")
                test.eq(custom_context.compilation_config.delegates.generate_tool_schemas, true)
                test.eq(custom_context.compilation_config.delegates.description_suffix, " - specialist agent")
                test.eq(custom_context.memory_contract.implementation_id, "vector_memory")
            end)
        end)

        describe("Tool Management", function()
            it("should add single tool as string", function()
                context:add_tools("wippy.files:read_file")

                test.eq(#context.additional_tools, 1)
                test.eq(context.additional_tools[1].id, "wippy.files:read_file")
            end)

            it("should add single tool as object", function()
                context:add_tools({
                    id = "wippy.files:write_file",
                    alias = "save_file",
                    description = "Save content to file",
                    context = { encoding = "utf-8" }
                })

                test.eq(#context.additional_tools, 1)
                local tool = context.additional_tools[1]
                test.eq(tool.id, "wippy.files:write_file")
                test.eq(tool.alias, "save_file")
                test.eq(tool.description, "Save content to file")
                test.eq(tool.context.encoding, "utf-8")
            end)

            it("should add multiple tools as array", function()
                context:add_tools({
                    "wippy.dev:*",
                    "wippy.search:web_search",
                    {
                        id = "wippy.data:analyze_csv",
                        alias = "analyze_data",
                        description = "Analyze CSV data",
                        context = { max_rows = 10000 }
                    }
                })

                test.eq(#context.additional_tools, 3)
                test.eq(context.additional_tools[1].id, "wippy.dev:*")
                test.eq(context.additional_tools[2].id, "wippy.search:web_search")
                test.eq(context.additional_tools[3].alias, "analyze_data")
            end)

            it("should clear current agent when tools are added", function()
                local agent_instance, err = context:load_agent("test-agent")
                test.is_nil(err)
                test.not_nil(context.current_agent)

                context:add_tools("new_tool")
                test.is_nil(context.current_agent)
                test.is_nil(context.current_agent_id)
            end)

            it("should chain tool additions", function()
                local result = context:add_tools("tool1"):add_tools("tool2")

                test.eq(result, context)
                test.eq(#context.additional_tools, 2)
            end)
        end)

        describe("Delegate Management", function()
            it("should add single delegate", function()
                context:add_delegates({
                    id = "code_specialist",
                    name = "write_code",
                    rule = "when coding is needed"
                })

                test.eq(#context.additional_delegates, 1)
                test.eq(context.additional_delegates[1].id, "code_specialist")
                test.eq(context.additional_delegates[1].name, "write_code")
            end)

            it("should add multiple delegates", function()
                context:add_delegates({
                    {
                        id = "code_specialist",
                        name = "write_code",
                        rule = "for coding tasks"
                    },
                    {
                        id = "data_analyst",
                        name = "analyze_data",
                        rule = "for data analysis",
                        schema = {
                            type = "object",
                            properties = {
                                data_type = { type = "string" }
                            }
                        }
                    }
                })

                test.eq(#context.additional_delegates, 2)
                test.eq(context.additional_delegates[1].name, "write_code")
                test.not_nil(context.additional_delegates[2].schema)
            end)

            it("should auto-enable delegate tool generation when delegates added", function()
                test.eq(context.compilation_config.delegates.generate_tool_schemas, false)

                context:add_delegates({
                    id = "specialist",
                    name = "delegate_task"
                })

                test.eq(context.compilation_config.delegates.generate_tool_schemas, true)
            end)

            it("should configure delegate tools", function()
                context:configure_delegate_tools({
                    enabled = true,
                    description_suffix = " - expert assistance",
                    default_schema = {
                        type = "object",
                        properties = {
                            request = { type = "string" }
                        }
                    }
                })

                test.eq(context.compilation_config.delegates.generate_tool_schemas, true)
                test.eq(context.compilation_config.delegates.description_suffix, " - expert assistance")
                test.not_nil(context.compilation_config.delegates.tool_schema.properties.request)
            end)
        end)

        describe("Agent Loading", function()
            it("should load agent by ID successfully", function()
                local agent_instance, err = context:load_agent("test-agent")

                test.is_nil(err)
                test.not_nil(agent_instance)

                if agent_instance then
                    test.eq(agent_instance.id, "test-agent")
                    test.eq(agent_instance.name, "Test Agent")
                    test.eq(agent_instance.model, "gpt-4o-mini")
                end

                test.eq(context.current_agent_id, "test-agent")
                test.eq(context.current_model, "gpt-4o-mini")
            end)

            it("should load agent by name successfully", function()
                local agent_instance, err = context:load_agent("test-agent")

                test.is_nil(err)
                test.not_nil(agent_instance)

                if agent_instance then
                    test.eq(agent_instance.id, "test-agent")
                end
            end)

            it("should handle agent not found", function()
                local agent_instance, err = context:load_agent("nonexistent-agent")

                test.is_nil(agent_instance)
                test.not_nil(err)
                if err then
                    test.contains(err, "Failed to load agent")
                    test.contains(err, "nonexistent-agent")
                end
            end)

            it("should handle missing agent identifier", function()
                local agent_instance, err = context:load_agent(nil)

                test.is_nil(agent_instance)
                test.eq(err, "Agent spec or identifier is required")
            end)

            it("should apply model override", function()
                local agent_instance, err = context:load_agent("test-agent", { model = "claude-haiku" })

                test.is_nil(err)
                test.not_nil(agent_instance)

                if agent_instance then
                    test.eq(agent_instance.model, "claude-haiku")
                    test.eq(context.current_model, "claude-haiku")
                end
            end)

            it("should include additional tools in compilation", function()
                context:add_tools({
                    "wippy.files:read_file",
                    {
                        id = "custom_tool",
                        alias = "my_tool"
                    }
                })

                local agent_instance, err = context:load_agent("test-agent")

                test.is_nil(err)
                test.not_nil(agent_instance)
            end)

            it("should include additional delegates in compilation", function()
                context:add_delegates({
                    {
                        id = "specialist",
                        name = "delegate_task"
                    }
                })

                local agent_instance, err = context:load_agent("test-agent")

                test.is_nil(err)
                test.not_nil(agent_instance)
                test.eq(context.compilation_config.delegates.generate_tool_schemas, true)
            end)
        end)

        describe("Current Agent Access", function()
            it("should return current agent when loaded", function()
                local agent_instance, load_err = context:load_agent("test-agent")
                test.is_nil(load_err)

                local current_agent, err = context:get_current_agent()
                test.is_nil(err)
                test.not_nil(current_agent)

                if current_agent then
                    test.eq(current_agent.id, "test-agent")
                end
            end)

            it("should handle no agent loaded", function()
                local current_agent, err = context:get_current_agent()

                test.is_nil(current_agent)
                test.eq(err, "No agent loaded")
            end)
        end)

        describe("Agent Switching", function()
            it("should switch to different agent successfully", function()
                local agent1, load_err1 = context:load_agent("test-agent")
                test.is_nil(load_err1)
                test.eq(context.current_agent_id, "test-agent")

                local success, err = context:switch_to_agent("specialist-agent")

                test.eq(success, true)
                test.is_nil(err)
                test.eq(context.current_agent_id, "specialist-agent")
                test.eq(context.current_model, "claude-sonnet")
            end)

            it("should preserve model when explicitly specified", function()
                local agent1, load_err1 = context:load_agent("test-agent", { model = "gpt-4o" })
                test.is_nil(load_err1)
                test.eq(context.current_model, "gpt-4o")

                local success, err = context:switch_to_agent("specialist-agent", { model = "gpt-4o" })

                test.eq(success, true)
                test.is_nil(err)
                test.eq(context.current_model, "gpt-4o")
            end)

            it("should handle agent switch failure", function()
                local agent1, load_err1 = context:load_agent("test-agent")
                test.is_nil(load_err1)

                local success, err = context:switch_to_agent("nonexistent-agent")

                test.eq(success, false)
                test.not_nil(err)
                if err then
                    test.contains(err, "Failed to load agent")
                end

                test.eq(context.current_agent_id, "test-agent")
            end)

            it("should handle missing agent identifier", function()
                local agent1, load_err1 = context:load_agent("test-agent")
                test.is_nil(load_err1)

                local success, err = context:switch_to_agent(nil)

                test.eq(success, false)
                test.eq(err, "Agent spec or identifier is required")
            end)
        end)

        describe("Model Switching", function()
            it("should switch model on current agent", function()
                local agent1, load_err1 = context:load_agent("test-agent")
                test.is_nil(load_err1)
                test.eq(context.current_model, "gpt-4o-mini")

                local success, err = context:switch_to_model("claude-sonnet")

                test.eq(success, true)
                test.is_nil(err)
                test.eq(context.current_model, "claude-sonnet")
                test.eq(context.current_agent_id, "test-agent")
            end)

            it("should handle no current agent", function()
                local success, err = context:switch_to_model("gpt-4o")

                test.eq(success, false)
                test.eq(err, "No current agent to change model for")
            end)

            it("should handle missing model name", function()
                local agent1, load_err1 = context:load_agent("test-agent")
                test.is_nil(load_err1)

                local success, err = context:switch_to_model(nil)

                test.eq(success, false)
                test.eq(err, "Model name is required")
            end)

            it("should handle empty model name", function()
                local agent1, load_err1 = context:load_agent("test-agent")
                test.is_nil(load_err1)

                local success, err = context:switch_to_model("")

                test.eq(success, false)
                test.eq(err, "Model name is required")
            end)
        end)

        describe("Context Management", function()
            it("should update base context", function()
                context:update_context({
                    new_key = "new_value",
                    priority = "high"
                })

                test.eq(context.base_context.new_key, "new_value")
                test.eq(context.base_context.priority, "high")

                test.eq(context.base_context.user_id, "test-user")
                test.eq(context.base_context.environment, "test")
            end)

            it("should clear current agent when context updated", function()
                local agent1, load_err1 = context:load_agent("test-agent")
                test.is_nil(load_err1)
                test.not_nil(context.current_agent)

                context:update_context({ new_key = "value" })

                test.is_nil(context.current_agent)
                test.is_nil(context.current_agent_id)
            end)

            it("should chain context updates", function()
                local result = context:update_context({ key1 = "value1" })

                test.eq(result, context)
                test.eq(context.base_context.key1, "value1")
            end)
        end)

        describe("Configuration Management", function()
            it("should set memory contract", function()
                context:set_memory_contract({
                    implementation_id = "redis_memory",
                    context = { host = "localhost" }
                })

                test.not_nil(context.memory_contract)
                test.eq(context.memory_contract.implementation_id, "redis_memory")
                test.eq(context.memory_contract.context.host, "localhost")
            end)

            it("should set custom context merger", function()
                local custom_merger = function(trait_ctx, agent_ctx, tool_ctx)
                    return { merged = true }
                end

                context:set_context_merger(custom_merger)

                test.eq(context.compilation_config.context_merger, custom_merger)
            end)

            it("should get configuration summary", function()
                context:add_tools({"tool1", "tool2"})
                context:add_delegates({{id = "delegate1", name = "delegate"}})
                context:set_memory_contract({implementation_id = "test_memory"})

                local agent1, load_err1 = context:load_agent("test-agent")
                test.is_nil(load_err1)

                local config = context:get_config()

                test.eq(config.current_agent_id, "test-agent")
                test.eq(config.current_model, "gpt-4o-mini")
                test.eq(config.additional_tools_count, 2)
                test.eq(config.additional_delegates_count, 1)
                test.eq(config.has_memory_contract, true)
                test.eq(config.cache_enabled, true)
                test.eq(config.delegate_tools_enabled, true)
            end)
        end)

        describe("Integration Scenarios", function()
            it("should handle complete agent lifecycle with new API", function()
                local ctx = agent_context.new({
                    context = { environment = "test" },
                    delegate_tools = { enabled = true }
                })

                ctx:add_tools({
                    "wippy.files:read_file",
                    {
                        id = "custom_tool",
                        alias = "my_tool",
                        description = "Custom tool"
                    }
                })
                ctx:add_delegates({{
                    id = "specialist",
                    name = "delegate_task"
                }})

                local agent1, err1 = ctx:load_agent("test-agent")
                test.is_nil(err1)
                test.eq(ctx.current_agent_id, "test-agent")

                local success2, err2 = ctx:switch_to_model("gpt-4o")
                test.eq(success2, true)
                test.is_nil(err2)
                test.eq(ctx.current_model, "gpt-4o")

                ctx:update_context({ workflow_stage = "analysis" })

                local agent_reload, reload_err = ctx:load_agent("test-agent", { model = "gpt-4o" })
                test.is_nil(reload_err)
                test.eq(ctx.current_agent_id, "test-agent")
                test.eq(ctx.current_model, "gpt-4o")

                local success3, err3 = ctx:switch_to_agent("specialist-agent", { model = "gpt-4o" })
                test.eq(success3, true)
                test.is_nil(err3)
                test.eq(ctx.current_agent_id, "specialist-agent")
                test.eq(ctx.current_model, "gpt-4o")

                local current, err4 = ctx:get_current_agent()
                test.is_nil(err4)
                test.not_nil(current)
                if current then
                    test.eq(current.id, "specialist-agent")
                end
            end)

            it("should handle errors gracefully without corrupting state", function()
                local agent1, load_err1 = context:load_agent("test-agent")
                test.is_nil(load_err1)

                local original_id = context.current_agent_id
                local original_model = context.current_model

                local success1, err1 = context:switch_to_agent("nonexistent-agent")
                test.eq(success1, false)

                local success2, err2 = context:switch_to_model("")
                test.eq(success2, false)

                test.eq(context.current_agent_id, original_id)
                test.eq(context.current_model, original_model)

                local current, err = context:get_current_agent()
                test.is_nil(err)
                test.not_nil(current)
            end)

            it("should support method chaining pattern", function()
                local chained_result = agent_context.new()
                    :add_tools({"tool1", "tool2"})
                    :add_delegates({{id = "delegate1", name = "delegate"}})
                    :update_context({environment = "prod"})
                    :set_memory_contract({implementation_id = "memory"})

                if chained_result then
                    local final_agent, load_err = chained_result:load_agent("test-agent")

                    test.eq(chained_result.current_agent_id, "test-agent")
                    test.eq(chained_result.base_context.environment, "prod")
                    test.eq(#chained_result.additional_tools, 2)
                    test.eq(#chained_result.additional_delegates, 1)
                    test.not_nil(chained_result.memory_contract)
                else
                    test.not_nil(chained_result)
                end
            end)
        end)

        describe("Active trait and tool overlays", function()
            local captured

            local function capture_compiler()
                captured = nil
                agent_context._compiler = {
                    compile = function(raw_spec, _config)
                        captured = raw_spec
                        local compiled = {}
                        for k, v in pairs(raw_spec) do
                            compiled[k] = v
                        end
                        compiled.tool_contexts = {}
                        compiled.tool_schemas = {}
                        compiled.delegate_tools = {}
                        compiled.delegate_map = {}
                        return compiled, nil
                    end
                }
            end

            local function has_tool(tools, id)
                for _, t in ipairs(tools or {}) do
                    local tid = type(t) == "table" and t.id or t
                    if tid == id then
                        return true
                    end
                end
                return false
            end

            it("should store a copy of active traits and pend recompile", function()
                context:load_agent("test-agent")
                test.not_nil(context.current_agent)

                local traits = { "trait_a", "trait_b" }
                local result = context:set_active_traits(traits)

                test.eq(result, context, "returns self for chaining")
                test.eq(#context.active_traits, 2)
                test.is_nil(context.current_agent, "current agent cleared so next load recompiles")

                traits[3] = "leaked"
                test.eq(#context.active_traits, 2, "external mutation does not leak into stored overlay")
            end)

            it("should replace the agent's traits on compile", function()
                capture_compiler()
                context:set_active_traits({ "only_this_trait" })
                local agent_instance, err = context:load_agent("test-agent")

                test.is_nil(err)
                test.not_nil(agent_instance)
                test.eq(#captured.traits, 1)
                test.eq(captured.traits[1], "only_this_trait")
            end)

            it("should replace the explicit tool set while arena tools still layer on top", function()
                capture_compiler()
                context:set_active_tools({ "wippy.x:active_tool" })
                context:add_tools("wippy.x:arena_tool")
                context:load_agent("test-agent")

                test.is_false(has_tool(captured.tools, "test:calculator"), "base tool replaced")
                test.is_true(has_tool(captured.tools, "wippy.x:active_tool"), "declared tool present")
                test.is_true(has_tool(captured.tools, "wippy.x:arena_tool"), "arena tool still appended")
            end)

            it("should fall back to the agent's own set when overlay is cleared with nil", function()
                capture_compiler()
                context:set_active_tools({ "wippy.x:active_tool" })
                context:set_active_tools(nil)
                test.is_nil(context.active_tools)

                context:load_agent("test-agent")
                test.is_false(has_tool(captured.tools, "wippy.x:active_tool"), "dropped overlay not applied")
                test.is_true(has_tool(captured.tools, "test:calculator"), "agent's own tools used")
            end)

            it("should not mutate the stored tool overlay when arena tools are appended", function()
                capture_compiler()
                context:set_active_tools({ "wippy.x:active_tool" })
                context:add_tools("wippy.x:arena_tool")
                context:load_agent("test-agent")

                test.eq(#context.active_tools, 1, "overlay still holds only the declared tool")
            end)

            it("should drop overlays when switching to a different agent", function()
                capture_compiler()
                context:load_agent("test-agent")
                context:set_active_traits({ "trait_a" })
                context:set_active_tools({ "wippy.x:active_tool" })

                local ok, err = context:switch_to_agent("specialist-agent")
                test.is_true(ok, tostring(err))
                test.is_nil(context.active_traits, "trait overlay dropped on agent switch")
                test.is_nil(context.active_tools, "tool overlay dropped on agent switch")
                test.is_false(has_tool(captured.tools, "wippy.x:active_tool"),
                    "previous agent's overlay not applied to the new agent")
            end)

            it("should preserve overlays across a model switch on the same agent", function()
                capture_compiler()
                -- Setting an overlay invalidates the loaded agent (incl. its id), so the
                -- realistic flow is: declare overlay -> load_agent to reconcile. A model
                -- switch on the now-loaded agent must keep the overlay.
                context:set_active_tools({ "wippy.x:active_tool" })
                context:load_agent("test-agent")

                local ok, err = context:switch_to_model("claude-haiku")
                test.is_true(ok, tostring(err))
                test.not_nil(context.active_tools, "overlay preserved on model switch")
                test.is_true(has_tool(captured.tools, "wippy.x:active_tool"), "overlay still applied")
                test.eq(captured.model, "claude-haiku")
            end)

            it("should treat an empty list as an explicit empty set", function()
                capture_compiler()
                context:set_active_tools({})
                context:load_agent("test-agent")

                test.is_false(has_tool(captured.tools, "test:calculator"), "base tools cleared")
                test.eq(#captured.tools, 0)
            end)

            it("should normalize a single trait or tool into a list", function()
                context:set_active_traits("solo_trait")
                test.eq(#context.active_traits, 1)
                test.eq(context.active_traits[1], "solo_trait")

                context:set_active_tools("wippy.x:solo_tool")
                test.eq(#context.active_tools, 1)
                test.eq(context.active_tools[1], "wippy.x:solo_tool")
            end)

            it("should report overlay state via get_config", function()
                test.is_false(context:get_config().has_active_traits)
                test.is_false(context:get_config().has_active_tools)

                context:set_active_traits({ "t" })
                test.is_true(context:get_config().has_active_traits)

                context:set_active_traits(nil)
                test.is_false(context:get_config().has_active_traits)
            end)

            it("should apply the trait overlay on every load without consuming it", function()
                capture_compiler()
                context:set_active_traits({ "persistent_trait" })

                context:load_agent("test-agent")
                test.eq(#captured.traits, 1)
                test.eq(captured.traits[1], "persistent_trait")

                context:load_agent("test-agent")
                test.eq(#captured.traits, 1, "overlay re-applied on the second load")
                test.eq(#context.active_traits, 1, "stored overlay neither consumed nor mutated")
            end)

            it("should not mutate the stored trait overlay across loads", function()
                capture_compiler()
                context:set_active_traits({ "trait_a" })
                context:load_agent("test-agent")

                -- mutating the compiled spec's trait list must not reach the stored overlay
                table.insert(captured.traits, "injected")
                test.eq(#context.active_traits, 1, "stored overlay isolated from compiled spec")
            end)

            it("should replace a previously declared overlay when set again", function()
                context:set_active_tools({ "tool_v1" })
                context:set_active_tools({ "tool_v2", "tool_v3" })

                test.eq(#context.active_tools, 2)
                test.eq(context.active_tools[1], "tool_v2")
            end)

            it("should disable trait processing for an explicit empty trait list", function()
                capture_compiler()
                context:set_active_traits({})
                context:load_agent("test-agent")

                test.not_nil(captured.traits)
                test.eq(#captured.traits, 0, "empty overlay yields no traits")
            end)

            it("should chain overlay setters", function()
                local result = context:set_active_traits({ "t" }):set_active_tools({ "x" })

                test.eq(result, context)
                test.eq(#context.active_traits, 1)
                test.eq(#context.active_tools, 1)
            end)
        end)

        -- Reconcile coverage: the suite above asserts the overlay reaches the compiler as
        -- raw_spec; these run the REAL compiler to prove an overlay actually changes the
        -- compiled prompt and tool set the agent runs with.
        describe("Active overlay reconcile (real compiler)", function()
            local compiler = require("compiler")
            local compiled

            local trait_defs = {
                ["trait:researcher"] = {
                    id = "trait:researcher",
                    name = "researcher",
                    prompt = "You research thoroughly before answering.",
                    tools = { "research:search" }
                },
                ["trait:writer"] = {
                    id = "trait:writer",
                    name = "writer",
                    prompt = "You write concisely."
                }
            }

            local function use_real_compiler()
                compiled = nil
                agent_context._compiler = {
                    compile = function(raw_spec, config)
                        local c, err = compiler.compile(raw_spec, config)
                        compiled = c
                        return c, err
                    end
                }
                compiler._traits = {
                    get_by_id = function(id)
                        local d = (trait_defs :: any)[id]
                        return d, d and nil or ("no trait: " .. id)
                    end,
                    get_by_name = function(name)
                        for _, d in pairs(trait_defs) do
                            if d.name == name then return d end
                        end
                        return nil, "no trait named " .. name
                    end
                }
                compiler._tools = {
                    find_tools = function(query)
                        if query and query.namespace == "research" then
                            return { { id = "research:search" }, { id = "research:summarize" } }
                        end
                        return {}
                    end,
                    run_input_schema_processors = function(schema) return schema end,
                    get_tool_schema = function(tool_id)
                        local name = tostring(tool_id):match("[^:]+$") or tool_id
                        return {
                            id = tool_id,
                            registry_id = tool_id,
                            name = name,
                            description = "Schema for " .. tool_id,
                            schema = { type = "object", properties = {} }
                        }
                    end
                }
            end

            after_each(function()
                compiler._traits = nil
                compiler._tools = nil
                compiler._funcs = nil
            end)

            local function tool_by_registry_id(tools, registry_id)
                for _, entry in pairs(tools or {}) do
                    if entry.registry_id == registry_id then return entry end
                end
                return nil
            end

            it("merges an active trait's prompt and tool into the compiled agent", function()
                use_real_compiler()
                context:set_active_traits({ "trait:researcher" })
                local agent_instance, err = context:load_agent("test-agent")

                test.is_nil(err)
                test.not_nil(agent_instance)
                test.not_nil(compiled)
                test.not_nil(string.find(compiled.prompt, "You are a test agent", 1, true),
                    "base agent prompt preserved")
                test.not_nil(string.find(compiled.prompt, "research thoroughly", 1, true),
                    "trait prompt merged into compiled prompt")
                test.not_nil(tool_by_registry_id(compiled.tools, "research:search"),
                    "trait tool present in compiled tool set")
                test.not_nil(tool_by_registry_id(compiled.tools, "test:calculator"),
                    "agent's own tool still present")
            end)

            it("silently skips an unknown trait in the overlay", function()
                use_real_compiler()
                context:set_active_traits({ "trait:does_not_exist" })
                local agent_instance, err = context:load_agent("test-agent")

                test.is_nil(err, "unknown trait does not fail compilation")
                test.not_nil(agent_instance)
                test.eq(compiled.prompt, "You are a test agent.", "no trait prompt appended")
            end)

            it("clears the agent's base tools with an empty tool overlay", function()
                use_real_compiler()
                context:set_active_tools({})
                context:load_agent("test-agent")

                test.is_nil(tool_by_registry_id(compiled.tools, "test:calculator"),
                    "base tool removed by empty overlay")
            end)

            it("keeps a trait's contributed tool even when the tool overlay is empty", function()
                use_real_compiler()
                context:set_active_traits({ "trait:researcher" })
                context:set_active_tools({})
                context:load_agent("test-agent")

                test.is_nil(tool_by_registry_id(compiled.tools, "test:calculator"),
                    "base tool cleared by empty tool overlay")
                test.not_nil(tool_by_registry_id(compiled.tools, "research:search"),
                    "trait-contributed tool survives the empty tool overlay")
            end)

            it("applies trait prompts in the overlay's declared order", function()
                use_real_compiler()
                context:set_active_traits({ "trait:writer", "trait:researcher" })
                context:load_agent("test-agent")

                local prompt = compiled.prompt :: string
                local writer_at = string.find(prompt, "write concisely", 1, true)
                local researcher_at = string.find(prompt, "research thoroughly", 1, true)
                test.not_nil(writer_at)
                test.not_nil(researcher_at)
                test.is_true((writer_at or 0) < (researcher_at or 0),
                    "writer prompt precedes researcher prompt, matching overlay order")
            end)

            it("reconciles a single-string trait overlay", function()
                use_real_compiler()
                context:set_active_traits("trait:researcher")
                context:load_agent("test-agent")

                test.not_nil(string.find(compiled.prompt :: string, "research thoroughly", 1, true),
                    "single-string trait normalized and merged")
            end)

            it("keys a table tool overlay by its alias", function()
                use_real_compiler()
                context:set_active_tools({ { id = "research:search", alias = "finder" } })
                context:load_agent("test-agent")

                local entry = (compiled.tools :: {[string]: any})["finder"]
                test.not_nil(entry, "tool keyed by alias")
                test.eq(entry.registry_id, "research:search", "alias entry resolves to the registry id")
            end)

            it("expands a wildcard tool overlay against the namespace", function()
                use_real_compiler()
                context:set_active_tools({ "research:*" })
                context:load_agent("test-agent")

                test.not_nil(tool_by_registry_id(compiled.tools, "research:search"))
                test.not_nil(tool_by_registry_id(compiled.tools, "research:summarize"))
                test.is_nil(tool_by_registry_id(compiled.tools, "test:calculator"),
                    "base tool replaced by the wildcard overlay")
            end)

            it("collapses a trait tool and an overlay tool with the same id into one entry", function()
                use_real_compiler()
                context:set_active_traits({ "trait:researcher" })
                context:set_active_tools({ "research:search" })
                context:load_agent("test-agent")

                local count = 0
                for _, entry in pairs(compiled.tools :: {[string]: any}) do
                    if entry.registry_id == "research:search" then count = count + 1 end
                end
                test.eq(count, 1, "duplicate tool id collapses to a single compiled entry")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
