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
                        expect(url).to_equal("https://test.googleapis.com/v1/test")
                        expect(options.headers["Accept"]).to_equal("application/json")
                        return {
                            status_code = 200,
                            body = json.encode({ data = "test" })
                        }
                    end
                }

                local response, err = client.request("GET", "https://test.googleapis.com/v1/test", {
                    headers = {}
                })

                expect(err).to_be_nil()
                expect(response.data).to_equal("test")
            end)

            it("should use POST method when specified", function()
                client._http_client = {
                    post = function(url, options)
                        expect(url).to_equal("https://test.googleapis.com/v1/test")
                        expect(options.headers["Accept"]).to_equal("application/json")
                        expect(options.headers["Content-Type"]).to_equal("application/json")
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

                expect(err).to_be_nil()
                expect(response.data).to_equal("test")
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

                expect(err).to_be_nil()
            end)
        end)

        describe("Headers Handling", function()
            it("should always add Accept header", function()
                client._http_client = {
                    get = function(url, options)
                        expect(options.headers["Accept"]).to_equal("application/json")
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
                        expect(options.headers["Content-Type"]).to_equal("application/json")
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
                        expect(options.headers["Content-Type"]).to_be_nil()
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
                        expect(options.headers["Authorization"]).to_equal("Bearer token")
                        expect(options.headers["X-Custom-Header"]).to_equal("custom-value")
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

                expect(err).to_be_nil()
                expect(response.candidates[1].content.parts[1].text).to_equal("Hello")
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

                expect(err).to_be_nil()
                expect(response.status_code).to_equal(200)
            end)

            it("should extract and add metadata to response", function()
                client._http_client = {
                    get = function(url, options)
                        return {
                            status_code = 200,
                            body = json.encode({
                                data = "test",
                                modelVersion = "gemini-1.5-pro-001",
                                responseId = "resp-123",
                                createTime = "2024-01-15T10:30:00Z"
                            })
                        }
                    end
                }

                local response, err = client.request("GET", "https://test.googleapis.com/v1/test", {
                    headers = {}
                })

                expect(err).to_be_nil()
                expect(response.metadata.model_version).to_equal("gemini-1.5-pro-001")
                expect(response.metadata.response_id).to_equal("resp-123")
                expect(response.metadata.create_time).to_equal("2024-01-15T10:30:00Z")
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

                expect(err).to_be_nil()
                expect(response.metadata).not_to_be_nil()
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

                expect(response).to_be_nil()
                expect(err.status_code).to_equal(400)
                expect(err.message).to_equal("Invalid request parameters")
                expect(err.code).to_equal(400)
                expect(err.type).to_equal("invalid_request_error")
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

                expect(response).to_be_nil()
                expect(err.status_code).to_equal(503)
                expect(err.message).to_equal("Service temporarily unavailable")
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

                expect(response).to_be_nil()
                expect(err.status_code).to_equal(401)
                expect(err.message).to_equal("Google API error: 401")
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

                expect(response).to_be_nil()
                expect(err.status_code).to_equal(500)
                expect(err.message).to_equal("Google API error: 500")
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

                expect(response).to_be_nil()
                expect(err.param).to_equal("temperature")
                expect(err.type).to_equal("invalid_request_error")
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

                expect(response).to_be_nil()
                expect(err.status_code).to_equal(0)
                expect(err.message).to_contain("Connection failed:")
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

                expect(response).to_be_nil()
                expect(err.message).to_contain("DNS resolution failed")
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

                expect(response).to_be_nil()
                expect(err.status_code).to_equal(200)
                expect(err.message).to_contain("Failed to parse Google response:")
            end)

            it("should include metadata in parse error", function()
                client._http_client = {
                    get = function(url, options)
                        return {
                            status_code = 200,
                            body = "Invalid JSON",
                            modelVersion = "gemini-1.5-pro-001"
                        }
                    end
                }

                local response, err = client.request("GET", "https://test.googleapis.com/v1/test", {
                    headers = {}
                })

                expect(response).to_be_nil()
                expect(err.metadata).not_to_be_nil()
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

                    expect(err).to_be_nil()
                    expect(response.result).to_equal("ok")
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

                expect(response).to_be_nil()
                expect(err).not_to_be_nil()
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

                expect(response).to_be_nil()
                expect(err).not_to_be_nil()
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

                expect(err).to_be_nil()
                expect(response).not_to_be_nil()
            end)

            it("should handle response with null values", function()
                client._http_client = {
                    get = function(url, options)
                        return {
                            status_code = 200,
                            body = json.encode({ data = json.null })
                        }
                    end
                }

                local response, err = client.request("GET", "https://test.googleapis.com/v1/test", {
                    headers = {}
                })

                expect(err).to_be_nil()
                expect(response).not_to_be_nil()
            end)
        end)
    end)
end

return tests.run_cases(define_tests)
