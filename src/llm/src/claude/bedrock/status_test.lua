local status_handler = require("status_handler")

local function define_tests()
    describe("Bedrock Status Handler", function()

        after_each(function()
            status_handler._client = nil
        end)

        describe("Healthy Response", function()
            it("should return healthy when API responds normally", function()
                status_handler._client = {
                    request = function(model_id, payload, options)
                        test.eq(model_id, "us.anthropic.claude-haiku-4-5-20251001-v1:0")
                        test.eq(payload.max_tokens, 1)
                        test.eq(options.timeout, 15)

                        return {
                            content = {
                                { type = "text", text = "p" }
                            },
                            stop_reason = "max_tokens",
                            usage = { input_tokens = 3, output_tokens = 1 },
                            metadata = {}
                        }
                    end
                }

                local response = status_handler.handler()

                test.is_true(response.success)
                test.eq(response.status, "healthy")
                test.eq(response.message, "Bedrock API is responding normally")
            end)
        end)

        describe("Custom Model", function()
            it("should use custom model parameter", function()
                local captured_model = nil
                status_handler._client = {
                    request = function(model_id, payload, options)
                        captured_model = model_id
                        return {
                            content = { { type = "text", text = "ok" } },
                            stop_reason = "max_tokens",
                            usage = { input_tokens = 3, output_tokens = 1 },
                            metadata = {}
                        }
                    end
                }

                local response = status_handler.handler({
                    model = "us.anthropic.claude-sonnet-4-20250514-v1:0"
                })

                test.is_true(response.success)
                test.eq(captured_model, "us.anthropic.claude-sonnet-4-20250514-v1:0")
            end)
        end)

        describe("Unhealthy States", function()
            it("should return unhealthy on connection failure", function()
                status_handler._client = {
                    request = function(model_id, payload, options)
                        return nil, {
                            status_code = 0,
                            message = "Connection failed"
                        }
                    end
                }

                local response = status_handler.handler()

                test.is_false(response.success)
                test.eq(response.status, "unhealthy")
                test.eq(response.message, "Connection failed")
            end)

            it("should return unhealthy on auth failure", function()
                status_handler._client = {
                    request = function(model_id, payload, options)
                        return nil, {
                            status_code = 403,
                            message = "The security token included in the request is invalid"
                        }
                    end
                }

                local response = status_handler.handler()

                test.is_false(response.success)
                test.eq(response.status, "unhealthy")
                test.contains(response.message, "security token")
            end)

            it("should return unhealthy on 401 error", function()
                status_handler._client = {
                    request = function(model_id, payload, options)
                        return nil, {
                            status_code = 401,
                            message = "Authentication failed"
                        }
                    end
                }

                local response = status_handler.handler()

                test.is_false(response.success)
                test.eq(response.status, "unhealthy")
            end)
        end)

        describe("Degraded States", function()
            it("should return degraded on rate limit", function()
                status_handler._client = {
                    request = function(model_id, payload, options)
                        return nil, {
                            status_code = 429,
                            message = "Too many requests"
                        }
                    end
                }

                local response = status_handler.handler()

                test.is_false(response.success)
                test.eq(response.status, "degraded")
                test.eq(response.message, "Rate limited but service is available")
            end)

            it("should return degraded on server error", function()
                status_handler._client = {
                    request = function(model_id, payload, options)
                        return nil, {
                            status_code = 503,
                            message = "Service unavailable"
                        }
                    end
                }

                local response = status_handler.handler()

                test.is_false(response.success)
                test.eq(response.status, "degraded")
                test.eq(response.message, "Service experiencing issues")
            end)

            it("should return degraded on 500 error", function()
                status_handler._client = {
                    request = function(model_id, payload, options)
                        return nil, {
                            status_code = 500,
                            message = "Internal server error"
                        }
                    end
                }

                local response = status_handler.handler()

                test.is_false(response.success)
                test.eq(response.status, "degraded")
                test.eq(response.message, "Service experiencing issues")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
