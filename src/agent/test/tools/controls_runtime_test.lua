local test = require("test")
local tool_caller = require("tool_caller")

local function call(id, args)
    return {id = id, name = "runtime_control", registry_id = "app:control_fixture",
        arguments = args, context = {scope = "tool"}}
end

local function count(value)
    local total = 0
    for _ in pairs(value) do total = total + 1 end
    return total
end

local function wrapper(source, phases, options)
    return {id = "runtime-wrapper", binding = "app:control_wrapper_binding", source = source,
        phases = phases, options = options or {}, strict = true}
end

local function define_tests()
    describe("registered tool runtime controls", function()
        for _, strategy in ipairs({tool_caller.STRATEGY.SEQUENTIAL, tool_caller.STRATEGY.PARALLEL}) do
            it(strategy .. " preserves IDs, controls and successful peers across mixed failures", function()
                local caller = tool_caller.new():set_strategy(strategy)
                caller:set_wrapper_context({host = {kind = "session", session_id = "runtime"}})
                caller:set_tool_wrappers({wrapper(nil, {"after_execute"})})
                local validated, err = caller:validate({
                    call("success-id", {message = "success", control = {config = {model = "next-model"},
                        context = {session = {set = {scope = "next"}}}, memory = {compact = true}}}),
                    call("data-error-id", {fail = true, message = "failure", control = {memory = {compact = false}}}),
                    call("execution-error-id", {raise = true}),
                    call("json-error-id", "{invalid json"),
                    {id = "missing-id", name = "missing", registry_id = "app:missing", arguments = {}},
                })
                test.is_nil(err)
                local results = caller:execute({scope = "session"}, validated)
                test.eq(count(results), 5)
                test.is_nil(results["success-id"].error)
                local success = results["success-id"].result
                test.eq(success.call_id, "success-id")
                test.eq(success.scope, "session")
                test.eq(success.message, "success")
                test.eq(success._control.config.model, "next-model")
                test.eq(success._control.context.session.set.scope, "next")
                test.is_true(success._control.memory.compact)
                test.eq(results["data-error-id"].error, "explicit runtime fixture failure")
                test.is_false(results["data-error-id"].result._control.memory.compact)
                test.eq(results["data-error-id"].result.call_id, "data-error-id")
                test.not_nil(results["execution-error-id"].error)
                test.is_nil(results["execution-error-id"].result)
                test.contains(tostring(results["json-error-id"].error), "Failed to parse arguments")
                test.not_nil(results["missing-id"].error)
                for id, result in pairs(results) do test.eq(result.tool_call.call_id, id) end
                test.eq(caller:get_wrapper_observations()[1].content.reason, "tool_execution_failed")
            end)

            it(strategy .. " collects detached behavior proposals and resets each execution", function()
                local caller = tool_caller.new():set_strategy(strategy)
                caller:set_wrapper_context({host = {kind = "session", session_id = "runtime"}})
                caller:set_tool_wrappers({wrapper("behavior", {"before_execute", "after_execute"})})
                local validated, err = caller:validate({call("behavior-id", {message = "first",
                    wrapper_control = {config = {model = "stronger"}, memory = {compact = false}}})})
                test.is_nil(err)
                local results = caller:execute({}, validated)
                test.eq(results["behavior-id"].result.message, "wrapped first")
                test.eq(results["behavior-id"].result.call_id, "behavior-id")
                test.eq(#caller:get_wrapper_controls(), 1)
                local controls = caller:get_wrapper_controls()
                test.eq(controls[1].config.model, "stronger")
                test.is_false(controls[1].memory.compact)
                controls[1].config.model = "mutated"
                test.eq(caller:get_wrapper_controls()[1].config.model, "stronger")
                results["behavior-id"].result.wrapper_control.config.model = "changed-result"
                test.eq(caller:get_wrapper_controls()[1].config.model, "stronger")
                caller:set_tool_wrappers({})
                caller:execute({}, validated)
                test.eq(#caller:get_wrapper_controls(), 0)
                caller:set_tool_wrappers({wrapper("behavior", {"after_execute"})})
                validated, err = caller:validate({call("second-id", {message = "second"})})
                test.is_nil(err)
                results = caller:execute({}, validated)
                test.eq(results["second-id"].result.message, "second")
                test.eq(#caller:get_wrapper_controls(), 0)
                test.eq(#caller:get_wrapper_errors(), 0)
            end)

            it(strategy .. " keeps different nested controls paired with two successful calls", function()
                local caller = tool_caller.new():set_strategy(strategy)
                caller:set_wrapper_context({host = {kind = "session", session_id = "runtime"}})
                local validated, err = caller:validate({
                    call("left-id", {message = "left", control = {config = {model = "left-model"},
                        context = {session = {set = {side = "left", nested = {depth = {value = 1}}}}}}}),
                    call("right-id", {message = "right", control = {config = {model = "right-model"},
                        context = {session = {set = {side = "right", nested = {depth = {value = 2}}}}}}}),
                })
                test.is_nil(err)
                local results = caller:execute({}, validated)
                test.eq(count(results), 2)
                for id, side in pairs({["left-id"] = "left", ["right-id"] = "right"}) do
                    local entry = results[id]
                    test.is_nil(entry.error)
                    test.eq(entry.tool_call.call_id, id)
                    test.eq(entry.result.call_id, id)
                    test.eq(entry.result.message, side)
                    test.eq(entry.result._control.config.model, side .. "-model")
                    test.eq(entry.result._control.context.session.set.side, side)
                end
                test.eq(results["left-id"].result._control.context.session.set.nested.depth.value, 1)
                test.eq(results["right-id"].result._control.context.session.set.nested.depth.value, 2)
                test.is_false(results["left-id"].result._control == results["right-id"].result._control)
            end)

            it(strategy .. " clears the previous round when a later round has no tool calls", function()
                local caller = tool_caller.new():set_strategy(strategy)
                caller:set_wrapper_context({host = {kind = "session", session_id = "runtime"}})
                caller:set_tool_wrappers({wrapper("behavior", {"after_execute"})})
                local validated, err = caller:validate({call("first-id", {message = "first",
                    wrapper_control = {memory = {compact = true}}})})
                test.is_nil(err)
                caller:execute({}, validated)
                test.eq(#caller:get_wrapper_controls(), 1)
                test.eq(caller:get_wrapper_metadata()[1].metadata.call_ids[1], "first-id")

                validated, err = caller:validate({})
                test.is_nil(err)
                test.eq(#caller:get_last_tool_calls(), 0)
                test.eq(#caller:get_wrapper_observations(), 0)
                test.eq(#caller:get_wrapper_metadata(), 0)
                test.eq(#caller:get_wrapper_errors(), 0)
                test.eq(#caller:get_wrapper_controls(), 0)

                local results = caller:execute({}, validated)
                test.eq(count(results), 0)
                local metadata = caller:get_wrapper_metadata()
                test.eq(#metadata, 1)
                test.eq(#metadata[1].metadata.call_ids, 0)
                test.eq(#caller:get_wrapper_controls(), 0)
            end)

            it(strategy .. " keeps legacy wrappers from proposing behavior controls", function()
                local caller = tool_caller.new():set_strategy(strategy)
                caller:set_wrapper_context({host = {kind = "session", session_id = "runtime"}})
                caller:set_tool_wrappers({wrapper(nil, {"after_execute"})})
                local validated, err = caller:validate({call("legacy-id", {wrapper_control = {memory = {compact = true}}})})
                test.is_nil(err)
                local results = caller:execute({}, validated)
                test.is_nil(results["legacy-id"].error)
                test.eq(#caller:get_wrapper_controls(), 0)
                test.eq(#caller:get_wrapper_observations(), 1)
            end)

            it(strategy .. " rejects invalid behavior proposals without losing tool results", function()
                local caller = tool_caller.new():set_strategy(strategy)
                caller:set_wrapper_context({host = {kind = "session", session_id = "runtime"}})
                caller:set_tool_wrappers({wrapper("behavior", {"after_execute"})})
                local validated, err = caller:validate({call("invalid-id", {message = "completed", wrapper_control = {yield = {}}})})
                test.is_nil(err)
                local results = caller:execute({}, validated)
                test.eq(results["invalid-id"].result.message, "completed")
                test.eq(#caller:get_wrapper_controls(), 0)
                test.eq(#caller:get_wrapper_errors(), 1)
            end)
        end

        it("rejects a registered wrapper that drops provider call identities", function()
            local caller = tool_caller.new()
            caller:set_wrapper_context({host = {kind = "session", session_id = "runtime"}})
            caller:set_tool_wrappers({wrapper("behavior", {"before_execute"}, {mode = "drop"})})
            local validated, err = caller:validate({call("must-survive", {message = "first"})})
            test.is_nil(validated)
            test.contains(err, "preserve every tool call ID")
        end)
    end)
end

return {run_tests = test.run_cases(define_tests)}
