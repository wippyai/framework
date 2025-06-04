--[[
Migration Core
-------------

This module provides the core DSL (Domain Specific Language) for defining database migrations.
It manages the context, lifecycle, and execution flow of migration definitions without
any database-specific logic.

The DSL includes the following functions:
- migration(description, fn) - Define a migration with a description
- database(type, fn) - Define database-specific implementation
- up(fn) - Define the forward migration logic
- after(fn) - Define post-migration steps
- down(fn) - Define rollback logic
]]

local migration_core = {}

-- Create a new context for migration definitions
function migration_core.create_context()
    return {
        current_migration = nil,
        current_database = nil,
        implementations = {}
    }
end

-- Define a specific migration
function migration_core.create_migration_fn(context)
    return function(description, fn)
        if not description or type(description) ~= "string" then
            error("Migration description must be a string")
        end
        
        if not fn or type(fn) ~= "function" then
            error("Migration definition must be a function")
        end
        
        -- Save current migration context to restore later
        local old_migration = context.current_migration
        
        -- Create new migration context
        context.current_migration = {
            description = description,
            database_implementations = {}
        }

        -- Run the migration definition function to collect implementations
        local success, err = cpcall(fn)
        if not success then
            context.current_migration = old_migration
            error("Error in migration definition: " .. tostring(err))
        end

        -- Store migration in implementations list
        table.insert(context.implementations, context.current_migration)
        
        -- Restore previous migration context
        context.current_migration = old_migration

        return context.implementations[#context.implementations]
    end
end

-- Define database-specific implementation
function migration_core.create_database_fn(context)
    return function(db_type, fn)
        if not context.current_migration then
            error("database() must be called within a migration block")
        end
        
        if not db_type or type(db_type) ~= "string" then
            error("Database type must be a string")
        end
        
        if not fn or type(fn) ~= "function" then
            error("Database implementation must be a function")
        end

        -- Save current database context to restore later
        local old_database = context.current_database
        
        -- Create new database context
        context.current_database = {
            type = db_type,
            up = nil,
            after = nil,
            down = nil,
        }

        -- Execute database implementation definition
        local success, err = cpcall(fn)
        if not success then
            context.current_database = old_database
            error("Error in database implementation: " .. tostring(err))
        end

        -- Store implementation in current migration
        context.current_migration.database_implementations[db_type] = context.current_database
        
        -- Restore previous database context
        context.current_database = old_database
    end
end

-- Define primary migration function
function migration_core.create_up_fn(context)
    return function(fn)
        if not context.current_database then
            error("up() must be called within a database block")
        end
        
        if not fn or type(fn) ~= "function" then
            error("Up migration must be a function")
        end

        context.current_database.up = fn
    end
end

-- Define post-migration steps
function migration_core.create_after_fn(context)
    return function(fn)
        if not context.current_database then
            error("after() must be called within a database block")
        end
        
        if not fn or type(fn) ~= "function" then
            error("After hook must be a function")
        end

        context.current_database.after = fn
    end
end

-- Define rollback function
function migration_core.create_down_fn(context)
    return function(fn)
        if not context.current_database then
            error("down() must be called within a database block")
        end
        
        if not fn or type(fn) ~= "function" then
            error("Down migration must be a function")
        end

        context.current_database.down = fn
    end
end

-- Setup global DSL functions with a context
function migration_core.setup_globals(context)
    _G.migration = migration_core.create_migration_fn(context)
    _G.database = migration_core.create_database_fn(context)
    _G.up = migration_core.create_up_fn(context)
    _G.after = migration_core.create_after_fn(context)
    _G.down = migration_core.create_down_fn(context)
end

-- Cleanup global DSL functions
function migration_core.cleanup_globals()
    _G.migration = nil
    _G.database = nil
    _G.up = nil
    _G.after = nil
    _G.down = nil
end

-- Define migration with a function
function migration_core.define(fn)
    if not fn or type(fn) ~= "function" then
        error("Migration definition must be a function")
    end
    
    -- Create a fresh context for this definition
    local context = migration_core.create_context()

    -- Setup global functions with our context
    migration_core.setup_globals(context)

    -- Run definition function to collect migrations
    local success, err = cpcall(fn)
    
    -- Always clean up globals, even if there was an error
    migration_core.cleanup_globals()
    
    -- Handle errors in the definition function
    if not success then
        error("Error in migration definition: " .. tostring(err))
    end

    -- Return collected migrations
    return context.implementations
end

-- Validate that a migration implementation is complete
function migration_core.validate_implementation(implementation, db_type)
    local impl = implementation.database_implementations[db_type]
    if not impl then
        return false, "No implementation for database type: " .. db_type
    end
    
    if not impl.up or type(impl.up) ~= "function" then
        return false, "Missing 'up' function for " .. db_type
    end
    
    if not impl.down or type(impl.down) ~= "function" then
        return false, "Missing 'down' function for " .. db_type
    end
    
    return true
end

return migration_core