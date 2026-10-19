local test = require("test")
local central = require("central")
local time = require("time")
local consts = require("consts")

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
    test.describe("relay inactivity retirement", function()
        test.it("requests retirement once and never cancels a draining hub", function()
            local now = time.now()
            local hub = { hub_pid = "draining-hub", created_at = now, last_activity = now,
                client_count = 0 }
            local connected = { hub_pid = "connected-hub", created_at = now, last_activity = now,
                client_count = 1 }
            local cfg = config("app:user")
            cfg.user_hub_inactivity_timeout = "-1s"
            local state = { config = cfg, plugins = {}, total_hubs = 2,
                user_hubs = { member = hub, connected = connected } }
            local sent, cancelled = {}, 0
            mock("process.send", function(pid, topic)
                sent[#sent + 1] = { pid = pid, topic = topic }
                return true
            end)
            mock("process.cancel", function() cancelled = cancelled + 1; return true end)
            local ok, err = pcall(function()
                central._check_inactive_hubs(state)
                central._check_inactive_hubs(state)
                test.eq(#sent, 1)
                test.eq(sent[1].pid, "draining-hub")
                test.eq(sent[1].topic, consts.HUB_CONTROL.RETIRE)
                test.eq(cancelled, 0)
                test.is_true(hub.terminating)
                central._handle_activity_update(state, { user_id = "member", client_count = 1 }, "foreign")
                test.is_true(hub.terminating, "a foreign sender cannot cancel pending collection")
                central._handle_activity_update(state, { user_id = "member", client_count = 1 }, "draining-hub")
                test.is_false(hub.terminating)
                test.is_nil(hub.termination_started_at)
                central._check_inactive_hubs(state)
                test.eq(#sent, 1, "the reconnected hub is not collected")
            end)
            restore_mock("process.cancel")
            restore_mock("process.send")
            if not ok then error(err) end
        end)
        test.it("retries an undelivered retirement request on the next sweep", function()
            local now = time.now()
            local hub = { hub_pid = "unavailable-hub", created_at = now, last_activity = now, client_count = 0 }
            local cfg = config("app:user")
            cfg.user_hub_inactivity_timeout = "-1s"
            local sent = 0
            local state = { config = cfg, plugins = {}, total_hubs = 1, user_hubs = { member = hub } }
            mock("process.send", function() sent = sent + 1; return false, "unavailable" end)
            local ok, err = pcall(function()
                central._check_inactive_hubs(state)
                central._check_inactive_hubs(state)
                test.eq(sent, 2)
                test.is_nil(hub.terminating)
            end)
            restore_mock("process.send")
            if not ok then error(err) end
        end)
    end)
    test.describe("relay central identity", function()
        test.after_each(function() central._set_security_for_test(nil) end)
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

            test.is_nil(err)
            test.not_nil(actor)
            test.not_nil(scope)
            test.eq(actor:id(), "admin@wippy.local")
            test.eq(meta.security_groups[1], "app.security:admin")
            test.eq(calls.scope_id, "app.security:admin")
            central._set_security_for_test(nil)
        end)

        test.it("falls back to the configured user scope for legacy relay metadata", function()
            local calls = {}
            central._set_security_for_test(fake_security(calls))
            local actor, scope, meta, err = central._identity_from_metadata(config("app.security:user"), "member@wippy.local", {})

            test.is_nil(err)
            test.not_nil(actor)
            test.not_nil(scope)
            test.eq(actor:id(), "member@wippy.local")
            test.is_table(meta)
            test.eq(calls.scope_id, "app.security:user")
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

            test.eq(snapshot.relay_upgrade, true)
            test.is_string(snapshot.user_hubs["admin@wippy.local"].created_at)

            local encoded = central._encode_upgrade_state(snapshot)
            test.is_string(encoded)
            local decoded = central._decode_upgrade_state(encoded)
            local restored = central._restore_hubs(decoded)
            local hub = restored["admin@wippy.local"]
            test.eq(hub.hub_pid, "app:hub:1")
            test.eq(hub.client_count, 2)
            test.eq(hub.created_at:format_rfc3339(), now:format_rfc3339())
        end)
    end)
end

return { run = test.run_cases(define_tests) }
