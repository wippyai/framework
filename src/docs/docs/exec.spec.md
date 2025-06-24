# Exec Module Specification

## Overview

The Exec module provides a Lua interface for executing external processes. It allows scripts to spawn, control, and interact with child processes, including reading/writing to their standard streams and monitoring their execution.

## Module Interface

### Loading the Module

```lua
local exec = require("exec")
```

## Core Concepts

### Resource Management

- Process executor factories are obtained from the resource registry
- These resources are automatically cleaned up when the containing unit of work completes
- Resources can be explicitly released earlier using the `release` method

### Process Execution Flow

1. Acquire an executor factory from the resource registry
2. Create a process handle using the factory
3. Start the process
4. Interact with the process through standard streams
5. Wait for process completion or terminate it
6. Close/release the process handle
7. Release the executor factory resource

## Executor Factory

### Getting an Executor Factory

```lua
local executor = exec.get("resource_id")
-- Parameters: resource_id (string) - Resource ID for the executor
-- Returns: executor factory object
-- Errors: raises if
--   - resource doesn't exist
--   - resource is not a process executor
--   - resource acquisition fails
```

### Creating a Process

```lua
local process = executor:exec(command, options)
-- Parameters:
--   command (string): Command to execute
--   options (table, optional): Process configuration with:
--     work_dir (string, optional): Working directory
--     env (table, optional): Environment variables as key-value pairs
-- Returns: process handle object
-- Errors: raises if process creation fails
```

### Releasing an Executor

```lua
local success = executor:release()
-- Returns: true (always succeeds)
-- Note: After release, executor methods will fail
```

## Process Handle

### Process Control

#### Start Process

```lua
process:start()
-- Returns: nothing
-- Errors: raises if start fails
-- Note: Process must be started before stdin/stdout/stderr operations
```

#### Signal Process

```lua
local success, err = process:signal(signal_number)
-- Parameters: signal_number (number) - OS signal number (e.g., 15 for SIGTERM)
-- Returns on success: true, nil
-- Returns if process already finished: nil, error message
-- Returns on error: nil, error message
```

#### Wait for Process Completion

```lua
local exit_code, err = process:wait()
-- Returns on success: exit_code (number), nil
-- Returns on error: nil, error message
-- Note: This is a blocking call that should be used with coroutines
-- Note: Process is automatically closed after wait completes
```

#### Close Process

```lua
local success = process:close(force_stop)
-- Parameters: force_stop (boolean, optional) - If true, sends SIGKILL instead of SIGTERM
-- Returns: true (always succeeds)
-- Note: Idempotent operation (safe to call multiple times)
```

### Stream Operations

#### Get Stdout Stream

```lua
local stdout_stream = process:stdout_stream()
-- Returns: stream object for reading stdout
-- Errors: raises if
--   - process is closed
--   - stream creation fails
-- Note: Returns the same stream object on multiple calls
```

#### Get Stderr Stream

```lua
local stderr_stream = process:stderr_stream()
-- Returns: stream object for reading stderr
-- Errors: raises if
--   - process is closed
--   - stream creation fails
-- Note: Returns the same stream object on multiple calls
```

#### Write to Stdin

```lua
local success, err = process:write_stdin(data)
-- Parameters: data (string) - Data to write to stdin
-- Returns on success: true, nil
-- Returns on error: nil, error message
```

## Stream Interface

Stdout and stderr streams implement the standard Stream interface:

```lua
-- Read data from stream
local data, err = stream:read()
-- Returns on success: string data, nil
-- Returns on EOF: nil, nil
-- Returns on error: nil, error message

-- Close stream
local success, err = stream:close()
-- Returns on success: true, nil
-- Returns on error: nil, error message
```

## Example Usage

### Basic Process Execution

```lua
local exec = require("exec")

-- Get executor factory from resource registry
local executor = exec.get("process:native")

-- Create and start a simple process
local proc = executor:exec("echo 'Hello World'")
proc:start()

-- Capture output using a coroutine
coroutine.spawn(function()
    local stream = proc:stdout_stream()
    local output = ""
    while true do
        local chunk = stream:read()
        if not chunk then break end
        output = output .. chunk
    end
    print("Output:", output)
    stream:close()
end)

-- Wait for completion
local exit_code, err = proc:wait()
assert(exit_code == 0, "Process failed with: " .. tostring(err))

-- Release resources
executor:release()
```

### Process with Custom Environment and Working Directory

```lua
local exec = require("exec")

-- Get executor factory
local executor = exec.get("process:native")

-- Create process with custom env and working directory
local proc = executor:exec("pwd && echo $CUSTOM_VAR", {
    work_dir = "/tmp",
    env = {
        PATH = "/usr/bin:/bin",
        CUSTOM_VAR = "Hello from env"
    }
})
proc:start()

-- Capture output with channel for synchronization
local done = channel.new()
coroutine.spawn(function()
    local stream = proc:stdout_stream()
    local output = ""
    while true do
        local chunk = stream:read()
        if not chunk then break end
        output = output .. chunk
    end
    stream:close()
    done:send(output)
end)

-- Receive output and wait for completion
local output = done:receive()
done:close()

local exit_code = proc:wait()
proc:close() -- Optional after wait()
executor:release()

return output
```

### Process with Stdin Input

```lua
local exec = require("exec")

-- Get executor factory
local executor = exec.get("process:native")

-- Create a process that processes stdin
local proc = executor:exec("sort")
proc:start()

-- Send data to stdin
proc:write_stdin("banana\napple\ncherry\n")

-- Capture sorted output
local done = channel.new()
coroutine.spawn(function()
    local stream = proc:stdout_stream()
    local output = ""
    while true do
        local chunk = stream:read()
        if not chunk then break end
        output = output .. chunk
    end
    stream:close()
    done:send(output)
end)

-- Get results
local sorted_output = done:receive()
done:close()

proc:wait()
executor:release()

return sorted_output
```

### Process Termination

```lua
local exec = require("exec")
local time = require("time")

-- Get executor factory
local executor = exec.get("process:native")

-- Start a long-running process
local proc = executor:exec("sleep 30")
proc:start()

-- Let it run for a moment
time.sleep("1s")

-- Terminate gracefully
proc:signal(15) -- SIGTERM

-- Or forcefully close
-- proc:close(true) -- Force stop

-- Wait for termination
local exit_code, err = proc:wait()
executor:release()
```

### Error Handling and Cleanup

```lua
local exec = require("exec")

-- Get executor factory
local executor, err = pcall(function() return exec.get("process:native") end)
if not executor then
    error("Failed to get executor: " .. tostring(err))
end

-- Create process with error handling
local proc, err = pcall(function() 
    return executor:exec("non_existent_command") 
end)
if not proc then
    executor:release()
    error("Failed to create process: " .. tostring(err))
end

-- Start with error handling
local success, err = pcall(function() proc:start() end)
if not success then
    proc:close()
    executor:release()
    error("Failed to start process: " .. tostring(err))
end

-- Always ensure cleanup
local function cleanup()
    pcall(function() proc:close() end)
    pcall(function() executor:release() end)
end

-- Wait will never fail, no need for pcall
local exit_code, err = proc:wait()
cleanup()

if err then
    -- Handle error if returned from wait
    error("Process wait error: " .. tostring(err))
end

return exit_code
```

## Notes

- Process streams implement a standard Stream interface
- After `wait()` completes, the process handle is automatically closed
- `wait()` never triggers an error, only returns the exit code and error message
- Use `coroutine.spawn` for non-blocking stream operations
- Use `channel` for synchronization between coroutines
- Always release resources explicitly when finished, or let the unit of work handle cleanup
- The module is designed to work with the Lua coroutine system for asynchronous operations