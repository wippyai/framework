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
                        test.eq(options.headers["content-type"], "application/json")
                        test.eq(options.headers["x-api-key"], "test-key")
                        test.eq(options.headers["anthropic-version"], "2023-06-01")
                        test.not_nil(options.body)
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/messages", {})
                test.is_nil(err)
                test.eq(called_method, "POST")
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
                        test.is_nil(options.headers["content-type"])
                        test.eq(options.headers["x-api-key"], "test-key")
                        test.is_nil(options.body)
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/status", nil, { method = "GET" })
                test.is_nil(err)
                test.eq(called_method, "GET")
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
                        test.is_nil(options.headers["content-type"])
                        test.is_nil(options.body)
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/resource/123", nil, { method = "DELETE" })
                test.is_nil(err)
                test.eq(called_method, "DELETE")
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
                        test.eq(options.headers["content-type"], "application/json")
                        test.not_nil(options.body)
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/resource", { data = "value" }, { method = "PUT" })
                test.is_nil(err)
                test.eq(called_method, "PUT")
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
                        test.eq(options.headers["content-type"], "application/json")
                        test.not_nil(options.body)
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/resource", { update = "value" }, { method = "PATCH" })
                test.is_nil(err)
                test.eq(called_method, "PATCH")
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

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err.status_code, 0)
                test.eq(err.message, "Connection failed")
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

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err.status_code, 0)
                test.eq(err.message, "Connection failed")
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
                        test.eq(options.headers["x-api-key"], "context-key")
                        return { status_code = 200, body = '{"test": true}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/messages", {})
                test.is_nil(err)
                test.is_true(response.test)
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
                        test.eq(options.headers["x-api-key"], "env-key")
                        return { status_code = 200, body = '{"test": true}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/messages", {})
                test.is_nil(err)
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
                        test.eq(url, "https://custom.claude.api/messages")
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/messages", {})
                test.is_nil(err)
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
                        test.eq(options.headers["anthropic-version"], "2024-02-01")
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/messages", {})
                test.is_nil(err)
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
                        test.eq(options.headers["anthropic-beta"], "computer-use-2024-10-22,prompt-caching-2024-07-31")
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/messages", {})
                test.is_nil(err)
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
                        test.eq(options.timeout, 120)
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/messages", {})
                test.is_nil(err)
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
                        test.eq(options.headers["x-custom-header"], "custom-value")
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/messages", {})
                test.is_nil(err)
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

                test.is_nil(response)
                test.eq(err.status_code, 401)
                test.contains(err.message, "API key is required")
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

                test.is_nil(response)
                test.eq(err.status_code, 400)
                test.eq(err.message, "Invalid model specified")
                test.eq(err.error.type, "invalid_request_error")
                test.eq(err.request_id, "req_claude123")
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

                test.is_nil(response)
                test.eq(err.status_code, 429)
                test.eq(err.message, "Rate limit exceeded")
                test.eq(err.metadata.rate_limits.requests_limit, 1000)
                test.eq(err.metadata.rate_limits.requests_remaining, 0)
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

                test.is_nil(response)
                test.eq(err.status_code, 401)
                test.eq(err.message, "Invalid API key")
                test.eq(err.error.type, "authentication_error")
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

                test.is_nil(response)
                test.eq(err.status_code, 0)
                test.eq(err.message, "Connection failed")
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

                test.is_nil(response)
                test.not_nil(err.metadata)
                local err_meta = assert(err.metadata)
                test.eq(err_meta.request_id, "req_error123")
                test.eq(err_meta.processing_ms, 350)
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

                test.is_nil(response)
                test.eq(err.status_code, 500)
                test.contains(err.message, "Claude API error")
                test.eq(err.request_id, "req_malformed")
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
                        test.is_true(http_options.stream)
                        local payload = json.decode(tostring(http_options.body))
                        test.is_true(payload.stream)

                        return {
                            status_code = 200,
                            stream = mock_stream,
                            headers = {}
                        }
                    end
                }

                local response, err = claude_client.request("/messages", {}, { stream = true })

                test.is_nil(err)
                test.not_nil(response.stream)
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

                test.is_nil(err)
                test.eq(full_content, "Hello world")
                test.eq(#content_chunks, 2)
                test.eq(content_chunks[1], "Hello")
                test.eq(content_chunks[2], " world")
                test.eq(finish_reason, "end_turn")
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

                test.is_nil(err)
                test.eq(#tool_calls, 1)
                local tc = assert(tool_calls[1])
                test.eq(tc.id, "call_123")
                test.eq(tc.name, "test_tool")
                test.eq(tc.arguments.param, "value")
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

                test.is_nil(err)
                test.eq(full_content, "42")
                test.eq(#thinking_chunks, 2)
                test.eq(thinking_chunks[1], "Let me think...")
                test.eq(thinking_chunks[2], " The answer is")

                -- result.thinking is an array of thinking block objects
                local res = assert(result)
                test.eq(#res.thinking, 1)
                local thinking_block = assert(res.thinking[1])
                test.eq(thinking_block.type, "thinking")
                test.eq(thinking_block.thinking, "Let me think... The answer is")

                test.eq(#content_chunks, 1)
                test.eq(content_chunks[1], "42")
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

                test.eq(err, "API overloaded")
                test.eq(#errors, 1)
                local err_info = assert(errors[1])
                test.eq(err_info.message, "API overloaded")
                test.eq(err_info.type, "overloaded_error")
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

                test.is_nil(err)
                test.not_nil(response.metadata)
                local meta = assert(response.metadata)
                test.eq(meta.request_id, "req_metadata123")
                test.eq(meta.processing_ms, 250)
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

                test.is_nil(err)
                test.not_nil(response.metadata.rate_limits)
                test.eq(response.metadata.rate_limits.requests_limit, 1000)
                test.eq(response.metadata.rate_limits.requests_remaining, 999)
                test.eq(response.metadata.rate_limits.tokens_limit, 100000)
                test.eq(response.metadata.rate_limits.tokens_remaining, 99500)
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

                test.is_nil(err)
                local meta = assert(response.metadata)
                test.eq(meta.request_id, "req_alt_format123")
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

                test.is_nil(err)
                test.not_nil(response.content)
                test.eq(response.content[1].text, "Hello!")
                test.eq(response.stop_reason, "end_turn")
                test.eq(response.usage.input_tokens, 10)
                local meta = assert(response.metadata)
                test.eq(meta.request_id, "req_parse123")
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

                test.is_nil(response)
                test.eq(err.status_code, 200)
                test.contains(err.message, "Failed to parse Claude response")
                local err_meta = assert(err.metadata)
                test.eq(err_meta.request_id, "req_parse_fail")
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
                        test.eq(url, "https://api.anthropic.com/v1/messages")
                        test.eq(options.headers["content-type"], "application/json")
                        test.eq(options.headers["x-api-key"], "test-key")
                        test.eq(options.headers["anthropic-version"], "2023-06-01")
                        test.not_nil(options.body)
                        local payload = json.decode(tostring(options.body))
                        test.eq(payload.model, "claude-3-sonnet-20240229")
                        return { status_code = 200, body = '{"test": "success"}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/v1/messages", { model = "claude-3-sonnet-20240229" })
                test.is_nil(err)
                test.eq(response.test, "success")
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
                        test.eq(url, "https://api.anthropic.com/messages")
                        test.eq(options.headers["x-api-key"], "default-env-key")
                        test.eq(options.headers["anthropic-version"], "2023-06-01")
                        test.eq(options.timeout, 600)
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/messages", {})
                test.is_nil(err)
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
                        test.is_nil(options.headers["anthropic-beta"])
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/messages", {})
                test.is_nil(err)
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

                test.eq(err, "Stream read failed")
                test.eq(#errors, 1)
                local err_info = assert(errors[1])
                test.eq(err_info.message, "Stream read failed")
            end)

            it("should handle invalid stream response", function()
                local full_content, err = claude_client.process_stream(nil)
                test.is_nil(full_content)
                test.eq(err, "Invalid stream response")

                local full_content2, err2 = claude_client.process_stream({})
                test.is_nil(full_content2)
                test.eq(err2, "Invalid stream response")
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

                test.is_nil(err)
                test.eq(full_content, "Hello")
                test.eq(#content_chunks, 1)
            end)

            it("should handle SSE events split across chunk boundaries", function()
                local stream_chunks = {
                    'event: message_start\ndata: {"type":"message_start","message":{"usage":{"input_tokens":10,"output_tokens":0}}}\n\n',
                    'event: content_block_start\ndata: {"type":"content_block_start","index":0,"content_block":{"type":"tool_use","id":"call_split","name":"run_script"}}\n\n',
                    'event: content_block_delta\ndata: {"type":"content_block_delta","index":0,"delta":{"type":"input_json_delta","partial_json":"{\\"scr"}}\n\n' ..
                    'event: content_block_del',
                    'ta\ndata: {"type":"content_block_delta","index":0,"delta":{"type":"input_json_delta","partial_json":"ipt\\": \\"echo"}}\n\n',
                    'event: content_block_delta\ndata: {"type":"content_block_delta","index":0,"delta":{"type":"input_json_delta","partial_json":" hello\\"}"}}\n\nevent: content_block_stop\ndata: {"type":"content_block_stop","index":0}\n\n',
                    'event: message_delta\ndata: {"type":"message_delta","delta":{"stop_reason":"tool_use"},"usage":{"output_tokens":8}}\n\n',
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

                test.is_nil(err)
                test.eq(#tool_calls, 1)
                local tc = assert(tool_calls[1])
                test.eq(tc.id, "call_split")
                test.eq(tc.name, "run_script")
                test.eq(tc.arguments.script, "echo hello")
            end)

            it("should handle chunk containing no complete events", function()
                local stream_chunks = {
                    'event: message_sta',
                    'rt\ndata: {"type":"message_start","message":{"usage":{"input_tokens":5,"output_tokens":0}}}\n\n',
                    'event: content_block_start\ndata: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}\n\n',
                    'event: content_block_delta\ndata: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"OK"}}\n\n',
                    'event: content_block_stop\ndata: {"type":"content_block_stop","index":0}\n\n',
                    'event: message_delta\ndata: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":1}}\n\n',
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

                test.is_nil(err)
                test.eq(full_content, "OK")
                test.eq(#content_chunks, 1)
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
                        test.eq(options.headers["x-api-key"], "fallback-key")
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/messages", {})
                test.is_nil(err)
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
                        test.eq(url, "https://env.claude.api/messages")  -- From env via context
                        test.eq(options.headers["x-api-key"], "direct-key")  -- Direct context
                        test.eq(options.timeout, 90)  -- Direct context
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/messages", {})
                test.is_nil(err)
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
                        test.eq(options.timeout, 30)  -- Request option overrides context
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = claude_client.request("/messages", {}, { timeout = 30 })
                test.is_nil(err)
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

                test.is_nil(response)
                test.eq(err.status_code, 400)
                test.eq(err.request_id, "req_stream_error")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
