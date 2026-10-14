local client = require("google_client")
local json = require("json")
local tests = require("test")

local function define_tests()
    describe("Google HTTP Client", function()
        describe("Foundation stream framing", function()
            it("preserves structured stream errors and never reports completion after one", function()
                local consumed, completed, observed = false, false, nil
                local stream = { read = function()
                    if consumed then return nil end
                    consumed = true
                    return 'data: {"error":{"message":"quota exceeded","code":429,"status":"RESOURCE_EXHAUSTED"}}\n\n'
                end }
                local content, err = client.process_stream({ stream = stream }, {
                    on_error = function(info: any): nil observed = info; return nil end,
                    on_done = function(_result: any): nil completed = true; return nil end,
                })
                tests.is_nil(content)
                tests.eq(err, "quota exceeded")
                assert(observed)
                tests.eq(observed.message, "quota exceeded")
                tests.eq(observed.code, 429)
                tests.eq(observed.status, "RESOURCE_EXHAUSTED")
                tests.is_false(completed)
            end)
            local function fake_stream(chunks)
                local index = 0
                return { read = function()
                    index = index + 1
                    return chunks[index]
                end }
            end

            local function event(candidate)
                return "data: " .. json.encode({ candidates = { candidate } }) .. "\n\n"
            end

            it("preserves text deltas exactly once when events share a read", function()
                local seen = {}
                local data = event({ content = { parts = {{ text = "First. " }} } })
                    .. event({ content = { parts = {{ text = "Second." }} }, finishReason = "STOP" })
                local content, err, result = client.process_stream({ stream = fake_stream({ data }) }, {
                    on_content = function(text: string): nil seen[#seen + 1] = text; return nil end,
                })
                tests.is_nil(err)
                tests.eq(content, "First. Second.")
                tests.eq(table.concat(seen), content)
                tests.eq(result.finish_reason, "STOP")
            end)

            it("foundation regression: retains a text event split across transport reads", function()
                local data = event({ content = { parts = {{ text = "Platform failed: permission denied" }} } })
                local split = math.floor(#data / 2)
                local content, err = client.process_stream({ stream = fake_stream({
                    data:sub(1, split), data:sub(split + 1), event({ finishReason = "STOP" }),
                }) })
                tests.is_nil(err)
                tests.eq(content, "Platform failed: permission denied")
            end)

            it("foundation regression: retains a tool event split across transport reads", function()
                local data = event({ content = { parts = {{
                    functionCall = { name = "Platform", args = { action = "connections" } },
                }} } })
                local split = math.floor(#data / 2)
                local _, err, result = client.process_stream({ stream = fake_stream({
                    data:sub(1, split), data:sub(split + 1), event({ finishReason = "STOP" }),
                }) })
                tests.is_nil(err)
                tests.eq(#result.tool_calls, 1)
                tests.eq(result.tool_calls[1].functionCall.name, "Platform")
            end)

            it("preserves IDs and feedback at every possible transport split", function()
                local data = event({ content = { parts = {
                    { text = "A failed call is not success. " },
                    { functionCall = { id = "native-call", name = "Platform", args = { action = "retry" } } },
                } }, finishReason = "STOP" })
                for split = 1, #data - 1 do
                    local ids = {}
                    local content, err, result = client.process_stream({ stream = fake_stream({
                        data:sub(1, split), data:sub(split + 1),
                    }) }, { on_tool_call = function(part: any): nil ids[#ids + 1] = part._call_id; return nil end })
                    tests.is_nil(err)
                    tests.eq(content, "A failed call is not success. ")
                    tests.eq(#result.tool_calls, 1)
                    tests.eq(#ids, 1)
                    tests.eq(ids[1], "native-call")
                    tests.eq(result.tool_calls[1]._call_id, ids[1])
                end
            end)

            it("handles comments, CRLF and multiline data fields", function()
                local content, err = client.process_stream({ stream = fake_stream({
                    ': keepalive\r', '\nevent: message\r\ndata: {"candidates":\r\n',
                    'data: [{"content":{"parts":[{"text":"received"}]}}]}\r\n\r\n',
                }) })
                tests.is_nil(err)
                tests.eq(content, "received")
            end)

            it("handles every transport split of CRLF and lone CR event delimiters", function()
                for _, newline in ipairs({ "\r\n", "\r" }) do
                    local data = 'data: {"candidates":[{"content":{"parts":[{"text":"once"}]}}]}'
                        .. newline .. newline
                    for split = 1, #data - 1 do
                        local content, err = client.process_stream({ stream = fake_stream({
                            data:sub(1, split), data:sub(split + 1),
                        }) })
                        tests.is_nil(err)
                        tests.eq(content, "once")
                    end
                end
            end)

            it("does not silently discard malformed or torn final events", function()
                for _, data in ipairs({ 'data: {broken}\n\n', 'data: {"candidates":' }) do
                    local errors, completions = 0, 0
                    local content, err = client.process_stream({ stream = fake_stream({data}) }, {
                        on_error = function(_info: any): nil errors = errors + 1; return nil end,
                        on_done = function(_result: any): nil completions = completions + 1; return nil end,
                    })
                    tests.is_nil(content)
                    tests.not_nil(err)
                    tests.eq(errors, 1)
                    tests.eq(completions, 0)
                end
            end)

            it("flushes valid final data without a newline and honors the done marker", function()
                local data = event({ content = { parts = {{ text = "final" }} } })
                local content, err = client.process_stream({ stream = fake_stream({data:sub(1, -3)}) })
                tests.is_nil(err)
                tests.eq(content, "final")
                content, err = client.process_stream({ stream = fake_stream({
                    data .. 'data: [DONE]\n\ndata: {invalid ignored after completion}\n\n',
                }) })
                tests.is_nil(err)
                tests.eq(content, "final")
            end)
        end)

        after_each(function()
            client._http_client = nil
        end)

        describe("Request Method Handling", function()
            it("should use GET method when specified", function()
                client._http_client = {
                    get = function(url, options)
                        tests.eq(url, "https://test.googleapis.com/v1/test")
                        tests.eq(options.headers["Accept"], "application/json")
                        return {
                            status_code = 200,
                            body = json.encode({ data = "test" })
                        }
                    end
                }

                local response, err = client.request("GET", "https://test.googleapis.com/v1/test", {
                    headers = {}
                })

                tests.is_nil(err)
                tests.eq(response.data, "test")
            end)

            it("should use POST method when specified", function()
                client._http_client = {
                    post = function(url, options)
                        tests.eq(url, "https://test.googleapis.com/v1/test")
                        tests.eq(options.headers["Accept"], "application/json")
                        tests.eq(options.headers["Content-Type"], "application/json")
                        return {
                            status_code = 200,
                            body = json.encode({ data = "test" })
                        }
                    end
                }

                local response, err = client.request("POST", "https://test.googleapis.com/v1/test", {
                    headers = {},
                    body = json.encode({ test = "data" })
                })

                tests.is_nil(err)
                tests.eq(response.data, "test")
            end)

            it("should default to POST for unknown methods", function()
                client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = json.encode({ data = "test" })
                        }
                    end
                }

                local response, err = client.request("PUT", "https://test.googleapis.com/v1/test", {
                    headers = {}
                })

                tests.is_nil(err)
            end)
        end)

        describe("Headers Handling", function()
            it("should always add Accept header", function()
                client._http_client = {
                    get = function(url, options)
                        tests.eq(options.headers["Accept"], "application/json")
                        return {
                            status_code = 200,
                            body = json.encode({})
                        }
                    end
                }

                client.request("GET", "https://test.googleapis.com/v1/test", {
                    headers = {}
                })
            end)

            it("should add Content-Type header for POST requests", function()
                client._http_client = {
                    post = function(url, options)
                        tests.eq(options.headers["Content-Type"], "application/json")
                        return {
                            status_code = 200,
                            body = json.encode({})
                        }
                    end
                }

                client.request("POST", "https://test.googleapis.com/v1/test", {
                    headers = {}
                })
            end)

            it("should not add Content-Type header for GET requests", function()
                client._http_client = {
                    get = function(url, options)
                        tests.is_nil(options.headers["Content-Type"])
                        return {
                            status_code = 200,
                            body = json.encode({})
                        }
                    end
                }

                client.request("GET", "https://test.googleapis.com/v1/test", {
                    headers = {}
                })
            end)

            it("should preserve existing headers", function()
                client._http_client = {
                    post = function(url, options)
                        tests.eq(options.headers["Authorization"], "Bearer token")
                        tests.eq(options.headers["X-Custom-Header"], "custom-value")
                        return {
                            status_code = 200,
                            body = json.encode({})
                        }
                    end
                }

                client.request("POST", "https://test.googleapis.com/v1/test", {
                    headers = {
                        ["Authorization"] = "Bearer token",
                        ["X-Custom-Header"] = "custom-value"
                    }
                })
            end)
        end)

        describe("Successful Response Handling", function()
            it("should parse and return successful JSON response", function()
                client._http_client = {
                    get = function(url, options)
                        return {
                            status_code = 200,
                            body = json.encode({
                                candidates = {
                                    { content = { parts = { { text = "Hello" } } } }
                                }
                            })
                        }
                    end
                }

                local response, err = client.request("GET", "https://test.googleapis.com/v1/test", {
                    headers = {}
                })

                tests.is_nil(err)
                tests.eq(response.candidates[1].content.parts[1].text, "Hello")
            end)

            it("should add status_code to response", function()
                client._http_client = {
                    get = function(url, options)
                        return {
                            status_code = 200,
                            body = json.encode({ data = "test" })
                        }
                    end
                }

                local response, err = client.request("GET", "https://test.googleapis.com/v1/test", {
                    headers = {}
                })

                tests.is_nil(err)
                tests.eq(response.status_code, 200)
            end)

            it("should extract and add metadata to response", function()
                client._http_client = {
                    get = function(url, options)
                        return {
                            status_code = 200,
                            body = json.encode({
                                data = "test",
                                modelVersion = "gemini-2.5-pro-001",
                                responseId = "resp-123",
                                createTime = "2024-01-15T10:30:00Z"
                            })
                        }
                    end
                }

                local response, err = client.request("GET", "https://test.googleapis.com/v1/test", {
                    headers = {}
                })

                tests.is_nil(err)
                local metadata = (response :: any).metadata
                tests.eq(metadata.model_version, "gemini-2.5-pro-001")
                tests.eq(metadata.response_id, "resp-123")
                tests.eq(metadata.create_time, "2024-01-15T10:30:00Z")
            end)

            it("should handle response without metadata fields", function()
                client._http_client = {
                    get = function(url, options)
                        return {
                            status_code = 200,
                            body = json.encode({ data = "test" })
                        }
                    end
                }

                local response, err = client.request("GET", "https://test.googleapis.com/v1/test", {
                    headers = {}
                })

                tests.is_nil(err)
                tests.not_nil(response.metadata)
            end)
        end)

        describe("Error Response Handling", function()
            it("should handle HTTP 4xx errors", function()
                client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 400,
                            body = json.encode({
                                error = {
                                    code = 400,
                                    message = "Invalid request parameters",
                                    type = "invalid_request_error"
                                }
                            })
                        }
                    end
                }

                local response, err = client.request("POST", "https://test.googleapis.com/v1/test", {
                    headers = {}
                })

                tests.is_nil(response)
                tests.eq(err.status_code, 400)
                tests.eq(err.message, "Invalid request parameters")
                tests.eq(err.code, 400)
                tests.eq(err.type, "invalid_request_error")
            end)

            it("should handle HTTP 5xx errors", function()
                client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 503,
                            body = json.encode({
                                error = {
                                    code = 503,
                                    message = "Service temporarily unavailable"
                                }
                            })
                        }
                    end
                }

                local response, err = client.request("POST", "https://test.googleapis.com/v1/test", {
                    headers = {}
                })

                tests.is_nil(response)
                tests.eq(err.status_code, 503)
                tests.eq(err.message, "Service temporarily unavailable")
            end)

            it("should handle error response without detailed error object", function()
                client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 401,
                            body = "Unauthorized"
                        }
                    end
                }

                local response, err = client.request("POST", "https://test.googleapis.com/v1/test", {
                    headers = {}
                })

                tests.is_nil(response)
                tests.eq(err.status_code, 401)
                tests.eq(err.message, "Google API error: 401")
            end)

            it("should handle error response with empty body", function()
                client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 500
                        }
                    end
                }

                local response, err = client.request("POST", "https://test.googleapis.com/v1/test", {
                    headers = {}
                })

                tests.is_nil(response)
                tests.eq(err.status_code, 500)
                tests.eq(err.message, "Google API error: 500")
            end)

            it("should include error param and type when available", function()
                client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 400,
                            body = json.encode({
                                error = {
                                    code = 400,
                                    message = "Invalid parameter value",
                                    param = "temperature",
                                    type = "invalid_request_error"
                                }
                            })
                        }
                    end
                }

                local response, err = client.request("POST", "https://test.googleapis.com/v1/test", {
                    headers = {}
                })

                tests.is_nil(response)
                tests.eq(err.param, "temperature")
                tests.eq(err.type, "invalid_request_error")
            end)
        end)

        describe("Connection Error Handling", function()
            it("should handle connection failure", function()
                client._http_client = {
                    get = function(url, options)
                        return nil, "Connection timeout"
                    end
                }

                local response, err = client.request("GET", "https://test.googleapis.com/v1/test", {
                    headers = {}
                })

                tests.is_nil(response)
                tests.eq(err.status_code, 0)
                tests.contains(err.message, "Connection failed:")
            end)

            it("should include error details in connection failure message", function()
                client._http_client = {
                    post = function(url, options)
                        return nil, "DNS resolution failed"
                    end
                }

                local response, err = client.request("POST", "https://test.googleapis.com/v1/test", {
                    headers = {}
                })

                tests.is_nil(response)
                tests.contains(err.message, "DNS resolution failed")
            end)
        end)

        describe("JSON Parsing Error Handling", function()
            it("should handle invalid JSON in successful response", function()
                client._http_client = {
                    get = function(url, options)
                        return {
                            status_code = 200,
                            body = "This is not valid JSON"
                        }
                    end
                }

                local response, err = client.request("GET", "https://test.googleapis.com/v1/test", {
                    headers = {}
                })

                tests.is_nil(response)
                tests.eq(err.status_code, 200)
                tests.contains(err.message, "Failed to parse Google response:")
            end)

            it("should include metadata in parse error", function()
                client._http_client = {
                    get = function(url, options)
                        return {
                            status_code = 200,
                            body = "Invalid JSON",
                            modelVersion = "gemini-2.5-pro-001"
                        }
                    end
                }

                local response, err = client.request("GET", "https://test.googleapis.com/v1/test", {
                    headers = {}
                })

                tests.is_nil(response)
                tests.not_nil(err.metadata)
            end)
        end)

        describe("Status Code Ranges", function()
            it("should treat 2xx as success", function()
                for status_code = 200, 205 do
                    client._http_client = {
                        get = function(url, options)
                            return {
                                status_code = status_code,
                                body = json.encode({ result = "ok" })
                            }
                        end
                    }

                    local response, err = client.request("GET", "https://test.googleapis.com/v1/test", {
                        headers = {}
                    })

                    tests.is_nil(err)
                    tests.eq(response.result, "ok")
                end
            end)

            it("should treat < 200 as error", function()
                client._http_client = {
                    get = function(url, options)
                        return {
                            status_code = 199,
                            body = json.encode({ error = { message = "Invalid status" } })
                        }
                    end
                }

                local response, err = client.request("GET", "https://test.googleapis.com/v1/test", {
                    headers = {}
                })

                tests.is_nil(response)
                tests.not_nil(err)
            end)

            it("should treat >= 300 as error", function()
                client._http_client = {
                    get = function(url, options)
                        return {
                            status_code = 300,
                            body = json.encode({ error = { message = "Redirect" } })
                        }
                    end
                }

                local response, err = client.request("GET", "https://test.googleapis.com/v1/test", {
                    headers = {}
                })

                tests.is_nil(response)
                tests.not_nil(err)
            end)
        end)

        describe("Edge Cases", function()
            it("should handle empty successful response body", function()
                client._http_client = {
                    get = function(url, options)
                        return {
                            status_code = 200,
                            body = json.encode({})
                        }
                    end
                }

                local response, err = client.request("GET", "https://test.googleapis.com/v1/test", {
                    headers = {}
                })

                tests.is_nil(err)
                tests.not_nil(response)
            end)

            it("should handle response with null values", function()
                client._http_client = {
                    get = function(url, options)
                        return {
                            status_code = 200,
                            body = '{"data":null}'
                        }
                    end
                }

                local response, err = client.request("GET", "https://test.googleapis.com/v1/test", {
                    headers = {}
                })

                tests.is_nil(err)
                tests.not_nil(response)
            end)
        end)

        describe("Retry", function()
            local function flaky_http(statuses: {number})
                local state = { calls = 0 }
                client._http_client = {
                    post = function(url, options)
                        state.calls = state.calls + 1
                        local status = statuses[state.calls]
                        if status == 200 then
                            return { status_code = 200, body = json.encode({ data = "ok" }) }
                        end
                        return {
                            status_code = status,
                            body = json.encode({ error = { code = status, message = "Unavailable" } })
                        }
                    end
                }
                return state
            end

            it("should retry a transient failure with a retry policy", function()
                local http = flaky_http({ 503, 200 })

                local response, err = client.request("POST", "https://test.googleapis.com/v1/test", {
                    headers = {}
                }, { attempts = 2, backoff_ms = 0 })

                tests.is_nil(err)
                tests.eq(response.data, "ok")
                tests.eq(http.calls, 2)
            end)

            it("should send once without a retry policy", function()
                local http = flaky_http({ 503, 200 })

                local response, err = client.request("POST", "https://test.googleapis.com/v1/test", {
                    headers = {}
                })

                tests.is_nil(response)
                tests.eq(err.status_code, 503)
                tests.eq(http.calls, 1)
            end)
        end)
    end)
end

return tests.run_cases(define_tests)
