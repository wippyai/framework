local bedrock_client = require("bedrock_client")
local json = require("json")

local function define_tests()
    describe("Bedrock Client", function()
        local original_http_client = bedrock_client._http_client
        local original_env = bedrock_client._env
        local original_ctx = bedrock_client._ctx
        local original_sigv4 = bedrock_client._sigv4
        local original_credentials = bedrock_client._credentials

        before_each(function()
            bedrock_client._env = {
                get = function(key)
                    return nil
                end
            }
            bedrock_client._credentials = {
                resolve = function()
                    return { access_key = "AKIDEXAMPLE", secret_key = "secret" }, nil
                end
            }
            bedrock_client._sigv4 = {
                sign_request = function(request)
                    return request.headers, nil
                end
            }
        end)

        after_each(function()
            bedrock_client._http_client = original_http_client
            bedrock_client._env = original_env
            bedrock_client._ctx = original_ctx
            bedrock_client._sigv4 = original_sigv4
            bedrock_client._credentials = original_credentials
        end)

        local function use_context(context)
            bedrock_client._ctx = {
                all = function()
                    return context
                end
            }
        end

        local function flaky_http(statuses: {number})
            local state = { calls = 0 }
            bedrock_client._http_client = {
                post = function(url, options)
                    state.calls = state.calls + 1
                    local status = statuses[state.calls]
                    if status == 200 then
                        return {
                            status_code = 200,
                            body = json.encode({ stopReason = "end_turn" }),
                            headers = {}
                        }
                    end
                    return {
                        status_code = status,
                        body = json.encode({ message = "Service unavailable" }),
                        headers = {}
                    }
                end
            }
            return state
        end

        describe("Retry", function()
            it("should retry a transient failure with context retry", function()
                use_context({ retry = { attempts = 2, backoff_ms = 0 } })
                local http = flaky_http({ 503, 200 })

                local response, err = bedrock_client.converse("test-model", { messages = {} })

                test.is_nil(err)
                test.eq(response.stopReason, "end_turn")
                test.eq(http.calls, 2)
            end)

            it("should send once without retry", function()
                use_context({})
                local http = flaky_http({ 503, 200 })

                local response, err = bedrock_client.converse("test-model", { messages = {} })

                test.is_nil(response)
                test.eq(err.status_code, 503)
                test.eq(err.message, "Service unavailable")
                test.eq(http.calls, 1)
            end)

            it("should let request retry override context retry", function()
                use_context({ retry = { attempts = 1, backoff_ms = 0 } })
                local http = flaky_http({ 503, 503, 200 })

                local response, err = bedrock_client.invoke("test-model", { inputText = "hi" }, {
                    retry = { attempts = 3, backoff_ms = 0 }
                })

                test.is_nil(err)
                test.eq(response.stopReason, "end_turn")
                test.eq(http.calls, 3)
            end)

            it("should send once when the request disables retry", function()
                use_context({ retry = { attempts = 3, backoff_ms = 0 } })
                local http = flaky_http({ 503, 200 })

                local response, err = bedrock_client.converse("test-model", { messages = {} }, { retry = false })

                test.is_nil(response)
                test.eq(err.status_code, 503)
                test.eq(http.calls, 1)
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
