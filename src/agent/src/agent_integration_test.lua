-- Comprehensive integration tests for the FULL agent system chain:
-- Raw Spec -> Compiler -> Compiled Spec -> Agent Runner -> Tool Caller -> Real Tools

local agent = require("agent")
local compiler = require("compiler")
local tool_caller = require("tool_caller")
local prompt = require("prompt")
local time = require("time")
local json = require("json")
local env = require("env")

local function define_integration_tests()
    -- Skip all integration tests if not enabled
    if not env.get("ENABLE_INTEGRATION_TESTS") then
        print("WARNING: Integration tests skipped - set ENABLE_INTEGRATION_TESTS=true to run")
        return
    end

    -- Test helpers for full chain testing
    local test_helpers = {}

    -- Helper: Pretty print JSON with indentation
    function test_helpers.pretty_print_json(obj, title)
        print(string.format("\n=== %s ===", title))

        local json_str = json.encode(obj)
        -- Simple pretty printing - add newlines after commas and braces
        json_str = json_str:gsub(',"', ',\n  "')
        json_str = json_str:gsub('{"', '{\n  "')
        json_str = json_str:gsub('"}', '"\n}')
        json_str = json_str:gsub('":{', '":\n  {')

        print(json_str)
        print(string.rep("=", #title + 8))
    end

    -- Helper: Count table elements
    function test_helpers.count_table(tbl)
        if not tbl then return 0 end
        local count = 0
        for _ in pairs(tbl) do count = count + 1 end
        return count
    end

    -- Helper: Get table keys as array
    function test_helpers.get_keys(tbl)
        if not tbl then return {} end
        local keys = {}
        for k, _ in pairs(tbl) do
            table.insert(keys, tostring(k))
        end
        return keys
    end

    -- Helper: Create raw agent spec (before compilation) with tool aliases
    function test_helpers.create_raw_agent_spec_with_aliases()
        return {
            id = "test-parallel-agent",
            name = "Parallel Tool Test Agent",
            description = "Agent that tests tool aliases and parallel execution",
            model = "class:test-model",  -- Updated to use test model
            max_tokens = 1024,
            temperature = 0.1,
            thinking_effort = 0,
            prompt = [[You are a test agent that MUST call the specified tools when asked.

CRITICAL INSTRUCTIONS:
- When asked to test parallel execution, you MUST call BOTH fast_echo and slow_echo tools
- When asked to call tools, you MUST use the tools - do not just respond with text
- Always call the tools with the exact messages requested
- Available tools: fast_echo (for speed tests), slow_echo (for thorough tests)

Be concise in your text responses but ALWAYS use the tools when requested.]],

            -- Tools with aliases - same registry tool, different names and contexts
            tools = {
                {
                    id = "wippy.agent.tools:delay_tool",
                    alias = "fast_echo",
                    description = "Quick response tool for immediate feedback and speed tests",
                    context = {
                        default_delay = 25,
                        priority = "high",
                        service_type = "fast_response",
                        timeout = 5000
                    }
                },
                {
                    id = "wippy.agent.tools:delay_tool",
                    alias = "slow_echo",
                    description = "Thorough response tool for detailed processing and tests",
                    context = {
                        default_delay = 80,
                        priority = "normal",
                        service_type = "thorough_processing",
                        timeout = 10000
                    }
                }
            },

            memory = {},
            delegates = {},
            context = {
                agent_purpose = "integration_testing",
                test_suite = "parallel_tools"
            }
        }
    end

    -- Helper: Create simple raw agent spec for basic tests
    function test_helpers.create_simple_raw_agent_spec()
        return {
            id = "simple-test-agent",
            name = "Simple Test Agent",
            description = "Basic agent for simple integration tests",
            model = "class:test-model",  -- Updated to use test model
            max_tokens = 512,
            temperature = 0.1,
            prompt = "You are a helpful test assistant. Be concise.",
            tools = {},
            memory = {},
            delegates = {},
            context = { test_type = "basic" }
        }
    end

    -- Helper: Create strategy test agent spec
    function test_helpers.create_strategy_test_agent_spec()
        return {
            id = "strategy-test-agent",
            name = "Strategy Test Agent",
            description = "Agent for testing sequential vs parallel execution strategies",
            model = "class:test-model",  -- Updated to use test model
            max_tokens = 1024,
            temperature = 0.1,
            thinking_effort = 0,
            prompt = [[You are a strategy testing agent that MUST call multiple tools when asked.

CRITICAL INSTRUCTIONS:
- When asked to test strategies, you MUST call ALL the requested tools
- Always use the tools - do not just respond with text
- Call tools with the exact messages and delays requested

Be concise but ALWAYS use the tools when requested.]],

            tools = {
                {
                    id = "wippy.agent.tools:delay_tool",
                    alias = "test_tool_1",
                    description = "First test tool",
                    context = {
                        default_delay = 30,
                        test_type = "strategy_test"
                    }
                },
                {
                    id = "wippy.agent.tools:delay_tool",
                    alias = "test_tool_2",
                    description = "Second test tool",
                    context = {
                        default_delay = 25,
                        test_type = "strategy_test"
                    }
                },
                {
                    id = "wippy.agent.tools:delay_tool",
                    alias = "test_tool_3",
                    description = "Third test tool",
                    context = {
                        default_delay = 35,
                        test_type = "strategy_test"
                    }
                }
            },

            memory = {},
            delegates = {},
            context = {
                test_purpose = "strategy_testing"
            }
        }
    end

    -- Helper: Execute full agent compilation chain
    function test_helpers.compile_and_create_agent(raw_spec, config)
        print(string.format("\nSTEP 1: Compiling raw agent spec: %s", raw_spec.id))
        test_helpers.pretty_print_json(raw_spec, "Raw Agent Spec")

        -- Compile the raw spec
        local compiled_spec, compile_err = compiler.compile(raw_spec, config)
        if compile_err then
            error(string.format("Compilation failed: %s", compile_err))
        end

        print("STEP 2: Compilation successful")
        test_helpers.pretty_print_json(compiled_spec, "Compiled Agent Spec")

        -- Create agent runner from compiled spec
        print("STEP 3: Creating agent runner")
        local agent_runner, agent_err = agent.new(compiled_spec)
        if agent_err then
            error(string.format("Agent creation failed: %s", agent_err))
        end

        print(string.format("SUCCESS: Agent '%s' created with %d tools",
            agent_runner.name, test_helpers.count_table(agent_runner.tools)))

        return agent_runner, compiled_spec
    end

    -- Helper: Execute agent step with detailed logging
    function test_helpers.execute_agent_step(agent_runner, user_message, runtime_options)
        print(string.format("\nSTEP 4: Agent execution - message: '%s'", user_message))
        print(string.format("Agent has %d tools: [%s]",
            test_helpers.count_table(agent_runner.tools),
            table.concat(test_helpers.get_keys(agent_runner.tools), ", ")))

        local prompt_builder = prompt.new()
        prompt_builder:add_user(user_message)

        -- Prepare step options
        local step_options = runtime_options or {}

        local start_time = time.now()
        local result, err = agent_runner:step(prompt_builder, step_options)
        local end_time = time.now()

        print(string.format("Agent execution took %dms", end_time:sub(start_time):milliseconds()))

        if err then
            print(string.format("AGENT STEP ERROR: %s", err))
            error(string.format("Agent step failed: %s", err))
        end

        if result then
            print(string.format("Agent result: %s", result.result or "nil"))
            test_helpers.pretty_print_json(result, "Agent Step Result")

            if result.tool_calls then
                print(string.format("Agent made %d tool calls:", #result.tool_calls))
                for i, call in ipairs(result.tool_calls) do
                    print(string.format("  %d. %s (id: %s, registry: %s)",
                        i, call.name, call.id, call.registry_id))
                    print(string.format("     args: %s", json.encode(call.arguments)))
                    if call.context then
                        print(string.format("     context keys: [%s]", table.concat(test_helpers.get_keys(call.context), ", ")))
                    end
                end
            else
                print("No tool calls made")
            end

            if result.error then
                print(string.format("Agent error: %s", result.error))
            end
        else
            print("AGENT RETURNED NIL RESULT")
            error("Agent returned nil result with no error message")
        end

        return {
            result = result,
            duration_ms = end_time:sub(start_time):milliseconds(),
            agent_stats = agent_runner:get_stats(),
            prompt_builder = prompt_builder
        }
    end

    -- Helper: Execute tools with tool caller and detailed logging
    function test_helpers.execute_tools_with_caller(tool_calls, context, strategy)
        print(string.format("\nSTEP 5: Tool execution with %d tools using %s strategy",
            #tool_calls, strategy or "SEQUENTIAL"))

        -- Create and configure tool caller
        local caller = tool_caller.new()
        if strategy == "PARALLEL" then
            caller:set_strategy(tool_caller.STRATEGY.PARALLEL)
            print("Using PARALLEL execution strategy")
        else
            caller:set_strategy(tool_caller.STRATEGY.SEQUENTIAL)
            print("Using SEQUENTIAL execution strategy")
        end

        -- Log tool calls (contexts should already be attached by agent)
        for i, tool_call in ipairs(tool_calls) do
            print(string.format("Tool %d: %s -> %s", i, tool_call.name, tool_call.registry_id))
            if tool_call.context then
                print(string.format("  Context keys: [%s]", table.concat(test_helpers.get_keys(tool_call.context), ", ")))
            else
                print("  No context attached")
            end
        end

        -- Validate tools
        local validated_tools, validation_err = caller:validate(tool_calls)
        if validation_err then
            print(string.format("Tool validation error: %s", validation_err))
            return nil, validation_err
        end

        print(string.format("Validated %d tools", test_helpers.count_table(validated_tools)))
        test_helpers.pretty_print_json(validated_tools, "Validated Tools")

        -- Execute tools
        local start_time = time.now()
        local results = caller:execute(context or {}, validated_tools)
        local end_time = time.now()

        print(string.format("Tool execution took %dms", end_time:sub(start_time):milliseconds()))
        test_helpers.pretty_print_json(results, "Tool Execution Results")

        -- Log individual results
        for call_id, result in pairs(results) do
            local tool_info = validated_tools[call_id]
            local tool_name = tool_info and tool_info.name or "unknown"

            if result.error then
                print(string.format("Tool %s failed: %s", tool_name, result.error))
            else
                print(string.format("Tool %s succeeded", tool_name))
                if result.result and result.result.message then
                    print(string.format("  Message: '%s'", result.result.message))
                end
                if result.result and result.result.delay_applied then
                    print(string.format("  Delay: %dms", result.result.delay_applied))
                end
                if result.result and result.result.context_received then
                    print(string.format("  Context keys received: [%s]",
                        table.concat(test_helpers.get_keys(result.result.context_received), ", ")))
                end
            end
        end

        return {
            results = results,
            duration_ms = end_time:sub(start_time):milliseconds(),
            validated_tools = validated_tools,
            caller = caller
        }
    end

    -- Helper: Assert tool execution result
    function test_helpers.assert_tool_result(result, expected_message, expected_delay, call_name)
        expect(result).not_to_be_nil()
        expect(result.error).to_be_nil()
        expect(result.result).not_to_be_nil()

        local tool_result = result.result
        expect(tool_result.message).to_equal(expected_message)

        if expected_delay then
            -- Allow some flexibility in delay timing (within 50ms)
            expect(math.abs(tool_result.delay_applied - expected_delay) < 50).to_be_true()
        end

        expect(tool_result.timestamp).not_to_be_nil()
        expect(tool_result.context_received).not_to_be_nil()

        print(string.format("ASSERTION PASSED: %s - message='%s', delay=%dms",
            call_name or "Tool call", tool_result.message, tool_result.delay_applied or 0))
    end

    describe("Agent Integration Tests - Full Chain", function()
        before_all(function()
            print("\n" .. string.rep("=", 60))
            print("STARTING AGENT INTEGRATION TESTS - FULL CHAIN")
            print("Testing: Raw Spec -> Compiler -> Agent -> Tool Caller -> Tools")
            print(string.rep("=", 60))

            -- Ensure we're using real modules
            agent._llm = nil
            agent._prompt = nil
            agent._contract = nil
            package.loaded.tool_caller = nil

            -- Check environment
            local openai_key = env.get("OPENAI_API_KEY")
            if openai_key then
                print("OpenAI API key found")
            else
                print("WARNING: No OpenAI API key found - some models may not work")
            end
        end)

        it("should work with basic raw spec compilation and execution", function()
            print("\n" .. string.rep("-", 50))
            print("TEST: Basic Raw Spec Compilation and Execution")
            print(string.rep("-", 50))

            -- Create simple raw spec
            local raw_spec = test_helpers.create_simple_raw_agent_spec()

            -- Compile and create agent
            local agent_runner, compiled_spec = test_helpers.compile_and_create_agent(raw_spec)

            -- Verify compiled spec structure
            expect(compiled_spec.id).to_equal(raw_spec.id)
            expect(compiled_spec.name).to_equal(raw_spec.name)
            expect(compiled_spec.model).to_equal(raw_spec.model)
            expect(compiled_spec.prompt).to_equal(raw_spec.prompt)

            -- Execute basic agent step
            local execution = test_helpers.execute_agent_step(
                agent_runner,
                "Say hello in exactly 3 words"
            )

            expect(execution.result).not_to_be_nil()
            expect(execution.result.result).not_to_be_nil()
            expect(#execution.result.result > 5).to_be_true()

            print(string.format("SUCCESS: Basic agent responded: '%s'", execution.result.result))
            print(string.format("Token usage: %d total", execution.agent_stats.total_tokens.total))
        end)

        it("should compile raw spec with tool aliases and execute tools in parallel", function()
            print("\n" .. string.rep("-", 50))
            print("TEST: Full Chain - Tool Aliases + Parallel Execution")
            print(string.rep("-", 50))

            -- Create raw spec with tool aliases
            local raw_spec = test_helpers.create_raw_agent_spec_with_aliases()

            -- Compile with default config
            local agent_runner, compiled_spec = test_helpers.compile_and_create_agent(raw_spec)

            -- Verify compilation worked correctly - UPDATED for unified structure
            expect(compiled_spec.tools).not_to_be_nil()
            expect(test_helpers.count_table(compiled_spec.tools)).to_equal(2)

            print(string.format("Compiled agent has %d tools: [%s]",
                test_helpers.count_table(compiled_spec.tools),
                table.concat(test_helpers.get_keys(compiled_spec.tools), ", ")))

            -- Verify unified tool structure has correct entries
            expect(compiled_spec.tools["fast_echo"]).not_to_be_nil()
            expect(compiled_spec.tools["slow_echo"]).not_to_be_nil()

            -- Check tool properties
            expect(compiled_spec.tools["fast_echo"].context.default_delay).to_equal(25)
            expect(compiled_spec.tools["slow_echo"].context.default_delay).to_equal(80)
            expect(compiled_spec.tools["fast_echo"].context.agent_id).to_equal(raw_spec.id)

            -- Execute agent step to get tool calls
            local execution = test_helpers.execute_agent_step(
                agent_runner,
                "Test parallel execution: call fast_echo with message 'Speed test!' and slow_echo with message 'Thorough test!' - you MUST use both tools",
                { tool_choice = "required" } -- Force tool calling
            )

            -- Verify agent made tool calls
            expect(execution.result).not_to_be_nil()
            expect(execution.result.tool_calls).not_to_be_nil()
            expect(#execution.result.tool_calls).to_equal(2)

            print(string.format("SUCCESS: Agent made %d tool calls as expected", #execution.result.tool_calls))

            -- Extract and verify tool calls
            local tool_calls = execution.result.tool_calls
            local fast_call = nil
            local slow_call = nil

            for _, call in ipairs(tool_calls) do
                if call.name == "fast_echo" then
                    fast_call = call
                elseif call.name == "slow_echo" then
                    slow_call = call
                end
            end

            expect(fast_call).not_to_be_nil()
            expect(slow_call).not_to_be_nil()

            -- Verify tool call properties
            expect(fast_call.registry_id).to_equal("wippy.agent.tools:delay_tool")
            expect(slow_call.registry_id).to_equal("wippy.agent.tools:delay_tool")

            print("Tool calls have correct registry IDs")

            -- Verify contexts are already attached by agent
            expect(fast_call.context).not_to_be_nil()
            expect(slow_call.context).not_to_be_nil()

            print("Tool contexts already attached by agent automatically")

            -- Execute tools in parallel using tool caller
            local tool_execution = test_helpers.execute_tools_with_caller(
                tool_calls,
                {
                    agent_id = compiled_spec.id,
                    test_run = "parallel_alias_integration",
                    execution_strategy = "parallel"
                },
                "PARALLEL"
            )

            expect(tool_execution).not_to_be_nil()
            expect(tool_execution.results).not_to_be_nil()

            -- Find results by matching tool names (using LLM call IDs as keys)
            local fast_result = nil
            local slow_result = nil

            for call_id, result in pairs(tool_execution.results) do
                local validated_tool = tool_execution.validated_tools[call_id]
                if validated_tool and validated_tool.name == "fast_echo" then
                    fast_result = result
                elseif validated_tool and validated_tool.name == "slow_echo" then
                    slow_result = result
                end
            end

            -- Assert both tool calls succeeded with correct delay from context
            test_helpers.assert_tool_result(fast_result, "Speed test!", 25, "fast_echo")
            test_helpers.assert_tool_result(slow_result, "Thorough test!", 80, "slow_echo")

            -- Verify parallel execution timing
            -- Should be closer to max delay (80ms) rather than sum (105ms)
            expect(tool_execution.duration_ms < 150).to_be_true()     -- Allow overhead
            expect(tool_execution.duration_ms).to_be_greater_than(60) -- Should be at least close to max delay

            print(string.format("Parallel execution timing verified: %dms (expected ~80ms)",
                tool_execution.duration_ms))

            -- Verify contexts were properly merged and received
            local fast_context = fast_result.result.context_received
            local slow_context = slow_result.result.context_received

            -- Check fast_echo context
            expect(fast_context.service_type).to_equal("fast_response")
            expect(fast_context.priority).to_equal("high")
            expect(fast_context.agent_id).to_equal(compiled_spec.id)
            expect(fast_context.test_run).to_equal("parallel_alias_integration")

            -- Check slow_echo context
            expect(slow_context.service_type).to_equal("thorough_processing")
            expect(slow_context.priority).to_equal("normal")
            expect(slow_context.agent_id).to_equal(compiled_spec.id)
            expect(slow_context.test_run).to_equal("parallel_alias_integration")

            print("Tool contexts properly merged and received")

            -- Verify token usage tracking
            expect(execution.agent_stats.total_tokens.total).to_be_greater_than(0)
            print(string.format("Token usage: %d total tokens",
                execution.agent_stats.total_tokens.total))

            print("FULL CHAIN INTEGRATION TEST COMPLETED SUCCESSFULLY!")
        end)

        it("should handle context precedence through full compilation chain", function()
            print("\n" .. string.rep("-", 50))
            print("TEST: Context Precedence Through Full Chain")
            print(string.rep("-", 50))

            -- Create raw spec with context that should be overridden
            local raw_spec = {
                id = "context-precedence-agent",
                name = "Context Precedence Test Agent",
                model = "class:test-model",  -- Updated to use test model
                prompt = "You are a context testing agent.",
                tools = {
                    {
                        id = "wippy.agent.tools:delay_tool",
                        alias = "context_test_tool",
                        description = "Tool for testing context precedence rules",
                        context = {
                            shared_key = "from_tool_context",
                            tool_only_key = "tool_value",
                            default_delay = 30
                        }
                    }
                },
                memory = {},
                delegates = {},
                context = {
                    agent_level_key = "agent_value"
                }
            }

            -- Compile and create agent
            local agent_runner, compiled_spec = test_helpers.compile_and_create_agent(raw_spec)

            -- Execute agent to get tool calls with automatic context attachment
            local execution = test_helpers.execute_agent_step(
                agent_runner,
                "Please call context_test_tool with message 'Context precedence test' and delay 40ms",
                { tool_choice = "required" } -- Force tool calling
            )

            expect(execution.result.tool_calls).not_to_be_nil()
            expect(#execution.result.tool_calls).to_equal(1)

            local tool_calls = execution.result.tool_calls
            expect(tool_calls[1].context).not_to_be_nil()

            print("Tool call has context automatically attached by agent")

            local context = {
                shared_key = "from_context", -- Should override tool context
                session_only_key = "session_value",
                test_scenario = "context_precedence"
            }

            local tool_execution = test_helpers.execute_tools_with_caller(
                tool_calls,
                context,
                "SEQUENTIAL"
            )

            expect(tool_execution.results).not_to_be_nil()

            local result = nil
            for _, res in pairs(tool_execution.results) do
                result = res
                break
            end

            test_helpers.assert_tool_result(result, "Context precedence test", 40, "context_test_tool")

            -- Verify context precedence: session > tool context
            local context = result.result.context_received
            expect(context.shared_key).to_equal("from_context") -- Session wins
            expect(context.tool_only_key).to_equal("tool_value")        -- Tool context preserved
            expect(context.session_only_key).to_equal("session_value")  -- Session context preserved
            expect(context.test_scenario).to_equal("context_precedence")

            print("Context precedence verified: session overrides tool context")
        end)

        it("should test different tool caller strategies with full LLM chain", function()
            print("\n" .. string.rep("-", 50))
            print("TEST: Tool Caller Strategies Comparison - Full LLM Chain")
            print(string.rep("-", 50))

            -- Create agent spec for strategy testing
            local raw_spec = test_helpers.create_strategy_test_agent_spec()

            -- Compile and create agent
            local agent_runner, compiled_spec = test_helpers.compile_and_create_agent(raw_spec)

            -- Execute agent to get real LLM-generated tool calls
            local execution = test_helpers.execute_agent_step(
                agent_runner,
                "Please call test_tool_1 with message 'Sequential test 1' and delay 30ms, test_tool_2 with message 'Sequential test 2' and delay 25ms, and test_tool_3 with message 'Sequential test 3' and delay 35ms - you MUST use all three tools",
                { tool_choice = "required" } -- Force tool calling
            )

            -- Verify agent made tool calls
            expect(execution.result).not_to_be_nil()
            expect(execution.result.tool_calls).not_to_be_nil()
            expect(#execution.result.tool_calls).to_equal(3)

            print(string.format("SUCCESS: Agent made %d tool calls as expected", #execution.result.tool_calls))

            -- Tool calls should already have contexts attached
            local tool_calls = execution.result.tool_calls
            for _, tool_call in ipairs(tool_calls) do
                expect(tool_call.context).not_to_be_nil()
                print(string.format("Tool %s has context automatically attached", tool_call.name))
            end

            local context = { strategy_test = "comparison" }

            -- Test sequential execution
            print("\nTesting SEQUENTIAL strategy:")
            local seq_execution = test_helpers.execute_tools_with_caller(
                tool_calls,
                context,
                "SEQUENTIAL"
            )

            expect(seq_execution.results).not_to_be_nil()
            expect(test_helpers.count_table(seq_execution.results)).to_equal(3)

            -- Sequential should take sum of delays (~90ms)
            expect(seq_execution.duration_ms).to_be_greater_than(80)
            print(string.format("Sequential execution: %dms (expected ~90ms)", seq_execution.duration_ms))

            -- Test parallel execution with same tool calls
            print("\nTesting PARALLEL strategy:")
            local par_execution = test_helpers.execute_tools_with_caller(
                tool_calls,
                context,
                "PARALLEL"
            )

            expect(par_execution.results).not_to_be_nil()
            expect(test_helpers.count_table(par_execution.results)).to_equal(3)

            -- Parallel should take max delay (~35ms)
            expect(par_execution.duration_ms < 80).to_be_true()
            expect(par_execution.duration_ms).to_be_greater_than(25)
            print(string.format("Parallel execution: %dms (expected ~35ms)", par_execution.duration_ms))

            -- Verify parallel is significantly faster
            local speedup = seq_execution.duration_ms / par_execution.duration_ms
            print(string.format("Parallel speedup: %.2fx faster", speedup))
            expect(speedup).to_be_greater_than(1.5) -- Should be at least 1.5x faster

            print("Tool caller strategy comparison completed successfully")
        end)
    end)
end

return require("test").run_cases(define_integration_tests)