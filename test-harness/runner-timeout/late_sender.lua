local time = require("time")

local function run(args)
    time.sleep(350 * time.MILLISECOND)
    process.send(args.pid, args.topic, { type = "test:case:pass", data = {
        ref_id = args.ref_id, suite = "late isolation", test = "late_pass", duration = 0,
    } })
    process.send(args.pid, args.topic, { type = "test:complete", data = {
        ref_id = args.ref_id, total = 1, passed = 1, failed = 0, skipped = 0,
    } })
    process.registry.register("late_sender_emitted")
    time.sleep(2 * time.SECOND)
end

return { run = run }
