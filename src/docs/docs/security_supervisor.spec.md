# Lua Security Permissions Specification

## Overview

This document specifies the security permissions system implemented across Lua modules in the Pony runtime. Every sensitive operation requires an explicit permission check using the security API.

## Permission Structure

Permissions follow the format: `{domain}.{action}[.{subaction}]`, with an optional resource identifier. The permission check system enforces least-privilege access control across all Lua modules.

### Permission Checking Mechanism

Permissions are checked using the `security.Can(context, permission, resource, metadata)` function:

- `context`: The current execution context containing actor and scope information
- `permission`: The permission string (e.g., "db.get")
- `resource`: Optional resource identifier (string) the permission applies to
- `metadata`: Optional additional contextual information

## Security Context

The security context consists of:

1. **Actor**: Entity performing actions (has ID and metadata)
2. **Scope**: Collection of policies defining permissions
3. **Policies**: Rules for authorization decisions

Tokens can be created that include specific actor and scope combinations, enabling fine-grained access control for different clients or services.

## Supervisor-Level Security Configuration

Security contexts can be configured at the supervisor level through the service lifecycle configuration. This provides a declarative way to define security properties for managed services:

```yaml
services:
  my_service:
    # Service configuration
    lifecycle:
      auto_start: true
      security:
        actor:
          id: "service_name"
          meta:
            role: "worker"
            team: "backend"
        policies:
          - "policy_id_1"
          - "policy_id_2"
        groups:
          - "worker_group"
          - "backend_services_group"
```

The supervisor automatically builds and injects the security context based on this configuration, making it available to the service at runtime. This approach ensures:

1. Consistent security context across service restarts
2. Centralized permission management
3. Clear, declarative permissions definition for each service
4. Audit capabilities through configuration version control

## Resource Identifiers

Resource identifiers follow the format `namespace:name` and are used to scope permissions to specific resources. For example:

- Database: `system.db:users_db`
- Filesystem: `system.fs:public`
- Process: `app.process:worker_pool`

## Core Security Modules

### Security Module
- `security.policy.get` - Access policies by ID
- `security.policy_group.get` - Access policy groups
- `security.scope.create` - Create custom scopes
    - Use "with" resource to add policies to scope
    - Use "without" resource to remove policies from scope
- `security.actor.create` - Create actors with specific IDs
- `security.token_store.get` - Access token store resources
- `security.token.validate` - Validate tokens (store ID as resource, token in metadata)
- `security.token.create` - Create tokens (store ID as resource, actor ID in metadata)
- `security.token.revoke` - Revoke tokens (store ID as resource, token in metadata)

### Function Module
- `funcs.context` - Execute functions with custom context values
- `funcs.security` - Execute functions with custom security context
- `funcs.call` - Call specific functions by ID (target function ID as resource)

## Resource Access Permissions

### File System
- `fs.get` - Access specific filesystem resources (filesystem name as resource)

### Execution
- `exec.get` - Access process executor resources (executor ID as resource)
- `exec.run` - Execute specific commands (command string as resource)

### Database
- `db.get` - Access database resources (database ID as resource)

### Storage
- `store.get` - Access key-value store resources (store ID as resource)
- `store.key.get` - Read specific keys (key as resource)
- `store.key.set` - Write specific keys (key as resource)
- `store.key.delete` - Delete specific keys (key as resource)
- `store.key.has` - Check key existence (key as resource)

### Cloud Storage
- `cloudstorage.get` - Access cloud storage resources (resource ID as resource)

## Communication Permissions

### Events
- `events.subscribe` - Subscribe to events from specific systems (system name as resource)

### HTTP Client
- `http_client.request` - Make HTTP requests to specific URLs (URL as resource)

### WebSocket
- `websocket.connect` - Establish WebSocket connections
- `websocket.connect.url` - Connect to specific WebSocket URLs (URL as resource)

### Environment Variables
- `env.get` - Access specific environment variables (variable name as resource)

## Process Permissions

### Process Lifecycle
- `process.spawn` - Spawn new processes (process ID as resource)
- `process.spawn.monitored` - Spawn monitored processes (process ID as resource)
- `process.spawn.linked` - Spawn linked processes (process ID as resource)
- `process.terminate` - Terminate specific processes (PID as resource)
- `process.cancel` - Cancel specific processes (PID as resource)

### Process Context
- `process.context` - Spawn processes with custom context
- `process.security` - Spawn processes with custom security context

### Process Topology
- `process.send` - Send messages to specific processes (PID as resource)
- `process.monitor` - Monitor specific processes (PID as resource)
- `process.unmonitor` - Stop monitoring specific processes (PID as resource)
- `process.link` - Link to specific processes (PID as resource)
- `process.unlink` - Unlink from specific processes (PID as resource)

### Process Registry
- `process.registry.register` - Register process names (name as resource)
- `process.registry.unregister` - Unregister process names (name as resource)

## System Permissions

### Registry
- `registry.apply` - Apply registry changes
- `registry.get` - Access specific registry entries (entry ID as resource)
- `registry.apply_version` - Apply specific registry versions

### System Information
- `system.read` - Read system information (resource types: "memory", "goroutines", "hostname", "pid", "cpu", "gomaxprocs", "gc_percent")
- `system.gc` - Force garbage collection (resource: "gc" or "gc_percent")
- `system.control` - Control system settings (resource: "gomaxprocs")

## Permission Handling Examples

### Rejection Example

When permissions are not granted, operations fail explicitly:

```lua
-- If security.Can(context, "db.get", "system.db:users", nil) returns false
local db = sql.get("system.db:users")
-- Results in: Error: not allowed to access database: system.db:users
```

### Token Store Authorization Example

```lua
-- Get token store
local store = security.token_store("system.security:auth_tokens")

-- Validate token (requires security.token.validate permission)
local actor, scope, err = store:validate("my_token")
-- Permission check uses store ID with token in metadata
-- security.Can(context, "security.token.validate", "system.security:auth_tokens", {token="my_token"})

-- Create token (requires security.token.create permission)
local token = store:create(actor, scope, {expiration="1h"})
-- Permission check uses store ID with actor ID in metadata
-- security.Can(context, "security.token.create", "system.security:auth_tokens", {actor=actor.id()})

-- Revoke token (requires security.token.revoke permission)
local success = store:revoke("my_token")
-- Permission check uses store ID with token in metadata
-- security.Can(context, "security.token.revoke", "system.security:auth_tokens", {token="my_token"})
```

### Key-Value Store Example

```lua
-- Get store (requires store.get permission)
local store = store.get("app.data:user_preferences")
-- security.Can(context, "store.get", "app.data:user_preferences", nil)

-- Read value (requires store.key.get permission)
local value, err = store:get("user:123:theme")
-- Permission check uses key as resource
-- security.Can(context, "store.key.get", "user:123:theme", nil)

-- Write value (requires store.key.set permission)
local success, err = store:set("user:123:theme", "dark")
-- Permission check uses key as resource
-- security.Can(context, "store.key.set", "user:123:theme", nil)
```

### Scope Modification Example

```lua
-- Create a scope (requires security.scope.create permission)
local scope = security.new_scope()

-- Add policy to scope (requires security.scope.create with "with" resource)
scope = scope:with(policy)
-- Security check: security.Can(context, "security.scope.create", "with", nil)

-- Remove policy from scope (requires security.scope.create with "without" resource)
scope = scope:without(policy_id)
-- Security check: security.Can(context, "security.scope.create", "without", nil)
```

### Security Context Separation

Security contexts are strictly separated from application contexts:

```lua
-- Create function executor with application context (requires permission)
local executor = funcs.new():with_context({ app_data = "value" }) 

-- Set security context (requires elevated permission)
executor = executor:with_actor(security.new_actor("admin"))
executor = executor:with_scope(admin_scope)
```

Security contexts cannot be removed, and modification attempts without proper permissions result in errors.