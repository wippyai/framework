local delay_tool = require("delay_tool")

local function define_tests()
    describe("Delay Tool", function()
        describe("delayed_echo", function()
            it("should return message and delay info", function()
                local result = delay_tool.delayed_echo({
                    message = "test message",
                    delay_ms = 10
                })

                test.not_nil(result)
                test.eq(result.message, "test message")
                test.eq(result.delay_applied, 10)
                test.not_nil(result.timestamp)
                test.eq(type(result.timestamp), "string")
                test.not_nil(result.unix_time)
                test.eq(type(result.unix_time), "number")
            end)

            it("should use default delay when not provided", function()
                local result = delay_tool.delayed_echo({
                    message = "no delay specified"
                })

                test.not_nil(result)
                test.eq(result.message, "no delay specified")
                test.eq(result.delay_applied, 100)
            end)

            it("should respect custom delay_ms", function()
                local time = require("time")
                local start = time.now()

                local result = delay_tool.delayed_echo({
                    message = "custom delay",
                    delay_ms = 50
                })

                local elapsed = time.now():sub(start):milliseconds()

                test.eq(result.delay_applied, 50)
                test.is_true(elapsed >= 50)
            end)

            it("should use default message when not provided", function()
                local result = delay_tool.delayed_echo({
                    delay_ms = 10
                })

                test.eq(result.message, "Hello")
            end)

            it("should include context information", function()
                local result = delay_tool.delayed_echo({
                    message = "ctx check",
                    delay_ms = 10
                })

                test.not_nil(result.context_received)
                test.eq(type(result.context_received), "table")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
