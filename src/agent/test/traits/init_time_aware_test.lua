local init_time_aware = require("init_time_aware")
local funcs = require("funcs")

local function define_tests()
    describe("Init Time Aware Trait", function()
        it("contributes turn context options and no prompt text", function()
            local result: any = init_time_aware.execute("base prompt")

            test.not_nil(result)
            test.is_nil(result.prompt)
            test.eq(result.agent_options.turn_context.time.timezone, "UTC")
            test.is_nil(result.agent_options.turn_context.time.format)
        end)

        it("carries the configured timezone and format", function()
            local result, err = funcs.new()
                :with_context({ timezone = "Europe/Berlin", time_format = "2006-01-02 15:04" })
                :call("wippy.agent.traits:init_time_aware", "base prompt")

            test.is_nil(err)
            test.is_nil(result.prompt)
            test.eq(result.agent_options.turn_context.time.timezone, "Europe/Berlin")
            test.eq(result.agent_options.turn_context.time.format, "2006-01-02 15:04")
        end)

        it("ignores a format key that the agent context uses for another purpose", function()
            local result, err = funcs.new()
                :with_context({ timezone = "UTC", format = "json" })
                :call("wippy.agent.traits:init_time_aware", "base prompt")

            test.is_nil(err)
            test.is_nil(result.agent_options.turn_context.time.format)
        end)

        it("rejects the removed time_interval setting and names its replacement", function()
            local result, err = funcs.new()
                :with_context({ timezone = "UTC", time_interval = 15 })
                :call("wippy.agent.traits:init_time_aware", "base prompt")

            test.is_nil(result)
            test.contains(tostring(err), "time_interval")
            test.contains(tostring(err), "turn_context")
        end)
    end)
end

return require("test").run_cases(define_tests)
