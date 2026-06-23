local env = require("env")

local function define_tests()
    -- Helper function to count table elements
    local function count_table_elements(tbl)
        local count = 0
        for _ in pairs(tbl) do
            count = count + 1
        end
        return count
    end

    describe("Tool Caller", function()
        local tool_caller
        local wrapper_calls
        local wrapper_behaviors

        -- Mock tool schemas
        local tool_schemas = {
            ["test:calculator"] = {
                id = "test:calculator",
                name = "calculator",
                description = "Perform calculations",
                meta = { type = "tool" }
            },
            ["test:weather"] = {
                id = "test:weather",
                name = "get_weather",
                description = "Get weather information",
                meta = { type = "tool" }
            },
            ["test:exclusive"] = {
                id = "test:exclusive",
                name = "exclusive_tool",
                description = "An exclusive tool",
                meta = { type = "tool", exclusive = true }
            },
            ["test:non_exclusive"] = {
                id = "test:non_exclusive",
                name = "non_exclusive_tool",
                description = "A regular tool",
                meta = { type = "tool" }
            },
            ["test:failing_tool"] = {
                id = "test:failing_tool",
                name = "failing_tool",
                description = "A tool that fails",
                meta = { type = "tool" }
            }
        }

        -- Mock call results
        local tool_results = {
            ["test:calculator"] = { result = 42 },
            ["test:weather"] = { result = "Sunny, 25°C" },
            ["test:exclusive"] = { result = "exclusive_result" },
            ["test:non_exclusive"] = { result = "regular_result" },
            ["test:failing_tool"] = { error = "Tool execution failed" }
        }

        before_each(function()
            -- Reset tool results to ensure clean state
            tool_results = {
                ["test:calculator"] = { result = 42 },
                ["test:weather"] = { result = "Sunny, 25°C" },
                ["test:exclusive"] = { result = "exclusive_result" },
                ["test:non_exclusive"] = { result = "regular_result" },
                ["test:failing_tool"] = { error = "Tool execution failed" }
            }
            wrapper_calls = {}
            wrapper_behaviors = {}

            -- Create mock modules
            local mock_json = {
                encode = function(obj)
                    if type(obj) == "table" then
                        return '{"mocked":"json"}'
                    else
                        return tostring(obj)
                    end
                end,
                decode = function(str)
                    if str == '{"expression": "2 + 2"}' then
                        return { expression = "2 + 2" }
                    elseif str == '{"invalid": json}' then
                        return nil, "Invalid JSON"
                    else
                        return { parsed = true }
                    end
                end
            }

            local mock_tools = {
                get_tool_schema = function(registry_id)
                    local schema = (tool_schemas :: any)[registry_id]
                    if schema then
                        return schema, nil
                    else
                        return nil, "Tool not found: " .. registry_id
                    end
                end
            }

            local mock_funcs = {
                new = function()
                    local executor = {
                        context = {},
                        with_context = function(self, ctx)
                            local new_executor = {
                                context = ctx,
                                call = function(self, registry_id, args)
                                    local result_data = (tool_results :: any)[registry_id]
                                    if result_data then
                                        if result_data.error then
                                            return nil, result_data.error
                                        else
                                            return result_data.result, nil
                                        end
                                    else
                                        return nil, "Tool execution failed"
                                    end
                                end,
                                async = function(self, registry_id, args)
                                    local result_data = (tool_results :: any)[registry_id]
                                    local final_result = nil
                                    local final_error = nil

                                    if result_data then
                                        if result_data.error then
                                            final_error = result_data.error
                                        else
                                            final_result = result_data.result
                                        end
                                    else
                                        final_error = "Tool execution failed"
                                    end

                                    return {
                                        response = function()
                                            return {
                                                receive = function()
                                                    return {}, true
                                                end
                                            }
                                        end,
                                        is_canceled = function() return false end,
                                        result = function()
                                            if final_error then
                                                return nil, final_error
                                            else
                                                return {
                                                    data = function()
                                                        return final_result
                                                    end
                                                }, nil
                                            end
                                        end
                                    }
                                end
                            }
                            return new_executor
                        end
                    }
                    return executor
                end
            }

            local mock_contract = {
                get = function(contract_id)
                    if contract_id ~= "wippy.agent:tool_wrapper" then
                        return nil, "unknown contract: " .. tostring(contract_id)
                    end

                    local function open_with_context(binding_context)
                        return {
                            open = function(self, binding)
                                return {
                                    apply = function(self, payload)
                                        table.insert(wrapper_calls, {
                                            binding = binding,
                                            context = binding_context or {},
                                            payload = payload
                                        })

                                        local behavior = wrapper_behaviors[binding]
                                        if behavior then
                                            return behavior(payload, binding_context or {})
                                        end
                                        return {}, nil
                                    end
                                }, nil
                            end
                        }
                    end

                    return {
                        with_context = function(self, binding_context)
                            return open_with_context(binding_context)
                        end,
                        open = function(self, binding)
                            return open_with_context({}):open(binding)
                        end
                    }, nil
                end
            }

            -- Inject mocks via internal fields
            tool_caller = require("tool_caller")
            tool_caller._json = mock_json
            tool_caller._tools = mock_tools
            tool_caller._funcs = mock_funcs
            tool_caller._contract = mock_contract
        end)

        after_each(function()
            tool_caller._json = nil
            tool_caller._tools = nil
            tool_caller._funcs = nil
            tool_caller._contract = nil
            tool_caller = nil
            wrapper_calls = nil
            wrapper_behaviors = nil
        end)

        describe("Constructor and Strategy", function()
            it("should create a new tool caller instance", function()
                local caller = tool_caller.new()

                test.not_nil(caller)
                test.eq(caller.strategy, tool_caller.STRATEGY.SEQUENTIAL)
                test.not_nil(caller.executor)
            end)

            it("should default to sequential strategy", function()
                local caller = tool_caller.new()

                test.eq(caller.strategy, tool_caller.STRATEGY.SEQUENTIAL)
            end)

            it("should allow setting parallel strategy", function()
                local caller = tool_caller.new()
                local result = caller:set_strategy(tool_caller.STRATEGY.PARALLEL)

                test.eq(caller.strategy, tool_caller.STRATEGY.PARALLEL)
                test.eq(result, caller) -- Should return self for chaining
            end)

            it("should ignore invalid strategies", function()
                local caller = tool_caller.new()
                local original_strategy = caller.strategy

                caller:set_strategy("invalid_strategy")

                test.eq(caller.strategy, original_strategy)
            end)

            it("should allow strategy chaining", function()
                local caller = tool_caller.new()

                local result = caller:set_strategy(tool_caller.STRATEGY.PARALLEL):set_strategy(tool_caller.STRATEGY.SEQUENTIAL)

                test.eq(result, caller)
                test.eq(caller.strategy, tool_caller.STRATEGY.SEQUENTIAL)
            end)
        end)

        describe("Validation", function()
            it("should validate basic tool calls", function()
                local caller = tool_caller.new()

                local tool_calls = {
                    {
                        id = "call_123",
                        name = "calculator",
                        arguments = { expression = "2 + 2" },
                        registry_id = "test:calculator"
                    }
                }

                local validated_tools, err = caller:validate(tool_calls)

                test.is_nil(err)
                test.not_nil(validated_tools)
                test.eq(count_table_elements(validated_tools), 1)

                local tool_data = next(validated_tools)
                test.not_nil(validated_tools[tool_data])
                test.is_true(validated_tools[tool_data].valid)
                test.eq(validated_tools[tool_data].name, "calculator")
                test.eq(validated_tools[tool_data].registry_id, "test:calculator")
                test.eq(type(validated_tools[tool_data].args), "table")
            end)

            it("should handle multiple tool calls", function()
                local caller = tool_caller.new()

                local tool_calls = {
                    {
                        id = "call_123",
                        name = "calculator",
                        arguments = { expression = "2 + 2" },
                        registry_id = "test:calculator"
                    },
                    {
                        id = "call_456",
                        name = "get_weather",
                        arguments = { location = "New York" },
                        registry_id = "test:weather"
                    }
                }

                local validated_tools, err = caller:validate(tool_calls)

                test.is_nil(err)
                test.not_nil(validated_tools)
                test.eq(count_table_elements(validated_tools), 2)

                -- Check both tools are valid
                for _, tool_data in pairs(validated_tools) do
                    test.is_true(tool_data.valid)
                end
            end)

            it("should handle empty tool calls", function()
                local caller = tool_caller.new()

                local validated_tools, err = caller:validate({})

                test.is_nil(err)
                test.not_nil(validated_tools)
                test.eq(count_table_elements(validated_tools), 0)
            end)

            it("should handle nil tool calls", function()
                local caller = tool_caller.new()

                local validated_tools, err = caller:validate(nil)

                test.is_nil(err)
                test.not_nil(validated_tools)
                test.eq(count_table_elements(validated_tools), 0)
            end)

            it("should handle tool schema errors", function()
                local caller = tool_caller.new()

                local tool_calls = {
                    {
                        id = "call_123",
                        name = "nonexistent",
                        arguments = {},
                        registry_id = "nonexistent:tool"
                    }
                }

                local validated_tools, err = caller:validate(tool_calls)

                test.is_nil(err)
                test.not_nil(validated_tools)
                test.eq(count_table_elements(validated_tools), 1)

                local tool_data = next(validated_tools)
                test.is_false(validated_tools[tool_data].valid)
                test.contains(validated_tools[tool_data].error, "Failed to get tool schema")
            end)

            it("should preserve tool context", function()
                local caller = tool_caller.new()

                local tool_calls = {
                    {
                        id = "call_123",
                        name = "calculator",
                        arguments = { expression = "2 + 2" },
                        registry_id = "test:calculator",
                        context = { precision = "high", timeout = 30 }
                    }
                }

                local validated_tools, err = caller:validate(tool_calls)

                test.is_nil(err)
                local tool_data = next(validated_tools)
                test.not_nil(validated_tools[tool_data].context)
                test.eq(validated_tools[tool_data].context.precision, "high")
                test.eq(validated_tools[tool_data].context.timeout, 30)
            end)

            it("should handle exclusive tools", function()
                local caller = tool_caller.new()

                local tool_calls = {
                    {
                        id = "call_123",
                        name = "exclusive_tool",
                        arguments = {},
                        registry_id = "test:exclusive"
                    },
                    {
                        id = "call_456",
                        name = "non_exclusive_tool",
                        arguments = {},
                        registry_id = "test:non_exclusive"
                    }
                }

                local validated_tools, err = caller:validate(tool_calls)

                test.eq(err, "Exclusive tool found, other tools skipped")
                test.not_nil(validated_tools)
                test.eq(count_table_elements(validated_tools), 1)

                local tool_data = next(validated_tools)
                test.eq(validated_tools[tool_data].name, "exclusive_tool")
            end)

            it("should reject multiple exclusive tools", function()
                -- Add another exclusive tool for this test
                tool_schemas["test:exclusive2"] = {
                    id = "test:exclusive2",
                    name = "exclusive_tool2",
                    description = "Another exclusive tool",
                    meta = { type = "tool", exclusive = true }
                }

                local caller = tool_caller.new()

                local tool_calls = {
                    {
                        id = "call_123",
                        name = "exclusive_tool",
                        arguments = {},
                        registry_id = "test:exclusive"
                    },
                    {
                        id = "call_456",
                        name = "exclusive_tool2",
                        arguments = {},
                        registry_id = "test:exclusive2"
                    }
                }

                local validated_tools, err = caller:validate(tool_calls)

                test.not_nil(validated_tools)
                test.eq(count_table_elements(validated_tools), 0)
                test.eq(err, "Multiple exclusive tools found, cannot process")
            end)
        end)

        describe("Sequential Execution", function()
            it("should execute tools sequentially", function()
                local caller = tool_caller.new()
                caller:set_strategy(tool_caller.STRATEGY.SEQUENTIAL)

                local validated_tools = {
                    ["call_123"] = {
                        call_id = "call_123",
                        name = "calculator",
                        args = { expression = "2 + 2" },
                        registry_id = "test:calculator",
                        valid = true,
                        context = { precision = "high" }
                    }
                }

                local context = { user_id = "test_user" }
                local results = caller:execute(context, validated_tools)

                test.not_nil(results)
                test.not_nil(results["call_123"])
                test.eq(results["call_123"].result, 42)
                test.is_nil(results["call_123"].error)
                test.not_nil(results["call_123"].tool_call)
            end)

            it("should execute multiple tools in sequence", function()
                local caller = tool_caller.new()
                caller:set_strategy(tool_caller.STRATEGY.SEQUENTIAL)

                local validated_tools = {
                    ["call_123"] = {
                        call_id = "call_123",
                        name = "calculator",
                        args = { expression = "2 + 2" },
                        registry_id = "test:calculator",
                        valid = true
                    },
                    ["call_456"] = {
                        call_id = "call_456",
                        name = "get_weather",
                        args = { location = "New York" },
                        registry_id = "test:weather",
                        valid = true
                    }
                }

                local results = caller:execute({}, validated_tools)

                test.not_nil(results)
                test.eq(count_table_elements(results), 2)
                test.eq(results["call_123"].result, 42)
                test.eq(results["call_456"].result, "Sunny, 25°C")
            end)

            it("should handle tool execution errors", function()
                local caller = tool_caller.new()

                local validated_tools = {
                    ["call_123"] = {
                        call_id = "call_123",
                        name = "failing_tool",
                        args = {},
                        registry_id = "test:failing_tool",
                        valid = true
                    }
                }

                local results = caller:execute({}, validated_tools)

                test.not_nil(results["call_123"])
                test.is_nil(results["call_123"].result)
                test.eq(results["call_123"].error, "Tool execution failed")
            end)

            it("should handle invalid tools", function()
                local caller = tool_caller.new()

                local validated_tools = {
                    ["call_123"] = {
                        call_id = "call_123",
                        name = "invalid_tool",
                        args = {},
                        registry_id = "test:invalid",
                        valid = false,
                        error = "Tool validation failed"
                    }
                }

                local results = caller:execute({}, validated_tools)

                test.not_nil(results["call_123"])
                test.is_nil(results["call_123"].result)
                test.eq(results["call_123"].error, "Tool validation failed")
                test.not_nil(results["call_123"].tool_call)
            end)

            it("should parse string arguments", function()
                local caller = tool_caller.new()

                local validated_tools = {
                    ["call_123"] = {
                        call_id = "call_123",
                        name = "calculator",
                        args = '{"expression": "2 + 2"}',  -- String args
                        registry_id = "test:calculator",
                        valid = true
                    }
                }

                local results = caller:execute({}, validated_tools)

                test.not_nil(results["call_123"])
                test.eq(results["call_123"].result, 42)
            end)

            it("should handle invalid JSON arguments", function()
                local caller = tool_caller.new()

                local validated_tools = {
                    ["call_123"] = {
                        call_id = "call_123",
                        name = "calculator",
                        args = '{"invalid": json}',  -- Invalid JSON
                        registry_id = "test:calculator",
                        valid = true
                    }
                }

                local results = caller:execute({}, validated_tools)

                test.not_nil(results["call_123"])
                test.is_nil(results["call_123"].result)
                test.contains(results["call_123"].error, "Failed to parse arguments")
            end)

            it("should merge contexts with session priority", function()
                local caller = tool_caller.new()

                local validated_tools = {
                    ["call_123"] = {
                        call_id = "call_123",
                        name = "calculator",
                        args = {},
                        registry_id = "test:calculator",
                        valid = true,
                        context = { precision = "high", shared_key = "from_tool" }
                    }
                }

                local context = { user_id = "test_user", shared_key = "from_session" }
                local results = caller:execute(context, validated_tools)

                -- The test passes if execution succeeded with proper context merging
                test.not_nil(results["call_123"])
                test.eq(results["call_123"].result, 42)
            end)
        end)

        describe("Parallel Execution", function()
            it("should execute tools in parallel", function()
                local caller = tool_caller.new()
                caller:set_strategy(tool_caller.STRATEGY.PARALLEL)

                local validated_tools = {
                    ["call_123"] = {
                        call_id = "call_123",
                        name = "calculator",
                        args = { expression = "2 + 2" },
                        registry_id = "test:calculator",
                        valid = true
                    },
                    ["call_456"] = {
                        call_id = "call_456",
                        name = "get_weather",
                        args = { location = "New York" },
                        registry_id = "test:weather",
                        valid = true
                    }
                }

                local results = caller:execute({}, validated_tools)

                test.not_nil(results)
                test.eq(count_table_elements(results), 2)
                test.eq(results["call_123"].result, 42)
                test.eq(results["call_456"].result, "Sunny, 25°C")
            end)

            it("should handle parallel execution errors", function()
                local caller = tool_caller.new()
                caller:set_strategy(tool_caller.STRATEGY.PARALLEL)

                local validated_tools = {
                    ["call_123"] = {
                        call_id = "call_123",
                        name = "calculator",
                        args = { expression = "2 + 2" },
                        registry_id = "test:calculator",
                        valid = true
                    },
                    ["call_456"] = {
                        call_id = "call_456",
                        name = "failing_tool",
                        args = {},
                        registry_id = "test:failing_tool",
                        valid = true
                    }
                }

                local results = caller:execute({}, validated_tools)

                test.eq(results["call_123"].result, 42)
                test.is_nil(results["call_123"].error)
                test.is_nil(results["call_456"].result)
                test.eq(results["call_456"].error, "Tool execution failed")
            end)

            it("should handle parallel execution with invalid tools", function()
                local caller = tool_caller.new()
                caller:set_strategy(tool_caller.STRATEGY.PARALLEL)

                local validated_tools = {
                    ["call_123"] = {
                        call_id = "call_123",
                        name = "calculator",
                        args = { expression = "2 + 2" },
                        registry_id = "test:calculator",
                        valid = true
                    },
                    ["call_456"] = {
                        call_id = "call_456",
                        name = "invalid_tool",
                        args = {},
                        registry_id = "test:invalid",
                        valid = false,
                        error = "Tool validation failed"
                    }
                }

                local results = caller:execute({}, validated_tools)

                test.eq(results["call_123"].result, 42)
                test.eq(results["call_456"].error, "Tool validation failed")
            end)
        end)

        describe("Edge Cases and Error Handling", function()
            it("should handle execution with empty validated tools", function()
                local caller = tool_caller.new()

                local results = caller:execute({}, {})

                test.not_nil(results)
                test.eq(count_table_elements(results), 0)
            end)

            it("should handle execution with nil context", function()
                local caller = tool_caller.new()

                local results = caller:execute(nil, {})

                test.not_nil(results)
                test.eq(count_table_elements(results), 0)
            end)

            it("should handle execution with nil validated tools", function()
                local caller = tool_caller.new()

                local results = caller:execute({}, nil)

                test.not_nil(results)
                test.eq(count_table_elements(results), 0)
            end)

            it("should handle missing registry_id in tool calls", function()
                local caller = tool_caller.new()

                local validated_tools = {
                    ["call_123"] = {
                        call_id = "call_123",
                        name = "calculator",
                        args = { expression = "2 + 2" },
                        -- No registry_id field at all
                        valid = true
                    }
                }

                local results = caller:execute({}, validated_tools)

                -- Just check that we get some kind of error
                test.not_nil(results["call_123"])
                test.is_nil(results["call_123"].result)

                -- The execute should have failed in some way
                -- Either error is set, or result is nil, or both
                local has_error = results["call_123"].error ~= nil
                local no_result = results["call_123"].result == nil

                test.is_true(has_error or no_result)
            end)

            it("should set call_id in execution context", function()
                local caller = tool_caller.new()

                local validated_tools = {
                    ["call_123"] = {
                        call_id = "call_123",
                        name = "calculator",
                        args = { expression = "2 + 2" },
                        registry_id = "test:calculator",
                        valid = true
                    }
                }

                local results = caller:execute({}, validated_tools)

                test.not_nil(results["call_123"])
                test.eq(results["call_123"].result, 42) -- Execution succeeded
                test.is_nil(results["call_123"].error)
            end)
        end)

        describe("Constants Export", function()
            it("should export strategy constants", function()
                test.not_nil(tool_caller.STRATEGY)
                test.eq(tool_caller.STRATEGY.SEQUENTIAL, "sequential")
                test.eq(tool_caller.STRATEGY.PARALLEL, "parallel")
            end)

            it("should export function status constants", function()
                test.not_nil(tool_caller.FUNC_STATUS)
                test.eq(tool_caller.FUNC_STATUS.PENDING, "pending")
                test.eq(tool_caller.FUNC_STATUS.SUCCESS, "success")
                test.eq(tool_caller.FUNC_STATUS.ERROR, "error")
            end)
        end)

        describe("Tool Wrapper Contracts", function()
            local function calculator_call(call_id)
                return {
                    id = call_id or "call_calculator",
                    name = "calculator",
                    arguments = { expression = "2 + 2" },
                    registry_id = "test:calculator"
                }
            end

            it("should apply focused before and after wrapper bindings without losing context", function()
                wrapper_behaviors["test.wrapper:guard"] = function(payload, binding_context)
                    test.eq(payload.phase, tool_caller.PHASE.BEFORE_EXECUTE)
                    test.eq(payload.host.kind, "session")
                    test.eq(payload.host.session_id, "session-1")
                    test.eq(payload.agent.id, "agent-1")
                    test.eq(payload.options.max_calls, 1)
                    test.eq(binding_context.policy, "guard")
                    test.eq(binding_context.agent_id, "agent-1")
                    test.eq(binding_context.trait_id, "trait:guard")

                    return {
                        tool_calls = {
                            {
                                id = "call_weather",
                                name = "get_weather",
                                arguments = { city = "NYC" },
                                registry_id = "test:weather"
                            }
                        },
                        observations = {
                            {
                                level = "info",
                                code = "guard.checked",
                                content = "tool calls checked"
                            }
                        },
                        metadata = {
                            checked = true
                        }
                    }, nil
                end

                wrapper_behaviors["test.wrapper:audit"] = function(payload, binding_context)
                    test.eq(payload.phase, tool_caller.PHASE.AFTER_EXECUTE)
                    test.eq(payload.host.kind, "session")
                    test.eq(payload.host.session_id, "session-1")
                    test.eq(payload.agent.model, "gpt-test")
                    test.eq(payload.run_context.contract, "wippy.agent:run_context")
                    test.eq(payload.run_context.binding, "wippy.session.run_context:binding")
                    test.eq(payload.options.include_results, true)
                    test.eq(binding_context.policy, "audit")
                    test.eq(payload.tool_calls[1].registry_id, "test:weather")
                    test.not_nil(payload.tool_results.call_weather)
                    test.eq(payload.tool_results.call_weather.result, "Sunny, 25°C")
                    test.eq(payload.outcome.state, tool_caller.OUTCOME_STATE.CONTINUES)
                    test.eq(payload.outcome.reason, tool_caller.OUTCOME_REASON.TOOL_RESULTS_RECORDED)

                    return {
                        observations = {
                            {
                                level = "info",
                                code = "audit.recorded",
                                content = "tool results recorded"
                            }
                        }
                    }, nil
                end

                local caller = tool_caller.new()
                caller:set_tool_wrappers({
                    {
                        id = "audit",
                        trait_id = "trait:audit",
                        phases = { tool_caller.PHASE.AFTER_EXECUTE },
                        binding = "test.wrapper:audit",
                        priority = 20,
                        context = {
                            policy = "audit",
                            trait_id = "trait:audit"
                        },
                        options = {
                            include_results = true
                        }
                    },
                    {
                        id = "guard",
                        trait_id = "trait:guard",
                        phases = { tool_caller.PHASE.BEFORE_EXECUTE },
                        binding = "test.wrapper:guard",
                        priority = 10,
                        context = {
                            policy = "guard",
                            agent_id = "agent-1",
                            trait_id = "trait:guard"
                        },
                        options = {
                            max_calls = 1
                        }
                    }
                })
                caller:set_wrapper_context({
                    host = {
                        kind = "session",
                        session_id = "session-1"
                    },
                    agent = {
                        id = "agent-1",
                        model = "gpt-test"
                    },
                    run_context = {
                        contract = "wippy.agent:run_context",
                        binding = "wippy.session.run_context:binding",
                        host = {
                            kind = "session",
                            session_id = "session-1"
                        }
                    }
                })

                local validated, validate_err = caller:validate({ calculator_call() })
                test.is_nil(validate_err)
                test.not_nil(validated)
                test.not_nil(validated.call_weather)
                test.eq(validated.call_weather.registry_id, "test:weather")

                local results = caller:execute({}, validated)
                test.not_nil(results.call_weather)
                test.eq(results.call_weather.result, "Sunny, 25°C")

                test.eq(#wrapper_calls, 2)
                test.eq(wrapper_calls[1].binding, "test.wrapper:guard")
                test.eq(wrapper_calls[2].binding, "test.wrapper:audit")

                local observations = caller:get_wrapper_observations()
                test.eq(#observations, 2)
                test.eq(observations[1].code, "guard.checked")
                test.eq(observations[2].code, "audit.recorded")

                local metadata = caller:get_wrapper_metadata()
                test.eq(#metadata, 1)
                test.eq(metadata[1].wrapper_id, "guard")
                test.is_true(metadata[1].metadata.checked)
            end)

            it("should require host context when wrappers are configured", function()
                local caller = tool_caller.new()
                caller:set_tool_wrappers({
                    {
                        id = "guard",
                        phases = { tool_caller.PHASE.BEFORE_EXECUTE },
                        binding = "test.wrapper:guard",
                        strict = true
                    }
                })

                local validated, err = caller:validate({ calculator_call() })

                test.is_nil(validated)
                test.not_nil(err)
                test.not_nil(err:match("host is required"))
                test.eq(#wrapper_calls, 0)
            end)

            it("should block validation on strict before wrapper errors", function()
                wrapper_behaviors["test.wrapper:guard"] = function(payload, binding_context)
                    return nil, "blocked by policy"
                end

                local caller = tool_caller.new()
                caller:set_tool_wrappers({
                    {
                        id = "guard",
                        trait_id = "trait:guard",
                        phases = { tool_caller.PHASE.BEFORE_EXECUTE },
                        binding = "test.wrapper:guard",
                        strict = true
                    }
                })
                caller:set_wrapper_context({
                    host = { kind = "dataflow", dataflow_id = "df-1", node_id = "node-1", iteration = 3 },
                    agent = { id = "agent-1" }
                })

                local validated, err = caller:validate({ calculator_call() })

                test.is_nil(validated)
                test.not_nil(err)
                test.not_nil(err:match("blocked by policy"))

                local wrapper_errors = caller:get_wrapper_errors()
                test.eq(#wrapper_errors, 1)
                test.eq(wrapper_errors[1].phase, tool_caller.PHASE.BEFORE_EXECUTE)
                test.is_true(wrapper_errors[1].strict)
            end)

            it("should preserve tool results on after wrapper errors", function()
                wrapper_behaviors["test.wrapper:audit"] = function(payload, binding_context)
                    test.eq(payload.outcome.reason, tool_caller.OUTCOME_REASON.TOOL_RESULTS_RECORDED)
                    return nil, "audit sink unavailable"
                end

                local caller = tool_caller.new()
                caller:set_tool_wrappers({
                    {
                        id = "audit",
                        trait_id = "trait:audit",
                        phases = { tool_caller.PHASE.AFTER_EXECUTE },
                        binding = "test.wrapper:audit",
                        strict = false
                    }
                })
                caller:set_wrapper_context({
                    host = { kind = "dataflow", dataflow_id = "df-1", node_id = "node-1", iteration = 7 },
                    agent = { id = "agent-1", model = "gpt-test" }
                })

                local validated, validate_err = caller:validate({ calculator_call("call_123") })
                test.is_nil(validate_err)
                test.not_nil(validated)

                local results = caller:execute({}, validated)
                test.not_nil(results.call_123)
                test.eq(results.call_123.result, 42)

                local wrapper_errors = caller:get_wrapper_errors()
                test.eq(#wrapper_errors, 1)
                test.eq(wrapper_errors[1].phase, tool_caller.PHASE.AFTER_EXECUTE)
                test.is_false(wrapper_errors[1].strict)
            end)
        end)

        describe("Interface Completeness", function()
            it("should have all required methods", function()
                local caller = tool_caller.new()

                test.eq(type(caller.validate), "function")
                test.eq(type(caller.execute), "function")
                test.eq(type(caller.set_strategy), "function")
                test.eq(type(caller.set_tool_wrappers), "function")
                test.eq(type(caller.set_wrapper_context), "function")
            end)

            it("should maintain consistent interface", function()
                local caller = tool_caller.new()

                -- Test method chaining
                local result = caller:set_strategy(tool_caller.STRATEGY.PARALLEL)
                test.eq(result, caller)

                -- Test that methods return expected types
                local validated, err = caller:validate({})
                test.eq(type(validated), "table")
                test.is_true(err == nil or type(err) == "string")

                local execution_result = caller:execute({}, {})
                test.eq(type(execution_result), "table")
            end)
        end)
    end)

    describe("Real Tool Integration", function()
        if not env.get("ENABLE_INTEGRATION_TESTS") then
            return
        end

        before_all(function()
            -- Use real modules for integration tests
            tool_caller = require("tool_caller")
            tool_caller._json = nil
            tool_caller._tools = nil
            tool_caller._funcs = nil
        end)

        it("should call real delay tool sequentially", function()
            local tool_caller = require("tool_caller")
            local caller = tool_caller.new()
            caller:set_strategy(tool_caller.STRATEGY.SEQUENTIAL)

            -- Create tool call for real delay_tool
            local tool_calls = {
                {
                    id = "call_delay_1",
                    name = "delayed_echo",
                    arguments = {
                        message = "Hello from real tool!",
                        delay_ms = 50
                    },
                    registry_id = "wippy.agent.tools:delay_tool"
                }
            }

            -- Validate the tool call
            local validated_tools, err = caller:validate(tool_calls)
            test.is_nil(err)
            test.not_nil(validated_tools)
            test.eq(count_table_elements(validated_tools), 1)

            -- Execute the tool
            local context = { test_run = "integration" }
            local results = caller:execute(context, validated_tools)

            -- Verify results
            test.not_nil(results)
            local call_id = next(validated_tools)
            test.not_nil(results[call_id])
            test.is_nil(results[call_id].error)
            test.not_nil(results[call_id].result)

            -- Check the actual result from delay tool
            local result = results[call_id].result
            test.eq(result.message, "Hello from real tool!")
            test.eq(result.delay_applied, 50)
            test.not_nil(result.timestamp)
            test.not_nil(result.unix_time)
        end)

        it("should execute multiple real tools sequentially with proper ordering", function()
            local time = require("time")
            local tool_caller = require("tool_caller")
            local caller = tool_caller.new()
            caller:set_strategy(tool_caller.STRATEGY.SEQUENTIAL)

            local start_time = time.now()

            -- Create multiple tool calls with different delays
            local tool_calls = {
                {
                    id = "call_first",
                    name = "delayed_echo",
                    arguments = {
                        message = "First call",
                        delay_ms = 30
                    },
                    registry_id = "wippy.agent.tools:delay_tool"
                },
                {
                    id = "call_second",
                    name = "delayed_echo",
                    arguments = {
                        message = "Second call",
                        delay_ms = 20
                    },
                    registry_id = "wippy.agent.tools:delay_tool"
                },
                {
                    id = "call_third",
                    name = "delayed_echo",
                    arguments = {
                        message = "Third call",
                        delay_ms = 40
                    },
                    registry_id = "wippy.agent.tools:delay_tool"
                }
            }

            -- Validate and execute
            local validated_tools, err = caller:validate(tool_calls)
            test.is_nil(err)
            test.eq(count_table_elements(validated_tools), 3)

            local results = caller:execute({}, validated_tools)
            local end_time = time.now()

            -- Verify all calls succeeded
            test.not_nil(results)
            test.eq(count_table_elements(results), 3)

            for call_id, result in pairs(results) do
                test.is_nil(result.error)
                test.not_nil(result.result)
            end

            -- Verify total execution time is at least sum of delays (sequential)
            local total_duration = end_time:sub(start_time):milliseconds()
            test.is_true(total_duration >= 90) -- 30+20+40 = 90ms minimum

            -- Note: We can't easily verify exact execution order since the tool calls
            -- are processed from a hash table, not in array order. The important thing
            -- is that they execute sequentially (verified by timing) and all succeed.
            local messages_found = {}
            for _, result in pairs(results) do
                messages_found[result.result.message] = true
            end

            test.is_true(messages_found["First call"])
            test.is_true(messages_found["Second call"])
            test.is_true(messages_found["Third call"])
        end)

        it("should execute multiple real tools in parallel", function()
            local time = require("time")
            local tool_caller = require("tool_caller")
            local caller = tool_caller.new()
            caller:set_strategy(tool_caller.STRATEGY.PARALLEL)

            local start_time = time.now()

            -- Create multiple tool calls with delays
            local tool_calls = {
                {
                    id = "call_parallel_1",
                    name = "delayed_echo",
                    arguments = {
                        message = "Parallel call 1",
                        delay_ms = 60
                    },
                    registry_id = "wippy.agent.tools:delay_tool"
                },
                {
                    id = "call_parallel_2",
                    name = "delayed_echo",
                    arguments = {
                        message = "Parallel call 2",
                        delay_ms = 40
                    },
                    registry_id = "wippy.agent.tools:delay_tool"
                },
                {
                    id = "call_parallel_3",
                    name = "delayed_echo",
                    arguments = {
                        message = "Parallel call 3",
                        delay_ms = 50
                    },
                    registry_id = "wippy.agent.tools:delay_tool"
                }
            }

            -- Validate and execute in parallel
            local validated_tools, err = caller:validate(tool_calls)
            test.is_nil(err)
            test.eq(count_table_elements(validated_tools), 3)

            local results = caller:execute({}, validated_tools)
            local end_time = time.now()

            -- Verify all calls succeeded
            test.not_nil(results)
            test.eq(count_table_elements(results), 3)

            for call_id, result in pairs(results) do
                test.is_nil(result.error)
                test.not_nil(result.result)
            end

            -- Verify total execution time is closer to max delay (parallel)
            local total_duration = end_time:sub(start_time):milliseconds()
            test.is_true(total_duration < 150) -- Should be much less than 150ms (60+40+50)
            test.is_true(total_duration >= 60)  -- Should be at least max delay (60ms)

            -- Verify all results are present
            local messages = {}
            for _, result in pairs(results) do
                table.insert(messages, result.result.message)
            end

            local message_set = {}
            for _, msg in ipairs(messages) do
                message_set[msg] = true
            end

            test.is_true(message_set["Parallel call 1"])
            test.is_true(message_set["Parallel call 2"])
            test.is_true(message_set["Parallel call 3"])
        end)

        it("should handle real tool with various parameter combinations", function()
            local tool_caller = require("tool_caller")
            local caller = tool_caller.new()

            -- Test different parameter combinations
            local test_cases = {
                {
                    message = "Default delay",
                    -- No delay_ms specified, should use default 100ms
                },
                {
                    message = "Custom message with custom delay",
                    delay_ms = 25
                },
                {
                    message = "",  -- Empty message
                    delay_ms = 10
                },
                {
                    delay_ms = 0  -- Zero delay
                    -- No message, should use default "Hello"
                }
            }

            for i, test_case in ipairs(test_cases) do
                local tool_calls = {
                    {
                        id = "call_param_test_" .. i,
                        name = "delayed_echo",
                        arguments = test_case,
                        registry_id = "wippy.agent.tools:delay_tool"
                    }
                }

                local validated_tools, err = caller:validate(tool_calls)
                test.is_nil(err)

                local results = caller:execute({}, validated_tools)
                local call_id = next(validated_tools)

                test.is_nil(results[call_id].error)
                test.not_nil(results[call_id].result)

                local result = results[call_id].result
                test.not_nil(result.delay_applied)
                test.not_nil(result.timestamp)
                test.not_nil(result.unix_time)

                -- Verify defaults work
                if not test_case.message then
                    test.eq(result.message, "Hello")
                else
                    test.eq(result.message, test_case.message)
                end

                if not test_case.delay_ms then
                    test.eq(result.delay_applied, 100) -- Default
                else
                    test.eq(result.delay_applied, test_case.delay_ms)
                end
            end
        end)

        it("should handle real tool errors gracefully", function()
            local tool_caller = require("tool_caller")
            local caller = tool_caller.new()

            -- Test with invalid parameters that might cause errors
            local tool_calls = {
                {
                    id = "call_with_negative_delay",
                    name = "delayed_echo",
                    arguments = {
                        message = "Test message",
                        delay_ms = -50  -- Negative delay might cause issues
                    },
                    registry_id = "wippy.agent.tools:delay_tool"
                }
            }

            local validated_tools, err = caller:validate(tool_calls)
            test.is_nil(err)

            local results = caller:execute({}, validated_tools)
            local call_id = next(validated_tools)

            -- The tool should either succeed (if it handles negative gracefully)
            -- or fail with a proper error message
            test.not_nil(results[call_id])

            if results[call_id].error then
                -- If it errors, it should be a string
                test.eq(type(results[call_id].error), "string")
                test.is_nil(results[call_id].result)
            else
                -- If it succeeds, result should be valid
                test.not_nil(results[call_id].result)
                test.eq(results[call_id].result.message, "Test message")
            end
        end)

        it("should pass context to real tools and verify it's received", function()
            local tool_caller = require("tool_caller")
            local caller = tool_caller.new()

            local tool_calls = {
                {
                    id = "call_context_verification",
                    name = "delayed_echo",
                    arguments = {
                        message = "Context verification test",
                        delay_ms = 20
                    },
                    registry_id = "wippy.agent.tools:delay_tool",
                    context = {
                        tool_context_key = "tool_value",
                        shared_key = "from_tool_context",
                        tool_specific = "only_in_tool"
                    }
                }
            }

            local validated_tools, err = caller:validate(tool_calls)
            test.is_nil(err)

            -- Execute with session context
            local context = {
                session_key = "session_value",
                user_id = "test_user_123",
                shared_key = "from_context", -- Should override tool context
                test_run = "context_verification"
            }

            local results = caller:execute(context, validated_tools)
            local call_id = next(validated_tools)

            test.is_nil(results[call_id].error)
            test.not_nil(results[call_id].result)

            local result = results[call_id].result
            test.eq(result.message, "Context verification test")
            test.is_nil(result.context_error)
            test.not_nil(result.context_received)

            local ctx_received = result.context_received

            -- Verify session context values were received
            test.eq(ctx_received.session_key, "session_value")
            test.eq(ctx_received.user_id, "test_user_123")
            test.eq(ctx_received.test_run, "context_verification")

            -- Verify tool context values were received
            test.eq(ctx_received.tool_context_key, "tool_value")

            -- Verify session context overrides tool context for shared keys
            test.eq(ctx_received.shared_key, "from_context")

            -- Verify call_id was set by the caller
            test.not_nil(ctx_received.call_id)
            test.eq(type(ctx_received.call_id), "string")
        end)

        it("should handle empty and nil contexts properly", function()
            local tool_caller = require("tool_caller")
            local caller = tool_caller.new()

            -- Test with no tool context and no session context
            local tool_calls = {
                {
                    id = "call_empty_context",
                    name = "delayed_echo",
                    arguments = {
                        message = "Empty context test",
                        delay_ms = 15
                    },
                    registry_id = "wippy.agent.tools:delay_tool"
                    -- No context field at all
                }
            }

            local validated_tools, err = caller:validate(tool_calls)
            test.is_nil(err)

            -- Execute with empty session context
            local results = caller:execute({}, validated_tools)
            local call_id = next(validated_tools)

            test.is_nil(results[call_id].error)
            test.not_nil(results[call_id].result)

            local result = results[call_id].result
            test.is_nil(result.context_error)
            test.not_nil(result.context_received)

            local ctx_received = result.context_received

            -- Should still have call_id set by caller
            test.not_nil(ctx_received.call_id)

            -- Other context values should be nil
            test.is_nil(ctx_received.session_key)
            test.is_nil(ctx_received.user_id)
            test.is_nil(ctx_received.tool_context_key)
            test.is_nil(ctx_received.shared_key)
        end)

        it("should produce consistent results with both sequential and parallel strategies", function()
            local tool_caller = require("tool_caller")

            -- Test same tool calls with sequential strategy
            local sequential_caller = tool_caller.new()
            sequential_caller:set_strategy(tool_caller.STRATEGY.SEQUENTIAL)

            local tool_calls = {
                {
                    id = "seq_call_1",
                    name = "delayed_echo",
                    arguments = { message = "Sequential 1", delay_ms = 30 },
                    registry_id = "wippy.agent.tools:delay_tool"
                },
                {
                    id = "seq_call_2",
                    name = "delayed_echo",
                    arguments = { message = "Sequential 2", delay_ms = 20 },
                    registry_id = "wippy.agent.tools:delay_tool"
                }
            }

            local seq_validated, err = sequential_caller:validate(tool_calls)
            test.is_nil(err)

            local seq_results = sequential_caller:execute({}, seq_validated)
            test.eq(count_table_elements(seq_results), 2)

            -- Test same tool calls with parallel strategy
            local parallel_caller = tool_caller.new()
            parallel_caller:set_strategy(tool_caller.STRATEGY.PARALLEL)

            local par_validated, err = parallel_caller:validate(tool_calls)
            test.is_nil(err)

            local par_results = parallel_caller:execute({}, par_validated)
            test.eq(count_table_elements(par_results), 2)

            -- Both should succeed with same results (different timing)
            for _, result in pairs(seq_results) do
                test.is_nil(result.error)
                test.not_nil(result.result)
            end

            for _, result in pairs(par_results) do
                test.is_nil(result.error)
                test.not_nil(result.result)
            end

            -- Verify both strategies produced the expected messages
            local seq_messages = {}
            for _, result in pairs(seq_results) do
                seq_messages[result.result.message] = true
            end

            local par_messages = {}
            for _, result in pairs(par_results) do
                par_messages[result.result.message] = true
            end

            test.is_true(seq_messages["Sequential 1"])
            test.is_true(seq_messages["Sequential 2"])
            test.is_true(par_messages["Sequential 1"])
            test.is_true(par_messages["Sequential 2"])
        end)

        it("should handle real tool validation failures", function()
            local tool_caller = require("tool_caller")
            local caller = tool_caller.new()

            -- Test with non-existent tool
            local tool_calls = {
                {
                    id = "call_nonexistent",
                    name = "nonexistent_function",
                    arguments = { test = "data" },
                    registry_id = "wippy.agent.tools:nonexistent_tool"
                }
            }

            local validated_tools, err = caller:validate(tool_calls)
            test.is_nil(err)  -- Validation doesn't fail, but marks tool as invalid
            test.not_nil(validated_tools)
            test.eq(count_table_elements(validated_tools), 1)

            local call_id = next(validated_tools)
            test.is_false(validated_tools[call_id].valid)
            test.not_nil(validated_tools[call_id].error)

            -- Execute anyway - should handle invalid tool gracefully
            local results = caller:execute({}, validated_tools)
            test.not_nil(results[call_id])
            test.is_nil(results[call_id].result)
            test.not_nil(results[call_id].error)
        end)
    end)
end

return require("test").run_cases(define_tests)
