# Lua Environment Module Specification

## Overview

The `env` module provides a Lua interface for accessing environment variables that are shared from the Go runtime. It
allows
Lua code to retrieve environment variables in a safe and controlled manner.

## Module Interface

### Module Loading

```lua
local env = require("env")
```

### Functions

#### env.get(key: string)

Retrieves the value of a specific environment variable.

Parameters:

- `key`: String identifier for the environment variable to retrieve

Returns:

- `value`: The value of the environment variable (or nil if not found)
- `error`: Error message string (or nil on success)

Example:

```lua
local value, err = env.get("PATH")
if err then
    print("Error:", err)
else
    print("PATH =", value)
end
```

#### env.get_all()

Retrieves all available environment variables as a table.

Returns:

- `table`: Table containing all environment variables (key-value pairs)
- `error`: Error message string (or nil on success)

Example:

```lua
local vars, err = env.get_all()
if err then
    print("Error:", err)
else
    for k, v in pairs(vars) do
        print(k, "=", v)
    end
end
```

## Error Handling

The module returns errors in the following cases:

1. **Missing Context:** When no context is found or the context is invalid

```lua
local value, err = env.get("PATH")  -- err: "no context found" or "invalid environment context"
```

2. **Empty Key:** When an empty key is provided

```lua
local value, err = env.get("")  -- err: "empty key provided"
```

3. **Variable Not Found:** When the requested environment variable doesn't exist

```lua
local value, err = env.get("NON_EXISTENT")  -- err: "environment variable not found: NON_EXISTENT"
```

## Best Practices

1. **Always check for errors:** Check both the value and error return values

```lua
local value, err = env.get("MY_VAR")
if err then
    -- Handle error
    return nil, err
end
-- Use value
```

2. **Use meaningful variable names:** Choose clear and descriptive environment variable names

3. **Cache frequently used values:** If you need to access the same environment variable multiple times

```lua
local config_path, err = env.get("CONFIG_PATH")
if err then
    return nil, err
end
-- Use config_path multiple times
```

4. **Validate environment variables early:** Check for required environment variables at startup

```lua
local function check_required_env()
    local required = {"API_KEY", "DATABASE_URL", "PORT"}
    for _, key in ipairs(required) do
        local value, err = env.get(key)
        if err then
            return false, "Missing required env var: " .. key
        end
    end
    return true
end
```

## Thread Safety

- The environment module is thread-safe
- Values are read-only from the Lua side
- Environment variables are managed by the Go runtime