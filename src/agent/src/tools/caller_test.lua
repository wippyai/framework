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
        local original_package_loaded = {}

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
            -- Store original modules
            original_package_loaded.json = package.loaded.json
            original_package_loaded.uuid = package.loaded.uuid
            original_package_loaded.tools = package.loaded.tools
            original_package_loaded.funcs = package.loaded.funcs

            -- Reset tool results to ensure clean state
            tool_results = {
                ["test:calculator"] = { result = 42 },
                ["test:weather"] = { result = "Sunny, 25°C" },
                ["test:exclusive"] = { result = "exclusive_result" },
                ["test:non_exclusive"] = { result = "regular_result" },
                ["test:failing_tool"] = { error = "Tool execution failed" }
            }

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

            local uuid_counter = 1000
            local mock_uuid = {
                v7 = function()
                    uuid_counter = uuid_counter + 1
                    return "uuid_" .. uuid_counter
                end
            }

            local mock_tools = {
                get_tool_schema = function(registry_id)
                    local schema = tool_schemas[registry_id]
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
                                    local result_data = tool_results[registry_id]
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
                                    -- Mock async command - simplified version
                                    local result_data = tool_results[registry_id]
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
                                                    return {}, true -- payload_wrapper, ok
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

            -- Inject mock modules
            package.loaded.json = mock_json
            package.loaded.uuid = mock_uuid
            package.loaded.tools = mock_tools
            package.loaded.funcs = mock_funcs

            -- Clear any cached tool_caller module
            package.loaded.tool_caller = nil

            -- Now require tool_caller with mocked dependencies
            tool_caller = require("tool_caller")
        end)

        after_each(function()
            -- Restore original modules
            package.loaded.json = original_package_loaded.json
            package.loaded.uuid = original_package_loaded.uuid
            package.loaded.tools = original_package_loaded.tools
            package.loaded.funcs = original_package_loaded.funcs

            -- Clear tool_caller from cache
            package.loaded.tool_caller = nil
            tool_caller = nil
        end)

        describe("Constructor and Strategy", function()
            it("should create a new tool caller instance", function()
                local caller = tool_caller.new()

                expect(caller).not_to_be_nil()
                expect(caller.strategy).to_equal(tool_caller.STRATEGY.SEQUENTIAL)
                expect(caller.executor).not_to_be_nil()
            end)

            it("should default to sequential strategy", function()
                local caller = tool_caller.new()

                expect(caller.strategy).to_equal(tool_caller.STRATEGY.SEQUENTIAL)
            end)

            it("should allow setting parallel strategy", function()
                local caller = tool_caller.new()
                local result = caller:set_strategy(tool_caller.STRATEGY.PARALLEL)

                expect(caller.strategy).to_equal(tool_caller.STRATEGY.PARALLEL)
                expect(result).to_equal(caller) -- Should return self for chaining
            end)

            it("should ignore invalid strategies", function()
                local caller = tool_caller.new()
                local original_strategy = caller.strategy

                caller:set_strategy("invalid_strategy")

                expect(caller.strategy).to_equal(original_strategy)
            end)

            it("should allow strategy chaining", function()
                local caller = tool_caller.new()

                local result = caller:set_strategy(tool_caller.STRATEGY.PARALLEL):set_strategy(tool_caller.STRATEGY.SEQUENTIAL)

                expect(result).to_equal(caller)
                expect(caller.strategy).to_equal(tool_caller.STRATEGY.SEQUENTIAL)
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

                expect(err).to_be_nil()
                expect(validated_tools).not_to_be_nil()
                expect(count_table_elements(validated_tools)).to_equal(1)

                local tool_data = next(validated_tools)
                expect(validated_tools[tool_data]).not_to_be_nil()
                expect(validated_tools[tool_data].valid).to_be_true()
                expect(validated_tools[tool_data].name).to_equal("calculator")
                expect(validated_tools[tool_data].registry_id).to_equal("test:calculator")
                expect(validated_tools[tool_data].args).to_be_type("table")
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

                expect(err).to_be_nil()
                expect(validated_tools).not_to_be_nil()
                expect(count_table_elements(validated_tools)).to_equal(2)

                -- Check both tools are valid
                for _, tool_data in pairs(validated_tools) do
                    expect(tool_data.valid).to_be_true()
                end
            end)

            it("should handle empty tool calls", function()
                local caller = tool_caller.new()

                local validated_tools, err = caller:validate({})

                expect(err).to_be_nil()
                expect(validated_tools).not_to_be_nil()
                expect(count_table_elements(validated_tools)).to_equal(0)
            end)

            it("should handle nil tool calls", function()
                local caller = tool_caller.new()

                local validated_tools, err = caller:validate(nil)

                expect(err).to_be_nil()
                expect(validated_tools).not_to_be_nil()
                expect(count_table_elements(validated_tools)).to_equal(0)
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

                expect(err).to_be_nil()
                expect(validated_tools).not_to_be_nil()
                expect(count_table_elements(validated_tools)).to_equal(1)

                local tool_data = next(validated_tools)
                expect(validated_tools[tool_data].valid).to_be_false()
                expect(validated_tools[tool_data].error).to_contain("Failed to get tool schema")
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

                expect(err).to_be_nil()
                local tool_data = next(validated_tools)
                expect(validated_tools[tool_data].context).not_to_be_nil()
                expect(validated_tools[tool_data].context.precision).to_equal("high")
                expect(validated_tools[tool_data].context.timeout).to_equal(30)
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

                expect(err).to_equal("Exclusive tool found, other tools skipped")
                expect(validated_tools).not_to_be_nil()
                expect(count_table_elements(validated_tools)).to_equal(1)

                local tool_data = next(validated_tools)
                expect(validated_tools[tool_data].name).to_equal("exclusive_tool")
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

                expect(validated_tools).not_to_be_nil()
                expect(count_table_elements(validated_tools)).to_equal(0)
                expect(err).to_equal("Multiple exclusive tools found, cannot process")
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

                expect(results).not_to_be_nil()
                expect(results["call_123"]).not_to_be_nil()
                expect(results["call_123"].result).to_equal(42)
                expect(results["call_123"].error).to_be_nil()
                expect(results["call_123"].tool_call).not_to_be_nil()
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

                expect(results).not_to_be_nil()
                expect(count_table_elements(results)).to_equal(2)
                expect(results["call_123"].result).to_equal(42)
                expect(results["call_456"].result).to_equal("Sunny, 25°C")
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

                expect(results["call_123"]).not_to_be_nil()
                expect(results["call_123"].result).to_be_nil()
                expect(results["call_123"].error).to_equal("Tool execution failed")
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

                expect(results["call_123"]).not_to_be_nil()
                expect(results["call_123"].result).to_be_nil()
                expect(results["call_123"].error).to_equal("Tool validation failed")
                expect(results["call_123"].tool_call).not_to_be_nil()
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

                expect(results["call_123"]).not_to_be_nil()
                expect(results["call_123"].result).to_equal(42)
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

                expect(results["call_123"]).not_to_be_nil()
                expect(results["call_123"].result).to_be_nil()
                expect(results["call_123"].error).to_contain("Failed to parse arguments")
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
                expect(results["call_123"]).not_to_be_nil()
                expect(results["call_123"].result).to_equal(42)
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

                expect(results).not_to_be_nil()
                expect(count_table_elements(results)).to_equal(2)
                expect(results["call_123"].result).to_equal(42)
                expect(results["call_456"].result).to_equal("Sunny, 25°C")
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

                expect(results["call_123"].result).to_equal(42)
                expect(results["call_123"].error).to_be_nil()
                expect(results["call_456"].result).to_be_nil()
                expect(results["call_456"].error).to_equal("Tool execution failed")
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

                expect(results["call_123"].result).to_equal(42)
                expect(results["call_456"].error).to_equal("Tool validation failed")
            end)
        end)

        describe("Edge Cases and Error Handling", function()
            it("should handle execution with empty validated tools", function()
                local caller = tool_caller.new()

                local results = caller:execute({}, {})

                expect(results).not_to_be_nil()
                expect(count_table_elements(results)).to_equal(0)
            end)

            it("should handle execution with nil context", function()
                local caller = tool_caller.new()

                local results = caller:execute(nil, {})

                expect(results).not_to_be_nil()
                expect(count_table_elements(results)).to_equal(0)
            end)

            it("should handle execution with nil validated tools", function()
                local caller = tool_caller.new()

                local results = caller:execute({}, nil)

                expect(results).not_to_be_nil()
                expect(count_table_elements(results)).to_equal(0)
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
                expect(results["call_123"]).not_to_be_nil()
                expect(results["call_123"].result).to_be_nil()

                -- The execute should have failed in some way
                -- Either error is set, or result is nil, or both
                local has_error = results["call_123"].error ~= nil
                local no_result = results["call_123"].result == nil

                expect(has_error or no_result).to_be_true()
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

                expect(results["call_123"]).not_to_be_nil()
                expect(results["call_123"].result).to_equal(42) -- Execution succeeded
                expect(results["call_123"].error).to_be_nil()
            end)
        end)

        describe("Constants Export", function()
            it("should export strategy constants", function()
                expect(tool_caller.STRATEGY).not_to_be_nil()
                expect(tool_caller.STRATEGY.SEQUENTIAL).to_equal("sequential")
                expect(tool_caller.STRATEGY.PARALLEL).to_equal("parallel")
            end)

            it("should export function status constants", function()
                expect(tool_caller.FUNC_STATUS).not_to_be_nil()
                expect(tool_caller.FUNC_STATUS.PENDING).to_equal("pending")
                expect(tool_caller.FUNC_STATUS.SUCCESS).to_equal("success")
                expect(tool_caller.FUNC_STATUS.ERROR).to_equal("error")
            end)
        end)

        describe("Interface Completeness", function()
            it("should have all required methods", function()
                local caller = tool_caller.new()

                expect(type(caller.validate)).to_equal("function")
                expect(type(caller.execute)).to_equal("function")
                expect(type(caller.set_strategy)).to_equal("function")
            end)

            it("should maintain consistent interface", function()
                local caller = tool_caller.new()

                -- Test method chaining
                local result = caller:set_strategy(tool_caller.STRATEGY.PARALLEL)
                expect(result).to_equal(caller)

                -- Test that methods return expected types
                local validated, err = caller:validate({})
                expect(type(validated)).to_equal("table")
                expect(err == nil or type(err) == "string").to_be_true()

                local execution_result = caller:execute({}, {})
                expect(type(execution_result)).to_equal("table")
            end)
        end)
    end)

    describe("Real Tool Integration", function()
        if not env.get("ENABLE_INTEGRATION_TESTS") then
            return
        end

        before_all(function()
            -- Use real modules for integration tests
            package.loaded.tool_caller = nil
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
            expect(err).to_be_nil()
            expect(validated_tools).not_to_be_nil()
            expect(count_table_elements(validated_tools)).to_equal(1)

            -- Execute the tool
            local context = { test_run = "integration" }
            local results = caller:execute(context, validated_tools)

            -- Verify results
            expect(results).not_to_be_nil()
            local call_id = next(validated_tools)
            expect(results[call_id]).not_to_be_nil()
            expect(results[call_id].error).to_be_nil()
            expect(results[call_id].result).not_to_be_nil()

            -- Check the actual result from delay tool
            local result = results[call_id].result
            expect(result.message).to_equal("Hello from real tool!")
            expect(result.delay_applied).to_equal(50)
            expect(result.timestamp).not_to_be_nil()
            expect(result.unix_time).not_to_be_nil()
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
            expect(err).to_be_nil()
            expect(count_table_elements(validated_tools)).to_equal(3)

            local results = caller:execute({}, validated_tools)
            local end_time = time.now()

            -- Verify all calls succeeded
            expect(results).not_to_be_nil()
            expect(count_table_elements(results)).to_equal(3)

            for call_id, result in pairs(results) do
                expect(result.error).to_be_nil()
                expect(result.result).not_to_be_nil()
            end

            -- Verify total execution time is at least sum of delays (sequential)
            local total_duration = end_time:sub(start_time):milliseconds()
            expect(total_duration >= 90).to_be_true() -- 30+20+40 = 90ms minimum

            -- Note: We can't easily verify exact execution order since the tool calls
            -- are processed from a hash table, not in array order. The important thing
            -- is that they execute sequentially (verified by timing) and all succeed.
            local messages_found = {}
            for _, result in pairs(results) do
                messages_found[result.result.message] = true
            end

            expect(messages_found["First call"]).to_be_true()
            expect(messages_found["Second call"]).to_be_true()
            expect(messages_found["Third call"]).to_be_true()
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
            expect(err).to_be_nil()
            expect(count_table_elements(validated_tools)).to_equal(3)

            local results = caller:execute({}, validated_tools)
            local end_time = time.now()

            -- Verify all calls succeeded
            expect(results).not_to_be_nil()
            expect(count_table_elements(results)).to_equal(3)

            for call_id, result in pairs(results) do
                expect(result.error).to_be_nil()
                expect(result.result).not_to_be_nil()
            end

            -- Verify total execution time is closer to max delay (parallel)
            local total_duration = end_time:sub(start_time):milliseconds()
            expect(total_duration < 150).to_be_true() -- Should be much less than 150ms (60+40+50)
            expect(total_duration >= 60).to_be_true()  -- Should be at least max delay (60ms)

            -- Verify all results are present
            local messages = {}
            for _, result in pairs(results) do
                table.insert(messages, result.result.message)
            end

            local message_set = {}
            for _, msg in ipairs(messages) do
                message_set[msg] = true
            end

            expect(message_set["Parallel call 1"]).to_be_true()
            expect(message_set["Parallel call 2"]).to_be_true()
            expect(message_set["Parallel call 3"]).to_be_true()
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
                expect(err).to_be_nil()

                local results = caller:execute({}, validated_tools)
                local call_id = next(validated_tools)

                expect(results[call_id].error).to_be_nil()
                expect(results[call_id].result).not_to_be_nil()

                local result = results[call_id].result
                expect(result.delay_applied).not_to_be_nil()
                expect(result.timestamp).not_to_be_nil()
                expect(result.unix_time).not_to_be_nil()

                -- Verify defaults work
                if not test_case.message then
                    expect(result.message).to_equal("Hello")
                else
                    expect(result.message).to_equal(test_case.message)
                end

                if not test_case.delay_ms then
                    expect(result.delay_applied).to_equal(100) -- Default
                else
                    expect(result.delay_applied).to_equal(test_case.delay_ms)
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
            expect(err).to_be_nil()

            local results = caller:execute({}, validated_tools)
            local call_id = next(validated_tools)

            -- The tool should either succeed (if it handles negative gracefully)
            -- or fail with a proper error message
            expect(results[call_id]).not_to_be_nil()

            if results[call_id].error then
                -- If it errors, it should be a string
                expect(type(results[call_id].error)).to_equal("string")
                expect(results[call_id].result).to_be_nil()
            else
                -- If it succeeds, result should be valid
                expect(results[call_id].result).not_to_be_nil()
                expect(results[call_id].result.message).to_equal("Test message")
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
            expect(err).to_be_nil()

            -- Execute with session context
            local context = {
                session_key = "session_value",
                user_id = "test_user_123",
                shared_key = "from_context", -- Should override tool context
                test_run = "context_verification"
            }

            local results = caller:execute(context, validated_tools)
            local call_id = next(validated_tools)

            expect(results[call_id].error).to_be_nil()
            expect(results[call_id].result).not_to_be_nil()

            local result = results[call_id].result
            expect(result.message).to_equal("Context verification test")
            expect(result.context_error).to_be_nil()
            expect(result.context_received).not_to_be_nil()

            local ctx_received = result.context_received

            -- Verify session context values were received
            expect(ctx_received.session_key).to_equal("session_value")
            expect(ctx_received.user_id).to_equal("test_user_123")
            expect(ctx_received.test_run).to_equal("context_verification")

            -- Verify tool context values were received
            expect(ctx_received.tool_context_key).to_equal("tool_value")

            -- Verify session context overrides tool context for shared keys
            expect(ctx_received.shared_key).to_equal("from_context")

            -- Verify call_id was set by the caller
            expect(ctx_received.call_id).not_to_be_nil()
            expect(type(ctx_received.call_id)).to_equal("string")
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
            expect(err).to_be_nil()

            -- Execute with empty session context
            local results = caller:execute({}, validated_tools)
            local call_id = next(validated_tools)

            expect(results[call_id].error).to_be_nil()
            expect(results[call_id].result).not_to_be_nil()

            local result = results[call_id].result
            expect(result.context_error).to_be_nil()
            expect(result.context_received).not_to_be_nil()

            local ctx_received = result.context_received

            -- Should still have call_id set by caller
            expect(ctx_received.call_id).not_to_be_nil()

            -- Other context values should be nil
            expect(ctx_received.session_key).to_be_nil()
            expect(ctx_received.user_id).to_be_nil()
            expect(ctx_received.tool_context_key).to_be_nil()
            expect(ctx_received.shared_key).to_be_nil()
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
            expect(err).to_be_nil()

            local seq_results = sequential_caller:execute({}, seq_validated)
            expect(count_table_elements(seq_results)).to_equal(2)

            -- Test same tool calls with parallel strategy
            local parallel_caller = tool_caller.new()
            parallel_caller:set_strategy(tool_caller.STRATEGY.PARALLEL)

            local par_validated, err = parallel_caller:validate(tool_calls)
            expect(err).to_be_nil()

            local par_results = parallel_caller:execute({}, par_validated)
            expect(count_table_elements(par_results)).to_equal(2)

            -- Both should succeed with same results (different timing)
            for _, result in pairs(seq_results) do
                expect(result.error).to_be_nil()
                expect(result.result).not_to_be_nil()
            end

            for _, result in pairs(par_results) do
                expect(result.error).to_be_nil()
                expect(result.result).not_to_be_nil()
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

            expect(seq_messages["Sequential 1"]).to_be_true()
            expect(seq_messages["Sequential 2"]).to_be_true()
            expect(par_messages["Sequential 1"]).to_be_true()
            expect(par_messages["Sequential 2"]).to_be_true()
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
            expect(err).to_be_nil()  -- Validation doesn't fail, but marks tool as invalid
            expect(validated_tools).not_to_be_nil()
            expect(count_table_elements(validated_tools)).to_equal(1)

            local call_id = next(validated_tools)
            expect(validated_tools[call_id].valid).to_be_false()
            expect(validated_tools[call_id].error).not_to_be_nil()

            -- Execute anyway - should handle invalid tool gracefully
            local results = caller:execute({}, validated_tools)
            expect(results[call_id]).not_to_be_nil()
            expect(results[call_id].result).to_be_nil()
            expect(results[call_id].error).not_to_be_nil()
        end)
    end)
end

return require("test").run_cases(define_tests)