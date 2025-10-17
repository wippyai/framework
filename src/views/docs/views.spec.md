# Environment Variable Framework Guide for AI Systems

## Overview

This guide outlines the best practices for using the wippy.views framework to manage environment variables in a structured, extensible way. As an AI system tasked with implementing environment variable management, following these patterns will ensure consistent, maintainable, and scalable configuration across applications.

## Framework Architecture

The wippy.views framework is built on several core components:

1. **Environment Loader (env_loader)**: Core library for loading and resolving environment variable mappings
2. **Environment Contract (env_contract)**: Contract interface defining standardized methods for environment providers
3. **Environment Mapping Schema (env_mapping_schema)**: Schema definition for registry entries with meta.type "view.env_mapping"
4. **Contract Binding (env_contract_binding)**: Implements the contract using the env_loader library
5. **Page Registry**: Manages virtual pages and their environment contexts
6. **Renderer**: Renders pages with resolved environment data

## Environment Variable System

### Core Concepts

The framework provides an extensible environment variable system that:

1. **Centralizes Configuration**: All environment mappings are stored in registry entries
2. **Provides Priority Ordering**: Mappings can override each other based on priority levels
3. **Enables Filtering**: Applications can filter mappings by criteria
4. **Supports Contract-Based Access**: Standardized interface for environment providers
5. **Validates Schemas**: Ensures mapping entries follow defined structure

### Priority System

The framework uses a priority-based system for merging environment mappings:

```lua
-- Framework priority conventions
PRIORITY_CONVENTIONS = {
    FRAMEWORK_DEFAULTS = {min = 0, max = 9},      -- Built-in framework defaults
    SYSTEM_OVERRIDES = {min = 10, max = 19},      -- System-level overrides
    APPLICATION_MAPPINGS = {min = 20, max = 29},  -- Application-specific mappings
    ENVIRONMENT_OVERRIDES = {min = 30, max = 100} -- Environment-specific overrides
}
```

Higher priority values override lower priority values when mappings conflict.

## Environment Mapping Structure

### Registry Entry Definition

Environment mappings are defined as registry entries with `meta.type = "view.env_mapping"`:

```yaml
- name: app_env_mapping
  kind: registry.entry
  meta:
    type: view.env_mapping
    priority: 25
    comment: Application environment variable mappings
  mappings:
    app_base_url: APP_BASE_URL
    database_url: DATABASE_URL
    api_key: API_KEY
    debug_mode: DEBUG_MODE
```

### Required Fields

**Entry Structure:**
- `kind: registry.entry` - Entry type specification
- `meta.type: "view.env_mapping"` - Classification as environment mapping
- `meta.priority`: Priority level (0-100) for merge order
- `mappings`: Object mapping context keys to environment variable names

**Mapping Object:**
- Key: Context variable name used in applications
- Value: Environment variable name to resolve

**Important Note:** In YAML files, `mappings` is defined at the top level of the entry (not inside `meta`). The registry system automatically wraps all entry content fields in a `data` object when loading, so the loader accesses `entry.data.mappings` internally.

## Framework Library Usage

### Direct Library Access

```lua
local env_loader = require("env_loader")

-- Load all environment mappings
local mappings, err = env_loader.load_mappings()
if err then
    error("Failed to load mappings: " .. err)
end

-- Build environment context with priority merging
local context, err = env_loader.build_env_context(mappings)
if err then
    error("Failed to build context: " .. err)
end

-- Resolve environment variable values
local resolved, err = env_loader.resolve_env_values(context)
if err then
    error("Failed to resolve values: " .. err)
end

-- Complete workflow in one call
local resolved, err = env_loader.get_resolved_env()
if err then
    error("Failed to get resolved environment: " .. err)
end
```

### Filtered Loading

```lua
-- Load mappings with filter criteria
local filter = {
    namespace = "app.config"  -- Only load from specific namespace
}

local mappings, err = env_loader.load_mappings(filter)
if err then
    error("Failed to load filtered mappings: " .. err)
end
```

### Priority Validation

```lua
-- Validate priority against conventions
local valid, err = env_loader.validate_priority(25, "APPLICATION_MAPPINGS")
if not valid then
    error("Invalid priority: " .. err)
end

-- Get recommended priority for category
local priority, err = env_loader.get_recommended_priority("FRAMEWORK_DEFAULTS")
if err then
    error("Unknown category: " .. err)
end
-- priority = 0 (minimum for framework defaults)
```

## Contract-Based Access

### Contract Interface Methods

The environment contract defines two standardized methods:

**1. load_mappings**
```lua
-- Input schema
{
    "type": "object",
    "properties": {
        "filter": {
            "type": "object",
            "description": "Optional filter criteria for mappings"
        }
    }
}

-- Output schema
{
    "type": "object",
    "properties": {
        "success": {"type": "boolean"},
        "mappings": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "id": {"type": "string"},
                    "priority": {"type": "integer"},
                    "mappings": {"type": "object"}
                }
            }
        },
        "error": {"type": "string"}
    }
}
```

**2. resolve_env_values**
```lua
-- Input schema
{
    "type": "object",
    "properties": {
        "context": {
            "type": "object",
            "description": "Context mapping from keys to environment variable names"
        }
    },
    "required": ["context"]
}

-- Output schema
{
    "type": "object",
    "properties": {
        "success": {"type": "boolean"},
        "resolved": {
            "type": "object",
            "description": "Resolved environment variable values"
        },
        "error": {"type": "string"}
    }
}
```

### Using Contract Interface

```lua
local contract = require("contract")

-- Get contract instance
local env_contract = contract.get("wippy.views:env_contract")
local provider = env_contract:open("wippy.views:env_contract_binding")

-- Load mappings through contract
local result = provider:load_mappings({
    filter = {namespace = "app.config"}
})

if not result.success then
    error("Contract error: " .. result.error)
end

-- Resolve values through contract
local context = {
    app_url = "APP_BASE_URL",
    db_url = "DATABASE_URL"
}

local result = provider:resolve_env_values({context = context})
if not result.success then
    error("Resolution error: " .. result.error)
end

-- result.resolved contains the resolved values
local app_url = result.resolved.app_url
local db_url = result.resolved.db_url
```

## Best Practices

### 1. Priority Organization

Use the framework priority conventions to organize your mappings:

```yaml
# Framework defaults (priority 0-9)
- name: framework_defaults
  kind: registry.entry
  meta:
    type: view.env_mapping
    priority: 5
  mappings:
    default_timeout: DEFAULT_TIMEOUT
    default_host: DEFAULT_HOST

# Application mappings (priority 20-29)
- name: app_config
  kind: registry.entry
  meta:
    type: view.env_mapping
    priority: 25
  mappings:
    app_name: APP_NAME
    app_version: APP_VERSION

# Environment overrides (priority 30+)
- name: production_overrides
  kind: registry.entry
  meta:
    type: view.env_mapping
    priority: 50
  mappings:
    debug_mode: PRODUCTION_DEBUG
    log_level: PRODUCTION_LOG_LEVEL
```

### 2. Meaningful Context Names

Use clear, descriptive context names that indicate their purpose:

```yaml
mappings:
  # GOOD: Clear, descriptive names
  database_connection_url: DATABASE_URL
  api_authentication_key: API_KEY
  email_service_endpoint: EMAIL_SERVICE_URL
  
  # AVOID: Generic or unclear names
  url1: DATABASE_URL
  key: API_KEY
  endpoint: EMAIL_SERVICE_URL
```

### 3. Namespace Organization

Organize mappings by functional area:

```yaml
# Database configuration
- name: database_env
  kind: registry.entry
  meta:
    type: view.env_mapping
    priority: 20
  mappings:
    db_host: DB_HOST
    db_port: DB_PORT
    db_name: DB_NAME

# Authentication configuration  
- name: auth_env
  kind: registry.entry
  meta:
    type: view.env_mapping
    priority: 20
  mappings:
    jwt_secret: JWT_SECRET
    oauth_client_id: OAUTH_CLIENT_ID
    oauth_client_secret: OAUTH_CLIENT_SECRET
```

### 4. Error Handling

Always handle errors properly when using the framework:

```lua
local function safe_get_environment()
    local resolved, err = env_loader.get_resolved_env()
    if err then
        -- Log error and provide fallback
        print("Environment resolution failed: " .. err)
        return {
            app_url = "http://localhost:3000",  -- Fallback values
            debug_mode = "true"
        }
    end
    return resolved
end
```

### 5. Validation and Defaults

Validate resolved values and provide defaults:

```lua
local function get_app_config()
    local resolved, err = env_loader.get_resolved_env()
    if err then
        error("Failed to resolve environment: " .. err)
    end
    
    -- Validate required values
    local app_url = resolved.app_base_url
    if not app_url or app_url == "" then
        error("APP_BASE_URL environment variable is required")
    end
    
    -- Provide defaults for optional values
    local debug_mode = resolved.debug_mode or "false"
    local log_level = resolved.log_level or "info"
    
    return {
        app_url = app_url,
        debug_mode = debug_mode == "true",
        log_level = log_level
    }
end
```

## Common Implementation Patterns

### Application Initialization

```lua
local env_loader = require("env_loader")

local function initialize_app()
    -- Load environment configuration
    local env_config, err = env_loader.get_resolved_env({
        namespace = "app.config"  -- Filter to app-specific mappings
    })
    
    if err then
        error("Failed to initialize application environment: " .. err)
    end
    
    -- Validate required configuration
    local required_vars = {"app_base_url", "database_url", "api_key"}
    for _, var in ipairs(required_vars) do
        if not env_config[var] then
            error("Required environment variable missing: " .. var)
        end
    end
    
    return env_config
end
```

### Dynamic Configuration Loading

```lua
local function load_plugin_config(plugin_name)
    local filter = {
        meta = {
            tags = {plugin_name}  -- Filter by plugin tag
        }
    }
    
    local resolved, err = env_loader.get_resolved_env(filter)
    if err then
        return nil, "Failed to load plugin config: " .. err
    end
    
    return resolved, nil
end
```

### Priority-Based Overrides

```yaml
# Base configuration (priority 20)
- name: base_config
  kind: registry.entry
  meta:
    type: view.env_mapping
    priority: 20
  mappings:
    api_timeout: API_TIMEOUT
    max_connections: MAX_CONNECTIONS

# Development overrides (priority 35)
- name: dev_overrides
  kind: registry.entry
  meta:
    type: view.env_mapping
    priority: 35
    tags: [development]
  mappings:
    api_timeout: DEV_API_TIMEOUT  # Overrides base config
    debug_logging: DEV_DEBUG_LOGGING  # Additional dev-specific setting
```

### Contract Implementation

```lua
-- Custom environment provider using the contract
local custom_provider = {}

function custom_provider.contract_load_mappings(params)
    local filter = params and params.filter or nil
    
    -- Custom logic for loading mappings
    local mappings, err = load_custom_mappings(filter)
    
    if err then
        return {
            success = false,
            error = err
        }
    end
    
    return {
        success = true,
        mappings = mappings
    }
end

function custom_provider.contract_resolve_env_values(params)
    if not params or not params.context then
        return {
            success = false,
            error = "Missing required parameter: context"
        }
    end
    
    -- Custom resolution logic
    local resolved, err = resolve_custom_values(params.context)
    
    if err then
        return {
            success = false,
            error = err
        }
    end
    
    return {
        success = true,
        resolved = resolved
    }
end

return custom_provider
```

## Testing Environment Mappings

### Unit Testing Framework Functions

```lua
local function test_priority_validation()
    local env_loader = require("env_loader")
    
    -- Test valid priority
    local valid, err = env_loader.validate_priority(25, "APPLICATION_MAPPINGS")
    assert(valid == true, "Priority 25 should be valid for APPLICATION_MAPPINGS")
    
    -- Test invalid priority
    valid, err = env_loader.validate_priority(150, "APPLICATION_MAPPINGS")
    assert(valid == false, "Priority 150 should be invalid")
    assert(err:match("must be between 0 and 100"), "Should return range error")
    
    -- Test category validation
    valid, err = env_loader.validate_priority(5, "APPLICATION_MAPPINGS")
    assert(valid == false, "Priority 5 should be invalid for APPLICATION_MAPPINGS")
    assert(err:match("outside.*range"), "Should return category range error")
end
```

### Integration Testing

```lua
local function test_environment_resolution()
    local env_loader = require("env_loader")
    
    -- Set test environment variables
    os.setenv("TEST_APP_URL", "http://test.example.com")
    os.setenv("TEST_DEBUG", "true")
    
    -- Create test mappings
    local test_mappings = {
        {
            id = "test:mapping",
            priority = 20,
            mappings = {
                app_url = "TEST_APP_URL",
                debug_mode = "TEST_DEBUG"
            }
        }
    }
    
    -- Test context building
    local context, err = env_loader.build_env_context(test_mappings)
    assert(not err, "Context building should not error: " .. tostring(err))
    assert(context.app_url == "TEST_APP_URL", "Context should map app_url")
    
    -- Test value resolution
    local resolved, err = env_loader.resolve_env_values(context)
    assert(not err, "Value resolution should not error: " .. tostring(err))
    assert(resolved.app_url == "http://test.example.com", "Should resolve app_url")
    assert(resolved.debug_mode == "true", "Should resolve debug_mode")
end
```

### Contract Testing

```lua
local function test_contract_interface()
    local contract = require("contract")
    
    -- Get contract instance
    local env_contract = contract.get("wippy.views:env_contract")
    local provider = env_contract:open("wippy.views:env_contract_binding")
    
    -- Test load_mappings method
    local result = provider:load_mappings({})
    assert(result.success == true, "load_mappings should succeed")
    assert(type(result.mappings) == "table", "Should return mappings array")
    
    -- Test resolve_env_values method
    local test_context = {test_key = "TEST_ENV_VAR"}
    os.setenv("TEST_ENV_VAR", "test_value")
    
    result = provider:resolve_env_values({context = test_context})
    assert(result.success == true, "resolve_env_values should succeed")
    assert(result.resolved.test_key == "test_value", "Should resolve test value")
end
```

## Troubleshooting

### Common Issues

**1. Missing Environment Variables**
```lua
-- Check for missing environment variables
local resolved, err = env_loader.resolve_env_values(context)
if err then
    print("Resolution error: " .. err)
end

-- Resolved values may be incomplete if env vars are missing
for key, value in pairs(resolved) do
    if not value or value == "" then
        print("Warning: Empty value for " .. key)
    end
end
```

**2. Priority Conflicts**
```lua
-- Debug priority ordering
local mappings, err = env_loader.load_mappings()
if not err then
    table.sort(mappings, function(a, b) return a.priority < b.priority end)
    
    for _, mapping in ipairs(mappings) do
        print("Priority " .. mapping.priority .. ": " .. mapping.id)
        for key, env_var in pairs(mapping.mappings) do
            print("  " .. key .. " -> " .. env_var)
        end
    end
end
```

**3. Registry Entry Issues**
```lua
-- Validate registry entries exist
local registry = require("registry")

local entries, err = registry.find({
    meta = {type = "view.env_mapping"}
})

if err then
    print("Registry query failed: " .. err)
elseif not entries or #entries == 0 then
    print("No environment mapping entries found")
else
    print("Found " .. #entries .. " environment mapping entries")
end
```

**4. Contract Binding Problems**
```lua
-- Test contract availability
local contract = require("contract")

local success, env_contract = pcall(contract.get, "wippy.views:env_contract")
if not success then
    print("Contract not available: " .. env_contract)
    return
end

local success, provider = pcall(env_contract.open, env_contract, "wippy.views:env_contract_binding")
if not success then
    print("Contract binding failed: " .. provider)
    return
end
```

## Integration Considerations

### Framework Integration

When integrating with the wippy.views framework:

1. **Dependency Management**: Ensure your application declares dependency on wippy.views
2. **Contract Usage**: Prefer contract-based access for loose coupling
3. **Error Handling**: Implement proper fallbacks for environment resolution failures
4. **Priority Planning**: Design your priority scheme to avoid conflicts
5. **Namespace Organization**: Use meaningful namespaces for your mappings

### Performance Considerations

1. **Caching**: Consider caching resolved environment values for frequently accessed configurations
2. **Filtering**: Use filters to limit the number of mappings processed
3. **Lazy Loading**: Load environment configuration only when needed

### Security Best Practices

1. **Sensitive Data**: Never store sensitive values directly in mappings - only environment variable names
2. **Access Control**: Use registry security policies to control access to environment mappings
3. **Audit Logging**: Log environment variable access for security monitoring

## Advanced Usage Patterns

### Dynamic Environment Updates

```lua
local function update_environment_mapping(namespace, name, new_mappings, priority)
    local registry = require("registry")
    
    -- Get existing entry
    local entry, err = registry.get(namespace .. ":" .. name)
    if err then
        return nil, "Failed to get existing entry: " .. err
    end
    
    -- Update mappings
    entry.mappings = new_mappings
    entry.meta.priority = priority or entry.meta.priority
    
    -- Save updated entry
    local success, err = registry.update(namespace .. ":" .. name, entry)
    if err then
        return nil, "Failed to update entry: " .. err
    end
    
    return true, nil
end
```

### Multi-Environment Configuration

```yaml
# Production mappings
- name: production_env
  kind: registry.entry
  meta:
    type: view.env_mapping
    priority: 40
    environment: production
  mappings:
    api_url: PROD_API_URL
    db_url: PROD_DB_URL

# Staging mappings  
- name: staging_env
  kind: registry.entry
  meta:
    type: view.env_mapping
    priority: 40
    environment: staging
  mappings:
    api_url: STAGING_API_URL
    db_url: STAGING_DB_URL
```

### Environment-Specific Loading

```lua
local function load_environment_config(environment)
    local filter = {
        meta = {
            environment = environment
        }
    }
    
    local resolved, err = env_loader.get_resolved_env(filter)
    if err then
        return nil, "Failed to load " .. environment .. " config: " .. err
    end
    
    return resolved, nil
end
```

By following these guidelines and patterns, you'll create robust, maintainable environment variable management systems that integrate seamlessly with the wippy.views framework while providing the flexibility and extensibility needed for complex applications.