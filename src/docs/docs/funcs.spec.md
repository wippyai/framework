# Lua Functions Module Specification

## Overview

The Functions module provides a Lua interface for executing tasks both synchronously and asynchronously. It enables namespace-aware function calls with proper context management, method chaining, and cancellation support.

## Module Interface

### Module Loading

```lua
local funcs = require("funcs")
```

### Creating Function Executor

```lua
local executor = funcs.new()
```

Returns a new function executor instance or raises an error if dependencies are missing.

### Methods

#### with_context(context_table)

Creates a new executor instance with merged context values.

```lua
-- Create new executor with context
local executor2 = executor:with_context({
    tenant_id = "123",
    user_id = "456"
})

-- Original executor remains unchanged
-- Chain multiple contexts
local executor3 = funcs.new()
    :with_context({ tenant = "123" })
    :with_context({ user = "john" })
```

Parameters:
- `context_table`: Table with string keys and any values

Returns:
- New executor instance with updated context (immutable operation)

Security:
- Requires `funcs.context` permission

#### with_actor(actor)

Creates a new executor instance with a specific security actor.

```lua
local executor_with_actor = executor:with_actor(actor_object)
```

Parameters:
- `actor`: Actor userdata object (cannot be nil)

Returns:
- New executor instance with the specified actor

Security:
- Requires `funcs.security` permission
- Actor cannot be nil (security context cannot be removed)

#### with_scope(scope)

Creates a new executor instance with a specific security scope.

```lua
local executor_with_scope = executor:with_scope(scope_object)
```

Parameters:
- `scope`: Scope userdata object (cannot be nil)

Returns:
- New executor instance with the specified scope

Security:
- Requires `funcs.security` permission
- Scope cannot be nil (security context cannot be removed)

#### call(target, ...)

Executes function synchronously and blocks until completion.

```lua
-- Call with single values
local result, err = executor:call("myapp:process", 1, 2, 3)

-- Call with table
local result, err = executor:call("myapp:process", {
    user_id = 123,
    data = "some data"
})
```

Parameters:
- `target`: String in "namespace:name" format (namespace required)
- `...`: Arguments to pass (auto-wrapped in payloads)

Returns:
- `result`: Function result or nil on error
- `err`: Error message or nil on success

Security:
- Requires `funcs.call` permission for the specific target function

#### async(target, ...)

Executes function asynchronously and returns a command object.

```lua
-- Start async execution with single values
local command = executor:async("myapp:worker", 1, 2, 3)

-- Start async execution with table argument
local command = executor:async("myapp:worker", {
    job_id = "job123", 
    data = "async data"
})
```

Parameters:
- `target`: String in "namespace:name" format (namespace required)
- `...`: Arguments to pass (auto-wrapped in payloads)

Returns:
- Command object for managing execution

Security:
- Requires `funcs.call` permission for the specific target function

## Command Object

The command object returned by `async()` provides the following interface:

### Methods

#### response()

Returns the response channel for receiving the function result.

```lua
local channel = command:response()
local payload_wrapper, ok = channel:receive()
```

Returns:
- Channel object for receiving the execution result

**Note**: The channel receives payload wrapper objects, not raw Lua values. Use `payload:data()` to extract the actual data.

#### is_complete()

Checks if the command execution has completed (successfully or with error).

```lua
local completed = command:is_complete()
```

Returns:
- `boolean`: true if execution is complete, false otherwise

#### result()

Gets the execution result and any error that occurred.

```lua
local payload, err = command:result()
```

Returns:
- `payload`: Payload object containing the result (nil if error or not complete)
- `err`: Error message string (nil on success, descriptive message on failure)

Note: If the command is not yet complete, returns `(nil, "command not completed")`

#### is_canceled()

Checks if the command was canceled.

```lua
local canceled = command:is_canceled()
```

Returns:
- `boolean`: true if the command was canceled, false otherwise

#### cancel()

Cancels the command execution.

```lua
local success, err = command:cancel()
```

Returns:
- `success`: boolean indicating if cancellation was successful
- `err`: Error message or nil on success

## Usage Examples

### Basic Usage

```lua
local funcs = require("funcs")

-- Create executor
local executor = funcs.new()

-- Synchronous call
local result, err = executor:call("myapp:process", 1, 2, 3)
if err then
    print("Error:", err)
else
    print("Result:", result)
end

-- Asynchronous call with result handling
local command = executor:async("myapp:worker", { job_id = "123" })

-- Do other work while the function executes
do_something_else()

-- Get the result when ready
local channel = command:response()
local value, ok = channel:receive()
if not ok then
    print("Channel closed without result")
    return
end

-- Access command information
if command:is_complete() then
    local payload, err = command:result()
    if err then
        print("Error:", err)
    else
        -- Extract data from payload
        local data = payload:data()
        print("Success:", data)
    end
end
```

### Context and Security Chaining

```lua
local funcs = require("funcs")

-- Chain operations with context
local result, err = funcs.new()
    :with_context({ tenant = "123" })
    :with_context({ user = "john" })
    :call("myapp:process", 1, 2, 3)

-- Context is immutable
local base = funcs.new():with_context({ tenant = "123" })
local exec1 = base:with_context({ user = "john" })
local exec2 = base:with_context({ user = "jane" })

-- Security context chaining
local secure_executor = funcs.new()
    :with_actor(actor_object)
    :with_scope(scope_object)
    :with_context({ operation = "sensitive" })
```

### Cancellation

```lua
-- Start async command
local command = executor:async("myapp:long_process", data)

-- Check if we should continue or cancel
if should_cancel() then
    local success, err = command:cancel()
    if success then
        print("Command cancelled successfully")
    else
        print("Failed to cancel:", err)
    end
end

-- Check completion and cancellation status
if command:is_complete() then
    if command:is_canceled() then
        print("Command was cancelled")
    else
        local payload, err = command:result()
        if err then
            print("Command failed with error:", err)
        else
            local data = payload:data()
            print("Command succeeded with result:", data)
        end
    end
end
```

### Integration with Channel System

```lua
local funcs = require("funcs")
local time = require("time")

-- Start async command
local command = executor:async("myapp:process", data)

-- Create a ticker for timeout
local ticker = time.ticker(5000) -- 5 seconds

-- Use select to wait for either result or timeout
local result = channel.select{
    command:response():case_receive(),
    ticker:channel():case_receive()
}

if result.channel == ticker:channel() then
    -- Timeout occurred, cancel command
    command:cancel()
    ticker:stop()
    print("Operation timed out")
else
    -- Command completed, extract data from payload wrapper
    ticker:stop()
    local data = result.value:data()
    handle_result(data)
end
```

### Parallel Execution

```lua
-- Execute multiple commands in parallel
local commands = {}
for i = 1, 5 do
    commands[i] = executor:async("myapp:process_chunk", {
        chunk_id = i,
        data = chunks[i]
    })
end

-- Collect all results
local results = {}
for i, command in ipairs(commands) do
    local channel = command:response()
    local payload_wrapper, ok = channel:receive()
    if ok then
        results[i] = payload_wrapper:data()
    else
        local payload, err = command:result()
        if err then
            print("Command", i, "failed:", err)
        end
    end
end
```

### Working with Payloads

```lua
-- Function returns payload object
local command = executor:async("myapp:get_data", { id = "123" })
local channel = command:response()
local payload_result, ok = channel:receive()

if ok and command:is_complete() then
    local payload, err = command:result()
    if not err then
        -- Get the raw data from payload
        local data = payload:data()
        
        -- Or transcode to specific format
        local json_payload = payload:transcode("JSON")
        local json_data = json_payload:data()
        
        -- Check payload format
        local format = payload:get_format()
        print("Payload format:", format)
    end
end
```

## Security Considerations

- Function calls require appropriate permissions (`funcs.call` for the target function)
- Context modification requires `funcs.context` permission
- Security context modification requires `funcs.security` permission
- Security contexts (actor/scope) cannot be set to nil once established
- All security checks are performed before function execution begins