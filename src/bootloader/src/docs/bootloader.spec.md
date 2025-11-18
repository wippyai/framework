# Bootloader Component Specification

The Bootloader component orchestrates application initialization by discovering and executing bootloader functions in a defined order.

## Overview

The Bootloader acts as an orchestrator that:
1. Discovers all bootloader functions from the registry
2. Sorts them by execution order
3. Executes each bootloader sequentially
4. Collects results and handles errors
5. Reports final initialization status

## Architecture

### Orchestration Flow

```
┌─────────────────────────────────────────┐
│   Bootloader Component (Orchestrator)   │
│                                         │
│  1. Discover bootloaders from registry  │
│  2. Sort by order (ascending)           │
│  3. Execute sequentially                │
│  4. Handle errors and stop on failure   │
│  5. Report statistics                   │
└─────────────────────────────────────────┘
              ↓
    ┌─────────┴─────────┬─────────────┐
    ↓                   ↓             ↓
┌──────────┐    ┌───────────────┐   ┌────────┐
│Bootloader│    │  Bootloader   │   │Bootldr │
│ order: 10│    │  order: 20    │   │ord: 30 │
└──────────┘    └───────────────┘   └────────┘
```

### Bootloader Concept

A **bootloader** is a self-contained function that performs a specific initialization task at application startup.

#### Key Principles

1. **Autonomy** - Each bootloader is independent and self-contained
2. **Ordering** - Bootloaders execute in order specified by `meta.order` (lower values execute first)
3. **Idempotency** - Each bootloader checks its own execution conditions
4. **Reporting** - Each bootloader returns execution status

## Bootloader Definition

### Metadata Structure

```yaml
entries:
  - name: my_bootloader
    kind: function.lua
    meta:
      type: bootloader              # Type identifier
      order: 10                     # Execution order (lower = earlier)
      description: What this does   # Human-readable description
      requires:                     # Optional: bootloader/service requirements
        - other:bootloader_id       # Must complete before this one
    source: file://my_bootloader.lua
    modules:                         # Required modules
      - logger
      - env
    imports:                         # Required imports
      some_lib: namespace:entry
    method: run                      # Function name to call
```

### Function Contract

Every bootloader must implement the `run` function with this signature:

```lua
local function run(options)
    -- options: table containing execution context
    --   - force: boolean - Force execution even if already done
    --   - dry_run: boolean - Simulate without making changes
    --   - context: table - Additional context data

    -- Perform initialization logic here

    -- Return result
    return {
        status = "success" | "error" | "skipped",
        message = "Human-readable result message",
        details = { ... },  -- Optional: detailed information
        duration = 1234,    -- Optional: execution time in ms
    }
end

return { run = run }
```

### Return Status Values

- **`success`** - Bootloader completed successfully
- **`error`** - Bootloader failed (stops execution of subsequent bootloaders)
- **`skipped`** - Bootloader skipped (already executed or conditions not met)

## Execution Order

Bootloaders are executed in ascending order based on `meta.order` value:

### Recommended Order Ranges

- **1-10** - Critical infrastructure (encryption keys, certificates)
- **11-20** - Database operations (migrations, connections)
- **21-30** - Business logic (seed data, reference tables)
- **31-40** - Caching and optimization
- **41-50** - Non-critical checks and notifications

Bootloaders with the same `order` value execute in alphabetical order by their fully-qualified ID.

## Dependencies

### Declaring Dependencies

Bootloaders can declare dependencies on:
1. **Other bootloaders** - ensures execution order
2. **Services** - waits for service availability

```yaml
- name: my_bootloader
  kind: function.lua
  meta:
    type: bootloader
    order: 30
    requires:
      - wippy.bootloader.bootloaders:encryption_key  # Bootloader dependency
      - app:db                                       # Service dependency
      - another.module:some_bootloader               # Bootloader dependency
```

### Dependency Checking

Before executing a bootloader, the orchestrator:

**For Bootloader Dependencies:**
1. Checks if the bootloader has completed (status: `success` or `skipped`)
2. If not completed, the bootloader fails with an error

**For Service Dependencies:**
1. Waits for the service to be available in the registry (max 20 attempts, 500ms delay)
2. If service doesn't become available, the bootloader fails with an error

If any dependency is not met, execution stops and application startup fails.

### Dependency Type Detection

The orchestrator automatically detects dependency types:

- **Service ID format:** `app:db`, `system:logger` (simple namespace without dots)
- **Bootloader ID format:** `wippy.bootloader.bootloaders:encryption_key` (namespace with dots)

### Dependency Rules

**Bootloader Dependencies:**
- Should have a **lower `order`** value than the dependent bootloader
- Can be from any module/package
- Use fully-qualified IDs (e.g., `namespace.subnamespace:name`)
- Both `success` and `skipped` bootloaders satisfy dependencies
- Failed bootloaders stop execution, so dependencies won't be met

**Service Dependencies:**
- Service must be registered in the registry
- Bootloader waits up to 10 seconds (20 attempts × 500ms) for service availability
- Useful for database connections, external services, etc.

### Example: Migration Bootloader

```yaml
- name: migration_bootloader
  kind: function.lua
  meta:
    type: bootloader
    order: 20
    description: Run database migrations for all targets
    requires:
      - wippy.bootloader.bootloaders:encryption_key  # Bootloader dependency
      - app:db                                       # Service dependency
  method: run
```

This ensures:
1. `encryption_key` bootloader (order: 10) completes successfully
2. `app:db` service is available in the registry
3. Only then `migration_bootloader` (order: 20) executes

## Built-in Bootloaders

### 1. Encryption Key Bootloader

**Location:** `wippy.bootloader.bootloaders:encryption_key`
**Order:** 10
**Purpose:** Generate ENCRYPTION_KEY environment variable if not exists

```yaml
- name: encryption_key
  kind: function.lua
  meta:
    type: bootloader
    order: 10
    description: Generate ENCRYPTION_KEY if not exists
  source: file://encryption_key_bootloader.lua
  method: run
```

### 2. Database Migration Bootloader

**Location:** `wippy.migration:migration_bootloader`
**Order:** 20
**Purpose:** Execute database migrations for all configured databases

```yaml
- name: migration_bootloader
  kind: function.lua
  meta:
    type: bootloader
    order: 20
    description: Run database migrations for all targets
  source: file://migration_bootloader.lua
  method: run
```

## Creating Custom Bootloaders

### Step 1: Implement Bootloader Function

Create a Lua file with the bootloader logic:

```lua
local logger = require("logger")
local log = logger:named("boot.custom")

local function run(options)
    log:info("Starting custom bootloader")

    -- Check if work needs to be done
    if already_initialized() then
        return {
            status = "skipped",
            message = "Already initialized"
        }
    end

    -- Perform initialization
    local success, err = perform_initialization()
    if not success then
        return {
            status = "error",
            message = "Initialization failed: " .. err
        }
    end

    return {
        status = "success",
        message = "Initialization completed"
    }
end

return { run = run }
```

### Step 2: Register in _index.yaml

Add an entry to your module's `_index.yaml`:

```yaml
entries:
  - name: custom_bootloader
    kind: function.lua
    meta:
      type: bootloader
      order: 25
      description: Custom initialization logic
    source: file://custom_bootloader.lua
    modules:
      - logger
    method: run
```

### Step 3: Deploy and Test

The bootloader will be automatically discovered and executed in the specified order during application startup.

## Error Handling

### Failure Behavior

When a bootloader returns `status = "error"`:
1. Execution stops immediately
2. Subsequent bootloaders are not executed
3. The bootloader service reports failure
4. Application startup fails

### Logging

All bootloader execution is logged with:
- Bootloader ID
- Execution order
- Status (success/error/skipped)
- Duration
- Result message
- Detailed information (if provided)

### Example Log Output

```
[INFO] boot: Starting application bootloader
[INFO] boot: Discovered bootloaders | count=2
[INFO] boot: Executing bootloader | id=wippy.bootloader.bootloaders:encryption_key order=10
[INFO] boot: SUCCESS: wippy.bootloader.bootloaders:encryption_key | duration=45ms message="Generated and persisted ENCRYPTION_KEY"
[INFO] boot: Executing bootloader | id=wippy.migration:migration_bootloader order=20
[INFO] boot: SUCCESS: wippy.migration:migration_bootloader | duration=1234ms message="Processed 1 database(s): 3 applied, 0 skipped"
[INFO] boot: Bootloader completed successfully | success=2 failed=0 skipped=0
```

## Best Practices

### Idempotency

Always check if work has already been done:

```lua
local function run(options)
    -- Check existing state
    if is_already_done() then
        return { status = "skipped", message = "Already completed" }
    end

    -- Perform work
    do_work()

    return { status = "success", message = "Work completed" }
end
```

### Error Messages

Provide clear, actionable error messages:

```lua
return {
    status = "error",
    message = "Failed to connect to database 'app:db' after 20 attempts",
    details = {
        database = "app:db",
        attempts = 20,
        last_error = "connection refused"
    }
}
```

### Logging

Use structured logging for better observability:

```lua
local logger = require("logger")
local log = logger:named("boot.myloader")

log:info("Starting initialization", { component = "my_service" })
log:error("Initialization failed", {
    component = "my_service",
    error = err,
    retries = 3
})
```

### Performance

Keep bootloader execution time minimal:
- Avoid unnecessary work
- Use timeouts for external operations
- Log slow operations for monitoring

## Integration with Other Components

### Migration Component

The Migration component provides its own bootloader:
- Located in `wippy.migration:migration_bootloader`
- Executes at `order: 20`
- Depends on `wippy/bootloader` component

### Custom Modules

Any module can provide bootloaders:
1. Add dependency on `wippy/bootloader`
2. Define bootloader functions
3. Register with `meta.type: bootloader`
4. Specify appropriate `order` value

## Testing

### Unit Testing Bootloaders

Test bootloader functions in isolation:

```lua
local my_bootloader = require("my_bootloader")

-- Test successful execution
local result = my_bootloader.run({})
assert(result.status == "success")

-- Test skip condition
setup_existing_state()
local result = my_bootloader.run({})
assert(result.status == "skipped")

-- Test error condition
setup_error_condition()
local result = my_bootloader.run({})
assert(result.status == "error")
```

### Integration Testing

Test bootloader execution order:

```lua
-- Verify bootloaders execute in correct order
local bootloaders = bootloader_registry.find()
assert(bootloaders[1].meta.order <= bootloaders[2].meta.order)
```

## Advanced Topics

### Conditional Execution

Use environment variables or configuration to conditionally execute:

```lua
local function run(options)
    local env = require("env")

    if env.get("SKIP_CUSTOM_INIT") == "true" then
        return { status = "skipped", message = "Disabled by configuration" }
    end

    -- Proceed with initialization
end
```

### Retry Logic

Implement retry logic for unreliable operations:

```lua
local function run(options)
    local max_retries = 3
    local retry_delay = "1s"

    for attempt = 1, max_retries do
        local success, err = try_operation()
        if success then
            return { status = "success", message = "Operation succeeded" }
        end

        if attempt < max_retries then
            time.sleep(retry_delay)
        end
    end

    return {
        status = "error",
        message = "Operation failed after " .. max_retries .. " attempts"
    }
end
```

### Detailed Reporting

Provide rich details for monitoring and debugging:

```lua
return {
    status = "success",
    message = "Processed 1000 records",
    details = {
        records_processed = 1000,
        records_skipped = 50,
        records_failed = 5,
        processing_time_ms = 5432,
        failures = {
            { record_id = 123, error = "validation failed" },
            { record_id = 456, error = "duplicate key" }
        }
    }
}
```
