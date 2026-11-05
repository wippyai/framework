local agent = require("agent")
local prompt = require("prompt")
local llm = require("llm")
local json = require("json")
local env = require("env")
local time = require("time")
local output = require("output")
local claude_mapper = require("claude_mapper")

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
            step_funcs = {},
            tool_wrappers = {}
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
                    registry_id = "app:delay_tool",
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
                    registry_id = "app:delay_tool",
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
            step_funcs = {},
            tool_wrappers = {}
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
            step_funcs = {},
            tool_wrappers = {}
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
            step_funcs = {},
            tool_wrappers = {}
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
            step_funcs = {},
            tool_wrappers = {}
        }

        local compiled_spec_with_tool_wrappers = {
            id = "tool-wrapper-agent",
            name = "Tool Wrapper Agent",
            description = "Agent with trait-owned tool wrappers",
            model = "gpt-4o-mini",
            prompt = "You are an agent with tool wrappers.",
            tools = {},
            memory = {},
            memory_contract = nil,
            agent_options = {
                checkpoint = {
                    token_threshold = 16000,
                    function_id = "agent.checkpoint:test"
                }
            },
            prompt_funcs = {},
            step_funcs = {},
            tool_wrappers = {
                {
                    id = "audit_tools",
                    trait_id = "audit_trait",
                    phases = { "before_execute", "after_execute" },
                    binding = "test.wrapper:audit_provider",
                    priority = 20,
                    strict = true,
                    context = {
                        agent_id = "tool-wrapper-agent",
                        trait_id = "audit_trait",
                        policy = "readonly"
                    },
                    options = {
                        max_calls = 4
                    }
                }
            }
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
                                    registry_id = "app:delay_tool"
                                },
                                {
                                    id = "call_slow_456",
                                    name = "slow_echo", -- Alias name matches context key
                                    arguments = { message = "slow test" },
                                    registry_id = "app:delay_tool"
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
            agent._funcs = nil
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
                test.not_nil(test_agent.tool_wrappers)
                test.eq(#test_agent.tool_wrappers, 0)
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
                test.is_nil(test_agent.temperature)
                test.eq(test_agent.thinking_effort, 0)
                test.is_nil(next(test_agent.tools)) -- Empty tools table
                test.not_nil(test_agent.tool_wrappers)
                test.eq(#test_agent.tool_wrappers, 0)
            end)

            it("should carry an explicit temperature through to the model options", function()
                local spec = {
                    id = "explicit-temp-agent",
                    name = "Explicit Temp Agent",
                    description = "Sets its own temperature",
                    prompt = "You are explicit.",
                    temperature = 0.7
                }

                local test_agent = agent.new(spec)
                test.eq(test_agent.temperature, 0.7)

                local seen
                agent._llm = {
                    generate = function(messages, options)
                        seen = options
                        return { result = "done", tokens = {} }
                    end
                }
                test_agent:step(mock_prompt.new())
                test.eq(seen.temperature, 0.7)
            end)

            it("should skip provider generation when stop_check reports a committed stop", function()
                local test_agent = agent.new({
                    id = "stop-check-agent",
                    name = "Stop Check Agent",
                    description = "Checks stop before generation",
                    prompt = "You are stoppable."
                })
                local calls = { generate = 0, checks = 0 }
                agent._llm = {
                    generate = function()
                        calls.generate = calls.generate + 1
                        return { result = "done", tokens = {} }
                    end
                }
                local result, err = test_agent:step(mock_prompt.new(), {
                    stop_check = function() calls.checks = calls.checks + 1; return true end
                })
                test.is_nil(err)
                test.is_true(result.stopped)
                test.eq(calls.generate, 0)
                test.eq(calls.checks, 1)

                result, err = test_agent:step(mock_prompt.new(), { stop_check = function() return false end })
                test.is_nil(err)
                test.is_nil(result.stopped)
                test.eq(calls.generate, 1)
            end)

            it("should cancel the in-flight model call through the host cancel channel", function()
                local test_agent = agent.new({
                    id = "cancel-agent",
                    name = "Cancel Agent",
                    description = "Cancels its model call",
                    prompt = "You are cancellable."
                })
                local cancel = channel.new()
                local seen
                agent._llm = {
                    generate = function(_, options)
                        seen = options
                        return {
                            result = "Partial answer",
                            tool_calls = {},
                            finish_reason = output.FINISH_REASON.CANCELLED,
                            metadata = {}
                        }
                    end
                }

                local result, err = test_agent:step(mock_prompt.new(), { cancel = cancel })

                test.is_nil(err)
                test.eq(seen.cancel, cancel)
                test.is_true(result.stopped)
                test.eq(result.result, "Partial answer")
                test.eq(result.finish_reason, output.FINISH_REASON.CANCELLED)
                test.is_nil(result.tool_calls)
                test.eq(test_agent.total_tokens.total, 0)
            end)

            it("should call the model without cancellation when the host gives no cancel channel", function()
                local test_agent = agent.new({
                    id = "plain-agent",
                    name = "Plain Agent",
                    description = "Runs without cancellation",
                    prompt = "You are plain."
                })
                local seen
                agent._llm = {
                    generate = function(_, options)
                        seen = options
                        return { result = "done", tokens = {}, finish_reason = "stop" }
                    end
                }

                local result, err = test_agent:step(mock_prompt.new())

                test.is_nil(err)
                test.is_nil(seen.cancel)
                test.is_nil(result.stopped)
                test.eq(result.result, "done")
            end)

            it("should carry an explicit zero temperature rather than treating it as unset", function()
                local spec = {
                    id = "zero-temp-agent",
                    name = "Zero Temp Agent",
                    description = "Asks for greedy decoding on purpose",
                    prompt = "You are deterministic.",
                    temperature = 0
                }

                local test_agent = agent.new(spec)
                test.eq(test_agent.temperature, 0)

                local seen
                agent._llm = {
                    generate = function(messages, options)
                        seen = options
                        return { result = "done", tokens = {} }
                    end
                }
                test_agent:step(mock_prompt.new())
                test.eq(seen.temperature, 0)
            end)

            it("should omit temperature from model options when the spec does not set one", function()
                -- Claude 4.7+ and Opus/Sonnet 5 reject temperature, top_p and
                -- top_k outright, so a fabricated default makes every agent that
                -- never asked for one unusable on those models.
                local spec = {
                    id = "unset-temp-agent",
                    name = "Unset Temp Agent",
                    description = "Leaves sampling to the model",
                    prompt = "You are unset."
                }

                local test_agent = agent.new(spec)

                local seen
                agent._llm = {
                    generate = function(messages, options)
                        seen = options
                        return { result = "done", tokens = {} }
                    end
                }
                test_agent:step(mock_prompt.new())

                test.not_nil(seen)
                test.is_nil(seen.temperature)
                test.is_nil(seen.top_p)
                test.is_nil(seen.top_k)
            end)

            it("should preserve tool wrapper specs from compiled specification", function()
                local test_agent = agent.new(compiled_spec_with_tool_wrappers)

                test.not_nil(test_agent)
                test.not_nil(test_agent.tool_wrappers)
                test.eq(#test_agent.tool_wrappers, 1)

                local wrapper = test_agent.tool_wrappers[1]
                test.eq(wrapper.id, "audit_tools")
                test.eq(wrapper.binding, "test.wrapper:audit_provider")
                test.eq(wrapper.phases[1], "before_execute")
                test.eq(wrapper.phases[2], "after_execute")
                test.is_true(wrapper.strict)
                test.eq(wrapper.context.policy, "readonly")
                test.eq(wrapper.options.max_calls, 4)
            end)

            it("should preserve agent options from compiled specification", function()
                local test_agent = agent.new(compiled_spec_with_tool_wrappers)

                test.not_nil(test_agent)
                test.not_nil(test_agent.agent_options)
                test.eq(test_agent.agent_options.checkpoint.token_threshold, 16000)
                test.eq(test_agent.agent_options.checkpoint.function_id, "agent.checkpoint:test")
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
                test.eq(fast_call.registry_id, "app:delay_tool")
                test.not_nil(fast_call.context)
                test.eq(fast_call.context.delay, 25)
                test.eq(fast_call.context.priority, "high")

                -- Verify slow_echo context
                test.eq(slow_call.name, "slow_echo")
                test.eq(slow_call.registry_id, "app:delay_tool")
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
            it("keeps malformed delegate arguments in the tool error path", function()
                mock_llm.generate = function()
                    return { finish_reason = "tool_call", tool_calls = {
                        { id = "bad", name = "to_data_specialist", arguments = '{"task":',
                            raw_arguments = '{"task":', arguments_error = "unexpected end of JSON input" }
                    } }
                end
                local result = agent.new(compiled_spec_with_delegates):step(mock_prompt.new())
                test.is_nil(result.delegate_calls)
                test.eq(#result.tool_calls, 1)
                test.eq(result.tool_calls[1].raw_arguments, '{"task":')
                test.eq(result.tool_calls[1].arguments_error, "unexpected end of JSON input")
            end)

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

            it("should keep tool wrapper metadata stable when a delegate redirect is emitted", function()
                local redirect_agent_spec = {}
                for k, v in pairs(compiled_spec_with_delegates) do
                    redirect_agent_spec[k] = v
                end
                redirect_agent_spec.tool_wrappers = compiled_spec_with_tool_wrappers.tool_wrappers
                redirect_agent_spec.agent_options = compiled_spec_with_tool_wrappers.agent_options

                local test_agent = agent.new(redirect_agent_spec)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("Please analyze this sales data for trends")
                local result = test_agent:step(prompt_builder)

                test.not_nil(result.delegate_calls)
                test.eq(#result.delegate_calls, 1)
                test.eq(#test_agent.tool_wrappers, 1)
                test.eq(test_agent.tool_wrappers[1].binding, "test.wrapper:audit_provider")
                test.eq(test_agent.agent_options.checkpoint.token_threshold, 16000)
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
                test.eq(#result.context_notes, 1)
                local note = result.context_notes[1]
                test.eq(note.role, prompt.ROLE.DEVELOPER)
                test.is_true(note.metadata.preserve_position)
                test.eq(note.metadata.memory_ids, result.memory_recall.memory_ids)
                test.is_nil(result.memory_prompt)
            end)

            it("recalls without any host option and returns the note on every result", function()
                local replies = {
                    { result = "ok", finish_reason = "stop" },
                    { result = "partial", finish_reason = "length",
                        tool_calls = { { id = "call_1", name = "calculator", arguments = {} } } },
                    { result = "partial", finish_reason = "cancelled" },
                }
                for _, reply in ipairs(replies) do
                    local sent: any = nil
                    agent._llm = {
                        generate = function(messages)
                            sent = messages
                            return reply
                        end
                    }
                    local test_agent = agent.new(compiled_spec_with_memory)
                    local prompt_builder = prompt.new()
                    prompt_builder:add_user("Hello")
                    prompt_builder:add_assistant("Hi there!")
                    prompt_builder:add_user("Can you help me calculate something?")

                    local result = assert(test_agent:step(prompt_builder))

                    test.eq(#result.context_notes, 1, reply.finish_reason)
                    test.eq(sent[#sent], result.context_notes[1], reply.finish_reason)
                    test.is_true(result.context_notes[1].metadata.preserve_position, reply.finish_reason)
                end
            end)

            it("sends the recall note at the conversation tail where the host persists it", function()
                local sent: any = nil
                agent._llm = {
                    generate = function(messages)
                        sent = messages
                        return { result = "ok", finish_reason = "stop" }
                    end
                }
                local test_agent = agent.new(compiled_spec_with_memory)
                local prompt_builder = prompt.new()
                prompt_builder:add_user("Hello")
                prompt_builder:add_assistant("Hi there!")
                prompt_builder:add_user("Can you help me calculate something?")

                local result = test_agent:step(prompt_builder)

                test.eq(#result.context_notes, 1)
                local n = #sent
                test.eq(sent[n], result.context_notes[1])
                test.eq(sent[n - 1].role, prompt.ROLE.CACHE_MARKER)
                test.eq(sent[n - 1].marker_id, "conversation_tail")
                test.eq(sent[n - 2].role, prompt.ROLE.USER)
            end)

            it("should skip memory recall when conversation is too short", function()
                local test_agent = agent.new(compiled_spec_with_memory)
                local prompt_builder = mock_prompt.new()

                -- Only one message - below min_conversation_length
                prompt_builder:add_user("Hello")

                local result = test_agent:step(prompt_builder)

                test.not_nil(result)
                test.is_nil(result.memory_recall)
                test.is_nil(result.context_notes)
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
                test.is_nil(result.context_notes)
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
                test.is_nil(result.context_notes)
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
            it("forwards each step context to the LLM without retaining it", function()
                local seen = {}
                agent._llm = {
                    generate = function(messages, options)
                        seen[#seen + 1] = options
                        return { result = "done", tokens = { prompt_tokens = 10, completion_tokens = 5 },
                            finish_reason = "stop" }
                    end
                }
                local runner = agent.new(basic_compiled_spec)
                local builder = mock_prompt.new()
                for _, options in ipairs({ { context_id = "first-context" }, { context_id = "second-context" }, {} }) do
                    local result, err = runner:step(builder, options)
                    test.is_nil(err)
                    test.not_nil(result)
                end
                test.eq(seen[1].context_id, "first-context")
                test.eq(seen[2].context_id, "second-context")
                test.is_nil(seen[3].context_id)
            end)

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

        describe("Prompt Caching", function()
            local function capture(builder)
                local captured = nil
                agent._llm = {
                    generate = function(messages, options)
                        captured = messages
                        return {
                            result = "ok",
                            tokens = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 },
                            finish_reason = "stop"
                        }
                    end
                }
                local test_agent = agent.new(basic_compiled_spec)
                test_agent:step(builder, { disable_memory_recall = true })
                agent._llm = nil
                return captured :: any
            end

            it("should mark the conversation tail after the newest user message", function()
                local builder = mock_prompt.new()
                builder:add_user("First message")
                builder:add_assistant("First response")
                builder:add_user("Second message")

                local messages = capture(builder)
                test.not_nil(messages)
                local last = messages[#messages]
                test.eq(last.role, prompt.ROLE.CACHE_MARKER)
                test.eq(last.marker_id, "conversation_tail")
                test.eq(messages[#messages - 1].role, "user")
            end)

            it("should not add a tail marker when the conversation ends with an assistant message", function()
                local builder = mock_prompt.new()
                builder:add_user("First message")
                builder:add_assistant("First response")

                local messages = capture(builder)
                test.not_nil(messages)
                for _, msg in ipairs(messages) do
                    test.is_true(msg.marker_id ~= "conversation_tail")
                end
            end)

            it("places the conversation tail marker before trailing per-step developer notes", function()
                local builder = prompt.new()
                builder:add_user("First message")
                builder:add_developer("Per-step lifecycle note")

                local messages = capture(builder)
                local n = #messages
                test.eq(messages[n].role, prompt.ROLE.DEVELOPER)
                test.eq(messages[n - 1].role, prompt.ROLE.CACHE_MARKER)
                test.eq(messages[n - 1].marker_id, "conversation_tail")
                test.eq(messages[n - 2].role, prompt.ROLE.USER)
            end)

            it("places the conversation tail marker before trailing positional notes", function()
                local builder = prompt.new()
                builder:add_user("First message")
                builder:add_system("The current date and time is Tuesday.", { preserve_position = true })
                builder:add_developer("Recalled memory", { preserve_position = true })

                local messages = capture(builder)
                local n = #messages
                test.eq(messages[n].role, prompt.ROLE.DEVELOPER)
                test.eq(messages[n - 1].role, prompt.ROLE.SYSTEM)
                test.eq(messages[n - 2].role, prompt.ROLE.CACHE_MARKER)
                test.eq(messages[n - 2].marker_id, "conversation_tail")
                test.eq(messages[n - 3].role, prompt.ROLE.USER)
            end)

            -- Canonical encoding with sorted keys and cache_control removed, so
            -- prefixes compare by the bytes a provider hashes for its cache.
            local function canonical(value)
                if type(value) ~= "table" then
                    return json.encode(value)
                end
                if value[1] ~= nil or next(value) == nil then
                    local parts = {}
                    for _, item in ipairs(value) do parts[#parts + 1] = canonical(item) end
                    return "[" .. table.concat(parts, ",") .. "]"
                end
                local keys = {}
                for key in pairs(value) do
                    if key ~= "cache_control" then keys[#keys + 1] = tostring(key) end
                end
                table.sort(keys)
                local parts = {}
                for _, key in ipairs(keys) do
                    parts[#parts + 1] = json.encode(key) .. ":" .. canonical(value[key])
                end
                return "{" .. table.concat(parts, ",") .. "}"
            end

            -- Every block the previous request marked for caching, as the
            -- canonical prefix ending at that block.
            local function cached_prefixes(mapped)
                local prefixes = {}
                local system = mapped.system or {}
                for index, block in ipairs(system) do
                    if block.cache_control then
                        prefixes[#prefixes + 1] = { system = index, messages = 0 }
                    end
                end
                for m, message in ipairs(mapped.messages) do
                    for b, block in ipairs(message.content or {}) do
                        if block.cache_control then
                            prefixes[#prefixes + 1] = { system = #system, messages = m, block = b }
                        end
                    end
                end
                return prefixes
            end

            local function prefix_text(mapped, system_count, message_count, block_count)
                local blocks = {}
                for i = 1, system_count do blocks[i] = (mapped.system or {})[i] end
                local messages = {}
                for m = 1, message_count do
                    local message = mapped.messages[m]
                    if not message then return nil end
                    local content = message.content or {}
                    if m == message_count and block_count then
                        local partial = {}
                        for b = 1, block_count do partial[b] = content[b] end
                        content = partial
                    end
                    messages[m] = { role = message.role, content = content }
                end
                return canonical({ system = blocks, messages = messages })
            end

            it("keeps the previous step's cached prefix byte-identical with per-step context attached", function()
                local recalls = 0
                agent._contract = {
                    get = function(contract_id)
                        test.eq(contract_id, "wippy.agent:memory")
                        return {
                            open = function()
                                return {
                                    recall = function()
                                        recalls = recalls + 1
                                        return { memories = { { id = "m" .. recalls, content = "Recalled fact " .. recalls } } }
                                    end
                                }
                            end
                        }
                    end
                }
                agent._funcs = {
                    new = function()
                        return {
                            with_context = function(self) return self end,
                            call = function() return "Workspace: release planning" end
                        }
                    end
                }

                local requests = {}
                local replies = {
                    {
                        result = "",
                        tool_calls = { { id = "call_1", name = "calculator", arguments = { expression = "2+2" }, registry_id = "test:calculator" } },
                        tokens = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 },
                        finish_reason = "tool_call"
                    },
                    {
                        result = "Done",
                        tokens = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 },
                        finish_reason = "stop"
                    },
                }
                agent._llm = {
                    generate = function(messages)
                        requests[#requests + 1] = messages
                        return replies[#requests]
                    end
                }

                local spec = {}
                for k, v in pairs(basic_compiled_spec) do spec[k] = v end
                spec.prompt_funcs = { { trait_id = "workspace", func_id = "test:workspace_prompt", context = {} } }
                spec.memory_contract = { implementation_id = "test:memory", options = { min_conversation_length = 1 } }
                local runner = agent.new(spec)

                local step1 = prompt.new()
                step1:add_user("Plan the release")
                step1:add_developer("Lifecycle note for step 1")
                local result1, err1 = runner:step(step1, { context = {} })
                test.is_nil(err1)

                local step2 = prompt.new()
                step2:add_user("Plan the release")
                for _, note in ipairs(result1.context_notes) do
                    step2:add_message(note.role, note.content, nil, note.metadata)
                end
                step2:add_function_call("calculator", '{"expression":"2+2"}', "call_1")
                step2:add_function_result("calculator", "4", "call_1")
                step2:add_developer("Lifecycle note for step 2")
                local _, err2 = runner:step(step2, { context = {} })
                test.is_nil(err2)

                test.eq(#requests, 2)
                test.eq(recalls, 2)

                local first = claude_mapper.map_messages(requests[1])
                local second = claude_mapper.map_messages(requests[2])
                local prefixes = cached_prefixes(first)
                test.gt(#prefixes, 1, "system and conversation breakpoints are both marked")
                for _, prefix in ipairs(prefixes) do
                    local before = prefix_text(first, prefix.system, prefix.messages, prefix.block)
                    local after = prefix_text(second, prefix.system, prefix.messages, prefix.block)
                    test.eq(after, before, "prefix through message " .. tostring(prefix.messages))
                end
            end)

            describe("Cache lifetime", function()
                local function requested_options(agent_options, runtime_options)
                    local seen = nil
                    agent._llm = {
                        generate = function(_, options)
                            seen = options
                            return { result = "ok", tokens = {}, finish_reason = "stop" }
                        end
                    }
                    local test_agent = agent.new({
                        id = "cache-lifetime-agent",
                        name = "Cache Lifetime Agent",
                        description = "Waits on long sub-tasks between steps",
                        prompt = "You coordinate long sub-tasks.",
                        agent_options = agent_options
                    })
                    local runtime = runtime_options or {}
                    runtime.disable_memory_recall = true
                    local _, err = test_agent:step(mock_prompt.new(), runtime)
                    agent._llm = nil
                    test.is_nil(err)
                    return seen :: any
                end

                it("asks the model for the cache lifetime its agent options set", function()
                    test.eq(requested_options({ prompt_cache = { ttl = "1h" } }).cache_ttl, "1h")
                end)

                it("lets the host set the cache lifetime for a step", function()
                    test.eq(requested_options({ prompt_cache = { ttl = "1h" } }, { cache_ttl = "5m" }).cache_ttl, "5m")
                    test.eq(requested_options(nil, { cache_ttl = "1h" }).cache_ttl, "1h")
                end)

                it("leaves the cache lifetime to the model route when nothing sets it", function()
                    test.is_nil(requested_options(nil).cache_ttl)
                    test.is_nil(requested_options({ prompt_cache = "1h" }).cache_ttl)
                end)
            end)

            describe("Stable prefix", function()
                it("requires an llm package that provides positional notes", function()
                    if type(prompt.is_positional_note) ~= "function" then
                        test.fail("wippy/llm >= 0.5.13 is required: prompt.is_positional_note is missing")
                    end
                end)

                local function without_markers(messages)
                    local result = {}
                    for _, message in ipairs(messages) do
                        if message.role ~= prompt.ROLE.CACHE_MARKER then
                            result[#result + 1] = message
                        end
                    end
                    return result
                end

                local function recording_llm(requests, replies)
                    return {
                        generate = function(messages)
                            requests[#requests + 1] = messages
                            return replies and replies[#requests] or { result = "ok", finish_reason = "stop" }
                        end
                    }
                end

                local function copy_spec(overrides)
                    local spec = {}
                    for k, v in pairs(basic_compiled_spec) do spec[k] = v end
                    local tools = {}
                    for name, tool in pairs(basic_compiled_spec.tools) do
                        local copied = {}
                        for k, v in pairs(tool) do copied[k] = v end
                        copied.schema = json.decode((json.encode(tool.schema)))
                        tools[name] = copied
                    end
                    spec.tools = tools
                    for k, v in pairs(overrides or {}) do spec[k] = v end
                    return spec
                end

                it("fails the step when a prompt function fails", function()
                    local requests = {}
                    agent._llm = recording_llm(requests)
                    agent._funcs = {
                        new = function()
                            return {
                                with_context = function(self) return self end,
                                call = function()
                                    return nil, errors.new({ message = "workspace store unavailable",
                                        kind = errors.UNAVAILABLE, retryable = true,
                                        details = { store = "workspace", attempt = 2 } })
                                end
                            }
                        end
                    }
                    local runner = agent.new(copy_spec({
                        prompt_funcs = { { trait_id = "workspace", func_id = "test:workspace_prompt", context = {} } }
                    }))
                    local builder = prompt.new()
                    builder:add_user("First")
                    local result, err = runner:step(builder, { context = {} })
                    test.is_nil(result)
                    test.contains(tostring(err), "test:workspace_prompt")
                    test.contains(tostring(err), "workspace store unavailable")
                    test.eq(err:kind(), errors.UNAVAILABLE)
                    test.is_true(err:retryable())
                    test.eq(err:details().store, "workspace")
                    test.eq(err:details().attempt, 2)
                    test.eq(#requests, 0)
                end)

                describe("Stale thinking", function()
                    local function blocks(name)
                        return { { type = "thinking", thinking = name, signature = "sig-" .. name } }
                    end

                    local function current_fingerprint()
                        agent._llm = recording_llm({})
                        local builder = prompt.new()
                        builder:add_user("Hello")
                        return assert(agent.new(copy_spec()):step(builder)).prefix_fingerprint
                    end

                    local function history(answer_metadata)
                        local answer = { role = prompt.ROLE.ASSISTANT, content = { prompt.text("Earlier answer") },
                            metadata = answer_metadata }
                        local builder = prompt.new({
                            { role = prompt.ROLE.USER, content = { prompt.text("Earlier question") } },
                            answer,
                            { role = prompt.ROLE.USER, content = { prompt.text("New question") } },
                        })
                        return builder, answer
                    end

                    local function sent_answer(requests)
                        for _, message in ipairs(requests[#requests]) do
                            if message.role == prompt.ROLE.ASSISTANT then return message end
                        end
                        return nil
                    end

                    it("strips blocks bound to another prefix before the request", function()
                        local builder, answer = history({ thinking_blocks = blocks("old"), prefix_fingerprint = "previous" })
                        local requests = {}
                        agent._llm = recording_llm(requests)
                        local result, err = agent.new(copy_spec()):step(builder, { drop_stale_thinking = true })
                        test.is_nil(err)
                        test.not_nil(result)
                        local sent = assert(sent_answer(requests))
                        test.is_nil(sent.metadata.thinking_blocks)
                        test.eq(sent.metadata.prefix_fingerprint, "previous")
                        test.eq(#answer.metadata.thinking_blocks, 1)
                    end)

                    it("treats blocks without a stored fingerprint as stale", function()
                        local builder = history({ thinking_blocks = blocks("old") })
                        local requests = {}
                        agent._llm = recording_llm(requests)
                        assert(agent.new(copy_spec()):step(builder, { drop_stale_thinking = true }))
                        test.is_nil(assert(sent_answer(requests)).metadata.thinking_blocks)
                    end)

                    it("keeps blocks bound to the current prefix", function()
                        local fingerprint = current_fingerprint()
                        local builder = history({ thinking_blocks = blocks("kept"), prefix_fingerprint = fingerprint })
                        local requests = {}
                        agent._llm = recording_llm(requests)
                        assert(agent.new(copy_spec()):step(builder, { drop_stale_thinking = true }))
                        test.eq(assert(sent_answer(requests)).metadata.thinking_blocks[1].thinking, "kept")
                    end)

                    it("leaves blocks alone when the host does not ask for stripping", function()
                        local builder = history({ thinking_blocks = blocks("old"), prefix_fingerprint = "previous" })
                        local requests = {}
                        agent._llm = recording_llm(requests)
                        assert(agent.new(copy_spec()):step(builder))
                        test.eq(assert(sent_answer(requests)).metadata.thinking_blocks[1].thinking, "old")
                    end)

                    it("honours a host predicate", function()
                        local fingerprint = current_fingerprint()
                        local builder = history({ thinking_blocks = blocks("epoch"), prefix_fingerprint = fingerprint,
                            checkpoint = "before" })
                        local requests = {}
                        local seen = nil
                        agent._llm = recording_llm(requests)
                        assert(agent.new(copy_spec()):step(builder, {
                            drop_stale_thinking = true,
                            thinking_is_current = function(msg, current)
                                seen = current
                                return msg.metadata.prefix_fingerprint == current and msg.metadata.checkpoint == "after"
                            end,
                        }))
                        test.eq(seen, fingerprint)
                        test.is_nil(assert(sent_answer(requests)).metadata.thinking_blocks)
                    end)

                    it("fails the step without a request when a stale turn has an open call", function()
                        local builder = prompt.new({
                            { role = prompt.ROLE.USER, content = { prompt.text("Question") } },
                            { role = prompt.ROLE.ASSISTANT, content = { prompt.text("Looking") },
                                metadata = { thinking_blocks = blocks("open"), prefix_fingerprint = "previous" } },
                            { role = prompt.ROLE.FUNCTION_CALL, content = {},
                                function_call = { id = "call_open", name = "calculator", arguments = "{}" } },
                            { role = prompt.ROLE.USER, content = { prompt.text("Never mind") } },
                        })
                        local requests = {}
                        agent._llm = recording_llm(requests)
                        local result, err = agent.new(copy_spec()):step(builder, { drop_stale_thinking = true })
                        test.is_nil(result)
                        test.contains(tostring(err), "call_open")
                        test.eq(#requests, 0)
                    end)

                    it("keeps the current tool round's blocks when a user message joins its results", function()
                        local builder = prompt.new({
                            { role = prompt.ROLE.USER, content = { prompt.text("Compute it") } },
                            { role = prompt.ROLE.ASSISTANT, content = { prompt.text("Computing") },
                                metadata = { thinking_blocks = blocks("round"), prefix_fingerprint = "previous" } },
                            { role = prompt.ROLE.FUNCTION_CALL, content = {},
                                function_call = { id = "call_1", name = "calculator", arguments = "{}" } },
                            { role = prompt.ROLE.FUNCTION_RESULT, name = "calculator", function_call_id = "call_1",
                                content = { prompt.text("4") } },
                            { role = prompt.ROLE.USER, content = { prompt.text("Use metric units") } },
                        })
                        local requests = {}
                        agent._llm = recording_llm(requests)
                        assert(agent.new(copy_spec()):step(builder, { drop_stale_thinking = true }))
                        local answer = assert(sent_answer(requests))
                        test.eq(answer.metadata.thinking_blocks[1].thinking, "round")
                    end)

                    it("keeps the current tool round's blocks and strips earlier stale turns", function()
                        local builder = prompt.new({
                            { role = prompt.ROLE.USER, content = { prompt.text("Earlier question") } },
                            { role = prompt.ROLE.ASSISTANT, content = { prompt.text("Earlier answer") },
                                metadata = { thinking_blocks = blocks("earlier"), prefix_fingerprint = "previous" } },
                            { role = prompt.ROLE.USER, content = { prompt.text("Compute it") } },
                            { role = prompt.ROLE.ASSISTANT, content = { prompt.text("Computing") },
                                metadata = { thinking_blocks = blocks("round"), prefix_fingerprint = "previous" } },
                            { role = prompt.ROLE.FUNCTION_CALL, content = {},
                                function_call = { id = "call_1", name = "calculator", arguments = "{}" } },
                            { role = prompt.ROLE.FUNCTION_RESULT, name = "calculator", function_call_id = "call_1",
                                content = { prompt.text("4") } },
                        })
                        local requests = {}
                        agent._llm = recording_llm(requests)
                        assert(agent.new(copy_spec()):step(builder, { drop_stale_thinking = true }))
                        local assistants = {}
                        for _, message in ipairs(requests[1]) do
                            if message.role == prompt.ROLE.ASSISTANT then table.insert(assistants, message) end
                        end
                        test.eq(#assistants, 2)
                        test.is_nil(assistants[1].metadata.thinking_blocks)
                        test.eq(assistants[2].metadata.thinking_blocks[1].thinking, "round")
                    end)

                    local function compacting_llm(captured)
                        return {
                            ERROR_TYPE = { CONTEXT_WINDOW = "context_window" },
                            generate = function(_, options)
                                local replacement, err = options.checkpoint.compact({ estimated_prompt_tokens = 10 })
                                captured.replacement, captured.err = replacement, err
                                return { result = "done", finish_reason = "stop" }
                            end
                        }
                    end

                    local function compaction()
                        local replacement = prompt.new()
                        replacement:add_user("Retained task")
                        replacement:add_message(prompt.ROLE.ASSISTANT, { prompt.text("Retained answer") }, nil,
                            { thinking_blocks = blocks("retained"), prefix_fingerprint = "previous" })
                        replacement:add_user("Next question")
                        return replacement
                    end

                    local function retained_answer(messages)
                        for _, message in ipairs(messages) do
                            if message.role == prompt.ROLE.ASSISTANT then return message end
                        end
                        return nil
                    end

                    it("returns the fingerprint of the request a checkpoint replacement sends", function()
                        local function replacement_history()
                            local replacement = prompt.new()
                            replacement:add_system("Context memory: release plan v2")
                            replacement:add_user("Retained task")
                            return replacement
                        end
                        local captured = {}
                        agent._llm = compacting_llm(captured)
                        local builder = prompt.new()
                        builder:add_user("Large conversation")
                        local compacted = assert(agent.new(copy_spec()):step(builder, {
                            checkpoint = { token_threshold = 1, compact = function() return replacement_history() end },
                        }))
                        test.is_nil(captured.err)

                        agent._llm = recording_llm({})
                        local direct = assert(agent.new(copy_spec()):step(replacement_history()))
                        local plain_builder = prompt.new()
                        plain_builder:add_user("Large conversation")
                        local plain = assert(agent.new(copy_spec()):step(plain_builder))

                        test.eq(compacted.prefix_fingerprint, direct.prefix_fingerprint)
                        test.neq(compacted.prefix_fingerprint, plain.prefix_fingerprint)
                    end)

                    it("keeps the fingerprint of a checkpointed step that does not compact", function()
                        agent._llm = {
                            ERROR_TYPE = { CONTEXT_WINDOW = "context_window" },
                            generate = function() return { result = "done", finish_reason = "stop" } end
                        }
                        local builder = prompt.new()
                        builder:add_user("Small conversation")
                        local checkpointed = assert(agent.new(copy_spec()):step(builder, {
                            checkpoint = { token_threshold = 1000, compact = function() return nil, "unused" end },
                        }))
                        agent._llm = recording_llm({})
                        local plain = assert(agent.new(copy_spec()):step(builder))
                        test.eq(checkpointed.prefix_fingerprint, plain.prefix_fingerprint)
                    end)

                    it("strips stale blocks from a checkpoint replacement history", function()
                        local captured = {}
                        agent._llm = compacting_llm(captured)
                        local builder = prompt.new()
                        builder:add_user("Large conversation")
                        local result, err = agent.new(copy_spec()):step(builder, {
                            drop_stale_thinking = true,
                            checkpoint = { token_threshold = 1, compact = function() return compaction() end },
                        })
                        test.is_nil(err)
                        test.not_nil(result)
                        test.is_nil(captured.err)
                        local answer = assert(retained_answer(captured.replacement))
                        test.is_nil(answer.metadata.thinking_blocks)
                    end)

                    it("consults the host predicate for checkpoint replacement messages", function()
                        local captured = {}
                        local consulted = {}
                        agent._llm = compacting_llm(captured)
                        local builder = prompt.new()
                        builder:add_user("Large conversation")
                        assert(agent.new(copy_spec()):step(builder, {
                            drop_stale_thinking = true,
                            thinking_is_current = function(msg)
                                table.insert(consulted, msg.content[1].text)
                                return true
                            end,
                            checkpoint = { token_threshold = 1, compact = function() return compaction() end },
                        }))
                        test.eq(#consulted, 1)
                        test.eq(consulted[1], "Retained answer")
                        test.eq(assert(retained_answer(captured.replacement)).metadata.thinking_blocks[1].thinking, "retained")
                    end)

                    it("never sends the stored fingerprint to the provider", function()
                        local fingerprint = current_fingerprint()
                        local builder = history({ thinking_blocks = blocks("kept"), prefix_fingerprint = fingerprint })
                        local requests = {}
                        agent._llm = recording_llm(requests)
                        assert(agent.new(copy_spec()):step(builder, { drop_stale_thinking = true }))
                        local mapped = assert(claude_mapper.map_messages(requests[1]))
                        test.is_nil(canonical(mapped):find(fingerprint, 1, true))
                        test.is_nil(canonical(mapped):find("prefix_fingerprint", 1, true))
                    end)
                end)

                it("sends the same system message on every step", function()
                    local requests = {}
                    agent._llm = recording_llm(requests)
                    agent._funcs = {
                        new = function()
                            return {
                                with_context = function(self) return self end,
                                call = function() return "Workspace: release planning" end
                            }
                        end
                    }
                    local spec = copy_spec({
                        prompt_funcs = { { trait_id = "workspace", func_id = "test:workspace_prompt", context = {} } }
                    })
                    local runner = agent.new(spec)
                    local builder = prompt.new()
                    builder:add_user("First")
                    runner:step(builder, { context = {} })
                    builder:add_assistant("Answer")
                    builder:add_user("Second")
                    runner:step(builder, { context = {} })

                    test.eq(#requests, 2)
                    test.eq(requests[1][1].role, prompt.ROLE.SYSTEM)
                    test.eq(requests[2][1].content[1].text, requests[1][1].content[1].text)
                end)

                it("keeps each request a prefix of the next once the host persists context notes", function()
                    agent._contract = {
                        get = function()
                            return {
                                open = function()
                                    return {
                                        recall = function(_, options)
                                            return { memories = { { id = "m" .. #options.recent_actions, content = "Fact" } } }
                                        end
                                    }
                                end
                            }
                        end
                    }
                    local requests = {}
                    agent._llm = recording_llm(requests, {
                        {
                            result = "",
                            tool_calls = { { id = "call_1", name = "calculator", arguments = { expression = "2+2" } } },
                            metadata = { thinking_blocks = { { type = "thinking", thinking = "plan", signature = "sig" } } },
                            finish_reason = "tool_call"
                        },
                        { result = "Done", finish_reason = "stop" },
                    })
                    local runner = agent.new(copy_spec({
                        memory_contract = { implementation_id = "test:memory", options = { min_conversation_length = 1 } }
                    }))

                    local history = prompt.new()
                    history:add_user("Plan the release")
                    local first = assert(runner:step(history, { context = {} }))
                    test.eq(#first.context_notes, 1)
                    for _, note in ipairs(first.context_notes) do
                        history:add_message(note.role, note.content, nil, note.metadata)
                    end
                    history:add_function_call("calculator", '{"expression":"2+2"}', "call_1")
                    history.messages[#history.messages].metadata = { thinking_blocks = first.metadata.thinking_blocks }
                    history:add_function_result("calculator", "4", "call_1")
                    local second = assert(runner:step(history, { context = {} }))
                    test.eq(#second.context_notes, 1)

                    local before = without_markers(requests[1])
                    local after = without_markers(requests[2])
                    test.gt(#after, #before)
                    for index, message in ipairs(before) do
                        test.eq(canonical(after[index]), canonical(message), "message " .. tostring(index))
                    end
                end)

                it("returns a prefix fingerprint that is stable across steps", function()
                    local requests = {}
                    agent._llm = recording_llm(requests)
                    local runner = agent.new(copy_spec())
                    local builder = prompt.new()
                    builder:add_user("First")
                    local first = assert(runner:step(builder))
                    builder:add_assistant("Answer")
                    builder:add_user("Second")
                    local second = assert(runner:step(builder))
                    local rebuilt = assert(agent.new(copy_spec()):step(builder))

                    test.eq(type(first.prefix_fingerprint), "string")
                    test.eq(#first.prefix_fingerprint, 64)
                    test.eq(second.prefix_fingerprint, first.prefix_fingerprint)
                    test.eq(rebuilt.prefix_fingerprint, first.prefix_fingerprint)
                end)

                local function fingerprint_of(spec, extend)
                    agent._llm = recording_llm({})
                    local builder = prompt.new()
                    builder:add_user("Hello")
                    if extend then extend(builder) end
                    return assert(agent.new(spec):step(builder)).prefix_fingerprint
                end

                it("changes the prefix fingerprint when the sent system text or tools change", function()
                    local base = fingerprint_of(copy_spec())
                    local fewer_tools = copy_spec()
                    fewer_tools.tools.weather = nil
                    local described = copy_spec()
                    described.tools.calculator.description = "Evaluate arithmetic"
                    local reshaped = copy_spec()
                    reshaped.tools.calculator.schema.required = { "expression" }
                    local renamed = copy_spec()
                    renamed.tools.calculate = renamed.tools.calculator
                    renamed.tools.calculator = nil
                    local native = copy_spec()
                    native.tools.calculator.meta = { claude = { type = "code_execution_20250522" } }
                    for label, spec in pairs({
                        system = copy_spec({ prompt = "You are a different agent." }),
                        tool_removed = fewer_tools,
                        tool_renamed = renamed,
                        tool_description = described,
                        tool_schema = reshaped,
                        tool_native_type = native,
                    }) do
                        test.neq(fingerprint_of(spec), base, label)
                    end
                end)

                it("includes conversation system messages that drivers hoist into the system prompt", function()
                    local base = fingerprint_of(copy_spec())
                    local hoisted = fingerprint_of(copy_spec(), function(builder)
                        builder:add_system("Mode: review")
                    end)
                    local positional = fingerprint_of(copy_spec(), function(builder)
                        builder:add_system("The current date and time is Tuesday.", { preserve_position = true })
                    end)
                    test.neq(hoisted, base)
                    test.eq(positional, base)
                end)

                it("keeps the prefix fingerprint across model and registry metadata changes", function()
                    local base = fingerprint_of(copy_spec())
                    local commented = copy_spec()
                    commented.tools.calculator.meta = { comment = "Renamed in the registry", tags = { "math" }, title = "Calc" }
                    commented.tools.calculator.registry_id = "other:calculator"
                    test.eq(fingerprint_of(commented), base)
                    test.eq(fingerprint_of(copy_spec({ model = "gpt-4o" })), base)
                end)
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
                        test.eq(tool.registry_id, "app:delay_tool")
                    elseif tool.name == "slow_echo" then
                        found_slow = true
                        test.eq(tool.registry_id, "app:delay_tool")
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

        describe("Context checkpoint prompt rebuilding", function()
            it("keeps ordinary legacy calls working and rejects unsupported checkpoint callbacks before dispatch", function()
                local runner = agent.new(basic_compiled_spec)
                local builder = mock_prompt.new()
                builder:add_user("ordinary conversation")
                local calls, compacted = 0, false
                agent._llm = {generate = function()
                    calls = calls + 1
                    return {result = "legacy response", metadata = {}}
                end}
                local ordinary, ordinary_err = runner:step(builder)
                test.is_nil(ordinary_err)
                test.eq(ordinary.result, "legacy response")
                test.eq(calls, 1)

                local result, err = runner:step(builder, {checkpoint = {compact = function()
                    compacted = true
                    error("unsupported callback must not run")
                end}})
                test.is_nil(result)
                test.contains(err:message(), "context admission support")
                test.is_false(err:retryable())
                test.eq(calls, 1)
                test.is_false(compacted)

                local stopped, stop_err = runner:step(builder, {
                    checkpoint = {compact = function() error("Stop must take priority") end},
                    stop_check = function() return true end,
                })
                test.is_nil(stop_err)
                test.is_true(stopped.stopped)
                test.eq(calls, 1)
            end)

            it("preserves system instructions and memory around a compacted conversation", function()
                local runner = agent.new(basic_compiled_spec)
                local builder = mock_prompt.new()
                builder:add_user("large conversation")
                agent._llm = { ERROR_TYPE = { CONTEXT_WINDOW = "context_window" }, generate = function(messages, options)
                    test.not_nil(options.checkpoint)
                    test.eq(options.checkpoint.token_threshold, 50)
                    local replacement, err = options.checkpoint.compact({ estimated_prompt_tokens = 100 })
                    test.is_nil(err)
                    test.eq(replacement[1], messages[1])
                    test.eq(replacement[1].role, "system")
                    test.eq(replacement[3].role, "user")
                    test.eq(replacement[4].role, "cache_marker")
                    test.eq(replacement[4].marker_id, "conversation_tail")
                    test.eq(replacement[5].role, "developer")
                    local task_found, old_found = false, false
                    for _, message in ipairs(replacement) do
                        for _, part in ipairs(type(message.content) == "table" and message.content or {}) do
                            if part.text == "retained task" then task_found = true end
                            if part.text == "large conversation" then old_found = true end
                        end
                    end
                    test.is_true(task_found)
                    test.is_false(old_found)
                    return { result = "done", metadata = {} }
                end }
                local result, err = runner:step(builder, { checkpoint = { token_threshold = 50, compact = function(info)
                    test.eq(info.estimated_prompt_tokens, 100)
                    local replacement = mock_prompt.new()
                    replacement:add_user("retained task")
                    replacement:add_developer("Per-step lifecycle note")
                    return replacement
                end } })
                test.is_nil(err)
                test.eq(result.result, "done")
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

            it("should send the route the host pinned and hand it back", function()
                local captured_options = nil
                local pin = { model = "backup", provider_id = "p.b", provider_model = "b-1" }
                agent._llm = {
                    generate = function(messages, options)
                        captured_options = options
                        return {
                            result = "Pinned response",
                            tokens = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 },
                            finish_reason = "stop",
                            metadata = { route = { model = "backup", provider_id = "p.b", provider_model = "b-1" } }
                        }
                    end
                }

                local test_agent = agent.new(basic_compiled_spec)
                local prompt_builder = mock_prompt.new()
                prompt_builder:add_user("Continue the turn")
                local response = test_agent:step(prompt_builder, { route = pin })

                test.eq((captured_options :: any).route, pin)
                test.eq((response :: any).route_pin, pin)

                agent._llm = nil
            end)

            it("should not pin a route while the first route answers", function()
                local captured_options = nil
                agent._llm = {
                    generate = function(messages, options)
                        captured_options = options
                        return {
                            result = "Primary response",
                            tokens = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 },
                            finish_reason = "stop",
                            metadata = { route = { model = "primary", provider_id = "p.a", provider_model = "a-1" } }
                        }
                    end
                }

                local test_agent = agent.new(basic_compiled_spec)
                local prompt_builder = mock_prompt.new()
                prompt_builder:add_user("First step")
                local response = test_agent:step(prompt_builder, {})

                test.is_nil((captured_options :: any).route)
                test.is_nil((response :: any).route_pin)

                agent._llm = nil
            end)

            it("should hand the host a pin once the model fell back", function()
                agent._llm = {
                    generate = function(messages, options)
                        return {
                            result = "Fallback response",
                            tokens = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 },
                            finish_reason = "stop",
                            metadata = {
                                route = { model = "backup", provider_id = "p.b", provider_model = "b-1" },
                                fallbacks = { { model = "primary", provider_id = "p.a", error_type = "server_error" } }
                            }
                        }
                    end
                }

                local test_agent = agent.new(basic_compiled_spec)
                local prompt_builder = mock_prompt.new()
                prompt_builder:add_user("First step")
                local response = test_agent:step(prompt_builder, {})

                local pin = (response :: any).route_pin
                test.eq(pin.model, "backup")
                test.eq(pin.provider_id, "p.b")
                test.eq(pin.provider_model, "b-1")

                agent._llm = nil
            end)

            it("should hand back no pin when the model reports no route", function()
                agent._llm = {
                    generate = function(messages, options)
                        return {
                            result = "Direct response",
                            tokens = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 },
                            finish_reason = "stop"
                        }
                    end
                }

                local test_agent = agent.new(basic_compiled_spec)
                local prompt_builder = mock_prompt.new()
                prompt_builder:add_user("First step")
                local response = test_agent:step(prompt_builder, {})

                test.is_nil((response :: any).route_pin)

                agent._llm = nil
            end)

            it("should forward the tool choice fallback the caller permits", function()
                local captured_options = nil
                agent._llm = {
                    generate = function(messages, options)
                        captured_options = options
                        return {
                            result = "ok",
                            tokens = { prompt_tokens = 1, completion_tokens = 1, total_tokens = 2 },
                            finish_reason = "stop"
                        }
                    end
                }

                local test_agent = agent.new(basic_compiled_spec)
                local prompt_builder = mock_prompt.new()
                prompt_builder:add_user("Finish")
                test_agent:step(prompt_builder, { tool_call = "any", tool_call_fallback = "auto" })

                test.eq((captured_options :: any).tool_choice, "any")
                test.eq((captured_options :: any).tool_choice_fallback, "auto")

                test_agent:step(prompt_builder, { tool_call = "any" })
                test.is_nil((captured_options :: any).tool_choice_fallback)

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
            it("distinguishes empty no-tool exhaustion without exposing executable calls", function()
                local test_agent = agent.new(basic_compiled_spec)
                local builder = mock_prompt.new()
                builder:add_user("Answer")
                agent._llm = { generate = function()
                    return { content = "", tool_calls = {}, finish_reason = "length" }
                end }
                local result, err = test_agent:step(builder)
                agent._llm = nil
                test.is_nil(err)
                test.is_true(result.truncated)
                test.eq(result.truncation_reason, "empty_output")
                test.is_nil(result.tool_calls)
            end)
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
                test.eq(result.truncation_reason, "tool_calls")

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
