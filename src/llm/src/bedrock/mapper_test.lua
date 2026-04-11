local mapper = require("mapper")
local json = require("json")

local function define_tests()
    describe("Bedrock Converse Mapper", function()

        describe("map_messages", function()
            it("should map user messages to Converse format", function()
                local result = mapper.map_messages({
                    { role = "user", content = { { type = "text", text = "Hello" } } }
                })

                test.eq(#result.messages, 1)
                test.eq(result.messages[1].role, "user")
                test.eq((result.messages[1].content[1] :: any).text, "Hello")
                test.is_nil(result.system)
            end)

            it("should extract system messages", function()
                local result = mapper.map_messages({
                    { role = "system", content = "You are helpful" },
                    { role = "user", content = { { type = "text", text = "Hi" } } }
                })

                test.eq(#result.messages, 1)
                test.not_nil(result.system)
                test.eq((result.system[1] :: any).text, "You are helpful")
            end)

            it("should map function_call to assistant toolUse", function()
                local result = mapper.map_messages({
                    { role = "user", content = { { type = "text", text = "Weather?" } } },
                    {
                        role = "function_call",
                        function_call = {
                            id = "call_123",
                            name = "get_weather",
                            arguments = { location = "NYC" }
                        }
                    }
                })

                test.eq(#result.messages, 2)
                test.eq(result.messages[2].role, "assistant")
                local tool_use_block = result.messages[2].content[1] :: any
                test.not_nil(tool_use_block.toolUse)
                test.eq(tool_use_block.toolUse.name, "get_weather")
                test.eq(tool_use_block.toolUse.toolUseId, "call_123")
            end)

            it("should map function_result to user toolResult", function()
                local result = mapper.map_messages({
                    { role = "user", content = { { type = "text", text = "Weather?" } } },
                    {
                        role = "function_call",
                        function_call = { id = "call_1", name = "get_weather", arguments = { location = "NYC" } }
                    },
                    {
                        role = "function_result",
                        content = "Sunny, 72F",
                        function_call_id = "call_1"
                    }
                })

                test.eq(#result.messages, 3)
                test.eq(result.messages[3].role, "user")
                local tool_result_block = result.messages[3].content[1] :: any
                test.not_nil(tool_result_block.toolResult)
                test.eq(tool_result_block.toolResult.toolUseId, "call_1")
            end)

            it("should consolidate consecutive same-role messages", function()
                local result = mapper.map_messages({
                    { role = "user", content = { { type = "text", text = "First" } } },
                    { role = "user", content = { { type = "text", text = "Second" } } }
                })

                test.eq(#result.messages, 1)
                test.eq(#result.messages[1].content, 2)
                test.eq((result.messages[1].content[1] :: any).text, "First")
                test.eq((result.messages[1].content[2] :: any).text, "Second")
            end)

            it("should handle string content in user messages", function()
                local result = mapper.map_messages({
                    { role = "user", content = "Plain text" }
                })

                test.eq(#result.messages, 1)
                test.eq((result.messages[1].content[1] :: any).text, "Plain text")
            end)

            it("should map developer messages to system blocks", function()
                local result = mapper.map_messages({
                    { role = "system", content = "System prompt" },
                    { role = "developer", content = "Developer instruction" },
                    { role = "user", content = { { type = "text", text = "Hello" } } }
                })

                test.not_nil(result.system)
                test.eq(#result.system, 2)
                test.eq((result.system[1] :: any).text, "System prompt")
                test.eq((result.system[2] :: any).text, "Developer instruction")
            end)

            it("should preserve thinking blocks in function_call messages", function()
                local result = mapper.map_messages({
                    { role = "user", content = { { type = "text", text = "Hi" } } },
                    {
                        role = "function_call",
                        function_call = { id = "call_1", name = "tool", arguments = {} },
                        metadata = {
                            thinking_blocks = {
                                { type = "thinking", thinking = "Let me think...", signature = "sig123" }
                            }
                        }
                    }
                })

                test.eq(#result.messages[2].content, 2)
                local reasoning_block = result.messages[2].content[1] :: any
                test.not_nil(reasoning_block.reasoningContent)
                test.eq(reasoning_block.reasoningContent.reasoningText.text, "Let me think...")
                local tool_block = result.messages[2].content[2] :: any
                test.not_nil(tool_block.toolUse)
            end)
        end)

        describe("map_tools", function()
            it("should map contract tools to Converse toolConfig format", function()
                local tools, name_map = mapper.map_tools({
                    {
                        id = "tool_1",
                        name = "get_weather",
                        description = "Get the weather",
                        schema = {
                            type = "object",
                            properties = { location = { type = "string" } },
                            required = { "location" }
                        }
                    }
                })

                test.not_nil(tools)
                test.eq(#tools, 1)
                test.eq(tools[1].toolSpec.name, "get_weather")
                test.eq(tools[1].toolSpec.description, "Get the weather")
                test.not_nil(tools[1].toolSpec.inputSchema.json)
                test.eq(name_map["get_weather"], "tool_1")
            end)

            it("should return nil tools for empty input", function()
                local tools, name_map = mapper.map_tools({})
                test.is_nil(tools)
            end)
        end)

        describe("map_tool_choice", function()
            it("should return nil for auto choice (default behavior)", function()
                local choice = mapper.map_tool_choice("auto", { { toolSpec = { name = "t" } } })
                test.is_nil(choice)
            end)

            it("should map any choice", function()
                local choice = mapper.map_tool_choice("any", { { toolSpec = { name = "t" } } })
                test.not_nil(choice)
                test.not_nil(choice.any)
            end)

            it("should map specific tool choice", function()
                local choice = mapper.map_tool_choice("get_weather", { { toolSpec = { name = "get_weather" } } })
                test.not_nil(choice)
                test.eq(choice.tool.name, "get_weather")
            end)

            it("should return nil for none", function()
                local choice = mapper.map_tool_choice("none", { { toolSpec = { name = "t" } } })
                test.is_nil(choice)
            end)
        end)

        describe("map_options", function()
            it("should map standard options to inferenceConfig", function()
                local config, additional = mapper.map_options({
                    temperature = 0.7,
                    max_tokens = 1000,
                    top_p = 0.9,
                    stop_sequences = { "END" }
                })

                test.eq(config.temperature, 0.7)
                test.eq(config.maxTokens, 1000)
                test.eq(config.topP, 0.9)
                test.eq((config :: any).stopSequences[1], "END")
            end)

            it("should map thinking_effort to additionalModelRequestFields", function()
                local config, additional = mapper.map_options({
                    thinking_effort = 50,
                    max_tokens = 5000
                })

                test.not_nil(additional.thinking)
                test.eq(additional.thinking.type, "enabled")
                test.is_true(additional.thinking.budget_tokens > 1024)
                test.eq(config.temperature, 1)
            end)

            it("should map top_k to additionalModelRequestFields", function()
                local config, additional = mapper.map_options({
                    top_k = 40
                })

                test.eq(additional.top_k, 40)
            end)
        end)

        describe("map_tokens", function()
            it("should map Converse usage to contract tokens", function()
                local tokens = mapper.map_tokens({
                    inputTokens = 100,
                    outputTokens = 50,
                    totalTokens = 150
                })

                test.eq(tokens.prompt_tokens, 100)
                test.eq(tokens.completion_tokens, 50)
                test.eq(tokens.total_tokens, 150)
            end)

            it("should handle cache tokens", function()
                local tokens = mapper.map_tokens({
                    inputTokens = 100,
                    outputTokens = 50,
                    cacheReadInputTokens = 80,
                    cacheWriteInputTokens = 20
                })

                test.eq(tokens.cache_read_tokens, 80)
                test.eq(tokens.cache_write_tokens, 20)
            end)
        end)

        describe("map_finish_reason", function()
            it("should map end_turn to stop", function()
                test.eq(mapper.map_finish_reason("end_turn"), "stop")
            end)

            it("should map tool_use to tool_call", function()
                test.eq(mapper.map_finish_reason("tool_use"), "tool_call")
            end)

            it("should map max_tokens to length", function()
                test.eq(mapper.map_finish_reason("max_tokens"), "length")
            end)
        end)

        describe("extract_response_content", function()
            it("should extract text content", function()
                local extracted = mapper.extract_response_content({
                    output = {
                        message = {
                            role = "assistant",
                            content = {
                                { text = "Hello world" }
                            }
                        }
                    }
                })

                test.eq(extracted.content, "Hello world")
                test.eq(#extracted.tool_calls, 0)
            end)

            it("should extract tool calls", function()
                local extracted = mapper.extract_response_content({
                    output = {
                        message = {
                            role = "assistant",
                            content = {
                                { toolUse = { toolUseId = "call_1", name = "get_weather", input = { location = "NYC" } } }
                            }
                        }
                    }
                })

                test.eq(#extracted.tool_calls, 1)
                test.eq(extracted.tool_calls[1].name, "get_weather")
                test.eq(extracted.tool_calls[1].id, "call_1")
            end)

            it("should extract reasoning content", function()
                local extracted = mapper.extract_response_content({
                    output = {
                        message = {
                            role = "assistant",
                            content = {
                                {
                                    reasoningContent = {
                                        reasoningText = { text = "Thinking...", signature = "sig" }
                                    }
                                },
                                { text = "Answer" }
                            }
                        }
                    }
                })

                test.eq(extracted.content, "Answer")
                test.eq(#extracted.thinking_blocks, 1)
                test.eq(extracted.thinking_blocks[1].thinking, "Thinking...")
            end)
        end)

        describe("map_error_response", function()
            it("should map HTTP status to error type", function()
                local response = mapper.map_error_response({
                    status_code = 429,
                    message = "Rate limited"
                })

                test.is_false(response.success)
                test.eq(response.error, "rate_limit_exceeded")
                test.eq(response.error_message, "Rate limited")
            end)

            it("should map auth errors", function()
                local response = mapper.map_error_response({
                    status_code = 403,
                    message = "Access denied"
                })

                test.is_false(response.success)
                test.eq(response.error, "authentication_error")
            end)

            it("should handle nil error", function()
                local response = mapper.map_error_response(nil)
                test.is_false(response.success)
                test.eq(response.error, "server_error")
            end)
        end)

        describe("format_success_response", function()
            it("should format a full Converse response", function()
                local response = mapper.format_success_response({
                    output = {
                        message = {
                            role = "assistant",
                            content = { { text = "Hello!" } }
                        }
                    },
                    stopReason = "end_turn",
                    usage = { inputTokens = 10, outputTokens = 5, totalTokens = 15 },
                    metadata = {}
                }, {})

                test.is_true(response.success)
                test.eq(response.result.content, "Hello!")
                test.eq(#response.result.tool_calls, 0)
                test.eq(response.tokens.prompt_tokens, 10)
                test.eq(response.tokens.completion_tokens, 5)
                test.eq(response.finish_reason, "stop")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
