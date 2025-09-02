local status_handler = require("status_handler")
local json = require("json")

local function define_tests()
    describe("Claude Status Handler", function()

        after_each(function()
            -- Clean up injected dependencies
            status_handler._client._ctx = nil
            status_handler._client._env = nil
            status_handler._client._http_client = nil
        end)

        describe("Health Check Success", function()
            it("should return healthy status when models API responds normally", function()
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
                        expect(url).to_contain("/v1/models")
                        expect(options.headers["x-api-key"]).to_equal("test-api-key")
                        expect(options.headers["anthropic-version"]).to_equal("2023-06-01")
                        expect(options.headers["content-type"]).to_be_nil()
                        expect(options.body).to_be_nil()
                        expect(options.timeout).to_equal(15)

                        return {
                            status_code = 200,
                            body = json.encode({
                                data = {
                                    { id = "claude-sonnet-4-20250514", type = "model", display_name = "Claude Sonnet 4" },
                                    { id = "claude-opus-4-1-20250805", type = "model", display_name = "Claude Opus 4.1" }
                                }
                            }),
                            headers = { ["request-id"] = "req_status_test" }
                        }
                    end
                }

                local response = status_handler.handler()

                expect(response.success).to_be_true()
                expect(response.status).to_equal("healthy")
                expect(response.message).to_equal("Claude API is responding normally")
            end)

            it("should resolve API key from context", function()
                status_handler._client._ctx = {
                    all = function()
                        return {
                            api_key_env = "CUSTOM_API_KEY",
                            base_url = "https://api.anthropic.com"
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
                        expect(options.headers["x-api-key"]).to_equal("custom-test-key")
                        expect(url).to_equal("https://api.anthropic.com/v1/models")

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

            it("should use custom API version from context", function()
                status_handler._client._ctx = {
                    all = function()
                        return {
                            api_key = "test-key",
                            api_version = "2024-02-01"
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
                        expect(options.headers["anthropic-version"]).to_equal("2024-02-01")

                        return {
                            status_code = 200,
                            body = json.encode({ data = {} }),
                            headers = {}
                        }
                    end
                }

                local response = status_handler.handler()

                expect(response.success).to_be_true()
            end)

            it("should handle beta features in headers", function()
                status_handler._client._ctx = {
                    all = function()
                        return {
                            api_key = "test-key",
                            beta_features = {"prompt-caching-2024-07-31"}
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
                        expect(options.headers["anthropic-beta"]).to_equal("prompt-caching-2024-07-31")

                        return {
                            status_code = 200,
                            body = json.encode({ data = {} }),
                            headers = {}
                        }
                    end
                }

                local response = status_handler.handler()

                expect(response.success).to_be_true()
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
                                type = "error",
                                error = {
                                    type = "authentication_error",
                                    message = "Invalid API key provided"
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

            it("should return unhealthy for permission errors", function()
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
                            status_code = 403,
                            body = json.encode({
                                type = "error",
                                error = {
                                    type = "permission_error",
                                    message = "Forbidden"
                                }
                            }),
                            headers = {}
                        }
                    end
                }

                local response = status_handler.handler()

                expect(response.success).to_be_false()
                expect(response.status).to_equal("unhealthy")
                expect(response.message).to_equal("Forbidden")
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
                expect(response.message).to_equal("Connection failed")
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
                                type = "error",
                                error = {
                                    type = "rate_limit_error",
                                    message = "Rate limit exceeded"
                                }
                            }),
                            headers = {
                                ["anthropic-ratelimit-requests-remaining"] = "0",
                                ["anthropic-ratelimit-requests-reset"] = "3600"
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
                                type = "error",
                                error = {
                                    type = "overloaded_error",
                                    message = "Service temporarily unavailable"
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
                                type = "error",
                                error = {
                                    type = "api_error",
                                    message = "Internal server error"
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
                            base_url = "https://custom.claude.proxy"
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
                        expect(url).to_equal("https://custom.claude.proxy/v1/models")

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
                        expect(options.headers["x-api-key"]).to_equal("test-key")
                        expect(options.headers["content-type"]).to_be_nil()
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

            it("should handle response with no models", function()
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
                            body = json.encode({
                                data = {},
                                has_more = false
                            }),
                            headers = {}
                        }
                    end
                }

                local response = status_handler.handler()

                expect(response.success).to_be_true()
                expect(response.status).to_equal("healthy")
                expect(response.message).to_equal("Claude API is responding normally")
            end)

            it("should handle timeout errors", function()
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
                            status_code = 408,
                            body = json.encode({
                                type = "error",
                                error = {
                                    message = "Request timeout"
                                }
                            }),
                            headers = {}
                        }
                    end
                }

                local response = status_handler.handler()

                expect(response.success).to_be_false()
                expect(response.status).to_equal("unhealthy")
                expect(response.message).to_equal("Request timeout")
            end)

            it("should validate proper GET request structure", function()
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

                local request_validated = false
                status_handler._client._http_client = {
                    get = function(url, options)
                        -- Validate all aspects of the GET request
                        expect(url).to_contain("https://api.anthropic.com/v1/models")
                        expect(options.headers["x-api-key"]).not_to_be_nil()
                        expect(options.headers["anthropic-version"]).not_to_be_nil()
                        expect(options.headers["content-type"]).to_be_nil()
                        expect(options.body).to_be_nil()
                        expect(options.timeout).to_equal(15)

                        request_validated = true

                        return {
                            status_code = 200,
                            body = json.encode({
                                data = {
                                    {
                                        id = "claude-sonnet-4-20250514",
                                        type = "model",
                                        display_name = "Claude Sonnet 4",
                                        created_at = "2025-02-19T00:00:00Z"
                                    }
                                }
                            }),
                            headers = {}
                        }
                    end
                }

                local response = status_handler.handler()

                expect(request_validated).to_be_true()
                expect(response.success).to_be_true()
                expect(response.status).to_equal("healthy")
            end)
        end)

        describe("Context Resolution Edge Cases", function()
            it("should fallback to default env vars when context is empty", function()
                status_handler._client._ctx = {
                    all = function()
                        return {}
                    end
                }

                status_handler._client._env = {
                    get = function(key)
                        if key == "ANTHROPIC_API_KEY" then return "fallback-key" end
                        if key == "ANTHROPIC_API_VERSION" then return "2024-01-01" end
                        return nil
                    end
                }

                status_handler._client._http_client = {
                    get = function(url, options)
                        expect(options.headers["x-api-key"]).to_equal("fallback-key")
                        expect(options.headers["anthropic-version"]).to_equal("2024-01-01")

                        return {
                            status_code = 200,
                            body = json.encode({ data = {} }),
                            headers = {}
                        }
                    end
                }

                local response = status_handler.handler()

                expect(response.success).to_be_true()
            end)

            it("should handle missing context gracefully", function()
                status_handler._client._ctx = {
                    all = function()
                        return nil
                    end
                }

                status_handler._client._env = {
                    get = function(key)
                        if key == "ANTHROPIC_API_KEY" then return "fallback-key" end
                        return nil
                    end
                }

                status_handler._client._http_client = {
                    get = function(url, options)
                        expect(options.headers["x-api-key"]).to_equal("fallback-key")

                        return {
                            status_code = 200,
                            body = json.encode({ data = {} }),
                            headers = {}
                        }
                    end
                }

                local response = status_handler.handler()

                expect(response.success).to_be_true()
            end)
        end)

        describe("Real Claude Error Scenarios", function()
            it("should handle Claude overloaded errors", function()
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
                            status_code = 529,
                            body = json.encode({
                                type = "error",
                                error = {
                                    type = "overloaded_error",
                                    message = "Overloaded"
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

            it("should handle Claude API error types", function()
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
                                type = "error",
                                error = {
                                    type = "api_error",
                                    message = "An unexpected error occurred"
                                }
                            }),
                            headers = {
                                ["request-id"] = "req_api_error_test"
                            }
                        }
                    end
                }

                local response = status_handler.handler()

                expect(response.success).to_be_false()
                expect(response.status).to_equal("degraded")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)