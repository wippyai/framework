local structured_output_handler = require("structured_output_handler")
local json = require("json")

local function define_tests()
    describe("Bedrock Structured Output Handler (Converse API)", function()

        after_each(function()
            structured_output_handler._client = nil
        end)

        describe("Contract Validation", function()
            it("should require model parameter", function()
                local response, err = structured_output_handler.handler({
                    messages = { { role = "user", content = { { type = "text", text = "Test" } } } },
                    schema = { type = "object", properties = {}, required = {}, additionalProperties = false }
                })
                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Invalid")
                test.contains(err:message(), "Model is required")
            end)

            it("should require messages parameter", function()
                local response, err = structured_output_handler.handler({
                    model = "test-model",
                    schema = { type = "object", properties = {}, required = {}, additionalProperties = false }
                })
                test.is_nil(response)
                test.not_nil(err)
                test.contains(err:message(), "Messages are required")
            end)

            it("should require schema parameter", function()
                local response, err = structured_output_handler.handler({
                    model = "test-model",
                    messages = { { role = "user", content = { { type = "text", text = "Test" } } } }
                })
                test.is_nil(response)
                test.not_nil(err)
                test.contains(err:message(), "Schema is required")
            end)

            it("should validate schema structure", function()
                local response, err = structured_output_handler.handler({
                    model = "test-model",
                    messages = { { role = "user", content = { { type = "text", text = "Test" } } } },
                    schema = { type = "string" }
                })
                test.is_nil(response)
                test.not_nil(err)
                test.contains(err:message(), "type 'object'")
            end)
        end)

        describe("Structured Output", function()
            it("should extract structured data from tool_use response", function()
                structured_output_handler._client = {
                    converse = function(model_id, payload, options)
                        return {
                            output = {
                                message = {
                                    role = "assistant",
                                    content = {
                                        {
                                            toolUse = {
                                                toolUseId = "call_1",
                                                name = "structured_output",
                                                input = { name = "John", age = 30, city = "NYC" }
                                            }
                                        }
                                    }
                                }
                            },
                            stopReason = "tool_use",
                            usage = { inputTokens = 40, outputTokens = 20 },
                            metadata = {}
                        }
                    end
                }

                local response = structured_output_handler.handler({
                    model = "test-model",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Extract: John Doe is 30 from NYC" } } }
                    },
                    schema = {
                        type = "object",
                        properties = {
                            name = { type = "string" },
                            age = { type = "number" },
                            city = { type = "string" }
                        },
                        required = { "name", "age", "city" },
                        additionalProperties = false
                    }
                })

                test.is_true(response.success)
                test.not_nil((response :: any).result.data)
                test.eq((response :: any).result.data.name, "John")
                test.eq((response :: any).result.data.age, 30)
                test.eq((response :: any).result.data.city, "NYC")
            end)

            it("should forward retry to the client request", function()
                local captured_options = nil
                structured_output_handler._client = {
                    converse = function(model_id, payload, options)
                        captured_options = options
                        return {
                            output = {
                                message = {
                                    role = "assistant",
                                    content = {
                                        {
                                            toolUse = {
                                                toolUseId = "call_1",
                                                name = "structured_output",
                                                input = { name = "John" }
                                            }
                                        }
                                    }
                                }
                            },
                            stopReason = "tool_use",
                            usage = { inputTokens = 40, outputTokens = 20 },
                            metadata = {}
                        }
                    end
                }

                local response = structured_output_handler.handler({
                    model = "test-model",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Extract: John" } } }
                    },
                    schema = {
                        type = "object",
                        properties = { name = { type = "string" } },
                        required = { "name" },
                        additionalProperties = false
                    },
                    retry = { attempts = 2, backoff_ms = 0 }
                })

                test.is_true(response.success)
                local options = captured_options :: any
                test.eq(options.retry.attempts, 2)
                test.eq(options.retry.backoff_ms, 0)
            end)

            it("binds replayed reasoning with drop_block", function()
                local captured_payload: any = nil
                structured_output_handler._client = {
                    converse = function(model_id, payload, options)
                        captured_payload = payload
                        return {
                            output = {
                                message = {
                                    role = "assistant",
                                    content = {
                                        { toolUse = { toolUseId = "c1", name = "structured_output", input = { x = 1 } } }
                                    }
                                }
                            },
                            stopReason = "tool_use",
                            usage = { inputTokens = 10, outputTokens = 5 },
                            metadata = {}
                        }
                    end
                }

                structured_output_handler.handler({
                    model = "us.anthropic.claude-opus-5-5-v1:0",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Plan" } } },
                        {
                            role = "assistant",
                            content = { { type = "text", text = "Planned." } },
                            metadata = { thinking_blocks = { { type = "thinking", thinking = "t", signature = "sig" } } }
                        },
                        { role = "user", content = { { type = "text", text = "Answer" } } }
                    },
                    schema = {
                        type = "object",
                        properties = { x = { type = "number" } },
                        required = { "x" },
                        additionalProperties = false
                    },
                    options = { thinking_effort = 50 },
                    accepts = { thinking = "adaptive" }
                })

                local fields = captured_payload.additionalModelRequestFields
                test.eq(fields.thinking.block_binding.prefix_mismatch_behavior, "drop_block")
                test.eq(fields.anthropic_beta[1], "thinking-binding-controls-2026-08-01")
                test.eq(captured_payload.additionalModelResponseFieldPaths[1], "/input_transformations")
            end)

            it("binds replayed reasoning on an always route at effort 0", function()
                local captured_payload: any = nil
                structured_output_handler._client = {
                    converse = function(model_id, payload, options)
                        captured_payload = payload
                        return {
                            output = { message = { role = "assistant", content = {
                                { toolUse = { toolUseId = "c1", name = "structured_output", input = { x = 1 } } }
                            } } },
                            stopReason = "tool_use",
                            usage = { inputTokens = 10, outputTokens = 5 },
                            metadata = {}
                        }
                    end
                }

                structured_output_handler.handler({
                    model = "us.anthropic.claude-opus-5-5-v1:0",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Plan" } } },
                        {
                            role = "assistant",
                            content = { { type = "text", text = "Planned." } },
                            metadata = { thinking_blocks = { { type = "thinking", thinking = "t", signature = "sig" } } }
                        },
                        { role = "user", content = { { type = "text", text = "Answer" } } }
                    },
                    schema = {
                        type = "object",
                        properties = { x = { type = "number" } },
                        required = { "x" },
                        additionalProperties = false
                    },
                    options = { thinking_effort = 0 },
                    accepts = { thinking = "always" }
                })

                local fields = captured_payload.additionalModelRequestFields
                test.eq(fields.thinking.type, "adaptive")
                test.is_nil(fields.output_config)
                test.eq(fields.thinking.block_binding.prefix_mismatch_behavior, "drop_block")
                test.eq(fields.anthropic_beta[1], "thinking-binding-controls-2026-08-01")
                test.eq(captured_payload.additionalModelResponseFieldPaths[1], "/input_transformations")
            end)

            it("rejects a request anthropic_beta the binding extends when it is not a list", function()
                local called = false
                structured_output_handler._client = {
                    converse = function()
                        called = true
                        return nil, { status_code = 500, message = "unreachable" }
                    end
                }

                local response, err = structured_output_handler.handler({
                    model = "us.anthropic.claude-opus-5-5-v1:0",
                    messages = {
                        { role = "user", content = { { type = "text", text = "Plan" } } },
                        {
                            role = "assistant",
                            content = { { type = "text", text = "Planned." } },
                            metadata = { thinking_blocks = { { type = "thinking", thinking = "t", signature = "sig" } } }
                        },
                        { role = "user", content = { { type = "text", text = "Answer" } } }
                    },
                    schema = {
                        type = "object",
                        properties = { x = { type = "number" } },
                        required = { "x" },
                        additionalProperties = false
                    },
                    options = { thinking_effort = 50, request = { additionalModelRequestFields = { anthropic_beta = "context-1m-2025-08-07" } } },
                    accepts = { thinking = "adaptive" }
                })

                test.is_nil(response)
                test.eq(err:kind(), "Invalid")
                test.contains(err:message(), "additionalModelRequestFields.anthropic_beta")
                test.is_false(called)
            end)

            it("should send forced tool_choice in payload", function()
                local captured_payload = nil
                structured_output_handler._client = {
                    converse = function(model_id, payload, options)
                        captured_payload = payload
                        return {
                            output = {
                                message = {
                                    role = "assistant",
                                    content = {
                                        { toolUse = { toolUseId = "c1", name = "structured_output", input = { x = 1 } } }
                                    }
                                }
                            },
                            stopReason = "tool_use",
                            usage = { inputTokens = 10, outputTokens = 5 },
                            metadata = {}
                        }
                    end
                }

                structured_output_handler.handler({
                    model = "test-model",
                    messages = { { role = "user", content = { { type = "text", text = "Test" } } } },
                    schema = {
                        type = "object",
                        properties = { x = { type = "number" } },
                        required = { "x" },
                        additionalProperties = false
                    }
                })

                test.not_nil((captured_payload :: any).toolConfig)
                test.not_nil((captured_payload :: any).toolConfig.toolChoice)
                test.not_nil((captured_payload :: any).toolConfig.toolChoice.any)
                test.eq(#(captured_payload :: any).toolConfig.tools, 1)
                test.eq((captured_payload :: any).toolConfig.tools[1].toolSpec.name, "structured_output")
            end)

            it("should handle missing tool_use in response", function()
                structured_output_handler._client = {
                    converse = function(model_id, payload, options)
                        return {
                            output = {
                                message = {
                                    role = "assistant",
                                    content = { { text = "I cannot do that" } }
                                }
                            },
                            stopReason = "end_turn",
                            usage = { inputTokens = 10, outputTokens = 5 },
                            metadata = {}
                        }
                    end
                }

                local response, err = structured_output_handler.handler({
                    model = "test-model",
                    messages = { { role = "user", content = { { type = "text", text = "Extract" } } } },
                    schema = {
                        type = "object",
                        properties = { x = { type = "number" } },
                        required = { "x" },
                        additionalProperties = false
                    }
                })

                test.is_nil(response)
                test.not_nil(err)
                test.contains(err:message(), "structured_output tool")
            end)

            local function reply(content, stop_reason)
                structured_output_handler._client = {
                    converse = function()
                        return {
                            output = { message = { role = "assistant", content = content } },
                            stopReason = stop_reason,
                            usage = { inputTokens = 120, outputTokens = 64 },
                            metadata = {}
                        }
                    end
                }
                return structured_output_handler.handler({
                    model = "test-model",
                    messages = { { role = "user", content = { { type = "text", text = "Extract" } } } },
                    schema = {
                        type = "object",
                        properties = { x = { type = "number" } },
                        required = { "x" },
                        additionalProperties = false
                    }
                })
            end

            it("preserves missing-tool errors and usage on a reply cut by the output limit", function()
                local response, err = reply({ { text = "Working on it" } }, "max_tokens")

                test.is_nil(response)
                test.eq(err:message(), "Model failed to use the structured_output tool")
                test.eq(err:kind(), "Unavailable")
                test.is_true(err:retryable())
                test.eq(err:details().error_type, "server_error")
                test.eq(err:details().finish_reason, "length")
                test.eq(err:details().tokens.prompt_tokens, 120)
                test.eq(err:details().tokens.completion_tokens, 64)
            end)

            it("carries finish_reason and usage when the tool is not used", function()
                local response, err = reply({ { text = "I cannot do that" } }, "end_turn")

                test.is_nil(response)
                test.eq(err:details().finish_reason, "stop")
                test.eq(err:details().tokens.completion_tokens, 64)
            end)
        end)

        describe("Route facts", function()
            it("rejects structured_output = native, which Bedrock cannot honor", function()
                local response, err = structured_output_handler.handler({
                    model = "test-model",
                    messages = { { role = "user", content = { { type = "text", text = "Extract" } } } },
                    schema = { type = "object", properties = {}, required = {}, additionalProperties = false },
                    accepts = { structured_output = "native" }
                })
                test.is_nil(response)
                test.eq(err:kind(), "Invalid")
                test.contains(err:message(), "structured_output")
            end)

            it("refuses the forced-tool path for a route that cannot be forced", function()
                local called = false
                structured_output_handler._client = {
                    converse = function() called = true end
                }
                local response, err = structured_output_handler.handler({
                    model = "test-model",
                    messages = { { role = "user", content = { { type = "text", text = "Extract" } } } },
                    schema = { type = "object", properties = {}, required = {}, additionalProperties = false },
                    accepts = { forced_tool_choice = false }
                })
                test.is_nil(response)
                test.eq(err:kind(), "Invalid")
                test.contains(err:message(), "forced_tool_choice")
                test.is_false(called)
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
