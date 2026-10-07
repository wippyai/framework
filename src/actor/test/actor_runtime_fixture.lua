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
            elseif args.scenario == "dispatch" then
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
        __on_cancel = function()
            return actor.exit({ status = "canceled" })
        end,
    }).run()
    process.unlisten(listener)
    process.unlisten(proceed)
    return result
end

return { run = run }
