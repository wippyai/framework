-- TUI rendering for test results
local term = require("terminal")

local display = {}

local SYM_PASS = term.green("o")
local SYM_FAIL = term.red("x")
local SYM_SKIP = term.yellow("-")

type Failure = {
    suite: string,
    test: string,
    error: string,
}

function display.begin()
    term.write(term.hide_cursor())
    term.print("")
    term.print(term.bold(term.cyan("  Running Tests")))
    term.print("")
end

function display.finish()
    term.write(term.show_cursor())
end

-- Overwrite current line with spinner showing test execution progress
function display.test_progress(name: string, suite: string, index: number, count: number, completed: number, total: number)
    local spinner = term.spinner(index)
    local progress = completed + index
    local pbar = term.progress_bar(progress, total, 15)
    local pct = string.format("%3d%%", math.floor((progress / total) * 100))

    term.write(
        term.clear_line()
        .. "  " .. spinner
        .. " " .. term.bold(suite)
        .. " " .. term.dim("(" .. index .. "/" .. count .. ")")
        .. " " .. term.dim(name)
        .. "  " .. pbar
        .. " " .. term.dim(pct)
    )
end

-- Print completed suite summary line replacing the spinner
function display.suite_result(name: string, count: number, passed: number, failed: number, skipped: number, elapsed: number)
    term.write(term.clear_line())

    local icon = failed == 0 and SYM_PASS or SYM_FAIL

    local status: string
    if failed == 0 then
        status = term.green(passed .. "/" .. count)
    else
        status = term.red(failed .. " failed")
    end

    local skip_part = ""
    if skipped > 0 then
        skip_part = " " .. term.yellow(skipped .. " skipped")
    end

    term.print(
        "  " .. icon
        .. " " .. term.bold(name)
        .. " " .. term.dim("(" .. count .. ")")
        .. " " .. status
        .. skip_part
        .. " " .. term.duration(elapsed)
    )
end

-- Print individual case pass
function display.case_pass(suite: string, name: string, duration_sec: number)
    term.write(term.clear_line())
    term.print("    " .. SYM_PASS .. " " .. term.dim(name) .. " " .. term.duration(duration_sec * 1000))
end

-- Print individual case failure (short line, details go in failures report)
function display.case_fail(suite: string, name: string, err: string, duration_sec: number)
    term.write(term.clear_line())
    term.print("    " .. SYM_FAIL .. " " .. name)
end

-- Print individual case skip
function display.case_skip(suite: string, name: string)
    term.write(term.clear_line())
    term.print("    " .. SYM_SKIP .. " " .. term.dim(name) .. " " .. term.dim("(skipped)"))
end

-- Print detailed failure report
function display.failures(failures: {Failure})
    if #failures == 0 then
        return
    end

    term.print("")
    term.print(term.bold(term.red("  Failures")))

    for _, f in ipairs(failures) do
        term.print("")
        term.print("    " .. term.cyan(f.suite .. " > " .. f.test))
        term.print("    " .. term.red(tostring(f.error)))
    end
end

-- Print final summary bar and counts
function display.summary(passed: number, failed: number, skipped: number, total: number, elapsed_ms: number)
    term.print("")

    local bar = term.progress_bar(passed, total, 25)

    if failed > 0 then
        term.print("  " .. term.red(term.bold("FAILED")) .. "  " .. bar)
        term.print("")

        local parts: {string} = {
            term.green(passed .. " passed"),
            term.red(failed .. " failed"),
        }
        if skipped > 0 then
            table.insert(parts, term.yellow(skipped .. " skipped"))
        end
        table.insert(parts, term.duration(elapsed_ms))
        term.print("  " .. table.concat(parts, "  "))
    else
        term.print("  " .. term.green(term.bold("PASSED")) .. "  " .. bar)
        term.print("")

        local parts: {string} = {
            term.green(passed .. " tests"),
        }
        if skipped > 0 then
            table.insert(parts, term.yellow(skipped .. " skipped"))
        end
        table.insert(parts, term.duration(elapsed_ms))
        term.print("  " .. table.concat(parts, "  "))
    end

    term.print("")
end

-- Print a dim info line
function display.info(text: string)
    term.print(term.dim("  " .. text))
end

-- Print a red error line
function display.error(text: string)
    term.print(term.red("  " .. text))
end

return display
