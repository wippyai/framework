# Lua Functions Module Specification

## Overview

The Functions module provides a Lua interface for executing tasks both synchronously and asynchronously. It enables
namespace-aware function calls with proper context management, method chaining, and cancellation support.

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

#### async(target, ...)

Executes function asynchronously and returns a task object.

```lua
-- Start async execution with single values
local task = executor:async("myapp:worker", 1, 2, 3)

-- Start async execution with table argument
local task = executor:async("myapp:worker", {
    job_id = "job123",
    data = "async data"
})
```

Parameters:

- `target`: String in "namespace:name" format (namespace required)
- `...`: Arguments to pass (auto-wrapped in payloads)

Returns:

- Task object with methods for managing execution and a response property

## Task Object

The task object returned by `async()` has the following methods:

```lua
-- Check if task has completed (successfully or with error)
local completed = task:is_complete()

-- Get error message if any occurred, nil otherwise
local err = task:error()

-- Get result and error (only if task is complete)
local result, err = task:result()

-- Check if task was cancelled
local canceled = task:is_canceled()

-- Cancel the task execution
task:cancel()
```

The task object also has a response property:

```lua
-- Get result from the response channel
local value, ok = task.response:receive()
```

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
local task = executor:async("myapp:worker", { job_id = "123" })

-- Do other work while the function executes
do_something_else()

-- Get the result when ready
local value, ok = task.response:receive()
if not ok then
    print("Channel closed without result")
    return
end

-- Access task information
if task:is_complete() then
    local result, err = task:result()
    if err then
        print("Error:", err)
    else
        print("Success:", result)
    end
end
```

### Context and Chaining

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
```

### Cancellation

```lua
-- Start async task
local task = executor:async("myapp:long_process", data)

-- Check if we should continue or cancel
if should_cancel() then
    task:cancel()
    print("Task cancelled")
end

-- Check completion and cancellation status
if task:is_complete() then
    if task:is_canceled() then
        print("Task was cancelled")
    else
        -- Check for errors
        local err = task:error()
        if err then
            print("Task failed with error:", err)
        else
            local result, err = task:result()
            if not err then
                print("Task succeeded with result:", result)
            end
        end
    end
end
```

### Integration with Channel System

```lua
local funcs = require("funcs")
local time = require("time")

-- Start async task
local task = executor:async("myapp:process", data)

-- Create a ticker for timeout
local ticker = time.ticker(5000) -- 5 seconds

-- Use select to wait for either result or timeout
local result = channel.select{
    task.response:case_receive(),
    ticker:channel():case_receive()
}

if result.channel == ticker:channel() then
    -- Timeout occurred, cancel task
    task:cancel()
    ticker:stop()
    print("Operation timed out")
else
    -- Task completed
    ticker:stop()
    handle_result(result.value)
end
```

### Parallel Execution

```lua
-- Execute multiple tasks in parallel
local tasks = {}
for i = 1, 5 do
    tasks[i] = executor:async("myapp:process_chunk", {
        chunk_id = i,
        data = chunks[i]
    })
end

-- Collect all results
local results = {}
for i, task in ipairs(tasks) do
    local value, ok = task.response:receive()
    if ok then
        results[i] = value
    else
        print("Task", i, "failed:", task:error())
    end
end
```