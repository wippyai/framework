# Actor

Actor pattern library for message-passing concurrency with topic-based routing.

## Installation

```yaml
entries:
  - name: actor
    kind: ns.dependency
    component: wippy/actor
    version: "*"
```

## Basic Usage

```lua
local actor = require("actor")

local initial_state = {
    counter = 0
}

local handlers = {
    increment = function(state, payload, topic, from)
        state.counter = state.counter + (payload.amount or 1)
    end,

    get_count = function(state, payload, topic, from)
        process.send(from, "count_result", {count = state.counter})
    end,

    stop = function(state)
        return actor.exit({final_count = state.counter})
    end
}

local a = actor.new(initial_state, handlers)
return a:run()
```

## Handlers

### Topic Handlers

Functions without `__` prefix handle messages by topic name:

```lua
local handlers = {
    ping = function(state, payload, topic, from)
        process.send(from, "pong", {})
    end,

    echo = function(state, payload, topic, from)
        process.send(from, "echo_reply", payload)
    end
}
```

### Special Handlers

```lua
local handlers = {
    __init = function(state)
        -- Called once when actor starts
        state.start_time = os.time()
    end,

    __default = function(state, payload, topic, from)
        -- Handles unmatched topics
    end,

    __on_event = function(state, event, kind, from)
        -- Handles system events (CANCEL, etc.)
    end,

    __on_cancel = function(state, event, kind, from)
        -- Handles cancellation specifically
        return actor.exit({reason = "cancelled"})
    end,

    __on_internal_message = function(state, payload, msg_type, from)
        -- Handles internal async results
    end
}
```

## Control Flow

### Exit Actor

```lua
function handlers.shutdown(state, payload)
    return actor.exit({status = "done", data = state.data})
end
```

### Chain to Another Handler

```lua
function handlers.validate(state, payload)
    if payload.valid then
        return actor.next("process", payload)
    end
    return actor.next("reject", {reason = "invalid"})
end

function handlers.process(state, payload)
    -- Process validated payload
end

function handlers.reject(state, payload)
    -- Handle rejection
end
```

## State Methods

Available on the state object:

### Dynamic Handler Registration

```lua
function handlers.__init(state)
    state.add_handler("custom_topic", function(s, payload, topic, from)
        -- Handle custom topic
    end)
end

function handlers.cleanup(state)
    state.remove_handler("custom_topic")
end
```

### Channel Registration

```lua
function handlers.__init(state)
    local my_channel = channel.new(10)

    state.register_channel(my_channel, function(s, value, ok, channel_id)
        if ok then
            -- Process channel value
        else
            -- Channel closed
        end
    end)

    state.my_channel = my_channel
end

function handlers.stop_channel(state)
    state.unregister_channel(state.my_channel)
end
```

### Async Operations

```lua
function handlers.start_background(state, payload)
    state.async(function()
        -- Long running operation
        local result = do_work()
        return actor.next("work_done", result)
    end)
end

function handlers.work_done(state, payload)
    state.result = payload
end
```

### Wait for Message

```lua
function handlers.request_and_wait(state, payload)
    process.send(payload.target, "request", {id = 123})

    local response, err = state.wait("response", 5000)  -- 5 second timeout
    if err then
        return actor.next("timeout", {})
    end

    state.response = response
end
```

## Process Events

The actor automatically handles process inbox and system events channel:

```lua
local handlers = {
    __on_event = function(state, event, kind, from)
        if kind == process.event.CANCEL then
            return actor.exit({reason = "cancelled"})
        end
    end
}
```

## Complete Example

```lua
local actor = require("actor")

local handlers = {
    __init = function(state)
        state.items = {}
        state.async(function()
            return actor.next("ready", {})
        end)
    end,

    ready = function(state)
        process.send(state.parent, "actor_ready", {pid = process.pid()})
    end,

    add_item = function(state, payload)
        table.insert(state.items, payload.item)
        return actor.next("notify_change", {})
    end,

    notify_change = function(state)
        if state.subscriber then
            process.send(state.subscriber, "items_changed", {count = #state.items})
        end
    end,

    subscribe = function(state, payload, topic, from)
        state.subscriber = from
    end,

    get_items = function(state, payload, topic, from)
        process.send(from, "items_list", {items = state.items})
    end,

    __on_cancel = function(state)
        return actor.exit({items = state.items})
    end
}

local a = actor.new({parent = process.parent()}, handlers)
return a:run()
```
