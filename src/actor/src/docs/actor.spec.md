# Actor Library for Wippy Runtime

The Actor Library provides a simple and flexible way to build processes using the actor model pattern in the Wippy Runtime environment. This guide explains how to use the library effectively.

## Basic Usage

### Creating an Actor

```lua
local actor = require("actor")

local function run()
    -- Initial state
    local state = {
        pid = process.pid(),
        count = 0
    }
    
    -- Create the actor with state and handlers
    local my_actor = actor.new(state, {
        -- Topic handler
        message = function(state, msg)
            state.count = state.count + 1
            print("Received message:", msg)
            
                            -- You can respond if the message includes a reply_to
            if msg.reply_to then
                process.send(msg.reply_to, "response", {
                    status = "ok",
                    count = state.count
                })
            end
        end,
        
        -- Cancellation handler
        __on_cancel = function(state)
            print("Process received cancel signal")
            return actor.exit({ status = "shutdown" })
        end
    })
    
    -- Run the actor loop
    return my_actor.run()
end

return { run = run }
```

### Handler Types

There are several types of handlers you can define:

1. **Topic Handlers**: Named functions that handle specific message topics
2. **Special Handlers**:
    - `__init`: Called when the actor starts
    - `__on_cancel`: Handles process cancellation
    - `__on_event`: Handles all system events (exit, cancel, link_down)
    - `__default`: Catches messages with topics that don't have specific handlers

## Working with Custom Channels

### Registering Channels

The actor library allows you to register custom channels:

```lua
-- Inside a handler or during initialization
local time = require("time")

-- Create a timer channel
local timer = time.ticker("1s")

-- Register the channel with a handler
state.register_channel(timer, function(state, value, ok)
    if ok then
        -- Timer fired
        state.count = state.count + 1
        print("Timer fired, count:", state.count)
    else
        -- Timer channel closed
        print("Timer channel closed")
    end
end)
```

### Unregistering Channels

You can manually unregister channels when needed:

```lua
-- Unregister a channel
state.unregister_channel(timer)
```

Note: Channels are automatically unregistered when they close.

## Handler Management

You can dynamically add and remove topic handlers at runtime:

```lua
-- Add a new topic handler
state.add_handler("new_topic", function(state, payload)
    print("Handling new topic:", payload)
    return { status = "processed" }
end)

-- Remove a topic handler
state.remove_handler("old_topic")
```

## Custom Process Implementation

The actor library supports custom process implementations:

```lua
-- Custom process implementation
local custom_process = {
    inbox = function() return my_custom_inbox() end,
    events = function() return my_custom_events() end,
    send = function(dest, topic, payload) return my_custom_send(dest, topic, payload) end,
    pid = function() return my_custom_pid() end,
    event = my_custom_event_types
}

-- Create actor with custom process
local my_actor = actor.new(state, handlers, custom_process)
```

## Common Patterns

### Request-Response Pattern

```lua
-- Handler for request
request = function(state, msg)
    -- Process request
    local result = process_request(msg.data)
    
    -- Send response if reply_to is provided
    if msg.reply_to then
        process.send(msg.reply_to, "response", {
            status = "ok",
            result = result
        })
    end
end
```

### Working with Timers

```lua
local time = require("time")

-- In your initialization handler
__init = function(state)
    -- Create and register a timer
    local timer = time.ticker("5s")
    state.register_channel(timer, function(state, _, ok)
        if ok then
            print("Periodic task running...")
            perform_periodic_task(state)
        end
    end)
end
```

### Using the Registry

```lua
-- Register process name for easy discovery
process.registry.register("my_service")

-- Inside a handler to send to a registered process
process.send("my_service", "message", payload)
```

## Advanced Patterns

### Supervision

```lua
-- Use trap_links to handle child process failures
process.set_options({ trap_links = true })

-- Spawn a linked child process
local child_pid = process.spawn_linked("app:child", "system:processes", args)

-- Handle link down events
__on_event = function(state, event)
    if event.kind == process.event.LINK_DOWN then
        print("Child process down:", event.from)
        -- Restart child process
        state.child_pid = process.spawn_linked("app:child", "system:processes", args)
    end
end
```

### Graceful Shutdown

```lua
__on_cancel = function(state)
    -- Perform cleanup
    cleanup_resources(state)
    
    -- Cancel any child processes
    if state.child_pid then
        process.cancel(state.child_pid, "2s")
    end
    
    -- Wait for child processes to clean up
    time.sleep("1s")
    
    -- Exit with result
    return actor.exit({ status = "shutdown_complete" })
end
```

## Exit Handling

The actor can be explicitly exited from any handler using `actor.exit()`:

```lua
shutdown = function(state, msg)
    -- Perform cleanup
    cleanup_resources(state)
    
    -- Return a result with actor.exit
    return actor.exit({ status = "shutdown", reason = msg.reason })
end
```

## Implementation Details

### Channel Selection

The library uses Wippy's channel selection mechanism to efficiently handle messages from multiple sources:

1. The actor's inbox for regular message passing
2. System events channel for process events
3. Any registered custom channels

The select mechanism automatically rebuilds when channels are added or removed.