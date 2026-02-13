local time = require("time")

local actor = {}

-- Allow for process injection for testing
actor._process = nil

-- Internal constants
local INTERNAL_CHANNEL_BUFFER = 100

type ExitSignal = {
    _actor_exit: boolean,
    result: any,
}

type NextSignal = {
    _actor_next: boolean,
    topic: string?,
    payload: any?,
}

type InternalMessage = {
    type: string,
    topic: string?,
    payload: any?,
    from: string?,
}

type ChannelInfo = {
    chan: any,
    handler: (any, any, any, any) -> any,
}

type SelectResult = {
    ok: boolean,
    channel: any?,
    value: any?,
}

-- Actor control flow helpers
local function is_exit(result: any): boolean
    return type(result) == "table" and result._actor_exit == true
end

local function is_next(result: any): boolean
    return type(result) == "table" and result._actor_next == true
end

function actor.exit(result: any): ExitSignal
    return {
        _actor_exit = true,
        result = result
    }
end

function actor.next(topic: string?, payload: any?): NextSignal
    return {
        _actor_next = true,
        topic = topic,
        payload = payload
    }
end

local function get_process(): any
    if actor._process then
        return actor._process
    end

    return {
        inbox = function() return process.inbox() end,
        events = function() return process.events() end,
        send = function(dest, topic, payload) return process.send(dest, topic, payload) end,
        pid = function() return process.pid() end,
        event = process.event
    }
end

function actor.new(initial_state: any, handlers: any): any
    if type(handlers) ~= "table" then
        error("handlers must be a table")
    end

    local function run_loop(state: any): any
        local proc = get_process()
        local inbox = proc.inbox()
        local events = proc.events()
        local internal_channel = channel.new(INTERNAL_CHANNEL_BUFFER)

        -- Extract topic handlers from main handlers
        local topic_handlers: {[string]: (any, any, any, any) -> any} = {}
        for name, handler in pairs(handlers) do
            if type(handler) == "function" and not name:match("^__") then
                topic_handlers[name] = handler
            end
        end

        -- Channel management
        local registered_channels: {[string]: ChannelInfo} = {}
        local channel_to_id: {[any]: string} = {}

        -- Wait functionality state
        local topic_listeners: {[string]: any} = {}

        -- Initial select cases
        local select_cases = {
            inbox:case_receive(),
            events:case_receive(),
            internal_channel:case_receive()
        }

        local function rebuild_select_cases()
            select_cases = {
                inbox:case_receive(),
                events:case_receive(),
                internal_channel:case_receive()
            }

            for _, channel_info in pairs(registered_channels) do
                table.insert(select_cases, channel_info.chan:case_receive())
            end
        end

        local function register_channel(chan: any, handler: (any, any, any, any) -> any): boolean
            if not chan or type(handler) ~= "function" then
                error("Channel and handler function must be provided")
            end

            local channel_id = tostring(chan)
            registered_channels[channel_id] = {chan = chan, handler = handler}
            channel_to_id[chan] = channel_id
            rebuild_select_cases()
            return true
        end

        local function unregister_channel(chan: any): boolean
            if not chan then return false end

            local channel_id = tostring(chan)
            if registered_channels[channel_id] then
                registered_channels[channel_id] = nil
                channel_to_id[chan] = nil
                rebuild_select_cases()
                return true
            end
            return false
        end

        local function add_handler(topic: string, handler: (any, any, any, any) -> any): boolean
            if not topic or type(handler) ~= "function" then
                error("Topic name and handler function must be provided")
            end
            topic_handlers[topic] = handler
            return true
        end

        local function remove_handler(topic: string): boolean
            if topic_handlers[topic] then
                topic_handlers[topic] = nil
                return true
            end
            return false
        end

        local function async(fn: () -> any): boolean
            coroutine.spawn(function()
                local result = fn()

                if is_next(result) then
                    internal_channel:send({
                        type = "__next",
                        topic = result.topic,
                        payload = result.payload,
                        from = "async"
                    })
                end
            end)

            return true
        end

        -- Ensure shared listener exists for topic
        local function ensure_topic_listener(topic: string)
            if not topic_listeners[topic] then
                local listener = process.listen(topic)
                topic_listeners[topic] = listener
            end
        end

        -- Wait for message on topic with timeout
        local function wait(topic: string, timeout: number): (any, string?)
            if not topic then
                return nil, "Invalid topic"
            end

            ensure_topic_listener(topic)

            local timer = time.timer(timeout)

            local result = channel.select({
                topic_listeners[topic]:case_receive(),
                timer:channel():case_receive()
            })

            timer:stop()

            if result.channel == timer:channel() then
                return nil, "timeout"
            else
                return result.value, nil
            end
        end

        local function process_topic_message(topic, payload, from)
            local current_topic = topic
            local current_payload = payload

            while true do
                local handler = topic_handlers[current_topic]
                if not handler and current_topic ~= "__default" then
                    handler = handlers.__default
                end

                if not handler then
                    return nil
                end

                local reply = handler(state, current_payload, current_topic, from)

                if is_next(reply) then
                    local next_topic = reply.topic

                    if reply.payload ~= nil then
                        current_payload = reply.payload
                    end

                    if not next_topic then
                        if handlers.__default then
                            current_topic = "__default"
                        else
                            return nil
                        end
                    else
                        current_topic = next_topic
                    end
                else
                    return reply
                end
            end
        end

        -- Expose state methods
        state.register_channel = register_channel
        state.unregister_channel = unregister_channel
        state.add_handler = add_handler
        state.remove_handler = remove_handler
        state.next = actor.next
        state.async = async
        state.wait = wait

        -- Initialize actor if handler exists
        if handlers.__init then
            local init_result = handlers.__init(state)
            if is_exit(init_result) then
                return init_result.result
            end

            if is_next(init_result) then
                internal_channel:send({
                    type = "__next",
                    topic = init_result.topic,
                    payload = init_result.payload,
                    from = "init"
                })
            end
        end

        -- Main actor loop
        while true do
            local result: SelectResult = channel.select(select_cases)
            if not result.ok then
                break
            end

            -- Handle system events
            if result.channel == events and result.value then
                local event = result.value
                local event_kind = event.kind
                local from = event.from

                if handlers.__on_event then
                    local exit_result = handlers.__on_event(state, event, event_kind, from)
                    if is_exit(exit_result) then
                        return exit_result.result
                    end

                    if is_next(exit_result) then
                        internal_channel:send({
                            type = "__next",
                            topic = exit_result.topic,
                            payload = exit_result.payload,
                            from = "event_handler"
                        })
                    end
                end

                if event_kind == proc.event.CANCEL and handlers.__on_cancel then
                    local exit_result = handlers.__on_cancel(state, event, event_kind, from)
                    if is_exit(exit_result) then
                        return exit_result.result
                    end
                end
            end

            -- Handle inbox messages
            if result.channel == inbox and result.value then
                local msg = result.value
                local exit_result = process_topic_message(msg:topic(), msg:payload():data(), msg:from())
                if is_exit(exit_result) then
                    return exit_result.result
                end
            end

            -- Handle internal messages
            if result.channel == internal_channel and result.value then
                local msg = result.value

                if msg.type == "__next" and msg.topic then
                    local exit_result = process_topic_message(msg.topic, msg.payload, msg.from)
                    if is_exit(exit_result) then
                        return exit_result.result
                    end
                elseif handlers.__on_internal_message then
                    local exit_result = handlers.__on_internal_message(state, msg.payload, msg.type, msg.from)
                    if is_exit(exit_result) then
                        return exit_result.result
                    end
                end
            end

            -- Handle registered channels
            local channel_id = channel_to_id[result.channel]
            if channel_id then
                local channel_info = registered_channels[channel_id]
                local value = result.value
                local is_ok = result.ok

                local reply = channel_info.handler(state, value, is_ok, channel_id)

                if not is_ok then
                    registered_channels[channel_id] = nil
                    channel_to_id[result.channel] = nil
                    rebuild_select_cases()
                end

                if is_exit(reply) then
                    return reply.result
                end

                if is_next(reply) then
                    internal_channel:send({
                        type = "__next",
                        topic = reply.topic,
                        payload = reply.payload,
                        from = "channel_handler"
                    })
                end
            end
        end

        return {status = "completed"}
    end

    return {
        run = function() return run_loop(initial_state) end
    }
end

return actor
