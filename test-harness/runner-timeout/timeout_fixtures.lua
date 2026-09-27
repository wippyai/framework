local time = require("time")
local test = require("test")

local function late(args)
    process.registry.register("timeout_late_entry")
    process.send(args.pid, args.topic, { type = "test:plan", data = {
        ref_id = args.ref_id, suites = { { tests = { "never" } } },
    } })
    local pid, err = process.spawn("app:late_sender", "app:processes", args)
    if err then error(err) end
    time.sleep(2 * time.SECOND)
end

local function silent(_args)
    process.registry.register("timeout_silent_entry")
    time.sleep(2 * time.SECOND)
end

local function next_late(args)
    return test.run_cases(function()
        test.describe("late isolation", function()
            test.it("ignores old events and terminates the timed-out entry", function()
                time.sleep(500 * time.MILLISECOND)
                test.not_nil(process.registry.lookup("late_sender_emitted"))
                test.is_nil(process.registry.lookup("timeout_late_entry"))
            end)
        end)
    end)(args)
end

local function next_silent(args)
    return test.run_cases(function()
        test.describe("silent timeout", function()
            test.it("terminates an entry before its first event", function()
                test.is_nil(process.registry.lookup("timeout_silent_entry"))
            end)
        end)
    end)(args)
end

return { late = late, silent = silent, next_late = next_late, next_silent = next_silent }
