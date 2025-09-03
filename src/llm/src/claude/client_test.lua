local claude_client = require("claude_client")
local json = require("json")

local function define_tests()
    describe("Claude Client", function()

        after_each(function()
            -- Clean up injected dependencies
            claude_client._ctx = nil
            claude_client._env = nil
            claude_client._http_client = nil
        end)

        describe("HTTP Method Support", function()
            it("should default to POST method", function()
                claude_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                local called_method = nil
                claude_client._http_client = {
                    post = function(url, options)
                        called_method = "POST"
                        expect(options.headers["content-type"]).to_equal("application/json")
                        expect(options.headers["x-api-key"]).to_equal("test-key")
                        expect(options.headers["anthropic-version"]).to_equal("2023-06-01")
                        expect(options.body).not_to_be_nil()
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/messages", {})
                expect(err).to_be_nil()
                expect(called_method).to_equal("POST")
            end)

            it("should support GET method", function()
                claude_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                local called_method = nil
                claude_client._http_client = {
                    get = function(url, options)
                        called_method = "GET"
                        expect(options.headers["content-type"]).to_be_nil()
                        expect(options.headers["x-api-key"]).to_equal("test-key")
                        expect(options.body).to_be_nil()
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/status", nil, { method = "GET" })
                expect(err).to_be_nil()
                expect(called_method).to_equal("GET")
            end)

            it("should support DELETE method", function()
                claude_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                local called_method = nil
                claude_client._http_client = {
                    delete = function(url, options)
                        called_method = "DELETE"
                        expect(options.headers["content-type"]).to_be_nil()
                        expect(options.body).to_be_nil()
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/resource/123", nil, { method = "DELETE" })
                expect(err).to_be_nil()
                expect(called_method).to_equal("DELETE")
            end)

            it("should support PUT method with body", function()
                claude_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                local called_method = nil
                claude_client._http_client = {
                    put = function(url, options)
                        called_method = "PUT"
                        expect(options.headers["content-type"]).to_equal("application/json")
                        expect(options.body).not_to_be_nil()
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/resource", { data = "value" }, { method = "PUT" })
                expect(err).to_be_nil()
                expect(called_method).to_equal("PUT")
            end)

            it("should support PATCH method with body", function()
                claude_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                local called_method = nil
                claude_client._http_client = {
                    patch = function(url, options)
                        called_method = "PATCH"
                        expect(options.headers["content-type"]).to_equal("application/json")
                        expect(options.body).not_to_be_nil()
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/resource", { update = "value" }, { method = "PATCH" })
                expect(err).to_be_nil()
                expect(called_method).to_equal("PATCH")
            end)
        end)

        describe("Nil Response Handling", function()
            it("should handle nil HTTP response", function()
                claude_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                claude_client._http_client = {
                    post = function(url, options)
                        return nil
                    end
                }

                local response, err = claude_client.request("/messages", {})

                expect(response).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err.status_code).to_equal(0)
                expect(err.message).to_equal("Connection failed")
            end)

            it("should handle nil response for GET requests", function()
                claude_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                claude_client._http_client = {
                    get = function(url, options)
                        return nil
                    end
                }

                local response, err = claude_client.request("/status", nil, { method = "GET" })

                expect(response).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err.status_code).to_equal(0)
                expect(err.message).to_equal("Connection failed")
            end)
        end)

        describe("Context Resolution", function()
            it("should resolve API key from direct context", function()
                claude_client._ctx = {
                    all = function()
                        return { api_key = "context-key" }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                claude_client._http_client = {
                    post = function(url, options)
                        expect(options.headers["x-api-key"]).to_equal("context-key")
                        return { status_code = 200, body = '{"test": true}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/messages", {})
                expect(err).to_be_nil()
                expect(response.test).to_be_true()
            end)

            it("should resolve API key from environment variable", function()
                claude_client._ctx = {
                    all = function()
                        return { api_key_env = "CUSTOM_ANTHROPIC_KEY" }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        if key == "CUSTOM_ANTHROPIC_KEY" then return "env-key" end
                        return nil
                    end
                }

                claude_client._http_client = {
                    post = function(url, options)
                        expect(options.headers["x-api-key"]).to_equal("env-key")
                        return { status_code = 200, body = '{"test": true}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/messages", {})
                expect(err).to_be_nil()
            end)

            it("should use custom base URL from context", function()
                claude_client._ctx = {
                    all = function()
                        return {
                            api_key = "test-key",
                            base_url = "https://custom.claude.api"
                        }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                claude_client._http_client = {
                    post = function(url, options)
                        expect(url).to_equal("https://custom.claude.api/messages")
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/messages", {})
                expect(err).to_be_nil()
            end)

            it("should use custom API version from context", function()
                claude_client._ctx = {
                    all = function()
                        return {
                            api_key = "test-key",
                            api_version = "2024-02-01"
                        }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                claude_client._http_client = {
                    post = function(url, options)
                        expect(options.headers["anthropic-version"]).to_equal("2024-02-01")
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/messages", {})
                expect(err).to_be_nil()
            end)

            it("should use beta features from context", function()
                claude_client._ctx = {
                    all = function()
                        return {
                            api_key = "test-key",
                            beta_features = {"computer-use-2024-10-22", "prompt-caching-2024-07-31"}
                        }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                claude_client._http_client = {
                    post = function(url, options)
                        expect(options.headers["anthropic-beta"]).to_equal("computer-use-2024-10-22,prompt-caching-2024-07-31")
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/messages", {})
                expect(err).to_be_nil()
            end)

            it("should use timeout from context", function()
                claude_client._ctx = {
                    all = function()
                        return {
                            api_key = "test-key",
                            timeout = 120
                        }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                claude_client._http_client = {
                    post = function(url, options)
                        expect(options.timeout).to_equal(120)
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/messages", {})
                expect(err).to_be_nil()
            end)

            it("should use additional headers from context", function()
                claude_client._ctx = {
                    all = function()
                        return {
                            api_key = "test-key",
                            headers = {
                                ["x-custom-header"] = "custom-value"
                            }
                        }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                claude_client._http_client = {
                    post = function(url, options)
                        expect(options.headers["x-custom-header"]).to_equal("custom-value")
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/messages", {})
                expect(err).to_be_nil()
            end)
        end)

        describe("Error Handling", function()
            it("should return error for missing API key", function()
                claude_client._ctx = {
                    all = function()
                        return {}
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                claude_client._http_client = nil

                local response, err = claude_client.request("/messages", {})

                expect(response).to_be_nil()
                expect(err.status_code).to_equal(401)
                expect(err.message).to_contain("API key is required")
            end)

            it("should parse Claude error responses with structured format", function()
                claude_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                claude_client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 400,
                            body = json.encode({
                                type = "error",
                                error = {
                                    type = "invalid_request_error",
                                    message = "Invalid model specified"
                                }
                            }),
                            headers = { ["request-id"] = "req_claude123" }
                        }
                    end
                }

                local response, err = claude_client.request("/messages", {})

                expect(response).to_be_nil()
                expect(err.status_code).to_equal(400)
                expect(err.message).to_equal("Invalid model specified")
                expect(err.error.type).to_equal("invalid_request_error")
                expect(err.request_id).to_equal("req_claude123")
            end)

            it("should handle Claude rate limit error", function()
                claude_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                claude_client._http_client = {
                    post = function(url, options)
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
                                ["request-id"] = "req_rate123",
                                ["anthropic-ratelimit-requests-limit"] = "1000",
                                ["anthropic-ratelimit-requests-remaining"] = "0"
                            }
                        }
                    end
                }

                local response, err = claude_client.request("/messages", {})

                expect(response).to_be_nil()
                expect(err.status_code).to_equal(429)
                expect(err.message).to_equal("Rate limit exceeded")
                expect(err.metadata.rate_limits.requests_limit).to_equal(1000)
                expect(err.metadata.rate_limits.requests_remaining).to_equal(0)
            end)

            it("should handle authentication error", function()
                claude_client._ctx = {
                    all = function()
                        return { api_key = "invalid-key" }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                claude_client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 401,
                            body = json.encode({
                                type = "error",
                                error = {
                                    type = "authentication_error",
                                    message = "Invalid API key"
                                }
                            }),
                            headers = { ["request-id"] = "req_auth_fail" }
                        }
                    end
                }

                local response, err = claude_client.request("/messages", {})

                expect(response).to_be_nil()
                expect(err.status_code).to_equal(401)
                expect(err.message).to_equal("Invalid API key")
                expect(err.error.type).to_equal("authentication_error")
            end)

            it("should handle error responses with nil HTTP response", function()
                claude_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                claude_client._http_client = {
                    get = function(url, options)
                        return nil
                    end
                }

                local response, err = claude_client.request("/status", nil, { method = "GET" })

                expect(response).to_be_nil()
                expect(err.status_code).to_equal(0)
                expect(err.message).to_equal("Connection failed")
            end)

            it("should extract metadata from error responses", function()
                claude_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                claude_client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 500,
                            body = json.encode({
                                type = "error",
                                error = { message = "Server error" }
                            }),
                            headers = {
                                ["request-id"] = "req_error123",
                                ["processing-ms"] = "350"
                            }
                        }
                    end
                }

                local response, err = claude_client.request("/messages", {})

                expect(response).to_be_nil()
                expect(err.metadata).not_to_be_nil()
                expect(err.metadata.request_id).to_equal("req_error123")
                expect(err.metadata.processing_ms).to_equal(350)
            end)

            it("should handle malformed error JSON gracefully", function()
                claude_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                claude_client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 500,
                            body = "invalid json {",
                            headers = { ["request-id"] = "req_malformed" }
                        }
                    end
                }

                local response, err = claude_client.request("/messages", {})

                expect(response).to_be_nil()
                expect(err.status_code).to_equal(500)
                expect(err.message).to_contain("Claude API error")
                expect(err.request_id).to_equal("req_malformed")
            end)
        end)

        describe("Streaming Support", function()
            it("should handle streaming request setup", function()
                claude_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                local stream_chunks = {
                    'event: message_start\ndata: {"type":"message_start","message":{"usage":{"input_tokens":10,"output_tokens":0}}}\n\n',
                    'event: content_block_start\ndata: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}\n\n',
                    'event: content_block_delta\ndata: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hello"}}\n\n',
                    'event: message_stop\ndata: {"type":"message_stop"}\n\n'
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

                claude_client._http_client = {
                    post = function(url, http_options)
                        expect(http_options.stream).not_to_be_nil()
                        expect(http_options.stream.buffer_size).to_equal(4096)
                        local payload = json.decode(http_options.body)
                        expect(payload.stream).to_be_true()

                        return {
                            status_code = 200,
                            stream = mock_stream,
                            headers = {}
                        }
                    end
                }

                local response, err = claude_client.request("/messages", {}, { stream = true })

                expect(err).to_be_nil()
                expect(response.stream).not_to_be_nil()
            end)

            it("should process streaming content correctly", function()
                local stream_chunks = {
                    'event: message_start\ndata: {"type":"message_start","message":{"usage":{"input_tokens":15,"output_tokens":0}}}\n\n',
                    'event: content_block_start\ndata: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}\n\n',
                    'event: content_block_delta\ndata: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hello"}}\n\n',
                    'event: content_block_delta\ndata: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":" world"}}\n\n',
                    'event: content_block_stop\ndata: {"type":"content_block_stop","index":0}\n\n',
                    'event: message_delta\ndata: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":5}}\n\n',
                    'event: message_stop\ndata: {"type":"message_stop"}\n\n'
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

                local full_content, err, result = claude_client.process_stream(stream_response, {
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
                expect(finish_reason).to_equal("end_turn")
            end)

            it("should process streaming tool calls", function()
                local stream_chunks = {
                    'event: message_start\ndata: {"type":"message_start","message":{"usage":{"input_tokens":20,"output_tokens":0}}}\n\n',
                    'event: content_block_start\ndata: {"type":"content_block_start","index":0,"content_block":{"type":"tool_use","id":"call_123","name":"test_tool"}}\n\n',
                    'event: content_block_delta\ndata: {"type":"content_block_delta","index":0,"delta":{"type":"input_json_delta","partial_json":"{\\"param\\""}}\n\n',
                    'event: content_block_delta\ndata: {"type":"content_block_delta","index":0,"delta":{"type":"input_json_delta","partial_json":": \\"value\\"}"}}\n\n',
                    'event: content_block_stop\ndata: {"type":"content_block_stop","index":0}\n\n',
                    'event: message_delta\ndata: {"type":"message_delta","delta":{"stop_reason":"tool_use"},"usage":{"output_tokens":10}}\n\n',
                    'event: message_stop\ndata: {"type":"message_stop"}\n\n'
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

                local full_content, err, result = claude_client.process_stream(stream_response, {
                    on_tool_call = function(tool_call)
                        table.insert(tool_calls, tool_call)
                    end
                })

                expect(err).to_be_nil()
                expect(#tool_calls).to_equal(1)
                expect(tool_calls[1].id).to_equal("call_123")
                expect(tool_calls[1].name).to_equal("test_tool")
                expect(tool_calls[1].arguments.param).to_equal("value")
            end)

            it("should process streaming thinking content", function()
                local stream_chunks = {
                    'event: message_start\ndata: {"type":"message_start","message":{"usage":{"input_tokens":25,"output_tokens":0}}}\n\n',
                    'event: content_block_start\ndata: {"type":"content_block_start","index":0,"content_block":{"type":"thinking"}}\n\n',
                    'event: content_block_delta\ndata: {"type":"content_block_delta","index":0,"delta":{"type":"thinking_delta","thinking":"Let me think..."}}\n\n',
                    'event: content_block_delta\ndata: {"type":"content_block_delta","index":0,"delta":{"type":"thinking_delta","thinking":" The answer is"}}\n\n',
                    'event: content_block_stop\ndata: {"type":"content_block_stop","index":0}\n\n',
                    'event: content_block_start\ndata: {"type":"content_block_start","index":1,"content_block":{"type":"text","text":""}}\n\n',
                    'event: content_block_delta\ndata: {"type":"content_block_delta","index":1,"delta":{"type":"text_delta","text":"42"}}\n\n',
                    'event: content_block_stop\ndata: {"type":"content_block_stop","index":1}\n\n',
                    'event: message_stop\ndata: {"type":"message_stop"}\n\n'
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

                local thinking_chunks = {}
                local content_chunks = {}

                local full_content, err, result = claude_client.process_stream(stream_response, {
                    on_thinking = function(chunk)
                        table.insert(thinking_chunks, chunk)
                    end,
                    on_content = function(chunk)
                        table.insert(content_chunks, chunk)
                    end
                })

                expect(err).to_be_nil()
                expect(full_content).to_equal("42")
                expect(#thinking_chunks).to_equal(2)
                expect(thinking_chunks[1]).to_equal("Let me think...")
                expect(thinking_chunks[2]).to_equal(" The answer is")

                -- result.thinking is an array of thinking block objects
                expect(#result.thinking).to_equal(1)
                expect(result.thinking[1].type).to_equal("thinking")
                expect(result.thinking[1].thinking).to_equal("Let me think... The answer is")

                expect(#content_chunks).to_equal(1)
                expect(content_chunks[1]).to_equal("42")
            end)

            it("should handle streaming errors", function()
                local stream_chunks = {
                    'event: error\ndata: {"type":"error","error":{"type":"overloaded_error","message":"API overloaded"}}\n\n'
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

                local errors = {}

                local full_content, err, result = claude_client.process_stream(stream_response, {
                    on_error = function(error_info)
                        table.insert(errors, error_info)
                    end
                })

                expect(err).to_equal("API overloaded")
                expect(#errors).to_equal(1)
                expect(errors[1].message).to_equal("API overloaded")
                expect(errors[1].type).to_equal("overloaded_error")
            end)
        end)

        describe("Response Metadata Extraction", function()
            it("should extract standard response metadata", function()
                claude_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                claude_client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = '{"test": true}',
                            headers = {
                                ["request-id"] = "req_metadata123",
                                ["processing-ms"] = "250"
                            }
                        }
                    end
                }

                local response, err = claude_client.request("/messages", {})

                expect(err).to_be_nil()
                expect(response.metadata).not_to_be_nil()
                expect(response.metadata.request_id).to_equal("req_metadata123")
                expect(response.metadata.processing_ms).to_equal(250)
            end)

            it("should extract rate limit information", function()
                claude_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                claude_client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = '{"test": true}',
                            headers = {
                                ["anthropic-ratelimit-requests-limit"] = "1000",
                                ["anthropic-ratelimit-requests-remaining"] = "999",
                                ["anthropic-ratelimit-tokens-limit"] = "100000",
                                ["anthropic-ratelimit-tokens-remaining"] = "99500"
                            }
                        }
                    end
                }

                local response, err = claude_client.request("/messages", {})

                expect(err).to_be_nil()
                expect(response.metadata.rate_limits).not_to_be_nil()
                expect(response.metadata.rate_limits.requests_limit).to_equal(1000)
                expect(response.metadata.rate_limits.requests_remaining).to_equal(999)
                expect(response.metadata.rate_limits.tokens_limit).to_equal(100000)
                expect(response.metadata.rate_limits.tokens_remaining).to_equal(99500)
            end)

            it("should handle x-request-id header variant", function()
                claude_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                claude_client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = '{"test": true}',
                            headers = {
                                ["x-request-id"] = "req_alt_format123"
                            }
                        }
                    end
                }

                local response, err = claude_client.request("/messages", {})

                expect(err).to_be_nil()
                expect(response.metadata.request_id).to_equal("req_alt_format123")
            end)
        end)

        describe("Response Parsing", function()
            it("should handle successful JSON parsing", function()
                claude_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                claude_client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = json.encode({
                                content = { { type = "text", text = "Hello!" } },
                                stop_reason = "end_turn",
                                usage = { input_tokens = 10, output_tokens = 5 }
                            }),
                            headers = { ["request-id"] = "req_parse123" }
                        }
                    end
                }

                local response, err = claude_client.request("/messages", {})

                expect(err).to_be_nil()
                expect(response.content).not_to_be_nil()
                expect(response.content[1].text).to_equal("Hello!")
                expect(response.stop_reason).to_equal("end_turn")
                expect(response.usage.input_tokens).to_equal(10)
                expect(response.metadata.request_id).to_equal("req_parse123")
            end)

            it("should handle JSON parsing errors", function()
                claude_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                claude_client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = "invalid json {",
                            headers = { ["request-id"] = "req_parse_fail" }
                        }
                    end
                }

                local response, err = claude_client.request("/messages", {})

                expect(response).to_be_nil()
                expect(err.status_code).to_equal(200)
                expect(err.message).to_contain("Failed to parse Claude response")
                expect(err.metadata.request_id).to_equal("req_parse_fail")
            end)
        end)

        describe("Backward Compatibility", function()
            it("should maintain exact same behavior for existing POST calls", function()
                claude_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                claude_client._http_client = {
                    post = function(url, options)
                        expect(url).to_equal("https://api.anthropic.com/v1/messages")
                        expect(options.headers["content-type"]).to_equal("application/json")
                        expect(options.headers["x-api-key"]).to_equal("test-key")
                        expect(options.headers["anthropic-version"]).to_equal("2023-06-01")
                        expect(options.body).not_to_be_nil()
                        local payload = json.decode(options.body)
                        expect(payload.model).to_equal("claude-3-sonnet-20240229")
                        return { status_code = 200, body = '{"test": "success"}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/v1/messages", { model = "claude-3-sonnet-20240229" })
                expect(err).to_be_nil()
                expect(response.test).to_equal("success")
            end)

            it("should use default configuration values correctly", function()
                claude_client._ctx = {
                    all = function()
                        return {}
                    end
                }

                claude_client._env = {
                    get = function(key)
                        if key == "ANTHROPIC_API_KEY" then return "default-env-key" end
                        return nil
                    end
                }

                claude_client._http_client = {
                    post = function(url, options)
                        expect(url).to_equal("https://api.anthropic.com/messages")
                        expect(options.headers["x-api-key"]).to_equal("default-env-key")
                        expect(options.headers["anthropic-version"]).to_equal("2023-06-01")
                        expect(options.timeout).to_equal(240)
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/messages", {})
                expect(err).to_be_nil()
            end)

            it("should handle empty beta_features gracefully", function()
                claude_client._ctx = {
                    all = function()
                        return {
                            api_key = "test-key",
                            beta_features = {}
                        }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                claude_client._http_client = {
                    post = function(url, options)
                        expect(options.headers["anthropic-beta"]).to_be_nil()
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/messages", {})
                expect(err).to_be_nil()
            end)
        end)

        describe("Stream Error Handling", function()
            it("should handle stream read errors", function()
                local mock_stream = {
                    read = function(self)
                        return nil, "Stream read failed"
                    end
                }

                local stream_response = {
                    stream = mock_stream,
                    metadata = {}
                }

                local errors = {}

                local full_content, err, result = claude_client.process_stream(stream_response, {
                    on_error = function(error_info)
                        table.insert(errors, error_info)
                    end
                })

                expect(err).to_equal("Stream read failed")
                expect(#errors).to_equal(1)
                expect(errors[1].message).to_equal("Stream read failed")
            end)

            it("should handle invalid stream response", function()
                local full_content, err = claude_client.process_stream(nil)
                expect(full_content).to_be_nil()
                expect(err).to_equal("Invalid stream response")

                local full_content2, err2 = claude_client.process_stream({})
                expect(full_content2).to_be_nil()
                expect(err2).to_equal("Invalid stream response")
            end)

            it("should skip malformed SSE events", function()
                local stream_chunks = {
                    'event: message_start\ndata: invalid json\n\n',
                    'event: content_block_delta\ndata: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hello"}}\n\n',
                    'event: message_stop\ndata: {"type":"message_stop"}\n\n'
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

                local content_chunks = {}

                local full_content, err, result = claude_client.process_stream(stream_response, {
                    on_content = function(chunk)
                        table.insert(content_chunks, chunk)
                    end
                })

                expect(err).to_be_nil()
                expect(full_content).to_equal("Hello")
                expect(#content_chunks).to_equal(1)
            end)
        end)

        describe("Configuration Edge Cases", function()
            it("should handle missing context gracefully", function()
                claude_client._ctx = {
                    all = function()
                        return nil
                    end
                }

                claude_client._env = {
                    get = function(key)
                        if key == "ANTHROPIC_API_KEY" then return "fallback-key" end
                        return nil
                    end
                }

                claude_client._http_client = {
                    post = function(url, options)
                        expect(options.headers["x-api-key"]).to_equal("fallback-key")
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/messages", {})
                expect(err).to_be_nil()
            end)

            it("should handle complex context resolution priority", function()
                claude_client._ctx = {
                    all = function()
                        return {
                            api_key = "direct-key",           -- Direct context (highest priority)
                            base_url_env = "CUSTOM_BASE_URL", -- Env variable reference
                            timeout = 90                       -- Direct timeout
                        }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        if key == "CUSTOM_BASE_URL" then return "https://env.claude.api" end
                        if key == "ANTHROPIC_API_KEY" then return "fallback-key" end -- Should not be used
                        return nil
                    end
                }

                claude_client._http_client = {
                    post = function(url, options)
                        expect(url).to_equal("https://env.claude.api/messages")  -- From env via context
                        expect(options.headers["x-api-key"]).to_equal("direct-key")  -- Direct context
                        expect(options.timeout).to_equal(90)  -- Direct context
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/messages", {})
                expect(err).to_be_nil()
            end)

            it("should handle request timeout override", function()
                claude_client._ctx = {
                    all = function()
                        return {
                            api_key = "test-key",
                            timeout = 60  -- Context timeout
                        }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                claude_client._http_client = {
                    post = function(url, options)
                        expect(options.timeout).to_equal(30)  -- Request option overrides context
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/messages", {}, { timeout = 30 })
                expect(err).to_be_nil()
            end)
        end)

        describe("Streaming Error in Response Body", function()
            it("should handle streaming error from response stream", function()
                local mock_stream = {
                    read = function(self)
                        return '{"type":"error","error":{"message":"Stream error"}}'
                    end
                }

                claude_client._ctx = {
                    all = function()
                        return { api_key = "test-key" }
                    end
                }

                claude_client._env = {
                    get = function(key)
                        return nil
                    end
                }

                claude_client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 400,
                            stream = mock_stream,
                            headers = { ["request-id"] = "req_stream_error" }
                        }
                    end
                }

                local response, err = claude_client.request("/messages", {}, { stream = true })

                expect(response).to_be_nil()
                expect(err.status_code).to_equal(400)
                expect(err.request_id).to_equal("req_stream_error")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)