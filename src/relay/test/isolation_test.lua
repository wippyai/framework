local test = require("test")
local time = require("time")
local json = require("json")
local consts = require("consts")

local children = {}

local function send(pid, topic, payload)
    local ok, err = process.send(pid, topic, payload)
    test.is_nil(err)
    test.ok(ok)
end

local function define_tests()
    test.describe("relay client isolation", function()
        test.after_each(function()
            for _, pid in ipairs(children) do
                local ok, err = process.cancel(pid, consts.CANCEL_TIMEOUT)
                test.is_nil(err)
                test.ok(ok)
            end
            children = {}
        end)

        test.it("routes only connected clients under their own actor", function()
            local central_pid = process.registry.lookup(consts.CENTRAL_HUB_REGISTRY_NAME)
            test.not_nil(central_pid)
            local observations = process.listen("test.isolation")
            local receipts = {}
            local function wait_for(predicate, label)
                local timer = time.after("3s")
                while true do
                    for _, receipt in ipairs(receipts) do
                        if predicate(receipt) then return receipt end
                    end
                    local result = channel.select({ observations:case_receive(), timer:case_receive() })
                    test.is_false(result.channel == timer, "isolation barrier " .. label .. " times out; " .. assert(json.encode(receipts)))
                    table.insert(receipts, result.value)
                    print(assert(json.encode(result.value)))
                end
            end
            local function client_event(user_id, topic)
                return wait_for(function(r)
                    return r.kind == "client" and r.user_id == user_id and r.topic == topic
                end, user_id .. ":" .. topic)
            end
            local function command(pid, target_pid, request_id)
                send(pid, "test.send", {
                    target_pid = target_pid, topic = consts.WS_TOPICS.MESSAGE,
                    data = assert(json.encode({ type = "probe_action", request_id = request_id })),
                })
            end
            local function plugin_event(user_id, request_id)
                return wait_for(function(r)
                    return r.kind == "plugin" and r.user_id == user_id
                        and r.payload.request_id == request_id
                end, user_id .. ":" .. request_id)
            end

            local users = { "alice@relay.test", "bob@relay.test" }
            local clients = {}
            local hubs = {}
            -- Both connections remain live; control application is held until the test releases it.
            for i, user_id in ipairs(users) do
                local pid, err = process.spawn_linked_monitored("app:isolation_client", "app:processes", {
                    central_pid = central_pid, observer_pid = process.pid(),
                    user_id = user_id,
                    scope_id = i == 1 and "app:user" or "wippy.relay.security:root",
                })
                test.is_nil(err)
                test.not_nil(pid)
                clients[i] = pid
                table.insert(children, pid)
            end
            for i, user_id in ipairs(users) do
                hubs[i] = client_event(user_id, consts.WS_TOPICS.CONTROL).hub_pid
                table.insert(children, hubs[i])
            end

            send(clients[2], "test.join", {})
            client_event(users[2], consts.CLIENT_TOPICS.WELCOME)
            command(clients[1], nil, "early")
            send(clients[1], "test.send", { topic = "test.barrier", data = {} })
            client_event(users[2], "test.barrier")
            command(clients[2], nil, "bob-fence")
            plugin_event(users[2], "bob-fence")

            send(clients[1], "test.join", {})
            client_event(users[1], consts.CLIENT_TOPICS.WELCOME)
            command(clients[1], nil, "alice-own")
            local alice = plugin_event(users[1], "alice-own")
            test.eq(alice.actor_id, users[1])
            test.eq(alice.privileged, false)
            test.eq(alice.payload.conn_pid, clients[1])

            command(clients[1], hubs[2], "foreign")
            send(clients[1], "test.send", { target_pid = hubs[2], topic = "test.foreign-barrier", data = {} })
            client_event(users[2], "test.foreign-barrier")
            command(clients[2], nil, "bob-own")
            local bob = plugin_event(users[2], "bob-own")
            test.eq(bob.actor_id, users[2])
            test.eq(bob.privileged, true)
            test.eq(bob.payload.conn_pid, clients[2])

            send(clients[1], "test.leave", {})
            command(clients[1], nil, "after-leave")
            send(clients[1], "test.join", {})
            command(clients[1], nil, "alice-fence")
            plugin_event(users[1], "alice-fence")

            local routed = {}
            for _, receipt in ipairs(receipts) do
                if receipt.kind == "plugin" then
                    table.insert(routed, receipt.payload.request_id)
                end
            end
            table.sort(routed)
            test.eq(table.concat(routed, ","), "alice-fence,alice-own,bob-fence,bob-own",
                "unjoined, foreign and disconnected clients must not invoke plugins")
        end)
    end)
end

return { run = test.run_cases(define_tests) }
