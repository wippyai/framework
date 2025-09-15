# Wippy Runtime Lua Process API Specification

## Overview

The Wippy Runtime Process API provides a robust actor-model implementation for building concurrent, message-passing
applications in Lua. This specification is designed for AI agents and developers working with the Wippy Runtime.

## Core Concepts

### Actor Model

The Wippy Runtime implements an actor model where:

- Processes are isolated units of computation
- Each process has a unique identifier (PID)
- Processes communicate exclusively through message passing
- No shared state between processes

### Concurrency Model

- Lightweight processes run concurrently
- Non-blocking message passing
- Event-driven programming with channel-based communication
- Supervision trees for process lifecycle management

## Process Identification

### Process ID (PID)

Each process has a unique PID with the following format:

```
{node@host|namespace:name|procname}  // With node component
{host|namespace:name|procname}       // Without node component
```

Where:

- `node` (optional): Physical node identifier in distributed setups
- `host`: Host identifier that determines process behavior
- `namespace:name`: Registry ID that identifies the process type
- `procname`: Unique instance identifier

Examples:

```
{host1|app:worker|proc123}
{node1@host1|system:logger|main}
```

### Getting Process Information

```lua
-- Get the current process PID as a string
local pid = process.pid()  -- Returns "{host1|app:worker|proc123}"
```

## Process Constants

The Wippy Runtime defines important constants for system events:

```lua
-- System event kinds (for identifying event types)
process.event.CANCEL           -- "pid.cancel" - Cancellation request event
process.event.EXIT             -- "pid.exit" - Process exit notification event
process.event.LINK_DOWN        -- "pid.link.down" - Linked process failure event
```

## Communication

### Message Passing

Messages are sent between processes through named topics:

```lua
-- Basic message sending
-- Params: destination, topic, [payload1, payload2, ...]
-- Returns: true on success, nil and error_message on failure
process.send(destination, topic, payload)

-- Sending to a PID
process.send("{host1|app:worker|proc123}", "notification", { type = "alert", level = "warning" })

-- Sending to a registered name
process.send("worker1", "task", { action = "process", id = "12345" })

-- Sending multiple values (each becomes a separate message)
process.send(destination, topic, value1, value2, value3)
```

#### Message Format Considerations

- Each value passed to `send()` becomes a separate message
- Messages preserve sending order between sender-receiver pairs
- Non-blocking send operations (fire and forget)

### Receiving Messages

Messages can be received through two types of channels:

#### 1. Topic-Specific Channels

```lua
-- Create a channel for a specific topic
local task_channel = process.listen("task")

-- Receive a message (blocks until message arrives)
local task, ok = task_channel:receive()

-- Already unmarshalled
print(task.foo)
```

#### 2. Default Inbox

```lua
-- Get the process inbox for messages without dedicated listeners
local inbox = process.inbox()

-- Receive a message
local message = inbox:receive()

-- Access message properties
print("Topic:", message:topic())
local payload = message:payload()
local from_pid = message:from()

-- Convert payload to Lua data
local data = payload:data()
```

Messages from inbox:

- Include topic metadata
- Include original payload wrapped in a message object
- Require unmarshal to access data
- You can send payload values without unpacking

### System Events

Processes and workflows can listen for system events:

```lua
-- Create a channel for system events
local events = process.events()

-- Receive an event
local event = events:receive()

-- Check event type
if event.kind == process.event.CANCEL then
    -- Handle cancellation request
    local deadline = event.deadline -- Time when cancellation should take effect
elseif event.kind == process.event.EXIT then
    -- Handle process result notification[process.md](../../../../../wippy-runtime-linux-alpha/process.md)
    local result = event.result -- Process execution result
    local data = result.payload:data() -- Result payload value (unmarshal required)
    local error = result.error -- Error if any
elseif event.kind == process.event.LINK_DOWN then
    -- Handle linked process failure
end
```

#### Event Structures

System events are delivered as Lua tables with the following structures:

1. Base Event Structure (present in all events):

```lua
event = {
    at = timestamp,  -- Time when the event occurred
    kind = "pid.cancel|pid.exit|pid.link.down|...",  -- Event type
    from = "{pid}"   -- Source PID
}
```

2. Exit Event (EXIT):

```lua
{
    event = {  -- Base event structure
        at = timestamp,
        kind = "pid.exit",
        from = "{pid}"
    },
    result = {
        value = {...},  -- payload value
        error = "..."   -- Error message (if failed)
    }
}
```

3. Cancel Event:

```lua
{
    event = {  -- Base event structure
        at = timestamp,
        kind = "pid.cancel",
        from = "{pid}"
    },
    deadline = timestamp  -- When cancellation should take effect
}
```

4. Link Event:

```lua
{
    event = {  -- Base event structure
        at = timestamp,
        kind = "pid.link.down", -- Also could be "pid.link.established" or "pid.link.removed"
        from = "{pid}"
    }
}
```

> Note, that link down events will only arrive if the `trap_links` option is set to `true`. Otherwise, when a linked
> process fails, the current process will also fail without receiving an event.

## Process Management

### Creating Processes

```lua
-- Basic process spawning (no supervision)
-- Params: id, host, [arg1, arg2, ...]
-- Returns: pid_string on success, nil and error_message on failure
local child_pid = process.spawn(
    "namespace:name",  -- Process type (required)
    "host_id",         -- Host to run on (required)
    arg1, arg2, arg3   -- Optional arguments passed to the process
)

-- Spawn with monitoring (parent gets notified when child terminates)
-- Params: id, host, [arg1, arg2, ...]
-- Returns: pid_string on success, nil and error_message on failure
local child_pid = process.spawn_monitored(
    "namespace:name",
    "host_id",
    { key = value }  -- Optional arguments (table format)
)

-- Spawn with linking (if child fails, parent also fails)
-- Params: id, host, [arg1, arg2, ...]
-- Returns: pid_string on success, nil and error_message on failure
local child_pid = process.spawn_linked(
    "namespace:name",
    "host_id",
    arg1, arg2, arg3  
)
```

#### Supervision Behaviors

- **Spawn**: No supervision, child failure doesn't affect parent
- **Monitored**: Parent receives notification (event.EXIT) when child terminates (success or failure)
- **Linked**: Bi-directional link where failure propagates (if child crashes, parent also crashes)

### Process Links and Monitors

```lua
-- Establish a link with another process
-- Params: destination (PID string or registered name)
-- Returns: true on success, nil and error_message on failure
process.link(destination)

-- Remove a link with another process
-- Params: destination (PID string or registered name)
-- Returns: true on success, nil and error_message on failure
process.unlink(destination)

-- Monitor another process (receive notification when it exits)
-- Params: destination (PID string or registered name)
-- Returns: true on success, nil and error_message on failure
process.monitor(destination)

-- Stop monitoring another process
-- Params: destination (PID string or registered name)
-- Returns: true on success, nil and error_message on failure
process.unmonitor(destination)
```

Unlike process spawning which creates new processes with links or monitoring, these functions establish links or
monitoring relationships with existing processes.

### Process Registry

Processes can register names for easier discovery:

```lua
-- Register the current process with a name
-- Params: name, [pid]
-- Returns: true on success, nil and error_message on failure
process.registry.register("worker1")

-- Register a specific PID with a name
-- Params: name, pid
-- Returns: true on success, nil and error_message on failure
process.registry.register("backup_worker", some_pid)

-- Look up a process by name
-- Params: name
-- Returns: pid_string on success, nil and error_message on failure
local pid = process.registry.lookup("worker1")

-- Unregister a name
-- Params: name
-- Returns: true if successfully unregistered, false if name wasn't registered
process.registry.unregister("worker1")
```

### Process Lifecycle Control

```lua
-- Terminate a process immediately
-- Params: destination (PID string or registered name)
-- Returns: true on success, nil and error_message on failure
process.terminate(pid_or_name)

-- Request graceful cancellation with deadline
-- Params: destination (PID string or registered name), deadline
-- Returns: true on success, nil and error_message on failure
process.cancel(pid_or_name, "5s")  -- String duration
process.cancel(pid_or_name, 5000)  -- Milliseconds
```

### Process Options

```lua
-- Get current process options
-- Params: none
-- Returns: options table
local options = process.get_options()
print(options.trap_links)  -- Check if link trapping is enabled

-- Set process options
-- Params: options_table
-- Returns: success (boolean), error_message (or nil if successful)
local success, error = process.set_options({
    trap_links = true  -- When true, process receives LINK_DOWN events instead of failing when linked processes die
})
```

## Process Implementation Patterns

### Basic Process Structure

```lua
local function run(args)
    -- Process initialization
    local pid = process.pid()
    
    -- Process implementation
    -- ...
    
    -- Return result data when done
    return { status = "completed", data = result_data }
end

return { run = run }
```

### Event Loop Pattern

```lua
local function run(args)
    -- Set up channels
    local tasks = process.listen("tasks")
    local inbox = process.inbox()
    local events = process.events()
    
    -- State
    local state = {
        running = true,
        tasks_processed = 0
    }
    
    -- Main event loop
    while state.running do
        local result = channel.select({
            tasks:case_receive(),
            inbox:case_receive(),
            events:case_receive()
        })
        
        if result.channel == tasks then
            -- Handle task
            local task = result.value
            process_task(task)
            state.tasks_processed = state.tasks_processed + 1
            
        elseif result.channel == inbox then
            -- Handle inbox message
            local msg = result.value
            local topic = msg:topic()
            local payload = msg:payload():data()
            handle_inbox_message(topic, payload)
            
        elseif result.channel == events then
            -- Handle system event
            local event = result.value
            if event.kind == process.event.CANCEL then
                state.running = false
            end
        end
    end
    
    -- Clean up and return result
    return { processed = state.tasks_processed }
end

return { run = run }
```

## Channel Operations

The channel system provides a Go-like concurrency model for communication between coroutines within a process.

### Channel Creation

```lua
-- Create an unbuffered channel
local ch = channel.new()

-- Create a buffered channel with capacity 5
local ch = channel.new(5)
```

### Channel Select

The `channel.select` function allows waiting on multiple channels simultaneously:

```lua
local result = channel.select({
    channel1:case_receive(),
    channel2:case_receive(),
    channel3:case_send("value")
})

if result.ok then
    -- Channel had data
    print("Selected channel:", result.channel)
    print("Value:", result.value)
else
    -- Error or closed channel
    print("Error:", result.error)
end
```

### Implementing Timeouts

Since there are no direct timeout parameters on channel operations, timeouts must be implemented using the time module
with a dedicated timeout channel:

```lua
local time = require("time")

-- Create a timeout channel that will receive after specified duration
local timeout = time.after("5s")  -- 5 second timeout

-- Use in select
local result = channel.select({
    msgs:case_receive(),
    timeout:case_receive()
})

if result.channel == timeout then
    -- Timeout occurred
    handle_timeout()
else
    -- Message received within timeout
    process_message(result.value)
end
```

### Select with Default Case

```lua
-- Non-blocking select with default case
local result = channel.select({
    ch1:case_receive(),
    ch2:case_send("value"),
    default = true
})

if result.default then
    -- No operations were ready
    print("Would have blocked, continuing...")
end
```

> You can close channels you own, but you can not closed channels own by the process.

## Common Patterns and Examples

### 1. Request-Response Pattern

```lua
-- Requester
local function send_request(target_pid, request_data)
    local inbox = process.inbox()
    
    -- Send request with reply address
    process.send(target_pid, "request", {
        data = request_data,
        reply_to = process.pid()
    })
    
    -- Wait for response with timeout
    local time = require("time")
    local timeout = time.after("5s")
    
    local result = channel.select({
        inbox:case_receive(),
        timeout:case_receive()
    })
    
    if result.channel == timeout then
        return nil, "timeout"
    end
    
    local response = result.value
    return response:payload():data()
end

-- Responder
local function handle_request(msg)
    local request = msg:payload():data()
    
    -- Process request
    local result = process_data(request.data)
    
    -- Send response back
    if request.reply_to then
        process.send(request.reply_to, "response", result)
    end
end
```

### 2. Work Distribution Pattern

```lua
-- Manager process
local function distribute_work(work_items, worker_count)
    -- Spawn workers
    local workers = {}
    for i = 1, worker_count do
        local pid = process.spawn_monitored(
            "app:worker",
            "system:processes",
            { worker_id = i }
        )
        table.insert(workers, pid)
    end
    
    -- Distribute work
    local work_index = 1
    while work_index <= #work_items do
        for _, worker in ipairs(workers) do
            if work_index <= #work_items then
                process.send(worker, "work", work_items[work_index])
                work_index = work_index + 1
            else
                break
            end
        end
    end
    
    -- Wait for results using monitoring events
    -- ...
end
```

### 3. Supervision Tree with Links and Monitors

```lua
local function supervisor()
    local children = {}
    local events = process.events()
    
    -- Start child processes
    local function start_child(id)
        local pid = process.spawn_monitored("app:worker", "system:processes", { id = id })
        children[id] = pid
        return pid
    end
    
    -- Initialize children
    for i = 1, 5 do
        start_child(i)
    end
    
    -- Add link to critical process
    local database_pid = process.registry.lookup("database")
    if database_pid then
        process.link(database_pid)
    end
    
    -- Supervision loop
    while true do
        local event = events:receive()
        
        if event.kind == process.event.EXIT then
            local failed_pid = event.from
            
            -- Find which child failed
            for id, pid in pairs(children) do
                if pid == failed_pid then
                    print("Child", id, "failed, restarting...")
                    -- Restart the child
                    start_child(id)
                    break
                end
            end
        elseif event.kind == process.event.LINK_DOWN then
            -- Critical linked process failed
            -- With trap_links = true, we receive LINK_DOWN events instead of dying
            local down_pid = event.from
            print("Linked process down:", down_pid)
                            
            -- Try to reconnect or restart
            if down_pid == database_pid then
                -- Try to reconnect to database
                reconnect_database()
            end
        end
    end
end
```

## Best Practices for AI Agents

### 1. Process Structure

- Always implement the `run` function that takes arguments and returns a result
- Keep process code self-contained (no global state)
- Handle system events, especially cancellation

### 2. Message Handling

- Use `process.listen()` for topic-specific messages
- Use `process.inbox()` for fallback messages
- Use `process.events()` for system events and lifecycle management
- Always use `channel.select()` to handle multiple channels
- Check message types before processing

### 3. Process Management

- Use `spawn_monitored` when you need to track child process completion
- Use `spawn_linked` when child failures should propagate to parent
- Use plain `spawn` for independent processes
- Use `process.link()` and `process.monitor()` for existing processes
- Always check return values for errors

### 4. Error Handling

- Return error information in process results
- Use message passing for error notifications
- Implement proper cleanup in termination handlers
- Use `trap_links = true` option to receive `LINK_DOWN` events when linked processes fail instead of failing yourself
- Unlink processes before terminating them if necessary

### 5. Timeouts and Deadlines

- Always implement timeouts for operations that may block
- Use the `time.after()` function with `channel.select()` for timeout handling
- Set realistic deadlines for cancellation requests
- Handle timeout cases gracefully

### 6. Performance Considerations

- Keep messages small
- Use appropriate buffering for channels
- Implement batching for high-throughput scenarios
- Avoid creating unnecessary processes for short-lived operations
- Consider link and monitor overhead when designing process relationships
