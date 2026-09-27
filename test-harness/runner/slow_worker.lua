local time = require("time")

local function run(args)
    process.registry.register("slow_worker_proc")
    local target_pid = args and args.pid
    local topic = args and args.topic or "test:update"
    local ref_id = args and args.ref_id or "app:slow_entry"

    -- Sleep to outlive the runner timeout
    time.sleep(200 * time.MILLISECOND)

    -- If still alive, emit late events to target
    if target_pid then
        local pid_str: string = tostring(target_pid)
        local topic_str: string = tostring(topic)
        process.send(pid_str, topic_str, {
            type = "test:case:pass",
            data = { ref_id = ref_id, suite = "runner", test = "late_pass", duration = 0.1 }
        })
        process.send(pid_str, topic_str, {
            type = "test:complete",
            data = { ref_id = ref_id, total = 1, passed = 1, failed = 0, skipped = 0, status = "passed" }
        })
    end
end

return { run = run }
