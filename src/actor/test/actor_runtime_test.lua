local test = require("test")
local time = require("time")
local env = require("env")
local benchmark_report = require("benchmark")

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

local function define_tests()
    test.describe("actor runtime", function()
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

local function benchmark(options)
    local count = tonumber(options and options.iterations) or 100
    return with_fixture("dispatch", 0, function(pid, _, responses, outcome)
        assert(receive(responses).phase == "ready")
        local started = time.now()
        for index = 1, count do
            assert(process.send(pid, "dispatch", index))
            local value = receive(responses)
            assert(value.count == index and value.value == index, "actor dispatch mismatch")
        end
        local duration_ms = time.now():sub(started):seconds() * 1000
        assert(process.cancel(pid, "2s"))
        assert(outcome().status == "canceled")
        return { operations = count, duration_ms = duration_ms }
    end)
end

local function benchmark_cases()
    test.describe("actor_roundtrip benchmark", function()
        local samples = tonumber((env.get("WIPPY_BENCH_SAMPLES")))
        if not samples then
            test.it_skip("requires WIPPY_BENCH_SAMPLES", function() end)
            return
        end
        test.it("measures verified runtime roundtrips", function()
            local size = tonumber((env.get("WIPPY_BENCH_SIZE"))) or 1
            local warmup = tonumber((env.get("WIPPY_BENCH_WARMUP"))) or 5
            assert(samples > 0 and size > 0 and warmup >= 0, "invalid benchmark configuration")
            for _ = 1, warmup do benchmark({ iterations = size }) end
            local durations = {}
            for index = 1, samples do
                local result = benchmark({ iterations = size })
                assert(result.operations == size, "benchmark operation count mismatch")
                durations[index] = result.duration_ms
            end
            local report, report_err = benchmark_report.report({
                name = "actor_roundtrip", size = size, operations_per_sample = size, samples_ms = durations,
            })
            test.not_nil(report, tostring(report_err))
        end)
    end)
end

return { run = test.run_cases(define_tests), benchmark = test.run_cases(benchmark_cases), workload = benchmark }
