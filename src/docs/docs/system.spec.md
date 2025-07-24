# Wippy Lua System Module Specification

## Overview

The `system` module provides Lua scripts with comprehensive access to the Go runtime and system information within Wippy applications. All operations are subject to Wippy's security permission model.

## Module Interface

### Loading
```lua
local system = require("system")
```

### Return Pattern
All functions return `(result, error)` where error is `nil` on success.

### Security Model
Functions require `system.{action}` permissions on specific resources:
- `system.read` - Read-only access to system information
- `system.gc` - Garbage collection control
- `system.control` - Runtime parameter modification

---

## Memory & Garbage Collection

#### `system.mem_stats()`
**Permission:** `system.read` on `memory`  
**Returns:** `table`, `error`

Table fields: `alloc`, `total_alloc`, `sys`, `heap_alloc`, `heap_sys`, `heap_idle`, `heap_in_use`, `heap_released`, `heap_objects`, `stack_in_use`, `stack_sys`, `mspan_in_use`, `mspan_sys`, `num_gc`, `next_gc`

#### `system.allocated()`
**Permission:** `system.read` on `memory`  
**Returns:** `number`, `error` (current heap allocation in bytes)

#### `system.heap_objects()`
**Permission:** `system.read` on `memory`  
**Returns:** `number`, `error` (current heap object count)

#### `system.set_memory_limit(limit: number)`
**Permission:** `system.control` on `memory_limit`  
**Parameters:** `limit` in bytes, `-1` for unlimited  
**Returns:** `number` (previous limit), `error`

#### `system.get_memory_limit()`
**Permission:** `system.read` on `memory_limit`  
**Returns:** `number` (`math.MaxInt64` = unlimited), `error`

#### `system.gc()`
**Permission:** `system.gc` on `gc`  
**Returns:** `boolean`, `error`

#### `system.set_gc_percent(percent: number)`
**Permission:** `system.gc` on `gc_percent`  
**Parameters:** `percent` (typically 50-200, `-1` to disable)  
**Returns:** `number` (previous percentage), `error`

#### `system.get_gc_percent()`
**Permission:** `system.read` on `gc_percent`  
**Returns:** `number`, `error`

---

## Runtime & Process Information

#### `system.num_goroutines()`
**Permission:** `system.read` on `goroutines`  
**Returns:** `number`, `error`

#### `system.go_max_procs([procs: number])`
**Permission:** `system.control` on `gomaxprocs` (when setting), `system.read` on `gomaxprocs` (when getting)  
**Parameters:** `procs` (optional, positive integer)  
**Returns:** `number` (previous/current GOMAXPROCS), `error`

#### `system.num_cpu()`
**Permission:** `system.read` on `cpu`  
**Returns:** `number`, `error`

#### `system.hostname()`
**Permission:** `system.read` on `hostname`  
**Returns:** `string`, `error`

#### `system.pid()`
**Permission:** `system.read` on `pid`  
**Returns:** `number`, `error`

---

## Performance Profiling Integration

When started with `-p` flag, pprof HTTP server available at `localhost:6060`:

- `/debug/pprof/` - Profile index
- `/debug/pprof/profile?seconds=N` - CPU profile
- `/debug/pprof/allocs` - Memory allocation profile
- `/debug/pprof/heap` - Heap memory profile
- `/debug/pprof/goroutine` - Goroutine stack traces
- `/debug/pprof/cmdline` - Command line arguments
- `/debug/pprof/symbol` - Symbol lookup
- `/debug/pprof/trace?seconds=N` - Execution trace

---

## Thread Safety

All functions are safe for concurrent use from multiple Lua coroutines. Global setting modifications are internally synchronized.