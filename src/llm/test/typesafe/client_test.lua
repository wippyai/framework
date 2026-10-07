local typesafe_client = require("typesafe_client")
local json = require("json")
local test = require("test")

local function define_tests()
    describe("TypeSafe Client", function()

        after_each(function()
            -- Clean up injected dependencies
            typesafe_client._ctx = nil
            typesafe_client._env = nil
            typesafe_client._http_client = nil
        end)

        local function with_key(overrides)
            local ctx_all = overrides or {}
            if ctx_all.api_key == nil then
                ctx_all.api_key = "test-api-key"
            end
            typesafe_client._ctx = {
                all = function()
                    return ctx_all
                end
            }
            typesafe_client._env = {
                get = function(key)
                    return nil
                end
            }
        end

        describe("HTTP Method Support", function()
            it("should default to POST with a JSON body", function()
                with_key(nil)

                local called_method = nil
                typesafe_client._http_client = {
                    post = function(url, options)
                        called_method = "POST"
                        test.eq(url, "https://api.typesafe.ai/v1/systemone")
                        test.eq(options.headers["Content-Type"], "application/json")
                        test.eq(options.headers["Authorization"], "Bearer test-api-key")

                        local payload = json.decode(tostring(options.body))
                        test.eq(payload.model, "jev-latest")

                        return { status_code = 200, body = '{"model":"jev-1.13.0"}', headers = {} }
                    end
                }

                local response, err = typesafe_client.request("/systemone", { model = "jev-latest" })

                test.is_nil(err)
                assert(response)
                test.eq(called_method, "POST")
                test.eq(response.model, "jev-1.13.0")
            end)

            it("should support GET without a body", function()
                with_key(nil)

                local called_method = nil
                typesafe_client._http_client = {
                    get = function(url, options)
                        called_method = "GET"
                        test.eq(url, "https://api.typesafe.ai/v1/models")
                        test.is_nil(options.headers["Content-Type"])
                        test.is_nil(options.body)

                        return { status_code = 200, body = '{"models":[]}', headers = {} }
                    end
                }

                local response, err = typesafe_client.request("/models", nil, { method = "GET" })

                test.is_nil(err)
                test.eq(called_method, "GET")
            end)
        end)

        describe("Context Resolution", function()
            it("should take the API key straight from the context", function()
                with_key({ api_key = "ctx-key" })

                typesafe_client._http_client = {
                    get = function(url, options)
                        test.eq(options.headers["Authorization"], "Bearer ctx-key")
                        return { status_code = 200, body = "{}", headers = {} }
                    end
                }

                local response, err = typesafe_client.request("/models", nil, { method = "GET" })
                test.is_nil(err)
            end)

            it("should resolve the API key from the context-named environment variable", function()
                typesafe_client._ctx = {
                    all = function()
                        return { api_key_env = "CUSTOM_TYPESAFE_KEY" }
                    end
                }
                typesafe_client._env = {
                    get = function(key)
                        if key == "CUSTOM_TYPESAFE_KEY" then return "env-named-key" end
                        return nil
                    end
                }
                typesafe_client._http_client = {
                    get = function(url, options)
                        test.eq(options.headers["Authorization"], "Bearer env-named-key")
                        return { status_code = 200, body = "{}", headers = {} }
                    end
                }

                local response, err = typesafe_client.request("/models", nil, { method = "GET" })
                test.is_nil(err)
            end)

            it("should fall back to the default environment variables", function()
                typesafe_client._ctx = {
                    all = function()
                        return {}
                    end
                }
                typesafe_client._env = {
                    get = function(key)
                        if key == "TYPESAFE_API_KEY" then return "default-env-key" end
                        if key == "TYPESAFE_BASE_URL" then return "https://staging.typesafe.ai/v1" end
                        if key == "TYPESAFE_TIMEOUT" then return "15" end
                        return nil
                    end
                }
                typesafe_client._http_client = {
                    get = function(url, options)
                        test.eq(url, "https://staging.typesafe.ai/v1/models")
                        test.eq(options.headers["Authorization"], "Bearer default-env-key")
                        test.eq(options.timeout, 15)
                        return { status_code = 200, body = "{}", headers = {} }
                    end
                }

                local response, err = typesafe_client.request("/models", nil, { method = "GET" })
                test.is_nil(err)
            end)

            it("should prefer the context value over the environment", function()
                typesafe_client._ctx = {
                    all = function()
                        return { api_key = "ctx-key", base_url = "https://ctx.typesafe.ai/v1" }
                    end
                }
                typesafe_client._env = {
                    get = function(key)
                        return "env-value"
                    end
                }
                typesafe_client._http_client = {
                    get = function(url, options)
                        test.eq(url, "https://ctx.typesafe.ai/v1/models")
                        test.eq(options.headers["Authorization"], "Bearer ctx-key")
                        return { status_code = 200, body = "{}", headers = {} }
                    end
                }

                local response, err = typesafe_client.request("/models", nil, { method = "GET" })
                test.is_nil(err)
            end)

            it("should default the timeout to sixty seconds", function()
                with_key(nil)

                typesafe_client._http_client = {
                    get = function(url, options)
                        test.eq(options.timeout, 60)
                        return { status_code = 200, body = "{}", headers = {} }
                    end
                }

                local response, err = typesafe_client.request("/models", nil, { method = "GET" })
                test.is_nil(err)
            end)

            it("should let the call override the configured timeout", function()
                with_key({ timeout = 30 })

                typesafe_client._http_client = {
                    get = function(url, options)
                        test.eq(options.timeout, 5)
                        return { status_code = 200, body = "{}", headers = {} }
                    end
                }

                local response, err = typesafe_client.request("/models", nil, { method = "GET", timeout = 5 })
                test.is_nil(err)
            end)

            it("should merge context headers into the request", function()
                with_key({ headers = { ["X-Tenant"] = "acme" } })

                typesafe_client._http_client = {
                    get = function(url, options)
                        test.eq(options.headers["X-Tenant"], "acme")
                        test.eq(options.headers["Authorization"], "Bearer test-api-key")
                        return { status_code = 200, body = "{}", headers = {} }
                    end
                }

                local response, err = typesafe_client.request("/models", nil, { method = "GET" })
                test.is_nil(err)
            end)

            it("should refuse to call without an API key", function()
                typesafe_client._ctx = {
                    all = function()
                        return {}
                    end
                }
                typesafe_client._env = {
                    get = function(key)
                        return nil
                    end
                }
                typesafe_client._http_client = {
                    get = function(url, options)
                        error("request must not be sent without an API key")
                    end
                }

                local response, err = typesafe_client.request("/models", nil, { method = "GET" })

                test.is_nil(response)
                assert(err)
                test.eq(err.status_code, 401)
                test.contains(tostring(err.message), "TypeSafe API key is required")
            end)
        end)

        describe("Error Handling", function()
            it("should read the message out of a detail object", function()
                with_key(nil)

                typesafe_client._http_client = {
                    get = function(url, options)
                        return {
                            status_code = 401,
                            body = json.encode({
                                detail = {
                                    error_type = "authentication_error",
                                    message = "Cannot authenticate with the server."
                                }
                            }),
                            headers = { ["x-typesafe-request-id"] = "req_auth" }
                        }
                    end
                }

                local response, err = typesafe_client.request("/models", nil, { method = "GET" })

                test.is_nil(response)
                assert(err)
                test.eq(err.status_code, 401)
                test.eq(err.message, "Cannot authenticate with the server.")
                test.eq(err.error_type, "authentication_error")
                test.eq(err.metadata.request_id, "req_auth")
            end)

            it("should flatten a validation detail list into the message", function()
                with_key(nil)

                typesafe_client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 422,
                            body = json.encode({
                                detail = {
                                    { type = "missing", loc = { "body", "state" }, msg = "Field required" }
                                }
                            }),
                            headers = {}
                        }
                    end
                }

                local response, err = typesafe_client.request("/systemone", { model = "jev-latest" })

                test.is_nil(response)
                assert(err)
                test.eq(err.status_code, 422)
                test.contains(tostring(err.message), "body.state")
                test.contains(tostring(err.message), "Field required")
            end)

            it("should keep a non-JSON error body in the message", function()
                with_key(nil)

                typesafe_client._http_client = {
                    get = function(url, options)
                        return {
                            status_code = 502,
                            body = "upstream connect error",
                            headers = {}
                        }
                    end
                }

                local response, err = typesafe_client.request("/models", nil, { method = "GET" })

                test.is_nil(response)
                assert(err)
                test.eq(err.status_code, 502)
                test.contains(tostring(err.message), "upstream connect error")
            end)

            it("should report a transport failure without a status", function()
                with_key(nil)

                typesafe_client._http_client = {
                    get = function(url, options)
                        return nil, "dial tcp: connection refused"
                    end
                }

                local response, err = typesafe_client.request("/models", nil, { method = "GET" })

                test.is_nil(response)
                assert(err)
                test.eq(err.status_code, 0)
                test.contains(tostring(err.message), "connection refused")
            end)

            it("should capture the retry-after header on a rate limit", function()
                with_key(nil)

                typesafe_client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 429,
                            body = json.encode({ detail = { message = "Rate limit exceeded" } }),
                            headers = { ["retry-after"] = "12", ["x-typesafe-request-id"] = "req_rate" }
                        }
                    end
                }

                local response, err = typesafe_client.request("/systemone", { model = "jev-latest" })

                test.is_nil(response)
                assert(err)
                test.eq(err.metadata.retry_after, 12)
                test.eq(err.metadata.request_id, "req_rate")
            end)

            it("should report an undecodable success body", function()
                with_key(nil)

                typesafe_client._http_client = {
                    get = function(url, options)
                        return { status_code = 200, body = "not json at all", headers = {} }
                    end
                }

                local response, err = typesafe_client.request("/models", nil, { method = "GET" })

                test.is_nil(response)
                assert(err)
                test.eq(err.status_code, 200)
                test.contains(tostring(err.message), "Failed to parse TypeSafe response")
            end)
            it("should reject a valid JSON scalar on a successful response", function()
                with_key(nil)
                typesafe_client._http_client = {
                    get = function(url, options)
                        return { status_code = 200, body = "null", headers = {} }
                    end
                }
                local response, err = typesafe_client.request("/models", nil, { method = "GET" })
                test.is_nil(response)
                assert(err)
                test.contains(tostring(err.message), "expected a JSON object")
            end)
        end)

        describe("Response Metadata", function()
            it("should expose the request id on a successful response", function()
                with_key(nil)

                typesafe_client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = json.encode({ model = "jev-1.13.0", answers = {} }),
                            headers = { ["x-typesafe-request-id"] = "req_ok" }
                        }
                    end
                }

                local response, err = typesafe_client.request("/systemone", { model = "jev-latest" })

                test.is_nil(err)
                assert(response)
                test.eq(response.metadata.request_id, "req_ok")
            end)

            it("should find the request id under a canonicalized header name", function()
                with_key(nil)

                typesafe_client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = json.encode({ model = "jev-1.13.0", answers = {} }),
                            headers = { ["X-Typesafe-Request-Id"] = "req_canonical" }
                        }
                    end
                }

                local response, err = typesafe_client.request("/systemone", { model = "jev-latest" })

                test.is_nil(err)
                assert(response)
                test.eq(response.metadata.request_id, "req_canonical")
            end)

            it("should find retry-after under a canonicalized header name", function()
                with_key(nil)

                typesafe_client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 429,
                            body = json.encode({ detail = { message = "Rate limit exceeded" } }),
                            headers = { ["Retry-After"] = "30" }
                        }
                    end
                }

                local response, err = typesafe_client.request("/systemone", { model = "jev-latest" })

                test.is_nil(response)
                assert(err)
                test.eq(err.metadata.retry_after, 30)
            end)

            it("should leave metadata empty when the response carries no headers", function()
                with_key(nil)

                typesafe_client._http_client = {
                    post = function(url, options)
                        return { status_code = 200, body = json.encode({ model = "jev-1.13.0" }), headers = {} }
                    end
                }

                local response, err = typesafe_client.request("/systemone", { model = "jev-latest" })

                test.is_nil(err)
                assert(response)
                test.is_nil(response.metadata.request_id)
            end)
        end)

        describe("Retry", function()
            it("should retry a server error and return the eventual success", function()
                with_key({ retry = { attempts = 3, backoff_ms = 0 } })

                local calls = 0
                typesafe_client._http_client = {
                    post = function(url, options)
                        calls = calls + 1
                        if calls < 3 then
                            return { status_code = 503, body = json.encode({ detail = { message = "unavailable" } }), headers = {} }
                        end
                        return { status_code = 200, body = json.encode({ model = "jev-1.13.0" }), headers = {} }
                    end
                }

                local response, err = typesafe_client.request("/systemone", { model = "jev-latest" })

                test.is_nil(err)
                assert(response)
                test.eq(calls, 3)
                test.eq(response.model, "jev-1.13.0")
            end)

            it("should give up once the attempts are exhausted", function()
                with_key({ retry = { attempts = 2, backoff_ms = 0 } })

                local calls = 0
                typesafe_client._http_client = {
                    post = function(url, options)
                        calls = calls + 1
                        return { status_code = 529, body = json.encode({ detail = { message = "overloaded" } }), headers = {} }
                    end
                }

                local response, err = typesafe_client.request("/systemone", { model = "jev-latest" })

                test.is_nil(response)
                assert(err)
                test.eq(calls, 3)
                test.eq(err.status_code, 529)
            end)

            it("should not retry a non-retryable status", function()
                with_key({ retry = { attempts = 3, backoff_ms = 0 } })

                local calls = 0
                typesafe_client._http_client = {
                    post = function(url, options)
                        calls = calls + 1
                        return { status_code = 401, body = json.encode({ detail = { message = "bad key" } }), headers = {} }
                    end
                }

                local response, err = typesafe_client.request("/systemone", { model = "jev-latest" })

                test.is_nil(response)
                test.eq(calls, 1)
            end)

            it("should retry a transport failure", function()
                with_key({ retry = { attempts = 2, backoff_ms = 0 } })

                local calls = 0
                typesafe_client._http_client = {
                    post = function(url, options)
                        calls = calls + 1
                        if calls == 1 then
                            return nil, "connection reset"
                        end
                        return { status_code = 200, body = json.encode({ model = "jev-1.13.0" }), headers = {} }
                    end
                }

                local response, err = typesafe_client.request("/systemone", { model = "jev-latest" })

                test.is_nil(err)
                test.eq(calls, 2)
            end)

            it("should let the call retry policy replace the configured one", function()
                with_key({ retry = { attempts = 5, backoff_ms = 0 } })

                local calls = 0
                typesafe_client._http_client = {
                    post = function(url, options)
                        calls = calls + 1
                        return { status_code = 500, body = json.encode({ detail = { message = "boom" } }), headers = {} }
                    end
                }

                local response, err = typesafe_client.request("/systemone", { model = "jev-latest" }, {
                    retry = { attempts = 1, backoff_ms = 0 }
                })

                test.is_nil(response)
                test.eq(calls, 2)
            end)

            it("should send a single request when no retry policy is configured", function()
                with_key(nil)

                local calls = 0
                typesafe_client._http_client = {
                    post = function(url, options)
                        calls = calls + 1
                        return { status_code = 500, body = json.encode({ detail = { message = "boom" } }), headers = {} }
                    end
                }

                local response, err = typesafe_client.request("/systemone", { model = "jev-latest" })

                test.is_nil(response)
                test.eq(calls, 1)
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
