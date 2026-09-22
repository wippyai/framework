local status_handler = require("status_handler")
local json = require("json")
local test = require("test")

local function define_tests()
    describe("TypeSafe Status Handler", function()

        after_each(function()
            -- Clean up injected dependencies
            status_handler._client._ctx = nil
            status_handler._client._env = nil
            status_handler._client._http_client = nil
        end)

        local function with_client(get)
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
            status_handler._client._http_client = { get = get }
        end

        describe("Health Check Success", function()
            it("should report healthy when the model list responds", function()
                with_client(function(url, options)
                    test.eq(url, "https://api.typesafe.ai/v1/models")
                    test.is_nil(options.body)
                    test.is_nil(options.headers["Content-Type"])

                    return {
                        status_code = 200,
                        body = json.encode({ models = { { name = "jev-latest" } } }),
                        headers = { ["x-typesafe-request-id"] = "req_status" }
                    }
                end)

                local response = status_handler.handler()

                test.is_true(response.success)
                test.eq(response.status, "healthy")
                test.eq(response.message, "TypeSafe API is responding normally")
            end)

            it("should resolve the API key from the environment", function()
                status_handler._client._ctx = {
                    all = function()
                        return { api_key_env = "CUSTOM_TYPESAFE_KEY" }
                    end
                }
                status_handler._client._env = {
                    get = function(key)
                        if key == "CUSTOM_TYPESAFE_KEY" then return "env-key" end
                        return nil
                    end
                }
                status_handler._client._http_client = {
                    get = function(url, options)
                        test.eq(options.headers["Authorization"], "Bearer env-key")
                        return { status_code = 200, body = json.encode({ models = {} }), headers = {} }
                    end
                }

                local response = status_handler.handler()

                test.is_true(response.success)
                test.eq(response.status, "healthy")
            end)
        end)

        describe("Health Check Failures", function()
            it("should report unhealthy on an authentication failure", function()
                with_client(function(url, options)
                    return {
                        status_code = 401,
                        body = json.encode({
                            detail = {
                                error_type = "authentication_error",
                                message = "Cannot authenticate with the server."
                            }
                        }),
                        headers = {}
                    }
                end)

                local response = status_handler.handler()

                test.is_false(response.success)
                test.eq(response.status, "unhealthy")
                test.contains(response.message, "Cannot authenticate")
            end)

            it("should report unhealthy on a transport failure", function()
                with_client(function(url, options)
                    return nil, "connection refused"
                end)

                local response = status_handler.handler()

                test.is_false(response.success)
                test.eq(response.status, "unhealthy")
                test.eq(response.message, "Connection failed")
            end)

            it("should report unhealthy without an API key", function()
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
                status_handler._client._http_client = {
                    get = function(url, options)
                        error("request must not be sent without an API key")
                    end
                }

                local response = status_handler.handler()

                test.is_false(response.success)
                test.eq(response.status, "unhealthy")
                test.contains(response.message, "TypeSafe API key is required")
            end)

            it("should report degraded when rate limited", function()
                with_client(function(url, options)
                    return {
                        status_code = 429,
                        body = json.encode({ detail = { message = "Rate limit exceeded" } }),
                        headers = {}
                    }
                end)

                local response = status_handler.handler()

                test.is_false(response.success)
                test.eq(response.status, "degraded")
                test.eq(response.message, "Rate limited but service is available")
            end)

            it("should report degraded when the service is overloaded", function()
                with_client(function(url, options)
                    return {
                        status_code = 529,
                        body = json.encode({ detail = { message = "Overloaded" } }),
                        headers = {}
                    }
                end)

                local response = status_handler.handler()

                test.is_false(response.success)
                test.eq(response.status, "degraded")
                test.eq(response.message, "Service experiencing issues")
            end)

            it("should report degraded on a server error", function()
                with_client(function(url, options)
                    return { status_code = 503, body = "upstream connect error", headers = {} }
                end)

                local response = status_handler.handler()

                test.is_false(response.success)
                test.eq(response.status, "degraded")
                test.eq(response.message, "Service experiencing issues")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
