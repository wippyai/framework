local test = require("test")
local actor = require("actor")
local time = require("time")

local function mock_channel()
    return {
        send = function(self, value) return true end,
        receive = function(self) return nil, false end,
        case_receive = function(self) return self end
    }
end

local function mock_message(topic: string, payload: any, from: string?): any
    return {
        from = function() return from or "sender_pid" end,
        topic = function() return topic end,
        payload = function()
            return {
                data = function() return payload end
            }
        end
    }
end

local function mock_process(inbox_chan: any, events_chan: any): any
    return {
        inbox = function() return inbox_chan end,
        events = function() return events_chan end,
        send = function(dest, topic, payload) return true end,
        pid = function() return "test-pid" end,
        event = {
            CANCEL = "pid.cancel",
            EXIT = "pid.exit",
            LINK_DOWN = "pid.link.down"
        }
    }
end

-- Creates a mock channel module with sequential select responses
local function mock_channel_module(internal_chan: any, responses: {any}): any
    local select_count = 0
    return {
        new = function(size) return internal_chan end,
        select = function(cases)
            select_count = select_count + 1
            return responses[select_count] or { ok = false }
        end
    }
end

local function define_tests()
    test.describe("actor", function()
    test.after_each(function()
        actor._process = nil
    end)

    test.describe("actor.exit and actor.next", function()
        test.it("actor.exit creates exit signal with result", function()
            local result = { status = "completed" }
            local signal = actor.exit(result)

            test.is_true(signal._actor_exit)
            test.eq(signal.result, result)
        end)

        test.it("actor.next creates next signal with topic only", function()
            local signal = actor.next("next_handler")

            test.is_true(signal._actor_next)
            test.eq(signal.topic, "next_handler")
            test.is_nil(signal.payload)
        end)

        test.it("actor.next creates next signal with topic and payload", function()
            local payload = { value = 42 }
            local signal = actor.next("next_handler", payload)

            test.is_true(signal._actor_next)
            test.eq(signal.topic, "next_handler")
            test.eq(signal.payload, payload)
        end)
    end)

    test.describe("actor.new", function()
        test.it("creates actor with run method", function()
            local a = actor.new({ count = 0 }, {})
            test.not_nil(a)
            test.is_function(a.run)
        end)

        test.it("errors when handlers is not a table", function()
            test.throws(function()
                actor.new({}, "not a table")
            end)
        end)
    end)

    test.describe("message handling", function()
        test.it("handles inbox messages with correct argument order", function()
            local received_state, received_payload, received_topic, received_from

            local inbox_chan = mock_channel()
            local events_chan = mock_channel()
            local internal_chan = mock_channel()

            local msg = mock_message("status", { command = "get_status" }, "sender_pid")

            local original_channel = _G.channel
            _G.channel = mock_channel_module(internal_chan, {
                { ok = true, channel = inbox_chan, value = msg }
            })

            actor._process = mock_process(inbox_chan, events_chan)

            local initial_state = { value = 42 }
            local a = actor.new(initial_state, {
                status = function(state, payload, topic, from)
                    received_state = state
                    received_payload = payload
                    received_topic = topic
                    received_from = from
                    return actor.exit({ status = "ok" })
                end
            })

            local result = a.run()
            _G.channel = original_channel

            test.eq(received_state, initial_state)
            test.eq(received_payload.command, "get_status")
            test.eq(received_topic, "status")
            test.eq(received_from, "sender_pid")
            test.eq(result.status, "ok")
        end)

        test.it("unmatched topic falls through to __default handler", function()
            local default_called = false
            local received_topic

            local inbox_chan = mock_channel()
            local events_chan = mock_channel()
            local internal_chan = mock_channel()

            local msg = mock_message("unknown_topic", { value = 1 })

            local original_channel = _G.channel
            _G.channel = mock_channel_module(internal_chan, {
                { ok = true, channel = inbox_chan, value = msg }
            })

            actor._process = mock_process(inbox_chan, events_chan)

            local a = actor.new({}, {
                __default = function(state, payload, topic, from)
                    default_called = true
                    received_topic = topic
                    return actor.exit({ status = "default" })
                end
            })

            local result = a.run()
            _G.channel = original_channel

            test.is_true(default_called)
            test.eq(received_topic, "unknown_topic")
            test.eq(result.status, "default")
        end)
    end)

    test.describe("event handling", function()
        test.it("handles system events with correct argument order", function()
            local received_state, received_event, received_kind, received_from

            local inbox_chan = mock_channel()
            local events_chan = mock_channel()
            local internal_chan = mock_channel()

            local mock_event = {
                kind = "pid.exit",
                from = "other_pid",
                at = time.now(),
            }

            local original_channel = _G.channel
            _G.channel = mock_channel_module(internal_chan, {
                { ok = true, channel = events_chan, value = mock_event }
            })

            actor._process = mock_process(inbox_chan, events_chan)

            local initial_state = { value = 0 }
            local a = actor.new(initial_state, {
                __on_event = function(state, event, kind, from)
                    received_state = state
                    received_event = event
                    received_kind = kind
                    received_from = from
                    return actor.exit({ status = "handled" })
                end
            })

            local result = a.run()
            _G.channel = original_channel

            test.eq(received_state, initial_state)
            test.eq(received_event, mock_event)
            test.eq(received_kind, "pid.exit")
            test.eq(received_from, "other_pid")
            test.eq(result.status, "handled")
        end)

        test.it("handles cancel events with __on_cancel handler", function()
            local cancel_called = false
            local received_kind, received_from

            local inbox_chan = mock_channel()
            local events_chan = mock_channel()
            local internal_chan = mock_channel()

            local mock_event = {
                kind = "pid.cancel",
                from = "parent_pid",
                at = time.now(),
            }

            local original_channel = _G.channel
            _G.channel = mock_channel_module(internal_chan, {
                { ok = true, channel = events_chan, value = mock_event }
            })

            actor._process = mock_process(inbox_chan, events_chan)

            local a = actor.new({ value = 0 }, {
                __on_cancel = function(state, event, kind, from)
                    cancel_called = true
                    received_kind = kind
                    received_from = from
                    return actor.exit({ status = "cancelled" })
                end
            })

            local result = a.run()
            _G.channel = original_channel

            test.is_true(cancel_called)
            test.eq(received_kind, "pid.cancel")
            test.eq(received_from, "parent_pid")
            test.eq(result.status, "cancelled")
        end)
    end)

    test.describe("init lifecycle", function()
        test.it("__init runs before main loop", function()
            local init_called = false

            local inbox_chan = mock_channel()
            local events_chan = mock_channel()
            local internal_chan = mock_channel()

            local original_channel = _G.channel
            _G.channel = mock_channel_module(internal_chan, {
                { ok = false }
            })

            actor._process = mock_process(inbox_chan, events_chan)

            local a = actor.new({}, {
                __init = function(state)
                    init_called = true
                    return nil
                end
            })

            a.run()
            _G.channel = original_channel

            test.is_true(init_called)
        end)

        test.it("__init returning actor.exit stops actor immediately", function()
            local inbox_chan = mock_channel()
            local events_chan = mock_channel()
            local internal_chan = mock_channel()

            local original_channel = _G.channel
            _G.channel = mock_channel_module(internal_chan, {})

            actor._process = mock_process(inbox_chan, events_chan)

            local a = actor.new({}, {
                __init = function(state)
                    return actor.exit({ status = "early_exit" })
                end
            })

            local result = a.run()
            _G.channel = original_channel

            test.eq(result.status, "early_exit")
        end)

        test.it("__init returning actor.next queues to internal channel", function()
            local internal_sent = nil

            local inbox_chan = mock_channel()
            local events_chan = mock_channel()
            local internal_chan = mock_channel()
            internal_chan.send = function(self, value)
                internal_sent = value
                return true
            end

            local original_channel = _G.channel
            _G.channel = mock_channel_module(internal_chan, {
                { ok = false }
            })

            actor._process = mock_process(inbox_chan, events_chan)

            local a = actor.new({}, {
                __init = function(state)
                    return actor.next("process_data", { value = 42 })
                end
            })

            a.run()
            _G.channel = original_channel

            test.not_nil(internal_sent)
            test.eq(internal_sent.type, "__next")
            test.eq(internal_sent.topic, "process_data")
            test.eq(internal_sent.payload.value, 42)
            test.eq(internal_sent.from, "init")
        end)
    end)

    test.describe("handler chaining", function()
        test.it("actor.next chains from one handler to another with modified payload", function()
            local second_payload

            local inbox_chan = mock_channel()
            local events_chan = mock_channel()
            local internal_chan = mock_channel()

            local msg = mock_message("first_topic", { value = 42 })

            local original_channel = _G.channel
            _G.channel = mock_channel_module(internal_chan, {
                { ok = true, channel = inbox_chan, value = msg }
            })

            actor._process = mock_process(inbox_chan, events_chan)

            local a = actor.new({ value = 0 }, {
                first_topic = function(state, payload, topic, from)
                    return actor.next("second_topic", { value = payload.value * 2 })
                end,
                second_topic = function(state, payload, topic, from)
                    second_payload = payload
                    return actor.exit({ value = payload.value })
                end
            })

            local result = a.run()
            _G.channel = original_channel

            test.eq(second_payload.value, 84)
            test.eq(result.value, 84)
        end)

        test.it("actor.next to nonexistent topic falls back to __default", function()
            local default_called = false
            local received_topic

            local inbox_chan = mock_channel()
            local events_chan = mock_channel()
            local internal_chan = mock_channel()

            local msg = mock_message("first_topic", { value = 42 })

            local original_channel = _G.channel
            _G.channel = mock_channel_module(internal_chan, {
                { ok = true, channel = inbox_chan, value = msg }
            })

            actor._process = mock_process(inbox_chan, events_chan)

            local a = actor.new({}, {
                first_topic = function(state, payload, topic, from)
                    return actor.next("nonexistent_topic")
                end,
                __default = function(state, payload, topic, from)
                    default_called = true
                    received_topic = topic
                    return actor.exit({ status = "handled_by_default" })
                end
            })

            local result = a.run()
            _G.channel = original_channel

            test.is_true(default_called)
            test.eq(received_topic, "nonexistent_topic")
            test.eq(result.status, "handled_by_default")
        end)

        test.it("actor.next with nil payload preserves original payload", function()
            local second_payload

            local inbox_chan = mock_channel()
            local events_chan = mock_channel()
            local internal_chan = mock_channel()

            local original_payload = { value = 42, extra = "data" }
            local msg = mock_message("first_topic", original_payload)

            local original_channel = _G.channel
            _G.channel = mock_channel_module(internal_chan, {
                { ok = true, channel = inbox_chan, value = msg }
            })

            actor._process = mock_process(inbox_chan, events_chan)

            local a = actor.new({}, {
                first_topic = function(state, payload, topic, from)
                    return actor.next("second_topic")
                end,
                second_topic = function(state, payload, topic, from)
                    second_payload = payload
                    return actor.exit({ status = "completed" })
                end
            })

            a.run()
            _G.channel = original_channel

            test.eq(second_payload, original_payload)
        end)
    end)

    test.describe("dynamic handler management", function()
        test.it("state.add_handler registers new topic handler", function()
            local dynamic_called = false

            local inbox_chan = mock_channel()
            local events_chan = mock_channel()
            local internal_chan = mock_channel()

            local msg = mock_message("dynamic_topic", { value = 42 })

            local original_channel = _G.channel
            _G.channel = mock_channel_module(internal_chan, {
                { ok = true, channel = inbox_chan, value = msg }
            })

            actor._process = mock_process(inbox_chan, events_chan)

            local a = actor.new({}, {
                __init = function(state)
                    state.add_handler("dynamic_topic", function(s, payload, topic, from)
                        dynamic_called = true
                        return actor.exit({ status = "dynamic" })
                    end)
                    return nil
                end
            })

            local result = a.run()
            _G.channel = original_channel

            test.is_true(dynamic_called)
            test.eq(result.status, "dynamic")
        end)

        test.it("state.remove_handler removes topic handler", function()
            local first_called = false
            local second_called = false

            local inbox_chan = mock_channel()
            local events_chan = mock_channel()
            local internal_chan = mock_channel()

            local msg = mock_message("dynamic_topic", { value = 42 })

            local original_channel = _G.channel
            _G.channel = mock_channel_module(internal_chan, {
                { ok = true, channel = inbox_chan, value = msg },
                { ok = true, channel = inbox_chan, value = msg },
                { ok = false }
            })

            actor._process = mock_process(inbox_chan, events_chan)

            local a = actor.new({}, {
                __init = function(state)
                    state.add_handler("dynamic_topic", function(s, payload, topic, from)
                        first_called = true
                        state.remove_handler("dynamic_topic")
                        state.add_handler("dynamic_topic", function(s2, payload2, topic2, from2)
                            second_called = true
                            return nil
                        end)
                        return nil
                    end)
                    return nil
                end
            })

            a.run()
            _G.channel = original_channel

            test.is_true(first_called)
            test.is_true(second_called)
        end)
    end)

    test.describe("channel management", function()
        test.it("state.register_channel adds channel to select cases", function()
            local handler_called = false
            local handler_value

            local inbox_chan = mock_channel()
            local events_chan = mock_channel()
            local internal_chan = mock_channel()
            local test_chan = mock_channel()

            local original_channel = _G.channel
            local original_tostring = _G.tostring

            _G.tostring = function(obj)
                if obj == test_chan then
                    return "test_channel_id"
                end
                return original_tostring(obj)
            end

            _G.channel = mock_channel_module(internal_chan, {
                { ok = true, channel = test_chan, value = "test_data" },
                { ok = false }
            })

            actor._process = mock_process(inbox_chan, events_chan)

            local a = actor.new({ test_channel = test_chan }, {
                __init = function(state)
                    state.register_channel(state.test_channel, function(s, value, ok, channel_name)
                        handler_called = true
                        handler_value = value
                        return nil
                    end)
                    return nil
                end
            })

            a.run()
            _G.channel = original_channel
            _G.tostring = original_tostring

            test.is_true(handler_called)
            test.eq(handler_value, "test_data")
        end)

        test.it("state.unregister_channel removes channel from select cases", function()
            local inbox_chan = mock_channel()
            local events_chan = mock_channel()
            local internal_chan = mock_channel()
            local test_chan = mock_channel()

            local original_channel = _G.channel
            local original_tostring = _G.tostring

            _G.tostring = function(obj)
                if obj == test_chan then
                    return "test_channel_id"
                end
                return original_tostring(obj)
            end

            _G.channel = mock_channel_module(internal_chan, {
                { ok = false }
            })

            actor._process = mock_process(inbox_chan, events_chan)

            local unregister_result
            local a = actor.new({ test_channel = test_chan }, {
                __init = function(state)
                    state.register_channel(state.test_channel, function() return nil end)
                    unregister_result = state.unregister_channel(state.test_channel)
                    return nil
                end
            })

            a.run()
            _G.channel = original_channel
            _G.tostring = original_tostring

            test.is_true(unregister_result)
        end)
    end)

    test.describe("async execution", function()
        test.it("state.async passes function to coroutine.spawn", function()
            local spawn_called = false
            local spawn_fn

            local inbox_chan = mock_channel()
            local events_chan = mock_channel()
            local internal_chan = mock_channel()

            local original_channel = _G.channel
            local original_coroutine = _G.coroutine

            _G.channel = mock_channel_module(internal_chan, {})
            _G.coroutine = {
                spawn = function(fn)
                    spawn_called = true
                    spawn_fn = fn
                    return true
                end
            }

            actor._process = mock_process(inbox_chan, events_chan)

            local a = actor.new({}, {
                __init = function(state)
                    state.async(function()
                        return { success = true }
                    end)
                    return actor.exit({ status = "initialized" })
                end
            })

            local result = a.run()
            _G.channel = original_channel
            _G.coroutine = original_coroutine

            test.is_true(spawn_called)
            test.is_function(spawn_fn)
            test.eq(result.status, "initialized")
        end)

        test.it("async result with actor.next sends to internal channel", function()
            local internal_sent

            local inbox_chan = mock_channel()
            local events_chan = mock_channel()
            local internal_chan = mock_channel()
            internal_chan.send = function(self, value)
                internal_sent = value
                return true
            end

            local original_channel = _G.channel
            local original_coroutine = _G.coroutine

            local captured_fn

            _G.channel = mock_channel_module(internal_chan, {})
            _G.coroutine = {
                spawn = function(fn)
                    captured_fn = fn
                    return true
                end
            }

            actor._process = mock_process(inbox_chan, events_chan)

            local a = actor.new({}, {
                __init = function(state)
                    state.async(function()
                        return actor.next("process_result", { data = "async_data" })
                    end)
                    return actor.exit({ status = "done" })
                end
            })

            a.run()

            -- Execute the captured spawn function to trigger the internal send
            captured_fn()

            _G.channel = original_channel
            _G.coroutine = original_coroutine

            test.not_nil(internal_sent)
            test.eq(internal_sent.type, "__next")
            test.eq(internal_sent.topic, "process_result")
            test.eq(internal_sent.payload.data, "async_data")
            test.eq(internal_sent.from, "async")
        end)
    end)
    end)
end

local run_cases = test.run_cases(define_tests)

local function run(options: any): any
    return run_cases(options)
end

return { run = run }
