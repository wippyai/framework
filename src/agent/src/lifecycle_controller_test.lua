local function define_tests()
    describe("Agent lifecycle controller", function()
        local controller
        local state
        local calls
        local failures

        before_each(function()
            controller = require("lifecycle_controller")
            state = {}
            calls = {}
            failures = {}
        end)

        local function agent(id, model, instance, variant)
            return { id = id, model = model, agent = instance, variant = variant }
        end

        local function options()
            return {
                payload = function(phase, descriptor)
                    return {
                        reason = phase == "activate" and "agent_loaded" or "agent_switch",
                        agent_id = descriptor.id,
                        model = descriptor.model,
                    }
                end,
                dispatch = function(instance, phase, payload)
                    calls[#calls + 1] = { instance = instance, phase = phase, payload = payload }
                    if failures[phase] then
                        return { applied = 0 }, failures[phase]
                    end
                    return { applied = 1, messages = { payload.reason } }, nil
                end,
            }
        end

        it("activates, refreshes the same identity, and deactivates", function()
            local result, err = controller.activate(state, agent("a", "m", "first"), options())
            test.is_nil(err)
            test.is_true(result.activated)
            test.eq(state.active_agent, "first")

            result, err = controller.activate(state, agent("a", "m", "refreshed"), options())
            test.is_nil(err)
            test.is_true(result.refreshed)
            test.eq(state.active_agent, "refreshed")
            test.eq(#calls, 1)

            result, err = controller.deactivate(state, options())
            test.is_nil(err)
            test.is_true(result.deactivated)
            test.eq(calls[2].instance, "refreshed")
            test.eq(state.active_agent, nil)
        end)

        it("deactivates the old agent before activating the new one with separate payloads", function()
            controller.activate(state, agent("a", "m1", "old"), options())
            local result, err = controller.activate(state, agent("b", "m2", "new"), options())

            test.is_nil(err)
            test.is_true(result.deactivated)
            test.is_true(result.activated)
            test.eq(result.activation.messages[1], "agent_loaded")
            test.eq(calls[2].instance, "old")
            test.eq(calls[2].phase, "deactivate")
            test.eq(calls[2].payload.reason, "agent_switch")
            test.eq(calls[3].instance, "new")
            test.eq(calls[3].payload.reason, "agent_loaded")
        end)

        it("keeps the prior state when deactivation fails", function()
            controller.activate(state, agent("a", "m", "old"), options())
            failures.deactivate = "cannot leave"
            local result, err = controller.activate(state, agent("b", "m", "new"), options())

            test.eq(err, "cannot leave")
            test.is_false(result.activated)
            test.eq(state.active_agent_id, "a")
            test.eq(state.active_agent, "old")
            test.eq(#calls, 2)
        end)

        it("leaves state inactive when new activation fails after a switch", function()
            controller.activate(state, agent("a", "m", "old"), options())
            failures.activate = "cannot enter"
            local result, err = controller.activate(state, agent("b", "m", "new"), options())

            test.eq(err, "cannot enter")
            test.is_true(result.deactivated)
            test.is_false(result.activated)
            test.eq(state.active_agent, nil)
            test.eq(state.active_agent_id, nil)
        end)

        it("keeps state on failed explicit deactivation and accepts a fallback", function()
            controller.activate(state, agent("a", "m", "old"), options())
            failures.deactivate = "retry later"
            local result, err = controller.deactivate(state, options())
            test.eq(err, "retry later")
            test.is_false(result.deactivated)
            test.eq(state.active_agent, "old")

            failures.deactivate = nil
            state = { active_agent_id = "fallback", active_model = "m" }
            local opts = options()
            opts.fallback = agent("fallback", "m", "fallback object")
            result, err = controller.deactivate(state, opts)
            test.is_nil(err)
            test.is_true(result.deactivated)
            test.eq(calls[#calls].instance, "fallback object")

            result, err = controller.deactivate(state, opts)
            test.is_nil(err)
            test.is_false(result.deactivated)
            test.eq(#calls, 3)
        end)

        it("uses fallback to switch an active agent whose object was lost", function()
            state.active_agent_id = "a"
            state.active_model = "m"
            local opts = options()
            opts.fallback = agent("a", "m", "recovered old")

            local result, err = controller.activate(state, agent("b", "m", "new"), opts)
            test.is_nil(err)
            test.is_true(result.deactivated)
            test.is_true(result.activated)
            test.eq(calls[1].instance, "recovered old")
            test.eq(calls[2].instance, "new")
        end)

        it("transitions only when an optional overlay variant changes by value", function()
            local overlay = { { id = "memory", options = { limit = 2 } } }
            controller.activate(state, agent("a", "m", "first", overlay), options())
            local result, err = controller.activate(state, agent("a", "m", "second", {
                { id = "memory", options = { limit = 2 } }
            }), options())
            test.is_nil(err)
            test.is_true(result.refreshed)
            test.eq(#calls, 1)

            overlay[1].options.limit = 3
            result, err = controller.activate(state, agent("a", "m", "third", overlay), options())
            test.is_nil(err)
            test.is_true(result.deactivated)
            test.is_true(result.activated)
            test.eq(calls[2].instance, "second")
            test.eq(calls[3].instance, "third")
            test.eq(state.active_variant[1].options.limit, 3)
        end)

        it("reports missing state, target, and callbacks", function()
            local result, err = controller.activate(nil, agent("a", "m", "x"), options())
            test.eq(err, "lifecycle state must be a table")
            result, err = controller.activate(state, nil, options())
            test.eq(err, "lifecycle target agent is required")
            result, err = controller.deactivate(state, {})
            test.eq(err, "lifecycle dispatch function is required")
        end)
    end)
end

return {
    run_tests = function()
        return require("test").run_cases(define_tests)
    end
}
