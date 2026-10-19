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

            it("should not retry past the call deadline from the context", function()
                use_context({ retry = { attempts = 3, backoff_ms = 0 }, deadline_at = 1 })
                local http = flaky_http({ 503, 503, 200 })

                local response, err = bedrock_client.converse("test-model", { messages = {} })

                test.is_nil(response)
                test.eq(err.status_code, 503)
                test.eq(http.calls, 1)
            end)
        end)

        describe("ConverseStream", function()
            -- Eventstream message with zeroed CRCs; the client does not verify them.
            local function header(name: string, type_id: number, value_bytes: string): string
                return string.char(#name) .. name .. string.char(type_id) .. value_bytes
            end

            local function string_header(name: string, value: string): string
                return header(name, 7, string.pack(">I2", #value) .. value)
            end

            local function message(headers: string, payload: string): string
                local total = 12 + #headers + #payload + 4
                return string.pack(">I4I4I4", total, #headers, 0) .. headers .. payload .. string.pack(">I4", 0)
            end

            local function event(event_type: string, body: any): string
                return message(
                    string_header(":event-type", event_type)
                        .. string_header(":content-type", "application/json")
                        .. string_header(":message-type", "event"),
                    json.encode(body))
            end

            local function delta(text: string): string
                return event("contentBlockDelta", { contentBlockIndex = 0, delta = { text = text } })
            end

            local function conversation(): {string}
                return {
                    event("messageStart", { role = "assistant" }),
                    delta("Hel"),
                    delta("lo"),
                    delta(" world"),
                    event("contentBlockStop", { contentBlockIndex = 0 }),
                    event("messageStop", { stopReason = "end_turn" }),
                    event("metadata", { usage = { inputTokens = 3, outputTokens = 4 } }),
                }
            end

            -- Serves the given chunks one read at a time, then nil (end of stream).
            local function chunked_stream(chunks: {string})
                local state = { reads = 0 }
                state.stream = {
                    read = function(_self, _size)
                        state.reads = state.reads + 1
                        return chunks[state.reads]
                    end
                }
                return state
            end

            local function split_every(data: string, size: number): {string}
                local chunks = {}
                for i = 1, #data, size do
                    table.insert(chunks, data:sub(i, i + size - 1))
                end
                return chunks
            end

            local function run(chunks: {string})
                local source = chunked_stream(chunks)
                local seen: { content_reads: {{ chunk: string, reads: number }}, errors: {any} } = {
                    content_reads = {},
                    errors = {}
                }
                local content, err, result = bedrock_client.process_converse_stream({ stream = source.stream }, {
                    on_content = function(chunk)
                        table.insert(seen.content_reads, { chunk = chunk, reads = source.reads })
                    end,
                    on_error = function(info)
                        table.insert(seen.errors, info)
                    end
                })
                return content, err, result, seen, source
            end

            it("should dispatch each delta as soon as its message arrives", function()
                local content, err, result, seen, source = run(conversation())

                test.is_nil(err)
                test.eq(content, "Hello world")
                test.eq(result.finish_reason, "end_turn")
                test.eq(result.usage.outputTokens, 4)
                test.eq(#seen.content_reads, 3)
                -- One message per read: "Hel" must be delivered on read 2, long before the stream ends.
                test.eq(seen.content_reads[1].reads, 2)
                test.eq(seen.content_reads[3].reads, 4)
                test.is_true(source.reads > seen.content_reads[3].reads)
            end)

            it("should reassemble messages split across reads", function()
                local content, err = run(split_every(table.concat(conversation()), 5))

                test.is_nil(err)
                test.eq(content, "Hello world")
            end)

            it("should keep reading after an empty chunk", function()
                local messages = conversation()
                table.insert(messages, 3, "")

                local content, err = run(messages)

                test.is_nil(err)
                test.eq(content, "Hello world")
            end)

            it("should surface an exception message as an error", function()
                local messages = conversation()
                messages[3] = message(
                    string_header(":message-type", "exception")
                        .. string_header(":exception-type", "throttlingException")
                        .. string_header(":content-type", "application/json"),
                    json.encode({ message = "Too many requests" }))

                local content, err, _, seen = run(messages)

                test.is_nil(content)
                test.eq(err, "Too many requests")
                test.eq(#seen.errors, 1)
                test.eq(seen.errors[1].type, "throttlingException")
            end)

            it("should read headers that follow a non-string header", function()
                local messages = conversation()
                messages[2] = message(
                    header(":date", 8, string.pack(">i8", 0))
                        .. string_header(":event-type", "contentBlockDelta")
                        .. string_header(":message-type", "event"),
                    json.encode({ contentBlockIndex = 0, delta = { text = "Hel" } }))

                local content, err = run(messages)

                test.is_nil(err)
                test.eq(content, "Hello world")
            end)

            it("should report a stream that ends mid-message", function()
                local messages = conversation()
                messages[#messages] = messages[#messages]:sub(1, 10)

                local content, err, _, seen = run(messages)

                test.is_nil(content)
                test.contains(err, "Truncated eventstream")
                test.eq(#seen.errors, 1)
            end)

            it("should reject zero and undersized frame lengths without hanging", function()
                for _, total in ipairs({ 0, 1, 12, 15 }) do
                    local frame = string.pack(">I4I4I4I4", total, 0, 0, 0)
                    local content, err, _, seen = run({ frame })

                    test.is_nil(content)
                    test.contains(err, "message length must be at least 16 bytes")
                    test.eq(#seen.errors, 1)
                end
            end)

            it("should reject headers outside the declared frame before reading further", function()
                -- The prelude alone already proves this frame is impossible:
                -- a 20-byte frame has only 4 bytes available for headers/payload.
                local frame = string.pack(">I4I4I4", 20, 5, 0)
                local content, err, _, seen, source = run({ frame, delta("unreachable") })

                test.is_nil(content)
                test.contains(err, "headers exceed the message length")
                test.eq(#seen.errors, 1)
                test.eq(#seen.content_reads, 0)
                test.eq(source.reads, 1)
            end)

            it("should validate the next frame after delivering a valid event", function()
                local frame = string.pack(">I4I4I4I4", 0, 0, 0, 0)
                local content, err, _, seen = run({ delta("prefix") .. frame })

                test.is_nil(content)
                test.contains(err, "message length must be at least 16 bytes")
                test.eq(#seen.errors, 1)
                test.eq(#seen.content_reads, 1)
                test.eq(seen.content_reads[1].chunk, "prefix")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
