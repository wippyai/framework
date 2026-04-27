local openai_client = require("openai_client")
local json = require("json")
local test = require("test")

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
                        test.eq(options.headers["Content-Type"], "application/json")
                        test.not_nil(options.body)
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = openai_client.request("/test", {})
                test.is_nil(err)
                test.eq(called_method, "POST")
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
                        test.is_nil(options.headers["Content-Type"])
                        test.is_nil(options.body)
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = openai_client.request("/models", nil, { method = "GET" })
                test.is_nil(err)
                test.eq(called_method, "GET")
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
                        test.is_nil(options.headers["Content-Type"])
                        test.is_nil(options.body)
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = openai_client.request("/files/123", nil, { method = "DELETE" })
                test.is_nil(err)
                test.eq(called_method, "DELETE")
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
                        test.eq(options.headers["Content-Type"], "application/json")
                        test.not_nil(options.body)
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = openai_client.request("/test", { data = "value" }, { method = "PUT" })
                test.is_nil(err)
                test.eq(called_method, "PUT")
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
                        test.eq(options.headers["Content-Type"], "application/json")
                        test.not_nil(options.body)
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = openai_client.request("/test", { update = "value" }, { method = "PATCH" })
                test.is_nil(err)
                test.eq(called_method, "PATCH")
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

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err.status_code, 0)
                test.eq(err.message, "Connection failed")
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

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err.status_code, 0)
                test.eq(err.message, "Connection failed")
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
                        test.eq(options.headers["Authorization"], "Bearer context-key")
                        return { status_code = 200, body = '{"test": true}', headers = {} }
                    end
                }

                local response, err = openai_client.request("/test", {})
                test.is_nil(err)
                test.is_true(response.test)
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
                        test.eq(options.headers["Authorization"], "Bearer env-key")
                        return { status_code = 200, body = '{"test": true}', headers = {} }
                    end
                }

                local response, err = openai_client.request("/test", {})
                test.is_nil(err)
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
                        test.eq(url, "https://custom.api/v1/test")
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = openai_client.request("/test", {})
                test.is_nil(err)
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
                        test.eq(options.timeout, 60)
                        return { status_code = 200, body = '{}', headers = {} }
                    end
                }

                local response, err = openai_client.request("/test", {})
                test.is_nil(err)
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

                test.is_nil(response)
                test.eq(err.status_code, 401)
                test.contains(err.message, "API key is required")
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

                test.is_nil(response)
                test.eq(err.status_code, 404)
                test.eq(err.message, "Model not found")
                test.eq(err.code, "model_not_found")
                test.eq(err.type, "invalid_request_error")
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

                test.is_nil(response)
                test.eq(err.status_code, 0)
                test.eq(err.message, "Connection failed")
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

                test.is_nil(response)
                test.not_nil(err.metadata)
                local err_meta = assert(err.metadata)
                test.eq(err_meta.request_id, "req_error123")
                test.eq(err_meta.processing_ms, 250)
            end)
        end)

        describe("Streaming Support", function()
            local function build_mock_stream(chunks)
                local s = { chunks = chunks, current = 0 }
                setmetatable(s, {
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
                return s
            end

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

                -- Responses API stream: named SSE events with embedded `type` field
                local mock_stream = build_mock_stream({
                    'data: {"type":"response.completed","response":{"id":"r","status":"completed","usage":{"input_tokens":1,"output_tokens":1}}}\n\n'
                })

                openai_client._http_client = {
                    post = function(url, http_options)
                        test.is_true(http_options.stream)
                        local payload = json.decode(tostring(http_options.body))
                        test.is_true(payload.stream)
                        -- Responses API does not require stream_options.include_usage:
                        -- usage is delivered inside the response.completed event.
                        test.is_nil(payload.stream_options)

                        return {
                            status_code = 200,
                            stream = mock_stream,
                            headers = {}
                        }
                    end
                }

                local response, err = openai_client.request("/responses", {}, { stream = true })

                test.is_nil(err)
                test.not_nil(response.stream)
            end)

            it("should process streaming content correctly", function()
                -- Responses API content deltas: response.output_text.delta events
                local mock_stream = build_mock_stream({
                    'data: {"type":"response.created","response":{"id":"r1","status":"in_progress"}}\n\n',
                    'data: {"type":"response.output_item.added","output_index":0,"item":{"type":"message","id":"msg_1","role":"assistant","content":[]}}\n\n',
                    'data: {"type":"response.output_text.delta","item_id":"msg_1","output_index":0,"content_index":0,"sequence_number":1,"delta":"Hello"}\n\n',
                    'data: {"type":"response.output_text.delta","item_id":"msg_1","output_index":0,"content_index":0,"sequence_number":2,"delta":" world"}\n\n',
                    'data: {"type":"response.output_text.done","item_id":"msg_1","output_index":0,"content_index":0,"sequence_number":3,"text":"Hello world"}\n\n',
                    'data: {"type":"response.completed","response":{"id":"r1","status":"completed","usage":{"input_tokens":3,"output_tokens":2,"total_tokens":5}}}\n\n'
                })

                local stream_response = {
                    stream = mock_stream,
                    metadata = { request_id = "req_stream123" }
                }

                local content_chunks = {}
                local done_result = nil

                local full_content, err, _ = openai_client.process_stream(stream_response, {
                    on_content = function(chunk)
                        table.insert(content_chunks, chunk)
                    end,
                    on_done = function(r)
                        done_result = r
                    end
                })

                test.is_nil(err)
                test.eq(full_content, "Hello world")
                test.eq(#content_chunks, 2)
                test.eq(content_chunks[1], "Hello")
                test.eq(content_chunks[2], " world")

                local r = assert(done_result) :: any
                test.eq(r.status, "completed")
                test.eq(r.response_id, "r1")
                test.eq(r.usage.input_tokens, 3)
                test.eq(r.usage.output_tokens, 2)
            end)

            it("should process streaming tool calls", function()
                -- Responses API tool call streaming:
                --  output_item.added announces the function_call (id, call_id, name)
                --  function_call_arguments.delta accumulates argument JSON chunks
                --  function_call_arguments.done finalizes the call
                local mock_stream = build_mock_stream({
                    'data: {"type":"response.output_item.added","output_index":0,"item":{"type":"function_call","id":"fc_1","call_id":"call_123","name":"test_tool","arguments":""}}\n\n',
                    'data: {"type":"response.function_call_arguments.delta","item_id":"fc_1","output_index":0,"sequence_number":1,"delta":"{\\"param\\""}\n\n',
                    'data: {"type":"response.function_call_arguments.delta","item_id":"fc_1","output_index":0,"sequence_number":2,"delta":": \\"value\\"}"}\n\n',
                    'data: {"type":"response.function_call_arguments.done","item_id":"fc_1","output_index":0,"sequence_number":3,"name":"test_tool","arguments":"{\\"param\\": \\"value\\"}"}\n\n',
                    'data: {"type":"response.completed","response":{"id":"r2","status":"completed","usage":{"input_tokens":1,"output_tokens":1}}}\n\n'
                })

                local stream_response = {
                    stream = mock_stream,
                    metadata = {}
                }

                local tool_calls = {}

                local _, err, _ = openai_client.process_stream(stream_response, {
                    on_tool_call = function(tool_call)
                        table.insert(tool_calls, tool_call)
                    end
                })

                test.is_nil(err)
                test.eq(#tool_calls, 1)
                local tc = assert(tool_calls[1])
                test.eq(tc.id, "call_123")
                test.eq(tc.name, "test_tool")
                test.eq(tc.arguments, '{"param": "value"}')
            end)

            it("should forward reasoning summary deltas via on_reasoning", function()
                -- Reasoning summary streaming event: response.reasoning_summary_text.delta
                local mock_stream = build_mock_stream({
                    'data: {"type":"response.output_item.added","output_index":0,"item":{"type":"reasoning","id":"rs_1","summary":[]}}\n\n',
                    'data: {"type":"response.reasoning_summary_text.delta","item_id":"rs_1","output_index":0,"summary_index":0,"sequence_number":1,"delta":"step1"}\n\n',
                    'data: {"type":"response.reasoning_summary_text.delta","item_id":"rs_1","output_index":0,"summary_index":0,"sequence_number":2,"delta":" step2"}\n\n',
                    'data: {"type":"response.completed","response":{"id":"r3","status":"completed","usage":{"input_tokens":1,"output_tokens":1}}}\n\n'
                })

                local reasoning_chunks = {}
                local _, err, _ = openai_client.process_stream({ stream = mock_stream, metadata = {} }, {
                    on_reasoning = function(chunk) table.insert(reasoning_chunks, chunk) end
                })

                test.is_nil(err)
                test.eq(#reasoning_chunks, 2)
                test.eq(reasoning_chunks[1], "step1")
                test.eq(reasoning_chunks[2], " step2")
            end)

            it("should propagate response.failed events to on_error", function()
                local mock_stream = build_mock_stream({
                    'data: {"type":"response.failed","response":{"id":"r4","status":"failed","error":{"message":"boom","type":"server_error","code":"err_500"}}}\n\n'
                })

                local seen_error = nil
                local _, err, _ = openai_client.process_stream({ stream = mock_stream, metadata = {} }, {
                    on_error = function(e) seen_error = e end
                })

                test.not_nil(err)
                test.not_nil(seen_error)
                local se = assert(seen_error) :: any
                test.eq(se.message, "boom")
                test.eq(se.type, "server_error")
                test.eq(se.code, "err_500")
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

                test.is_nil(err)
                test.not_nil(response.metadata)
                local meta = assert(response.metadata)
                test.eq(meta.request_id, "req_metadata123")
                test.eq(meta.organization, "org-test")
                test.eq(meta.processing_ms, 150)
                test.eq(meta.version, "2023-12-01")
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

                test.is_nil(err)
                test.not_nil(response.metadata.rate_limits)
                test.eq(response.metadata.rate_limits.limit_requests, 5000)
                test.eq(response.metadata.rate_limits.remaining_requests, 4999)
                test.eq(response.metadata.rate_limits.limit_tokens, 200000)
                test.eq(response.metadata.rate_limits.remaining_tokens, 199500)
            end)
        end)

        describe("POST Request Shape", function()
            it("should POST JSON with auth + content-type to base_url + endpoint_path", function()
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
                        test.eq(url, "https://api.openai.com/v1/responses")
                        test.eq(options.headers["Content-Type"], "application/json")
                        test.eq(options.headers["Authorization"], "Bearer test-key")
                        test.not_nil(options.body)
                        local payload = json.decode(tostring(options.body))
                        test.eq(payload.model, "gpt-5.4")
                        return { status_code = 200, body = '{"test": "success"}', headers = {} }
                    end
                }

                local response, err = openai_client.request("/responses", { model = "gpt-5.4" })
                test.is_nil(err)
                test.eq(response.test, "success")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
