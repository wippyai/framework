local user = require("user")
local json = require("json")
local consts = require("consts")
local security = require("security")

local function run(args: any): any
    return user.run(args)
end

local function upgraded(args: any): any
    assert(type(args) == "string", "live update must enter with the relay upgrade snapshot")
    local snapshot = user._decode_upgrade_state(args)
    local probe = process.listen("relay.runtime.upgrade_probe")
    coroutine.spawn(function()
        local token = probe:receive()
        local actor = assert(security.actor())
        assert(process.send(snapshot.config.runtime_observer, "relay.runtime.upgrade_options", {
            token = token, pid = process.pid(), actor_id = actor:id(),
            options = process.get_options(),
        }))
        process.unlisten(probe)
    end)
    assert(process.send(snapshot.config.runtime_observer, "relay.runtime.upgrade_loaded", {
        pid = process.pid(), clients = snapshot.connected_clients,
        plugin_pid = snapshot.active_plugins.runtime_.pid,
    }))
    return user.run(args)
end

local function foreign(args: any): any
    local done = process.listen("relay.runtime.foreign_done")
    assert(process.send(args.hub_pid, consts.WS_TOPICS.MESSAGE,
        assert(json.encode({type = "runtime_echo", request_id = "foreign-after-upgrade"}))))
    -- Both messages have the same sender. The broadcast is a FIFO fence proving
    -- the hub has processed the unconnected sender's earlier command.
    assert(process.send(args.hub_pid, "relay.runtime.foreign_fence", { pid = process.pid() }))
    done:receive()
    process.unlisten(done)
end

return { run = run, upgraded = upgraded, foreign = foreign }
