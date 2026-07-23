local test = require("test")
local central = require("central")
local time = require("time")

local function fake_security(calls: any): any
    return {
        new_actor = function(user_id: string, meta: any)
            calls.actor_id = user_id
            calls.actor_meta = meta
            return {
                id = function() return user_id end,
                meta = function() return meta end,
            }
        end,
        named_scope = function(scope_id: string)
            calls.scope_id = scope_id
            return { id = scope_id }, nil
        end,
    }
end

local function config(scope_id: string)
    return {
        max_connections_per_user = 10,
        user_hub_inactivity_timeout = "5m",
        user_hub_host = "wippy.terminal:host",
        user_security_scope = scope_id,
        gc_check_interval = "1m",
        heartbeat_interval = "30s",
        message_queue_size = 100,
        queue_multiplier = 2,
    }
end

local function define_tests()
    test.describe("relay central identity", function()
        test.it("uses the authenticated scope id when relay metadata carries it", function()
            local calls = {}
            central._set_security_for_test(fake_security(calls))
            local actor, scope, meta, err = central._identity_from_metadata(config("fallback:scope"), "admin@wippy.local", {
                scope_id = "app.security:admin",
                user_metadata = {
                    security_groups = { "app.security:admin", "app.security:user" },
                    email = "admin@wippy.local",
                },
            })

            test.expect(err).to_be_nil()
            test.expect(actor).not_to_be_nil()
            test.expect(scope).not_to_be_nil()
            test.expect(actor:id()).to_equal("admin@wippy.local")
            test.expect(meta.security_groups[1]).to_equal("app.security:admin")
            test.expect(calls.scope_id).to_equal("app.security:admin")
            central._set_security_for_test(nil)
        end)

        test.it("falls back to the configured user scope for legacy relay metadata", function()
            local calls = {}
            central._set_security_for_test(fake_security(calls))
            local actor, scope, meta, err = central._identity_from_metadata(config("app.security:user"), "member@wippy.local", {})

            test.expect(err).to_be_nil()
            test.expect(actor).not_to_be_nil()
            test.expect(scope).not_to_be_nil()
            test.expect(actor:id()).to_equal("member@wippy.local")
            test.expect(type(meta)).to_equal("table")
            test.expect(calls.scope_id).to_equal("app.security:user")
            central._set_security_for_test(nil)
        end)
    end)

    test.describe("relay central hot upgrade state", function()
        test.it("serializes hub timestamps and restores the same child pids", function()
            local now = time.now()
            local snapshot = central._snapshot_state({
                config = config("app.security:user"),
                plugins = {},
                user_hubs = {
                    ["admin@wippy.local"] = {
                        hub_pid = "app:hub:1",
                        created_at = now,
                        last_activity = now,
                        client_count = 2,
                    },
                },
                total_hubs = 1,
            })

            test.expect(snapshot.relay_upgrade).to_equal(true)
            test.expect(type(snapshot.user_hubs["admin@wippy.local"].created_at)).to_equal("string")

            local encoded = central._encode_upgrade_state(snapshot)
            test.expect(type(encoded)).to_equal("string")
            local decoded = central._decode_upgrade_state(encoded)
            local restored = central._restore_hubs(decoded)
            local hub = restored["admin@wippy.local"]
            test.expect(hub.hub_pid).to_equal("app:hub:1")
            test.expect(hub.client_count).to_equal(2)
            test.expect(hub.created_at:format_rfc3339()).to_equal(now:format_rfc3339())
        end)
    end)
end

return { run = test.run_cases(define_tests) }
