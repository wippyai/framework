local consts = require("consts")
local security = require("security")
local sql = require("sql")

local function send(pid, topic, payload)
    local ok, err = process.send(pid, topic, payload)
    assert(ok, tostring(err))
end

local function client(args)
    local target = args.central_pid
    local hub_pid
    send(target, consts.WS_TOPICS.JOIN, {
        client_pid = process.pid(),
        metadata = {
            user_id = args.user_id,
            scope_id = args.scope_id,
            scope_policy_ids = args.scope_policy_ids,
            token_id = args.token_id,
            session_id = args.session_id,
            user_metadata = args.user_metadata or { observer_pid = args.observer_pid },
        },
    })
    local inbox = process.inbox()
    local events = process.events()
    while true do
        local result = channel.select({ inbox:case_receive(), events:case_receive() })
        if not result.ok then break end
        if result.channel == events then
            if result.value.kind == process.event.CANCEL then break end
        else
            local msg = result.value
            local topic = msg:topic()
            local payload = msg:payload():data()
            if topic == consts.WS_TOPICS.CONTROL then
                hub_pid = payload.target_pid
            elseif topic == "test.join" then
                assert(hub_pid, "control must arrive before retargeting")
                target = hub_pid
                send(target, consts.WS_TOPICS.JOIN, { client_pid = process.pid() })
            elseif topic == "test.send" then
                send(payload.target_pid or target, payload.topic, payload.data)
            elseif topic == "test.leave" then
                send(target, consts.WS_TOPICS.LEAVE, { client_pid = process.pid() })
            end
            send(args.observer_pid, "test.isolation", {
                kind = "client", user_id = args.user_id, client_pid = process.pid(),
                topic = topic, payload = payload, hub_pid = hub_pid,
            })
        end
    end
end

local function plugin(args)
    local inbox = process.inbox()
    local events = process.events()
    while true do
        local result = channel.select({ inbox:case_receive(), events:case_receive() })
        if not result.ok then break end
        if result.channel == events then
            if result.value.kind == process.event.CANCEL then break end
        else
            local msg = result.value
            local payload = msg:payload():data()
            local actor = assert(security.actor(), "plugin requires a user actor")
            local actor_id = actor:id()
            local privileged = security.can("relay.test.privileged", "relay.test:resource")
            if privileged then
                local db = assert(sql.get("app:db"))
                local written, err = db:execute(
                    "INSERT INTO isolation_actions (actor_id, request_id) VALUES ($1, $2)",
                    { actor_id, payload.request_id })
                db:release()
                assert(written, tostring(err))
            end
            send(args.user_metadata.observer_pid, "test.isolation", {
                kind = "plugin", user_id = args.user_id,
                actor_id = actor_id,
                privileged = privileged,
                topic = msg:topic(), payload = payload,
            })
        end
    end
end

return { client = client, plugin = plugin }
