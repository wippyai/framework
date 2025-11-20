# Store Package Specification

## Overview

The Store package provides a Lua interface to key-value stores. It exposes a consistent API for store operations that
works across different store implementations (in-memory, Redis, etc.). The module allows for storing, retrieving, and
managing structured data with support for Time-To-Live (TTL) expiration.

## Module Interface

### Loading the Module

```lua
local store = require("store")
```

## Core Concepts

### Resource Management

- Store connections are obtained from the resource registry
- All store resources are automatically cleaned up when the containing unit of work completes
- Store resources can be explicitly released earlier if needed using the `release` method

### Error Handling

- Most operations return `value, error` pairs
- Success is indicated by a result value + nil for error
- Failure is indicated by nil + error message
- Store connections are managed as resources with proper cleanup

### Keys and Values

- Keys are registry IDs in the format "namespace:name"
- Values can be any Lua data type (strings, numbers, booleans, tables)
- Complex Lua data structures (nested tables) are automatically serialized and deserialized

## Store Operations

### Getting a Store Connection

```lua
local storeObj, err = store.get("resource_id")
-- Parameters: resource_id (string) - Resource ID for the store
-- Returns on success: store object, nil
-- Returns on error: nil, error message
```

### Get Value

```lua
local value, err = storeObj:get(key)
-- Parameters: key (string) - Key to retrieve
-- Returns on success: value, nil
-- Returns on error: nil, error message
-- Note: Returns nil, "key not found" if the key doesn't exist
```

### Set Value

```lua
local success, err = storeObj:set(key, value[, ttl])
-- Parameters:
--   key (string): Key to set
--   value (any): Value to store
--   ttl (number, optional): Time-to-live in seconds
-- Returns on success: true, nil
-- Returns on error: nil, error message
```

### Delete Value

```lua
local success, err = storeObj:delete(key)
-- Parameters: key (string) - Key to delete
-- Returns on success: true, nil (if key existed and was deleted)
--                    false, nil (if key didn't exist)
-- Returns on error: nil, error message
```

### Check Key Existence

```lua
local exists, err = storeObj:has(key)
-- Parameters: key (string) - Key to check
-- Returns on success: boolean (true if key exists, false otherwise), nil
-- Returns on error: nil, error message
```

### Release Store Connection

```lua
local success = storeObj:release()
-- Returns: true (always succeeds)
-- Note: After release, store methods will fail
```

## Example Usage

### Basic Operations

```lua
-- Get store connection from resource registry
local storeObj, err = store.get("cache_store")
if err then error(err) end

-- Store a value
local success, err = storeObj:set("user:preferences", {
    theme = "dark",
    fontSize = 14,
    notifications = true
})
if err then error(err) end

-- Retrieve the value
local prefs, err = storeObj:get("user:preferences")
if err then error(err) end

if prefs then
    print("User theme: " .. prefs.theme)
    print("Font size: " .. prefs.fontSize)
end

-- Check if a key exists
local exists, err = storeObj:has("user:preferences")
if err then error(err) end

if exists then
    print("User preferences exist in store")
end

-- Delete a value
local success, err = storeObj:delete("user:preferences")
if err then error(err) end

-- Release the store when done
storeObj:release()
```

### Using TTL (Time-To-Live)

```lua
-- Get store connection from resource registry
local storeObj, err = store.get("session_store")
if err then error(err) end

-- Store a session with 30-minute expiration
local success, err = storeObj:set("session:12345", {
    user_id = 42,
    last_access = os.time(),
    data = { permissions = {"read", "write"} }
}, 1800) -- 30 minutes in seconds
if err then error(err) end

-- Later, retrieve the session (if not expired)
local session, err = storeObj:get("session:12345")
if err then error(err) end

if session then
    print("User ID: " .. session.user_id)
    print("Last access: " .. os.date("%Y-%m-%d %H:%M:%S", session.last_access))
else
    print("Session expired or not found")
end

-- Release the store when done
storeObj:release()
```

### Error Handling

```lua
-- Get store connection from resource registry
local storeObj, err = store.get("data_store")
if err then
    print("Failed to connect to store: " .. tostring(err))
    return
end

-- Try to get a value that might not exist
local value, err = storeObj:get("config:api_key")
if err then
    if err == "key not found" then
        print("API key not configured")
    else
        print("Error retrieving API key: " .. tostring(err))
    end
    return
end

-- Release the store when done
storeObj:release()
```

### Batch Processing

```lua
-- Get store connection from resource registry
local storeObj, err = store.get("inventory_store")
if err then error(err) end

-- Process multiple items
local items = {
    "item:1001",
    "item:1002",
    "item:1003"
}

local results = {}
for _, item_key in ipairs(items) do
    local item, err = storeObj:get(item_key)
    if err then
        if err ~= "key not found" then
            error("Failed to get " .. item_key .. ": " .. tostring(err))
        end
    else
        -- Process the item
        if item.quantity > 0 then
            table.insert(results, item)
            
            -- Update the item
            item.quantity = item.quantity - 1
            local success, err = storeObj:set(item_key, item)
            if err then error("Failed to update " .. item_key .. ": " .. tostring(err)) end
        end
    end
end

-- Release the store when done
storeObj:release()

return results
```
