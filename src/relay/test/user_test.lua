local test = require("test")
local time = require("time")
local consts = require("consts")
local security = require("security")
local user = require("user")

local function define_tests()
    test.describe("relay user hub", function()
        for _, parent in ipairs({false, true}) do
            test.it("sends a legacy-compatible welcome payload on join, custom parent " .. tostring(parent), function()
                local user_id = "relay-user-test-" .. tostring(parent) .. "@wippy.local"
                local actor = security.new_actor(user_id, {})
                local scope, scope_err = security.named_scope("app:user")
                test.is_nil(scope_err)

                local config = consts.get_config()
                local hub_host = assert(config.user_hub_host, "relay application_host is not configured")
                local hub_pid, spawn_err = process.with_context({})
                    :with_actor(actor)
                    :with_scope(scope)
                    :spawn_linked_monitored(
                        consts.USER_HUB_PROCESS_ID,
                        hub_host,
                        {
                            user_id = user_id,
                            user_metadata = {},
                            plugins = {},
                            config = config,
                            central_hub_pid = parent and process.pid() or nil,
                        }
                    )

                test.is_nil(spawn_err)
                test.not_nil(hub_pid)

                local welcome = process.listen(consts.CLIENT_TOPICS.WELCOME)
                local send_ok, send_err = process.send(hub_pid :: string, consts.WS_TOPICS.JOIN, { client_pid = process.pid() })
                test.is_nil(send_err)

                local timer = time.after(3000 * time.MILLISECOND)
                local res = channel.select({ welcome:case_receive(), timer:case_receive() })

                test.is_false(res.channel == timer)
                test.not_nil(res.value)
                test.eq(res.value.user_id, user_id)
                test.eq(process.registry.lookup(consts.USER_HUB_REGISTRY_PREFIX .. user_id), hub_pid)
                test.eq(type(res.value.plugins), "table")
                test.eq(type(res.value.active_session_ids), "table")
                test.eq(#res.value.active_session_ids, 0)
                test.eq(res.value.active_sessions, 0)

                process.cancel(hub_pid :: string, consts.CANCEL_TIMEOUT)
            end)
        end
    end)

    test.describe("relay user rolling upgrade", function()
        test.it("retires a superseded frame even when the older version missed RETIRE", function()
            local user_id = "relay-resume-" .. process.pid()
            local name = consts.USER_HUB_REGISTRY_PREFIX .. user_id
            assert(process.registry.register(name))
            local failures = process.listen(consts.CLIENT_TOPICS.ERROR)
            local events = process.events()
            local scope = assert(security.named_scope("app:user"))
            local config = consts.get_config()
            local pid = assert(process.with_context({}):with_actor(security.new_actor(user_id, {}))
                :with_scope(scope):spawn_monitored(consts.USER_HUB_PROCESS_ID, assert(config.user_hub_host),
                    user._encode_upgrade_state({
                        relay_user_upgrade = true, user_id = user_id, user_metadata = {}, plugins = {},
                        config = config, central_hub_pid = assert(process.registry.lookup(consts.CENTRAL_HUB_REGISTRY_NAME)),
                        active_plugins = {}, connected_clients = {[process.pid()] = true}, client_count = 1,
                        pg_groups = {},
                    })))
            local ok, err = pcall(function()
                local timer = time.timer(3 * time.SECOND)
                local event
                repeat
                    local res = channel.select({events:case_receive(), timer:channel():case_receive()})
                    if res.channel == timer:channel() then
                        timer:stop()
                        error("a superseded resumed frame must not await another retirement request")
                    end
                    event = res.value
                until event.from == pid and event.kind == process.event.EXIT
                timer:stop()
                test.is_nil(event.result.error)
                local deadline = time.timer(3 * time.SECOND)
                local failure = channel.select({failures:case_receive(), deadline:channel():case_receive()})
                deadline:stop()
                test.eq(failure.channel, failures)
                test.eq(failure.value.error, consts.ERROR_CODES.HUB_CREATION_FAILED)
                test.eq(process.registry.lookup(name), (process.pid()), "retirement must preserve the current binding")
            end)
            process.cancel(pid, consts.CANCEL_TIMEOUT)
            assert(process.registry.unregister(name))
            process.unlisten(failures)
            if not ok then error(err) end
        end)
    end)

    test.describe("relay user hot upgrade state", function()
        test.it("preserves clients, child plugins, and group declarations without carrying handles", function()
            local snapshot = user._snapshot_state({
                user_id = "admin@wippy.local",
                user_metadata = { email = "admin@wippy.local" },
                plugins = { session_ = { prefix = "session_", process_id = "app:session", auto_start = true } },
                config = { user_hub_host = "app:host" },
                central_hub_pid = "app:central:1",
                active_plugins = { session_ = { pid = "app:plugin:1", restart_count = 0, status = "running" } },
                connected_clients = { ["app:client:1"] = true },
                client_count = 1,
                retiring = true,
                pg_scopes = { ["app:scope"] = { opaque = true } },
                pg_groups = { ["workspace.1"] = "app:scope" },
                routes = { session_message = { prefix = "session_", config = { prefix = "session_",
                    process_id = "app:session", auto_start = true }, topic = "message" } },
                route_count = 1,
            })

            test.eq(snapshot.relay_user_upgrade, true)
            test.is_nil((snapshot :: any).routes)
            test.eq(snapshot.active_plugins.session_.pid, "app:plugin:1")
            test.eq(snapshot.connected_clients["app:client:1"], true)
            test.eq(snapshot.pg_groups["workspace.1"], "app:scope")

            local encoded = user._encode_upgrade_state(snapshot)
            test.is_string(encoded)
            local decoded = user._decode_upgrade_state(encoded)
            test.eq(decoded.active_plugins.session_.pid, "app:plugin:1")
            test.eq(decoded.connected_clients["app:client:1"], true)
            test.is_true(decoded.retiring)
        end)
    end)
end

return { run = test.run_cases(define_tests) }
