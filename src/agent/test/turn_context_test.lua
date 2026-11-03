local turn_context = require("turn_context")
local time = require("time")

local function define_tests()
    describe("Turn context", function()
        local now = time.date(2026, 11, 3, 9, 44, 7, 0, time.utc)

        local function options(time_config)
            return { turn_context = { time = time_config } }
        end

        it("renders the exact current minute in the configured timezone", function()
            local text, err = turn_context.render(options({ timezone = "UTC" }), now)
            test.is_nil(err)
            test.eq(text, "The current date and time is Tuesday, November 3, 2026 at 09:44 UTC.")
        end)

        it("converts the time into a named timezone", function()
            local text, err = turn_context.render(options({ timezone = "America/New_York" }), now)
            test.is_nil(err)
            test.eq(text, "The current date and time is Tuesday, November 3, 2026 at 04:44 America/New_York.")
        end)

        it("formats the time with a configured layout", function()
            local text, err = turn_context.render(
                options({ timezone = "America/New_York", format = "2006-01-02 15:04 MST" }), now)
            test.is_nil(err)
            test.eq(text, "The current date and time is 2026-11-03 04:44 EST.")
        end)

        it("renders identical text for the same instant", function()
            local first = turn_context.render(options({ timezone = "UTC" }), now)
            local second = turn_context.render(options({ timezone = "UTC" }), time.unix(now:unix(), 0))
            test.eq(second, first)
        end)

        it("renders nothing when the agent has no turn context", function()
            for _, agent_options in ipairs({ {}, { turn_context = {} } }) do
                local text, err = turn_context.render(agent_options, now)
                test.is_nil(text)
                test.is_nil(err)
            end
        end)

        it("rejects an unknown timezone", function()
            local text, err = turn_context.render(options({ timezone = "Mars/Olympus" }), now)
            test.is_nil(text)
            test.contains(tostring(err), "Mars/Olympus")
        end)
    end)
end

return require("test").run_cases(define_tests)
