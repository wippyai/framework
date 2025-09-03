local openai_client = require("openai_client")
local json = require("json")

local function define_tests()
    describe("OpenAI Client", function()

        after_each(function()
            -- Clean up injected dependencies
            openai_client._ctx = nil
            openai_client._env = nil
            openai_client._http_client = nil
        end)

        describe("HTTP Method Support", function()
            it("should default to POST method", function()
                openai_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                openai_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                local called_method = nil
                openai_client._http_client = {
                    post = function(url, options)
                        called_method = "POST"
                        expect(options.headers["Content-Type"]).to_equal("application/json")
                        expect(options.body).not_to_be_nil()
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = openai_client.request("/test", {})
                expect(err).to_be_nil()
                expect(called_method).to_equal("POST")
            end)

            it("should support GET method", function()
                openai_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                openai_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                local called_method = nil
                openai_client._http_client = {
                    get = function(url, options)
                        called_method = "GET"
                        expect(options.headers["Content-Type"]).to_be_nil()
                        expect(options.body).to_be_nil()
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = openai_client.request("/models", nil, { method = "GET" })
                expect(err).to_be_nil()
                expect(called_method).to_equal("GET")
            end)

            it("should support DELETE method", function()
                openai_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                openai_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                local called_method = nil
                openai_client._http_client = {
                    delete = function(url, options)
                        called_method = "DELETE"
                        expect(options.headers["Content-Type"]).to_be_nil()
                        expect(options.body).to_be_nil()
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = openai_client.request("/files/123", nil, { method = "DELETE" })
                expect(err).to_be_nil()
                expect(called_method).to_equal("DELETE")
            end)

            it("should support PUT method with body", function()
                openai_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                openai_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                local called_method = nil
                openai_client._http_client = {
                    put = function(url, options)
                        called_method = "PUT"
                        expect(options.headers["Content-Type"]).to_equal("application/json")
                        expect(options.body).not_to_be_nil()
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = openai_client.request("/test", { data = "value" }, { method = "PUT" })
                expect(err).to_be_nil()
                expect(called_method).to_equal("PUT")
            end)

            it("should support PATCH method with body", function()
                openai_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                openai_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                local called_method = nil
                openai_client._http_client = {
                    patch = function(url, options)
                        called_method = "PATCH"
                        expect(options.headers["Content-Type"]).to_equal("application/json")
                        expect(options.body).not_to_be_nil()
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = openai_client.request("/test", { update = "value" }, { method = "PATCH" })
                expect(err).to_be_nil()
                expect(called_method).to_equal("PATCH")
            end)
        end)

        describe("Nil Response Handling", function()
            it("should handle nil HTTP response", function()
                openai_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                openai_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                openai_client._http_client = {
                    post = function(url, options)
                        return nil
                    end
                }

                local response, err = openai_client.request("/test", {})

                expect(response).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err.status_code).to_equal(0)
                expect(err.message).to_equal("Connection failed")
            end)

            it("should handle nil response for GET requests", function()
                openai_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                openai_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                openai_client._http_client = {
                    get = function(url, options)
                        return nil
                    end
                }

                local response, err = openai_client.request("/models", nil, { method = "GET" })

                expect(response).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err.status_code).to_equal(0)
                expect(err.message).to_equal("Connection failed")
            end)
        end)

        describe("Context Resolution", function()
            it("should resolve API key from direct context", function()
                openai_client._ctx = {
                    all = function()
                        return { api_key = "context-key" }
                    end
                }

                openai_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                openai_client._http_client = {
                    post = function(url, options)
                        expect(options.headers["Authorization"]).to_equal("Bearer context-key")
                        return { status_code = 200, body = '{"test": true}', headers = {} }
                    end
                }

                local response, err = openai_client.request("/test", {})
                expect(err).to_be_nil()
                expect(response.test).to_be_true()
            end)

            it("should resolve API key from environment variable", function()
                openai_client._ctx = {
                    all = function()
                        return { api_key_env = "CUSTOM_KEY" }
                    end
                }

                openai_client._env = {
                    get = function(key)
                        if key == "CUSTOM_KEY" then return "env-key" end
                        return nil
                    end
                }

                openai_client._http_client = {
                    post = function(url, options)
                        expect(options.headers["Authorization"]).to_equal("Bearer env-key")
                        return { status_code = 200, body = '{"test": true}', headers = {} }
                    end
                }

                local response, err = openai_client.request("/test", {})
                expect(err).to_be_nil()
            end)

            it("should use custom base URL from context", function()
                openai_client._ctx = {
                    all = function()
                        return {
                            api_key = "test-key",
                            base_url = "https://custom.api/v1"
                        }
                    end
                }

                openai_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                openai_client._http_client = {
                    post = function(url, options)
                        expect(url).to_equal("https://custom.api/v1/test")
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = openai_client.request("/test", {})
                expect(err).to_be_nil()
            end)

            it("should use timeout from context", function()
                openai_client._ctx = {
                    all = function()
                        return {
                            api_key = "test-key",
                            timeout = 60
                        }
                    end
                }

                openai_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                openai_client._http_client = {
                    post = function(url, options)
                        expect(options.timeout).to_equal(60)
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = openai_client.request("/test", {})
                expect(err).to_be_nil()
            end)
        end)

        describe("Error Handling", function()
            it("should return error for missing API key", function()
                openai_client._ctx = {
                    all = function()
                        return {}
                    end
                }

                openai_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                openai_client._http_client = nil

                local response, err = openai_client.request("/test", {})

                expect(response).to_be_nil()
                expect(err.status_code).to_equal(401)
                expect(err.message).to_contain("API key is required")
            end)

            it("should parse HTTP error responses", function()
                openai_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                openai_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                openai_client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 404,
                            body = json.encode({
                                error = {
                                    message = "Model not found",
                                    code = "model_not_found",
                                    type = "invalid_request_error"
                                }
                            }),
                            headers = { ["x-request-id"] = "req_123" }
                        }
                    end
                }

                local response, err = openai_client.request("/test", {})

                expect(response).to_be_nil()
                expect(err.status_code).to_equal(404)
                expect(err.message).to_equal("Model not found")
                expect(err.code).to_equal("model_not_found")
                expect(err.type).to_equal("invalid_request_error")
            end)

            it("should handle error responses with nil HTTP response", function()
                openai_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                openai_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                openai_client._http_client = {
                    get = function(url, options)
                        return nil
                    end
                }

                local response, err = openai_client.request("/models", nil, { method = "GET" })

                expect(response).to_be_nil()
                expect(err.status_code).to_equal(0)
                expect(err.message).to_equal("Connection failed")
            end)

            it("should extract metadata from error responses", function()
                openai_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                openai_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                openai_client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 500,
                            body = json.encode({ error = { message = "Server error" } }),
                            headers = {
                                ["X-Request-Id"] = "req_error123",
                                ["Openai-Processing-Ms"] = "250"
                            }
                        }
                    end
                }

                local response, err = openai_client.request("/test", {})

                expect(response).to_be_nil()
                expect(err.metadata).not_to_be_nil()
                expect(err.metadata.request_id).to_equal("req_error123")
                expect(err.metadata.processing_ms).to_equal(250)
            end)
        end)

        describe("Streaming Support", function()
            it("should handle streaming request setup", function()
                openai_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                openai_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                local stream_chunks = {
                    'data: {"choices":[{"delta":{"content":"Hello"}}]}\n\n',
                    'data: [DONE]\n\n'
                }

                local mock_stream = {
                    chunks = stream_chunks,
                    current = 0
                }

                setmetatable(mock_stream, {
                    __index = {
                        read = function(self)
                            self.current = self.current + 1
                            if self.current <= #self.chunks then
                                return self.chunks[self.current]
                            end
                            return nil
                        end
                    }
                })

                openai_client._http_client = {
                    post = function(url, http_options)
                        expect(http_options.stream).to_be_true()
                        local payload = json.decode(http_options.body)
                        expect(payload.stream).to_be_true()
                        expect(payload.stream_options.include_usage).to_be_true()

                        return {
                            status_code = 200,
                            stream = mock_stream,
                            headers = {}
                        }
                    end
                }

                local response, err = openai_client.request("/test", {}, { stream = true })

                expect(err).to_be_nil()
                expect(response.stream).not_to_be_nil()
            end)

            it("should process streaming content correctly", function()
                local stream_chunks = {
                    'data: {"choices":[{"delta":{"content":"Hello"}}]}\n\n',
                    'data: {"choices":[{"delta":{"content":" world"}}]}\n\n',
                    'data: {"choices":[{"finish_reason":"stop"}]}\n\n',
                    'data: [DONE]\n\n'
                }

                local mock_stream = {
                    chunks = stream_chunks,
                    current = 0
                }

                setmetatable(mock_stream, {
                    __index = {
                        read = function(self)
                            self.current = self.current + 1
                            if self.current <= #self.chunks then
                                return self.chunks[self.current]
                            end
                            return nil
                        end
                    }
                })

                local stream_response = {
                    stream = mock_stream,
                    metadata = { request_id = "req_stream123" }
                }

                local content_chunks = {}
                local finish_reason = nil

                local full_content, err, result = openai_client.process_stream(stream_response, {
                    on_content = function(chunk)
                        table.insert(content_chunks, chunk)
                    end,
                    on_done = function(result)
                        finish_reason = result.finish_reason
                    end
                })

                expect(err).to_be_nil()
                expect(full_content).to_equal("Hello world")
                expect(#content_chunks).to_equal(2)
                expect(content_chunks[1]).to_equal("Hello")
                expect(content_chunks[2]).to_equal(" world")
                expect(finish_reason).to_equal("stop")
            end)

            it("should process streaming tool calls", function()
                local stream_chunks = {
                    'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"id":"call_123","type":"function","function":{"name":"test_tool"}}]}}]}\n\n',
                    'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"function":{"arguments":"{\\"param\\""}}]}}]}\n\n',
                    'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"function":{"arguments":": \\"value\\"}"}}]}}]}\n\n',
                    'data: {"choices":[{"finish_reason":"tool_calls"}]}\n\n',
                    'data: [DONE]\n\n'
                }

                local mock_stream = {
                    chunks = stream_chunks,
                    current = 0
                }

                setmetatable(mock_stream, {
                    __index = {
                        read = function(self)
                            self.current = self.current + 1
                            if self.current <= #self.chunks then
                                return self.chunks[self.current]
                            end
                            return nil
                        end
                    }
                })

                local stream_response = {
                    stream = mock_stream,
                    metadata = {}
                }

                local tool_calls = {}

                local full_content, err, result = openai_client.process_stream(stream_response, {
                    on_tool_call = function(tool_call)
                        table.insert(tool_calls, tool_call)
                    end
                })

                expect(err).to_be_nil()
                expect(#tool_calls).to_equal(1)
                expect(tool_calls[1].id).to_equal("call_123")
                expect(tool_calls[1].name).to_equal("test_tool")
                expect(tool_calls[1].arguments).to_equal('{"param": "value"}')
            end)
        end)

        describe("Response Metadata Extraction", function()
            it("should extract standard response metadata", function()
                openai_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                openai_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                openai_client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = '{"test": true}',
                            headers = {
                                ["X-Request-Id"] = "req_metadata123",
                                ["Openai-Organization"] = "org-test",
                                ["Openai-Processing-Ms"] = "150",
                                ["Openai-Version"] = "2023-12-01"
                            }
                        }
                    end
                }

                local response, err = openai_client.request("/test", {})

                expect(err).to_be_nil()
                expect(response.metadata).not_to_be_nil()
                expect(response.metadata.request_id).to_equal("req_metadata123")
                expect(response.metadata.organization).to_equal("org-test")
                expect(response.metadata.processing_ms).to_equal(150)
                expect(response.metadata.version).to_equal("2023-12-01")
            end)

            it("should extract rate limit information", function()
                openai_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                openai_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                openai_client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = '{"test": true}',
                            headers = {
                                ["x-ratelimit-limit-requests"] = "5000",
                                ["x-ratelimit-remaining-requests"] = "4999",
                                ["x-ratelimit-limit-tokens"] = "200000",
                                ["x-ratelimit-remaining-tokens"] = "199500"
                            }
                        }
                    end
                }

                local response, err = openai_client.request("/test", {})

                expect(err).to_be_nil()
                expect(response.metadata.rate_limits).not_to_be_nil()
                expect(response.metadata.rate_limits.limit_requests).to_equal(5000)
                expect(response.metadata.rate_limits.remaining_requests).to_equal(4999)
                expect(response.metadata.rate_limits.limit_tokens).to_equal(200000)
                expect(response.metadata.rate_limits.remaining_tokens).to_equal(199500)
            end)
        end)

        describe("Backward Compatibility", function()
            it("should maintain exact same behavior for existing POST calls", function()
                openai_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                openai_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                openai_client._http_client = {
                    post = function(url, options)
                        expect(url).to_equal("https://api.openai.com/v1/chat/completions")
                        expect(options.headers["Content-Type"]).to_equal("application/json")
                        expect(options.headers["Authorization"]).to_equal("Bearer test-key")
                        expect(options.body).not_to_be_nil()
                        local payload = json.decode(options.body)
                        expect(payload.model).to_equal("gpt-4")
                        return { status_code = 200, body = '{"test": "success"}', headers = {} }
                    end
                }

                local response, err = openai_client.request("/chat/completions", { model = "gpt-4" })
                expect(err).to_be_nil()
                expect(response.test).to_equal("success")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)