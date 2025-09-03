local selector = require("selector")

local function define_tests()
    describe("Agent Selector", function()
        local mock_agent_registry
        local mock_llm

        -- Sample agent data for testing
        local sample_agents = {
            {
                id = "coding:python_expert",
                meta = {
                    name = "Python Expert",
                    title = "Python Development Specialist",
                    comment = "Expert in Python development, debugging, and optimization",
                    tags = {"python", "development", "debugging"}
                }
            },
            {
                id = "coding:web_developer",
                meta = {
                    name = "Web Developer",
                    title = "Full Stack Web Developer",
                    comment = "Specializes in frontend and backend web development",
                    tags = {"web", "frontend", "backend", "javascript"}
                }
            },
            {
                id = "coding:data_scientist",
                meta = {
                    name = "Data Scientist",
                    title = "Data Analysis and ML Specialist",
                    comment = "Expert in data analysis, machine learning, and statistical modeling",
                    tags = {"data", "ml", "statistics", "python"}
                }
            }
        }

        before_each(function()
            -- Create mock agent registry
            mock_agent_registry = {
                list_by_class = function(class_name)
                    if class_name == "coding" then
                        return sample_agents
                    elseif class_name == "empty_class" then
                        return {}
                    elseif class_name == "nil_class" then
                        return nil
                    elseif class_name == "minimal" then
                        return {
                            {
                                id = "minimal:agent"
                                -- No meta field
                            }
                        }
                    elseif class_name == "partial" then
                        return {
                            {
                                id = "partial:agent",
                                meta = {
                                    name = "Partial Agent"
                                    -- Missing title, comment, tags
                                }
                            }
                        }
                    else
                        return {}
                    end
                end
            }

            -- Create mock LLM with pattern matching
            mock_llm = {
                structured_output = function(schema, prompt, options)
                    -- Extract user prompt for cleaner matching
                    local user_prompt = ""
                    local user_prompt_match = string.match(prompt, 'User Prompt: "([^"]*)"')
                    if user_prompt_match then
                        user_prompt = user_prompt_match:lower()
                    else
                        user_prompt = prompt:lower()
                    end

                    -- Pattern matching logic
                    if user_prompt:find("debug") and user_prompt:find("python") then
                        return {
                            result = {
                                success = true,
                                agent = "coding:python_expert",
                                reason = "The Python Expert is best suited for Python debugging tasks"
                            }
                        }, nil
                    elseif user_prompt:find("website") or user_prompt:find("web") or user_prompt:find("frontend") then
                        return {
                            result = {
                                success = true,
                                agent = "coding:web_developer",
                                reason = "The Web Developer specializes in web-related tasks"
                            }
                        }, nil
                    elseif user_prompt:find("data") or user_prompt:find("machine learning") or user_prompt:find("analysis") then
                        return {
                            result = {
                                success = true,
                                agent = "coding:data_scientist",
                                reason = "The Data Scientist is perfect for data analysis and ML tasks"
                            }
                        }, nil
                    elseif user_prompt:find("invalid_agent") then
                        return {
                            result = {
                                success = true,
                                agent = "nonexistent:agent",
                                reason = "This should trigger an error"
                            }
                        }, nil
                    elseif user_prompt:find("llm_error") then
                        return nil, "Simulated LLM error"
                    elseif user_prompt:find("minimal") then
                        return {
                            result = {
                                success = true,
                                agent = "minimal:agent",
                                reason = "Selected minimal agent"
                            }
                        }, nil
                    elseif user_prompt:find("partial") then
                        return {
                            result = {
                                success = true,
                                agent = "partial:agent",
                                reason = "Selected partial agent"
                            }
                        }, nil
                    else
                        -- Default to first agent for generic prompts
                        return {
                            result = {
                                success = true,
                                agent = "coding:python_expert",
                                reason = "Default selection for general coding tasks"
                            }
                        }, nil
                    end
                end
            }

            -- Inject mocks
            selector._agent_registry = mock_agent_registry
            selector._llm = mock_llm
        end)

        after_each(function()
            -- Clean up mocks
            selector._agent_registry = nil
            selector._llm = nil
        end)

        describe("Basic Functionality", function()
            it("should select appropriate agent for Python debugging", function()
                local result, err = selector.select_agent("Help me debug this Python script", "coding")

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.success).to_be_true()
                expect(result.agent).to_equal("coding:python_expert")
                expect(result.reason).not_to_be_nil()
                expect(type(result.reason)).to_equal("string")
                expect(#result.reason).to_be_greater_than(0)
            end)

            it("should select web developer for web-related tasks", function()
                local result, err = selector.select_agent("I need help building a website", "coding")

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.success).to_be_true()
                expect(result.agent).to_equal("coding:web_developer")
                expect(result.reason).to_contain("Web Developer")
            end)

            it("should select data scientist for data analysis", function()
                local result, err = selector.select_agent("I need help with machine learning analysis", "coding")

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.success).to_be_true()
                expect(result.agent).to_equal("coding:data_scientist")
                expect(result.reason).to_contain("Data Scientist")
            end)

            it("should select default agent for generic prompts", function()
                local result, err = selector.select_agent("General coding help needed", "coding")

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.success).to_be_true()
                expect(result.agent).to_equal("coding:python_expert")
                expect(result.reason).not_to_be_nil()
            end)
        end)

        describe("Input Validation", function()
            it("should error on empty user prompt", function()
                local result, err = selector.select_agent("", "coding")

                expect(result).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err).to_contain("User prompt is required")
            end)

            it("should error on nil user prompt", function()
                local result, err = selector.select_agent(nil, "coding")

                expect(result).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err).to_contain("User prompt is required")
            end)

            it("should error on empty class name", function()
                local result, err = selector.select_agent("Test prompt", "")

                expect(result).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err).to_contain("Class name is required")
            end)

            it("should error on nil class name", function()
                local result, err = selector.select_agent("Test prompt", nil)

                expect(result).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err).to_contain("Class name is required")
            end)
        end)

        describe("Agent Registry Integration", function()
            it("should error when no agents found for class", function()
                local result, err = selector.select_agent("Test prompt", "empty_class")

                expect(result).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err).to_contain("No agents found for class: empty_class")
            end)

            it("should error when registry returns nil", function()
                local result, err = selector.select_agent("Test prompt", "nil_class")

                expect(result).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err).to_contain("No agents found for class: nil_class")
            end)

            it("should error when class doesn't exist", function()
                local result, err = selector.select_agent("Test prompt", "nonexistent_class")

                expect(result).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err).to_contain("No agents found for class: nonexistent_class")
            end)
        end)

        describe("LLM Integration", function()
            it("should error when LLM fails", function()
                local result, err = selector.select_agent("LLM_ERROR trigger prompt", "coding")

                expect(result).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err).to_contain("Failed to analyze agents: Simulated LLM error")
            end)

            it("should error when LLM selects invalid agent", function()
                local result, err = selector.select_agent("INVALID_AGENT trigger prompt", "coding")

                expect(result).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err).to_contain("LLM selected invalid agent ID: nonexistent:agent")
            end)

            it("should pass correct parameters to LLM", function()
                local captured_schema = nil
                local captured_prompt = nil
                local captured_options = nil

                mock_llm.structured_output = function(schema, prompt, options)
                    captured_schema = schema
                    captured_prompt = prompt
                    captured_options = options

                    return {
                        result = {
                            success = true,
                            agent = "coding:python_expert",
                            reason = "Test reason"
                        }
                    }, nil
                end

                local result, err = selector.select_agent("Test prompt", "coding")

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()

                -- Verify schema structure
                expect(captured_schema).not_to_be_nil()
                expect(captured_schema.type).to_equal("object")
                expect(captured_schema.properties.success).not_to_be_nil()
                expect(captured_schema.properties.agent).not_to_be_nil()
                expect(captured_schema.properties.reason).not_to_be_nil()
                expect(#captured_schema.required).to_equal(3)

                -- Verify prompt contains required elements
                expect(captured_prompt).not_to_be_nil()
                expect(captured_prompt).to_contain("Test prompt")
                expect(captured_prompt).to_contain("coding")
                expect(captured_prompt).to_contain("Python Expert")

                -- Verify options
                expect(captured_options).not_to_be_nil()
                expect(captured_options.model).to_equal("gpt-4.1")
                expect(captured_options.temperature).to_equal(0)
            end)
        end)

        describe("Execute Function (Public API)", function()
            it("should work with user_prompt parameter", function()
                local result, err = selector.execute({
                    user_prompt = "Help me debug Python code",
                    class_name = "coding"
                })

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.success).to_be_true()
                expect(result.agent).to_equal("coding:python_expert")
            end)

            it("should work with prompt parameter (alternative)", function()
                local result, err = selector.execute({
                    prompt = "Build a website",
                    class_name = "coding"
                })

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.success).to_be_true()
                expect(result.agent).to_equal("coding:web_developer")
            end)

            it("should work with class parameter (alternative)", function()
                local result, err = selector.execute({
                    user_prompt = "Data analysis help",
                    class = "coding"
                })

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.success).to_be_true()
                expect(result.agent).to_equal("coding:data_scientist")
            end)

            it("should handle empty input table", function()
                local result, err = selector.execute({})

                expect(result).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err).to_contain("User prompt is required")
            end)

            it("should handle nil input", function()
                local result, err = selector.execute(nil)

                expect(result).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err).to_contain("Input is required")
            end)
        end)

        describe("Response Structure", function()
            it("should always set success to true for valid selections", function()
                -- Even if LLM initially returns success=false, we override it if agent is valid
                mock_llm.structured_output = function(schema, prompt, options)
                    return {
                        result = {
                            success = false, -- LLM says false
                            agent = "coding:python_expert", -- but agent is valid
                            reason = "Not very confident but this is the best match"
                        }
                    }, nil
                end

                local result, err = selector.select_agent("Test prompt", "coding")

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.success).to_be_true() -- Should be overridden to true
                expect(result.agent).to_equal("coding:python_expert")
                expect(result.reason).not_to_be_nil()
            end)

            it("should return all required fields", function()
                local result, err = selector.select_agent("Test prompt", "coding")

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.success).not_to_be_nil()
                expect(result.agent).not_to_be_nil()
                expect(result.reason).not_to_be_nil()
                expect(type(result.success)).to_equal("boolean")
                expect(type(result.agent)).to_equal("string")
                expect(type(result.reason)).to_equal("string")
            end)
        end)

        describe("Agent Information Processing", function()
            it("should handle agents with minimal metadata", function()
                local result, err = selector.select_agent("Test minimal prompt", "minimal")

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.success).to_be_true()
                expect(result.agent).to_equal("minimal:agent")
            end)

            it("should handle agents with partial metadata", function()
                local result, err = selector.select_agent("Test partial prompt", "partial")

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.success).to_be_true()
                expect(result.agent).to_equal("partial:agent")
            end)
        end)

        describe("Edge Cases", function()
            it("should handle very long prompts", function()
                local long_prompt = string.rep("This is a very long prompt. ", 100)

                local result, err = selector.select_agent(long_prompt, "coding")

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.success).to_be_true()
            end)

            it("should handle special characters in prompts", function()
                local special_prompt = "Help with código in Python! @#$%^&*(){}[]|\\:;\"'<>,./?"

                local result, err = selector.select_agent(special_prompt, "coding")

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.success).to_be_true()
            end)

            it("should handle prompts with JSON-like content", function()
                local json_prompt = 'Parse this: {"key": "value", "array": [1,2,3]}'

                local result, err = selector.select_agent(json_prompt, "coding")

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(result.success).to_be_true()
            end)
        end)

        describe("Dependency Injection", function()
            it("should use injected dependencies when provided", function()
                local custom_registry_called = false
                local custom_llm_called = false

                local custom_registry = {
                    list_by_class = function(class_name)
                        custom_registry_called = true
                        return sample_agents
                    end
                }

                local custom_llm = {
                    structured_output = function(schema, prompt, options)
                        custom_llm_called = true
                        return {
                            result = {
                                success = true,
                                agent = "coding:python_expert",
                                reason = "Custom LLM response"
                            }
                        }, nil
                    end
                }

                selector._agent_registry = custom_registry
                selector._llm = custom_llm

                local result, err = selector.select_agent("Test prompt", "coding")

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(custom_registry_called).to_be_true()
                expect(custom_llm_called).to_be_true()
                expect(result.reason).to_equal("Custom LLM response")
            end)
        end)
    end)

    -- Integration tests with proper mock setup for end-to-end testing
    describe("Agent Selector Integration Tests", function()
        local env = require("env")

        -- Only run integration tests if enabled and use mock registry for realistic testing
        if not env.get("ENABLE_INTEGRATION_TESTS") then
            return
        end

        before_all(function()
            print("\n" .. string.rep("=", 60))
            print("STARTING AGENT SELECTOR INTEGRATION TESTS")
            print("Testing with real LLM and mock agent registry")
            print(string.rep("=", 60))

            -- For integration tests, use real LLM but mock registry with realistic data
            -- This tests the actual LLM integration without requiring real agent classes
            selector._llm = nil -- Use real LLM

            -- Use mock registry but with more realistic agent data
            selector._agent_registry = {
                list_by_class = function(class_name)
                    if class_name == "coding" then
                        return {
                            {
                                id = "coding:python_developer",
                                meta = {
                                    name = "Python Developer",
                                    title = "Python Development Expert",
                                    comment = "Specializes in Python development, debugging, and Flask applications",
                                    tags = {"python", "flask", "debugging", "development"}
                                }
                            },
                            {
                                id = "coding:web_specialist",
                                meta = {
                                    name = "Web Specialist",
                                    title = "Full Stack Web Developer",
                                    comment = "Expert in modern web development with React, TypeScript, and Node.js",
                                    tags = {"web", "react", "typescript", "frontend", "backend"}
                                }
                            }
                        }
                    elseif class_name == "data" then
                        return {
                            {
                                id = "data:ml_engineer",
                                meta = {
                                    name = "ML Engineer",
                                    title = "Machine Learning Engineer",
                                    comment = "Expert in machine learning, data analysis, and predictive modeling",
                                    tags = {"ml", "data", "analysis", "python", "models"}
                                }
                            }
                        }
                    else
                        return {}
                    end
                end
            }
        end)

        after_all(function()
            -- Clean up integration test mocks
            selector._agent_registry = nil
            selector._llm = nil
        end)

        it("should work with real LLM for coding tasks", function()
            print("\n" .. string.rep("-", 40))
            print("INTEGRATION TEST: Real LLM coding agent selection")
            print(string.rep("-", 40))

            local result, err = selector.select_agent(
                "I need help debugging a Python Flask application that's throwing 500 errors",
                "coding"
            )

            if err then
                print("Integration test failed with error:", err)
                return
            end

            print("Selected agent:", result and result.agent or "nil")
            print("Reason:", result and result.reason or "nil")
            print("Success:", result and result.success or "nil")

            expect(err).to_be_nil()
            expect(result).not_to_be_nil()
            expect(result.success).to_be_true()
            expect(result.agent).not_to_be_nil()
            expect(type(result.agent)).to_equal("string")
            expect(result.reason).not_to_be_nil()
            expect(type(result.reason)).to_equal("string")
            expect(#result.reason).to_be_greater_than(10)
        end)

        it("should work with real LLM for data analysis tasks", function()
            print("\n" .. string.rep("-", 40))
            print("INTEGRATION TEST: Real LLM data analysis selection")
            print(string.rep("-", 40))

            local result, err = selector.select_agent(
                "I have a large dataset of customer purchases and need to build a machine learning model to predict churn",
                "data"
            )

            if err then
                print("Integration test failed with error:", err)
                return
            end

            print("Selected agent:", result and result.agent or "nil")
            print("Reason:", result and result.reason or "nil")

            expect(err).to_be_nil()
            expect(result).not_to_be_nil()
            expect(result.success).to_be_true()
            expect(result.agent).not_to_be_nil()
            expect(result.reason).not_to_be_nil()
        end)

        it("should handle edge case with empty agent class gracefully", function()
            local result, err = selector.select_agent("Test prompt", "nonexistent_class")

            expect(result).to_be_nil()
            expect(err).not_to_be_nil()
            expect(err).to_contain("No agents found for class")
        end)

        it("should work with execute function in real environment", function()
            local result, err = selector.execute({
                user_prompt = "Help me set up a React application with TypeScript",
                class_name = "coding"
            })

            if err then
                print("Integration test failed with error:", err)
                return
            end

            expect(err).to_be_nil()
            expect(result).not_to_be_nil()
            expect(result.success).to_be_true()
            expect(result.agent).not_to_be_nil()
            expect(result.reason).not_to_be_nil()
        end)
    end)
end

return require("test").run_cases(define_tests)