local test = require("test")
local central = require("central")
local time = require("time")
local consts = require("consts")
local json = require("json")
local security = require("security")

local function receive(ch: any): any
    local timer = time.timer(3 * time.SECOND)
    local result = channel.select({ch:case_receive(), timer:channel():case_receive()})
    timer:stop()
    assert(result.channel == ch and result.ok, "hub authority response deadline")
    return result.value
end

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
    test.describe("relay authenticated session authority", function()
        test.it("keeps both authenticated clients on one hub across independent logins", function()
            local central_pid = assert(process.registry.lookup(consts.CENTRAL_HUB_REGISTRY_NAME))
            local user_id = "same-user-" .. process.pid()
            local observations = process.listen("test.isolation")
            local session = process.listen("relay.authority.session")
            local children, hubs, receipts = {}, {}, {}
            local function client_event(pid, topic)
                while true do
                    for index, receipt in ipairs(receipts) do
                        if receipt.client_pid == pid and receipt.topic == topic then
                            table.remove(receipts, index)
                            return receipt
                        end
                    end
                    local receipt = receive(observations)
                    receipts[#receipts + 1] = receipt
                    if receipt.kind == "client" then
                        if receipt.topic == consts.WS_TOPICS.CONTROL then
                            hubs[receipt.hub_pid] = true
                        end
                        test.neq(receipt.topic, consts.CLIENT_TOPICS.ERROR,
                            "an equivalent login must not retire a connected client's hub: " .. assert(json.encode(receipt)))
                    end
                end
            end
            local ok, err = pcall(function()
                local clients = {}
                local scope = assert(security.named_scope("app:user"))
                local policies = {}
                for _, policy in ipairs(scope:policies()) do policies[#policies + 1] = policy:id() end
                local first_hub
                for index = 1, 2 do
                    local pid = assert(process.spawn_linked_monitored("app:isolation_client", "app:processes", {
                        central_pid = central_pid, observer_pid = process.pid(), user_id = user_id,
                        scope_id = "app:user", scope_policy_ids = policies,
                        token_id = "token-" .. index, session_id = "session-" .. index,
                        user_metadata = {observer_pid = process.pid(), groups = {"reader"},
                            login_time = "2026-01-01T00:00:0" .. index .. "Z"},
                    }))
                    children[#children + 1] = pid
                    clients[index] = pid
                    local hub = client_event(pid, consts.WS_TOPICS.CONTROL).hub_pid
                    if not first_hub then first_hub = hub end
                    test.eq(hub, first_hub, "equal grants must reuse the current hub across logins")
                    assert(process.send(pid, "test.join", {}))
                    test.eq(client_event(pid, consts.CLIENT_TOPICS.WELCOME).payload.client_count, index)
                    if index == 1 then
                        assert(process.send(pid, "test.send", {topic = consts.WS_TOPICS.MESSAGE,
                            data = assert(json.encode({type = "session_hold"}))}))
                        test.is_true(receive(session).busy)
                    end
                end
                assert(process.send(first_hub, "test.same-user-update", {value = "fresh"}))
                for _, pid in ipairs(clients) do
                    test.eq(client_event(pid, "test.same-user-update").payload.value, "fresh")
                end
                test.eq(process.registry.lookup(consts.USER_HUB_REGISTRY_PREFIX .. user_id), first_hub)
            end)
            for _, pid in ipairs(children) do assert(process.cancel(pid, consts.CANCEL_TIMEOUT)) end
            for pid in pairs(hubs) do assert(process.cancel(pid, consts.CANCEL_TIMEOUT)) end
            process.unlisten(observations)
            process.unlisten(session)
            if not ok then error(err) end
        end)
        for _, connected in ipairs({false, true}) do
            test.it("refreshes composed authority while earlier work drains, connected " .. tostring(connected), function()
                local central_pid = assert(process.registry.lookup(consts.CENTRAL_HUB_REGISTRY_NAME))
                local user_id = "authority-" .. process.pid() .. "-" .. tostring(connected)
                local listeners = {}
                for _, topic in ipairs({consts.WS_TOPICS.CONTROL, consts.CLIENT_TOPICS.WELCOME,
                    consts.CLIENT_TOPICS.ERROR, "relay.authority.session"}) do
                    listeners[#listeners + 1] = process.listen(topic)
                end
                local control, welcome, failures, session = listeners[1], listeners[2], listeners[3], listeners[4]
                local events = process.events()
                local hubs = {}
                local exited = {}
                local function await_exit(pid)
                    while not exited[pid] do
                        local event = receive(events)
                        if event.kind == process.event.EXIT then
                            test.is_nil(event.result.error, tostring(event.result.error))
                            exited[event.from] = true
                        end
                    end
                end
                local function login(policies)
                    assert(process.send(central_pid, consts.WS_TOPICS.JOIN, {
                        client_pid = process.pid(), metadata = {user_id = user_id, scope_id = "app:user",
                            scope_policy_ids = policies, user_metadata = {observer_pid = process.pid()}},
                    }))
                    local hub = receive(control).target_pid
                    if not hubs[hub] then assert(process.monitor(hub)); hubs[hub] = true end
                    return hub
                end
                local function join(hub)
                    assert(process.send(hub, consts.WS_TOPICS.JOIN, {client_pid = process.pid()}))
                    test.eq(receive(welcome).user_id, user_id)
                end
                local function command(hub, kind)
                    local encoded = assert(json.encode({type = "session_" .. kind}))
                    assert(process.send(hub, consts.WS_TOPICS.MESSAGE, encoded))
                end
                local ok, err = pcall(function()
                    local scope = assert(security.named_scope("app:user"))
                    local policies = {}
                    for _, policy in ipairs(scope:policies()) do policies[#policies + 1] = policy:id() end
                    local old = login(policies)
                    join(old)
                    command(old, "hold")
                    local held = receive(session)
                    test.is_false(held.writable)
                    assert(process.monitor(held.pid))
                    if not connected then
                        assert(process.send(old, consts.WS_TOPICS.LEAVE, {client_pid = process.pid()}))
                        test.eq(receive(session).topic, "shutdown")
                    end
                    policies[#policies + 1] = "app:authority_write"
                    local current = login(policies)
                    test.neq(current, old, "renewed login must not inherit the earlier scope")
                    join(current)
                    command(current, "probe")
                    local probe = receive(session)
                    local shutdown
                    if probe.topic == "shutdown" then shutdown = probe; probe = receive(session) end
                    test.eq(probe.hub_pid, current)
                    test.eq(probe.actor_id, user_id)
                    test.is_true(probe.writable, "new session work uses the authenticated composed scope")
                    test.eq(login(policies), current, "unchanged authenticated authority reuses the hub")
                    test.eq(process.registry.lookup(consts.USER_HUB_REGISTRY_PREFIX .. user_id), current)
                    if connected then
                        shutdown = shutdown or receive(session)
                        test.eq(shutdown.topic, "shutdown")
                        test.is_true(shutdown.busy, "accepted work is not cancelled")
                        test.eq(receive(failures).error, consts.ERROR_CODES.HUB_CREATION_FAILED)
                    end
                    command(old, "probe")
                    assert(process.send(old, consts.WS_TOPICS.JOIN, {client_pid = process.pid()}))
                    test.eq(receive(failures).error, consts.ERROR_CODES.HUB_CREATION_FAILED)
                    assert(process.send(held.pid, "release", {}))
                    test.eq(receive(session).topic, "release")
                    await_exit(held.pid)
                    await_exit(old)
                    test.eq(process.registry.lookup(consts.USER_HUB_REGISTRY_PREFIX .. user_id), current)
                    command(current, "probe")
                    test.is_true(receive(session).writable)
                end)
                for pid in pairs(hubs) do
                    if not exited[pid] then
                        local cancelled, cancel_err = process.cancel(pid, consts.CANCEL_TIMEOUT)
                        if not cancelled then
                            ok, err = false, tostring(err or "") .. "; hub cleanup: " .. tostring(cancel_err)
                        else
                            await_exit(pid)
                        end
                    end
                end
                for _, listener in ipairs(listeners) do process.unlisten(listener) end
                if not ok then error(err) end
            end)
        end
    end)
    test.describe("relay hub authority", function()
        local state: any
        local spawned: any
        local sent: any
        local names: any
        local cancelled: any
        test.before_each(function()
            state = {config = config("app:user"), plugins = {}, user_hubs = {}, total_hubs = 0}
            spawned, sent, names, cancelled = {}, {}, {}, {}
            local fake = fake_security({})
            fake.policy = function(id)
                return {id = function() return id end}, nil
            end
            fake.new_scope = function(policies)
                return {policies = function() return policies end}
            end
            fake.named_scope = function(id)
                return fake.new_scope({assert(fake.policy(id))}), nil
            end
            central._set_security_for_test(fake)
            mock("process.with_context", function()
                local builder = {}
                function builder:with_actor(actor) self.actor = actor; return self end
                function builder:with_scope(scope) self.scope = scope; return self end
                function builder:spawn_linked_monitored(_, _, args)
                    self.args = args
                    spawned[#spawned + 1] = self
                    return "hub-" .. #spawned
                end
                return builder
            end)
            mock("process.send", function(pid, topic, payload)
                sent[#sent + 1] = {pid = pid, topic = topic, payload = payload}
                return true
            end)
            mock("process.cancel", function(pid) cancelled[#cancelled + 1] = pid; return true end)
            local registry = {}
            for key, value in pairs(process.registry) do registry[key] = value end
            registry.register = function(name, pid) names[name] = pid; return true end
            registry.unregister = function(name) names[name] = nil; return true end
            mock("process.registry", registry)
        end)
        test.after_each(function() central._set_security_for_test(nil) end)

        for _, change in ipairs({"grant", "revoke", "actor metadata", "named scope"}) do
            test.it("retires the earlier frame after a change to " .. change, function()
                local first = {scope_policy_ids = {"app:read"}, user_metadata = {groups = {"reader"}}}
                local second = {scope_policy_ids = {"app:read", "app:write"}, user_metadata = {groups = {"reader"}}}
                if change == "revoke" then first, second = second, first end
                if change == "actor metadata" then
                    second.scope_policy_ids = {"app:read"}
                    second.user_metadata.groups = {"editor"}
                elseif change == "named scope" then
                    first = {scope_id = "app:reader"}
                    second = {scope_id = "app:editor"}
                end
                local old = assert(central._get_or_create_user_hub(state, "member", first))
                local current = central._get_or_create_user_hub(state, "member", second)
                test.neq(current, old, "a changed authenticated identity requires a new frame")
                test.eq(#spawned, 2)
                test.eq(#sent, 1)
                test.eq(sent[1].pid, old)
                test.eq(sent[1].topic, consts.HUB_CONTROL.RETIRE)
                test.eq(spawned[2].actor:meta().groups, second.user_metadata and second.user_metadata.groups)
                test.eq(spawned[2].scope:policies()[1]:id(), second.scope_policy_ids and second.scope_policy_ids[1] or second.scope_id)
                test.eq(names[consts.USER_HUB_REGISTRY_PREFIX .. "member"], current)
                central._handle_activity_update(state, {user_id = "member", client_count = 9}, old)
                central._handle_process_event(state, {kind = process.event.EXIT, from = old})
                test.eq(state.user_hubs.member.hub_pid, current)
                test.eq(state.user_hubs.member.client_count, 0)
                test.eq(state.total_hubs, 1)
            end)
        end
        test.it("reuses equivalent policy sets and actor metadata across a hot upgrade", function()
            local old = central._get_or_create_user_hub(state, "member", {
                scope_policy_ids = {"app:read", "app:write"}, user_metadata = {groups = {"reader"}, nested = {a = 1, b = 2}},
            })
            state.user_hubs = central._restore_hubs(central._decode_upgrade_state(
                central._encode_upgrade_state(central._snapshot_state(state))))
            local current = central._get_or_create_user_hub(state, "member", {
                scope_policy_ids = {"app:write", "app:read", "app:read"}, user_metadata = {nested = {b = 2, a = 1}, groups = {"reader"}},
            })
            test.eq(current, old)
            test.eq(#spawned, 1)
            test.eq(#sent, 0)
        end)
        test.it("validates new login metadata before reusing the cached hub", function()
            local old = central._get_or_create_user_hub(state, "member", {})
            local ok = pcall(central._get_or_create_user_hub, state, "member", {scope_policy_ids = "invalid"})
            test.is_false(ok, "cached authority cannot bypass authenticated identity validation")
            test.eq(state.user_hubs.member.hub_pid, old)
            test.eq(#spawned, 1)
            test.eq(#sent, 0)
        end)
        test.it("contains a failed admission and continues serving another user", function()
            local ok = pcall(central._handle_client_connection, state, "bad-client", {user_id = "bad", scope_policy_ids = "invalid"})
            test.is_true(ok, "one failed login must not escape the central message handler")
            test.eq(sent[1].pid, "bad-client")
            test.eq(sent[1].payload.error, consts.ERROR_CODES.HUB_CREATION_FAILED)
            central._handle_client_connection(state, "good-client", {user_id = "good"})
            test.eq(sent[2].pid, "good-client")
            test.eq(sent[2].payload.target_pid, state.user_hubs.good.hub_pid)
        end)
        for _, failure in ipairs({"spawn", "unregister", "register", "retire"}) do
            test.it("preserves the admitted hub when replacement fails at " .. failure, function()
                local old = central._get_or_create_user_hub(state, "member", {scope_policy_ids = {"app:read"}})
                if failure == "spawn" then
                    mock("process.with_context", function()
                        local builder = {}
                        function builder:with_actor(_) return self end
                        function builder:with_scope(_) return self end
                        function builder:spawn_linked_monitored() return nil, "unavailable" end
                        return builder
                    end)
                elseif failure == "retire" then
                    mock("process.send", function() return false, "unavailable" end)
                else
                    local registry = {}
                    for key, value in pairs(process.registry) do registry[key] = value end
                    if failure == "unregister" then
                        registry.unregister = function() return false, "unavailable" end
                    else
                        registry.register = function(name, pid)
                            if pid ~= old then return false, "unavailable" end
                            names[name] = pid
                            return true
                        end
                    end
                    mock("process.registry", registry)
                end
                local ok, result = pcall(central._get_or_create_user_hub, state, "member", {scope_policy_ids = {"app:write"}})
                if failure == "spawn" then
                    test.is_true(ok)
                    test.is_nil(result)
                    test.eq(#cancelled, 0)
                else
                    test.is_false(ok)
                    test.contains(tostring(result), "unavailable")
                    test.eq(cancelled[1], "hub-2", "only the unadmitted replacement may be cancelled")
                end
                test.eq(state.user_hubs.member.hub_pid, old)
                test.eq(state.total_hubs, 1)
                test.eq(names[consts.USER_HUB_REGISTRY_PREFIX .. "member"], old,
                    "failed replacement must preserve the admitted hub's canonical binding")
            end)
        end
        test.it("retires a restored hub whose original identity is unknown", function()
            local now = time.now()
            state.user_hubs.member = {hub_pid = "earlier-hub", created_at = now, last_activity = now, client_count = 0}
            state.total_hubs = 1
            local snapshot = central._snapshot_state(state)
            test.is_nil(snapshot.user_hubs.member.identity)
            state.user_hubs = central._restore_hubs(central._decode_upgrade_state(central._encode_upgrade_state(snapshot)))
            local current = central._get_or_create_user_hub(state, "member", {})
            test.neq(current, "earlier-hub")
            test.eq(sent[1].pid, "earlier-hub")
            test.eq(sent[1].topic, consts.HUB_CONTROL.RETIRE)
            test.eq(state.total_hubs, 1)
        end)
    end)
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
        test.it("preserves the authenticated composed scope instead of its group name", function()
            local calls = {}
            local fake = fake_security(calls)
            fake.policy = function(id)
                calls.policy_id = id
                return {id = function() return id end}, nil
            end
            fake.new_scope = function(policies) return {policies = policies} end
            central._set_security_for_test(fake)
            local _, scope, _, err = central._identity_from_metadata(config("app:user"), "member", {
                scope_id = "app:user", scope_policy_ids = {"app:composed_module_access"},
            })
            central._set_security_for_test(nil)
            test.is_nil(err, tostring(err))
            test.is_nil(calls.scope_id, "a named group drops composed policies")
            test.eq(calls.policy_id, "app:composed_module_access")
            test.eq(scope.policies[1].id(), "app:composed_module_access")
        end)
        test.it("preserves an empty authenticated scope", function()
            local calls = {}
            local fake = fake_security(calls)
            fake.new_scope = function(policies) return {policies = policies} end
            central._set_security_for_test(fake)
            local _, scope, _, err = central._identity_from_metadata(config("app:user"), "member", {
                scope_id = "app:user", scope_policy_ids = {},
            })
            central._set_security_for_test(nil)
            test.is_nil(err, tostring(err))
            test.is_nil(calls.scope_id)
            test.eq(#scope.policies, 0)
        end)
        test.it("refuses an unreadable composed policy without selecting another scope", function()
            local calls = {}
            local fake = fake_security(calls)
            local failure = errors.new({kind = errors.PERMISSION_DENIED, message = "policy access denied"})
            fake.policy = function() return nil, failure end
            central._set_security_for_test(fake)
            local actor, scope, _, err = central._identity_from_metadata(config("app:user"), "member", {
                scope_id = "app:user", scope_policy_ids = {"app:composed_module_access"},
            })
            central._set_security_for_test(nil)
            test.is_nil(actor)
            test.is_nil(scope)
            test.is_nil(calls.scope_id)
            test.is_true(errors.is(err, errors.PERMISSION_DENIED), tostring(err))
        end)

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
