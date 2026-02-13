local init_time_aware = require("init_time_aware")

local function define_tests()
    describe("Init Time Aware Trait", function()
        it("should return prompt with time info", function()
            local result = init_time_aware.execute("base prompt")

            test.not_nil(result)
            test.not_nil(result.prompt)
            test.eq(type(result.prompt), "string")
            test.is_true(#result.prompt > 0)
        end)

        it("should contain date components in prompt", function()
            local time = require("time")
            local now = time.now()
            local result = init_time_aware.execute("base prompt")

            local year = tostring(now:year())
            test.not_nil(result.prompt:find(year))

            local months = {
                "January", "February", "March", "April", "May", "June",
                "July", "August", "September", "October", "November", "December"
            }
            local month_name = months[now:month()]
            test.not_nil(result.prompt:find(month_name))

            local day = tostring(now:day())
            test.not_nil(result.prompt:find(day))

            local hour_str = string.format("%02d", now:hour())
            test.not_nil(result.prompt:find(hour_str))
        end)

        it("should round minutes to interval", function()
            local time = require("time")
            local now = time.now()
            local minute = now:minute()
            local rounded = math.floor(minute / 15) * 15

            local result = init_time_aware.execute("base prompt")

            local rounded_str = string.format("%02d", rounded)
            test.not_nil(result.prompt:find(rounded_str))
        end)

        it("should contain weekday name", function()
            local time = require("time")
            local now = time.now()
            local weekdays = {
                "Sunday", "Monday", "Tuesday", "Wednesday",
                "Thursday", "Friday", "Saturday"
            }
            local weekday_name = weekdays[now:weekday() + 1]

            local result = init_time_aware.execute("base prompt")

            test.not_nil(result.prompt:find(weekday_name))
        end)

        it("should contain timezone in prompt", function()
            local result = init_time_aware.execute("base prompt")

            test.not_nil(result.prompt:find("UTC"))
        end)

        it("should contain temporal context instruction", function()
            local result = init_time_aware.execute("base prompt")

            test.not_nil(result.prompt:find("temporal context"))
        end)
    end)
end

return require("test").run_cases(define_tests)
