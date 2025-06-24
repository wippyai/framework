# Security Package Specification

## Overview

The security package provides a Lua interface for managing authentication, authorization, and access control. It includes functionality for working with actors, scopes, policies, and token stores.

## Loading the Module

```lua
local security = require("security")
```

## Core Concepts

### Actor

Represents an entity performing actions in the system:
- Has an ID (string)
- Contains metadata (key-value pairs)

### Scope

A collection of policies that define permissions:
- Can be extended or reduced with policies
- Can evaluate actions against actors and resources

### Policy

Defines rules for authorization decisions:
- Has an ID (namespace:name format)
- Evaluates if an actor can perform an action on a resource

### Token Store

Manages authentication tokens:
- Validates tokens to get actor and scope
- Creates new tokens for actors with specific scopes

## API Reference

### Context Operations

#### Get Current Actor

```lua
-- Returns the actor from the current context or nil if not available
local actor = security.actor()
-- Return: actor userdata or nil
```

#### Get Current Scope

```lua
-- Returns the scope from the current context or nil if not available
local scope = security.scope()
-- Return: scope userdata or nil
```

#### Check Permission

```lua
-- Checks if the current actor can perform an action on a resource
local allowed = security.can("update", "document:123", {owner = "user456"})
-- Parameters:
--   action (string): The action to check (e.g., "read", "update", "delete")
--   resource (string): The resource identifier
--   metadata (table, optional): Additional context for the permission check
-- Return: boolean (true if allowed, false otherwise)
```

### Policy Management

#### Get Policy

```lua
-- Retrieves a policy by ID
local policy, err = security.policy("system:admin_policy")
-- Parameters:
--   id (string): Policy ID in "namespace:name" format
-- Returns on success: policy userdata, nil
-- Returns on error: nil, error message
```

#### Get Named Scope

```lua
-- Retrieves a policy group as a scope
local scope, err = security.named_scope("global:admin")
-- Parameters:
--   id (string): Policy group ID in "namespace:name" format
-- Returns on success: scope userdata, nil
-- Returns on error: nil, error message
```

#### Create New Scope

```lua
-- Creates a new scope, optionally with initial policies
local new_scope = security.new_scope({policy1, policy2})
-- Parameters:
--   policies (table, optional): Array of policy objects to include in scope
-- Return: scope userdata
```

#### Create Actor

```lua
-- Creates a new actor
local actor = security.new_actor("user123", {role = "admin", org = "company"})
-- Parameters:
--   id (string): Actor identifier
--   metadata (table, optional): Actor metadata
-- Return: actor userdata
```

### Token Store Operations

#### Get Token Store

```lua
-- Retrieves a token store resource
local token_store, err = security.token_store("system.security:auth.tokens")
-- Parameters:
--   id (string): Resource ID in "namespace:name" format
-- Returns on success: token_store userdata, nil
-- Returns on error: nil, error message
```

## Actor Methods

#### Get Actor ID

```lua
-- Returns the actor's ID
local id = actor:id()
-- Return: string
```

#### Get Actor Metadata

```lua
-- Returns the actor's metadata as a table
local metadata = actor:meta()
-- Return: table of key-value pairs
```

## Scope Methods

#### Check if Scope Contains Policy

```lua
-- Checks if the scope contains a specific policy
local has_policy = scope:contains("system:admin_policy")
-- Parameters:
--   policy_id (string or userdata or table): Policy ID as string, policy object, or table with ns/name fields
-- Return: boolean
```

#### Get All Policies in Scope

```lua
-- Returns an array of all policies in the scope
local policies = scope:policies()
-- Return: array of policy objects
```

#### Evaluate Permission

```lua
-- Evaluates if an action is allowed for an actor on a resource
local result = scope:evaluate(actor, "delete", "resource:xyz", {owner = "user789"})
-- Parameters:
--   actor (userdata): Actor object
--   action (string): Action to check
--   resource (string): Resource identifier
--   metadata (table, optional): Additional context
-- Return: string ("allow", "deny", or "undefined")
```

#### Add Policy to Scope

```lua
-- Creates a new scope with an additional policy
local extended_scope = scope:with(policy)
-- Parameters:
--   policy (userdata): Policy to add
-- Return: new scope userdata
```

#### Remove Policy from Scope

```lua
-- Creates a new scope without a specific policy
local reduced_scope = scope:without("system:read_only")
-- Parameters:
--   policy_id (string or userdata or table): Policy ID as string, policy object, or table with ns/name fields
-- Return: new scope userdata
```

## Policy Methods

#### Get Policy ID

```lua
-- Returns the policy's ID
local id = policy:id()
-- Return: string in "namespace:name" format
```

#### Evaluate Policy

```lua
-- Evaluates if this policy allows an action for an actor on a resource
local result = policy:evaluate(actor, "read", "document:456", {owner = "user789"})
-- Parameters:
--   actor (userdata): Actor object
--   action (string): Action to check
--   resource (string): Resource identifier
--   metadata (table, optional): Additional context
-- Return: string ("allow", "deny", or "undefined")
```

## Token Store Methods

#### Validate Token

```lua
-- Validates a token and returns the associated actor and scope
local actor, scope, err = token_store:validate("eyJhbGciOiJ...")
-- Parameters:
--   token (string): Token to validate
-- Returns on success: actor userdata, scope userdata, nil
-- Returns on error: nil, nil, error message
```

#### Create Token

```lua
-- Creates a new token for an actor with a specific scope
local token, err = token_store:create(actor, scope, {
  expiration = "24h",
  meta = {
    device = "mobile",
    ip = "192.168.1.1"
  }
})
-- Parameters:
--   actor (userdata): Actor for the token
--   scope (userdata): Scope for the token
--   options (table, optional):
--     expiration (string or number): Token lifetime as duration string ("24h", "30m") or milliseconds
--     meta (table): Additional metadata for the token
-- Returns on success: token string, nil
-- Returns on error: nil, error message
```

#### Close Token Store

```lua
-- Releases the token store resource
local success = token_store:close()
-- Return: boolean (true on success)
```

## Example Usage

### Basic Authorization

```lua
local security = require("security")

-- Check if current actor can perform an action
local can_update = security.can("update", "document:123")
if can_update then
    -- Proceed with update
else
    -- Handle permission denied
end
```

### Working with Scopes and Policies

```lua
local security = require("security")

-- Get named scope and policy
local admin_scope, err = security.named_scope("global:admin")
local read_policy, err = security.policy("system:read_only")

if admin_scope and read_policy then
    -- Check if admin scope contains read policy
    if admin_scope:contains(read_policy) then
        print("Admin scope includes read-only policy")
    end
    
    -- Create a new restricted scope
    local restricted = admin_scope:without("system:full_access")
    
    -- Create a new actor
    local actor = security.new_actor("user123", {role = "viewer"})
    
    -- Check if actor can perform action with the restricted scope
    local result = restricted:evaluate(actor, "view", "document:456")
    print("View permission: " .. result) -- "allow", "deny", or "undefined"
end
```

### Token Management

```lua
local security = require("security")

-- Get token store
local token_store, err = security.token_store("system.security:auth.tokens")
if not token_store then
    error("Failed to get token store: " .. (err or "unknown error"))
end

-- Validate an existing token
local actor, scope, err = token_store:validate("eyJhbGciOiJ...")
if actor and scope then
    print("Token is valid for actor: " .. actor:id())
    
    -- Check specific permission with the token's scope
    local can_access = scope:evaluate(actor, "access", "api:endpoint")
    if can_access == "allow" then
        -- Grant access
    end
else
    print("Invalid token: " .. (err or "unknown error"))
end

-- Create a new token
local actor = security.new_actor("user456", {role = "editor"})
local base_scope, _ = security.named_scope("roles:editor")
local token, err = token_store:create(actor, base_scope, {
    expiration = "8h",
    meta = {
        device = "desktop",
        source = "login"
    }
})

if token then
    print("Created new token: " .. token)
else
    print("Failed to create token: " .. err)
end

-- Always close the token store when done
token_store:close()
```