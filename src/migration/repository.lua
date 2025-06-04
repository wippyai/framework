local migrations = {}
local sql = require("sql")
local json = require("json")

--[[
Migration Ledger Interface
--------------------------

This module manages the database ledger for tracking applied migrations.
It handles table creation, record management, and status queries
to maintain a history of all successful migrations.

Expected data structures:
- Migration Record: {
    id: string           -- Unique identifier for the migration (up to 512 chars)
    applied_at: timestamp -- When the migration was applied
    description: string   -- Human-readable description
}
]]

-- Schema definitions for tracking table by database type
migrations.schemas = {
    [sql.type.POSTGRES] = [[
        CREATE TABLE IF NOT EXISTS _migrations (
            id VARCHAR(512) PRIMARY KEY,
            applied_at TIMESTAMP NOT NULL DEFAULT NOW(),
            description TEXT
        )
    ]],

    [sql.type.SQLITE] = [[
        CREATE TABLE IF NOT EXISTS _migrations (
            id VARCHAR(512) PRIMARY KEY,
            applied_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
            description TEXT
        )
    ]],

    [sql.type.MYSQL] = [[
        CREATE TABLE IF NOT EXISTS _migrations (
            id VARCHAR(512) PRIMARY KEY,
            applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            description TEXT
        )
    ]]
}

-- Queries to check if migration table exists
migrations.table_exists_queries = {
    [sql.type.POSTGRES] = [[
        SELECT EXISTS (
            SELECT FROM pg_tables
            WHERE schemaname = 'public'
            AND tablename = '_migrations'
        )
    ]],

    [sql.type.SQLITE] = [[
        SELECT COUNT(*) AS count
        FROM sqlite_master
        WHERE type='table'
        AND name='_migrations'
    ]],

    [sql.type.MYSQL] = [[
        SELECT COUNT(*) AS count
        FROM information_schema.tables
        WHERE table_schema = DATABASE()
        AND table_name = '_migrations'
    ]]
}

-- Check if migration tracking table exists
function migrations.table_exists(db)
    local db_type, err = db:type()
    if err then
        return nil, "Failed to determine database type: " .. err
    end

    local check_query = migrations.table_exists_queries[db_type]
    if not check_query then
        return nil, "Unsupported database type: " .. db_type
    end

    local result, err = db:query(check_query)
    if err then
        return nil, "Failed to check if table exists: " .. err
    end

    -- Handle different result formats from different database types
    if db_type == sql.type.POSTGRES then
        return result[1] and result[1].exists, nil
    else
        return result[1] and result[1].count > 0, nil
    end
end

-- Initialize migration tracking table
function migrations.init_tracking_table(db)
    -- First check if table already exists
    local exists, err = migrations.table_exists(db)
    if err then
        return nil, err
    end

    -- Table already exists, no need to create it
    if exists then
        return true, nil
    end

    local db_type, err = db:type()
    if err then
        return nil, "Failed to determine database type: " .. err
    end
    local schema = migrations.schemas[db_type]
    if not schema then
        return nil, "Unsupported database type: " .. db_type
    end

    return db:execute(schema)
end

-- Record a migration execution
function migrations.record_migration(db, id, description)
    if not id or id == "" then
        return nil, "Migration ID is required"
    end

    if #id > 512 then
        return nil, "Migration ID exceeds maximum length (512 characters)"
    end

    local query = [[
        INSERT INTO _migrations (id, description)
        VALUES ($1, $2)
    ]]
    -- Create an array-like table for parameters
    local params = { id, description or "" }

    return db:execute(query, params)
end

-- Remove a migration record (for rollbacks)
function migrations.remove_migration(db, id)
    if not id or id == "" then
        return nil, "Migration ID is required"
    end

    local query = [[
        DELETE FROM _migrations
        WHERE id = $1
    ]]

    -- Create an array-like table for parameters
    return db:execute(query, { id })
end

-- Get migrations by filter
function migrations.get_migrations(db, filter)
    filter = filter or {}

    local query = "SELECT id, applied_at, description FROM _migrations"
    local params = {}
    local where_clauses = {}

    if filter.id then
        table.insert(where_clauses, "id = $1")
        table.insert(params, filter.id)
    end

    if #where_clauses > 0 then
        query = query .. " WHERE " .. table.concat(where_clauses, " AND ")
    end

    query = query .. " ORDER BY applied_at"

    -- Make sure params is an array-like table, not a key-value map
    if #params == 0 then
        params = nil
    end

    return db:query(query, params)
end

-- Check if a specific migration has been applied
function migrations.is_applied(db, id)
    if not id or id == "" then
        return nil, "Migration ID is required"
    end

    local query = [[
        SELECT COUNT(*) AS count
        FROM _migrations
        WHERE id = $1
    ]]
    -- Create an array-like table for parameters
    local params = { id }
    local result, err = db:query(query, params)
    if err then
        return nil, "Failed to check migration status: " .. err
    end

    return result[1] and result[1].count > 0, nil
end

return migrations
