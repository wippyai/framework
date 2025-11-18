<p align="center">
    <a href="https://wippy.ai" target="_blank">
        <picture>
            <source media="(prefers-color-scheme: dark)" srcset="https://github.com/wippyai/.github/blob/main/logo/wippy-text-dark.svg?raw=true">
            <img width="30%" align="center" src="https://github.com/wippyai/.github/blob/main/logo/wippy-text-light.svg?raw=true" alt="Wippy logo">
        </picture>
    </a>
</p>
<h1 align="center">Bootloader Module</h1>
<div align="center">

[![Latest Release](https://img.shields.io/github/v/release/wippyai/module-bootloader?style=flat-square)][releases-page]
[![License](https://img.shields.io/github/license/wippyai/module-bootloader?style=flat-square)](LICENSE)
[![Documentation](https://img.shields.io/badge/Wippy-Documentation-brightgreen.svg?style=flat-square)][wippy-documentation]

</div>


> [!NOTE]
> This repository is read-only.
> The code is generated from the [wippyai/framework][wippy-framework] repository.


The bootloader module orchestrates application initialization by discovering and executing bootloader functions in a defined order during application startup.

## Overview

The bootloader acts as an **orchestrator** that:
- Discovers all bootloader functions from the registry
- Sorts them by execution order (using `meta.order`)
- Executes each bootloader sequentially
- Collects results and handles errors
- Reports final initialization status

## Architecture

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

## What is a Bootloader?

A **bootloader** is a self-contained function that performs a specific initialization task at application startup. Each bootloader:

- Is **autonomous** - operates independently
- Has an **order** - determines execution sequence (lower values execute first)
- Is **idempotent** - checks its own execution conditions
- **Reports status** - returns success, error, or skipped

## Built-in Bootloaders

### 1. Encryption Key Bootloader
- **Order:** 10
- **Purpose:** Generate `ENCRYPTION_KEY` environment variable if not exists
- **Location:** `wippy.bootloader.bootloaders:encryption_key`

### 2. Database Migration Bootloader
- **Order:** 20
- **Purpose:** Execute database migrations for all configured databases
- **Location:** `wippy.migration:migration_bootloader`
- **Dependencies:**
  - `wippy.bootloader.bootloaders:encryption_key` (bootloader)
  - `app:db` (service)
- **Note:** Provided by the `wippy/migration` component

## Dependencies

Bootloaders can declare two types of dependencies using `meta.requires`:

### 1. Bootloader Dependencies
Ensures execution order between bootloaders:

```yaml
- name: my_bootloader
  kind: function.lua
  meta:
    type: bootloader
    order: 30
    requires:
      - wippy.bootloader.bootloaders:encryption_key
```

### 2. Service Dependencies
Waits for service availability before execution:

```yaml
- name: my_bootloader
  kind: function.lua
  meta:
    type: bootloader
    order: 25
    requires:
      - app:db          # Waits for database service
      - system:cache    # Waits for cache service
```

### Dependency Detection

Dependencies are automatically detected by ID format:
- **Service:** `app:db`, `system:logger` (simple namespace)
- **Bootloader:** `wippy.bootloader.bootloaders:encryption_key` (namespace with dots)

### Rules

**Bootloader Dependencies:**
- Must complete successfully (or be skipped)
- Should have lower `order` values
- Use fully-qualified IDs

**Service Dependencies:**
- Waits up to 10 seconds for service availability
- Service must be registered in the registry
- Useful for databases, external services, etc.

Missing dependencies cause startup failure.

## Creating Custom Bootloaders

Any module can provide bootloaders by:

1. Adding a dependency on `wippy/bootloader`
2. Implementing a bootloader function with the `run` method
3. Registering it with `meta.type: bootloader` and appropriate `meta.order`

### Example

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

## Execution Order

Bootloaders execute in ascending order based on `meta.order`:

- **1-10** - Critical infrastructure (encryption keys, certificates)
- **11-20** - Database operations (migrations, connections)
- **21-30** - Business logic (seed data, reference tables)
- **31-40** - Caching and optimization
- **41-50** - Non-critical checks and notifications

Bootloaders with the same `order` execute in alphabetical order by their ID.

## Error Handling

When a bootloader returns `status = "error"`:
1. Execution stops immediately
2. Subsequent bootloaders are not executed
3. The bootloader service reports failure
4. Application startup fails

## Documentation

For detailed specification and advanced usage, see:
- [Bootloader Specification](src/docs/bootloader.spec.md)

## How It Works

1. **Discovery** - The bootloader finds all entries in the registry with `meta.type: bootloader`
2. **Sorting** - Entries are sorted by `meta.order` (ascending), then alphabetically by ID
3. **Execution** - Each bootloader's `run` function is called with options
4. **Result Handling** - Status is logged and tracked (success/error/skipped)
5. **Failure Handling** - On error, execution stops and the service fails

## Integration

The bootloader runs automatically during application startup as a service with `auto_start: true`. It must complete successfully before other services start.

Other components can provide their own bootloaders by:
- Adding `wippy/bootloader` as a dependency
- Defining bootloader functions with appropriate `order` values
- Registering them with `meta.type: bootloader`


[wippy-documentation]: https://docs.wippy.ai
[releases-page]: https://github.com/wippyai/module-bootloader/releases
[wippy-framework]: https://github.com/wippyai/framework
