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

        it("rejects non-finite numbers and ambiguous or excessively nested stored values", function()
            local deep = {}
            local cursor = deep
            for _ = 1, 33 do
                cursor.child = {}
                cursor = cursor.child
            end
            for _, value in ipairs({
                math.huge, -math.huge, 0 / 0,
                { [1] = "item", key = "mixed object and list" },
                { [3] = "sparse list" }, deep,
            }) do
                local prepared, err = behavior_controls.prepare({ {
                    context = { session = { set = { value = value } } },
                } })
                test.is_nil(prepared)
                test.not_nil(err)
            end
        end)

        it("allows shared acyclic values while preserving explicit false and empty targets", function()
            local shared = { enabled = false, limit = 0, name = "" }
            local prepared, err = behavior_controls.prepare({ {
                config = { traits = {}, tools = {} }, memory = { compact = false },
                context = { session = { set = { first = shared, second = shared } } },
            } })
            test.is_nil(err)
            shared.limit = 99
            local values = prepared[1].context.session.set
            test.eq(values.first.limit, 0)
            test.eq(values.second.limit, 0)
            test.is_false(values.first.enabled)
            test.eq(values.second.name, "")
            test.is_false(prepared[1].memory.compact)
            test.eq(#prepared[1].config.traits, 0)
            test.eq(#prepared[1].config.tools, 0)
        end)

        it("does nothing when no behavior proposes controls", function()
            test.eq(#behavior_controls.prepare(nil), 0)
            test.eq(#behavior_controls.prepare({}), 0)
        end)
    end)
end

return { run_tests = test.run_cases(define_tests) }
