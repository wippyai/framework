local init_time_aware = require("init_time_aware")
local funcs = require("funcs")
local compiler = require("compiler")

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

        it("rejects a time_format that is not a non-empty string", function()
            for _, layout in ipairs({ 42, true, "" }) do
                local result, err = funcs.new()
                    :with_context({ timezone = "UTC", time_format = layout })
                    :call("wippy.agent.traits:init_time_aware", "base prompt")

                test.is_nil(result)
                test.contains(tostring(err), "time_format")
            end
        end)

        it("ignores the legacy time_interval setting", function()
            local result, err = funcs.new()
                :with_context({ timezone = "Europe/Berlin", time_format = "2006-01-02 15:04", time_interval = 15 })
                :call("wippy.agent.traits:init_time_aware", "base prompt")

            test.is_nil(err, "legacy time_interval is ignored")
            test.not_nil(result)
            test.is_nil(result.prompt)
            test.eq(result.agent_options.turn_context.time.timezone, "Europe/Berlin")
            test.eq(result.agent_options.turn_context.time.format, "2006-01-02 15:04")
        end)

        it("compiles a time-aware agent with legacy time_interval context", function()
            local result, err = compiler.compile({
                id = "test:legacy_time_aware",
                model = "test-model",
                prompt = "Base prompt",
                context = { timezone = "Europe/Berlin", time_interval = 15 },
                traits = { "wippy.agent.traits:time_aware" },
            })

            test.is_nil(err, "legacy time_interval does not fail compilation")
            test.not_nil(result)
            test.eq(result.prompt, "Base prompt")
            test.eq(result.agent_options.turn_context.time.timezone, "Europe/Berlin")
            test.is_nil(result.agent_options.turn_context.time.format)
        end)
    end)
end

return require("test").run_cases(define_tests)
