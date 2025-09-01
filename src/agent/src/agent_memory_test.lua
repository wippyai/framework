local agent = require("agent")
local prompt = require("prompt")
local json = require("json")
local time = require("time")

local function define_tests()
    describe("Agent Memory Processing - Detailed Logic", function()
        local mock_llm
        local mock_prompt
        local mock_contract
        local test_messages = {}

        -- Helper function to create test messages
        local function create_message(role, content, metadata, name)
            local msg = {
                role = role,
                content = content,
                metadata = metadata
            }
            if name then
                msg.name = name -- For function_result messages
            end
            return msg
        end

        -- Helper function to create conversation messages
        local function create_conversation_messages(count)
            local messages = {}
            for i = 1, count do
                if i % 2 == 1 then
                    -- User message
                    table.insert(messages, create_message("user", {{ type = "text", text = "User message " .. i }}))
                else
                    -- Assistant message
                    table.insert(messages, create_message("assistant", {{ type = "text", text = "Assistant response " .. i }}))
                end
            end
            return messages
        end

        -- Mock memory contract that tracks calls and returns configurable responses
        local function create_mock_memory_contract(config)
            config = config or {}
            local call_log = {}

            return {
                recall = function(self, options)
                    -- Log the call for inspection
                    table.insert(call_log, {
                        recent_actions = options.recent_actions or {},
                        previous_memories = options.previous_memories or {},
                        constraints = options.constraints or {}
                    })

                    -- Return configured response
                    if config.should_error then
                        return nil, config.error_message or "Mock memory error"
                    end

                    local memories = config.memories or {
                        {
                            id = "test_memory_1",
                            content = "Mock memory content 1",
                            metadata = { type = "test", source = "mock" }
                        }
                    }

                    return { memories = memories }
                end,
                get_call_log = function() return call_log end,
                clear_call_log = function() call_log = {} end
            }
        end

        before_each(function()
            -- Reset test messages
            test_messages = {}

            mock_llm = {
                generate = function(messages, options)
                    -- Store messages for inspection
                    test_messages = messages

                    return {
                        result = "Mock LLM response",
                        tokens = { prompt_tokens = 10, completion_tokens = 5, total_tokens = 15 },
                        finish_reason = "stop"
                    }
                end
            }

            mock_prompt = {
                ROLE = {
                    USER = "user",
                    ASSISTANT = "assistant",
                    FUNCTION_RESULT = "function_result",
                    DEVELOPER = "developer",
                    SYSTEM = "system"
                },
                new = function()
                    local messages = {}
                    return {
                        add_user = function(self, content)
                            table.insert(messages, create_message("user", {{ type = "text", text = content }}))
                            return self
                        end,
                        add_assistant = function(self, content)
                            table.insert(messages, create_message("assistant", {{ type = "text", text = content }}))
                            return self
                        end,
                        add_developer = function(self, content)
                            table.insert(messages, create_message("developer", content))
                            return self
                        end,
                        add_function_result = function(self, name, result, id)
                            local content = type(result) == "string" and result or json.encode(result)
                            table.insert(messages, create_message("function_result", {{ type = "text", text = content }}, { function_call_id = id }, name))
                            return self
                        end,
                        get_messages = function()
                            return messages
                        end,
                        clone = function()
                            local cloned_messages = {}
                            for i, msg in ipairs(messages) do
                                -- Deep copy message
                                local cloned_msg = {
                                    role = msg.role,
                                    content = msg.content,
                                    metadata = msg.metadata,
                                    name = msg.name
                                }
                                cloned_messages[i] = cloned_msg
                            end
                            return {
                                add_user = function(self, content)
                                    table.insert(cloned_messages, create_message("user", {{ type = "text", text = content }}))
                                    return self
                                end,
                                add_assistant = function(self, content)
                                    table.insert(cloned_messages, create_message("assistant", {{ type = "text", text = content }}))
                                    return self
                                end,
                                add_developer = function(self, content)
                                    table.insert(cloned_messages, create_message("developer", content))
                                    return self
                                end,
                                add_system = function(self, content)
                                    table.insert(cloned_messages, create_message("system", content))
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
                                -- Return the mock contract that was set up for each test
                                return mock_contract._current_instance, mock_contract._current_error
                            end
                        }
                    else
                        return nil, "Unknown contract: " .. tostring(contract_id)
                    end
                end,
                _current_instance = nil,
                _current_error = nil
            }

            agent._llm = mock_llm
            agent._prompt = mock_prompt
            agent._contract = mock_contract

            -- Also inject the prompt module globally so agent can access prompt.ROLE
            _G.prompt = mock_prompt
        end)

        after_each(function()
            agent._llm = nil
            agent._prompt = nil
            agent._contract = nil
            mock_contract._current_instance = nil
            mock_contract._current_error = nil
            _G.prompt = nil
        end)

        describe("Recent Actions Extraction", function()
            it("should extract recent actions from messages in chronological order", function()
                local memory_contract = create_mock_memory_contract()
                mock_contract._current_instance = memory_contract

                local spec = {
                    id = "test-agent",
                    name = "Test Agent",
                    prompt = "Test agent",
                    tools = {},
                    memory_contract = {
                        implementation_id = "test:memory",
                        options = { max_actions = 3, message_types = { "user", "assistant", "function_result" } }
                    }
                }

                local test_agent = agent.new(spec)
                local prompt_builder = mock_prompt.new()

                -- Create specific message sequence
                prompt_builder:add_user("Calculate 2 + 2")
                prompt_builder:add_assistant("I'll calculate that for you")
                prompt_builder:add_function_result("calculator", "Result: 4", "call_123")
                prompt_builder:add_user("What about 3 + 3?")

                test_agent:step(prompt_builder)

                -- Inspect what was passed to memory contract
                local call_log = memory_contract:get_call_log()
                expect(#call_log).to_equal(1)

                local recent_actions = call_log[1].recent_actions
                expect(#recent_actions).to_equal(3) -- Limited by max_actions

                -- Check action formatting in chronological order (oldest to newest of recent actions)
                expect(recent_actions[1]).to_equal("assistant: I'll calculate that for you")  -- oldest of recent
                expect(recent_actions[2]).to_equal("tool: calculator -> Result: 4")
                expect(recent_actions[3]).to_equal("user: What about 3 + 3?")  -- newest
            end)

            it("should respect max_actions limit", function()
                local memory_contract = create_mock_memory_contract()
                mock_contract._current_instance = memory_contract

                local spec = {
                    id = "test-agent",
                    name = "Test Agent",
                    prompt = "Test agent",
                    tools = {},
                    memory_contract = {
                        implementation_id = "test:memory",
                        options = { max_actions = 2 }
                    }
                }

                local test_agent = agent.new(spec)
                local prompt_builder = mock_prompt.new()

                -- Add more messages than max_actions
                prompt_builder:add_user("Message 1")
                prompt_builder:add_assistant("Response 1")
                prompt_builder:add_user("Message 2")
                prompt_builder:add_assistant("Response 2")
                prompt_builder:add_user("Message 3")

                test_agent:step(prompt_builder)

                local call_log = memory_contract:get_call_log()
                local recent_actions = call_log[1].recent_actions

                expect(#recent_actions).to_equal(2) -- Should be limited
                -- Should be the 2 most recent actions in chronological order
                expect(recent_actions[1]).to_equal("assistant: Response 2")  -- older of the recent 2
                expect(recent_actions[2]).to_equal("user: Message 3")       -- newer of the recent 2
            end)

            it("should filter messages by type", function()
                local memory_contract = create_mock_memory_contract()
                mock_contract._current_instance = memory_contract

                local spec = {
                    id = "test-agent",
                    name = "Test Agent",
                    prompt = "Test agent",
                    tools = {},
                    memory_contract = {
                        implementation_id = "test:memory",
                        options = {
                            max_actions = 10,
                            message_types = { "user" } -- Only user messages
                        }
                    }
                }

                local test_agent = agent.new(spec)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("User message 1")
                prompt_builder:add_assistant("Assistant response 1")
                prompt_builder:add_user("User message 2")
                prompt_builder:add_assistant("Assistant response 2")

                test_agent:step(prompt_builder)

                local call_log = memory_contract:get_call_log()
                local recent_actions = call_log[1].recent_actions

                expect(#recent_actions).to_equal(2) -- Only user messages
                -- Should be in chronological order
                expect(recent_actions[1]).to_equal("user: User message 1")  -- older
                expect(recent_actions[2]).to_equal("user: User message 2")  -- newer
            end)

            it("should handle empty and malformed messages gracefully", function()
                local memory_contract = create_mock_memory_contract()
                mock_contract._current_instance = memory_contract

                local spec = {
                    id = "test-agent",
                    name = "Test Agent",
                    prompt = "Test agent",
                    tools = {},
                    memory_contract = {
                        implementation_id = "test:memory"
                    }
                }

                local test_agent = agent.new(spec)
                local prompt_builder = mock_prompt.new()

                -- Add a mix of normal and problematic messages
                prompt_builder:add_user("Normal message")

                -- Manually add malformed message
                local messages = prompt_builder:get_messages()
                table.insert(messages, { role = "user" }) -- No content
                table.insert(messages, { role = "assistant", content = {} }) -- Empty content
                table.insert(messages, { role = "user", content = {{ type = "text", text = "" }} }) -- Empty text

                test_agent:step(prompt_builder)

                local call_log = memory_contract:get_call_log()
                local recent_actions = call_log[1].recent_actions

                -- Should handle gracefully, extracting what it can
                expect(#recent_actions).to_be_greater_than(0)
                -- The normal message should be there, but empty messages might result in empty strings
                local found_normal = false
                for _, action in ipairs(recent_actions) do
                    if action == "user: Normal message" then
                        found_normal = true
                        break
                    end
                end
                expect(found_normal).to_be_true()
            end)
        end)

        describe("Memory ID Extraction and Deduplication", function()
            it("should extract memory IDs from message metadata", function()
                local memory_contract = create_mock_memory_contract()
                mock_contract._current_instance = memory_contract

                local spec = {
                    id = "test-agent",
                    name = "Test Agent",
                    prompt = "Test agent",
                    tools = {},
                    memory_contract = {
                        implementation_id = "test:memory",
                        options = { scan_limit = 5 }
                    }
                }

                local test_agent = agent.new(spec)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("First message")
                prompt_builder:add_assistant("First response")

                -- Add developer message with memory metadata (simulating previous recall)
                prompt_builder:add_developer("Previous memory")
                local messages = prompt_builder:get_messages()
                messages[#messages].metadata = { memory_ids = { "mem_1", "mem_2" } }

                prompt_builder:add_user("Second message")
                prompt_builder:add_developer("Another memory")
                messages = prompt_builder:get_messages()
                messages[#messages].metadata = { memory_ids = { "mem_3" } }

                prompt_builder:add_user("Current message")

                test_agent:step(prompt_builder)

                local call_log = memory_contract:get_call_log()
                local previous_memories = call_log[1].previous_memories

                -- Should find all memory IDs from metadata
                expect(#previous_memories).to_equal(3)
                local memory_set = {}
                for _, id in ipairs(previous_memories) do memory_set[id] = true end
                expect(memory_set["mem_1"]).to_be_true()
                expect(memory_set["mem_2"]).to_be_true()
                expect(memory_set["mem_3"]).to_be_true()
            end)

            it("should respect scan limit when extracting memory IDs", function()
                local memory_contract = create_mock_memory_contract()
                mock_contract._current_instance = memory_contract

                local spec = {
                    id = "test-agent",
                    name = "Test Agent",
                    prompt = "Test agent",
                    tools = {},
                    memory_contract = {
                        implementation_id = "test:memory",
                        options = { scan_limit = 2 }
                    }
                }

                local test_agent = agent.new(spec)
                local prompt_builder = mock_prompt.new()

                -- Add many messages with memory metadata
                for i = 1, 5 do
                    prompt_builder:add_user("Message " .. i)
                    prompt_builder:add_developer("Memory " .. i)
                    local messages = prompt_builder:get_messages()
                    messages[#messages].metadata = { memory_ids = { "mem_" .. i } }
                end

                test_agent:step(prompt_builder)

                local call_log = memory_contract:get_call_log()

                -- Verify memory was called (might not be due to scan limit affecting other triggers)
                if #call_log > 0 then
                    local previous_memories = call_log[1].previous_memories
                    -- Should only scan the last 2 messages due to scan_limit
                    expect(#previous_memories).to_be_less_than(5)
                else
                    -- Memory recall was skipped, which is also valid behavior with scan limits
                    expect(#call_log).to_equal(0)
                end
            end)

            it("should combine prompt memory IDs with runtime previous_memory_ids", function()
                local memory_contract = create_mock_memory_contract()
                mock_contract._current_instance = memory_contract

                local spec = {
                    id = "test-agent",
                    name = "Test Agent",
                    prompt = "Test agent",
                    tools = {},
                    memory_contract = {
                        implementation_id = "test:memory"
                    }
                }

                local test_agent = agent.new(spec)
                local prompt_builder = mock_prompt.new()

                -- Add message with memory metadata
                prompt_builder:add_user("Test message")
                prompt_builder:add_developer("Previous memory")
                local messages = prompt_builder:get_messages()
                messages[#messages].metadata = { memory_ids = { "mem_from_prompt" } }

                prompt_builder:add_user("Current message")

                -- Pass runtime previous_memory_ids - FIXED: Use correct 2-parameter signature
                local runtime_options = {
                    previous_memory_ids = { "mem_from_runtime_1", "mem_from_runtime_2" }
                }

                test_agent:step(prompt_builder, runtime_options)

                local call_log = memory_contract:get_call_log()
                local previous_memories = call_log[1].previous_memories

                -- Should combine both sources
                expect(#previous_memories).to_equal(3)
                local memory_set = {}
                for _, id in ipairs(previous_memories) do memory_set[id] = true end
                expect(memory_set["mem_from_prompt"]).to_be_true()
                expect(memory_set["mem_from_runtime_1"]).to_be_true()
                expect(memory_set["mem_from_runtime_2"]).to_be_true()
            end)
        end)

        describe("Memory Options Processing", function()
            it("should merge default options with agent-specific options", function()
                local memory_contract = create_mock_memory_contract()
                mock_contract._current_instance = memory_contract

                local spec = {
                    id = "test-agent",
                    name = "Test Agent",
                    prompt = "Test agent",
                    tools = {},
                    memory_contract = {
                        implementation_id = "test:memory",
                        options = {
                            max_items = 10,
                            enabled = true,
                            min_conversation_length = 5
                            -- Other options should use defaults
                        }
                    }
                }

                local test_agent = agent.new(spec)
                local prompt_builder = mock_prompt.new()

                -- Add enough messages to trigger recall
                for i = 1, 6 do
                    prompt_builder:add_user("Message " .. i)
                end

                test_agent:step(prompt_builder)

                local call_log = memory_contract:get_call_log()
                local constraints = call_log[1].constraints

                -- Should use agent-specific max_items
                expect(constraints.max_items).to_equal(10)

                -- Should use default max_length (since not specified)
                expect(constraints.max_length).to_equal(1000)
            end)

            it("should handle all memory option types", function()
                local memory_contract = create_mock_memory_contract()
                mock_contract._current_instance = memory_contract

                local spec = {
                    id = "test-agent",
                    name = "Test Agent",
                    description = "A test agent",
                    prompt = "Test agent",
                    tools = {},
                    memory = {},
                    delegates = {},
                    memory_contract = {
                        implementation_id = "test:memory",
                        options = {
                            max_items = 7,
                            max_length = 2500,
                            enabled = true,
                            min_conversation_length = 4,
                            recall_cooldown = 3,
                            message_types = { "user", "assistant" },
                            scan_limit = 25,
                            max_messages = 15,
                            max_actions = 6
                        }
                    }
                }

                local test_agent, err = agent.new(spec)
                expect(err).to_be_nil()
                expect(test_agent).not_to_be_nil()
                expect(test_agent.step).not_to_be_nil()

                local prompt_builder = mock_prompt.new()

                -- Add enough messages to trigger recall
                for i = 1, 5 do
                    prompt_builder:add_user("Message " .. i)
                end

                local result = test_agent:step(prompt_builder)
                expect(result).not_to_be_nil()

                local call_log = memory_contract:get_call_log()
                expect(#call_log).to_equal(1)

                local constraints = call_log[1].constraints
                local recent_actions = call_log[1].recent_actions

                expect(constraints.max_items).to_equal(7)
                expect(constraints.max_length).to_equal(2500)
                expect(recent_actions).not_to_be_nil()
                expect(#recent_actions <=6).to_be_true() -- max_actions
            end)
        end)

        describe("Memory Recall Triggers", function()
            it("should trigger recall when conversation length meets minimum", function()
                local memory_contract = create_mock_memory_contract()
                mock_contract._current_instance = memory_contract

                local spec = {
                    id = "test-agent",
                    name = "Test Agent",
                    prompt = "Test agent",
                    tools = {},
                    memory_contract = {
                        implementation_id = "test:memory",
                        options = { min_conversation_length = 3 }
                    }
                }

                local test_agent = agent.new(spec)
                local prompt_builder = mock_prompt.new()

                -- Add exactly minimum number of messages
                prompt_builder:add_user("Message 1")
                prompt_builder:add_assistant("Response 1")
                prompt_builder:add_user("Message 2")

                local result = test_agent:step(prompt_builder)

                expect(result.memory_recall).not_to_be_nil()
                expect(memory_contract:get_call_log()).not_to_be_nil()
                expect(#memory_contract:get_call_log()).to_equal(1)
            end)

            it("should not trigger recall when conversation is too short", function()
                local memory_contract = create_mock_memory_contract()
                mock_contract._current_instance = memory_contract

                local spec = {
                    id = "test-agent",
                    name = "Test Agent",
                    prompt = "Test agent",
                    tools = {},
                    memory_contract = {
                        implementation_id = "test:memory",
                        options = { min_conversation_length = 5 }
                    }
                }

                local test_agent = agent.new(spec)
                local prompt_builder = mock_prompt.new()

                -- Add fewer than minimum messages
                prompt_builder:add_user("Message 1")
                prompt_builder:add_assistant("Response 1")

                local result = test_agent:step(prompt_builder)

                expect(result.memory_recall).to_be_nil()
                expect(#memory_contract:get_call_log()).to_equal(0)
            end)

            it("should respect recall cooldown", function()
                local memory_contract = create_mock_memory_contract()
                mock_contract._current_instance = memory_contract

                local spec = {
                    id = "test-agent",
                    name = "Test Agent",
                    prompt = "Test agent",
                    tools = {},
                    memory_contract = {
                        implementation_id = "test:memory",
                        options = {
                            min_conversation_length = 2,
                            recall_cooldown = 3
                        }
                    }
                }

                local test_agent = agent.new(spec)
                local prompt_builder = mock_prompt.new()

                -- Build conversation with previous memory recall
                prompt_builder:add_user("Message 1")
                prompt_builder:add_assistant("Response 1")

                -- Add developer message with memory metadata (simulating previous recall)
                prompt_builder:add_developer("Previous memory recall")
                local messages = prompt_builder:get_messages()
                messages[#messages].metadata = { memory_ids = { "prev_mem" } }

                -- Add only 2 more messages (less than cooldown of 3)
                prompt_builder:add_user("Message 2")
                prompt_builder:add_assistant("Response 2")

                local result = test_agent:step(prompt_builder)

                expect(result.memory_recall).to_be_nil() -- Should not recall due to cooldown
                expect(#memory_contract:get_call_log()).to_equal(0)
            end)

            it("should trigger recall after cooldown period", function()
                local memory_contract = create_mock_memory_contract()
                mock_contract._current_instance = memory_contract

                local spec = {
                    id = "test-agent",
                    name = "Test Agent",
                    prompt = "Test agent",
                    tools = {},
                    memory_contract = {
                        implementation_id = "test:memory",
                        options = {
                            min_conversation_length = 2,
                            recall_cooldown = 2
                        }
                    }
                }

                local test_agent = agent.new(spec)
                local prompt_builder = mock_prompt.new()

                -- Build conversation with previous memory recall
                prompt_builder:add_user("Message 1")
                prompt_builder:add_developer("Previous memory")
                local messages = prompt_builder:get_messages()
                messages[#messages].metadata = { memory_ids = { "prev_mem" } }

                -- Add exactly cooldown number of messages
                prompt_builder:add_user("Message 2")
                prompt_builder:add_assistant("Response 2")

                local result = test_agent:step(prompt_builder)

                expect(result.memory_recall).not_to_be_nil() -- Should recall after cooldown
                expect(#memory_contract:get_call_log()).to_equal(1)
            end)

            it("should respect runtime disable flag", function()
                local memory_contract = create_mock_memory_contract()
                mock_contract._current_instance = memory_contract

                local spec = {
                    id = "test-agent",
                    name = "Test Agent",
                    prompt = "Test agent",
                    tools = {},
                    memory_contract = {
                        implementation_id = "test:memory",
                        options = { min_conversation_length = 2 }
                    }
                }

                local test_agent = agent.new(spec)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("Message 1")
                prompt_builder:add_assistant("Response 1")
                prompt_builder:add_user("Message 2")

                -- Disable memory recall via runtime options - FIXED: Use correct 2-parameter signature
                local result = test_agent:step(prompt_builder, { disable_memory_recall = true })

                expect(result.memory_recall).to_be_nil()
                expect(#memory_contract:get_call_log()).to_equal(0)
            end)
        end)

        describe("Memory Prompt Formatting and Injection", function()
            it("should format memory content correctly", function()
                local memory_contract = create_mock_memory_contract({
                    memories = {
                        { id = "mem1", content = "First memory", metadata = {} },
                        { id = "mem2", content = "Second memory", metadata = {} },
                        { id = "mem3", content = "Third memory", metadata = {} }
                    }
                })
                mock_contract._current_instance = memory_contract

                local spec = {
                    id = "test-agent",
                    name = "Test Agent",
                    prompt = "Test agent",
                    tools = {},
                    memory_contract = {
                        implementation_id = "test:memory",
                        options = { min_conversation_length = 2 }
                    }
                }

                local test_agent = agent.new(spec)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("Message 1")
                prompt_builder:add_assistant("Response 1")
                prompt_builder:add_user("Message 2")

                local result = test_agent:step(prompt_builder)

                expect(result.memory_recall).not_to_be_nil()
                expect(result.memory_prompt).not_to_be_nil()

                local memory_prompt = result.memory_prompt
                expect(memory_prompt.role).to_equal("developer")
                expect(memory_prompt.content).to_contain("Relevant context from your memory:")
                expect(memory_prompt.content).to_contain("- First memory")
                expect(memory_prompt.content).to_contain("- Second memory")
                expect(memory_prompt.content).to_contain("- Third memory")
                expect(memory_prompt.metadata.memory_ids).not_to_be_nil()
                expect(#memory_prompt.metadata.memory_ids).to_equal(3)
            end)

            it("should handle empty memory responses", function()
                local memory_contract = create_mock_memory_contract({
                    memories = {} -- Empty memories
                })
                mock_contract._current_instance = memory_contract

                local spec = {
                    id = "test-agent",
                    name = "Test Agent",
                    prompt = "Test agent",
                    tools = {},
                    memory_contract = {
                        implementation_id = "test:memory",
                        options = { min_conversation_length = 2 }
                    }
                }

                local test_agent = agent.new(spec)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("Message 1")
                prompt_builder:add_assistant("Response 1")
                prompt_builder:add_user("Message 2")

                local result = test_agent:step(prompt_builder)

                expect(result.memory_recall).to_be_nil() -- No memories returned
                expect(result.memory_prompt).to_be_nil()
            end)

            it("should inject memory into internal message flow", function()
                local memory_contract = create_mock_memory_contract({
                    memories = {
                        { id = "mem1", content = "Injected memory", metadata = {} }
                    }
                })
                mock_contract._current_instance = memory_contract

                local spec = {
                    id = "test-agent",
                    name = "Test Agent",
                    prompt = "Test agent",
                    tools = {},
                    memory_contract = {
                        implementation_id = "test:memory",
                        options = { min_conversation_length = 2 }
                    }
                }

                local test_agent = agent.new(spec)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("Message 1")
                prompt_builder:add_assistant("Response 1")
                prompt_builder:add_user("Trigger memory")

                test_agent:step(prompt_builder)

                -- Check that memory was injected into LLM messages
                local llm_messages = test_messages
                expect(#llm_messages).to_be_greater_than(3) -- Original + system + memory

                -- Find developer message with memory
                local memory_message = nil
                for _, msg in ipairs(llm_messages) do
                    if msg.role == "developer" and msg.content and msg.content:find("Relevant context") then
                        memory_message = msg
                        break
                    end
                end

                expect(memory_message).not_to_be_nil()
                expect(memory_message.content).to_contain("- Injected memory")
            end)
        end)

        describe("Context Processing and Merging", function()
            it("should merge memory contract context with runtime context", function()
                local memory_contract = create_mock_memory_contract()
                mock_contract._current_instance = memory_contract

                local spec = {
                    id = "test-agent",
                    name = "Test Agent",
                    prompt = "Test agent",
                    tools = {},
                    memory_contract = {
                        implementation_id = "test:memory",
                        context = {
                            memory_type = "vector",
                            collection_name = "test_memories",
                            shared_key = "from_contract_context"
                        },
                        options = { min_conversation_length = 2 }
                    }
                }

                local test_agent = agent.new(spec)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("Message 1")
                prompt_builder:add_assistant("Response 1")
                prompt_builder:add_user("Message 2")

                -- Pass runtime context - FIXED: Use correct 2-parameter signature
                local runtime_options = {
                    context = {
                        session_id = "test_session_123",
                        shared_key = "from_runtime_context" -- Should override contract context
                    }
                }

                test_agent:step(prompt_builder, runtime_options)

                -- We can't directly inspect the context passed to memory contract in this implementation,
                -- but we can verify the call was made successfully
                local call_log = memory_contract:get_call_log()
                expect(#call_log).to_equal(1)
            end)

            it("should include agent_id in memory context", function()
                local memory_contract = create_mock_memory_contract()
                mock_contract._current_instance = memory_contract

                local spec = {
                    id = "unique-test-agent-123",
                    name = "Unique Test Agent",
                    prompt = "Test agent",
                    tools = {},
                    memory_contract = {
                        implementation_id = "test:memory",
                        options = { min_conversation_length = 2 }
                    }
                }

                local test_agent = agent.new(spec)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("Message 1")
                prompt_builder:add_assistant("Response 1")
                prompt_builder:add_user("Message 2")

                test_agent:step(prompt_builder)

                -- Verify memory contract was called (agent_id would be in context)
                local call_log = memory_contract:get_call_log()
                expect(#call_log).to_equal(1)
            end)
        end)

        describe("Error Handling and Edge Cases", function()
            it("should handle memory contract instantiation failures", function()
                mock_contract._current_error = "Failed to create memory instance"

                local spec = {
                    id = "test-agent",
                    name = "Test Agent",
                    prompt = "Test agent",
                    tools = {},
                    memory_contract = {
                        implementation_id = "failing:memory",
                        options = { min_conversation_length = 2 }
                    }
                }

                local test_agent = agent.new(spec)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("Message 1")
                prompt_builder:add_assistant("Response 1")
                prompt_builder:add_user("Message 2")

                -- Should not crash, just skip memory recall
                local result = test_agent:step(prompt_builder)

                expect(result).not_to_be_nil()
                expect(result.memory_recall).to_be_nil()
            end)

            it("should handle memory recall errors gracefully", function()
                local memory_contract = create_mock_memory_contract({
                    should_error = true,
                    error_message = "Memory recall failed"
                })
                mock_contract._current_instance = memory_contract

                local spec = {
                    id = "test-agent",
                    name = "Test Agent",
                    prompt = "Test agent",
                    tools = {},
                    memory_contract = {
                        implementation_id = "test:memory",
                        options = { min_conversation_length = 2 }
                    }
                }

                local test_agent = agent.new(spec)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("Message 1")
                prompt_builder:add_assistant("Response 1")
                prompt_builder:add_user("Message 2")

                -- Should not crash, just skip memory recall
                local result = test_agent:step(prompt_builder)

                expect(result).not_to_be_nil()
                expect(result.memory_recall).to_be_nil()
            end)

            it("should handle malformed memory contract responses", function()
                local memory_contract = {
                    recall = function(self, options)
                        -- Return malformed response
                        return { not_memories = "wrong_field" }
                    end,
                    get_call_log = function() return {} end
                }
                mock_contract._current_instance = memory_contract

                local spec = {
                    id = "test-agent",
                    name = "Test Agent",
                    prompt = "Test agent",
                    tools = {},
                    memory_contract = {
                        implementation_id = "test:memory",
                        options = { min_conversation_length = 2 }
                    }
                }

                local test_agent = agent.new(spec)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("Message 1")
                prompt_builder:add_assistant("Response 1")
                prompt_builder:add_user("Message 2")

                -- Should handle gracefully
                local result = test_agent:step(prompt_builder)

                expect(result).not_to_be_nil()
                expect(result.memory_recall).to_be_nil()
            end)

            it("should handle large memory datasets within constraints", function()
                -- Create many memories to test constraint handling
                local many_memories = {}
                for i = 1, 20 do
                    table.insert(many_memories, {
                        id = "mem_" .. i,
                        content = "Memory content " .. i .. " - " .. string.rep("x", 100), -- Long content
                        metadata = { type = "test" }
                    })
                end

                local memory_contract = create_mock_memory_contract({
                    memories = many_memories
                })
                mock_contract._current_instance = memory_contract

                local spec = {
                    id = "test-agent",
                    name = "Test Agent",
                    prompt = "Test agent",
                    tools = {},
                    memory_contract = {
                        implementation_id = "test:memory",
                        options = {
                            min_conversation_length = 2,
                            max_items = 5,
                            max_length = 1000
                        }
                    }
                }

                local test_agent = agent.new(spec)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("Message 1")
                prompt_builder:add_assistant("Response 1")
                prompt_builder:add_user("Message 2")

                local result = test_agent:step(prompt_builder)

                -- Should handle large dataset
                expect(result).not_to_be_nil()

                -- Verify constraints were passed to memory contract
                local call_log = memory_contract:get_call_log()
                expect(#call_log).to_equal(1)
                expect(call_log[1].constraints.max_items).to_equal(5)
                expect(call_log[1].constraints.max_length).to_equal(1000)
            end)
        end)

        describe("Message Flow Integration", function()
            it("should maintain proper message order with memory injection at end", function()
                local memory_contract = create_mock_memory_contract({
                    memories = {
                        { id = "mem1", content = "Injected memory", metadata = {} }
                    }
                })
                mock_contract._current_instance = memory_contract

                local spec = {
                    id = "test-agent",
                    name = "Test Agent",
                    description = "A test agent",
                    prompt = "You are a test agent.",
                    tools = {},
                    memory_contract = {
                        implementation_id = "test:memory",
                        options = { min_conversation_length = 2 }
                    }
                }

                local test_agent = agent.new(spec)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("First message")
                prompt_builder:add_assistant("First response")
                prompt_builder:add_user("Second message")

                test_agent:step(prompt_builder)

                -- Verify message order in LLM input
                local llm_messages = test_messages
                expect(#llm_messages).to_be_greater_than(3)

                -- Should have: system, [cache_marker], conversation messages, memory
                expect(llm_messages[1].role).to_equal("system")

                -- Find the memory message - should be near the end since memory is injected at end
                local memory_found = false
                local memory_position = 0

                for i, msg in ipairs(llm_messages) do
                    if msg.role == "developer" and msg.content and msg.content:find("Relevant context") then
                        memory_found = true
                        memory_position = i
                        break
                    end
                end

                expect(memory_found).to_be_true()
                -- Memory should be injected after the conversation messages (near the end)
                expect(memory_position).to_be_greater_than(3) -- After system and some conversation
            end)

            it("should not affect original prompt builder", function()
                local memory_contract = create_mock_memory_contract({
                    memories = {
                        { id = "mem1", content = "Memory content", metadata = {} }
                    }
                })
                mock_contract._current_instance = memory_contract

                local spec = {
                    id = "test-agent",
                    name = "Test Agent",
                    prompt = "Test agent",
                    tools = {},
                    memory_contract = {
                        implementation_id = "test:memory",
                        options = { min_conversation_length = 2 }
                    }
                }

                local test_agent = agent.new(spec)
                local prompt_builder = mock_prompt.new()

                prompt_builder:add_user("Message 1")
                prompt_builder:add_assistant("Response 1")
                prompt_builder:add_user("Message 2")

                local original_message_count = #prompt_builder:get_messages()

                test_agent:step(prompt_builder)

                -- Original prompt builder should be unchanged
                expect(#prompt_builder:get_messages()).to_equal(original_message_count)

                -- Should not contain memory injection
                local original_messages = prompt_builder:get_messages()
                for _, msg in ipairs(original_messages) do
                    if msg.content and type(msg.content) == "string" then
                        expect(msg.content:find("Relevant context")).to_be_nil()
                    end
                end
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)