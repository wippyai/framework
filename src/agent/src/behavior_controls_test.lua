local test = require("test")
local behavior_controls = require("behavior_controls")

local function define_tests()
    describe("behavior controls", function()
        it("prepares detached declarative controls including empty overlays", function()
            local original = {{ config = { traits = {}, tools = { { id = "app:tool", options = { limit = 2 } } } },
                context = { session = { set = { scope = "project" }, delete = { "old" } } },
                memory = { compact = true } }}
            local prepared, err = behavior_controls.prepare(original)
            test.is_nil(err)
            original[1].config.tools[1].options.limit = 100
            test.eq(prepared[1].config.tools[1].options.limit, 2)
            test.eq(#prepared[1].config.traits, 0)
        end)

        it("rejects malformed or unsupported controls before any application", function()
            for _, control in ipairs({
                { yield = {} }, { config = { stop = true } }, { config = { agent = "" } },
                { config = { tools = { [2] = "app:tool" } } }, { config = { traits = { {} } } },
                { context = { session = { delete = "all" } } },
                { context = { session = { set = { [1] = true } } } },
                { context = { public_meta = { set = { entry = "not an object" } } } },
                { memory = { compact = "true" } }, { memory = { add = {} } },
            }) do
                local prepared, err = behavior_controls.prepare({ {}, control })
                test.is_nil(prepared)
                test.not_nil(err)
            end
            local prepared, err = behavior_controls.prepare({ [2] = {} })
            test.is_nil(prepared)
            test.not_nil(err)
        end)

        it("rejects non-persistent context values", function()
            local cycle = {}
            cycle.self = cycle
            for _, value in ipairs({ cycle, function() end }) do
                local prepared, err = behavior_controls.prepare({ { context = { session = { set = { bad = value } } } } })
                test.is_nil(prepared)
                test.not_nil(err)
            end
        end)

        it("does nothing when no behavior proposes controls", function()
            test.eq(#behavior_controls.prepare(nil), 0)
            test.eq(#behavior_controls.prepare({}), 0)
        end)
    end)
end

return { run_tests = test.run_cases(define_tests) }
