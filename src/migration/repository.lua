local sql = require("sql")

type MigrationRecord = {
    id: string,
    applied_at: any,
    description: string?,
    content_hash: string?,
}

local migrations = {}

--[[
Migration Ledger Interface
--------------------------

This module manages the database ledger for tracking applied migrations.
It handles table creation, record management, and status queries
to maintain a history of all successful migrations.
]]

-- Schema definitions for tracking table by database type
migrations.schemas = {
    [sql.type.POSTGRES] = [[
        CREATE TABLE IF NOT EXISTS _migrations (
            id VARCHAR(512) PRIMARY KEY,
            applied_at TIMESTAMP NOT NULL DEFAULT NOW(),
            description TEXT,
            content_hash VARCHAR(64)
        )
    ]],

    [sql.type.SQLITE] = [[
        CREATE TABLE IF NOT EXISTS _migrations (
            id VARCHAR(512) PRIMARY KEY,
            applied_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
            description TEXT,
            content_hash VARCHAR(64)
        )
    ]],

    [sql.type.MYSQL] = [[
        CREATE TABLE IF NOT EXISTS _migrations (
            id VARCHAR(512) PRIMARY KEY,
            applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            description TEXT,
            content_hash VARCHAR(64)
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
function migrations.table_exists(db: any): (any, string?)
    local db_type, err = db:type()
    if err then
        return nil, "Failed to determine database type: " .. tostring(err)
    end

    local check_query = (migrations.table_exists_queries :: any)[db_type]
    if not check_query then
        return nil, "Unsupported database type: " .. db_type
    end

    local query_result, query_err = db:query(check_query)
    if query_err then
        return nil, "Failed to check if table exists: " .. tostring(query_err)
    end

    local result: any = query_result
    -- Handle different result formats from different database types
    if db_type == sql.type.POSTGRES then
        return result[1] and result[1].exists, nil
    else
        return result[1] and result[1].count > 0, nil
    end
end

-- Initialize migration tracking table
function migrations.init_tracking_table(db: any): (any, string?)
    -- First check if table already exists
    local exists, err = migrations.table_exists(db)
    if err then
        return nil, err
    end

    local db_type, err = db:type()
    if err then
        return nil, "Failed to determine database type: " .. tostring(err)
    end
    local schema = (migrations.schemas :: any)[db_type]
    if not schema then
        return nil, "Unsupported database type: " .. db_type
    end

    if not exists then
        local created, create_err = db:execute(schema)
        if not created then return nil, create_err end
    end

    -- Existing installations have a ledger without this column. Add it in
    -- place; historical rows remain NULL because their executed bytes cannot
    -- be reconstructed from the current registry.
    if db_type == sql.type.POSTGRES then
        return db:execute("ALTER TABLE _migrations ADD COLUMN IF NOT EXISTS content_hash VARCHAR(64)")
    end

    local columns, columns_err
    if db_type == sql.type.SQLITE then
        columns, columns_err = db:query("PRAGMA table_info(_migrations)")
    else
        columns, columns_err = db:query([[SELECT column_name AS name FROM information_schema.columns
            WHERE table_schema = DATABASE() AND table_name = '_migrations']])
    end
    if columns_err then return nil, columns_err end
    for _, column in ipairs(columns or {}) do
        if column.name == "content_hash" then return true, nil end
    end
    return db:execute("ALTER TABLE _migrations ADD COLUMN content_hash VARCHAR(64)")
end

-- Record a migration execution
function migrations.record_migration(db: any, id: string, description: string?, content_hash: string?): (any, string?)
    if not id or id == "" then
        return nil, "Migration ID is required"
    end

    if #id > 512 then
        return nil, "Migration ID exceeds maximum length (512 characters)"
    end

    local query = [[
        INSERT INTO _migrations (id, description, content_hash)
        VALUES ($1, $2, $3)
    ]]
    -- Create an array-like table for parameters
    local params = { id, description or "", content_hash or sql.NULL }

    return db:execute(query, params)
end

-- Remove a migration record (for rollbacks)
function migrations.remove_migration(db: any, id: string): (any, string?)
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
function migrations.get_migrations(db: any, filter: any?): (any, string?)
    filter = filter or {}

    local query = "SELECT id, applied_at, description, content_hash FROM _migrations"
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

function migrations.get_migration(db: any, id: string): (MigrationRecord?, string?)
    if not id or id == "" then return nil, "Migration ID is required" end
    local rows, err = db:query(
        "SELECT id, applied_at, description, content_hash FROM _migrations WHERE id = $1",
        { id })
    if err then return nil, err end
    if rows and rows[1] then return rows[1] :: MigrationRecord, nil end
    return nil, nil
end

-- Check if a specific migration has been applied
function migrations.is_applied(db: any, id: string): (any, string?)
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
        return nil, "Failed to check migration status: " .. tostring(err)
    end

    return result[1] and result[1].count > 0, nil
end

return migrations
