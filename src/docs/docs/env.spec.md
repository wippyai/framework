# Environment Module Specification

## Overview

This specification defines a comprehensive environment storage system for LLM runtime environments, providing secure and flexible access to environment variables and configuration data. The `env` module provides a Lua interface for accessing environment variables that are shared from the Go runtime in a safe and controlled manner.

## Storage Architecture

### Storage Types

#### 1. Memory Storage (`env.storage.memory`)
- **Access**: Read-write
- **Persistence**: In-memory only
- **Use Cases**: Temporary variables, caching, runtime state
- **Lifecycle**: Session-bound

#### 2. File Storage (`env.storage.file`)
- **Access**: Read-write
- **Persistence**: File-based
- **Use Cases**: Configuration storage, persistent settings
- **Format**: Support for YAML, JSON, and plain text formats

#### 3. OS Storage (`env.storage.os`)
- **Access**: Read-only
- **Persistence**: System-managed
- **Use Cases**: System environment variables, secure configurations
- **Security**: Enforced read-only access for system integrity

### Configuration Schema

#### Environment Storage Definition
```yaml
- name: envos
  kind: env.storage.os
  meta:
    type: envstorage
    comment: OS storage for environment variables (read-only)
```

#### Variable Definition
```yaml
- name: home_env
  kind: env.variable
  meta:
    type: secret_key
    depends_on:
      - system:envos
  variable: HOME
  storage: system:envos
  readonly: true
```

## Module Interface

### Module Loading

```lua
local env = require("env")
```

### Core Functions

#### env.get(key: string)

Retrieves the value of a specific environment variable.

Parameters:

- `key`: String identifier for the environment variable to retrieve

Returns:

- `value`: The value of the environment variable (or nil if not found)
- `error`: Error message string (or nil on success)

**Behavior**: 
- Attempts direct access first
- Falls back to full name resolution
- Returns nil for non-existent variables

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

### Extended Storage Functions

#### env.set(variable_name, value)

Sets an environment variable value (storage-dependent).

Parameters:
- `variable_name` (string) - Name of the environment variable
- `value` (string) - Value to set

Returns:
- Boolean indicating success

**Behavior**:
- Returns false for read-only storage
- Returns true for successful write operations
- Storage-type dependent implementation

Example:

```lua
-- Write operations (storage-dependent)
local success = env.set('variable_name', 'value')  -- Returns boolean
if not success then
    print("Failed to set variable (read-only storage)")
end
```

## Variable Types

### System Variables
- **PATH**: System path configuration
- **HOME**: User home directory
- **USER**: Current user
- **TEMP/TMP**: Temporary directory paths

### Custom Variables
- **Configuration keys**: Application-specific settings
- **Secret keys**: Sensitive configuration data
- **Runtime variables**: Dynamic runtime state

## Security Considerations

### Read-Only Enforcement
- OS storage enforces read-only access
- Prevents accidental system modification
- Maintains system integrity

### Access Control
- Storage-based permission model
- Respect system-level permissions
- Container-aware security boundaries

## Error Handling

### Runtime Errors

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

### Storage-Level Errors

- **Variable not found**: Returns nil, no error thrown
- **Permission denied**: Returns false for set operations
- **Storage unavailable**: Graceful degradation
- **Invalid variable name**: Input validation

## Best Practices

### Error Handling Best Practices

1. **Always check for errors:** Check both the value and error return values

```lua
local value, err = env.get("MY_VAR")
if err then
    -- Handle error
    return nil, err
end
-- Use value
```

2. **Handle nil responses appropriately:** Use appropriate storage types for use cases
3. **Implement fallback mechanisms:** Always check return values

### General Best Practices

4. **Use meaningful variable names:** Choose clear and descriptive environment variable names

5. **Cache frequently used values:** If you need to access the same environment variable multiple times

```lua
local config_path, err = env.get("CONFIG_PATH")
if err then
    return nil, err
end
-- Use config_path multiple times
```

6. **Validate environment variables early:** Check for required environment variables at startup

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

## Cross-Platform Support

### Supported Platforms
- **Linux**: Full support for all storage types
- **Windows**: Native environment variable access
- **macOS**: POSIX-compliant implementation
- **Containers**: Docker/Podman compatible

### Platform-Specific Behaviors
- Windows: Support for both user and system variables
- Unix-like: Standard POSIX environment handling
- Container: Respects container isolation

## Testing Requirements

### Test Cases
1. **Basic OS variable access**
   - Verify common system variables (HOME, PATH, USER)
   - Test variable existence checking

2. **Full name variable access**
   - Test complete environment variable names
   - Verify case sensitivity handling

3. **Direct access patterns**
   - ENV_NAME direct access
   - Variable name resolution

4. **Read-only enforcement**
   - Verify OS storage write protection
   - Test permission boundaries

5. **Cross-platform compatibility**
   - Test on multiple operating systems
   - Verify container environment handling

6. **Error conditions**
   - Non-existent variable handling
   - Permission denied scenarios
   - Storage unavailability

## Integration Guidelines

### Runtime Integration
- Initialize storage systems at startup
- Configure appropriate storage types per use case
- Implement proper cleanup procedures

### Container Deployment
- Mount necessary environment files
- Configure storage permissions
- Handle container-specific paths

### Development Workflow
- Use memory storage for development variables
- File storage for configuration management
- OS storage for system integration

## Performance Considerations

- **Memory storage**: Fastest access, limited persistence
- **File storage**: Moderate performance, full persistence
- **OS storage**: System-dependent performance, read-only optimization

## Migration and Compatibility

### Version Compatibility
- Backward compatible API design
- Graceful handling of missing features
- Clear deprecation paths

### Data Migration
- Support for configuration migration
- File format evolution support
- Environment variable mapping

## Thread Safety

- The environment module is thread-safe
- Values are read-only from the Lua side
- Environment variables are managed by the Go runtime