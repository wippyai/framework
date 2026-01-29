-- Test runner with real-time progress and beautiful error display
-- Finds and runs all functions with meta.type = "test"
local io = require("io")
local registry = require("registry")
local funcs = require("funcs")
local time = require("time")

-- ANSI codes
local reset = "\027[0m"
local function bold(s) return "\027[1m" .. s .. reset end
local function red(s) return "\027[31m" .. s .. reset end
local function green(s) return "\027[32m" .. s .. reset end
local function yellow(s) return "\027[33m" .. s .. reset end
local function cyan(s) return "\027[36m" .. s .. reset end
local function dim(s) return "\027[2m" .. s .. reset end

-- Cursor control
local function clear_line() return "\027[2K\r" end
local function hide_cursor() return "\027[?25l" end
local function show_cursor() return "\027[?25h" end

-- Spinner frames
local spinner_frames = {"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}

-- Progress bar characters
local bar_full = "█"
local bar_empty = "░"

-- Symbols
local SYM_FAIL = red("✗")
local SYM_SUITE_DONE = green("●")
local SYM_SUITE_FAIL = red("●")

-- Format duration
local function format_duration(ms: number): string
    if ms < 1 then
        return dim("<1ms")
    elseif ms < 1000 then
        return dim(string.format("%dms", ms))
    else
        return dim(string.format("%.1fs", ms / 1000))
    end
end

-- Build progress bar
local function progress_bar(current: number, total: number, width: number?): string
    width = width or 20
    if total == 0 then return dim(string.rep(bar_empty, width)) end
    local filled = math.floor((current / total) * width)
    local empty = width - filled
    return cyan(string.rep(bar_full, filled)) .. dim(string.rep(bar_empty, empty))
end

-- Results
local results = {
    passed = 0,
    failed = 0,
    errors = {},
    suite_times = {},
}

-- Sort tests by order field (meta.order), then by id
local function sort_tests(tests)
    table.sort(tests, function(a, b)
        local order_a = (a.meta and a.meta.order) or 0
        local order_b = (b.meta and b.meta.order) or 0
        if order_a ~= order_b then
            return order_a < order_b
        end
        return a.id < b.id
    end)
    return tests
end

-- Group tests by suite
local function group_by_suite(entries)
    local suites = {}
    local no_suite = {}

    for _, entry in ipairs(entries) do
        local suite = entry.meta and entry.meta.suite
        if suite then
            suites[suite] = suites[suite] or {}
            table.insert(suites[suite], entry)
        else
            table.insert(no_suite, entry)
        end
    end

    for _, tests in pairs(suites) do
        sort_tests(tests)
    end
    sort_tests(no_suite)

    return suites, no_suite
end

-- Get sorted suite names
local function sorted_keys(t)
    local keys = {}
    for k in pairs(t) do
        table.insert(keys, k)
    end
    table.sort(keys)
    return keys
end

-- Extract short name from full id
local function short_name(id: string): string
    return id:match(":([^:]+)$") or id
end

-- Run single test with retry for pool registration race
local function run_test(entry)
    local max_retries = 3
    local retry_delay = 10 * time.MILLISECOND

    for attempt = 1, max_retries do
        local ok, result, err = pcall(function()
            return funcs.call(entry.id)
        end)

        if not ok then
            local err_str = tostring(result)
            if err_str:match("pool not found") and attempt < max_retries then
                time.sleep(retry_delay)
            else
                return false, result
            end
        elseif err then
            return false, err
        elseif result == false then
            return false, "test returned false"
        else
            return true, nil
        end
    end

    return false, "max retries exceeded"
end

-- Run suite with live progress
local function run_suite(name: string, tests: {any}, suite_idx: number, total_suites: number, completed_tests: number, total_tests: number)
    local suite_passed = 0
    local suite_failed = 0
    local failures = {}
    local suite_start = time.now()

    local base_indent = "  "

    for i, entry in ipairs(tests) do
        local test_name = short_name(entry.id)
        local spinner = cyan(spinner_frames[((i - 1) % #spinner_frames) + 1])

        local progress = completed_tests + i
        local pbar = progress_bar(progress, total_tests, 15)
        local pct = string.format("%3d%%", math.floor((progress / total_tests) * 100))

        io.write(clear_line() .. base_indent .. spinner .. " " .. bold(name) .. " " .. dim("(" .. i .. "/" .. #tests .. ")") .. " " .. dim(test_name) .. "  " .. pbar .. " " .. dim(pct))
        io.flush()

        local test_start = time.now()
        local ok, err_obj = run_test(entry)
        local test_elapsed = time.now():sub(test_start):milliseconds()

        if ok then
            suite_passed = suite_passed + 1
            results.passed = results.passed + 1
        else
            suite_failed = suite_failed + 1
            results.failed = results.failed + 1
            table.insert(failures, {
                name = test_name,
                id = entry.id,
                error = err_obj,
                time = test_elapsed
            })
            table.insert(results.errors, {id = entry.id, error = err_obj})
        end
    end

    local suite_elapsed = time.now():sub(suite_start):milliseconds()
    results.suite_times[name] = suite_elapsed

    io.write(clear_line())

    local icon = suite_failed == 0 and SYM_SUITE_DONE or SYM_SUITE_FAIL
    local status
    if suite_failed == 0 then
        status = green(suite_passed .. "/" .. #tests)
    else
        status = red(suite_failed .. " failed")
    end

    io.print(base_indent .. icon .. " " .. bold(name) .. " " .. dim("(" .. #tests .. ")") .. " " .. status .. " " .. format_duration(suite_elapsed))

    for _, f in ipairs(failures) do
        io.print("    " .. SYM_FAIL .. " " .. f.name)
    end

    return #tests, failures
end

-- Filter tests by patterns (args)
local function filter_tests(entries, patterns)
    if not patterns or #patterns == 0 then
        return entries
    end

    local filtered = {}
    for _, entry in ipairs(entries) do
        for _, pattern in ipairs(patterns) do
            if entry.id:find(pattern, 1, true) then
                table.insert(filtered, entry)
                break
            end
        end
    end
    return filtered
end

-- Main test runner logic
local function run_tests()
    local args = io.args()

    io.print("")
    io.print(bold(cyan("  Running Tests")))
    io.print("")

    local entries, err = registry.find({["meta.type"] = "test"})
    if err then
        io.print(red("  Error: " .. tostring(err)))
        return 1
    end

    if not entries or #entries == 0 then
        io.print(yellow("  No tests found"))
        return 0
    end

    if args and #args > 0 then
        entries = filter_tests(entries, args)
        if #entries == 0 then
            io.print(yellow("  No tests match filter: " .. table.concat(args, ", ")))
            return 0
        end
        io.print(dim("  Filter: " .. table.concat(args, ", ")))
    end

    local suites, no_suite = group_by_suite(entries)
    local suite_names = sorted_keys(suites)

    local total_tests = #entries
    local total_suites = #suite_names + (#no_suite > 0 and 1 or 0)

    io.print(dim("  " .. total_tests .. " tests in " .. total_suites .. " suites"))
    io.print("")

    local start_time = time.now()
    local completed_tests = 0
    local all_failures = {}

    for idx, name in ipairs(suite_names) do
        local count, failures = run_suite(name, suites[name], idx, total_suites, completed_tests, total_tests)
        completed_tests = completed_tests + count
        for _, f in ipairs(failures) do
            table.insert(all_failures, f)
        end
    end

    if #no_suite > 0 then
        local _, failures = run_suite("other", no_suite, total_suites, total_suites, completed_tests, total_tests)
        for _, f in ipairs(failures) do
            table.insert(all_failures, f)
        end
    end

    local total_elapsed = time.now():sub(start_time):milliseconds()

    if #all_failures > 0 then
        io.print("")
        io.print(bold(red("  Failures")))

        for _, f in ipairs(all_failures) do
            io.print("")
            io.print("    " .. cyan(f.id))
            io.print("    " .. red(tostring(f.error)))
        end
    end

    io.print("")

    local summary_bar = progress_bar(results.passed, total_tests, 25)

    if results.failed > 0 then
        io.print("  " .. red(bold("FAILED")) .. "  " .. summary_bar)
        io.print("")
        io.print("  " .. green(results.passed .. " passed") .. "  " .. red(results.failed .. " failed") .. "  " .. format_duration(total_elapsed))
    else
        io.print("  " .. green(bold("PASSED")) .. "  " .. summary_bar)
        io.print("")
        io.print("  " .. green(results.passed .. " tests") .. "  " .. format_duration(total_elapsed))
    end

    io.print("")

    return results.failed > 0 and 1 or 0
end

local function main()
    time.sleep(500 * time.MILLISECOND)

    io.write(hide_cursor())
    io.flush()

    local ok, result = pcall(run_tests)

    io.write(show_cursor())
    io.flush()

    if not ok then
        io.print("")
        io.print(red(bold("  RUNNER ERROR")))
        io.print("")
        io.print(red("  " .. tostring(result)))
        io.print("")
        return 1
    end

    return result
end

return { main = main }
