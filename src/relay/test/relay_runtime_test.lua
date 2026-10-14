local test = require("test")
local time = require("time")
local json = require("json")
local security = require("security")
local consts = require("consts")
local registry = require("registry")

local sequence = 0
local PIPELINE_WINDOW = 32
local function pipeline_slot(index: any, first: number, last: number): number?
    if type(index) ~= "number" or index < first or index > last or index % 1 ~= 0 then return nil end
    return index - first + 1
end

local function receive(ch: any): any
    local timer = time.timer(3 * time.SECOND)
    local result = channel.select({ ch:case_receive(), timer:channel():case_receive() })
    timer:stop()
    assert(result.channel == ch and result.ok, "relay runtime response deadline")
    return result.value
end

local function with_hub(plugin_id: string, body: any, active_pid: string?, session_pid: string?, saved_client_count: number?, hub_source: string?): any
    sequence = sequence + 1
    local user_id = "relay-runtime-" .. process.pid() .. "-" .. sequence
    local actor = security.new_actor(user_id, {})
    local scope, scope_err = security.named_scope("app:user")
    assert(scope, tostring(scope_err))
    local config = consts.get_config()
    config.runtime_observer = process.pid()
    local welcome = process.listen(consts.CLIENT_TOPICS.WELCOME)
    local response = process.listen("relay.runtime.response")
    local errors = process.listen(consts.CLIENT_TOPICS.ERROR)
    local started = process.listen("relay.runtime.started")
    local events = process.events()
    local args = {
            user_id = user_id, user_metadata = { fixture = true },
            config = config, plugins = {
                runtime_ = { prefix = "runtime_", process_id = plugin_id,
                    host = config.user_hub_host, auto_start = false },
            },
        }
    if active_pid or session_pid then
        args.relay_user_upgrade = true
        args.active_plugins = {}
        if active_pid then
            args.active_plugins.runtime_ = { pid = active_pid, status = "running", restart_count = 0 }
        end
        if session_pid then
            args.active_plugins.session_ = { pid = session_pid, status = "running", restart_count = 0 }
        end
        args.connected_clients = {}
        args.client_count = 0
        if saved_client_count ~= nil then
            args.connected_clients[process.pid()] = true
            args.client_count = saved_client_count
        end
        args.pg_groups = {}
        args = (json.encode(args))
    end
    local pid, err = process.with_context({}):with_actor(actor):with_scope(scope):spawn_monitored(
        hub_source or consts.USER_HUB_PROCESS_ID, assert(config.user_hub_host), args)
    assert(pid, tostring(err))
    local function join()
        assert(process.send(pid, consts.WS_TOPICS.JOIN, { client_pid = process.pid() }))
        return receive(welcome)
    end
    local function send(value)
        local encoded, encode_err = json.encode(value)
        assert(encoded, tostring(encode_err))
        assert(process.send(pid, consts.WS_TOPICS.MESSAGE, encoded))
    end
    local children = {}
    local function startup()
        local plugin = receive(started)
        assert(process.monitor(plugin.pid))
        children[plugin.pid] = true
        return plugin
    end
    local ok: boolean, result: any = pcall(body, pid, user_id, join, send, response, errors, startup)
    process.send(pid, consts.WS_TOPICS.CANCEL, {})
    local stopped = false
    local timer = time.timer(3 * time.SECOND)
    while not stopped or next(children) do
        local selected = channel.select({ events:case_receive(), timer:channel():case_receive() })
        if selected.channel == timer:channel() then break end
        local event = selected.value
        if event.kind == process.event.EXIT and children[event.from] then
            children[event.from] = nil
            if event.result.error then
                result = (not ok and tostring(result) .. "; " or "") .. "plugin exited: " .. tostring(event.result.error)
                ok = false
            end
        end
        if event.from == pid and event.kind == process.event.EXIT then
            stopped = true
            if event.result.error then
                ok, result = false, tostring(result or "") .. "; hub exited: " .. tostring(event.result.error)
            end
        end
    end
    timer:stop()
    local cleanup_timed_out = not stopped or next(children) ~= nil
    if cleanup_timed_out then
        if not stopped then process.terminate(pid) end
        for child in pairs(children) do process.terminate(child) end
        local forced_deadline = time.timer(3 * time.SECOND)
        while not stopped or next(children) do
            local selected = channel.select({ events:case_receive(), forced_deadline:channel():case_receive() })
            if selected.channel == forced_deadline:channel() then break end
            local event = selected.value
            if event.kind == process.event.EXIT then
                if event.from == pid then stopped = true end
                children[event.from] = nil
            end
        end
        forced_deadline:stop()
    end
    local leaked = not stopped or next(children) ~= nil
    for _, ch in ipairs({ welcome, response, errors, started }) do process.unlisten(ch) end
    if leaked then error(tostring(result or "") .. "; relay fixture termination deadline") end
    if not ok then error(result) end
    assert(not cleanup_timed_out and not leaked, "relay hub or plugin cleanup deadline")
    return result
end

local function define_tests()
    test.describe("relay runtime", function()
        test.it("starts plugins lazily and preserves command routing and payload fields", function()
            with_hub("app:relay_runtime_plugin", function(pid, user_id, join, send, response, _, started)
                local welcome = join()
                test.eq(welcome.plugins[1].status, "not_started")
                send({ type = "runtime_echo", data = { nested = { value = 42 } },
                    request_id = "request-1", session_id = "session-1", start_token = "start-1",
                    attention_context_enabled = true, context = { label = "fixture" } })
                local boot = started()
                local result = receive(response)
                test.eq(result.plugin_pid, boot.pid)
                test.eq(result.topic, "echo")
                test.eq(result.from, pid)
                test.eq(result.user_id, user_id)
                test.eq(result.user_metadata.fixture, true)
                test.eq(result.payload.conn_pid, (process.pid()))
                test.eq(result.payload.type, "runtime_echo")
                test.eq(result.payload.data.nested.value, 42)
                test.eq(result.payload.request_id, "request-1")
                test.eq(result.payload.session_id, "session-1")
                test.eq(result.payload.start_token, "start-1")
                test.eq(result.payload.attention_context_enabled, true)
                test.eq(result.payload.context.label, "fixture")
            end)
        end)
        test.it("delivers commands after disconnect and reconnect using the same plugin", function()
            with_hub("app:relay_runtime_plugin", function(pid, _, join, send, response, _, started)
                join()
                send({ type = "runtime_echo", data = "before", request_id = "before" })
                local boot = started()
                test.eq(receive(response).payload.data, "before")
                assert(process.send(pid, consts.WS_TOPICS.LEAVE, { client_pid = process.pid() }))
                local welcome = join()
                test.eq(welcome.client_count, 1)
                test.eq(welcome.plugins[1].status, "running")
                send({ type = "runtime_echo", data = "after", request_id = "after", session_id = "reconnected" })
                local result = receive(response)
                test.eq(result.plugin_pid, boot.pid)
                test.eq(result.payload.data, "after")
                test.eq(result.payload.request_id, "after")
                test.eq(result.payload.session_id, "reconnected")
            end)
        end)
        test.it("keeps client ownership, options, actor and queued commands through a real live update", function()
            local original = assert(registry.get("app:relay_upgrade_user"))
            local function apply_entry(entry: any)
                local snapshot = assert(registry.snapshot())
                local changes = snapshot:changes()
                changes:update(entry)
                local version, err = changes:apply()
                assert(version, tostring(err))
            end
            local loaded = process.listen("relay.runtime.upgrade_loaded")
            local options = process.listen("relay.runtime.upgrade_options")
            local fence = process.listen("relay.runtime.foreign_fence")
            local ok, err = pcall(with_hub, "app:relay_runtime_plugin", function(pid, user_id, join, send, response, _, started)
                join()
                send({type = "runtime_echo", request_id = "before-upgrade"})
                local plugin = started()
                test.eq(receive(response).payload.request_id, "before-upgrade")
                for index = 1, 16 do
                    send({type = "runtime_echo", request_id = "queued-" .. index, data = {index = index}})
                end
                local updated = assert(registry.get("app:relay_upgrade_user"))
                updated.data.method = "upgraded"
                apply_entry(updated)
                for index = 17, 32 do
                    send({type = "runtime_echo", request_id = "queued-" .. index, data = {index = index}})
                end
                local incarnation = receive(loaded)
                test.eq(incarnation.pid, pid)
                test.eq(incarnation.plugin_pid, plugin.pid)
                test.eq(incarnation.clients[process.pid()], true)
                local seen = {}
                for _ = 1, 32 do
                    local delivered = receive(response)
                    local index = delivered.payload.data.index
                    local slot = pipeline_slot(index, 1, 32)
                    test.not_nil(slot)
                    test.is_nil(seen[slot])
                    seen[slot] = true
                    test.eq(delivered.payload.request_id, "queued-" .. index)
                    test.eq(delivered.plugin_pid, plugin.pid)
                    test.eq(delivered.payload.conn_pid, (process.pid()))
                end
                assert(process.send(pid, "relay.runtime.upgrade_probe", "options-after-upgrade"))
                local live = receive(options)
                test.eq(live.token, "options-after-upgrade")
                test.eq(live.pid, pid)
                test.eq(live.actor_id, user_id)
                test.eq(live.options.upgradable, true)
                test.eq(live.options.trap_links, true)
                local foreign_pid, foreign_err = process.spawn_monitored("app:relay_upgrade_foreign", "app:processes", {hub_pid = pid})
                assert(foreign_pid, tostring(foreign_err))
                local isolated, isolation_err = pcall(function()
                    test.eq(receive(fence).pid, foreign_pid)
                    send({type = "runtime_echo", request_id = "owned-after-upgrade"})
                    local owned = receive(response)
                    test.eq(owned.payload.request_id, "owned-after-upgrade", "the foreign sender must not dispatch after live update")
                    test.eq(owned.plugin_pid, plugin.pid)
                end)
                local canceled, cancel_err = process.cancel(foreign_pid, "2s")
                assert(canceled, tostring(cancel_err))
                if not isolated then error(isolation_err) end
            end, nil, nil, nil, "app:relay_upgrade_user")
            local restored, restore_err = pcall(apply_entry, original)
            for _, listener in ipairs({loaded, options, fence}) do process.unlisten(listener) end
            if not ok then error(err) end
            assert(restored, tostring(restore_err))
        end)
        test.it("routes repeated commands and stops on a process cancellation event", function()
            with_hub("app:relay_runtime_plugin", function(pid, _, join, send, response, _, started)
                join()
                local plugin_pid
                for index = 1, 8 do
                    send({ type = "runtime_echo", request_id = tostring(index), data = index })
                    if index == 1 then plugin_pid = started().pid end
                    local result = receive(response)
                    test.eq(result.plugin_pid, plugin_pid)
                    test.eq(result.payload.request_id, tostring(index))
                    test.eq(result.payload.data, index)
                end
                assert(process.cancel(pid, "2s"))
            end)
        end)
        test.it("preserves independent payloads across pipelined commands", function()
            with_hub("app:relay_runtime_plugin", function(pid, _, join, send, response, _, started)
                join()
                for index = 1, 16 do
                    send({ type = "runtime_echo", request_id = tostring(index), session_id = "pipeline",
                        data = { index = index }, start_token = "token-" .. index,
                        attention_context_enabled = index % 2 == 0, context = { index = index } })
                end
                local plugin = started()
                local seen = {}
                for _ = 1, 16 do
                    local value = receive(response)
                    local index = value.payload.data.index
                    test.is_true(index >= 1 and index <= 16 and not seen[index])
                    seen[index] = true
                    test.eq(value.plugin_pid, plugin.pid)
                    test.eq(value.from, pid)
                    test.eq(value.topic, "echo")
                    test.eq(value.payload.conn_pid, (process.pid()))
                    test.eq(value.payload.type, "runtime_echo")
                    test.eq(value.payload.request_id, tostring(index))
                    test.eq(value.payload.session_id, "pipeline")
                    test.eq(value.payload.start_token, "token-" .. index)
                    test.eq(value.payload.attention_context_enabled, index % 2 == 0)
                    test.eq(value.payload.context.index, index)
                end
            end)
        end)
        test.it("bounds pipeline identity slots by the window at high operation ids", function()
            local first = 4294967297
            test.eq(pipeline_slot(first, first, first + PIPELINE_WINDOW - 1), 1)
            test.eq(pipeline_slot(first + PIPELINE_WINDOW - 1, first, first + PIPELINE_WINDOW - 1), PIPELINE_WINDOW)
            test.is_nil(pipeline_slot(first - 1, first, first + PIPELINE_WINDOW - 1))
            test.is_nil(pipeline_slot(first + PIPELINE_WINDOW, first, first + PIPELINE_WINDOW - 1))
            test.is_nil(pipeline_slot(first + 0.5, first, first + PIPELINE_WINDOW - 1))
            test.is_nil(pipeline_slot("1", 1, PIPELINE_WINDOW))
        end)
        test.it("cancels pending disconnect shutdown when a client rejoins", function()
            local resumed = process.listen("resume")
            local shutdown = process.listen("shutdown")
            local ok, err = pcall(with_hub, "app:relay_runtime_plugin", function(pid, _, join)
                join()
                receive(resumed)
                assert(process.send(pid, consts.WS_TOPICS.LEAVE, { client_pid = process.pid() }))
                local early = time.timer(200 * time.MILLISECOND)
                local selected = channel.select({ shutdown:case_receive(), early:channel():case_receive() })
                early:stop()
                test.eq(selected.channel, early:channel(), "last LEAVE allows time for transport reconnection")
                test.eq(join().client_count, 1)
                receive(resumed)
                local deadline = time.timer(1500 * time.MILLISECOND)
                selected = channel.select({ shutdown:case_receive(), deadline:channel():case_receive() })
                deadline:stop()
                test.eq(selected.channel, deadline:channel(), "rejoining cancels the pending shutdown")
                assert(process.send(pid, consts.WS_TOPICS.LEAVE, { client_pid = process.pid() }))
                receive(shutdown)
            end, nil, process.pid())
            process.unlisten(resumed)
            process.unlisten(shutdown)
            if not ok then error(err) end
        end)
        test.it("counts a repeated JOIN once so the last LEAVE shuts down the session plugin", function()
            local resumed = process.listen("resume")
            local shutdown = process.listen("shutdown")
            local ok, err = pcall(with_hub, "app:relay_runtime_plugin", function(pid, _, join)
                test.eq(join().client_count, 1)
                receive(resumed)
                test.eq(join().client_count, 1, "A repeated JOIN must keep one membership")
                assert(process.send(pid, consts.WS_TOPICS.LEAVE, { client_pid = process.pid() }))
                receive(shutdown)
                test.eq(join().client_count, 1)
                receive(resumed)
            end, nil, process.pid())
            process.unlisten(resumed)
            process.unlisten(shutdown)
            if not ok then error(err) end
        end)
        for _, saved_count in ipairs({0, 1, 3}) do
            test.it("restores the membership count before the final LEAVE, saved count " .. saved_count, function()
                local shutdown = process.listen("shutdown")
                local ok, err = pcall(with_hub, "app:relay_runtime_plugin", function(pid, _, join)
                    test.eq(join().client_count, 1, "Restored memberships are the source of the client count")
                    assert(process.send(pid, consts.WS_TOPICS.LEAVE, { client_pid = process.pid() }))
                    receive(shutdown)
                end, nil, process.pid(), saved_count)
                process.unlisten(shutdown)
                if not ok then error(err) end
            end)
        end
        test.it("reports a real plugin startup failure and keeps the hub responsive", function()
            with_hub("app:missing_runtime_plugin", function(_, _, join, send, _, errors)
                join()
                send({ type = "runtime_echo", data = "first" })
                test.eq(receive(errors).error, consts.ERROR_CODES.PLUGIN_FAILED)
                send({ type = "runtime_echo", data = "second" })
                local error_message = receive(errors)
                test.eq(error_message.error, consts.ERROR_CODES.PLUGIN_FAILED)
                test.is_true(error_message.message:find("failed permanently", 1, true) ~= nil)
            end)
        end)
        test.it("reports delivery failure when a restored plugin pid has already exited", function()
            local events = process.events()
            local dead_pid, err = process.spawn_monitored("app:relay_runtime_finished_plugin", "app:processes")
            assert(dead_pid, tostring(err))
            while true do
                local event = receive(events)
                if event.from == dead_pid and event.kind == process.event.EXIT then break end
            end
            with_hub("app:relay_runtime_plugin", function(_, _, join, send, _, errors)
                test.eq(join().plugins[1].status, "running")
                send({ type = "runtime_echo", request_id = "stale-plugin", data = "delivery" })
                test.eq(receive(errors).error, consts.ERROR_CODES.PLUGIN_FAILED)
            end, dead_pid)
        end)
        test.it("keeps the hub responsive when a session plugin exits before disconnect shutdown", function()
            local events = process.events()
            local dead_pid = assert(process.spawn_monitored("app:relay_runtime_finished_plugin", "app:processes"))
            while true do
                local event = receive(events)
                if event.from == dead_pid and event.kind == process.event.EXIT then break end
            end
            with_hub("app:relay_runtime_plugin", function(pid, _, join, send, response, _, started)
                join()
                assert(process.send(pid, consts.WS_TOPICS.LEAVE, { client_pid = process.pid() }))
                time.sleep("1200ms")
                test.eq(join().client_count, 1)
                send({ type = "runtime_echo", request_id = "after-session-exit" })
                started()
                test.eq(receive(response).payload.request_id, "after-session-exit")
            end, nil, dead_pid)
        end)
        test.it("rejects invalid JSON and missing or unknown commands without stopping", function()
            with_hub("app:relay_runtime_plugin", function(pid, _, join, send, _, errors)
                join()
                assert(process.send(pid, consts.WS_TOPICS.MESSAGE, "{"))
                test.eq(receive(errors).error, consts.ERROR_CODES.INVALID_JSON)
                send({ data = "missing type" })
                test.eq(receive(errors).error, consts.ERROR_CODES.UNKNOWN_COMMAND)
                send({ type = "missing_echo" })
                test.eq(receive(errors).error, consts.ERROR_CODES.PLUGIN_NOT_FOUND)
            end)
        end)
        test.it("keeps routing to the same plugin after invalid input and a rejected plugin topic", function()
            with_hub("app:relay_runtime_plugin", function(pid, _, join, send, response, errors, started)
                join()
                send({ type = "runtime_echo", request_id = "first", data = 1 })
                local plugin = started()
                test.eq(receive(response).payload.request_id, "first")
                assert(process.send(pid, consts.WS_TOPICS.MESSAGE, "{"))
                test.eq(receive(errors).error, consts.ERROR_CODES.INVALID_JSON)
                send({ type = "runtime_echo", request_id = "after-json", data = 2 })
                test.eq(receive(response).payload.request_id, "after-json")
                send(42)
                test.eq(receive(errors).error, consts.ERROR_CODES.UNKNOWN_COMMAND)
                send({ type = "runtime_echo", request_id = "after-type", data = 3 })
                test.eq(receive(response).payload.request_id, "after-type")
                send({ type = "runtime_@reserved", request_id = "reserved", data = 4 })
                local failure = receive(errors)
                test.eq(failure.error, consts.ERROR_CODES.PLUGIN_FAILED)
                test.contains(tostring(failure.message), "cannot send to @ topics")
                send({ type = "runtime_echo", request_id = "after-reserved", data = 5 })
                local after = receive(response)
                test.eq(after.payload.request_id, "after-reserved")
                test.eq(after.plugin_pid, plugin.pid)
            end)
        end)
        test.it("routes commands beyond the route cache bound and keeps rejecting invalid commands", function()
            with_hub("app:relay_runtime_plugin", function(_, _, join, send, response, errors, started)
                join()
                for index = 1, 80 do
                    send({ type = "runtime_echo_" .. index, request_id = tostring(index) })
                end
                started()
                local seen = {}
                for _ = 1, 80 do
                    local value = receive(response)
                    local request_id = value.payload.request_id
                    test.eq(value.topic, "echo_" .. request_id)
                    test.is_nil(seen[request_id])
                    seen[request_id] = true
                end
                send({ type = "runtime_echo_1", request_id = "cached" })
                local cached = receive(response)
                test.eq(cached.topic, "echo_1")
                test.eq(cached.payload.request_id, "cached")
                send({ type = 42 })
                test.eq(receive(errors).error, consts.ERROR_CODES.UNKNOWN_COMMAND)
                send({ type = "missing_echo" })
                test.eq(receive(errors).error, consts.ERROR_CODES.PLUGIN_NOT_FOUND)
                send({ type = "runtime_echo_80", request_id = "uncached" })
                test.eq(receive(response).topic, "echo_80")
            end)
        end)
        test.it("rejects non-object JSON and non-string command types without stopping", function()
            with_hub("app:relay_runtime_plugin", function(pid, _, join, send, _, errors)
                join()
                assert(process.send(pid, consts.WS_TOPICS.MESSAGE, "null"))
                test.eq(receive(errors).error, consts.ERROR_CODES.UNKNOWN_COMMAND)
                for _, value in ipairs({ 42, true, false, "scalar", {}, { type = 42 }, { type = true }, { type = "" } }) do
                    send(value)
                    test.eq(receive(errors).error, consts.ERROR_CODES.UNKNOWN_COMMAND)
                end
            end)
        end)
    end)
end

return { run = test.run_cases(define_tests) }
