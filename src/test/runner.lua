-- Test runner with real-time per-case TUI display
local io = require("io")
local registry = require("registry")
local time = require("time")
local channel = require("channel")
local discovery = require("discovery")
local display = require("display")
local verdict = require("verdict")

type CaseStats = {
    passed: number,
    failed: number,
    skipped: number,
}

type Failure = {
    suite: string,
    test: string,
    error: string,
}

type SuiteGroup = {
    name: string,
    tests: {any},
}

-- Wait for a value on a channel with timeout
local function wait_for(ch: any, timeout: any): any
    local result = channel.select {
        ch:case_receive(),
        time.after(timeout):case_receive(),
    }
    if result.channel == ch then
        return result.value
    end
    return nil
end

-- Record a failure into both per-test and global failure lists
local function record_failure(
    all_failures: {Failure},
    case_stats: {[string]: CaseStats},
    ref_id: string,
    suite: string,
    test_name: string,
    error_msg: string
)
    local failure: Failure = { suite = suite, test = test_name, error = error_msg }
    table.insert(all_failures, failure)

    local cs = case_stats[ref_id]
    if not cs then
        cs = { passed = 0, failed = 0, skipped = 0 }
        case_stats[ref_id] = cs
    end
    cs.failed = cs.failed + 1
end

-- Main test runner logic
local function run_tests(): number
    local args: {string}? = io.args()

    display.begin()

    -- Discover test functions from registry
    local raw_entries, err = registry.find({["meta.type"] = "test"})
    if err then
        display.error("Error: " .. tostring(err))
        return 1
    end

    if not raw_entries or #raw_entries == 0 then
        display.info("No tests found")
        return 0
    end

    local entries: {discovery.TestEntry} = raw_entries

    -- Apply CLI filter patterns
    if args and #args > 0 then
        entries = discovery.filter_tests(entries, args)
        if #entries == 0 then
            display.info("No tests match filter: " .. table.concat(args, ", "))
            return 0
        end
        display.info("Filter: " .. table.concat(args, ", "))
    end

    -- Group and sort tests by suite
    local suites, no_suite = discovery.group_by_suite(entries)
    local suite_names = discovery.sorted_keys(suites :: {[string]: any})

    local total_tests: number = #entries
    local total_suites: number = #suite_names + (#no_suite > 0 and 1 or 0)

    display.info(total_tests .. " tests in " .. total_suites .. " suites")
    display.info("")

    -- Subscribe to test case events before launching tests
    local inbox = process.listen("test:update", { message = true })
    local control_inbox = process.listen("runner:control", { message = true })

    -- Coordination channels
    local done_ch = channel.new()
    local processor_done = channel.new(1)

    -- Shared state between message processor and main loop
    local case_stats: {[string]: CaseStats} = {}
    local all_failures: {Failure} = {}
    local declared_cases: {[string]: number} = {}
    local entry_status: {[string]: string} = {}
    local completion_channels: {[string]: any} = {}
    local control_channels: {[string]: any} = {}
    local current_running_entry_id: string? = nil

    -- Background message processor: renders case events as they arrive
    coroutine.spawn(function()
        while true do
            local result = channel.select {
                inbox:case_receive(),
                control_inbox:case_receive(),
                done_ch:case_receive(),
            }

            if not result.ok then
                break
            end

            local raw = result.value
            if result.channel == control_inbox then
                local payload = raw and raw:payload()
                local data = payload and payload:data()
                local ch = type(data) == "table" and control_channels[tostring(data.ref_id or "")] or nil
                if ch then ch:send(raw) end
            else
                local event_data: any = nil

                if raw then
                    local pl = raw:payload()
                    if pl then
                        event_data = pl:data()
                    end
                end

                local msg = (type(event_data) == "table" and event_data or {}) :: any
                local msg_type = tostring(msg.type or "")
                local data: any = msg.data or {}
                local ref_id = tostring(data.ref_id or "")

                -- Attribute events by entry identity; ignore late events from completed/timed-out entries
                local status = entry_status[ref_id]
                if verdict.is_event_applicable(ref_id, current_running_entry_id, status) then
                    if not case_stats[ref_id] then
                        case_stats[ref_id] = { passed = 0, failed = 0, skipped = 0 }
                    end

                    if msg_type == "test:plan" then
                        local count = 0
                        for _, planned_suite in ipairs(data.suites or {}) do
                            count = count + #(planned_suite.tests or {})
                        end
                        declared_cases[ref_id] = count

                    elseif msg_type == "test:case:pass" then
                        local cs = case_stats[ref_id]
                        if cs then cs.passed = cs.passed + 1 end
                        display.case_pass(tostring(data.suite or ""), tostring(data.test or ""), tonumber(data.duration) or 0)

                    elseif msg_type == "test:case:fail" then
                        record_failure(all_failures, case_stats, ref_id, tostring(data.suite or ""), tostring(data.test or ""), tostring(data.error or "unknown error"))
                        display.case_fail(tostring(data.suite or ""), tostring(data.test or ""), tostring(data.error or ""), tonumber(data.duration) or 0)

                    elseif msg_type == "test:case:skip" then
                        local cs = case_stats[ref_id]
                        if cs then cs.skipped = cs.skipped + 1 end
                        display.case_skip(tostring(data.suite or ""), tostring(data.test or ""))

                    elseif msg_type == "test:complete" then
                        local ch = completion_channels[ref_id]
                        if ch then ch:send(msg) end
                    end
                end
            end
        end

        processor_done:send(true)
    end)

    -- A spawned process gives the runner a PID before the test function starts.
    local runner_pid = process.pid()

    local start_time = time.now()
    local completed_tests: number = 0
    local totals: CaseStats = { passed = 0, failed = 0, skipped = 0 }

    -- Build ordered suite list
    local ordered: {SuiteGroup} = {}
    for _, name in ipairs(suite_names) do
        table.insert(ordered, { name = name, tests = suites[name] })
    end
    if #no_suite > 0 then
        table.insert(ordered, { name = "other", tests = no_suite })
    end

    -- Execute each suite sequentially
    for _, suite in ipairs(ordered) do
        local suite_start = time.now()

        for i, entry in ipairs(suite.tests) do
            local entry_id = tostring((entry :: any).id)
            local test_name = discovery.short_name(entry_id)
            display.test_progress(test_name, suite.name, i, #suite.tests, completed_tests, total_tests)

            local entry_meta: any = (entry :: any).meta or {}
            local test_timeout = entry_meta.timeout or "30s"

            entry_status[entry_id] = "running"
            current_running_entry_id = entry_id
            completion_channels[entry_id] = channel.new(1)
            control_channels[entry_id] = channel.new(2)

            local entry_pid: string?, spawn_err: any = process.spawn("wippy.test:runner_entry", "wippy.test:runner_host", {
                parent_pid = runner_pid, topic = "test:update", entry_id = entry_id,
            })

            if spawn_err or not entry_pid then
                entry_status[entry_id] = "completed"
                current_running_entry_id = nil
                local error_msg = "test process failed to start: " .. tostring(spawn_err or "no PID")
                record_failure(all_failures, case_stats, entry_id, suite.name, test_name, error_msg)
                display.case_fail(suite.name, test_name, error_msg, 0)
            else
                local response = wait_for(control_channels[entry_id], test_timeout)
                local control: any = response and response:payload():data() or nil
                local protocol_error: string? = nil
                if control and (response:from() ~= entry_pid
                    or control.ref_id ~= entry_id or control.kind ~= "result") then
                    protocol_error = "test result attributed to " .. tostring(response:from())
                        .. ", expected " .. entry_pid
                    control = nil
                end

                if not control then
                    -- Timed out! Mark status first so any arriving events are immediately dropped
                    entry_status[entry_id] = "timed_out"
                    current_running_entry_id = nil

                    local sent, send_err = process.send(entry_pid, "runner:cancel", true)
                    local cancel_error: string? = nil
                    if not sent then
                        cancel_error = "test cancellation request failed: " .. tostring(send_err)
                    else
                        local ack = wait_for(control_channels[entry_id], "500ms")
                        local ack_data: any = ack and ack:payload():data() or nil
                        if not ack or ack:from() ~= entry_pid or not ack_data
                            or ack_data.ref_id ~= entry_id or ack_data.kind ~= "canceled" then
                            cancel_error = "test cancellation was not acknowledged"
                        elseif not ack_data.cancel_ok then
                            cancel_error = "test cancellation failed: " .. tostring(ack_data.cancel_error)
                        end
                    end
                    local terminated, terminate_err = process.terminate(entry_pid)

                    local lifecycle_error = not terminated and
                        ("test process termination failed: " .. tostring(terminate_err))
                        or cancel_error or protocol_error
                    local problem = verdict.check({
                        entry_id = entry_id,
                        declared = declared_cases[entry_id],
                        observed = case_stats[entry_id] and ((case_stats[entry_id].passed or 0) + (case_stats[entry_id].failed or 0) + (case_stats[entry_id].skipped or 0)) or 0,
                        completed = nil,
                        timed_out = true,
                        lifecycle_error = lifecycle_error,
                    })
                    local error_msg = problem and problem.message or "test timed out"

                    record_failure(all_failures, case_stats, entry_id, suite.name, test_name, error_msg)
                    display.case_fail(suite.name, test_name, error_msg, 0)
                else
                    -- Function completed; a missing completion is itself a failure.
                    local completion: any = wait_for(completion_channels[entry_id], "1s")
                    entry_status[entry_id] = "completed"
                    current_running_entry_id = nil

                    local cs = case_stats[entry_id]
                    local case_count = cs and ((cs.passed or 0) + (cs.failed or 0) + (cs.skipped or 0)) or 0
                    local value: any = control.value
                    local result_err: any = control.result_error
                    local problem = verdict.check({
                        entry_id = entry_id,
                        declared = declared_cases[entry_id],
                        observed = case_count,
                        completed = completion and completion.data or nil,
                        result_error = result_err,
                        returned_false = value == false or (declared_cases[entry_id] == nil
                            and type(value) == "table" and value.status == "error"),
                    })

                    if problem then
                        record_failure(all_failures, case_stats, entry_id, suite.name, test_name, problem.message)
                        display.case_fail(suite.name, test_name, problem.message, 0)
                    elseif declared_cases[entry_id] == nil then
                        -- A simple test has no BDD plan or per-case events.
                        if case_count == 0 then
                            local pcs = case_stats[entry_id]
                            if not pcs then
                                pcs = { passed = 0, failed = 0, skipped = 0 }
                                case_stats[entry_id] = pcs
                            end
                            pcs.passed = pcs.passed + 1
                            display.case_pass(suite.name, test_name, 0)
                        end
                    end
                end
            end

            completion_channels[entry_id] = nil
            control_channels[entry_id] = nil
            completed_tests = completed_tests + 1
        end

        -- Aggregate suite stats from case_stats
        local suite_stats: CaseStats = { passed = 0, failed = 0, skipped = 0 }
        for _, entry in ipairs(suite.tests) do
            local cs = case_stats[(entry :: any).id]
            if cs then
                suite_stats.passed = suite_stats.passed + cs.passed
                suite_stats.failed = suite_stats.failed + cs.failed
                suite_stats.skipped = suite_stats.skipped + cs.skipped
            end
        end

        totals.passed = totals.passed + suite_stats.passed
        totals.failed = totals.failed + suite_stats.failed
        totals.skipped = totals.skipped + suite_stats.skipped

        local suite_count = suite_stats.passed + suite_stats.failed + suite_stats.skipped
        local suite_elapsed = time.now():sub(suite_start):milliseconds()

        display.suite_result(suite.name, suite_count, suite_stats.passed, suite_stats.failed, suite_stats.skipped, suite_elapsed)
    end

    -- Shut down message processor
    done_ch:close()
    wait_for(processor_done, "100ms")

    local total_elapsed = time.now():sub(start_time):milliseconds()
    local effective_total = totals.passed + totals.failed + totals.skipped

    display.failures(all_failures)
    display.summary(totals.passed, totals.failed, totals.skipped, effective_total, total_elapsed)

    return totals.failed > 0 and 1 or 0
end

local function main(): number
    time.sleep(500 * time.MILLISECOND)

    local ok, result = pcall(run_tests)

    display.finish()

    if not ok then
        display.error("")
        display.error("RUNNER ERROR")
        display.error("")
        display.error(tostring(result))
        display.error("")
        return 1
    end

    return result :: number
end

return { main = main }
