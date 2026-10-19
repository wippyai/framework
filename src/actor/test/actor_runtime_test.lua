local test = require("test")
local time = require("time")
local actor = require("actor")
local system = require("system")

local sequence = 0

local function receive(ch)
    local timer = time.timer(3 * time.SECOND)
    local result = channel.select({ ch:case_receive(), timer:channel():case_receive() })
    timer:stop()
    assert(result.channel == ch and result.ok, "actor runtime response deadline")
    return result.value
end

local function with_fixture(scenario, count, body): any
    sequence = sequence + 1
    local topic = "actor.runtime." .. sequence
    local responses = process.listen(topic)
    local events = process.events()
    local pid, err = process.spawn_monitored("app:actor_runtime_fixture", "app:runtime_processes", {
        parent = process.pid(), topic = topic, scenario = scenario, count = count,
    })
    assert(pid, tostring(err))
    local exited = false
    local function outcome(check_result)
        local timer = time.timer(3 * time.SECOND)
        while true do
            local selected = channel.select({ events:case_receive(), timer:channel():case_receive() })
            if selected.channel == timer:channel() then
                timer:stop()
                error("actor runtime exit deadline")
            end
            local event = selected.value
            if event.from == pid and event.kind == process.event.EXIT then
                exited = true
                timer:stop()
                if check_result ~= false then
                    assert(not event.result.error, tostring(event.result.error))
                end
                return event.result.value
            end
        end
    end
    local ok: boolean, result: any = pcall(body, pid, topic, responses, outcome)
    if not ok and not exited then
        process.terminate(pid)
        local cleaned, cleanup_err = pcall(outcome, false)
        if not cleaned then result = tostring(result) .. "; cleanup: " .. tostring(cleanup_err) end
    end
    process.unmonitor(pid)
    process.unlisten(responses)
    if not ok then error(result) end
    return result
end

local function wait_idle(pid)
    local deadline = time.timer(3 * time.SECOND)
    local cases = { deadline:channel():case_receive() }
    while true do
        local processes = assert(system.hosts.processes("app:runtime_processes"))
        for _, child in ipairs(processes) do
            if child.pid == pid and child.state == "idle" then
                deadline:stop()
                return
            end
        end
        if channel.select(cases, true).channel == deadline:channel() then
            deadline:stop()
            error("actor idle state deadline")
        end
        coroutine.yield()
    end
end

local function define_tests()
    test.describe("actor runtime", function()
        test.it("initializes and completes repeated actors with the real process interface", function()
            for index = 1, 8 do
                local result = actor.new({ index = index }, {
                    __init = function(state) return actor.exit(state.index) end,
                }).run()
                test.eq(result, index)
            end
        end)
        local next_sources = { init_next = "init", async_next = "async",
            channel_next = "channel_handler", event_next = "event_handler" }
        for _, scenario in ipairs({ "init_next", "async_next", "channel_next", "event_next" }) do
            test.it("delivers internal next messages from " .. scenario, function()
                with_fixture(scenario, 1, function(pid, _, responses, outcome)
                    if scenario == "event_next" then
                        test.eq(receive(responses).phase, "ready")
                        assert(process.cancel(pid, "2s"))
                    end
                    local result = outcome()
                    test.eq(result.status, "next")
                    test.eq(result.payload.scenario, scenario)
                    test.eq(result.topic, "next_result")
                    test.eq(result.from, next_sources[scenario])
                end)
            end)
        end
        test.it("wakes an idle actor when an external coroutine invokes state.async", function()
            with_fixture("deferred_async", 1, function(pid, topic, responses, outcome)
                test.eq(receive(responses).phase, "ready")
                wait_idle(pid)
                assert(process.send(pid, topic .. ".proceed", true))
                local result = outcome()
                test.eq(result.status, "next")
                test.eq(result.payload.scenario, "deferred_async")
                test.eq(result.from, "async")
            end)
        end)
        test.it("receives a real topic reply before the wait deadline", function()
            with_fixture("reply", 1, function(pid, topic, responses, outcome)
                test.eq(receive(responses).phase, "waiting")
                assert(process.send(pid, topic .. ".reply", { value = 42 }))
                local result = outcome()
                test.eq(result.status, "replied")
                test.eq(result.value.value, 42)
                test.eq(result.count, 1)
            end)
        end)
        test.it("returns timeout when the real deadline expires", function()
            with_fixture("deadline", 1, function(_, _, responses, outcome)
                local expired = receive(responses)
                test.eq(expired.phase, "expired")
                test.is_nil(expired.value)
                test.eq(expired.error, "timeout")
                test.eq(outcome().status, "deadline")
            end)
        end)
        test.it("preserves a late reply for the next wait on the same topic", function()
            with_fixture("late", 1, function(pid, topic, responses, outcome)
                test.eq(receive(responses).error, "timeout")
                assert(process.send(pid, topic .. ".reply", { late = true }))
                assert(process.send(pid, topic .. ".proceed", true))
                local result = outcome()
                test.eq(result.status, "late")
                test.eq(result.value.late, true)
                test.is_nil(result.error)
            end)
        end)
        test.it("reuses a topic listener across repeated waits without replaying replies", function()
            with_fixture("reply", 3, function(pid, topic, responses, outcome)
                for index = 1, 3 do
                    test.eq(receive(responses).index, index)
                    assert(process.send(pid, topic .. ".reply", { index = index }))
                end
                local result = outcome()
                test.eq(result.count, 3)
                test.eq(result.value.index, 3)
            end)
        end)
        test.it("handles cancellation after a bounded outstanding wait", function()
            with_fixture("cancel", 1, function(pid, _, responses, outcome)
                test.eq(receive(responses).phase, "waiting")
                assert(process.cancel(pid, "2s"))
                test.eq(outcome().status, "canceled")
            end)
        end)
        test.it("selects a channel registered after a handler catches an error", function()
            with_fixture("dispatch", 0, function(pid, _, responses, outcome)
                test.eq(receive(responses).phase, "ready")
                assert(process.send(pid, "register_after_error", true))
                local result = outcome()
                test.eq(result.status, "channel_after_error")
                test.eq(result.value, "after caught error")
                test.is_true(result.ok)
            end)
        end)
        test.it("drains buffered channel values including false before one closure exit", function()
            with_fixture("drain_exit", 0, function(_, _, _, outcome)
                local result = outcome()
                test.eq(result.status, "drained")
                test.eq(result.closures, 1)
                test.eq(#result.values, 3)
                test.eq(result.values[1], 1)
                test.eq(result.values[2], false)
                test.eq(result.values[3], "x")
            end)
        end)
        test.it("delivers an internal next returned by a closed channel callback", function()
            with_fixture("drain_next", 0, function(_, _, _, outcome)
                local result = outcome()
                test.eq(result.status, "next")
                test.eq(result.topic, "next_result")
                test.eq(result.from, "channel_handler")
                test.eq(result.payload.closures, 1)
                test.eq(#result.payload.values, 3)
                test.eq(result.payload.values[2], false)
            end)
        end)
        test.it("unregisters a closed channel and continues handling inbox messages", function()
            with_fixture("closure", 1, function(pid, _, responses, outcome)
                local closed = receive(responses)
                test.eq(closed.phase, "closed")
                test.eq(closed.ok, false)
                assert(process.send(pid, "ping", { value = "after closure" }))
                local result = outcome()
                test.eq(result.status, "inbox")
                test.eq(result.closures, 1)
                test.eq(result.removed, true)
                test.eq(result.payload.value, "after closure")
                test.eq(result.topic, "ping")
                test.eq(result.from, (process.pid()))
            end)
        end)
    end)
end

return { run = test.run_cases(define_tests) }
