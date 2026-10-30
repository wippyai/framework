local security = require("security")

local function run(args)
    local observer = args.user_metadata.observer_pid
    local inbox, events = process.inbox(), process.events()
    local busy, retiring = false, false
    while true do
        local result = channel.select({inbox:case_receive(), events:case_receive()})
        if not result.ok then break end
        if result.channel == events then
            if result.value.kind == process.event.CANCEL then break end
        else
            local topic = result.value:topic()
            if topic == "hold" then busy = true end
            if topic == "release" then busy = false end
            if topic == "shutdown" then retiring = true end
            if topic == "resume" then retiring = false end
            assert(process.send(observer, "relay.authority.session", {
                pid = process.pid(), hub_pid = args.user_hub_pid, topic = topic,
                actor_id = security.actor():id(), busy = busy,
                writable = security.can("relay.authority.write", "app:resource"),
            }))
            if retiring and not busy then break end
        end
    end
    return {status = "stopped"}
end

return {run = run}
