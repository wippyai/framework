# Channel System Documentation for Wippy Coroutine VM

⚠️ **Important:** The channel system can only be used inside Wippy processes. It is not available in other parts of the
system like function.

## Overview

The channel system provides a Go-like concurrency model for Wippy processes, allowing coroutines to communicate and
synchronize through message passing. It supports both buffered and unbuffered channels and select operations.

## Channels

Channels are used for internal communication between coroutines within a process.

```lua
-- Create an unbuffered channel
local ch = channel.new()

-- Create a buffered channel with capacity 5
local ch = channel.new(5)
```

## Basic Operations

### Sending

```lua
-- Send a value (blocks if channel is full)
ch:send("message")
```

### Receiving

```lua
-- Receive a value and status (blocks if channel is empty)
local value, ok = ch:receive()
if ok then
    print("Received:", value)
else
    print("Channel closed")
end
```

### Closing

```lua
-- Close a channel (only for regular channels)
ch:close()
```

## Select Operations

The select statement allows you to wait on multiple channel operations simultaneously.

### Using Select

```lua
-- Select with multiple cases
local result = channel.select{
    ch1:case_receive(),
    ch2:case_send("value")
}

-- Check selected case
if result.channel == ch1 then
    print("Received:", result.value)
elseif result.channel == ch2 then
    print("Sent value")
end

-- result.ok is true if operation was successful, false on closed
```

### Select with Default

```lua
-- Select with default case
local result = channel.select{
    ch1:case_receive(),
    ch2:case_send("value"),
    default = true
}

if result.default then
    print("No operation ready")
end
```

## Examples

### Basic Producer-Consumer

```lua
-- Producer-consumer pattern
local function producer(ch)
    for i = 1, 5 do
        ch:send("item" .. i)
    end
    ch:close()
end

local function consumer(ch)
    while true do
        local value, ok = ch:receive()
        if not ok then
            break
        end
        do_something(value)
    end
end

local ch = channel.new(2)
coroutine.spawn(function() producer(ch) end)
coroutine.spawn(function() consumer(ch) end)
```

### Multiple Coroutines with Select

```lua
-- Multiple channel handling with select
local function handler()
    local ch1 = channel.new()
    local ch2 = channel.new()
    
    -- Start sender coroutines
    coroutine.spawn(function()
        ch1:send("message1")
    end)
    
    coroutine.spawn(function()
        ch2:send("message2")
    end)
    
    -- Handle messages from both channels
    for i = 1, 2 do
        local result = channel.select{
            ch1:case_receive(), -- always first written value
            ch2:case_receive()
        }
       do_work(result.value)
    end
end

coroutine.spawn(handler)
```

## Best Practices

1. **Channel Ownership**
    - Close channels from the sender side
    - Check `ok` value when receiving

2. **Buffering**
    - Use unbuffered channels for synchronization
    - Use buffered channels for decoupling
    - Choose buffer size based on expected message rate

3. **Error Handling**
    - Always check for errors when sending/receiving
    - Handle channel closure gracefully
    - Use select with default case for non-blocking operations

4. **Resource Management**
    - Close channels when no longer needed
    - Don't leave blocked coroutines
    - Clean up resources in case of errors

## Limitations and Considerations

1. **Select Operations**
    - Cases must be channel operations
    - Default case makes select non-blocking
    - Select fairly chooses between ready cases
    - Always deterministically selects one case

3. **Coroutine Context**
    - Channels only work within Wippy processes and coroutines
    - Not available in regular functions