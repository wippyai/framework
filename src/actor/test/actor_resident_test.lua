local test = require("test")
local time = require("time")

local sequence = 0

local function with_residents(count: number, body: any): any
    sequence = sequence + 1
    local topic = "actor.resident." .. sequence
    local responses = process.listen(topic)
    local events = process.events()
    local active = {}
    local pids = {}
    local batch = 0
    local pending_deadline
    local function dispatch()
        batch = batch + 1
        for index, pid in ipairs(pids) do
            assert(process.send(pid, "dispatch", { index = index, batch = batch }))
        end
        local seen = {}
        local deadline = time.timer(10 * time.SECOND)
        pending_deadline = deadline
        for _ = 1, count do
            local selected = channel.select({ responses:case_receive(), deadline:channel():case_receive() })
            assert(selected.channel == responses and selected.ok, "resident actor response deadline")
            local value = selected.value
            assert(active[value.pid] and not seen[value.pid], "resident actor response identity mismatch")
            assert(pids[value.value.index] == value.pid and value.value.batch == batch and value.count == batch,
                "resident actor dispatch mismatch")
            seen[value.pid] = true
        end
        deadline:stop()
        pending_deadline = nil
    end
    local ok: boolean, result: any = pcall(function()
        for index = 1, count do
            local pid, err = process.spawn_monitored("app:actor_resident_fixture", "app:runtime_processes", {
                parent = process.pid(), topic = topic,
            })
            assert(pid, tostring(err))
            active[pid] = true
            pids[index] = pid
        end
        local ready = {}
        local deadline = time.timer(10 * time.SECOND)
        pending_deadline = deadline
        for _ = 1, count do
            local selected = channel.select({ responses:case_receive(), deadline:channel():case_receive() })
            assert(selected.channel == responses and selected.ok, "resident actor startup deadline")
            local value = selected.value
            assert(value.phase == "ready" and active[value.pid] and not ready[value.pid],
                "resident actor startup identity mismatch")
            ready[value.pid] = true
        end
        deadline:stop()
        pending_deadline = nil
        return body(dispatch)
    end)
    if pending_deadline then pending_deadline:stop() end
    for pid in pairs(active) do process.cancel(pid, "2s") end
    local deadline = time.timer(10 * time.SECOND)
    while next(active) do
        local selected = channel.select({ events:case_receive(), deadline:channel():case_receive() })
        if selected.channel ~= events then break end
        local event = selected.value
        if active[event.from] and event.kind == process.event.EXIT then
            active[event.from] = nil
            process.unmonitor(event.from)
            if event.result.error then ok, result = false, tostring(event.result.error) end
        end
    end
    deadline:stop()
    local cleanup_expired = next(active) ~= nil
    if cleanup_expired then
        for pid in pairs(active) do process.terminate(pid) end
        local forced = time.timer(3 * time.SECOND)
        while next(active) do
            local selected = channel.select({ events:case_receive(), forced:channel():case_receive() })
            if selected.channel ~= events then break end
            local event = selected.value
            if active[event.from] and event.kind == process.event.EXIT then
                active[event.from] = nil
                process.unmonitor(event.from)
            end
        end
        forced:stop()
    end
    process.unlisten(responses)
    assert(not next(active), tostring(result or "") .. "; resident actor termination deadline")
    if not ok then error(result) end
    assert(not cleanup_expired, "resident actor cleanup deadline")
    return result
end

local function define_tests()
    test.describe("resident actor runtime", function()
        test.it("starts, dispatches to, and cancels a real actor cohort", function()
            with_residents(4, function(dispatch)
                dispatch()
                dispatch()
            end)
        end)
    end)
end

return { run = test.run_cases(define_tests) }
