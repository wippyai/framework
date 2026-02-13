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
    end)
end

return require("test").run_cases(define_tests)
