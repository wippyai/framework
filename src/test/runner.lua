-- Test runner with real-time per-case TUI display
local io = require("io")
local registry = require("registry")
local funcs = require("funcs")
local time = require("time")
local channel = require("channel")
local discovery = require("discovery")
local display = require("display")

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
    local inbox = process.listen("test:update")

    -- Coordination channels
    local done_ch = channel.new()
    local test_done_ch = channel.new(1)
    local processor_done = channel.new(1)

    -- Shared state between message processor and main loop
    local case_stats: {[string]: CaseStats} = {}
    local all_failures: {Failure} = {}

    -- Background message processor: renders case events as they arrive
    coroutine.spawn(function()
        while true do
            local result = channel.select {
                inbox:case_receive(),
                done_ch:case_receive(),
            }

            if not result.ok then
                break
            end

            local msg: any = result.value
            local msg_type = tostring(msg.type)
            local data: any = msg.data or {}
            local ref_id = tostring(data.ref_id or "")

            if ref_id ~= "" and not case_stats[ref_id] then
                case_stats[ref_id] = { passed = 0, failed = 0, skipped = 0 }
            end

            if msg_type == "test:case:pass" then
                if ref_id ~= "" then
                    local cs = case_stats[ref_id]
                    if cs then cs.passed = cs.passed + 1 end
                end
                display.case_pass(tostring(data.suite or ""), tostring(data.test or ""), tonumber(data.duration) or 0)

            elseif msg_type == "test:case:fail" then
                if ref_id ~= "" then
                    record_failure(all_failures, case_stats, ref_id, tostring(data.suite or ""), tostring(data.test or ""), tostring(data.error or "unknown error"))
                end
                display.case_fail(tostring(data.suite or ""), tostring(data.test or ""), tostring(data.error or ""), tonumber(data.duration) or 0)

            elseif msg_type == "test:case:skip" then
                if ref_id ~= "" then
                    local cs = case_stats[ref_id]
                    if cs then cs.skipped = cs.skipped + 1 end
                end
                display.case_skip(tostring(data.suite or ""), tostring(data.test or ""))

            elseif msg_type == "test:complete" then
                test_done_ch:send(msg)
            end
        end

        processor_done:send(true)
    end)

    -- Create executor with parent PID context for auto-forwarding
    local executor = funcs.new():with_context({
        parent_pid = process.pid(),
        test_topic = "test:update",
    })

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

            local cmd: any, cmd_err: any = executor:async(entry_id, {
                pid = process.pid(),
                topic = "test:update",
                ref_id = entry_id,
            })

            if cmd_err then
                record_failure(all_failures, case_stats, entry_id, suite.name, test_name, tostring(cmd_err))
                display.case_fail(suite.name, test_name, tostring(cmd_err), 0)
            else
                local response = wait_for(cmd:response(), "30s")

                if not response then
                    local _, result_err = cmd:result()
                    local error_msg = result_err and tostring(result_err) or "test timed out"

                    record_failure(all_failures, case_stats, entry_id, suite.name, test_name, error_msg)
                    display.case_fail(suite.name, test_name, error_msg, 0)
                else
                    -- Function completed, drain any pending test:complete event
                    wait_for(test_done_ch, "1s")

                    local cs = case_stats[entry_id]
                    local case_count = cs and ((cs.passed or 0) + (cs.failed or 0) + (cs.skipped or 0)) or 0
                    local has_case_events = case_count > 0

                    if not has_case_events then
                        -- Simple test without BDD case events, check function result
                        local payload: any, result_err: any = cmd:result()
                        if result_err then
                            record_failure(all_failures, case_stats, entry_id, suite.name, test_name, tostring(result_err))
                            display.case_fail(suite.name, test_name, tostring(result_err), 0)
                        elseif payload and payload:data() == false then
                            record_failure(all_failures, case_stats, entry_id, suite.name, test_name, "test returned false")
                            display.case_fail(suite.name, test_name, "test returned false", 0)
                        else
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
