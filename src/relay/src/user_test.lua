local test = require("test")
local time = require("time")
local consts = require("consts")
local security = require("security")
local user = require("user")

local function define_tests()
    test.describe("relay user hub", function()
        test.it("sends a legacy-compatible welcome payload on join", function()
            local actor = security.new_actor("relay-user-test@wippy.local", {})
            local scope = security.named_scope("app:user")

            local hub_pid, spawn_err = process.with_context({})
                :with_actor(actor)
                :with_scope(scope)
                :spawn_linked_monitored(
                    consts.USER_HUB_PROCESS_ID,
                    "wippy.terminal:host",
                    {
                        user_id = "relay-user-test@wippy.local",
                        user_metadata = {},
                        plugins = {},
                        config = consts.get_config(),
                    }
                )

            test.expect(spawn_err).to_be_nil()
            test.expect(hub_pid).not_to_be_nil()

            local welcome = process.listen(consts.CLIENT_TOPICS.WELCOME)
            process.send(hub_pid :: string, consts.WS_TOPICS.JOIN, { client_pid = process.pid() })

            local timer = time.after(3000 * time.MILLISECOND)
            local res = channel.select({ welcome:case_receive(), timer:case_receive() })

            test.expect(res.channel == timer).to_be_falsy()
            test.expect(res.value).not_to_be_nil()
            test.expect(res.value.user_id).to_equal("relay-user-test@wippy.local")
            test.expect(type(res.value.plugins)).to_equal("table")
            test.expect(type(res.value.active_session_ids)).to_equal("table")
            test.expect(#res.value.active_session_ids).to_equal(0)
            test.expect(res.value.active_sessions).to_equal(0)

            process.cancel(hub_pid :: string, consts.CANCEL_TIMEOUT)
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
                pg_scopes = { ["app:scope"] = { opaque = true } },
                pg_groups = { ["workspace.1"] = "app:scope" },
            })

            test.expect(snapshot.relay_user_upgrade).to_equal(true)
            test.expect(snapshot.active_plugins.session_.pid).to_equal("app:plugin:1")
            test.expect(snapshot.connected_clients["app:client:1"]).to_equal(true)
            test.expect(snapshot.pg_groups["workspace.1"]).to_equal("app:scope")

            local encoded = user._encode_upgrade_state(snapshot)
            test.expect(type(encoded)).to_equal("string")
            local decoded = user._decode_upgrade_state(encoded)
            test.expect(decoded.active_plugins.session_.pid).to_equal("app:plugin:1")
            test.expect(decoded.connected_clients["app:client:1"]).to_equal(true)
        end)
    end)
end

return { run = test.run_cases(define_tests) }
