local function run(args)
    local observer = args.config.runtime_observer
    assert(process.send(observer, "relay.runtime.started", { pid = process.pid(), user_id = args.user_id }))
    local inbox = process.inbox()
    local events = process.events()
    while true do
        local result = channel.select({ inbox:case_receive(), events:case_receive() })
        if not result.ok then break end
        if result.channel == events then
            if result.value.kind == process.event.CANCEL then break end
        else
            local message = result.value
            local payload = message:payload():data()
            assert(process.send(args.user_hub_pid, "relay.runtime.response", {
                topic = message:topic(), from = message:from(), plugin_pid = process.pid(),
                user_id = args.user_id, user_metadata = args.user_metadata, payload = payload,
            }))
        end
    end
    return { status = "stopped" }
end

return { run = run, finish = function() return { status = "finished" } end }
