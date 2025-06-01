local agent = require("agent")
local prompt = require("prompt")
local llm = require("llm")
local registry = require("agent_registry")
local json = require("json")
local time = require("time")
local env = require("env")

local function define_tests()
    describe("Agent Library", function()
        local mock_llm
        local mock_prompt
        local mock_time

        -- Sample agent specification for testing - updated with new delegate format
        local test_agent_spec = {
            id = "test-agent",
            name = "Test Agent",
            description = "A test agent for unit testing",
            model = "gpt-4o-mini",
            prompt = "You are a test agent designed for unit testing.",
            tools = { "test:calculator" },
            traits = {},
            memory = { "You were created for testing purposes" },
            delegates = {
                {
                    id = "data-analyst-id",
                    name = "to_data_analyst",
                    rule = "Forward to this agent when you detect data analysis questions"
                }
            }
        }

        -- Create a calculator tool schema
        local calculator_schema = {
            name = "calculator",
            description = "Perform mathematical calculations",
            schema = {
                type = "object",
                properties = {
                    expression = {
                        type = "string",
                        description = "The mathematical expression to evaluate"
                    }
                },
                required = { "expression" }
            }
        }

        before_each(function()
            -- Create mock LLM module
            mock_llm = {
                generate = function(messages, options)
                    -- Check if tool_ids contains "test:calculator"
                    local has_calculator_tool = false
                    if options.tool_ids then
                        for _, tool_id in ipairs(options.tool_ids) do
                            if tool_id == "test:calculator" then
                                has_calculator_tool = true
                                break
                            end
                        end
                    end

                    -- Get the last message for contextual responses
                    local last_message = messages[#messages]

                    -- Standard response for normal queries
                    if not has_calculator_tool then
                        return {
                            result = "This is a test response.",
                            tokens = {
                                prompt_tokens = 10,
                                completion_tokens = 5,
                                thinking_tokens = 0,
                                total_tokens = 15
                            },
                            finish_reason = "stop"
                        }
                    else
                        -- If calculator tool is available, simulate tool calling
                        if last_message.role == "user" and last_message.content[1].text:lower():match("calculat") then
                            return {
                                result = "I'll help you calculate that.",
                                tool_calls = {
                                    {
                                        id = "call_123",
                                        name = "test:calculator",
                                        arguments = {
                                            expression = "123 * 456"
                                        }
                                    }
                                },
                                tokens = {
                                    prompt_tokens = 15,
                                    completion_tokens = 10,
                                    thinking_tokens = 0,
                                    total_tokens = 25
                                },
                                finish_reason = "tool_call"
                            }
                        end

                        -- If delegate tool is available and detected, simulate delegate delegation
                        if options.tool_schemas and options.tool_schemas["to_data_analyst"] and
                            last_message.role == "user" and
                            last_message.content[1].text:lower():match("analyze") then
                            return {
                                result = "I'll delegate this to our data analyst.",
                                tool_calls = {
                                    {
                                        id = "call_456",
                                        name = "to_data_analyst",
                                        arguments = {
                                            message = "Please analyze this data"
                                        }
                                    }
                                },
                                tokens = {
                                    prompt_tokens = 20,
                                    completion_tokens = 15,
                                    thinking_tokens = 0,
                                    total_tokens = 35
                                },
                                finish_reason = "tool_call"
                            }
                        end

                        -- Default response if no special condition is met
                        return {
                            result = "This is a test response.",
                            tokens = {
                                prompt_tokens = 10,
                                completion_tokens = 5,
                                thinking_tokens = 0,
                                total_tokens = 15
                            },
                            finish_reason = "stop"
                        }
                    end
                end
            }

            -- Create mock prompt module for testing
            mock_prompt = {
                new = function()
                    local messages = {}

                    return {
                        add_system = function(self, content)
                            table.insert(messages, {
                                role = "system",
                                content = { { type = "text", text = content } }
                            })
                            return self
                        end,
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
                            local content = result
                            if type(result) ~= "string" then
                                content = json.encode(result)
                            end

                            table.insert(messages, {
                                role = "function",
                                name = name,
                                content = { { type = "text", text = content } },
                                function_call_id = id
                            })
                            return self
                        end,
                        add_message = function(self, role, content)
                            table.insert(messages, {
                                role = role,
                                content = content
                            })
                            return self
                        end,
                        get_messages = function()
                            return messages
                        end
                    }
                end
            }

            -- Inject mocks
            agent._llm = mock_llm
            agent._prompt = mock_prompt
        end)

        after_each(function()
            -- Cleanup mocks
            agent._llm = nil
            agent._prompt = nil
        end)

        it("should create an agent from specification", function()
            local test_agent = agent.new(test_agent_spec)

            expect(test_agent).not_to_be_nil()
            expect(test_agent.id).to_equal("test-agent")
            expect(test_agent.name).to_equal("Test Agent")
            expect(test_agent.model).to_equal("gpt-4o-mini")
        end)

        it("should handle basic conversation", function()
            local test_agent = agent.new(test_agent_spec)

            -- Create a prompt builder
            local prompt_builder = mock_prompt.new()

            -- Add a user message
            prompt_builder:add_user("Hello")

            -- Execute the agent with the external prompt
            local result = test_agent:step(prompt_builder)

            -- Verify result
            expect(result).not_to_be_nil()
            expect(result.result).to_equal("This is a test response.")

            -- Check token tracking
            expect(result.tokens.prompt_tokens).to_equal(10)
            expect(result.tokens.completion_tokens).to_equal(5)
            expect(result.tokens.total_tokens).to_equal(15)

            -- Add the response to conversation and create a follow-up
            prompt_builder:add_assistant(result.result)
            prompt_builder:add_user("How are you?")

            -- Execute again
            local result2 = test_agent:step(prompt_builder)
            expect(result2).not_to_be_nil()
            expect(result2.result).to_equal("This is a test response.")

            -- Get conversation statistics (if still supported)
            local stats = test_agent:get_stats()
            expect(stats.id).to_equal("test-agent")
        end)

        it("should handle tool calls", function()
            local test_agent = agent.new(test_agent_spec)

            -- Create a prompt builder
            local prompt_builder = mock_prompt.new()

            -- Add a user message that will trigger tool calling
            prompt_builder:add_user("Calculate 123 * 456")

            -- Execute the agent
            local result = test_agent:step(prompt_builder)

            -- Verify tool calls
            expect(result.tool_calls).not_to_be_nil()
            expect(#result.tool_calls).to_equal(1)
            expect(result.tool_calls[1].name).to_equal("test:calculator")
            expect(result.tool_calls[1].arguments.expression).to_equal("123 * 456")

            -- Add the response and tool call to the conversation
            prompt_builder:add_assistant(result.result)
            prompt_builder:add_function_call(
                "test:calculator",
                { expression = "123 * 456" },
                result.tool_calls[1].id
            )

            -- Add function result
            prompt_builder:add_function_result(
                "test:calculator",
                { result = 56088 },
                result.tool_calls[1].id
            )

            -- Execute again to get response with tool result
            local final_result = test_agent:step(prompt_builder)
            expect(final_result.result).not_to_be_nil()
        end)

        it("should handle delegate delegation", function()
            local test_agent = agent.new(test_agent_spec)

            -- Create a prompt builder
            local prompt_builder = mock_prompt.new()

            -- Add a user message that will trigger delegate
            prompt_builder:add_user("Analyze this dataset for me")

            -- Execute the agent
            local result = test_agent:step(prompt_builder)

            -- Verify delegate information
            expect(result.delegate_target).not_to_be_nil()
            expect(result.delegate_target).to_equal("data-analyst-id")
            expect(result.delegate_message).to_equal("Please analyze this data")

            -- Handout tool calls should be intercepted (replaced with delegate info)
            expect(result.tool_calls).to_be_nil()
        end)

        it("should require name for delegates", function()
            -- Create an agent spec with a delegate missing a name
            local invalid_agent_spec = {
                id = "invalid-agent",
                name = "Invalid Agent",
                description = "An agent with invalid delegate configuration",
                model = "gpt-4o-mini",
                prompt = "You are an invalid test agent.",
                tools = {},
                traits = {},
                memory = {},
                delegates = {
                    {
                        id = "some-agent-id",
                        -- Missing name field
                        rule = "This will fail"
                    }
                }
            }

            -- This should throw an error
            local success, err = pcall(function()
                local agent_instance = agent.new(invalid_agent_spec)
                -- Force delegate tools generation if it's not done in new()
                agent_instance:_generate_delegate_tools()
            end)

            expect(success).to_be_false("Should fail when delegate is missing a name field")
            expect(tostring(err):match("Handout name is required")).not_to_be_nil(
            "Error should mention the missing name")
        end)

        -- Integration test with real LLM
        it("should integrate with real LLM when not mocked", function()
            -- Skip if agent still has mocked llm
            if agent._llm then return end

            -- Create real agent
            local test_agent = agent.new(test_agent_spec)

            -- Create a prompt builder
            local prompt_builder = prompt.new()

            -- Add a simple user message
            prompt_builder:add_user("Hello, what are you?")

            -- Execute with error handling
            local result, err = test_agent:step(prompt_builder)
            if err then
                print("Integration test error: " .. err)
                return
            end

            -- Output should contain something about being a test agent
            expect(result).not_to_be_nil()
            expect(result.result).not_to_be_nil()
            expect(result.result:lower():match("test agent")).not_to_be_nil()
        end)
    end)

    describe("Agent Real Integration", function()
        if not env.get("ENABLE_INTEGRATION_TESTS") then
            return
        end

        -- Clear any mocks before integration tests
        before_all(function()
            agent._llm = nil
            agent._prompt = nil
            agent._time = nil
        end)

        -- Real integration test with gpt-4o-mini
        it("should perform conversation with real gpt-4o-mini", function()
            local real_agent_spec = {
                id = "integration-test-agent",
                name = "Integration Test Agent",
                description = "An agent for real integration testing",
                model = "gpt-4o-mini",
                prompt = "You are a helpful assistant designed for integration testing. You are concise but helpful.",
                tools = {},
                traits = {},
                memory = {}
            }

            -- Create agent
            local test_agent = agent.new(real_agent_spec)
            expect(test_agent).not_to_be_nil()

            -- Create a prompt builder
            local prompt_builder = prompt.new()

            -- Add a simple user message
            prompt_builder:add_user("Tell me a very short joke about programming")

            -- Run a simple conversation
            local result = test_agent:step(prompt_builder)

            -- Verify response
            expect(result).not_to_be_nil()
            expect(result.result).not_to_be_nil()
            expect(#result.result > 10).to_be_true() -- Ensure there's a real response

            -- Display result for debugging
            print("GPT-4o-mini response: " .. result.result)

            -- Get and print stats
            local stats = test_agent:get_stats()
            print("Total tokens: " .. stats.total_tokens.total)

            -- Continue conversation
            prompt_builder:add_assistant(result.result)
            prompt_builder:add_user("Explain why that joke is funny in two sentences.")

            local result2 = test_agent:step(prompt_builder)
            expect(result2).not_to_be_nil()
            expect(result2.result).not_to_be_nil()

            -- Display result for debugging
            print("Follow-up response: " .. result2.result)
        end)

        -- Integration test with tool calling
        it("should handle tool calls with real model", function()
            -- Get API keys from environment
            local openai_api_key = env.get("OPENAI_API_KEY")
            if not openai_api_key or #openai_api_key < 10 then
                print("Skipping tool calling test: No valid OpenAI API key found")
                return
            end

            -- Define calculator tool schema
            local calculator_schema = {
                name = "calculator",
                description = "Perform mathematical calculations",
                schema = {
                    type = "object",
                    properties = {
                        expression = {
                            type = "string",
                            description = "The mathematical expression to evaluate"
                        }
                    },
                    required = { "expression" }
                }
            }

            -- Create agent
            local test_agent = agent.new({
                id = "calculator-test-agent",
                name = "Calculator Test Agent",
                description = "An agent for testing tool calls",
                model = "gpt-4o-mini",
                prompt =
                "You are a helpful assistant that can perform calculations. Always use the calculator tool for math problems.",
                tools = {}, -- Empty tools list - we'll use inline tools instead
                traits = {},
                memory = {}
            })

            -- Register the calculator tool directly
            test_agent:register_tool("calculator", calculator_schema)

            -- Create a prompt builder
            local prompt_builder = prompt.new()

            -- Add a user message
            prompt_builder:add_user("What is 123 * 456?")

            -- Calculator function handler
            local function handle_calculator_tool(expression)
                -- Simple calculator that evaluates basic math expressions
                if expression == "123 * 456" then
                    return { result = 56088 }
                elseif expression == "123 + 456" then
                    return { result = 579 }
                elseif expression == "123 - 456" then
                    return { result = -333 }
                elseif expression == "456 / 123" then
                    return { result = 3.7073 }
                else
                    return { error = "Expression not supported in test calculator" }
                end
            end

            -- Process conversation with tools
            local result, err = test_agent:step(prompt_builder)
            expect(err).to_be_nil()

            -- If no tool calls, just print the response and skip the rest
            if not result.tool_calls or #result.tool_calls == 0 then
                print("No tool calls made. Response: " .. (result.result or "None"))
                return
            end

            -- Handle tool calls
            prompt_builder:add_assistant(result.result)

            for _, tool_call in ipairs(result.tool_calls) do
                print("Tool called: " .. tool_call.name)

                prompt_builder:add_function_call(tool_call.name, tool_call.arguments, tool_call.id)

                -- Process the calculator call
                local tool_result
                if tool_call.name == "calculator" then
                    tool_result = handle_calculator_tool(tool_call.arguments.expression)
                else
                    tool_result = { error = "Unknown tool" }
                end

                -- Add the result back to conversation
                prompt_builder:add_function_result(tool_call.name, tool_result, tool_call.id)
            end

            -- Get final response with tool output incorporated
            local final_result, err = test_agent:step(prompt_builder)
            expect(err).to_be_nil("Error processing conversation")
            expect(final_result).not_to_be_nil()
            expect(final_result.result).not_to_be_nil()

            -- Response should contain the calculation result (56088)
            print("Final response: " .. final_result.result)
            expect(final_result.result:match("56088") or
                final_result.result:match("56,088")).not_to_be_nil()
        end)

        -- Integration test with delegate delegation
        it("should handle delegate mechanism with real model", function()
            -- Skip if integration tests are disabled or no API key
            if not env.get("ENABLE_INTEGRATION_TESTS") then
                return
            end

            local openai_api_key = env.get("OPENAI_API_KEY")
            if not openai_api_key or #openai_api_key < 10 then
                print("Skipping delegate test: No valid OpenAI API key found")
                return
            end

            -- Create parent agent with very explicit delegation instruction
            local parent_agent_spec = {
                id = "parent-agent",
                name = "Parent Agent",
                description = "An agent that delegates tasks",
                model = "gpt-4o-mini",
                prompt = "You are a coordinator that delegates tasks. ALWAYS use the to_data_analyst " ..
                    "tool when you receive ANY statistics questions.",
                tools = {},
                traits = {},
                memory = {},
                delegates = {
                    {
                        id = "data-analyst-id",
                        name = "to_data_analyst",
                        rule = "ALWAYS use for statistics questions"
                    }
                }
            }

            -- Create data analyst agent
            local data_analyst_spec = {
                id = "data-analyst-id",
                name = "Data Analyst",
                description = "Statistics expert",
                model = "gpt-4o-mini",
                prompt = "You are a statistics expert.",
                tools = {},
                traits = {},
                memory = {}
            }

            -- Create registry and register agents
            local test_registry = {
                agents = {},
                register = function(self, agent_spec)
                    local test_agent = agent.new(agent_spec)
                    self.agents[agent_spec.id] = test_agent
                    return test_agent
                end,
                get = function(self, agent_id)
                    return self.agents[agent_id]
                end
            }

            local parent = test_registry:register(parent_agent_spec)
            local analyst = test_registry:register(data_analyst_spec)

            -- Create prompt builders
            local parent_prompt = prompt.new()
            local analyst_prompt = prompt.new()

            -- Test the delegation mechanism
            parent_prompt:add_user("What is the correlation coefficient in statistics?")
            local result, err = parent:step(parent_prompt)

            -- Only verify basic error handling
            expect(err).to_be_nil("Error in conversation")
            expect(result).not_to_be_nil("Result is nil")

            -- If delegation occurred, verify the mechanism works correctly
            if result.delegate_target then
                print("Delegation occurred to: " .. result.delegate_target)

                -- Verify target agent exists
                local target_agent = test_registry:get(result.delegate_target)
                expect(target_agent).not_to_be_nil("Target agent not found")

                -- Process the delegate with the target agent
                analyst_prompt:add_user(result.delegate_message)
                local specialist_result = target_agent:step(analyst_prompt)

                -- Verify we got a response from the specialist
                expect(specialist_result).not_to_be_nil("Specialist result is nil")
                expect(specialist_result.result).not_to_be_nil("No response from specialist")

                -- Close the loop by sending response back to parent
                parent_prompt:add_assistant("Delegated to specialist: " .. specialist_result.result)

                print("Delegation test passed")
            else
                print("No delegation occurred - this is acceptable for a real LLM test")
                print("Agent response: " .. result.result:sub(1, 100) .. "...")
            end
        end)
    end)
end

return require("test").run_cases(define_tests)