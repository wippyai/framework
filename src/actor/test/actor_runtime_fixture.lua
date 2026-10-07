local actor = require("actor")
local time = require("time")

local function run(args)
    local reply_topic = args.topic .. ".reply"
    local proceed_topic = args.topic .. ".proceed"
    local listener = process.listen(reply_topic)
    local proceed = process.listen(proceed_topic)
    local closed = channel.new(1)
    local state = { count = 0, closures = 0 }
    local function notify(value)
        assert(process.send(args.parent, args.topic, value))
    end
    local result = actor.new(state, {
        __init = function(s)
            if args.scenario == "closure" then
                s.register_channel(closed, function(current, value, ok)
                    if not ok then
                        current.closures = current.closures + 1
                        notify({ phase = "closed", value = value, ok = ok })
                    end
                end)
                closed:close()
            elseif args.scenario == "deadline" or args.scenario == "late" then
                local value, err = s.wait(reply_topic, 5 * time.MILLISECOND)
                notify({ phase = "expired", value = value, error = err })
                if args.scenario == "deadline" then
                    return actor.exit({ status = "deadline", error = err })
                end
                local _, proceed_err = s.wait(proceed_topic, 2 * time.SECOND)
                assert(not proceed_err, proceed_err)
                local late, late_err = s.wait(reply_topic, 2 * time.SECOND)
                return actor.exit({ status = "late", value = late, error = late_err })
            elseif args.scenario == "drain_exit" or args.scenario == "drain_next" then
                local buffered = channel.new(4)
                s.values = {}
                s.register_channel(buffered, function(current, value, ok)
                    if ok then
                        current.values[#current.values + 1] = value
                        return
                    end
                    current.closures = current.closures + 1
                    local outcome = { status = "drained", values = current.values, closures = current.closures }
                    if args.scenario == "drain_next" then return actor.next("next_result", outcome) end
                    return actor.exit(outcome)
                end)
                buffered:send(1)
                buffered:send(false)
                buffered:send("x")
                buffered:close()
            elseif args.scenario == "dispatch" then
                notify({ phase = "ready" })
            elseif args.scenario == "init_next" then
                return actor.next("next_result", { scenario = args.scenario })
            elseif args.scenario == "async_next" then
                s.async(function() return actor.next("next_result", { scenario = args.scenario }) end)
            elseif args.scenario == "deferred_async" then
                coroutine.spawn(function()
                    assert(proceed:receive(), "deferred async proceed missing")
                    s.async(function() return actor.next("next_result", { scenario = args.scenario }) end)
                end)
                notify({ phase = "ready" })
            elseif args.scenario == "channel_next" then
                s.register_channel(closed, function(_, value, ok)
                    assert(ok, "runtime channel closed before next")
                    return actor.next("next_result", value)
                end)
                closed:send({ scenario = args.scenario })
            elseif args.scenario == "event_next" then
                notify({ phase = "ready" })
            elseif args.scenario == "cancel" then
                notify({ phase = "waiting" })
                s.wait(reply_topic, 20 * time.MILLISECOND)
            else
                for index = 1, args.count or 1 do
                    notify({ phase = "waiting", index = index })
                    local value, err = s.wait(reply_topic, 2 * time.SECOND)
                    if err then return actor.exit({ status = "failed", error = err }) end
                    s.count = s.count + 1
                    s.last = value
                end
                return actor.exit({ status = "replied", count = s.count, value = s.last })
            end
        end,
        ping = function(s, payload, topic, from)
            return actor.exit({ status = "inbox", closures = s.closures,
                removed = not s.unregister_channel(closed), payload = payload, topic = topic, from = from })
        end,
        dispatch = function(s, payload)
            s.count = s.count + 1
            assert(process.send(args.parent, args.topic, { count = s.count, value = payload }))
        end,
        register_after_error = function(s)
            assert(not pcall(error, "expected handler failure"))
            s.register_channel(closed, function(_, value, ok)
                return actor.exit({ status = "channel_after_error", value = value, ok = ok })
            end)
            closed:send("after caught error")
        end,
        next_result = function(_, payload, topic, from)
            return actor.exit({ status = "next", payload = payload, topic = topic, from = from })
        end,
        __on_event = function(_, event)
            if args.scenario == "event_next" and event.kind == process.event.CANCEL then
                return actor.next("next_result", { scenario = args.scenario })
            end
        end,
        __on_cancel = function()
            if args.scenario == "event_next" then return end
            return actor.exit({ status = "canceled" })
        end,
    }).run()
    process.unlisten(listener)
    process.unlisten(proceed)
    return result
end

local function resident(args)
    return actor.new({ count = 0 }, {
        __init = function()
            assert(process.send(args.parent, args.topic, { phase = "ready", pid = process.pid() }))
        end,
        dispatch = function(state, value)
            state.count = state.count + 1
            assert(process.send(args.parent, args.topic, { pid = process.pid(), count = state.count, value = value }))
        end,
        __on_cancel = function() return actor.exit({ status = "canceled" }) end,
    }).run()
end

return { run = run, resident = resident }
