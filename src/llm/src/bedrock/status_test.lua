local status_handler = require("status_handler")

local function define_tests()
    describe("Bedrock Status Handler", function()

        after_each(function()
            status_handler._client = nil
        end)

        it("should return healthy when API responds", function()
            status_handler._client = {
                converse = function(model_id, payload, options)
                    return {
                        output = { message = { role = "assistant", content = { { text = "p" } } } },
                        stopReason = "end_turn",
                        usage = { inputTokens = 1, outputTokens = 1 }
                    }
                end
            }

            local response = status_handler.handler({})
            test.is_true(response.success)
            test.eq(response.status, "healthy")
        end)

        it("should use Converse API format", function()
            local captured_payload = nil
            status_handler._client = {
                converse = function(model_id, payload, options)
                    captured_payload = payload
                    return {
                        output = { message = { role = "assistant", content = { { text = "p" } } } },
                        stopReason = "end_turn",
                        usage = { inputTokens = 1, outputTokens = 1 }
                    }
                end
            }

            status_handler.handler({})

            test.not_nil((captured_payload :: any).messages)
            test.eq((captured_payload :: any).messages[1].content[1].text, "ping")
            test.not_nil((captured_payload :: any).inferenceConfig)
            test.eq((captured_payload :: any).inferenceConfig.maxTokens, 1)
        end)

        it("should return unhealthy on connection failure", function()
            status_handler._client = {
                converse = function(model_id, payload, options)
                    return nil, { status_code = 0, message = "Connection failed" }
                end
            }

            local response = status_handler.handler({})
            test.is_false(response.success)
            test.eq(response.status, "unhealthy")
        end)

        it("should return degraded on rate limit", function()
            status_handler._client = {
                converse = function(model_id, payload, options)
                    return nil, { status_code = 429, message = "Rate limited" }
                end
            }

            local response = status_handler.handler({})
            test.is_false(response.success)
            test.eq(response.status, "degraded")
        end)

        it("should return unhealthy on auth failure", function()
            status_handler._client = {
                converse = function(model_id, payload, options)
                    return nil, { status_code = 403, message = "Access denied" }
                end
            }

            local response = status_handler.handler({})
            test.is_false(response.success)
            test.eq(response.status, "unhealthy")
        end)

        it("should use custom model if provided", function()
            local captured_model = nil
            status_handler._client = {
                converse = function(model_id, payload, options)
                    captured_model = model_id
                    return {
                        output = { message = { role = "assistant", content = { { text = "p" } } } },
                        stopReason = "end_turn",
                        usage = { inputTokens = 1, outputTokens = 1 }
                    }
                end
            }

            status_handler.handler({ model = "custom-model-id" })
            test.eq(captured_model, "custom-model-id")
        end)
    end)
end

return require("test").run_cases(define_tests)
