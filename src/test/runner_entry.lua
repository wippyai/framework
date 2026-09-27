-- One runner-owned process per test function. The runner knows this PID at spawn,
-- before the function can emit any test:update message (or hang without one).
local funcs = require("funcs")
local channel = require("channel")
local time = require("time")

local function run(args)
    local parent_pid: string = tostring(args.parent_pid)
    local entry_id: string = tostring(args.entry_id)
    local cancel_inbox = process.listen("runner:cancel")
    local executor = funcs.new():with_context({
        parent_pid = parent_pid,
        test_topic = args.topic,
    })
    local cmd, start_err = executor:async(entry_id, {
        pid = parent_pid, topic = args.topic, ref_id = entry_id,
    })
    if start_err then
        process.send(parent_pid, "runner:control", {
            kind = "result", ref_id = entry_id, result_error = tostring(start_err),
        })
        return
    end

    local result = channel.select {
        cmd:response():case_receive(),
        cancel_inbox:case_receive(),
    }
    if result.channel == cancel_inbox then
        local canceled, cancel_err = cmd:cancel()
        local settled = channel.select {
            cmd:response():case_receive(),
            time.after("400ms"):case_receive(),
        }
        process.send(parent_pid, "runner:control", {
            kind = "canceled", ref_id = entry_id,
            cancel_ok = canceled == true and settled.channel == cmd:response(),
            cancel_error = cancel_err and tostring(cancel_err) or
                (settled.channel ~= cmd:response() and "command did not settle" or nil),
        })
        -- Remain alive until the runner explicitly terminates its owned process.
        process.listen("runner:stop"):receive()
        return
    end

    local payload, result_err = cmd:result()
    process.send(parent_pid, "runner:control", {
        kind = "result", ref_id = entry_id,
        value = payload and payload:data() or nil,
        result_error = result_err and tostring(result_err) or nil,
    })
end

return { run = run }
