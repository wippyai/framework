local test = require("test")
local transport = require("transport")

type Sender = {
    count: () -> number,
    send: () -> (transport.HttpResponse?, string?)
}

local function define_tests()
    describe("Provider Transport", function()
        describe("config_value", function()
            local env_values = {
                CUSTOM_KEY = "from-custom-env",
                DEFAULT_KEY = "from-default-env",
                EMPTY_KEY = ""
            }
            local env_module = {
                get = function(name) return env_values[name] end
            }

            it("should prefer a literal context value", function()
                test.eq(transport.config_value({ api_key = "literal", api_key_env = "CUSTOM_KEY" }, env_module, "api_key", "DEFAULT_KEY"), "literal")
            end)

            it("should read the env variable named by the context", function()
                test.eq(transport.config_value({ api_key_env = "CUSTOM_KEY" }, env_module, "api_key", "DEFAULT_KEY"), "from-custom-env")
            end)

            it("should fall back to the default env variable when the named one is empty", function()
                test.eq(transport.config_value({ api_key_env = "EMPTY_KEY" }, env_module, "api_key", "DEFAULT_KEY"), "from-default-env")
            end)

            it("should stringify non-string context values", function()
                test.eq(transport.config_value({ timeout = 30 }, env_module, "timeout"), "30")
            end)

            it("should return nil when nothing is configured", function()
                test.is_nil(transport.config_value({}, env_module, "api_key", "MISSING_KEY"))
                test.is_nil(transport.config_value({}, env_module, "api_key"))
            end)
        end)

        describe("normalize_retry", function()
            it("should reject missing or non-positive attempts", function()
                test.is_nil(transport.normalize_retry(nil))
                test.is_nil(transport.normalize_retry("3"))
                test.is_nil(transport.normalize_retry({ attempts = 0 }))
                test.is_nil(transport.normalize_retry({ backoff_ms = 100 }))
            end)

            it("should default backoff and clamp both bounds", function()
                local retry = transport.normalize_retry({ attempts = "2" })
                test.eq(retry.attempts, 2)
                test.eq(retry.backoff_ms, 500)

                local clamped = transport.normalize_retry({ attempts = 50, backoff_ms = 999999 })
                test.eq(clamped.attempts, 10)
                test.eq(clamped.backoff_ms, 60000)

                test.eq(transport.normalize_retry({ attempts = 1, backoff_ms = -5 }).backoff_ms, 0)
            end)
        end)

        describe("request_retry", function()
            it("should use the context policy when the request sets none", function()
                local context_retry = { attempts = 2, backoff_ms = 0 }
                test.eq(transport.request_retry(nil, context_retry), context_retry)
                test.is_nil(transport.request_retry(nil, nil))
            end)

            it("should prefer the normalized request policy", function()
                local retry = transport.request_retry({ attempts = 4, backoff_ms = 10 }, { attempts = 2, backoff_ms = 0 })
                test.eq(retry.attempts, 4)
                test.eq(retry.backoff_ms, 10)
            end)

            it("should disable retry when the request sets false", function()
                test.is_nil(transport.request_retry(false, { attempts = 2, backoff_ms = 0 }))
            end)
        end)

        describe("retryable", function()
            it("should retry connection failures, timeouts, conflicts, throttling and server errors", function()
                for _, status in ipairs({ 0, 408, 409, 425, 429, 500, 503, 599 }) do
                    test.ok(transport.retryable({ status_code = status }), "status " .. status)
                end
            end)

            it("should not retry client errors", function()
                for _, status in ipairs({ 400, 401, 403, 404, 422 }) do
                    test.ok(not transport.retryable({ status_code = status }), "status " .. status)
                end
            end)
        end)

        describe("dispatch", function()
            local calls
            local http = {}
            for _, verb in ipairs({ "get", "post", "put", "patch", "delete" }) do
                http[verb] = function(url, options)
                    table.insert(calls, verb)
                    return { status_code = 200, url = url, options = options }
                end
            end

            before_each(function()
                calls = {}
            end)

            it("should route each method to its http client verb", function()
                for _, method in ipairs({ "GET", "POST", "PUT", "PATCH", "DELETE" }) do
                    transport.dispatch(http, method, "https://api.test/x", {})
                end
                test.eq(table.concat(calls, ","), "get,post,put,patch,delete")
            end)

            it("should raise on an unsupported method", function()
                test.throws(function()
                    transport.dispatch(http, "TRACE", "https://api.test/x", {})
                end)
                test.eq(#calls, 0)
            end)
        end)

        describe("send", function()
            local function parse_error(response)
                return { status_code = response.status_code, message = "HTTP " .. response.status_code }
            end

            local function sequence(responses: {any}): Sender
                local index = 0
                return {
                    count = function(): number
                        return index
                    end,
                    send = function(): (transport.HttpResponse?, string?)
                        index = index + 1
                        local entry = responses[index]
                        if entry.error then
                            return nil, entry.error
                        end
                        return entry :: transport.HttpResponse, nil
                    end
                }
            end

            it("should return a successful response on the first attempt", function()
                local sender = sequence({ { status_code = 200, body = "ok" } })
                local response, err = transport.send(sender.send, parse_error, nil)
                test.is_nil(err)
                test.eq(response.body, "ok")
                test.eq(sender.count(), 1)
            end)

            it("should report a connection failure", function()
                local sender = sequence({ { error = "dial tcp: refused" } })
                local response, err = transport.send(sender.send, parse_error, nil)
                test.is_nil(response)
                test.eq(err.status_code, 0)
                test.eq(err.message, "Connection failed: dial tcp: refused")
            end)

            it("should map a non-2xx response through the provider parser", function()
                local sender = sequence({ { status_code = 404 } })
                local response, err = transport.send(sender.send, parse_error, { attempts = 3, backoff_ms = 0 })
                test.is_nil(response)
                test.eq(err.message, "HTTP 404")
                test.eq(sender.count(), 1)
            end)

            it("should retry retryable failures until success", function()
                local sender = sequence({
                    { status_code = 503 },
                    { error = "reset" },
                    { status_code = 201, body = "created" }
                })
                local response, err = transport.send(sender.send, parse_error, { attempts = 3, backoff_ms = 0 })
                test.is_nil(err)
                test.eq(response.body, "created")
                test.eq(sender.count(), 3)
            end)

            it("should stop after the configured attempts and return the last error", function()
                local sender = sequence({
                    { status_code = 500 },
                    { status_code = 502 },
                    { status_code = 429 }
                })
                local response, err = transport.send(sender.send, parse_error, { attempts = 2, backoff_ms = 0 })
                test.is_nil(response)
                test.eq(err.status_code, 429)
                test.eq(sender.count(), 3)
            end)
        end)

        describe("health_failure", function()
            it("should mark connection failures unhealthy", function()
                local result = transport.health_failure({ status_code = 0, message = "dial tcp" })
                test.eq(result.success, false)
                test.eq(result.status, "unhealthy")
                test.eq(result.message, "Connection failed")
            end)

            it("should mark throttling and server errors degraded", function()
                local throttled = transport.health_failure({ status_code = 429, message = "slow down" })
                test.eq(throttled.status, "degraded")
                test.eq(throttled.message, "Rate limited but service is available")

                local server = transport.health_failure({ status_code = 503, message = "down" })
                test.eq(server.status, "degraded")
                test.eq(server.message, "Service experiencing issues")
            end)

            it("should mark auth failures unhealthy with the provider message", function()
                local forbidden = transport.health_failure({ status_code = 403, message = "forbidden" })
                test.eq(forbidden.status, "unhealthy")
                test.eq(forbidden.message, "forbidden")
            end)

            it("should keep the provider message for other client errors", function()
                local result = transport.health_failure({ status_code = 404, message = "no such route" })
                test.eq(result.status, "unhealthy")
                test.eq(result.message, "no such route")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
