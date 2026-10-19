local test = require("test")
local tool_caller = require("tool_caller")
local time = require("time")

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
        it("retains a completed peer after cancelling a waiting parallel call", function()
            local caller = tool_caller.new():set_strategy(tool_caller.STRATEGY.PARALLEL)
            local cancel = channel.new()
            local executor = {}
            executor.with_context = function(self) return self end
            executor.async = function(_, id)
                local completed = id == "app:done"
                local response = channel.new(1)
                if completed then response:send(true); cancel:close() end
                return {
                    response = function() return response end,
                    cancel = function() return not completed end,
                    is_canceled = function() return not completed end,
                    result = function()
                        if completed then return { data = function() return "committed result" end } end
                        return nil, "cancelled"
                    end,
                }
            end
            caller.executor = executor
            caller.authority, caller.authority_error = nil, nil
            local results = caller:execute({}, {
                { call_id = "held", name = "held", registry_id = "app:held", args = {}, meta = {}, valid = true },
                { call_id = "done", name = "done", registry_id = "app:done", args = {}, meta = {}, valid = true },
            }, cancel)
            test.is_true(results[1].cancelled)
            test.eq(results[2].result, "committed result", "finished effects need their real outcome")
            test.is_nil(results[2].cancelled)
        end)
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

            it(strategy .. " cancels in-flight calls when the cancel channel closes", function()
                local caller = tool_caller.new():set_strategy(strategy)
                caller:set_wrapper_context({host = {kind = "session", session_id = "runtime"}})
                local validated, err = caller:validate({
                    call("held-a", {message = "a", hold_ms = 30000}),
                    call("held-b", {message = "b", hold_ms = 30000}),
                })
                test.is_nil(err)
                local cancel = channel.new()
                local done = channel.new(1)
                coroutine.spawn(function() done:send(caller:execute({}, validated, cancel)) end)
                time.sleep("50ms")

                local started = time.now()
                cancel:close()
                local timer = time.timer("2s")
                local selected = channel.select({done:case_receive(), timer:channel():case_receive()})
                timer:stop()
                test.eq(selected.channel, done, "Cancelled tool calls must return promptly")
                test.is_true(time.now():sub(started):seconds() < 2)
                local results = selected.value
                test.eq(count(results), 2)
                for _, id in ipairs({"held-a", "held-b"}) do
                    test.is_true(results[id].cancelled)
                    test.is_nil(results[id].result)
                    test.eq(results[id].error, "Tool call was cancelled")
                    test.eq(results[id].tool_call.call_id, id)
                end
            end)

            it("" .. strategy .. " does not start tools when cancellation is already signaled", function()
                local caller = tool_caller.new():set_strategy(strategy)
                local starts = 0
                local executor = {}
                executor.with_context = function(self) return self end
                executor.async = function()
                    starts = starts + 1
                    local response = channel.new(1)
                    return {
                        response = function() return response end,
                        cancel = function() return true end,
                        is_canceled = function() return true end,
                        result = function() return nil, "cancelled" end,
                    }
                end
                caller.executor = executor
                caller.authority, caller.authority_error = nil, nil
                local cancel = channel.new()
                cancel:close()
                local results = caller:execute({}, {
                    a = { call_id = "a", name = "a", registry_id = "app:a", args = {}, meta = {}, valid = true },
                    b = { call_id = "b", name = "b", registry_id = "app:b", args = {}, meta = {}, valid = true },
                }, cancel)
                test.is_true(results.a.cancelled)
                test.is_true(results.b.cancelled)
                test.eq(starts, 0, "a pre-cancelled batch must not launch a side-effecting call")
            end)

            it(strategy .. " completes calls normally when the cancel channel stays open", function()
                local caller = tool_caller.new():set_strategy(strategy)
                caller:set_wrapper_context({host = {kind = "session", session_id = "runtime"}})
                local validated, err = caller:validate({call("open-id", {message = "kept"})})
                test.is_nil(err)

                local results = caller:execute({scope = "session"}, validated, channel.new())

                test.is_nil(results["open-id"].error)
                test.is_nil(results["open-id"].cancelled)
                test.eq(results["open-id"].result.message, "kept")
                test.eq(results["open-id"].result.scope, "session")
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
