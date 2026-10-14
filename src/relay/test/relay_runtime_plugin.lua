local function run(args)
    local observer = args.config.runtime_observer
    assert(process.send(observer, "relay.runtime.started", { pid = process.pid(), user_id = args.user_id }))
    local inbox = process.inbox()
    local events = process.events()
    local busy, retiring, shutdowns = false, false, 0
    while true do
        local result = channel.select({ inbox:case_receive(), events:case_receive() })
        if not result.ok then break end
        if result.channel == events then
            if result.value.kind == process.event.CANCEL then break end
        else
            local message = result.value
            local payload = message:payload():data()
            if args.config.runtime_drain_fixture then
                local topic = message:topic()
                if topic == "hold" then busy = true end
                if topic == "shutdown" then shutdowns = shutdowns + 1; retiring = true end
                if topic == "resume" then retiring = false end
                if topic == "release" then busy = false end
                if topic == "forge_retire" then
                    assert(process.send(args.user_hub_pid, "hub.retire", {}))
                end
                assert(process.send(observer, "relay.runtime.lifecycle", {
                    pid = process.pid(), topic = topic, busy = busy, shutdowns = shutdowns,
                }))
                if retiring and not busy then break end
            end
            assert(process.send(args.user_hub_pid, "relay.runtime.response", {
                topic = message:topic(), from = message:from(), plugin_pid = process.pid(),
                user_id = args.user_id, user_metadata = args.user_metadata, payload = payload,
            }))
        end
    end
    return { status = "stopped" }
end

return { run = run, finish = function() return { status = "finished" } end }
