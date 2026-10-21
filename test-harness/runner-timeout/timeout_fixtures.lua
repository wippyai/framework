local time = require("time")

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

return { late = late, silent = silent }
