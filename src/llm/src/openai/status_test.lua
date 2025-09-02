local status_handler = require("status_handler")
local json = require("json")

local function define_tests()
    describe("OpenAI Status Handler", function()

        after_each(function()
            -- Clean up injected dependencies
            status_handler._client._ctx = nil
            status_handler._client._env = nil
            status_handler._client._http_client = nil
        end)

        describe("Health Check Success", function()
            it("should return healthy status when API responds normally", function()
                status_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                status_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                status_handler._client._http_client = {
                    get = function(url, options)
                        expect(url).to_contain("/models")
                        expect(options.headers["Content-Type"]).to_be_nil()
                        expect(options.body).to_be_nil()

                        return {
                            status_code = 200,
                            body = json.encode({
                                data = {
                                    { id = "gpt-4o", object = "model" },
                                    { id = "gpt-4o-mini", object = "model" }
                                }
                            }),
                            headers = { ["X-Request-Id"] = "req_status_test" }
                        }
                    end
                }

                local response = status_handler.handler()

                expect(response.success).to_be_true()
                expect(response.status).to_equal("healthy")
                expect(response.message).to_equal("OpenAI API is responding normally")
            end)

            it("should resolve API key from context", function()
                status_handler._client._ctx = {
                    all = function()
                        return {
                            api_key_env = "CUSTOM_API_KEY",
                            base_url = "https://api.openai.com/v1"
                        }
                    end
                }

                status_handler._client._env = {
                    get = function(key)
                        if key == "CUSTOM_API_KEY" then return "custom-test-key" end
                        return nil
                    end
                }

                status_handler._client._http_client = {
                    get = function(url, options)
                        expect(options.headers["Authorization"]).to_equal("Bearer custom-test-key")
                        expect(url).to_equal("https://api.openai.com/v1/models")

                        return {
                            status_code = 200,
                            body = json.encode({ data = {} }),
                            headers = {}
                        }
                    end
                }

                local response = status_handler.handler()

                expect(response.success).to_be_true()
                expect(response.status).to_equal("healthy")
            end)
        end)

        describe("Health Check Failures", function()
            it("should return unhealthy for authentication errors", function()
                status_handler._client._ctx = {
                    all = function()
                        return { api_key = "invalid-key" }
                    end
                }

                status_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                status_handler._client._http_client = {
                    get = function(url, options)
                        return {
                            status_code = 401,
                            body = json.encode({
                                error = {
                                    message = "Invalid API key provided",
                                    type = "invalid_request_error"
                                }
                            }),
                            headers = {}
                        }
                    end
                }

                local response = status_handler.handler()

                expect(response.success).to_be_false()
                expect(response.status).to_equal("unhealthy")
                expect(response.message).to_contain("Invalid API key")
            end)

            it("should return unhealthy for network errors", function()
                status_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                status_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                status_handler._client._http_client = {
                    get = function(url, options)
                        return {
                            status_code = 0, -- Connection failed
                            body = nil,
                            headers = {}
                        }
                    end
                }

                local response = status_handler.handler()

                expect(response.success).to_be_false()
                expect(response.status).to_equal("unhealthy")
                expect(response.message).to_contain("Connection failed")
            end)

            it("should return unhealthy for missing API key", function()
                status_handler._client._ctx = {
                    all = function()
                        return {}
                    end
                }

                status_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                status_handler._client._http_client = nil

                local response = status_handler.handler()

                expect(response.success).to_be_false()
                expect(response.status).to_equal("unhealthy")
                expect(response.message).to_contain("API key is required")
            end)

            it("should handle nil HTTP response", function()
                status_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                status_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                status_handler._client._http_client = {
                    get = function(url, options)
                        return nil
                    end
                }

                local response = status_handler.handler()

                expect(response.success).to_be_false()
                expect(response.status).to_equal("unhealthy")
                expect(response.message).to_equal("Connection failed")
            end)
        end)

        describe("Degraded Status", function()
            it("should return degraded for rate limit errors", function()
                status_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                status_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                status_handler._client._http_client = {
                    get = function(url, options)
                        return {
                            status_code = 429,
                            body = json.encode({
                                error = {
                                    message = "Rate limit exceeded",
                                    type = "rate_limit_exceeded"
                                }
                            }),
                            headers = {
                                ["x-ratelimit-remaining-requests"] = "0",
                                ["x-ratelimit-reset-requests"] = "1h"
                            }
                        }
                    end
                }

                local response = status_handler.handler()

                expect(response.success).to_be_false()
                expect(response.status).to_equal("degraded")
                expect(response.message).to_equal("Rate limited but service is available")
            end)

            it("should return degraded for server errors (5xx)", function()
                status_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                status_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                status_handler._client._http_client = {
                    get = function(url, options)
                        return {
                            status_code = 503,
                            body = json.encode({
                                error = {
                                    message = "Service temporarily unavailable",
                                    type = "service_unavailable"
                                }
                            }),
                            headers = {}
                        }
                    end
                }

                local response = status_handler.handler()

                expect(response.success).to_be_false()
                expect(response.status).to_equal("degraded")
                expect(response.message).to_equal("Service experiencing issues")
            end)

            it("should return degraded for internal server error (500)", function()
                status_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                status_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                status_handler._client._http_client = {
                    get = function(url, options)
                        return {
                            status_code = 500,
                            body = json.encode({
                                error = {
                                    message = "Internal server error",
                                    type = "server_error"
                                }
                            }),
                            headers = {}
                        }
                    end
                }

                local response = status_handler.handler()

                expect(response.success).to_be_false()
                expect(response.status).to_equal("degraded")
                expect(response.message).to_equal("Service experiencing issues")
            end)
        end)

        describe("Edge Cases", function()
            it("should handle empty response body gracefully", function()
                status_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                status_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                status_handler._client._http_client = {
                    get = function(url, options)
                        return {
                            status_code = 200,
                            body = "",
                            headers = {}
                        }
                    end
                }

                local response = status_handler.handler()

                expect(response.success).to_be_false()
                expect(response.status).to_equal("unhealthy")
                expect(response.message).to_contain("Failed to parse")
            end)

            it("should handle malformed JSON response", function()
                status_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                status_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                status_handler._client._http_client = {
                    get = function(url, options)
                        return {
                            status_code = 200,
                            body = "invalid json {",
                            headers = {}
                        }
                    end
                }

                local response = status_handler.handler()

                expect(response.success).to_be_false()
                expect(response.status).to_equal("unhealthy")
                expect(response.message).to_contain("Failed to parse")
            end)

            it("should handle custom base URL from context", function()
                status_handler._client._ctx = {
                    all = function()
                        return {
                            api_key = "test-key",
                            base_url = "https://custom.openai.proxy/v1"
                        }
                    end
                }

                status_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                status_handler._client._http_client = {
                    get = function(url, options)
                        expect(url).to_equal("https://custom.openai.proxy/v1/models")

                        return {
                            status_code = 200,
                            body = json.encode({ data = {} }),
                            headers = {}
                        }
                    end
                }

                local response = status_handler.handler()

                expect(response.success).to_be_true()
                expect(response.status).to_equal("healthy")
            end)

            it("should use GET method properly", function()
                status_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                status_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                local method_called = nil
                status_handler._client._http_client = {
                    get = function(url, options)
                        method_called = "GET"
                        expect(options.headers["Authorization"]).to_equal("Bearer test-key")
                        expect(options.headers["Content-Type"]).to_be_nil()
                        expect(options.body).to_be_nil()

                        return {
                            status_code = 200,
                            body = json.encode({ data = {} }),
                            headers = {}
                        }
                    end
                }

                local response = status_handler.handler()

                expect(response.success).to_be_true()
                expect(method_called).to_equal("GET")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)