# Lua UUID Module Specification

## Overview

The `uuid` module provides functions for generating, validating, and manipulating UUIDs (Universally Unique Identifiers)
using different UUID versions and formats. It is built on top of the Google UUID library to provide robust UUID handling
capabilities to Lua code.

## Module Interface

### Module Loading

```lua
local uuid = require("uuid")
```

### Error Handling

All functions in the module follow a consistent error handling pattern, returning two values:

1. The result value (or nil if an error occurred)
2. An error message string (or nil if operation was successful)

Example:

```lua
local id, err = uuid.v4()
if err then
    -- handle error
end
```

### Global Functions

#### uuid.v4()

Generates a new random UUID using version 4.

Returns:

- `string, error`: The generated UUID string in standard format (e.g., "110ec58a-a0f2-4ac4-8393-c866d813b8d1"), or nil
  and error message on failure

#### uuid.v7()

Generates a new time-ordered UUID using version 7.

Returns:

- `string, error`: The generated UUID string in standard format, or nil and error message on failure

#### uuid.v1()

Generates a new time-based UUID using version 1.

Returns:

- `string, error`: The generated UUID string in standard format, or nil and error message on failure

#### uuid.v3(namespace: string, name: string)

Generates a new namespace-based UUID using version 3 (MD5).

Parameters:

- `namespace`: A valid UUID string representing the namespace
- `name`: The name string to generate the UUID from

Returns:

- `string, error`: The generated UUID string in standard format, or nil and error message on failure

Errors:

- "namespace must be a string"
- "name must be a string"
- "invalid namespace UUID"

#### uuid.v5(namespace: string, name: string)

Generates a new namespace-based UUID using version 5 (SHA-1).

Parameters:

- `namespace`: A valid UUID string representing the namespace
- `name`: The name string to generate the UUID from

Returns:

- `string, error`: The generated UUID string in standard format, or nil and error message on failure

Errors:

- "namespace must be a string"
- "name must be a string"
- "invalid namespace UUID"

#### uuid.validate(str: string)

Validates if a string is a valid UUID.

Parameters:

- `str`: The string to validate

Returns:

- `boolean, error`: true if valid UUID, or nil and error message on failure

Errors:

- "input must be a string"

#### uuid.version(str: string)

Gets the version of a UUID.

Parameters:

- `str`: The UUID string to check

Returns:

- `number, error`: The UUID version (1-8), or nil and error message on failure

Errors:

- "input must be a string"
- "invalid UUID format"

#### uuid.variant(str: string)

Gets the variant of a UUID.

Parameters:

- `str`: The UUID string to check

Returns:

- `string, error`: The UUID variant ("RFC4122", "Microsoft", "NCS", or "Invalid"), or nil and error message on failure

Errors:

- "input must be a string"
- "invalid UUID format"

#### uuid.parse(str: string)

Parses a UUID string into its components.

Parameters:

- `str`: The UUID string to parse

Returns:

- `table, error`: Table containing parsed components, or nil and error message on failure:
    - `timestamp`: (for v1, v7) Unix timestamp
    - `node`: (for v1) Node ID
    - `version`: UUID version
    - `variant`: UUID variant

Errors:

- "input must be a string"
- "invalid UUID format"

#### uuid.format(str: string, format: string)

Formats a UUID string in different representations.

Parameters:

- `str`: The UUID string to format
- `format`: The desired format:
    - "standard" (default): "123e4567-e89b-12d3-a456-426614174000"
    - "simple": "123e4567e89b12d3a456426614174000"
    - "urn": "urn:uuid:123e4567-e89b-12d3-a456-426614174000"

Returns:

- `string, error`: The formatted UUID string, or nil and error message on failure

Errors:

- "input must be a string"
- "invalid UUID format"
- "unsupported format"

## Behavior

1. **Version 4 (Random):**
    - Generates cryptographically secure random UUIDs
    - No timestamp or node information
    - Suitable for general-purpose unique identifiers

2. **Version 7 (Time-ordered):**
    - Combines Unix timestamp with random data
    - Monotonically increasing for same-millisecond generation
    - Optimal for database primary keys

3. **Version 1 (Time-based):**
    - Uses timestamp and node identifier
    - May expose system information through node ID
    - Backwards compatibility support

4. **Version 3/5 (Namespace):**
    - Deterministic UUIDs based on namespace and name
    - v3 uses MD5, v5 uses SHA-1
    - Same inputs always generate same UUID

## Thread Safety

- The module is thread-safe
- All functions can be called concurrently
- No shared mutable state between calls

## Best Practices

1. **Error Handling:**
   ```lua
   local id, err = uuid.v4()
   if err then
       error(err)
   end
   ```

2. **Version Selection:**
    - Use v4 for general-purpose UUIDs
    - Use v7 for database keys and time-ordering
    - Use v5 for deterministic UUIDs (prefer over v3)
    - Use v1 only when specifically required

3. **Validation:**
    ```lua
    local valid, err = uuid.validate(input)
    if err then
        error(err)
    end
    if not valid then
        error("invalid UUID")
    end
    ```

4. **Performance:**
    - Cache namespace UUIDs when using v3/v5 repeatedly
    - Batch generate UUIDs when possible
    - Consider string format overhead in high-performance scenarios

## Example Usage

```lua
local uuid = require("uuid")

-- Generate different versions
local v4_id, err = uuid.v4()
if err then error(err) end

local v7_id, err = uuid.v7()
if err then error(err) end

local v1_id, err = uuid.v1()
if err then error(err) end

-- Namespace-based generation
local namespace = "6ba7b810-9dad-11d1-80b4-00c04fd430c8"  -- DNS namespace
local v5_id, err = uuid.v5(namespace, "example.com")
if err then error(err) end

-- Validation and inspection
local valid, err = uuid.validate(v4_id)
if err then error(err) end

if valid then
    local version, err = uuid.version(v4_id)
    if err then error(err) end
    
    local variant, err = uuid.variant(v4_id)
    if err then error(err) end
    
    print(string.format("Valid v%d UUID: %s (%s)", version, v4_id, variant))
end

-- Parsing
local info, err = uuid.parse(v7_id)
if err then error(err) end

if info then
    print(string.format("Generated at: %s", os.date("%c", info.timestamp)))
end

-- Different formats
local simple_format, err = uuid.format(v4_id, "simple")
if err then error(err) end

local urn_format, err = uuid.format(v4_id, "urn")
if err then error(err) end
```