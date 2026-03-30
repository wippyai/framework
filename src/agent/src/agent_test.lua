local agent = require("agent")
local prompt = require("prompt")
local llm = require("llm")
local json = require("json")
local env = require("env")
local time = require("time")

local function define_tests()
    describe("Agent Runner with Tool Context Support and Memory Contracts", function()
        local mock_llm
        local mock_prompt
        local mock_contract

        -- Updated compiled agent specs using unified tool structure
        local basic_compiled_spec = {
            id = "basic-agent",
            name = "Basic Agent",
            description = "A basic test agent",
            model = "gpt-4o-mini",
            max_tokens = 4096,
            temperature = 0.7,
            thinking_effort = 0,
            prompt = "You are a helpful test agent.",
            tools = {
                calculator = {
                    name = "calculator",
                    description = "Perform calculations",
                    schema = { type = "object", properties = {} },
                    registry_id = "test:calculator",
                    context = {
                        precision = "high",
                        timeout = 30,
                        agent_id = "basic-agent"
                    }
                },
                weather = {
                    name = "weather",
                    description = "Get weather information",
                    schema = { type = "object", properties = {} },
                    registry_id = "test:weather",
                    context = {
                        api_key = "test_key",
                        units = "celsius",
                        agent_id = "basic-agent"
                    }
                }
            },
            memory = { "You are designed for testing" },
            memory_contract = nil,
            prompt_funcs = {},
            step_funcs = {}
        }

        local compiled_spec_with_aliases = {
            id = "alias-agent",
            name = "Agent With Aliases",
            description = "Agent that uses tool aliases",
            model = "gpt-4o-mini",
            prompt = "You are an agent with aliased tools.",
            tools = {
                fast_echo = {
                    name = "fast_echo",
                    description = "Fast echo tool",
                    schema = { type = "object", properties = {} },
                    registry_id = "wippy.agent.tools:delay_tool",
                    context = {
                        delay = 25,
                        priority = "high",
                        agent_id = "alias-agent"
                    }
                },
                slow_echo = {
                    name = "slow_echo",
                    description = "Slow echo tool",
                    schema = { type = "object", properties = {} },
                    registry_id = "wippy.agent.tools:delay_tool",
                    context = {
                        delay = 80,
                        priority = "low",
                        agent_id = "alias-agent"
                    }
                }
            },
            memory = {},
            memory_contract = nil,
            prompt_funcs = {},
            step_funcs = {}
        }

        local compiled_spec_with_delegates = {
            id = "delegate-agent",
            name = "Agent With Delegates",
            description = "Agent that can delegate tasks",
            model = "gpt-4o-mini",
            prompt = "You are a coordinator agent that delegates tasks.",
            tools = {
                calculator = {
                    name = "calculator",
                    description = "Perform calculations",
                    schema = { type = "object", properties = {} },
                    registry_id = "test:calculator",
                    context = {
                        precision = "standard",
                        agent_id = "delegate-agent"
                    }
                },
                to_data_specialist = {
                    name = "to_data_specialist",
                    description = "Forward the request to when handling data analysis, this is exit tool, you can not call anything else with it.",
                    schema = {
                        type = "object",
                        properties = {
                            message = {
                                type = "string",
                                description = "The message to forward to the agent"
                            }
                        },
                        required = { "message" }
                    },
                    agent_id = "specialist:data", -- This makes it a delegate tool
                    context = {
                        agent_id = "delegate-agent"
                    }
                }
            },
            memory = {},
            memory_contract = nil,
            prompt_funcs = {},
            step_funcs = {}
        }

        local compiled_spec_with_tool_schemas = {
            id = "schema-agent",
            name = "Agent With Tool Schemas",
            description = "Agent with custom tool schemas from traits",
            model = "gpt-4o-mini",
            prompt = "You are an agent with custom API tools.",
            tools = {
                api_client = {
                    name = "api_client",
                    description = "Call external API",
                    schema = {
                        type = "object",
                        properties = {
                            method = {
                                type = "string",
                                enum = { "GET", "POST", "PUT", "DELETE" }
                            },
                            path = {
                                type = "string",
                                description = "API endpoint path"
                            },
                            data = {
                                type = "object",
                                description = "Request payload"
                            }
                        },
                        required = { "method", "path" }
                    },
                    registry_id = "custom:api_client",
                    context = {
                        endpoint = "https://api.example.com",
                        timeout = 60,
                        agent_id = "schema-agent"
                    }
                }
            },
            memory = {},
            memory_contract = nil,
            prompt_funcs = {},
            step_funcs = {}
        }

        local compiled_spec_with_memory = {
            id = "memory-agent",
            name = "Agent With Memory Contract",
            description = "Agent that uses memory recall",
            model = "gpt-4o-mini",
            prompt = "You are an agent with memory capabilities.",
            tools = {
                calculator = {
                    name = "calculator",
                    description = "Perform calculations",
                    schema = { type = "object", properties = {} },
                    registry_id = "test:calculator",
                    context = {
                        precision = "high",
                        agent_id = "memory-agent"
                    }
                }
            },
            memory = {},
            memory_contract = {
                implementation_id = "test.memory:vector_impl",
                context = {
                    memory_type = "vector",
                    collection_name = "test_memories"
                },
                options = {
                    max_items = 5,
                    max_length = 2000,
                    enabled = true,
                    min_conversation_length = 3,
                    recall_cooldown = 2
                }
            },
            prompt_funcs = {},
            step_funcs = {}
        }

        before_each(function()
            mock_llm = {
                generate = function(messages, options)
                    -- Find the last USER message, not just the last message
                    local user_text = ""
                    for i = #messages, 1, -1 do
                        local msg = messages[i]
                        if msg.role == "user" and msg.content and msg.content[1] and msg.content[1].text then
                            user_text = msg.content[1].text:lower()
                            break
                        end
                    end

                    print("Mock LLM received: '" .. user_text .. "'")

                    -- Check for specific test patterns in order (using canonical names)
                    if user_text:find("weather") and user_text:find("calculate") then
                        print("Matched weather + calculate pattern")
                        return {
                            result = "I'll get the weather and do the calculation.",
                            tool_calls = {
                                {
                                    id = "call_weather_456",
                                    name = "weather", -- Canonical name
                                    arguments = { location = "New York" },
                                    registry_id = "test:weather"
                                },
                                {
                                    id = "call_calc_789",
                                    name = "calculator", -- Canonical name
                                    arguments = { expression = "10 * 5" },
                                    registry_id = "test:calculator"
                                }
                            },
                            tokens = { prompt_tokens = 20, completion_tokens = 15, total_tokens = 35 },
                            finish_reason = "tool_call"
                        }
                    elseif user_text:find("fast") and user_text:find("slow") then
                        print("Matched fast + slow alias pattern")
                        return {
                            result = "I'll use both echo tools.",
                            tool_calls = {
                                {
                                    id = "call_fast_123",
                                    name = "fast_echo", -- Alias name matches context key
                                    arguments = { message = "fast test" },
                                    registry_id = "wippy.agent.tools:delay_tool"
                                },
                                {
                                    id = "call_slow_456",
                                    name = "slow_echo", -- Alias name matches context key
                                    arguments = { message = "slow test" },
                                    registry_id = "wippy.agent.tools:delay_tool"
                                }
                            },
                            tokens = { prompt_tokens = 25, completion_tokens = 20, total_tokens = 45 },
                            finish_reason = "tool_call"
                        }
                    elseif user_text:find("calculate") or user_text:find("%d+ %+ %d+") or user_text:find("math") then
                        print("Matched calculate only pattern")
                        return {
                            result = "I'll calculate that for you.",
                            tool_calls = {
                                {
                                    id = "call_calc_123",
                                    name = "calculator", -- Canonical name
                                    arguments = { expression = "2 + 2" },
                                    registry_id = "test:calculator"
                                }
                            },
                            tokens = { prompt_tokens = 15, completion_tokens = 10, total_tokens = 25 },
                            finish_reason = "tool_call"
                        }
                    elseif user_text:find("no context") then
                        print("Matched no context pattern")
                        return {
                            result = "I'll use the tool with no context.",
                            tool_calls = {
                                {
                                    id = "call_no_ctx_999",
                                    name = "no_context", -- Canonical name
                                    arguments = { data = "test" },
                                    registry_id = "test:no_context"
                                }
                            },
                            tokens = { prompt_tokens = 12, completion_tokens = 8, total_tokens = 20 },
                            finish_reason = "tool_call"
                        }
                    elseif user_text:find("api") then
                        print("Matched API pattern")
                        return {
                            result = "I'll call the API for you.",
                            tool_calls = {
                                {
                                    id = "call_api_456",
                                    name = "api_client", -- Canonical name
                                    arguments = { method = "GET", path = "/users", data = {} },
                                    registry_id = "custom:api_client"
                                }
                            },
                            tokens = { prompt_tokens = 20, completion_tokens = 15, total_tokens = 35 },
                            finish_reason = "tool_call"
                        }
                    elseif user_text:find("analyz") then
                        print("Matched analyze pattern")
                        return {
                            result = "I'll delegate this to our data specialist.",
                            tool_calls = {
                                {
                                    id = "call_delegate_789",
                                    name = "to_data_specialist", -- Delegate tool name
                                    arguments = { message = "Please analyze this dataset" },
                                    registry_id = "to_data_specialist"
                                }
                            },
                            tokens = { prompt_tokens = 25, completion_tokens = 20, total_tokens = 45 },
                            finish_reason = "tool_call"
                        }
                    elseif user_text:find("memory") then
                        print("Matched memory pattern")
                        return {
                            result = "I remember working on similar problems.",
                            tokens = { prompt_tokens = 30, completion_tokens = 10, total_tokens = 40 },
                            finish_reason = "stop"
                        }
                    else
                        print("No pattern matched, returning default")
                        return {
                            result = "This is a test response.",
                            tokens = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 },
                            finish_reason = "stop"
                        }
                    end
                end
            }

            mock_prompt = {
                new = function()
                    local messages = {}
                    return {
                        add_user = function(self, content)
                            table.insert(messages, {
                                role = "user",
                                content = { { type = "text", text = content } }
                            })
                            return self
                        end,
                        add_assistant = function(self, content)
                            table.insert(messages, {
                                role = "assistant",
                                content = { { type = "text", text = content } }
                            })
                            return self
                        end,
                        add_developer = function(self, content, meta)
                            table.insert(messages, {
                                role = "developer",
                                content = content,
                                meta = meta
                            })
                            return self
                        end,
                        add_function_call = function(self, name, arguments, id)
                            table.insert(messages, {
                                role = "function",
                                name = name,
                                content = arguments,
                                function_call_id = id
                            })
                            return self
                        end,
                        add_function_result = function(self, name, result, id)
                            local content = type(result) == "string" and result or json.encode(result)
                            table.insert(messages, {
                                role = "function",
                                name = name,
                                content = { { type = "text", text = content } },
                                function_call_id = id
                            })
                            return self
                        end,
                        get_messages = function()
                            return messages
                        end,
                        clone = function()
                            local cloned_messages = {}
                            for i, msg in ipairs(messages) do
                                cloned_messages[i] = msg
                            end
                            return {
                                add_user = function(self, content)
                                    table.insert(cloned_messages, {
                                        role = "user",
                                        content = { { type = "text", text = content } }
                                    })
                                    return self
                                end,
                                add_assistant = function(self, content)
                                    table.insert(cloned_messages, {
                                        role = "assistant",
                                        content = { { type = "text", text = content } }
                                    })
                                    return self
                                end,
                                add_developer = function(self, content, meta)
                                    table.insert(cloned_messages, {
                                        role = "developer",
                                        content = content,
                                        meta = meta
                                    })
                                    return self
                                end,
                                add_system = function(self, content)
                                    table.insert(cloned_messages, {
                                        role = "system",
                                        content = content
                                    })
                                    return self
                                end,
                                get_messages = function()
                                    return cloned_messages
                                end
                            }
                        end
                    }
                end
            }

            mock_contract = {
                get = function(contract_id)
                    if contract_id == "wippy.agent:memory" then
                        return {
                            open = function(self, implementation_id, context)
                                if implementation_id == "test.memory:vector_impl" then
                                    return {
                                        recall = function(self, options)
                                            -- Mock memory recall behavior
                                            local recent_actions = options.recent_actions or {}
                                            local previous_memories = options.previous_memories or {}
                                            local constraints = options.constraints or {}

                                            -- Simulate memory recall based on recent actions
                                            local memories = {}

                                            for _, action in ipairs(recent_actions) do
                                                if action:find("calculate") or action:find("math") then
                                                    table.insert(memories, {
                                                        id = "mem_calc_" .. #memories + 1,
                                                        content = "Previously helped with similar calculations",
                                                        metadata = { type = "calculation", source = "conversation" }
                                                    })
                                                elseif action:find("weather") then
                                                    table.insert(memories, {
                                                        id = "mem_weather_" .. #memories + 1,
                                                        content = "User often asks about weather in New York",
                                                        metadata = { type = "preference", source = "pattern" }
                                                    })
                                                end
                                            end

                                            -- Limit by constraints
                                            local max_items = constraints.max_items or 3
                                            if #memories > max_items then
                                                local limited = {}
                                                for i = 1, max_items do
                                                    limited[i] = memories[i]
                                                end
                                                memories = limited
                                            end

                                            return {
                                                memories = memories
                                            }
                                        end
                                    }
                                else
                                    return nil, "Unknown memory implementation: " .. tostring(implementation_id)
                                end
                            end
                        }
                    else
                        return nil, "Unknown contract: " .. tostring(contract_id)
                    end
                end
            }

            agent._llm = mock_llm
            agent._prompt = mock_prompt
            agent._contract = mock_contract
        end)

        after_each(function()
            agent._llm = nil
            agent._prompt = nil
            agent._contract = nil
        end)

        describe("Agent Construction", function()
            it("should create agent from compiled specification", function()
                local test_agent = agent.new(basic_compiled_spec)

                test.not_nil(test_agent)
                test.eq(test_agent.id, "basic-agent")
                test.eq(test_agent.name, "Basic Agent")
                test.eq(test_agent.model, "gpt-4o-mini")
                -- Updated expectation: memory items are automatically appended to system prompt
                test.eq(test_agent.system_prompt, "You are a helpful test agent.\n\n## Your memory contains:\n- You are designed for testing")
                test.not_nil(test_agent.tools["calculator"])
                test.not_nil(test_agent.tools["weather"])
                test.eq(test_agent.total_tokens.total, 0)
            end)

            it("should handle nil compiled spec", function()
                local test_agent, err = agent.new(nil)

                test.is_nil(test_agent)
                test.eq(err, "Compiled spec is required")
            end)

            it("should use default values for missing fields", function()
                local minimal_spec = {
                    id = "minimal-agent",
                    name = "Minimal Agent",
                    description = "A minimal agent",
                    prompt = "You are minimal."
                }

                local test_agent = agent.new(minimal_spec)

                test.not_nil(test_agent)
                test.eq(test_agent.model, "")
                test.eq(test_agent.max_tokens, 512)
                test.eq(test_agent.temperature, 0)
                test.eq(test_agent.thinking_effort, 0)
                test.is_nil(next(test_agent.tools)) -- Empty tools table
            end)
        end)

        describe("Tool Context Handling - Canonical Names", function()
            it("should automatically attach contexts to tool calls with canonical names", function()
                local test_agent = agent.new(basic_compiled_spec)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("Please calculate 2 + 2")
                local result = test_agent:step(prompt_builder)

                test.not_nil(result.tool_calls)
                test.eq(#result.tool_calls, 1)

                local tool_call = result.tool_calls[1]
                test.eq(tool_call.id, "call_calc_123")
                test.eq(tool_call.name, "calculator") -- Canonical name
                test.eq(tool_call.registry_id, "test:calculator")

                -- Context should be automatically attached
                test.not_nil(tool_call.context)
                test.eq(tool_call.context.precision, "high")
                test.eq(tool_call.context.timeout, 30)
            end)

            it("should handle multiple tool calls with different contexts", function()
                local test_agent = agent.new(basic_compiled_spec)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("Get weather and calculate 10 * 5")
                local result = test_agent:step(prompt_builder)

                test.not_nil(result.tool_calls)
                test.eq(#result.tool_calls, 2)

                local weather_call = result.tool_calls[1]
                local calc_call = result.tool_calls[2]

                -- Both should have contexts attached
                test.not_nil(weather_call.context)
                test.eq(weather_call.context.api_key, "test_key")
                test.eq(weather_call.context.units, "celsius")

                test.not_nil(calc_call.context)
                test.eq(calc_call.context.precision, "high")
                test.eq(calc_call.context.timeout, 30)
            end)

            it("should handle tools with no context gracefully", function()
                local test_agent = agent.new(basic_compiled_spec)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("Use tool with no context")
                local result = test_agent:step(prompt_builder)

                test.not_nil(result.tool_calls)
                test.eq(#result.tool_calls, 1)

                local tool_call = result.tool_calls[1]
                test.is_nil(tool_call.context) -- No context available for this tool
            end)

            it("should handle custom schema tool calls with contexts", function()
                local test_agent = agent.new(compiled_spec_with_tool_schemas)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("Please call the API to get user data")
                local result = test_agent:step(prompt_builder)

                test.not_nil(result.tool_calls)
                test.eq(#result.tool_calls, 1)

                local tool_call = result.tool_calls[1]
                test.eq(tool_call.name, "api_client") -- Canonical name
                test.eq(tool_call.registry_id, "custom:api_client")

                -- Context should be attached
                test.not_nil(tool_call.context)
                test.eq(tool_call.context.endpoint, "https://api.example.com")
                test.eq(tool_call.context.timeout, 60)
            end)
        end)

        describe("Tool Context Handling - Aliases", function()
            it("should automatically attach contexts to aliased tool calls", function()
                local test_agent = agent.new(compiled_spec_with_aliases)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("Use both fast and slow echo tools")
                local result = test_agent:step(prompt_builder)

                test.not_nil(result.tool_calls)
                test.eq(#result.tool_calls, 2)

                local fast_call = result.tool_calls[1]
                local slow_call = result.tool_calls[2]

                -- Verify fast_echo context
                test.eq(fast_call.name, "fast_echo")
                test.eq(fast_call.registry_id, "wippy.agent.tools:delay_tool")
                test.not_nil(fast_call.context)
                test.eq(fast_call.context.delay, 25)
                test.eq(fast_call.context.priority, "high")

                -- Verify slow_echo context
                test.eq(slow_call.name, "slow_echo")
                test.eq(slow_call.registry_id, "wippy.agent.tools:delay_tool")
                test.not_nil(slow_call.context)
                test.eq(slow_call.context.delay, 80)
                test.eq(slow_call.context.priority, "low")
            end)

            it("should handle same registry ID with different aliases correctly", function()
                local test_agent = agent.new(compiled_spec_with_aliases)

                -- Updated: Access contexts via unified tools table
                test.not_nil(test_agent.tools["fast_echo"])
                test.not_nil(test_agent.tools["slow_echo"])
                test.eq(test_agent.tools["fast_echo"].context.delay, 25)
                test.eq(test_agent.tools["slow_echo"].context.delay, 80)
            end)
        end)

        describe("Delegate Handling", function()
            it("should handle delegate calls correctly", function()
                local test_agent = agent.new(compiled_spec_with_delegates)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("Please analyze this sales data for trends")
                local result = test_agent:step(prompt_builder)

                -- Updated expectation: should use delegate_calls array
                test.not_nil(result.delegate_calls)
                test.eq(#result.delegate_calls, 1)
                test.eq(result.delegate_calls[1].agent_id, "specialist:data")
                test.eq(result.delegate_calls[1].name, "to_data_specialist")
                test.is_nil(result.tool_calls) -- Tool calls should be cleared for delegates
            end)

            it("should preserve tool calls when no delegates are triggered", function()
                local test_agent = agent.new(compiled_spec_with_delegates)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("Please calculate 2 + 2")
                local result = test_agent:step(prompt_builder)

                test.not_nil(result.tool_calls)
                test.eq(#result.tool_calls, 1)
                test.is_nil(result.delegate_calls)
            end)
        end)

        describe("Memory Contract Integration", function()
            it("should perform memory recall when conditions are met", function()
                local test_agent = agent.new(compiled_spec_with_memory)
                local prompt_builder = mock_prompt.new()

                -- Add enough messages to trigger recall (min_conversation_length = 3)
                prompt_builder:add_user("Hello")
                prompt_builder:add_assistant("Hi there!")
                prompt_builder:add_user("Can you help me calculate something?")
                prompt_builder:add_assistant("Of course!")
                prompt_builder:add_user("What's 2 + 2?")

                local result = test_agent:step(prompt_builder)

                test.not_nil(result)
                test.not_nil(result.memory_recall)
                test.not_nil(result.memory_recall.memory_ids)
                test.gt(result.memory_recall.count, 0)
                test.not_nil(result.memory_prompt)
            end)

            it("should skip memory recall when conversation is too short", function()
                local test_agent = agent.new(compiled_spec_with_memory)
                local prompt_builder = mock_prompt.new()

                -- Only one message - below min_conversation_length
                prompt_builder:add_user("Hello")

                local result = test_agent:step(prompt_builder)

                test.not_nil(result)
                test.is_nil(result.memory_recall)
                test.is_nil(result.memory_prompt)
            end)

            it("should skip memory recall when disabled", function()
                local test_agent = agent.new(compiled_spec_with_memory)
                local prompt_builder = mock_prompt.new()

                -- Add enough messages to normally trigger recall
                prompt_builder:add_user("Hello")
                prompt_builder:add_assistant("Hi there!")
                prompt_builder:add_user("Can you help me calculate something?")
                prompt_builder:add_assistant("Of course!")
                prompt_builder:add_user("What's 2 + 2?")

                -- Disable memory recall via runtime options
                local result = test_agent:step(prompt_builder, { disable_memory_recall = true })

                test.not_nil(result)
                test.is_nil(result.memory_recall)
                test.is_nil(result.memory_prompt)
            end)

            it("should handle memory contract errors gracefully", function()
                local bad_memory_spec = {
                    id = "bad-memory-agent",
                    name = "Bad Memory Agent",
                    prompt = "I have bad memory config.",
                    tools = {},
                    memory_contract = {
                        implementation_id = "nonexistent:memory",
                        context = {}
                    }
                }

                local test_agent = agent.new(bad_memory_spec)
                local prompt_builder = mock_prompt.new()

                -- Add messages to trigger recall
                prompt_builder:add_user("Hello")
                prompt_builder:add_assistant("Hi!")
                prompt_builder:add_user("Test memory")

                -- Should not fail, just skip memory recall
                local result = test_agent:step(prompt_builder)

                test.not_nil(result)
                test.is_nil(result.memory_recall)
            end)

            it("should respect memory recall cooldown", function()
                local test_agent = agent.new(compiled_spec_with_memory)
                local prompt_builder = mock_prompt.new()

                -- Build conversation with previous memory recall
                prompt_builder:add_user("Hello")
                prompt_builder:add_assistant("Hi there!")
                prompt_builder:add_user("Previous question")
                prompt_builder:add_assistant("Previous answer")

                -- Add a developer message with memory metadata (simulating previous recall)
                prompt_builder:add_developer("Previous memory recall", { memory_ids = { "mem_1", "mem_2" } })

                -- Add only one more message (cooldown = 2, so should not trigger)
                prompt_builder:add_user("New question")

                local result = test_agent:step(prompt_builder)

                test.not_nil(result)
                test.is_nil(result.memory_recall) -- Should not recall due to cooldown
            end)

            it("should handle agents without memory contracts", function()
                local test_agent = agent.new(basic_compiled_spec) -- No memory contract
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("Hello")
                prompt_builder:add_assistant("Hi!")
                prompt_builder:add_user("Test without memory")

                local result = test_agent:step(prompt_builder)

                test.not_nil(result)
                test.is_nil(result.memory_recall)
                test.is_nil(result.memory_prompt)
            end)

            it("should include session context in memory recall", function()
                local test_agent = agent.new(compiled_spec_with_memory)
                local prompt_builder = mock_prompt.new()

                -- Add enough messages to trigger recall
                prompt_builder:add_user("Hello")
                prompt_builder:add_assistant("Hi there!")
                prompt_builder:add_user("Can you help me calculate something?")
                prompt_builder:add_assistant("Of course!")
                prompt_builder:add_user("What's 2 + 2?")

                -- Pass session context via runtime options
                local result = test_agent:step(prompt_builder, {
                    context = {
                        user_id = "test_user_123",
                        session_id = "session_456"
                    }
                })

                test.not_nil(result)
                -- Memory recall should work and use the session context internally
                if result.memory_recall then
                    test.not_nil(result.memory_recall.memory_ids)
                end
            end)
        end)

        describe("Token Usage Tracking", function()
            it("should track token usage correctly", function()
                local test_agent = agent.new(basic_compiled_spec)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("Please calculate 2 + 2")
                local result = test_agent:step(prompt_builder)

                test.eq(test_agent.total_tokens.total, 25)
                test.eq(test_agent.total_tokens.prompt, 15)
                test.eq(test_agent.total_tokens.completion, 10)
                test.eq(test_agent.total_tokens.thinking, 0)
            end)

            it("should accumulate token usage across multiple steps", function()
                local test_agent = agent.new(basic_compiled_spec)
                local prompt_builder = mock_prompt.new()

                -- First step
                prompt_builder:add_user("Please calculate 2 + 2")
                test_agent:step(prompt_builder)

                test.eq(test_agent.total_tokens.total, 25)

                -- Second step
                prompt_builder:add_user("What about 3 + 3?")
                test_agent:step(prompt_builder)

                test.eq(test_agent.total_tokens.total, 50) -- Should accumulate
            end)

            it("should provide agent statistics", function()
                local test_agent = agent.new(basic_compiled_spec)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("Test message")
                test_agent:step(prompt_builder)

                local stats = test_agent:get_stats()
                test.not_nil(stats)
                test.eq(stats.id, "basic-agent")
                test.eq(stats.name, "Basic Agent")
                test.not_nil(stats.total_tokens)
                test.gt(stats.total_tokens.total, 0)
            end)
        end)

        describe("Tool Schema Usage", function()
            it("should always use tools array for LLM", function()
                -- Mock LLM that captures the options passed to it
                local captured_options = nil
                local schema_mock_llm = {
                    generate = function(messages, options)
                        captured_options = options
                        return {
                            result = "Tool schema response",
                            tokens = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 },
                            finish_reason = "stop"
                        }
                    end
                }

                -- Inject mock LLM
                agent._llm = schema_mock_llm

                local test_agent = agent.new(basic_compiled_spec)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("Test tool schemas")
                test_agent:step(prompt_builder)

                -- Updated expectation: should use tools array
                test.not_nil(captured_options)
                local opts = captured_options :: any
                test.not_nil(opts.tools) -- Should be array format
                test.eq(#opts.tools, 2)

                -- Check that tools are in array format with proper structure
                local found_calculator = false
                local found_weather = false
                for _, tool in ipairs(opts.tools) do
                    if tool.name == "calculator" then
                        found_calculator = true
                        test.eq(tool.registry_id, "test:calculator")
                    elseif tool.name == "weather" then
                        found_weather = true
                        test.eq(tool.registry_id, "test:weather")
                    end
                end
                test.is_true(found_calculator)
                test.is_true(found_weather)

                -- Cleanup
                agent._llm = nil
            end)

            it("should use tools array for alias tools", function()
                -- Mock LLM that captures the options passed to it
                local captured_options = nil
                local aliases_mock_llm = {
                    generate = function(messages, options)
                        captured_options = options
                        return {
                            result = "Alias tools response",
                            tokens = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 },
                            finish_reason = "stop"
                        }
                    end
                }

                -- Inject mock LLM
                agent._llm = aliases_mock_llm

                local test_agent = agent.new(compiled_spec_with_aliases)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("Test aliases")
                test_agent:step(prompt_builder)

                -- Updated expectation: should use tools array
                test.not_nil(captured_options)
                local opts = captured_options :: any
                test.not_nil(opts.tools)
                test.eq(#opts.tools, 2)

                local found_fast = false
                local found_slow = false
                for _, tool in ipairs(opts.tools) do
                    if tool.name == "fast_echo" then
                        found_fast = true
                        test.eq(tool.registry_id, "wippy.agent.tools:delay_tool")
                    elseif tool.name == "slow_echo" then
                        found_slow = true
                        test.eq(tool.registry_id, "wippy.agent.tools:delay_tool")
                    end
                end
                test.is_true(found_fast)
                test.is_true(found_slow)

                -- Cleanup
                agent._llm = nil
            end)

            it("should handle empty tool schemas gracefully", function()
                local empty_spec = {
                    id = "empty-agent",
                    name = "Empty Agent",
                    prompt = "I have no tools.",
                    tools = {}
                }

                local captured_options = nil
                local empty_mock_llm = {
                    generate = function(messages, options)
                        captured_options = options
                        return {
                            result = "No tools response",
                            tokens = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 },
                            finish_reason = "stop"
                        }
                    end
                }

                agent._llm = empty_mock_llm

                local test_agent = agent.new(empty_spec)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("Test empty tools")
                test_agent:step(prompt_builder)

                -- Verify no tools are sent when there are no tools
                test.not_nil(captured_options)
                local opts = captured_options :: any
                test.is_nil(opts.tools) -- Should be nil when no tools

                agent._llm = nil
            end)
        end)

        describe("Runtime Options Integration", function()
            it("should pass through stream target", function()
                local captured_options = nil
                local stream_mock_llm = {
                    generate = function(messages, options)
                        captured_options = options
                        return {
                            result = "Streamed response",
                            tokens = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 },
                            finish_reason = "stop"
                        }
                    end
                }

                agent._llm = stream_mock_llm

                local test_agent = agent.new(basic_compiled_spec)
                local prompt_builder = mock_prompt.new()
                local mock_stream_target = { write = function() end }

                prompt_builder:add_user("Test streaming")
                test_agent:step(prompt_builder, { stream_target = mock_stream_target })

                test.eq((captured_options :: any).stream, mock_stream_target)

                agent._llm = nil
            end)

            it("should pass through runtime options", function()
                local captured_options = nil
                local runtime_mock_llm = {
                    generate = function(messages, options)
                        captured_options = options
                        return {
                            result = "Runtime options response",
                            tokens = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 },
                            finish_reason = "stop"
                        }
                    end
                }

                agent._llm = runtime_mock_llm

                local test_agent = agent.new(basic_compiled_spec)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("Test runtime options")
                test_agent:step(prompt_builder, { tool_call = "required" })

                -- Updated expectation: tool_call should be mapped to tool_choice
                test.eq((captured_options :: any).tool_choice, "required")

                agent._llm = nil
            end)

            it("should set thinking effort when configured", function()
                local thinking_spec = {
                    id = "thinking-agent",
                    name = "Thinking Agent",
                    model = "gpt-4o-mini",
                    thinking_effort = 75,
                    prompt = "I think deeply.",
                    tools = {}
                }

                local captured_options = nil
                local thinking_mock_llm = {
                    generate = function(messages, options)
                        captured_options = options
                        return {
                            result = "Thoughtful response",
                            tokens = { prompt_tokens = 10, completion_tokens = 5, thinking_tokens = 20, total_tokens = 35 },
                            finish_reason = "stop"
                        }
                    end
                }

                agent._llm = thinking_mock_llm

                local test_agent = agent.new(thinking_spec)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("Think about this")
                local result = test_agent:step(prompt_builder)

                test.eq((captured_options :: any).thinking_effort, 75)
                test.eq(test_agent.total_tokens.thinking, 20)

                agent._llm = nil
            end)

            it("should handle combined runtime options", function()
                local test_agent = agent.new(basic_compiled_spec)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("Test combined options")

                local mock_stream = { write = function() end }
                local runtime_options = {
                    stream_target = mock_stream,
                    context = {
                        user_id = "test_user",
                        session_id = "test_session"
                    },
                    tool_call = "auto",
                    disable_memory_recall = true
                }

                local result = test_agent:step(prompt_builder, runtime_options)

                test.not_nil(result)
                test.not_nil(result.result)
            end)
        end)

        describe("Truncation Handling", function()
            it("should set truncated flag and strip tool_calls when finish_reason is length with tool_calls", function()
                local test_agent = agent.new(basic_compiled_spec)
                local prompt_builder = mock_prompt.new()
                prompt_builder:add_user("Do something complex")

                local truncation_mock_llm = {
                    generate = function(messages, options)
                        return {
                            result = "I will call the tool with a very long...",
                            tool_calls = {
                                {
                                    id = "call_truncated",
                                    name = "calculator",
                                    arguments = {},
                                    registry_id = "test:calculator"
                                }
                            },
                            tokens = { prompt_tokens = 100, completion_tokens = 8000, total_tokens = 8100 },
                            finish_reason = "length"
                        }
                    end
                }
                agent._llm = truncation_mock_llm

                local result = test_agent:step(prompt_builder)
                test.not_nil(result)
                test.is_true(result.truncated)
                test.is_nil(result.tool_calls)
                test.is_nil(result.delegate_calls)

                agent._llm = nil
            end)

            it("should not set truncated flag when finish_reason is tool_call with tool_calls", function()
                local test_agent = agent.new(basic_compiled_spec)
                local prompt_builder = mock_prompt.new()
                prompt_builder:add_user("Calculate something")

                local normal_mock_llm = {
                    generate = function(messages, options)
                        return {
                            result = "I will calculate.",
                            tool_calls = {
                                {
                                    id = "call_normal",
                                    name = "calculator",
                                    arguments = { expression = "2+2" },
                                    registry_id = "test:calculator"
                                }
                            },
                            tokens = { prompt_tokens = 50, completion_tokens = 100, total_tokens = 150 },
                            finish_reason = "tool_call"
                        }
                    end
                }
                agent._llm = normal_mock_llm

                local result = test_agent:step(prompt_builder)
                test.not_nil(result)
                test.is_nil(result.truncated)
                test.not_nil(result.tool_calls)

                agent._llm = nil
            end)

            it("should not set truncated flag when finish_reason is length without tool_calls", function()
                local test_agent = agent.new(basic_compiled_spec)
                local prompt_builder = mock_prompt.new()
                prompt_builder:add_user("Write a long essay")

                local length_no_tools_mock = {
                    generate = function(messages, options)
                        return {
                            result = "This is a long text that got cut off...",
                            tool_calls = {},
                            tokens = { prompt_tokens = 50, completion_tokens = 4096, total_tokens = 4146 },
                            finish_reason = "length"
                        }
                    end
                }
                agent._llm = length_no_tools_mock

                local result = test_agent:step(prompt_builder)
                test.not_nil(result)
                test.is_nil(result.truncated)

                agent._llm = nil
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)