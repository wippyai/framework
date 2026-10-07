local test = require("test")
local exec = require("exec")
local fs = require("fs")
local env = require("env")
local time = require("time")

local function read_all(stream)
    local chunks = {}
    while true do
        local data = stream:read()
        if not data then break end
        chunks[#chunks + 1] = data
    end
    stream:close()
    return table.concat(chunks)
end

local function run_check(target, message, exit_code)
    local root = env.get("WIPPY_FRAMEWORK_ROOT")
    test.not_nil(root, "WIPPY_FRAMEWORK_ROOT must select the real Framework checkout")
    local files = fs.get("app:aggregate_fixtures")
    local directory = "check-" .. tostring(time.now():unix_nano())
    for _, path in ipairs({directory, directory .. "/src", directory .. "/src/fixture",
        directory .. "/src/fixture/test"}) do
        local created, err = files:mkdir(path)
        test.is_true(created, tostring(err))
    end
    local module = directory .. "/src/fixture/test/Makefile"
    local written, write_err = files:writefile(module,
        "test lint:\n\t@printf '%s\\n' '" .. message .. "'; exit " .. tostring(exit_code) .. "\n")
    test.is_true(written, tostring(write_err))
    local executor, executor_err = exec.get("app:build_executor")
    test.not_nil(executor, tostring(executor_err))
    local command = "make --no-print-directory -f " .. string.format("%q", root .. "/Makefile")
        .. " -C " .. string.format("%q", "/tmp/wippy-aggregate-checks/" .. directory)
        .. " " .. target .. " TEST_MODULES=fixture BENCH_REVISION=fixture"
    local proc, create_err = executor:exec(command, {env = {MAKEFLAGS = ""}})
    test.not_nil(proc, tostring(create_err))
    local stdout, stdout_err = proc:stdout_stream()
    local stderr, stderr_err = proc:stderr_stream()
    test.not_nil(stdout, tostring(stdout_err))
    test.not_nil(stderr, tostring(stderr_err))
    local started, start_err = proc:start()
    test.is_true(started, tostring(start_err))
    local output = read_all(stdout)
    local errors = read_all(stderr)
    local status, wait_err = proc:wait()
    test.is_nil(wait_err)
    executor:release()
    files:remove(module)
    files:remove(directory .. "/src/fixture/test")
    files:remove(directory .. "/src/fixture")
    files:remove(directory .. "/src")
    files:remove(directory)
    return status, output .. errors
end

local function define_tests()
    test.describe("aggregate build checks", function()
        test.it("fails aggregate tests when a failed module prints PASSED", function()
            local status, output = run_check("run-tests", "PASSED", 1)
            test.is_true(status ~= 0)
            test.contains(output, "FAILED")
        end)

        test.it("passes aggregate tests without requiring a PASSED marker", function()
            local status, output = run_check("run-tests", "completed", 0)
            test.eq(status, 0, output)
        end)

        test.it("fails aggregate lint without requiring an errors marker", function()
            local status, output = run_check("run-lint", "Checked fixture", 1)
            test.is_true(status ~= 0)
            test.contains(output, "FAILED")
        end)

        test.it("passes aggregate lint when successful output mentions errors", function()
            local status, output = run_check("run-lint", "Checked fixture: 0 errors", 0)
            test.eq(status, 0, output)
        end)
    end)
end

return {run = test.run_cases(define_tests)}
