# Bootloader

Application initialization orchestrator that discovers and runs bootloaders in dependency order.

Requires Wippy runtime **v0.3.44a or newer**. The auto-start service uses
`lifecycle.startup: complete`: application readiness waits for initialization to
finish successfully. A discovery or bootloader failure prevents `wippy test`
and `wippy run <command>` from running their entrypoint. Other services may
start concurrently; the gate does not serialize service startup.

## Installation

```yaml
entries:
  - name: bootloader
    kind: ns.dependency
    component: wippy/bootloader
    version: "*"
```

## Creating a Bootloader

```lua
-- bootloaders/my_bootloader.lua
local logger = require("logger")
local log = logger:named("boot.my")

local function run(options)
    log:info("Initializing my component")

    -- Do initialization work
    local success, err = initialize_something()
    if err then
        return {
            status = "error",
            message = "Failed to initialize: " .. err
        }
    end

    return {
        status = "success",
        message = "Initialized successfully"
    }
end

return { run = run }
```

## Registering a Bootloader

```yaml
entries:
  - name: my_bootloader
    kind: function.lua
    meta:
      type: bootloader
      order: 50
      description: Initialize my component
      requires:
        - wippy.bootloader.bootloaders:encryption_key
    source: file://bootloaders/my_bootloader.lua
    method: run
```

## Bootloader Metadata

- `type: bootloader` - Required to be discovered
- `order` - Execution order (lower runs first, default 999)
- `description` - Human-readable description
- `requires` - Dependencies (bootloader IDs or service IDs)

## Return Values

Bootloaders must return a table with:

```lua
{
    status = "success" | "error" | "skipped",
    message = "Description of result",
    details = { ... }  -- optional
}
```

## Calling the Orchestrator

The orchestrator's `run(options)` returns `stats, nil` on success, including when
no bootloaders are discovered, or `nil, error` on discovery or execution failure.
This differs from an individual bootloader's status-table return value above.
`run_chain(entries, options, satisfied)` retains its `success, stats` contract.

## Built-in Bootloaders

### encryption_key (order: 10)
Generates `ENCRYPTION_KEY` environment variable if not exists.

## Dependency Types

- **Bootloader IDs**: `wippy.bootloader.bootloaders:encryption_key`
- **Service IDs**: `app:db` (waits for service availability)
