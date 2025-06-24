# Events Module Specification

## Overview

The Events module provides access to the Wippy event bus system through a simple, channel-based API. It enables Lua processes to subscribe to specific event patterns and receive events through channels, supporting concurrent event processing with coroutines.

## Module Interface

### Loading the Module

```lua
local events = require("events")
```

### Methods

#### subscribe(system, [kind])

Creates a subscription to events matching the system and optional kind pattern.

```lua
-- Subscribe to all events in the "users" system
local subscription = events.subscribe("users")

-- Subscribe to specific event kinds with pattern matching
local subscription = events.subscribe("users", "*.created")
```

Parameters:
- `system` (string): System identifier or pattern (e.g., "users", "auth", "*")
- `kind` (string, optional): Event kind pattern (e.g., "created", "user.*", "*")

Returns:
- Subscription object on success
- `nil, error_message` on failure

## Subscription Object

The subscription object returned by `events.subscribe()` has the following methods:

#### channel()

Returns the channel that receives matching events.

```lua
local ch = subscription:channel()
```

Returns:
- Channel object that receives event tables

#### close()

Closes the subscription, removing it from the event bus and stopping event delivery.

```lua
subscription:close()
```

Returns:
- `true` on success

## Event Format

Events received through subscription channels are Lua tables with the following fields:

```lua
{
    system = "users",       -- System identifier (string)
    kind = "user.created",  -- Event kind (string)
    path = "users/123",     -- Optional path identifier (string)
    data = { ... }          -- Event payload (any type)
}
```

## Resource Management

- Subscriptions are automatically closed when the unit of work (UoW) that created them ends
- Explicitly calling `subscription:close()` is recommended when a subscription is no longer needed
- All event resources are properly cleaned up when subscriptions are closed

## Integration with Channels

Events module is designed to work seamlessly with the Wippy channel system:

```lua
-- Receive events one at a time
local evt, ok = subscription:channel():receive()

-- Use with channel.select for concurrent operations
local result = channel.select{
    subscription:channel():case_receive(),
    other_channel:case_receive()
}
```

## Error Handling

Most operations can return errors:

```lua
-- Handle subscription errors
local subscription, err = events.subscribe("users", "*.created")
if not subscription then
    error("Failed to subscribe: " .. err)
end

-- Handle channel errors
local evt, ok = subscription:channel():receive()
if not ok then
    -- Channel closed or error occurred
end
```

## Usage Examples

### Basic Event Subscription

```lua
local events = require("events")

-- Subscribe to all auth events
local subscription = events.subscribe("auth", "*")

-- Process events in a loop
while true do
    local evt, ok = subscription:channel():receive()
    if not ok then
        print("Subscription channel closed")
        break
    end
    
    print("Received event:", evt.system, evt.kind)
    
    -- Process the event based on its kind
    if evt.kind == "user.login" then
        handle_login(evt.data)
    elseif evt.kind == "user.logout" then
        handle_logout(evt.data)
    end
end

-- Close subscription when done
subscription:close()
```

### Event Processing with Coroutines

```lua
local events = require("events")

-- Create multiple subscriptions
local user_events = events.subscribe("users")
local system_events = events.subscribe("system")

-- Process users events in a separate coroutine
coroutine.spawn(function()
    while true do
        local evt, ok = user_events:channel():receive()
        if not ok then break end
        process_user_event(evt)
    end
end)

-- Process system events in another coroutine
coroutine.spawn(function()
    while true do
        local evt, ok = system_events:channel():receive()
        if not ok then break end
        process_system_event(evt)
    end
end)

-- Continue with other operations in the main coroutine
do_something_else()
```

### Event Filtering with Pattern Matching

```lua
local events = require("events")

-- Subscribe to specific event patterns
local created_events = events.subscribe("*", "*.created")
local deleted_events = events.subscribe("*", "*.deleted")
local user_events = events.subscribe("users", "*")

-- Process events from multiple subscriptions with select
while true do
    local result = channel.select{
        created_events:channel():case_receive(),
        deleted_events:channel():case_receive(),
        user_events:channel():case_receive()
    }
    
    if result.channel == created_events:channel() then
        handle_creation(result.value)
    elseif result.channel == deleted_events:channel() then
        handle_deletion(result.value)
    elseif result.channel == user_events:channel() then
        handle_user_event(result.value)
    end
end
```

### Helper Function for Event Handling

```lua
local events = require("events")

-- Helper function to subscribe with a handler
function subscribe_with_handler(system, kind, handler)
    local subscription = events.subscribe(system, kind)
    
    -- Process events in a background coroutine
    coroutine.spawn(function()
        while true do
            local evt, ok = subscription:channel():receive()
            if not ok then break end
            
            -- Call the handler with the event
            handler(evt)
        end
    end)
    
    return subscription
end

-- Usage example
local auth_sub = subscribe_with_handler("auth", "user.*", function(evt)
    if evt.kind == "user.login" then
        log_login(evt.data.user_id, evt.data.timestamp)
    elseif evt.kind == "user.logout" then
        log_logout(evt.data.user_id, evt.data.timestamp)
    end
end)

-- Later: close subscription when done
auth_sub:close()
```

### Timed Events with Integration

```lua
local events = require("events")
local time = require("time")

-- Subscribe to events
local subscription = events.subscribe("alerts", "*")

-- Create a timer for periodic checks
local timer = time.after("5s")

-- Wait for either event or timeout
local result = channel.select{
    subscription:channel():case_receive(),
    timer:case_receive()
}

if result.channel == subscription:channel() then
    -- Process event
    handle_alert(result.value)
else
    -- Timeout occurred
    print("No alerts received in 5 seconds")
end

-- Clean up
subscription:close()
```

## Best Practices

1. **Always close subscriptions** when no longer needed
2. **Use pattern matching** for efficient event filtering
3. **Handle channel closure** properly in receive loops
4. **Spawn coroutines** for concurrent event processing
5. **Use `channel.select`** to handle multiple event sources
6. **Keep event handlers small and focused** to process events efficiently