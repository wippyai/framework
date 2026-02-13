local status = require("google_status")
local tests = require("test")

local function define_tests()
    describe("Google Status Handler", function()

        after_each(function()
            status._contract = nil
            status._ctx = nil
        end)

        describe("Health Check Success", function()
            it("should return healthy status when API responds normally", function()
                status._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end,
                    get = function(key)
                        if key == "client_id" then
                            return "test-client-id"
                        end
                        return nil
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        tests.not_nil(args.model)
                        tests.eq(args.options.method, "GET")

                        return {
                            status_code = 200,
                            candidates = {
                                {
                                    content = {
                                        parts = {{ text = "Test response" }}
                                    },
                                    finishReason = "STOP"
                                }
                            }
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        tests.not_nil(context)
                        return self
                    end,
                    open = function(self, client_id)
                        tests.eq(client_id, "test-client-id")
                        return mock_client_instance, nil
                    end
                }

                status._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-pro"
                }

                local response = status.handler(contract_args)

                tests.is_true(response.success)
                tests.eq(response.status, "healthy")
                tests.eq(response.message, "Google API is responding normally")
            end)

            it("should resolve API configuration from context", function()
                status._ctx = {
                    all = function()
                        return {
                            api_key = "custom-api-key",
                            location = "us-central1",
                            project_id = "test-project"
                        }
                    end,
                    get = function(key)
                        if key == "client_id" then
                            return "custom-client-id"
                        end
                        return nil
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        return {
                            status_code = 200,
                            candidates = {{
                                content = { parts = {{ text = "OK" }} },
                                finishReason = "STOP"
                            }}
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        tests.eq(context.api_key, "custom-api-key")
                        tests.eq(context.location, "us-central1")
                        tests.eq(context.project_id, "test-project")
                        return self
                    end,
                    open = function(self, client_id)
                        tests.eq(client_id, "custom-client-id")
                        return mock_client_instance, nil
                    end
                }

                status._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-pro"
                }

                local response = status.handler(contract_args)

                tests.is_true(response.success)
                tests.eq(response.status, "healthy")
            end)
        end)

        describe("Health Check Failures", function()
            it("should return unhealthy for authentication errors", function()
                status._ctx = {
                    all = function()
                        return { api_key = "invalid-key" }
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        return {
                            status_code = 401,
                            message = "Invalid API key provided"
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                status._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-pro"
                }

                local response = status.handler(contract_args)

                tests.is_false(response.success)
                tests.eq(response.status, "unhealthy")
                tests.eq(response.message, "Invalid API key provided")
            end)

            it("should return unhealthy for network errors", function()
                status._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        return {
                            status_code = 0,
                            message = "Connection failed"
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                status._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-pro"
                }

                local response = status.handler(contract_args)

                tests.is_false(response.success)
                tests.eq(response.status, "unhealthy")
                tests.eq(response.message, "Connection failed")
            end)

            it("should return unhealthy for forbidden errors", function()
                status._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        return {
                            status_code = 403,
                            message = "Forbidden - insufficient permissions"
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                status._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-pro"
                }

                local response = status.handler(contract_args)

                tests.is_false(response.success)
                tests.eq(response.status, "unhealthy")
                tests.eq(response.message, "Forbidden - insufficient permissions")
            end)

            it("should return unhealthy for not found errors", function()
                status._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        return {
                            status_code = 404,
                            message = "Model not found"
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                status._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-pro"
                }

                local response = status.handler(contract_args)

                tests.is_false(response.success)
                tests.eq(response.status, "unhealthy")
                tests.eq(response.message, "Model not found")
            end)
        end)

        describe("Degraded Status", function()
            it("should return degraded for rate limit errors", function()
                status._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        return {
                            status_code = 429,
                            message = "Rate limit exceeded"
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                status._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-pro"
                }

                local response = status.handler(contract_args)

                tests.is_false(response.success)
                tests.eq(response.status, "degraded")
                tests.eq(response.message, "Rate limited but service is available")
            end)

            it("should return degraded for internal server error (500)", function()
                status._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        return {
                            status_code = 500,
                            message = "Internal server error"
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                status._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-pro"
                }

                local response = status.handler(contract_args)

                tests.is_false(response.success)
                tests.eq(response.status, "degraded")
                tests.eq(response.message, "Service experiencing issues")
            end)

            it("should return degraded for service unavailable (503)", function()
                status._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        return {
                            status_code = 503,
                            message = "Service temporarily unavailable"
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                status._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-pro"
                }

                local response = status.handler(contract_args)

                tests.is_false(response.success)
                tests.eq(response.status, "degraded")
                tests.eq(response.message, "Service experiencing issues")
            end)

            it("should return degraded for bad gateway (502)", function()
                status._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        return {
                            status_code = 502,
                            message = "Bad gateway"
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                status._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-pro"
                }

                local response = status.handler(contract_args)

                tests.is_false(response.success)
                tests.eq(response.status, "degraded")
                tests.eq(response.message, "Service experiencing issues")
            end)

            it("should return degraded for gateway timeout (504)", function()
                status._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        return {
                            status_code = 504,
                            message = "Gateway timeout"
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                status._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-pro"
                }

                local response = status.handler(contract_args)

                tests.is_false(response.success)
                tests.eq(response.status, "degraded")
                tests.eq(response.message, "Service experiencing issues")
            end)
        end)

        describe("Contract Errors", function()
            it("should handle contract retrieval error", function()
                status._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                status._contract = {
                    get = function(contract_id)
                        return nil, "Contract not found"
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-pro"
                }

                local response = status.handler(contract_args)

                tests.is_false(response.success)
                tests.eq(response.status, 500)
                tests.contains(response.message, "Failed to get client contract")
            end)

            it("should handle client binding error", function()
                status._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return nil, "Failed to initialize client"
                    end
                }

                status._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-pro"
                }

                local response = status.handler(contract_args)

                tests.is_false(response.success)
                tests.eq(response.status, 500)
                tests.contains(response.message, "Failed to open client binding")
            end)
        end)

        describe("Edge Cases", function()
            it("should handle response with message but no explicit error status", function()
                status._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        return {
                            status_code = 400,
                            message = "Bad request"
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                status._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-pro"
                }

                local response = status.handler(contract_args)

                tests.is_false(response.success)
                tests.eq(response.status, "unhealthy")
                tests.eq(response.message, "Bad request")
            end)

            it("should handle response without message field", function()
                status._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        return {
                            status_code = 500
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                status._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-pro"
                }

                local response = status.handler(contract_args)

                tests.is_false(response.success)
                tests.eq(response.status, "degraded")
                tests.eq(response.message, "Service experiencing issues")
            end)

            it("should handle empty context", function()
                status._ctx = {
                    all = function()
                        return {}
                    end,
                    get = function(key)
                        if key == "client_id" then
                            return "default-client-id"
                        end
                        return nil
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        return {
                            status_code = 200,
                            candidates = {{
                                content = { parts = {{ text = "OK" }} },
                                finishReason = "STOP"
                            }}
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        tests.eq(type(context), "table")
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                status._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-pro"
                }

                local response = status.handler(contract_args)

                tests.is_true(response.success)
                tests.eq(response.status, "healthy")
            end)

            it("should handle nil context gracefully", function()
                status._ctx = {
                    all = function()
                        return nil
                    end,
                    get = function(key)
                        if key == "client_id" then
                            return "default-client-id"
                        end
                        return nil
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        return {
                            status_code = 200,
                            candidates = {{
                                content = { parts = {{ text = "OK" }} },
                                finishReason = "STOP"
                            }}
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        tests.eq(type(context), "table")
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                status._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-pro"
                }

                local response = status.handler(contract_args)

                tests.is_true(response.success)
                tests.eq(response.status, "healthy")
            end)

            it("should use GET method for health check request", function()
                local method_verified = false

                status._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end,
                    get = function(key)
                        return "test-client-id"
                    end
                }

                local mock_client_instance = {
                    request = function(self, args)
                        tests.eq(args.options.method, "GET")
                        method_verified = true

                        return {
                            status_code = 200,
                            candidates = {{
                                content = { parts = {{ text = "OK" }} },
                                finishReason = "STOP"
                            }}
                        }
                    end
                }

                local mock_contract = {
                    with_context = function(self, context)
                        return self
                    end,
                    open = function(self, client_id)
                        return mock_client_instance, nil
                    end
                }

                status._contract = {
                    get = function(contract_id)
                        return mock_contract, nil
                    end
                }

                local contract_args = {
                    model = "gemini-2.5-pro"
                }

                status.handler(contract_args)

                tests.is_true(method_verified)
            end)

            it("should handle all 5xx status codes as degraded", function()
                local status_codes = { 500, 501, 502, 503, 504, 505, 599 }

                for _, code in ipairs(status_codes) do
                    status._ctx = {
                        all = function()
                            return { api_key = "test-key" }
                        end,
                        get = function(key)
                            return "test-client-id"
                        end
                    }

                    local mock_client_instance = {
                        request = function(self, args)
                            return {
                                status_code = code,
                                message = "Server error " .. code
                            }
                        end
                    }

                    local mock_contract = {
                        with_context = function(self, context)
                            return self
                        end,
                        open = function(self, client_id)
                            return mock_client_instance, nil
                        end
                    }

                    status._contract = {
                        get = function(contract_id)
                            return mock_contract, nil
                        end
                    }

                    local contract_args = {
                        model = "gemini-2.5-pro"
                    }

                    local response = status.handler(contract_args)

                    tests.eq(response.status, "degraded")
                    tests.eq(response.message, "Service experiencing issues")
                end
            end)

            it("should handle 4xx errors other than 429 as unhealthy", function()
                local status_codes = { 400, 402, 404, 405, 409, 422 }

                for _, code in ipairs(status_codes) do
                    status._ctx = {
                        all = function()
                            return { api_key = "test-key" }
                        end,
                        get = function(key)
                            return "test-client-id"
                        end
                    }

                    local mock_client_instance = {
                        request = function(self, args)
                            return {
                                status_code = code,
                                message = "Client error " .. code
                            }
                        end
                    }

                    local mock_contract = {
                        with_context = function(self, context)
                            return self
                        end,
                        open = function(self, client_id)
                            return mock_client_instance, nil
                        end
                    }

                    status._contract = {
                        get = function(contract_id)
                            return mock_contract, nil
                        end
                    }

                    local contract_args = {
                        model = "gemini-2.5-pro"
                    }

                    local response = status.handler(contract_args)

                    tests.eq(response.status, "unhealthy")
                end
            end)
        end)
    end)
end

return tests.run_cases(define_tests)
