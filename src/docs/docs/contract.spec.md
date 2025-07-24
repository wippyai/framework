# Lua Contract Module Specification

## Overview

The Contract module provides a Lua interface for working with contracts - abstract service definitions that can be implemented by different bindings. It enables type-safe service discovery, instantiation, and method calling with proper security context management and both synchronous and asynchronous execution.

## Module Interface

### Module Loading

```lua
local contract = require("contract")
```

### Getting Contracts

```lua
local contract_def, err = contract.get("namespace:contract_name")
```

Returns a contract wrapper for the specified contract definition or error if not found/accessible.

### Finding Implementations

```lua
local binding_ids, err = contract.find_implementations("namespace:contract_name")
```

Returns an array of binding IDs that implement the specified contract.

### Checking Contract Implementation

```lua
local implements = contract.is(instance, "namespace:contract_name")
```

Returns `true` if the instance implements the specified contract, `false` otherwise. Throws an error if the first argument is not a valid instance userdata.

Parameters:
- `instance`: Contract instance userdata
- `contract_id`: String contract identifier in "namespace:name" format

Returns:
- Boolean indicating whether the instance implements the contract

## Contract Wrapper

The contract wrapper supports immutable chaining of security and application context.

### Context Chain Methods

#### with_context(context_table)

Creates a new contract wrapper with additional application context values.

```lua
local contract2 = contract_def:with_context({
    tenant_id = "123",
    cache_enabled = true
})

-- Chain multiple contexts (immutable)
local contract3 = contract.get("user:service")
    :with_context({ tenant = "123" })
    :with_context({ user = "john" })
```

Parameters:
- `context_table`: Table with string keys and any values

Returns:
- New contract wrapper with updated context (immutable operation)

#### with_actor(actor)

Creates a new contract wrapper with security actor context.

```lua
local secured_contract = contract_def:with_actor(current_user_actor)
```

Parameters:
- `actor`: Security actor userdata

Returns:
- New contract wrapper with actor context

#### with_scope(scope)

Creates a new contract wrapper with security scope context.

```lua
local scoped_contract = contract_def:with_scope(admin_scope)
```

Parameters:
- `scope`: Security scope userdata

Returns:
- New contract wrapper with scope context

### Contract Methods

#### open(binding_id?, context_table?)

Opens a contract binding to create an instance. If no binding_id is provided, uses the default binding for the contract (if one exists). Context values from the parameter merge with/override chained context.

```lua
-- Open with default binding (no arguments)
local instance, err = contract_def:open()

-- Open with specific binding
local instance, err = contract_def:open("user:database_impl")

-- Open with additional context (merges with chained context)
local instance, err = contract_def:open("user:database_impl", {
    database = "users_prod",
    timeout = 30
})

-- Open default binding with context
local instance, err = contract_def:open(nil, {
    database = "users_prod"
})

-- Open with binding parameters via query string format
local instance, err = contract_def:open("user:database_impl?timeout=30&retries=3")
```

Parameters:
- `binding_id`: Optional string binding identifier in "namespace:name" format, optionally with query parameters "namespace:name?key1=value1&key2=value2". If nil or not provided, uses the default binding for this contract.
- `context_table`: Optional table with additional context values (highest priority)

Returns:
- Contract instance or nil on error
- Error message or nil on success

**Note**: When using the default binding (no binding_id provided), the binding must require no context dependencies, or all required context must be available through chained context. If the default binding requires context that is not available, the open() call will fail.

#### id()

Returns the contract definition ID as a string.

```lua
local contract_id = contract_def:id()
```

#### methods()

Returns all methods defined in the contract with their schemas.

```lua
local methods = contract_def:methods()
for i, method in ipairs(methods) do
    print("Method:", method.name)
    print("Description:", method.description)
    
    -- Input schemas (array)
    if method.input_schemas then
        for j, schema in ipairs(method.input_schemas) do
            print("Input schema format:", schema.format)
            print("Input schema definition:", schema.definition)
        end
    end
    
    -- Output schemas (array)  
    if method.output_schemas then
        for j, schema in ipairs(method.output_schemas) do
            print("Output schema format:", schema.format)
            print("Output schema definition:", schema.definition)
        end
    end
end
```

#### method(method_name)

Returns a specific method definition with its schemas.

```lua
local method_def, err = contract_def:method("get_user")
```

Parameters:
- `method_name`: String method name

Returns:
- Method definition table or nil on error
- Error message or nil on success

#### implementations()

Returns all binding IDs that implement this contract.

```lua
local binding_ids, err = contract_def:implementations()
```

Returns:
- Array of binding ID strings or nil on error
- Error message or nil on success

## Contract Instance

The contract instance inherits all security and application context from the contract wrapper and provides dynamic method access. Instances are purely functional - they only support method calling, not introspection.

### Dynamic Method Calling

Contract instances support dynamic method access with both sync and async patterns:

```lua
-- Synchronous method call (returns direct Lua values)
local result, err = instance:method_name(arg1, arg2, arg3)

-- Asynchronous method call (returns command object)
local command = instance:method_name_async(arg1, arg2, arg3)
```

Methods are resolved dynamically based on the contracts the instance implements.

### Instance Introspection

To check what contracts an instance implements, use the module-level `contract.is()` function:

```lua
-- Check if instance implements a specific contract
if contract.is(instance, "user:service") then
    print("Instance implements user:service")
end

if contract.is(instance, "audit:logging") then
    print("Instance also implements audit:logging")
end
```

## Command Object

Async method calls return command objects for managing execution:

### Command Methods

#### is_complete()

Checks if the command has completed (successfully or with error).

```lua
local completed = command:is_complete()
```

Returns: boolean

#### result()

Returns the command's result and error (only available if command is complete).

```lua
local result_payload, err = command:result()
if err then
    print("Command failed:", err)
elseif result_payload then
    -- result_payload is a payload object
    local data = result_payload:data()
    print("Command succeeded:", data)
end
```

Returns:
- Payload userdata or nil
- Error message or nil

#### is_canceled()

Checks if the command was canceled.

```lua
local canceled = command:is_canceled()
```

Returns: boolean

#### cancel()

Cancels the command execution.

```lua
local success, err = command:cancel()
```

Returns:
- Boolean success
- Error message or nil

#### response()

Returns the response channel for the command.

```lua
local channel = command:response()
local value, ok = channel:receive()
```

Returns: channel userdata

## Usage Examples

### Default Binding Usage

```lua
local contract = require("contract")

-- Get contract definition
local user_service, err = contract.get("user:service")
if err then
    error("Failed to get contract: " .. err)
end

-- Open using default binding (if available and requires no context)
local instance, err = user_service:open()
if err then
    -- Fallback to specific binding if default doesn't work
    instance, err = user_service:open("user:database_impl")
    if err then
        error("Failed to open any binding: " .. err)
    end
end

-- Verify instance implements expected contract
if not contract.is(instance, "user:service") then
    error("Instance does not implement user:service")
end

-- Use the instance
local user, err = instance:get_user("user123")
```

### Default Binding with Context

```lua
-- Try default binding with required context
local service = contract.get("payment:processor")
    :with_context({
        api_key = "secret_key",
        environment = "production"
    })

-- Open default binding - will work if these context values satisfy requirements
local instance, err = service:open()
if err then
    print("Default binding failed:", err)
    -- Could fall back to specific binding
    instance, err = service:open("payment:stripe_impl")
end
```

### Early Initialization Pattern

```lua
-- During application startup (before runtime context is available)
local contract = require("contract")

-- Get contract definitions for schema validation and planning
local user_contract, err = contract.get("user:service")
if err then
    error("Required user service contract not available: " .. err)
end

-- Inspect contract schema during initialization
local methods = user_contract:methods()
print("User service provides", #methods, "methods:")
for i, method in ipairs(methods) do
    print("-", method.name)
end

-- Find available implementations early
local implementations, err = contract.find_implementations("user:service")
print("Available user service implementations:", table.concat(implementations, ", "))

-- Store contract definitions for later use
app.contracts = {
    user_service = user_contract,
    payment_service = contract.get("payment:processor"),
    -- ... other contracts
}

-- Later, during runtime execution with full context
function handle_request(request)
    -- Try to use default binding first
    local instance, err = app.contracts.user_service
        :with_actor(request.actor)
        :with_context({ request_id = request.id })
        :open() -- Use default binding
    
    if err then
        -- Fallback to specific implementation
        instance, err = app.contracts.user_service
            :with_actor(request.actor)
            :with_context({ request_id = request.id })
            :open("user:database_impl")
    end
    
    -- Check what the instance implements
    if contract.is(instance, "user:service") then
        -- ... use instance
    end
end
```

### Basic Contract Usage

```lua
local contract = require("contract")

-- Get contract definition
local user_service, err = contract.get("user:service")
if err then
    error("Failed to get contract: " .. err)
end

-- Try default binding first
local instance, err = user_service:open()
if err then
    -- Fallback to specific implementation
    instance, err = user_service:open("user:database_impl")
    if err then
        error("Failed to open binding: " .. err)
    end
end

-- Verify instance implements expected contract
if not contract.is(instance, "user:service") then
    error("Instance does not implement user:service")
end

-- Call methods synchronously (returns direct Lua values)
local user, err = instance:get_user("user123")
if err then
    print("Error getting user:", err)
else
    print("User found:", user.name)
end

-- Call methods asynchronously (returns command object)
local cmd = instance:create_user_async({
    name = "John Doe",
    email = "john@example.com"
})

-- Get async result (returns payload wrapper)
local result_payload, err = cmd:result()
if err then
    print("Error creating user:", err)
else
    local user_data = result_payload:data()
    print("User created with ID:", user_data.id)
end
```

### Security Context Chaining

```lua
local contract = require("contract")
local security = require("security")

-- Get current security context
local actor = security.actor()
local admin_scope, _ = security.named_scope("global:admin")

-- Chain security and application context
local secured_service = contract.get("user:service")
    :with_actor(actor)
    :with_scope(admin_scope)
    :with_context({
        audit_trail = true,
        request_id = "req-123"
    })

-- Try default binding first
local instance, err = secured_service:open()
if err then
    -- Open with specific binding and additional context
    instance, err = secured_service:open("user:admin_impl", {
        elevated_access = true
    })
end

-- Verify instance capabilities
if contract.is(instance, "user:service") and contract.is(instance, "admin:privileged") then
    -- All method calls inherit the security context
    local admin_data, err = instance:get_admin_data()
end
```

### Context Merging with Query Parameters

```lua
-- Base context through chaining
local service = contract.get("data:processor")
    :with_context({
        environment = "prod",
        timeout = 30,
        retries = 3
    })

-- Query parameters in binding ID (second priority)
-- Additional context in open() (highest priority) - merges/overrides
local instance, err = service:open("data:fast_impl?timeout=45&cache=true", {
    timeout = 60,        -- Overrides both chained and query param values
    priority = "high"    -- Adds new value
})
-- Final context: {environment = "prod", timeout = 60, retries = 3, cache = true, priority = "high"}
```

### Working with Multiple Contract Implementations

```lua
local contract = require("contract")

-- Get a contract that might be implemented by instances with different capabilities
local storage_contract, err = contract.get("storage:service")
local instance, err = storage_contract:open() -- Try default first

-- Check what contracts this instance actually implements
local capabilities = {}
local contracts_to_check = {"storage:service", "storage:versioned", "storage:encrypted", "audit:logging"}

for i, contract_id in ipairs(contracts_to_check) do
    if contract.is(instance, contract_id) then
        table.insert(capabilities, contract_id)
    end
end

print("Instance capabilities:", table.concat(capabilities, ", "))

-- Use features based on capabilities
if contract.is(instance, "storage:versioned") then
    local version, err = instance:get_version("document123")
end

if contract.is(instance, "audit:logging") then
    instance:log_access("user123", "read", "document123")
end
```

### Working with Payloads

```lua
-- Async method returns command
local cmd = instance:process_data_async(large_dataset)

-- Get result as payload
local result_payload, err = cmd:result()
if not err then
    -- Option 1: Get raw data
    local raw_data = result_payload:data()
    
    -- Option 2: Unmarshal to Lua value 
    local lua_value = result_payload:unmarshal()
    
    -- Option 3: Transcode to different format
    local json_payload = result_payload:transcode("application/json")
    local json_string = json_payload:data()
    
    -- Check payload format
    local format = result_payload:get_format()
    print("Result format:", format)
end
```

### Async Patterns and Cancellation

```lua
local time = require("time")

-- Start async contract method
local instance, err = contract.get("data:analyzer"):open() -- Try default binding
local command = instance:analyze_dataset_async(large_dataset)

-- Create timeout
local ticker = time.ticker(30000) -- 30 seconds

-- Wait for either completion or timeout
local result = channel.select{
    command:response():case_receive(),
    ticker:channel():case_receive()
}

if result.channel == ticker:channel() then
    -- Timeout - cancel the operation
    local success, err = command:cancel()
    ticker:stop()
    if success then
        print("Analysis timed out and cancelled")
    else
        print("Analysis timed out, cancel failed:", err)
    end
else
    -- Analysis completed
    ticker:stop()
    local cmd_result, err = command:result()
    if err then
        print("Analysis failed:", err)
    else
        local analysis_data = cmd_result:data()
        print("Analysis complete:", analysis_data)
    end
end
```

### Parallel Contract Execution

```lua
-- Open multiple instances for parallel processing
local instances = {}
local implementations = {"user:db_impl", "user:cache_impl", "user:search_impl"}

for i, impl in ipairs(implementations) do
    local instance, err = contract.get("user:service"):open(impl)
    if not err and contract.is(instance, "user:service") then
        instances[i] = instance
    end
end

-- Execute same operation on all instances in parallel
local commands = {}
for i, instance in ipairs(instances) do
    commands[i] = instance:search_users_async({query = "john"})
end

-- Collect results
local results = {}
for i, cmd in ipairs(commands) do
    local result_payload, err = cmd:result()
    if not err then
        results[i] = result_payload:data()
    else
        print("Command", i, "failed:", err)
    end
end
```

### Contract Introspection and Discovery

```lua
-- Discover available implementations
local implementations, err = contract.find_implementations("user:service")
if err then
    error("Failed to find implementations: " .. err)
end

print("Available implementations:")
for i, binding_id in ipairs(implementations) do
    print("-", binding_id)
end

-- Get contract schema
local contract_def, err = contract.get("user:service")
local methods = contract_def:methods()

print("Contract methods:")
for i, method in ipairs(methods) do
    print("- " .. method.name .. ": " .. method.description)
    
    -- Show input schemas
    if method.input_schemas then
        for j, schema in ipairs(method.input_schemas) do
            print("  Input " .. j .. ": " .. schema.format)
        end
    end
end

-- Test default binding first
local instance, err = contract_def:open()
if err then
    print("No default binding or requires context:", err)
    
    -- Test different implementations
    for i, impl_id in ipairs(implementations) do
        local instance, err = contract_def:open(impl_id)
        if not err then
            print("Implementation " .. impl_id .. " supports:")
            
            -- Check for optional contract extensions
            local extensions = {"storage:versioned", "audit:logging", "cache:enabled"}
            for j, ext in ipairs(extensions) do
                if contract.is(instance, ext) then
                    print("  - " .. ext)
                end
            end
            break -- Use first working implementation
        end
    end
else
    print("Using default binding successfully")
end
```

### Error Handling with Contract Validation

```lua
local contract = require("contract")

function safe_service_call(service_contract_id, binding_id, method_name, ...)
    -- Get contract safely
    local contract_def, err = contract.get(service_contract_id)
    if err then
        return nil, "Failed to get contract " .. service_contract_id .. ": " .. err
    end
    
    -- Try to open instance safely
    local instance, err
    if binding_id then
        instance, err = contract_def:open(binding_id)
    else
        -- Try default binding first
        instance, err = contract_def:open()
        if err then
            return nil, "Failed to open default binding: " .. err
        end
    end
    
    if err then
        return nil, "Failed to open binding " .. (binding_id or "default") .. ": " .. err
    end
    
    -- Verify contract implementation
    if not contract.is(instance, service_contract_id) then
        return nil, "Instance does not implement expected contract " .. service_contract_id
    end
    
    -- Call method safely
    local result, err = instance[method_name](instance, ...)
    if err then
        return nil, "Method call failed: " .. err
    end
    
    return result, nil
end

-- Usage with default binding
local user, err = safe_service_call("user:service", nil, "get_user", "user123")
if err then
    print("Service call failed:", err)
else
    print("Got user:", user.name)
end

-- Usage with specific binding
local user, err = safe_service_call("user:service", "user:db_impl", "get_user", "user123")
```

## Security Model

### Permission Requirements

The contract module enforces several security permissions:

- `contract.get` - Required to access contract definitions
- `contract.implementations.list` - Required to list implementations
- `contract.binding.open` - Required to open specific bindings (including default bindings)
- `contract.method.access` - Required to access specific methods
- `contract.method.call` - Required to call specific methods
- `contract.security` - Required to use custom security context (`with_actor`, `with_scope`)
- `contract.context` - Required to use custom application context (`with_context`)

### Context Inheritance

Security context flows through the entire chain:

1. **Contract Level**: Set via `with_actor()` and `with_scope()`
2. **Instance Level**: Inherited from contract wrapper
3. **Method Level**: All method calls use inherited security context

Application context merges at each level:

1. **Base Context**: From current Lua context
2. **Chain Context**: Added via `with_context()` calls
3. **Query Parameters**: From binding ID query string (second priority)
4. **Open Context**: Added via `open()` parameters (highest priority)

## Error Conditions

Common error scenarios:

- **Contract not found**: Contract definition doesn't exist or access denied
- **Implementation not found**: Binding ID doesn't exist or access denied
- **Default binding not found**: No default binding configured for the contract
- **Context requirements not met**: Default binding requires context that is not available
- **Method not found**: Method doesn't exist in any implemented contract
- **Security denied**: Insufficient permissions for operation
- **Context validation**: Invalid context values or types
- **Instantiation failed**: Binding instantiation failed (missing dependencies, etc.)
- **Method execution failed**: Runtime error during method execution
- **Command errors**: Async command completion failures
- **Type errors**: Passing wrong types to `contract.is()` (e.g., non-userdata as first argument)