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

            it("should not detect truncation when finish_reason is LENGTH without tool_calls", function()
                local result = {
                    finish_reason = output.FINISH_REASON.LENGTH,
                    tool_calls = {}
                }
                test.is_false(output.detect_truncation(result))
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

            it("should not detect truncation when tool_calls is nil", function()
                local result = {
                    finish_reason = output.FINISH_REASON.LENGTH,
                    tool_calls = nil
                }
                test.is_false(output.detect_truncation(result))
            end)

            it("should have a non-empty truncation message", function()
                test.not_nil(output.TRUNCATION_MSG)
                test.is_true(#output.TRUNCATION_MSG > 0)
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
