# Lua System Module Specification

## Overview

The `system` module provides Lua access to the Go runtime and system information. It exposes functions for monitoring and managing memory, controlling garbage collection, and inspecting runtime characteristics. This module is useful for diagnostic tooling, performance monitoring, and memory-critical applications.

## Module Interface

### Module Loading

```lua
local system = require("system")
```

### Error Handling

All functions in the module follow a consistent error handling pattern, returning two values:

1. The result value (or nil if an error occurred)
2. An error message string (or nil if operation was successful)

Example:

```lua
local stats, err = system.mem_stats()
if err then
    -- handle error
end
```

### Global Functions

#### system.mem_stats()

Returns detailed memory statistics from the Go runtime.

Returns:

- `table, error`: Table with memory statistics, or nil and error message on failure

Example returned table:

```lua
{
  alloc = 8420344,            -- Currently allocated bytes
  total_alloc = 25648720,     -- Total bytes allocated (including freed)
  sys = 24234592,             -- Total memory obtained from OS
  heap_alloc = 8420344,       -- Bytes of allocated heap objects
  heap_sys = 16605184,        -- Bytes of heap memory from OS
  heap_idle = 7274496,        -- Bytes in idle spans
  heap_in_use = 9330688,      -- Bytes in in-use spans
  heap_released = 5242880,    -- Bytes of physical memory returned to OS
  heap_objects = 42675,       -- Number of allocated heap objects
  stack_in_use = 2359296,     -- Bytes in stack spans in use
  stack_sys = 2359296,        -- Bytes obtained from system for stack spans
  mspan_in_use = 352128,      -- Bytes of allocated mspan structures
  mspan_sys = 491520,         -- Bytes used for mspan structures from system
  num_gc = 12,                -- Number of completed GC cycles
  next_gc = 16840688          -- Target heap size of next GC cycle
}
```

#### system.allocated()

Returns the number of bytes of allocated heap objects.

Returns:

- `number, error`: Allocated bytes, or nil and error message on failure

#### system.heap_objects()

Returns the number of allocated heap objects.

Returns:

- `number, error`: Number of heap objects, or nil and error message on failure

#### system.gc()

Forces a garbage collection.

Returns:

- `boolean, error`: true on success, or nil and error message on failure

#### system.set_gc_percent(percent: number)

Sets the garbage collection target percentage. The percentage controls how much CPU time should be spent on garbage collection relative to program execution.

Parameters:

- `percent`: Target percentage. A lower value means more frequent garbage collection.

Returns:

- `number, error`: Previous GC percentage, or nil and error message on failure

#### system.get_gc_percent()

Gets the current garbage collection target percentage.

Returns:

- `number, error`: Current GC percentage, or nil and error message on failure

#### system.num_goroutines()

Returns the number of currently executing goroutines.

Returns:

- `number, error`: Goroutine count, or nil and error message on failure

#### system.go_max_procs([procs: number])

Gets or sets the maximum number of CPUs that can be executing simultaneously.

Parameters:

- `procs` (optional): Number of processors to use. If not provided, returns the current setting without changing it.

Returns:

- `number, error`: Previous GOMAXPROCS value, or nil and error message on failure

#### system.num_cpu()

Returns the number of logical CPUs available on the current system.

Returns:

- `number, error`: CPU count, or nil and error message on failure

#### system.hostname()

Returns the hostname of the current system.

Returns:

- `string, error`: Hostname, or nil and error message on failure

#### system.pid()

Returns the process ID of the current process.

Returns:

- `number, error`: Process ID, or nil and error message on failure

## Behavior

### Memory Statistics

The `mem_stats()` function provides a comprehensive view of the Go runtime's memory usage. It's useful for:

- Monitoring memory consumption over time
- Detecting memory leaks
- Understanding garbage collection behavior
- Tuning application performance

The function returns a table containing various memory metrics, most importantly:

- `alloc`: Currently allocated bytes
- `heap_objects`: Number of allocated objects
- `num_gc`: Number of completed garbage collection cycles

### Garbage Collection

The module provides several functions for monitoring and controlling garbage collection:

- `gc()`: Triggers an immediate garbage collection
- `set_gc_percent(percent)`: Adjusts how aggressively the garbage collector runs
- `get_gc_percent()`: Retrieves the current GC target percentage

Lower GC percentage values make garbage collection more aggressive (more CPU time spent on GC, less memory usage), while higher values make it less aggressive (less CPU time on GC, more memory usage).

### Runtime Information

The module exposes information about the Go runtime:

- `num_goroutines()`: Shows how many goroutines are currently active
- `go_max_procs([procs])`: Controls parallel execution
- `num_cpu()`: Reports hardware capabilities

This information is useful for diagnosing concurrency issues, tuning parallelism, and understanding resource utilization.

### System Information

Basic system information is available through:

- `hostname()`: Gets the system's hostname
- `pid()`: Gets the current process ID

These can be useful for logging, monitoring, and diagnostics.

## Thread Safety

- All functions in the module are thread-safe
- They can be called concurrently from different Lua coroutines
- The underlying Go runtime functions are designed for concurrent access

## Best Practices

1. **Memory Monitoring:**
   ```lua
   -- Periodically check memory usage
   local function monitor_memory()
       local stats, err = system.mem_stats()
       if err then error(err) end
       
       print(string.format("Memory allocated: %.2f MB", stats.alloc / 1024 / 1024))
       print(string.format("Heap objects: %d", stats.heap_objects))
       print(string.format("GC cycles: %d", stats.num_gc))
   end
   ```

2. **GC Tuning:**
   ```lua
   -- Save original GC setting
   local original, err = system.get_gc_percent()
   if err then error(err) end
   
   -- Make GC more aggressive during bulk processing
   system.set_gc_percent(50)
   
   -- ... perform memory-intensive work ...
   
   -- Restore original setting
   system.set_gc_percent(original)
   ```

3. **Error Handling:**
   ```lua
   local result, err = system.num_goroutines()
   if err then
       -- Log the error
       print("Error getting goroutine count: " .. err)
       return default_value
   end
   return result
   ```

4. **Resource Check:**
   ```lua
   local cpus, err = system.num_cpu()
   if err then error(err) end
   
   local procs, err = system.go_max_procs()
   if err then error(err) end
   
   if procs < cpus then
       -- Adjust GOMAXPROCS to use all available CPUs
       system.go_max_procs(cpus)
       print("Adjusted GOMAXPROCS to use all " .. cpus .. " CPUs")
   end
   ```