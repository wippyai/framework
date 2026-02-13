local status_handler = require("status_handler")
local json = require("json")
local test = require("test")

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
                        test.contains(url, "/models")
                        test.is_nil(options.headers["Content-Type"])
                        test.is_nil(options.body)

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

                test.is_true(response.success)
                test.eq(response.status, "healthy")
                test.eq(response.message, "OpenAI API is responding normally")
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
                        test.eq(options.headers["Authorization"], "Bearer custom-test-key")
                        test.eq(url, "https://api.openai.com/v1/models")

                        return {
                            status_code = 200,
                            body = json.encode({ data = {} }),
                            headers = {}
                        }
                    end
                }

                local response = status_handler.handler()

                test.is_true(response.success)
                test.eq(response.status, "healthy")
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

                test.is_false(response.success)
                test.eq(response.status, "unhealthy")
                test.contains(response.message, "Invalid API key")
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

                test.is_false(response.success)
                test.eq(response.status, "unhealthy")
                test.contains(response.message, "Connection failed")
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

                test.is_false(response.success)
                test.eq(response.status, "unhealthy")
                test.contains(response.message, "API key is required")
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

                test.is_false(response.success)
                test.eq(response.status, "unhealthy")
                test.eq(response.message, "Connection failed")
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

                test.is_false(response.success)
                test.eq(response.status, "degraded")
                test.eq(response.message, "Rate limited but service is available")
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

                test.is_false(response.success)
                test.eq(response.status, "degraded")
                test.eq(response.message, "Service experiencing issues")
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

                test.is_false(response.success)
                test.eq(response.status, "degraded")
                test.eq(response.message, "Service experiencing issues")
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

                test.is_false(response.success)
                test.eq(response.status, "unhealthy")
                test.contains(response.message, "Failed to parse")
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

                test.is_false(response.success)
                test.eq(response.status, "unhealthy")
                test.contains(response.message, "Failed to parse")
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
                        test.eq(url, "https://custom.openai.proxy/v1/models")

                        return {
                            status_code = 200,
                            body = json.encode({ data = {} }),
                            headers = {}
                        }
                    end
                }

                local response = status_handler.handler()

                test.is_true(response.success)
                test.eq(response.status, "healthy")
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
                        test.eq(options.headers["Authorization"], "Bearer test-key")
                        test.is_nil(options.headers["Content-Type"])
                        test.is_nil(options.body)

                        return {
                            status_code = 200,
                            body = json.encode({ data = {} }),
                            headers = {}
                        }
                    end
                }

                local response = status_handler.handler()

                test.is_true(response.success)
                test.eq(method_called, "GET")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
