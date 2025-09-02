local generate_handler = require("generate_handler")
local structured_output_handler = require("structured_output_handler")
local status_handler = require("status_handler")
local json = require("json")
local env = require("env")
local ctx = require("ctx")

local function define_tests()
    -- Toggle to enable/disable real API integration tests
    local RUN_INTEGRATION_TESTS = env.get("ENABLE_INTEGRATION_TESTS")

    describe("Claude Integration Tests", function()
        local actual_api_key = nil

        before_all(function()
            -- Check if we have a real API key for integration tests
            actual_api_key = env.get("ANTHROPIC_API_KEY")

            if RUN_INTEGRATION_TESTS then
                if actual_api_key and #actual_api_key > 10 then
                    print("Integration tests will run with real Claude API key")
                else
                    print("Integration tests disabled - no valid Claude API key found")
                    RUN_INTEGRATION_TESTS = false
                end
            else
                print("Integration tests disabled - set ENABLE_INTEGRATION_TESTS=true to enable")
            end
        end)

        before_each(function()
            -- Set up context with API key for each test
            if actual_api_key then
                generate_handler._client._ctx = {
                    all = function()
                        return { api_key = actual_api_key }
                    end
                }

                structured_output_handler._client._ctx = {
                    all = function()
                        return { api_key = actual_api_key }
                    end
                }

                -- Mock env dependency (return nil for environment lookups)
                generate_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                structured_output_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }
            end
        end)

        after_each(function()
            -- Clean up mocked dependencies
            generate_handler._client._ctx = nil
            generate_handler._client._env = nil
            generate_handler._output = nil

            structured_output_handler._client._ctx = nil
            structured_output_handler._client._env = nil
        end)

        describe("Text Generation Integration", function()
            it("should generate text with claude-3-haiku (base model)", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping integration test - not enabled")
                    return
                end

                local contract_args = {
                    model = "claude-3-haiku-20240307",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "Reply with exactly 'Integration test successful'" }}
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 10
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content).to_contain("Integration test successful")
                expect(response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens reported")
                expect(response.tokens.completion_tokens > 0).to_be_true("No completion tokens reported")
                expect(response.tokens.total_tokens > 0).to_be_true("No total tokens reported")
                expect(response.finish_reason).to_equal("stop")
            end)

            it("should generate text with claude-3-5-sonnet for complex reasoning", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping sonnet reasoning test - not enabled")
                    return
                end

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        {
                            role = "user",
                            content = {{
                                type = "text",
                                text = "Think step by step: If a train travels 60 mph for 2 hours, then 40 mph for 1 hour, what's the total distance? Show your reasoning."
                            }}
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 200
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_true("Sonnet reasoning request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content).to_contain("160")  -- 120 + 40 = 160 miles
                expect(response.result.content:lower()).to_contain("step")  -- Should show step-by-step reasoning
                expect(response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens reported")
                expect(response.tokens.completion_tokens > 0).to_be_true("No completion tokens reported")
                expect(response.finish_reason).to_equal("stop")
            end)

            it("should handle system messages in text generation", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping system message test - not enabled")
                    return
                end

                local contract_args = {
                    model = "claude-3-haiku-20240307",
                    messages = {
                        {
                            role = "system",
                            content = {{ type = "text", text = "You are a helpful assistant who responds with enthusiasm. Always start with 'Absolutely!'" }}
                        },
                        {
                            role = "user",
                            content = {{ type = "text", text = "Can you help me?" }}
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 20
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content).to_contain("Absolutely")
            end)

            it("should generate text with tool calling using haiku", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping tool calling test - not enabled")
                    return
                end

                local contract_args = {
                    model = "claude-3-haiku-20240307",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "Calculate 15 * 7 using the calculator" }}
                        }
                    },
                    tools = {
                        {
                            name = "calculate",
                            description = "Perform mathematical calculations",
                            schema = {
                                type = "object",
                                properties = {
                                    expression = { type = "string", description = "Mathematical expression" }
                                },
                                required = { "expression" }
                            }
                        }
                    },
                    tool_choice = "calculate",
                    options = {
                        temperature = 0
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.tool_calls).not_to_be_nil("No tool calls in response")
                expect(#response.result.tool_calls > 0).to_be_true("Expected at least one tool call")
                expect(response.result.tool_calls[1].name).to_equal("calculate")
                expect(response.result.tool_calls[1].arguments.expression).to_contain("15")
                expect(response.result.tool_calls[1].arguments.expression).to_contain("7")
                expect(response.finish_reason).to_equal("tool_call")
            end)

            it("should handle multiple tool calls with sonnet", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping multiple tool calls test - not enabled")
                    return
                end

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "What's the weather in London and calculate 20 * 30?" }}
                        }
                    },
                    tools = {
                        {
                            name = "get_weather",
                            description = "Get weather information",
                            schema = {
                                type = "object",
                                properties = {
                                    location = { type = "string" }
                                },
                                required = { "location" }
                            }
                        },
                        {
                            name = "calculate",
                            description = "Perform calculations",
                            schema = {
                                type = "object",
                                properties = {
                                    expression = { type = "string" }
                                },
                                required = { "expression" }
                            }
                        }
                    },
                    options = {
                        temperature = 0
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_true("Multiple tool calls failed: " .. (response.error_message or "unknown error"))
                expect(response.result.tool_calls).not_to_be_nil("No tool calls in response")
                expect(#response.result.tool_calls > 0).to_be_true("Expected at least one tool call")
            end)

            it("should handle streaming generation with haiku", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping streaming test - not enabled")
                    return
                end

                -- Mock the output module for streaming since we can't test real streaming easily
                local mock_streamer = {
                    buffer_content = function(self, chunk) end,
                    send_tool_call = function(self, name, args, id) end,
                    send_error = function(self, error, message) end,
                    flush = function(self) end
                }

                generate_handler._output = {
                    streamer = function(reply_to, topic, buffer_size)
                        return mock_streamer
                    end
                }

                local contract_args = {
                    model = "claude-3-haiku-20240307",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "Count from 1 to 5 separated by spaces" }}
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 20
                    },
                    stream = {
                        reply_to = "integration-test-pid",
                        topic = "integration_stream"
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_true("API request failed: " .. (response.error_message or "unknown error"))
                expect(response.result.content).to_contain("1")
                expect(response.result.content).to_contain("5")
                expect(response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens reported")
                expect(response.finish_reason).to_equal("stop")
            end)

            it("should handle complex reasoning with sonnet", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping complex reasoning test - not enabled")
                    return
                end

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        {
                            role = "user",
                            content = {{
                                type = "text",
                                text = "Solve this logic puzzle: In a room with 5 people, each person shakes hands exactly once with every other person. How many handshakes occur? Think through this step by step."
                            }}
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 300
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_true("Complex reasoning failed: " .. (response.error_message or "unknown"))
                expect(response.result.content).to_contain("10")  -- Answer: 5*4/2 = 10 handshakes
                expect(response.result.content:lower()).to_contain("step")  -- Should show reasoning steps
                expect(response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens")
                expect(response.tokens.completion_tokens > 0).to_be_true("No completion tokens")
            end)
        end)

        describe("Streaming Integration Tests", function()
            it("should stream simple text generation with haiku", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping streaming test - not enabled")
                    return
                end

                local streaming_events = {}
                local mock_streamer = {
                    buffer_content = function(self, chunk)
                        table.insert(streaming_events, {type = "content", data = chunk})
                    end,
                    send_tool_call = function(self, name, args, id) end,
                    send_error = function(self, error, message) end,
                    flush = function(self) end
                }

                generate_handler._output = {
                    streamer = function(reply_to, topic, buffer_size)
                        return mock_streamer
                    end
                }

                local contract_args = {
                    model = "claude-3-haiku-20240307",
                    messages = {
                        {
                            role = "user",
                            content = {{type = "text", text = "Count from 1 to 5, separated by commas"}}
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 50
                    },
                    stream = {
                        reply_to = "test-streaming-pid",
                        topic = "test_basic_stream"
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_true("Streaming request failed: " .. (response.error_message or "unknown"))
                expect(response.result.content).not_to_be_nil("No content in streaming response")
                expect(response.result.content).to_contain("1")
                expect(response.result.content).to_contain("5")

                -- Verify streaming events occurred
                local content_events = 0
                for _, event in ipairs(streaming_events) do
                    if event.type == "content" then
                        content_events = content_events + 1
                    end
                end
                expect(content_events > 0).to_be_true("No content streaming events occurred")

                expect(response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens")
                expect(response.tokens.completion_tokens > 0).to_be_true("No completion tokens")
                expect(response.finish_reason).to_equal("stop")
            end)

            it("should stream tool calls with sonnet", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping streaming tool call test - not enabled")
                    return
                end

                local streaming_events = {}
                local mock_streamer = {
                    buffer_content = function(self, chunk)
                        table.insert(streaming_events, {type = "content", data = chunk})
                    end,
                    send_tool_call = function(self, name, args, id)
                        table.insert(streaming_events, {type = "tool_call", name = name, args = args, id = id})
                    end,
                    send_error = function(self, error, message) end,
                    flush = function(self) end
                }

                generate_handler._output = {
                    streamer = function(reply_to, topic, buffer_size)
                        return mock_streamer
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        {
                            role = "user",
                            content = {{type = "text", text = "Calculate the area of a circle with radius 10cm"}}
                        }
                    },
                    tools = {
                        {
                            name = "calculate",
                            description = "Perform mathematical calculations",
                            schema = {
                                type = "object",
                                properties = {
                                    expression = {type = "string", description = "Mathematical expression"}
                                },
                                required = {"expression"}
                            }
                        }
                    },
                    options = {
                        temperature = 0
                    },
                    stream = {
                        reply_to = "test-tool-streaming-pid",
                        topic = "test_tool_stream"
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_true("Streaming tool call failed: " .. (response.error_message or "unknown"))
                expect(response.result.tool_calls).not_to_be_nil("No tool calls in response")
                expect(#response.result.tool_calls > 0).to_be_true("Expected at least one tool call")

                local tool_call = response.result.tool_calls[1]
                expect(tool_call.name).to_equal("calculate")
                expect(tool_call.arguments.expression).not_to_be_nil("No expression in tool call")

                -- Verify streaming events
                local tool_call_events = 0
                for _, event in ipairs(streaming_events) do
                    if event.type == "tool_call" then
                        tool_call_events = tool_call_events + 1
                    end
                end
                expect(tool_call_events > 0).to_be_true("No tool call streaming events occurred")

                expect(response.finish_reason).to_equal("tool_call")
            end)

            it("should handle streaming complex reasoning with sonnet", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping sonnet streaming reasoning test - not enabled")
                    return
                end

                local mock_streamer = {
                    buffer_content = function(self, chunk) end,
                    send_tool_call = function(self, name, args, id) end,
                    send_error = function(self, error, message) end,
                    flush = function(self) end
                }

                generate_handler._output = {
                    streamer = function(reply_to, topic, buffer_size)
                        return mock_streamer
                    end
                }

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        {
                            role = "user",
                            content = {{type = "text", text = "Think step by step: If I have 3 apples and buy 5 more, then give away 2, how many do I have left? Show your reasoning."}}
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 200
                    },
                    stream = {
                        reply_to = "test-reasoning-streaming-pid",
                        topic = "test_reasoning_stream"
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_true("Sonnet streaming reasoning failed: " .. (response.error_message or "unknown"))
                expect(response.result.content).not_to_be_nil("No content in response")
                expect(response.result.content).to_contain("6")  -- 3 + 5 - 2 = 6
                expect(response.result.content:lower()).to_contain("step")  -- Should show reasoning
                expect(response.finish_reason).to_equal("stop")
            end)
        end)

        describe("Structured Output Integration", function()
            it("should generate structured output with haiku", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping structured output test - not enabled")
                    return
                end

                local contract_args = {
                    model = "claude-3-haiku-20240307",
                    messages = {
                        {
                            role = "user",
                            content = {{
                                type = "text",
                                text = "Create a fictional person profile with name, age, and occupation. Return as JSON."
                            }}
                        }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            name = { type = "string" },
                            age = { type = "number" },
                            occupation = { type = "string" }
                        },
                        required = { "name", "age", "occupation" },
                        additionalProperties = false
                    },
                    options = {
                        temperature = 0
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_true("Structured output failed: " .. (response.error_message or "unknown error"))
                expect(response.result.data).not_to_be_nil("No structured data in response")
                expect(response.result.data.name).not_to_be_nil("Missing name in structured output")
                expect(type(response.result.data.name)).to_equal("string", "Name should be string")
                expect(response.result.data.age).not_to_be_nil("Missing age in structured output")
                expect(type(response.result.data.age)).to_equal("number", "Age should be number")
                expect(response.result.data.occupation).not_to_be_nil("Missing occupation in structured output")
                expect(type(response.result.data.occupation)).to_equal("string", "Occupation should be string")
                expect(response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens reported")
                expect(response.finish_reason).to_equal("stop")
            end)

            it("should generate complex nested structured output with sonnet", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping complex structured output test - not enabled")
                    return
                end

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        {
                            role = "user",
                            content = {{
                                type = "text",
                                text = "Create a company profile with basic info and a list of departments. Think through a realistic example and return as JSON."
                            }}
                        }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            company_name = { type = "string" },
                            founded_year = { type = "number" },
                            headquarters = { type = "string" },
                            departments = {
                                type = "array",
                                items = {
                                    type = "object",
                                    properties = {
                                        name = { type = "string" },
                                        employees = { type = "number" }
                                    },
                                    required = { "name", "employees" },
                                    additionalProperties = false
                                }
                            }
                        },
                        required = { "company_name", "founded_year", "headquarters", "departments" },
                        additionalProperties = false
                    },
                    options = {
                        temperature = 0
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_true("Complex structured output failed: " .. (response.error_message or "unknown error"))
                expect(response.result.data).not_to_be_nil("No structured data in response")
                expect(response.result.data.company_name).not_to_be_nil("Missing company_name")
                expect(response.result.data.departments).not_to_be_nil("Missing departments")
                expect(type(response.result.data.departments)).to_equal("table", "Departments should be array")
                expect(#response.result.data.departments > 0).to_be_true("Should have at least one department")

                local first_dept = response.result.data.departments[1]
                expect(first_dept.name).not_to_be_nil("First department missing name")
                expect(first_dept.employees).not_to_be_nil("First department missing employees")
                expect(type(first_dept.employees)).to_equal("number", "Employee count should be number")
            end)

            it("should generate structured output with reasoning using sonnet", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping sonnet structured reasoning test - not enabled")
                    return
                end

                local contract_args = {
                    model = "claude-3-5-sonnet-20241022",
                    messages = {
                        {
                            role = "user",
                            content = {{
                                type = "text",
                                text = "Analyze this problem: 'If 5 apples cost $3, how much do 8 apples cost?' Think through the solution step by step and provide a structured analysis."
                            }}
                        }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            problem_type = { type = "string" },
                            given_values = {
                                type = "object",
                                properties = {
                                    apples = { type = "number" },
                                    cost = { type = "number" }
                                },
                                required = { "apples", "cost" },
                                additionalProperties = false
                            },
                            solution_steps = {
                                type = "array",
                                items = { type = "string" }
                            },
                            final_answer = { type = "number" }
                        },
                        required = { "problem_type", "given_values", "solution_steps", "final_answer" },
                        additionalProperties = false
                    },
                    schema_name = "math_solution",
                    options = {
                        temperature = 0,
                        max_tokens = 500
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_true("Sonnet structured reasoning failed: " .. (response.error_message or "unknown error"))
                expect(response.result.data).not_to_be_nil("No structured data in response")
                expect(response.result.data.problem_type).not_to_be_nil("Missing problem_type")
                expect(response.result.data.given_values.apples).to_equal(5)
                expect(response.result.data.given_values.cost).to_equal(3)
                expect(response.result.data.final_answer).to_equal(4.8) -- 8 * 3/5 = 4.8
                expect(response.result.data.solution_steps).not_to_be_nil("Missing solution steps")
                expect(#response.result.data.solution_steps > 0).to_be_true("Should have solution steps")
                expect(response.tokens.prompt_tokens > 0).to_be_true("No prompt tokens reported")
            end)
        end)

        describe("Error Handling Integration", function()
            it("should handle model not found errors", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping model error test - not enabled")
                    return
                end

                local contract_args = {
                    model = "nonexistent-claude-model-123",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "Test message" }}
                        }
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_false("Expected error for nonexistent model")
                expect(response.error).to_equal("model_error")
                expect(response.error_message).to_contain("model")
            end)

            it("should handle authentication errors", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping authentication error test - not enabled")
                    return
                end

                -- Temporarily override with invalid key
                generate_handler._client._ctx = {
                    all = function()
                        return { api_key = "sk-ant-invalid-key-12345" }
                    end
                }

                local contract_args = {
                    model = "claude-3-haiku-20240307",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "Test message" }}
                        }
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_false("Expected authentication error")
                expect(response.error).to_equal("authentication_error")

                -- Restore valid key
                generate_handler._client._ctx = {
                    all = function()
                        return { api_key = actual_api_key }
                    end
                }
            end)

            it("should handle invalid schema errors", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping invalid schema test - not enabled")
                    return
                end

                local contract_args = {
                    model = "claude-3-haiku-20240307",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = "Generate data" }}
                        }
                    },
                    schema = {
                        type = "array",  -- Should be object for root schema
                        items = { type = "string" }
                    }
                }

                local response = structured_output_handler.handler(contract_args)

                expect(response.success).to_be_false("Expected error for invalid schema")
                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_contain("Root schema must be type 'object'")
            end)
        end)

        describe("Performance and Edge Cases", function()
            it("should handle large context with haiku", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping large context test - not enabled")
                    return
                end

                -- Create moderately large but valid content
                local large_content = string.rep("This is test content for Claude. ", 500) -- ~17k characters

                local contract_args = {
                    model = "claude-3-haiku-20240307",
                    messages = {
                        {
                            role = "user",
                            content = {{ type = "text", text = large_content .. " Summarize this in one sentence." }}
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 50
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_true("Large context request failed: " .. (response.error_message or "unknown"))
                expect(response.result.content).not_to_be_nil("No content in response")
                expect(response.tokens.prompt_tokens > 1000).to_be_true("Expected many prompt tokens")
            end)

            it("should preserve metadata across all handler types", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping metadata test - not enabled")
                    return
                end

                -- Test metadata in text generation
                local gen_response = generate_handler.handler({
                    model = "claude-3-haiku-20240307",
                    messages = {{ role = "user", content = {{ type = "text", text = "Hello" }} }},
                    options = { temperature = 0, max_tokens = 5 }
                })

                expect(gen_response.success).to_be_true("Text generation failed")
                expect(gen_response.metadata).not_to_be_nil("No metadata in text generation")

                -- Test metadata in structured output
                local struct_response = structured_output_handler.handler({
                    model = "claude-3-haiku-20240307",
                    messages = {{ role = "user", content = {{ type = "text", text = "Generate test data as JSON" }} }},
                    schema = {
                        type = "object",
                        properties = { test = { type = "boolean" } },
                        required = { "test" },
                        additionalProperties = false
                    }
                })

                expect(struct_response.success).to_be_true("Structured output failed")
                expect(struct_response.metadata).not_to_be_nil("No metadata in structured output")
            end)

            it("should handle model switching from haiku to sonnet for complex tasks", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping model switching test - not enabled")
                    return
                end

                -- Test simple task with haiku
                local simple_response = generate_handler.handler({
                    model = "claude-3-haiku-20240307",
                    messages = {{ role = "user", content = {{ type = "text", text = "What is 2+2?" }} }},
                    options = { temperature = 0, max_tokens = 10 }
                })

                expect(simple_response.success).to_be_true("Haiku simple task failed")
                expect(simple_response.result.content).to_contain("4")

                -- Test complex task with sonnet
                local complex_response = generate_handler.handler({
                    model = "claude-3-5-sonnet-20241022",
                    messages = {{
                        role = "user",
                        content = {{
                            type = "text",
                            text = "Explain the philosophical implications of artificial intelligence consciousness in 3 sentences."
                        }}
                    }},
                    options = { temperature = 0, max_tokens = 200 }
                })

                expect(complex_response.success).to_be_true("Sonnet complex task failed")
                expect(#complex_response.result.content > #simple_response.result.content).to_be_true("Sonnet should provide more detailed response")
                expect(complex_response.result.content:lower()).to_contain("artificial")
                expect(complex_response.result.content:lower()).to_contain("consciousness")
            end)
        end)

        describe("Status Handler Integration Tests", function()
            local actual_api_key = nil

            before_all(function()
                actual_api_key = env.get("ANTHROPIC_API_KEY")
                if not RUN_INTEGRATION_TESTS or not actual_api_key then
                    print("Claude status integration tests disabled")
                end
            end)

            before_each(function()
                if actual_api_key then
                    status_handler._client._ctx = {
                        all = function()
                            return { api_key = actual_api_key }
                        end
                    }
                    status_handler._client._env = {
                        get = function(key)
                            return nil
                        end
                    }
                end
            end)

            after_each(function()
                status_handler._client._ctx = nil
                status_handler._client._env = nil
            end)

            it("should return healthy status with real Claude API", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping real Claude API status test")
                    return
                end

                local response = status_handler.handler()

                expect(response.success).to_be_true("Claude API status check failed")
                expect(response.status).to_equal("healthy")
                expect(response.message).to_equal("Claude API is responding normally")
            end)

            it("should handle invalid API key", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping invalid Claude key test")
                    return
                end

                status_handler._client._ctx = {
                    all = function()
                        return { api_key = "sk-ant-invalid12345" }
                    end
                }

                local response = status_handler.handler()

                expect(response.success).to_be_false("Expected auth failure")
                expect(response.status).to_equal("unhealthy")
                expect(response.message).to_contain("invalid")
            end)

            it("should work with custom base URL", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping custom base URL test")
                    return
                end

                status_handler._client._ctx = {
                    all = function()
                        return {
                            api_key = actual_api_key,
                            base_url = "https://api.anthropic.com"
                        }
                    end
                }

                local response = status_handler.handler()

                expect(response.success).to_be_true("Custom base URL failed")
                expect(response.status).to_equal("healthy")
            end)

            it("should resolve API key from environment", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping env resolution test")
                    return
                end

                status_handler._client._ctx = {
                    all = function()
                        return { api_key_env = "ANTHROPIC_API_KEY" }
                    end
                }

                status_handler._client._env = {
                    get = function(key)
                        if key == "ANTHROPIC_API_KEY" then
                            return actual_api_key
                        end
                        return nil
                    end
                }

                local response = status_handler.handler()

                expect(response.success).to_be_true("Env API key resolution failed")
                expect(response.status).to_equal("healthy")
            end)
        end)

        describe("Claude 4 Text Editor Tool Integration", function()
            it("should create and edit a simple file", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping Claude 4 text editor test - not enabled")
                    return
                end

                local contract_args = {
                    model = "claude-sonnet-4-20250514",
                    messages = {
                        {
                            role = "user",
                            content = {{
                                type = "text",
                                text = "Create a simple hello.py file that prints 'Hello World'"
                            }}
                        }
                    },
                    tools = {
                        {
                            type = "text_editor_20250728",
                            name = "str_replace_based_edit_tool"
                        }
                    },
                    options = {
                        temperature = 0,
                        max_tokens = 500
                    }
                }

                local response = generate_handler.handler(contract_args)

                expect(response.success).to_be_true("Claude 4 text editor failed: " .. (response.error_message or "unknown"))
                expect(response.result.tool_calls).not_to_be_nil("No tool calls in response")
                expect(#response.result.tool_calls > 0).to_be_true("Expected text editor tool call")

                local tool_call = response.result.tool_calls[1]
                expect(tool_call.name).to_equal("str_replace_based_edit_tool")
                expect(tool_call.arguments.command).to_equal("create")
                expect(tool_call.arguments.path).to_contain("hello.py")
                expect(tool_call.arguments.file_text).to_contain("print")
                expect(response.finish_reason).to_equal("tool_call")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)