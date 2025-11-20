# Registry Package Specification

## Overview

The Registry package provides a Lua interface for working with a distributed registry system. It offers operations for querying, creating, updating, and deleting registry entries, as well as version history management capabilities.

## Performance Considerations

**Important:** Snapshots are not free operations - they have performance and resource implications. For read-only operations, prefer using direct registry functions whenever possible instead of creating snapshots unnecessarily.

- Use direct `registry.get()` and `registry.find()` for simple read operations
- Only create snapshots when you need a consistent point-in-time view of multiple entries
- Reuse existing snapshots when performing multiple operations on the same dataset
- Release snapshots when no longer needed

## Module Interface

### Loading the Module

```lua
local registry = require("registry")
```

## Core Concepts

### Registry Entries

Each registry entry consists of:

- **ID**: A string identifier in "namespace:name" format
- **Kind**: Type classifier for the entry
- **Metadata**: A table of key-value pairs containing additional attributes
- **Data**: Arbitrary payload attached to the entry

### Snapshots

A snapshot represents a point-in-time view of the registry's state. Most operations are performed on snapshots to provide consistency. However, snapshots should only be used when necessary, as they have performance implications.

### Versioning

All changes to the registry are versioned. The registry maintains a complete history of changes that can be traversed and applied.

### Changes API

Changes to the registry are accumulated in a changeset before being applied atomically to create a new version.

## Module-Level Functions

### Direct Registry Access (Preferred for Read-Only Operations)

```lua
local entry, err = registry.get("namespace:name")
-- Parameters: id (string) - Entry ID in "namespace:name" format
-- Returns on success: entry table, nil
-- Returns on error: nil, error message
```

```lua
local entries, err = registry.find(criteria)
-- Parameters: criteria (table) - Search criteria
-- Returns on success: Array of matching entry tables, nil
-- Returns on error: nil, error message
```
## Module-Level Functions

### Get Current Snapshot

```lua
local snapshot, err = registry.snapshot()
-- Returns on success: snapshot object, nil
-- Returns on error: nil, error message
```

### Get Snapshot at Version

```lua
local snapshot, err = registry.snapshot_at(version_id)
-- Parameters: version_id (number) - Version ID to retrieve snapshot for
-- Returns on success: snapshot object, nil
-- Returns on error: nil, error message
```

### Get Current Version

```lua
local currentVersion, err = registry.current_version()
-- Returns on success: version object, nil
-- Returns on error: nil, error message
```

### List All Versions

```lua
local versions, err = registry.versions()
-- Returns on success: array of version objects, nil
-- Returns on error: nil, error message
```

### Apply Version (Rollback/Forward)

```lua
local success, err = registry.apply_version(version)
-- Parameters: version (version object) - Version to apply
-- Returns on success: true, nil
-- Returns on error: false, error message
```

### Parse ID String

```lua
local idTable = registry.parse_id("namespace:name")
-- Parameters: id_string (string) - ID in "namespace:name" format
-- Returns: ID table with {ns = "namespace", name = "name"}
```

### Get History Object

```lua
local history = registry.history()
-- Returns: history object
```

### Find Entries by Criteria

```lua
local entries, err = registry.find(criteria)
-- Parameters: criteria (table) - Search criteria
-- Returns on success: Array of matching entry tables, nil
-- Returns on error: nil, error message
```

### Get Specific Entry

```lua
local entry, err = registry.get("namespace:name")
-- Parameters: id (string) - Entry ID in "namespace:name" format
-- Returns on success: entry table, nil
-- Returns on error: nil, error message
```

### Build Delta Between States

```lua
local changeset, err = registry.build_delta(fromEntries, toEntries)
-- Parameters:
--   fromEntries (table) - Array of source entries
--   toEntries (table) - Array of target entries
-- Returns on success: array of operations, nil
-- Returns on error: nil, error message
```

## Snapshot Object Methods

### Get All Entries

```lua
local entries = snapshot:entries()
-- Returns: Array of entry tables
```

### Get Snapshot at Version

```lua
local snapshot, err = registry.snapshot_at(version_id)
-- Parameters: version_id (number) - Version ID to retrieve snapshot for
-- Returns on success: snapshot object, nil
-- Returns on error: nil, error message
```

### Get Current Version

```lua
local currentVersion, err = registry.current_version()
-- Returns on success: version object, nil
-- Returns on error: nil, error message
```

### List All Versions

```lua
local versions, err = registry.versions()
-- Returns on success: array of version objects, nil
-- Returns on error: nil, error message
```

### Apply Version (Rollback/Forward)

```lua
local success, err = registry.apply_version(version)
-- Parameters: version (version object) - Version to apply
-- Returns on success: true, nil
-- Returns on error: false, error message
```

### Parse ID String

```lua
local idTable = registry.parse_id("namespace:name")
-- Parameters: id_string (string) - ID in "namespace:name" format
-- Returns: ID table with {ns = "namespace", name = "name"}
```

### Get History Object

```lua
local history = registry.history()
-- Returns: history object
```

### Build Delta Between States

```lua
local changeset, err = registry.build_delta(fromEntries, toEntries)
-- Parameters:
--   fromEntries (table) - Array of source entries
--   toEntries (table) - Array of target entries
-- Returns on success: array of operations, nil
-- Returns on error: nil, error message
```

## Snapshot Object Methods

### Get All Entries

```lua
local entries = snapshot:entries()
-- Returns: Array of entry tables
```

### Get Specific Entry

```lua
local entry, err = snapshot:get("namespace:name")
-- Parameters: id (string) - Entry ID in "namespace:name" format
-- Returns on success: entry table, nil
-- Returns on error: nil, error message
```

### Get Entries by Namespace

```lua
local namespaceEntries = snapshot:namespace("services")
-- Parameters: namespace (string) - Namespace to filter by
-- Returns: Array of entry tables
```

### Find Entries by Criteria

```lua
local matchingEntries = snapshot:find(criteria)
-- Parameters: criteria (table) - Search criteria
-- Returns: Array of matching entry tables

-- Example:
local productionServices = snapshot:find({
  [".kind"] = "service",
  ["meta.environment"] = "production",
  ["*meta.region"] = "us-west"
})
```

### Create Changeset

```lua
local changes = snapshot:changes()
-- Returns: changeset object
```

### Get Snapshot Version

```lua
local version = snapshot:version()
-- Returns: version object for the snapshot
```

## Changes Object Methods

### Get Operations
```lua
local operations = changes:ops()
-- Returns: Array of operation tables, each containing:
--   - kind: Operation type ("entry.create", "entry.update", or "entry.delete")
--   - entry: The entry being operated on
```

### Create Entry

```lua
changes:create({
  id = "namespace:name", -- String ID format
  -- OR
  id = { ns = "namespace", name = "entry-name" }, -- Table ID format
  kind = "entry-kind",
  meta = {
    -- Metadata key-value pairs
    environment = "production",
    owner = "team-name"
  },
  data = {
    -- Any data to associate with the entry
  }
})
-- Returns: changeset object (for chaining)
```

### Update Entry

```lua
changes:update({
  id = "namespace:name", -- String ID format
  -- OR
  id = { ns = "namespace", name = "entry-name" }, -- Table ID format
  kind = "entry-kind", -- must match existing entry's kind
  meta = {
    -- Updated metadata (replaces existing metadata completely)
  },
  data = {
    -- Updated data (replaces existing data completely)
  }
})
-- Returns: changeset object (for chaining)
```

### Delete Entry

```lua
-- Using string ID
changes:delete("namespace:entry-name")

-- Or using table ID
changes:delete({ns = "namespace", name = "entry-name"})
-- Returns: changeset object (for chaining)
```

### Apply Changes

```lua
local version, err = changes:apply()
-- Returns on success: version object, nil
-- Returns on error: nil, error message
```

## History Object Methods

### List All Versions

```lua
local versions, err = history:versions()
-- Returns on success: array of version objects, nil
-- Returns on error: nil, error message
```

### Get Specific Version

```lua
local specificVersion, err = history:get_version(42)
-- Parameters: version_id (number) - Version ID to retrieve
-- Returns on success: version object, nil
-- Returns on error: nil, error message
```

### Get Snapshot at Specific Version

```lua
local oldSnapshot, err = history:snapshot_at(version)
-- Parameters: version (version object) - Version for the snapshot
-- Returns on success: snapshot object, nil
-- Returns on error: nil, error message
```

## Version Object Methods

### Get Version ID

```lua
local id = version:id()
-- Returns: version ID (number)
```

### Get Previous Version

```lua
local previousVersion = version:previous()
-- Returns: previous version object or nil if this is the first version
```

### Get Version String Representation

```lua
local versionString = version:string()
-- Returns: string representation of the version
```

## Search Criteria Format

The find function accepts a table of search criteria where:

### Special Fields

- `.kind`: Match entry's Kind field (exact match)
- `.name`: Match entry's ID.Name field (exact match)
- `.ns`: Match entry's ID.Namespace field (exact match)
- `.id`: Match entry's full ID (exact match)

### Metadata Matching Operators

- `field` or `meta.field`: Standard equality match for the field
- `~field` or `~meta.field`: Regex pattern match (e.g., "~description": ".*service.*")
- `*field` or `*meta.field`: Contains match (substring search)
- `^field` or `^meta.field`: Prefix match (starts with)
- `$field` or `$meta.field`: Suffix match (ends with)

## Example Usage

### Basic Operations Without Snapshots (Preferred for Read-Only)

```lua
-- Import the registry module
local registry = require("registry")

-- Get a specific entry directly (more efficient than creating a snapshot)
local entry, err = registry.get("services:database")
if entry then
  print("Found entry: " .. entry.id)
  print("Kind: " .. entry.kind)
  print("Environment: " .. (entry.meta.environment or "not set"))
else
  print("Entry not found: " .. (err or "unknown error"))
end

-- Find entries matching criteria directly
local productionServices, err = registry.find({
  [".kind"] = "service",
  ["meta.environment"] = "production"
})
if productionServices then
  print("Found " .. #productionServices .. " production services")
end
```

### Operations Using Snapshots (When Consistency is Required)

```lua
-- Get the current snapshot
local snapshot, err = registry.snapshot()
if not snapshot then
  print("Error getting snapshot: " .. tostring(err))
  return
end

-- Get a specific entry from the snapshot
local entry, err = snapshot:get("services:database")
if entry then
  print("Found entry: " .. entry.id)
  print("Kind: " .. entry.kind)
  print("Environment: " .. (entry.meta.environment or "not set"))
else
  print("Entry not found: " .. (err or "unknown error"))
end

-- Get all entries in a namespace from the snapshot
local services = snapshot:namespace("services")
print("Found " .. #services .. " services")

-- Find entries by criteria using the same snapshot
local productionServices = snapshot:find({
  [".kind"] = "service",
  ["meta.environment"] = "production",
  ["*meta.region"] = "us-west"
})
print("Found " .. #productionServices .. " production services in us-west")
```

### Advanced Searching

```lua
-- Find entries by criteria directly
local apiServices, err = registry.find({
  ["~meta.description"] = ".*api.*",
  ["^meta.status"] = "healthy"
})
if apiServices then
  print("Found " .. #apiServices .. " healthy API services")
end
```

### Making Changes

```lua
-- Create a changeset from the snapshot
local snapshot, err = registry.snapshot()
if not snapshot then
  print("Error getting snapshot: " .. tostring(err))
  return
end

local changes = snapshot:changes()

-- Create a new entry
changes:create({
  id = "services:new-service",
  kind = "service",
  meta = {
    environment = "staging",
    owner = "platform-team",
    tags = {"microservice", "api"}
  },
  data = {
    port = 8080,
    limits = {memory = "1Gi", cpu = "0.5"}
  }
})

-- Update an existing entry
changes:update({
  id = "config:rate-limits",
  kind = "config",
  meta = {
    updated = os.time(),
    revision = 3
  },
  data = {
    rate = 100,
    burst = 200
  }
})

-- Delete an entry
changes:delete("services:deprecated-service")

-- Apply changes to create a new version
local version, err = changes:apply()
if version then
  print("Created version: " .. version:id())
else
  print("Error applying changes: " .. tostring(err))
end
```

### Working with Version History

```lua
-- Get history object
local history = registry.history()

-- Get current version
local currentVersion, err = registry.current_version()
if currentVersion then
  print("Current version: " .. currentVersion:id())
else
  print("Error getting current version: " .. tostring(err))
end

-- List all versions
local versions, err = history:versions()
if versions then
  for i, ver in ipairs(versions) do
    print(i .. ". Version: " .. ver:id() .. " - " .. ver:string())
    
    -- Navigate version chain
    local prev = ver:previous()
    if prev then
      print("   Previous: " .. prev:id())
    end
  end
else
  print("Error getting versions: " .. tostring(err))
end

-- Get a snapshot at a specific version
local oldVersion, err = history:get_version(42)
if oldVersion then
  local oldSnapshot, err = history:snapshot_at(oldVersion)
  if oldSnapshot then
    local entriesAtVersion = oldSnapshot:entries()
    print("Found " .. #entriesAtVersion .. " entries at version 42")
    
    -- Search within the historical snapshot
    local oldServices = oldSnapshot:find({[".kind"] = "service"})
    print("Found " .. #oldServices .. " services at version 42")
  else
    print("Error getting snapshot: " .. tostring(err))
  end
else
  print("Error getting version: " .. tostring(err))
end

-- Apply a specific version (rollback)
local success, err = registry.apply_version(oldVersion)
if success then
  print("Successfully rolled back to version " .. oldVersion:id())
else
  print("Error rolling back: " .. tostring(err))
end
```

### Building and Applying State Deltas

```lua
-- Import the registry module
local registry = require("registry")

-- Get current registry state
local snapshot, err = registry.snapshot()
if not snapshot then
  print("Error getting snapshot: " .. tostring(err))
  return
end
local currentEntries = snapshot:entries()

-- Define a target state (could be loaded from files)
local targetEntries = {
  {
    id = "services:api",
    kind = "service",
    meta = { version = "2.0" },
    data = { port = 8080 }
  },
  -- more entries...
}

-- Build delta between current state and target state
local changeset, err = registry.build_delta(currentEntries, targetEntries)
if not changeset then
  print("Error building delta: " .. tostring(err))
  return
end

print("Delta contains " .. #changeset .. " operations")

-- Apply each operation in the changeset
local changes = snapshot:changes()

for _, op in ipairs(changeset) do
  if op.kind == "entry.create" then
    changes:create(op.entry)
    print("Adding: " .. op.entry.id)
  elseif op.kind == "entry.update" then
    changes:update(op.entry)
    print("Updating: " .. op.entry.id)
  elseif op.kind == "entry.delete" then
    changes:delete(op.entry.id)
    print("Removing: " .. op.entry.id)
  end
end

-- Apply changes to create a new version
local version, err = changes:apply()
if version then
  print("Updated registry to version: " .. version:id())
else
  print("Error applying changes: " .. tostring(err))
end
```
