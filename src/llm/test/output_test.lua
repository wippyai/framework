local output = require("output")
local time = require("time")

local function define_tests()
    describe("Output Library", function()
        it("should create content responses", function()
            local response = output.content("Hello world")

            test.eq(response.type, output.TYPE.CONTENT)
            test.eq(response.content, "Hello world")
        end)

        it("should create error responses", function()
            local response = output.error(
                output.ERROR_TYPE.INVALID_REQUEST,
                "Bad request",
                400
            )

            test.eq(response.type, output.TYPE.ERROR)
            test.eq(response.error.type, output.ERROR_TYPE.INVALID_REQUEST)
            test.eq(response.error.message, "Bad request")
            test.eq(response.error.code, 400)
        end)

        it("should create tool call responses", function()
            local response = output.tool_call(
                "get_weather",
                '{"location":"London"}',
                "call_123"
            )

            test.eq(response.type, output.TYPE.TOOL_CALL)
            test.eq(response.name, "get_weather")
            test.eq(response.arguments, '{"location":"London"}')
            test.eq(response.id, "call_123")
        end)

        it("should create thinking responses", function()
            local response = output.thinking("Analyzing data...")

            test.eq(response.type, output.TYPE.THINKING)
            test.eq(response.content, "Analyzing data...")
        end)

        it("should calculate usage information", function()
            local usage = output.usage(100, 50, 25)

            test.eq(usage.prompt_tokens, 100)
            test.eq(usage.completion_tokens, 50)
            test.eq(usage.thinking_tokens, 25)
            test.eq(usage.total_tokens, 175)
        end)

        it("should wrap content results", function()
            local wrapped = output.wrap(output.TYPE.CONTENT, "Hello world")

            test.eq(wrapped.type, output.TYPE.CONTENT)
            test.eq(wrapped.content, "Hello world")
        end)

        it("should wrap tool call results", function()
            local wrapped = output.wrap(
                output.TYPE.TOOL_CALL,
                {
                    name = "get_weather",
                    arguments = '{"location":"London"}',
                    id = "call_123"
                }
            )

            test.eq(wrapped.type, output.TYPE.TOOL_CALL)
            test.eq(wrapped.name, "get_weather")
            test.eq(wrapped.arguments, '{"location":"London"}')
            test.eq(wrapped.id, "call_123")
        end)

        it("should wrap error results", function()
            local error_info = {
                type = output.ERROR_TYPE.SERVER_ERROR,
                message = "Internal error",
                code = 500
            }

            local wrapped = output.wrap(output.TYPE.ERROR, error_info)

            test.eq(wrapped.type, output.TYPE.ERROR)
            test.eq(wrapped.error, error_info)
        end)

        it("should include usage information in wrapped results", function()
            local usage_info = output.usage(100, 50, 25)
            local wrapped = output.wrap(
                output.TYPE.CONTENT,
                "Hello world",
                usage_info
            )

            test.eq(wrapped.usage, usage_info)
        end)

        it("should create a streamer with proper configuration", function()
            -- Mock process.send
            local sent_messages = {}
            mock("process.send", function(pid, topic, payload)
                table.insert(sent_messages, {
                    pid = pid,
                    topic = topic,
                    payload = payload
                })
                return true
            end)

            local streamer = output.streamer("test-pid", "custom_topic", 20)
            assert(streamer)

            test.not_nil(streamer)
            test.eq(streamer.pid, "test-pid")
            test.eq(streamer.topic, "custom_topic")
            test.eq(streamer.buffer_size, 20)

            -- Test missing PID
            local bad_streamer, err = output.streamer(nil)
            test.is_nil(bad_streamer)
            test.not_nil(err)
        end)

        it("should send content chunks via streamer", function()
            -- Mock process.send
            local sent_messages = {}
            mock("process.send", function(pid, topic, payload)
                table.insert(sent_messages, {
                    pid = pid,
                    topic = topic,
                    payload = payload
                })
                return true
            end)

            local streamer = output.streamer("test-pid")
            assert(streamer)
            streamer:send_content("Hello world")

            test.eq(#sent_messages, 1)
            local msg = assert(sent_messages[1])
            test.eq(msg.pid, "test-pid")
            test.eq(msg.topic, "llm_response")
            test.eq(msg.payload.type, output.TYPE.CONTENT)
            test.eq(msg.payload.content, "Hello world")
        end)

        it("should send thinking chunks via streamer", function()
            -- Mock process.send
            local sent_messages = {}
            mock("process.send", function(pid, topic, payload)
                table.insert(sent_messages, {
                    pid = pid,
                    topic = topic,
                    payload = payload
                })
                return true
            end)

            local streamer = output.streamer("test-pid")
            assert(streamer)
            streamer:send_thinking("Analyzing...")

            test.eq(#sent_messages, 1)
            local msg = assert(sent_messages[1])
            test.eq(msg.payload.type, output.TYPE.THINKING)
            test.eq(msg.payload.content, "Analyzing...")
        end)

        it("should send tool call chunks via streamer", function()
            -- Mock process.send
            local sent_messages = {}
            mock("process.send", function(pid, topic, payload)
                table.insert(sent_messages, {
                    pid = pid,
                    topic = topic,
                    payload = payload
                })
                return true
            end)

            local streamer = output.streamer("test-pid")
            assert(streamer)
            streamer:send_tool_call("get_weather", '{"location":"London"}', "call_123")

            test.eq(#sent_messages, 1)
            local msg = assert(sent_messages[1])
            test.eq(msg.payload.type, output.TYPE.TOOL_CALL)
            test.eq(msg.payload.name, "get_weather")
            test.eq(msg.payload.arguments, '{"location":"London"}')
            test.eq(msg.payload.id, "call_123")
        end)

        it("should send error chunks via streamer", function()
            -- Mock process.send
            local sent_messages = {}
            mock("process.send", function(pid, topic, payload)
                table.insert(sent_messages, {
                    pid = pid,
                    topic = topic,
                    payload = payload
                })
                return true
            end)

            local streamer = output.streamer("test-pid")
            assert(streamer)
            streamer:send_error(output.ERROR_TYPE.RATE_LIMIT, "Too many requests", 429)

            test.eq(#sent_messages, 1)
            local msg = assert(sent_messages[1])
            test.eq(msg.payload.type, output.TYPE.ERROR)
            test.eq(msg.payload.error.type, output.ERROR_TYPE.RATE_LIMIT)
            test.eq(msg.payload.error.message, "Too many requests")
            test.eq(msg.payload.error.code, 429)
        end)

        it("should buffer content and send on natural breaks", function()
            -- Mock process.send
            local sent_messages = {}
            mock("process.send", function(pid, topic, payload)
                table.insert(sent_messages, {
                    pid = pid,
                    topic = topic,
                    payload = payload
                })
                return true
            end)

            local streamer = output.streamer("test-pid")
            assert(streamer)

            -- Add content that doesn't trigger sending
            local sent = streamer:buffer_content("Hello")
            test.is_false(sent)
            test.eq(#sent_messages, 0)

            -- Add content with period that should trigger sending
            sent = streamer:buffer_content(" world.")
            test.is_true(sent)
            test.eq(#sent_messages, 1)
            local msg = assert(sent_messages[1])
            test.eq(msg.payload.content, "Hello world.")

            -- Buffer should be empty now
            test.eq(streamer.buffer, "")
        end)

        it("should flush remaining buffer content", function()
            -- Mock process.send
            local sent_messages = {}
            mock("process.send", function(pid, topic, payload)
                table.insert(sent_messages, {
                    pid = pid,
                    topic = topic,
                    payload = payload
                })
                return true
            end)

            -- Create streamer with a larger buffer size to prevent auto-send
            local streamer = output.streamer("test-pid", "llm_response", 20)
            assert(streamer)

            -- Empty buffer case - should return false
            local sent = streamer:flush()
            test.is_false(sent)
            test.eq(#sent_messages, 0)

            -- Add content without triggering automatic send
            streamer:buffer_content("Hello world")

            -- Now there should be content to flush
            sent = streamer:flush()
            test.is_true(sent)
            test.eq(#sent_messages, 1)
            local msg = assert(sent_messages[1])
            test.eq(msg.payload.content, "Hello world")

            -- Flush empty buffer should not send anything and return false
            sent = streamer:flush()
            test.is_false(sent)
            test.eq(#sent_messages, 1) -- Still just one message
        end)

        describe("Truncation Detection", function()
            it("should detect truncation when finish_reason is LENGTH with tool_calls", function()
                local result = {
                    finish_reason = output.FINISH_REASON.LENGTH,
                    tool_calls = {
                        { id = "call_1", name = "test_tool", arguments = {} }
                    }
                }
                test.is_true(output.detect_truncation(result))
            end)

            it("should not detect truncation when a LENGTH-cut response still carries text", function()
                local result = {
                    finish_reason = output.FINISH_REASON.LENGTH,
                    tool_calls = {},
                    content = "a partial but usable answer"
                }
                test.is_false(output.detect_truncation(result))
            end)

            it("should detect truncation when LENGTH is hit with no tool calls and no content", function()
                local result = {
                    finish_reason = output.FINISH_REASON.LENGTH,
                    tool_calls = {},
                    content = ""
                }
                test.is_true(output.detect_truncation(result))
            end)

            it("should not detect truncation when finish_reason is STOP with tool_calls", function()
                local result = {
                    finish_reason = output.FINISH_REASON.STOP,
                    tool_calls = {
                        { id = "call_1", name = "test_tool", arguments = {} }
                    }
                }
                test.is_false(output.detect_truncation(result))
            end)

            it("should not detect truncation when finish_reason is TOOL_CALL with tool_calls", function()
                local result = {
                    finish_reason = output.FINISH_REASON.TOOL_CALL,
                    tool_calls = {
                        { id = "call_1", name = "test_tool", arguments = {} }
                    }
                }
                test.is_false(output.detect_truncation(result))
            end)

            it("should not detect truncation for nil result", function()
                test.is_false(output.detect_truncation(nil))
            end)

            it("should detect truncation when tool_calls is nil and nothing was produced", function()
                local result = {
                    finish_reason = output.FINISH_REASON.LENGTH,
                    tool_calls = nil
                }
                test.is_true(output.detect_truncation(result))
            end)

            it("should not detect truncation when tool_calls is nil but result text exists", function()
                local result = {
                    finish_reason = output.FINISH_REASON.LENGTH,
                    tool_calls = nil,
                    result = "text under the alternate field name"
                }
                test.is_false(output.detect_truncation(result))
            end)

            it("should have a non-empty truncation message", function()
                test.not_nil(output.TRUNCATION_MSG)
                test.is_true(#output.TRUNCATION_MSG > 0)
            end)
        end)

        describe("Streamer delivery tracking", function()
            local sent_messages
            local delivered

            before_each(function()
                sent_messages = {}
                delivered = true
                mock("process.send", function(pid, topic, payload)
                    table.insert(sent_messages, payload)
                    return delivered
                end)
            end)

            it("should start with nothing sent", function()
                local streamer = assert(output.streamer("test-pid"))
                test.is_false(streamer.sent_any)
            end)

            it("should not count content still held in the buffer", function()
                local streamer = assert(output.streamer("test-pid", "t", 20))
                streamer:buffer_content("Hello")
                test.eq(#sent_messages, 0)
                test.is_false(streamer.sent_any)

                streamer:flush()
                test.eq(#sent_messages, 1)
                test.is_true(streamer.sent_any)
            end)

            it("should count a buffered chunk once it is delivered", function()
                local streamer = assert(output.streamer("test-pid"))
                streamer:buffer_content("Hello world.")
                test.eq(#sent_messages, 1)
                test.is_true(streamer.sent_any)
            end)

            it("should count every kind of delivered chunk", function()
                local senders = {
                    function(s) s:send_content("text") end,
                    function(s) s:send_thinking("thought") end,
                    function(s) s:send_tool_call("tool", "{}", "call-1") end,
                    function(s) s:send_error(output.ERROR_TYPE.SERVER_ERROR, "boom", nil) end,
                    function(s) s:send_done({ finish_reason = "stop" }) end,
                }
                for _, send in ipairs(senders) do
                    local streamer = assert(output.streamer("test-pid"))
                    send(streamer)
                    test.is_true(streamer.sent_any)
                end
            end)

            it("should not count a chunk the process did not accept", function()
                delivered = false
                local streamer = assert(output.streamer("test-pid"))
                streamer:send_content("text")
                streamer:send_thinking("thought")
                test.eq(#sent_messages, 2)
                test.is_false(streamer.sent_any)
            end)
        end)

        describe("Stream error deferral", function()
            local sent_messages

            before_each(function()
                sent_messages = {}
                mock("process.send", function(pid, topic, payload)
                    table.insert(sent_messages, payload)
                    return true
                end)
            end)

            it("should hold the error chunk back while nothing was sent", function()
                local streamer = assert(output.streamer("test-pid"))
                streamer:buffer_content("Hel")
                local deferred = output.send_or_defer_error(streamer, "server_error", "Overloaded")
                test.eq(#sent_messages, 0)
                local held = assert(deferred)
                test.eq(held.type, "server_error")
                test.eq(held.message, "Overloaded")
            end)

            it("should send the error chunk once the client received part of the answer", function()
                local streamer = assert(output.streamer("test-pid"))
                streamer:send_thinking("thought")
                local deferred = output.send_or_defer_error(streamer, "server_error", "Overloaded")
                test.is_nil(deferred)
                test.eq(#sent_messages, 2)
                local chunk = assert(sent_messages[2])
                test.eq(chunk.type, output.TYPE.ERROR)
                test.eq(chunk.error.type, "server_error")
                test.eq(chunk.error.message, "Overloaded")
            end)

            it("should treat a streamer double without sent_any as nothing sent", function()
                local calls = 0
                local double = { send_error = function() calls = calls + 1 end }
                local deferred = output.send_or_defer_error(double, "UNAVAILABLE", "lost")
                test.eq(calls, 0)
                test.eq(assert(deferred).type, "UNAVAILABLE")
            end)

            it("should describe a stream error without a held chunk", function()
                local started = output.stream_error_details(true, nil)
                test.is_true(started.stream_started)
                test.is_nil(started.deferred_error_type)
                test.is_nil(started.deferred_error_message)

                local not_started = output.stream_error_details(false, nil)
                test.is_false(not_started.stream_started)
            end)

            it("should carry a held chunk in the details", function()
                local details = output.stream_error_details(false, { type = "server_error", message = "Overloaded" })
                test.is_false(details.stream_started)
                test.eq(details.deferred_error_type, "server_error")
                test.eq(details.deferred_error_message, "Overloaded")
            end)
        end)

        describe("Error builder", function()
            it("should keep the LLM error type in the details", function()
                local err = output.errors.generate({ model = "m", _provider_id = "p" })
                    :kind(output.ERROR_TYPE.CONTEXT_LENGTH)
                    :message("too long")
                    :build()
                local details = err:details()
                test.eq(details.error_type, output.ERROR_TYPE.CONTEXT_LENGTH)
                test.eq(details.provider, "p")
                test.eq(details.operation, "generate")
                test.eq(details.model, "m")
                test.eq(err:message(), "too long")
            end)

            it("should record server_error when no kind is given", function()
                local err = output.errors.embed({}):message("unclear"):build()
                test.eq(err:details().error_type, output.ERROR_TYPE.SERVER_ERROR)
            end)

            it("should record the kind the classifier reports", function()
                local err = output.errors.generate({})
                    :classifier(function(http_err)
                        return output.ERROR_TYPE.RATE_LIMIT, "slow down", { status_code = http_err.status_code }
                    end)
                    :from({ status_code = 429 })
                    :build()
                local details = err:details()
                test.eq(details.error_type, output.ERROR_TYPE.RATE_LIMIT)
                test.eq(details.status_code, 429)
            end)

            it("should let the resolved kind win over an error_type passed in details", function()
                local err = output.errors.generate({})
                    :kind(output.ERROR_TYPE.AUTHENTICATION)
                    :message("denied")
                    :details({ error_type = "something_else", stream_started = false })
                    :build()
                local details = err:details()
                test.eq(details.error_type, output.ERROR_TYPE.AUTHENTICATION)
                test.is_false(details.stream_started)
            end)

            it("should keep an unknown kind as the error type", function()
                local err = output.errors.status({}):kind("brand_new_type"):message("odd"):build()
                test.eq(err:details().error_type, "brand_new_type")
                test.is_false(err:retryable())
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
