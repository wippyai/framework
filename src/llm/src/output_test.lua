local output = require("output")
local time = require("time")

local function define_tests()
    describe("Output Library", function()
        it("should create content responses", function()
            local response = output.content("Hello world")

            expect(response.type).to_equal(output.TYPE.CONTENT)
            expect(response.content).to_equal("Hello world")
        end)

        it("should create error responses", function()
            local response = output.error(
                output.ERROR_TYPE.INVALID_REQUEST,
                "Bad request",
                400
            )

            expect(response.type).to_equal(output.TYPE.ERROR)
            expect(response.error.type).to_equal(output.ERROR_TYPE.INVALID_REQUEST)
            expect(response.error.message).to_equal("Bad request")
            expect(response.error.code).to_equal(400)
        end)

        it("should create tool call responses", function()
            local response = output.tool_call(
                "get_weather",
                '{"location":"London"}',
                "call_123"
            )

            expect(response.type).to_equal(output.TYPE.TOOL_CALL)
            expect(response.name).to_equal("get_weather")
            expect(response.arguments).to_equal('{"location":"London"}')
            expect(response.id).to_equal("call_123")
        end)

        it("should create thinking responses", function()
            local response = output.thinking("Analyzing data...")

            expect(response.type).to_equal(output.TYPE.THINKING)
            expect(response.content).to_equal("Analyzing data...")
        end)

        it("should calculate usage information", function()
            local usage = output.usage(100, 50, 25)

            expect(usage.prompt_tokens).to_equal(100)
            expect(usage.completion_tokens).to_equal(50)
            expect(usage.thinking_tokens).to_equal(25)
            expect(usage.total_tokens).to_equal(175)
        end)

        it("should wrap content results", function()
            local wrapped = output.wrap(output.TYPE.CONTENT, "Hello world")

            expect(wrapped.type).to_equal(output.TYPE.CONTENT)
            expect(wrapped.content).to_equal("Hello world")
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

            expect(wrapped.type).to_equal(output.TYPE.TOOL_CALL)
            expect(wrapped.name).to_equal("get_weather")
            expect(wrapped.arguments).to_equal('{"location":"London"}')
            expect(wrapped.id).to_equal("call_123")
        end)

        it("should wrap error results", function()
            local error_info = {
                type = output.ERROR_TYPE.SERVER_ERROR,
                message = "Internal error",
                code = 500
            }

            local wrapped = output.wrap(output.TYPE.ERROR, error_info)

            expect(wrapped.type).to_equal(output.TYPE.ERROR)
            expect(wrapped.error).to_equal(error_info)
        end)

        it("should include usage information in wrapped results", function()
            local usage_info = output.usage(100, 50, 25)
            local wrapped = output.wrap(
                output.TYPE.CONTENT,
                "Hello world",
                usage_info
            )

            expect(wrapped.usage).to_equal(usage_info)
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

            expect(streamer).not_to_be_nil()
            expect(streamer.pid).to_equal("test-pid")
            expect(streamer.topic).to_equal("custom_topic")
            expect(streamer.buffer_size).to_equal(20)

            -- Test missing PID
            local bad_streamer, err = output.streamer(nil)
            expect(bad_streamer).to_be_nil()
            expect(err).not_to_be_nil()
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
            streamer:send_content("Hello world")

            expect(#sent_messages).to_equal(1)
            expect(sent_messages[1].pid).to_equal("test-pid")
            expect(sent_messages[1].topic).to_equal("llm_response")
            expect(sent_messages[1].payload.type).to_equal(output.TYPE.CONTENT)
            expect(sent_messages[1].payload.content).to_equal("Hello world")
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
            streamer:send_thinking("Analyzing...")

            expect(#sent_messages).to_equal(1)
            expect(sent_messages[1].payload.type).to_equal(output.TYPE.THINKING)
            expect(sent_messages[1].payload.content).to_equal("Analyzing...")
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
            streamer:send_tool_call("get_weather", '{"location":"London"}', "call_123")

            expect(#sent_messages).to_equal(1)
            expect(sent_messages[1].payload.type).to_equal(output.TYPE.TOOL_CALL)
            expect(sent_messages[1].payload.name).to_equal("get_weather")
            expect(sent_messages[1].payload.arguments).to_equal('{"location":"London"}')
            expect(sent_messages[1].payload.id).to_equal("call_123")
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
            streamer:send_error(output.ERROR_TYPE.RATE_LIMIT, "Too many requests", 429)

            expect(#sent_messages).to_equal(1)
            expect(sent_messages[1].payload.type).to_equal(output.TYPE.ERROR)
            expect(sent_messages[1].payload.error.type).to_equal(output.ERROR_TYPE.RATE_LIMIT)
            expect(sent_messages[1].payload.error.message).to_equal("Too many requests")
            expect(sent_messages[1].payload.error.code).to_equal(429)
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

            -- Add content that doesn't trigger sending
            local sent = streamer:buffer_content("Hello")
            expect(sent).to_be_false()
            expect(#sent_messages).to_equal(0)

            -- Add content with period that should trigger sending
            sent = streamer:buffer_content(" world.")
            expect(sent).to_be_true()
            expect(#sent_messages).to_equal(1)
            expect(sent_messages[1].payload.content).to_equal("Hello world.")

            -- Buffer should be empty now
            expect(streamer.buffer).to_equal("")
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

            -- Empty buffer case - should return false
            local sent = streamer:flush()
            expect(sent).to_be_false()
            expect(#sent_messages).to_equal(0)

            -- Add content without triggering automatic send
            streamer:buffer_content("Hello world")

            -- Now there should be content to flush
            sent = streamer:flush()
            expect(sent).to_be_true()
            expect(#sent_messages).to_equal(1)
            expect(sent_messages[1].payload.content).to_equal("Hello world")

            -- Flush empty buffer should not send anything and return false
            sent = streamer:flush()
            expect(sent).to_be_false()
            expect(#sent_messages).to_equal(1) -- Still just one message
        end)
    end)
end

return require("test").run_cases(define_tests)
