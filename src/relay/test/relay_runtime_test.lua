local test = require("test")
local time = require("time")
local env = require("env")
local benchmark_report = require("benchmark")
local json = require("json")
local security = require("security")
local consts = require("consts")

local sequence = 0
local function receive(ch: any): any
    local timer = time.timer(3 * time.SECOND)
    local result = channel.select({ ch:case_receive(), timer:channel():case_receive() })
    timer:stop()
    assert(result.channel == ch and result.ok, "relay runtime response deadline")
    return result.value
end

local function with_hub(plugin_id: string, body: any, active_pid: string?): any
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
    if active_pid then
        args.relay_user_upgrade = true
        args.active_plugins = { runtime_ = { pid = active_pid, status = "running", restart_count = 0 } }
        args.connected_clients = {}
        args.client_count = 0
        args.pg_groups = {}
        args = (json.encode(args))
    end
    local pid, err = process.with_context({}):with_actor(actor):with_scope(scope):spawn_monitored(
        consts.USER_HUB_PROCESS_ID, assert(config.user_hub_host), args)
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
            if event.result.error then ok, result = false, tostring(event.result.error) end
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

local function benchmark(options)
    options = options or {}
    local count = tonumber(options.iterations) or 100
    local samples = tonumber(options.samples) or 1
    local warmup = tonumber(options.warmup) or 0
    return with_hub("app:relay_runtime_plugin", function(_, _, join, send, response, _, started)
        join()
        send({ type = "runtime_echo", request_id = "startup", data = 0 })
        started()
        assert(receive(response).payload.request_id == "startup")
        local durations = {}
        for iteration = 1, warmup + samples do
            local began = time.now()
            for index = 1, count do
                local operation = (iteration - 1) * count + index
                send({ type = "runtime_echo", request_id = tostring(operation), session_id = "benchmark", data = operation })
                local value = receive(response)
                assert(value.payload.request_id == tostring(operation) and value.payload.data == operation,
                    "relay roundtrip mismatch")
            end
            local elapsed = time.now():sub(began):seconds() * 1000
            if iteration > warmup then durations[#durations + 1] = elapsed end
        end
        return { operations = count, duration_ms = durations[1], samples_ms = durations }
    end)
end

local function benchmark_cases()
    test.describe("relay_roundtrip benchmark", function()
        local samples = tonumber((env.get("WIPPY_BENCH_SAMPLES")))
        if not samples then
            test.it_skip("requires WIPPY_BENCH_SAMPLES", function() end)
            return
        end
        test.it("measures verified runtime roundtrips", function()
            local size = tonumber((env.get("WIPPY_BENCH_SIZE"))) or 1
            local warmup = tonumber((env.get("WIPPY_BENCH_WARMUP"))) or 5
            assert(samples > 0 and size > 0 and warmup >= 0, "invalid benchmark configuration")
            local result = benchmark({ iterations = size, samples = samples, warmup = warmup })
            test.eq(result.operations, size)
            test.eq(#result.samples_ms, samples)
            local report, report_err = benchmark_report.report({
                name = "relay_roundtrip", size = size, operations_per_sample = size, samples_ms = result.samples_ms,
            })
            test.not_nil(report, tostring(report_err))
        end)
    end)
end

return { run = test.run_cases(define_tests), benchmark = test.run_cases(benchmark_cases), workload = benchmark }
