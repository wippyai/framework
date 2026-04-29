local client = require("google_client")
local json = require("json")
local tests = require("test")

local function define_tests()
    describe("Google HTTP Client", function()

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
    end)
end

return tests.run_cases(define_tests)
