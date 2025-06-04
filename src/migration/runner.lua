--[[
Migration Runner
---------------

This module provides a high-level API for discovering and executing migrations
from the registry in an isolated manner. It handles finding migrations for a specific
database, running them forward (up) or rolling them back (down).

Usage:
local runner = require("runner")

-- Initialize runner for a specific database
local db_runner = runner.setup("my_database_id")

-- Run all pending migrations
local results = db_runner:run({
    tags = {"schema", "data"}  -- Optional: Filter by tags
})

-- Run just the next pending migration
local results = db_runner:run_next()

-- Roll back the last applied migration
local rollback_result = db_runner:rollback()
]]

local sql = require("sql")
local time = require("time")
local funcs = require("funcs")
local repository = require("repository")
local registry_finder = require("registry")

local runner = {}

-- Helper function to create error response
local function create_error(message)
    return {
        status = "error",
        error = tostring(message)
    }
end

-- Runner object for a specific database
local Runner = {}
Runner.__index = Runner

-- Set up a runner for a specific database
function runner.setup(database_id)
    if not database_id then
        error("Database ID is required for migration runner setup")
    end

    local self = setmetatable({}, Runner)
    self.database_id = database_id

    return self
end

-- Find migrations for this database
function Runner:find_migrations(options)
    options = options or {}

    -- Get database connection to determine type
    local db, err = sql.get(self.database_id)
    if err then
        return nil, "Failed to connect to database: " .. tostring(err)
    end

    -- Get database type
    local db_type, type_err = db:type()
    if type_err then
        db:release()
        return nil, "Failed to determine database type: " .. tostring(type_err)
    end

    -- Initialize tracking table
    local init_ok, init_err = repository.init_tracking_table(db)
    if not init_ok then
        db:release()
        return nil, "Failed to initialize migration tracking table: " .. tostring(init_err)
    end

    -- Get applied migrations
    local applied_migrations, applied_err = repository.get_migrations(db)
    if applied_err then
        db:release()
        return nil, "Failed to get applied migrations: " .. tostring(applied_err)
    end

    -- Build map of applied migrations for quick lookup
    local applied_map = {}
    for _, m in ipairs(applied_migrations or {}) do
        applied_map[m.id] = m
    end

    -- Find migrations in registry
    local find_options = {
        target_db = self.database_id,
        tags = options.tags
    }

    local migrations, find_err = registry_finder.find(find_options)
    if find_err then
        db:release()
        return nil, "Failed to find migrations: " .. tostring(find_err)
    end

    db:release()

    -- Enrich migrations with applied status - UPDATED
    for i, migration in ipairs(migrations) do
        local migration_id = migration.id

        -- Check if the migration has been applied by its registry ID
        migrations[i].applied = applied_map[migration_id] ~= nil
        migrations[i].applied_at = applied_map[migration_id] and applied_map[migration_id].applied_at or nil
    end

    return migrations
end

-- Get the next pending migration
function Runner:get_next_migration(options)
    local migrations, err = self:find_migrations(options)
    if err then
        return nil, err
    end

    if not migrations or #migrations == 0 then
        return nil, "No migrations found"
    end

    -- Migrations are already sorted by timestamp
    -- Find the first one that hasn't been applied yet
    for _, migration in ipairs(migrations) do
        if not migration.applied then
            return migration
        end
    end

    return nil, "All migrations have been applied"
end

-- Execute a single migration with proper settings
local function execute_migration(migration_id, options)
    -- Create function executor
    local executor = funcs.new()

    -- Execute the migration in isolation
    local result, exec_err = executor:call(migration_id, options)
    if exec_err then
        return {
            status = "error",
            error = "Failed to execute migration: " .. tostring(exec_err)
        }
    end

    return result
end

-- Run migrations in isolated manner
function Runner:run(options)
    options = options or {}

    -- Find available migrations
    local migrations, find_err = self:find_migrations(options)
    if find_err then
        return create_error(find_err)
    end

    if not migrations or #migrations == 0 then
        return {
            status = "complete",
            message = "No migrations found",
            migrations_found = 0,
            migrations_applied = 0,
            migrations_skipped = 0,
            migrations_failed = 0
        }
    end

    -- Track results
    local results = {
        status = "running",
        migrations_found = #migrations,
        migrations_applied = 0,
        migrations_skipped = 0,
        migrations_failed = 0,
        migrations = {},
        skipped_details = {} -- Add this field to track skipped migrations details
    }

    -- Start timing
    local start_time = time.now()

    -- Execute each migration that's not already applied
    for _, migration in ipairs(migrations) do
        -- Skip if already applied
        if migration.applied then
            results.migrations_skipped = results.migrations_skipped + 1
            local skip_details = {
                id = migration.id,
                name = migration.meta and migration.meta.description or "",
                reason = "Already applied"
            }
            table.insert(results.skipped_details, skip_details)
            table.insert(results.migrations, {
                id = migration.id,
                status = "skipped",
                reason = "Already applied",
                applied_at = migration.applied_at,
                description = migration.meta and migration.meta.description or ""
            })
            goto continue
        end

        -- Set up migration options
        local migration_options = {
            database_id = self.database_id,
            direction = "up",
            id = migration.id
        }

        -- Execute the migration
        local result = execute_migration(migration.id, migration_options)

        if result and result.status == "error" then
            results.migrations_failed = results.migrations_failed + 1
            table.insert(results.migrations, {
                id = migration.id,
                status = "error",
                error = result.error,
                description = migration.meta and migration.meta.description or ""
            })

            -- Stop on first error
            results.status = "error"
            results.error = result.error
            break
        elseif result and result.status == "applied" then
            results.migrations_applied = results.migrations_applied + 1
            table.insert(results.migrations, {
                id = migration.id,
                status = "applied",
                description = migration.meta and migration.meta.description or "",
                duration = result.duration
            })
        else
            results.migrations_skipped = results.migrations_skipped + 1

            -- Extract reason properly from nested result
            local reason
            if result then
                -- Check if reason is directly available
                if result.reason then
                    reason = result.reason
                    -- Check if it's inside the skipped_reasons structure
                elseif result.name and result.reason then
                    reason = result.reason
                elseif result.skipped_reasons and #result.skipped_reasons > 0 then
                    reason = result.skipped_reasons[1].reason
                else
                    reason = "Unknown"
                end
            else
                reason = "Unknown"
            end

            local skip_details = {
                id = migration.id,
                name = migration.meta and migration.meta.description or "",
                reason = reason
            }
            table.insert(results.skipped_details, skip_details)
            table.insert(results.migrations, {
                id = migration.id,
                status = "skipped",
                reason = reason,
                description = migration.meta and migration.meta.description or ""
            })
        end

        ::continue::
    end

    local end_time = time.now()
    results.duration = end_time:sub(start_time):milliseconds() / 1000 -- Convert to seconds

    -- Determine final status
    if results.status ~= "error" then
        results.status = "complete"
    end

    -- Include skipped_reasons if there are any skipped migrations
    if results.migrations_skipped > 0 and result and result.skipped_reasons then
        results.skipped_reasons = result.skipped_reasons
    end

    return results
end

-- Run just the next pending migration - UPDATED
function Runner:run_next(options)
    options = options or {}

    -- Find the next migration
    local next_migration, err = self:get_next_migration(options)
    if err then
        return {
            status = "complete",
            message = err,
            migrations_found = 0,
            migrations_applied = 0,
            migrations_skipped = 0,
            migrations_failed = 0
        }
    end

    -- Track results
    local results = {
        status = "running",
        migrations_found = 1,
        migrations_applied = 0,
        migrations_skipped = 0,
        migrations_failed = 0,
        migrations = {},
        skipped_details = {} -- Add this field to track skipped migrations details
    }

    -- Start timing
    local start_time = time.now()

    -- Set up migration options
    local migration_options = {
        database_id = self.database_id,
        direction = "up"
    }

    -- Execute the migration
    local result = execute_migration(next_migration.id, migration_options)

    if result and result.status == "error" then
        results.migrations_failed = 1
        table.insert(results.migrations, {
            id = next_migration.id,
            status = "error",
            error = result.error,
            description = next_migration.meta and next_migration.meta.description or ""
        })
        results.status = "error"
        results.error = result.error
    elseif result and result.status == "applied" then
        results.migrations_applied = 1
        table.insert(results.migrations, {
            id = next_migration.id,
            status = "applied",
            description = next_migration.meta and next_migration.meta.description or "",
            duration = result.duration
        })
    else
        results.migrations_skipped = 1

        -- Extract reason properly from nested result - UPDATED
        local reason
        if result then
            -- Check if reason is directly available
            if result.reason then
                reason = result.reason
                -- Check if it's inside the skipped_reasons structure
            elseif result.name and result.reason then
                reason = result.reason
            elseif result.skipped_reasons and #result.skipped_reasons > 0 then
                reason = result.skipped_reasons[1].reason
            else
                reason = "Unknown"
            end
        else
            reason = "Unknown"
        end

        local skip_details = {
            id = next_migration.id,
            name = next_migration.meta and next_migration.meta.description or "",
            reason = reason
        }
        table.insert(results.skipped_details, skip_details)
        table.insert(results.migrations, {
            id = next_migration.id,
            status = "skipped",
            reason = reason,
            description = next_migration.meta and next_migration.meta.description or ""
        })
    end

    -- Include skipped_reasons if available
    if result and result.skipped_reasons then
        results.skipped_reasons = result.skipped_reasons
    end

    local end_time = time.now()
    results.duration = end_time:sub(start_time):milliseconds() / 1000 -- Convert to seconds

    -- Determine final status
    if results.status ~= "error" then
        results.status = "complete"
    end

    return results
end

-- Roll back migrations
function Runner:rollback(options)
    options = options or {}

    -- Get database connection
    local db, err = sql.get(self.database_id)
    if err then
        return create_error("Failed to connect to database: " .. tostring(err))
    end

    -- Initialize tracking table
    local init_ok, init_err = repository.init_tracking_table(db)
    if not init_ok then
        db:release()
        return create_error("Failed to initialize migration tracking table: " .. tostring(init_err))
    end

    -- Get applied migrations sorted by most recent first
    local applied_migrations, query_err = repository.get_migrations(db)
    if query_err then
        db:release()
        return create_error("Failed to get applied migrations: " .. tostring(query_err))
    end

    db:release()

    if not applied_migrations or #applied_migrations == 0 then
        return {
            status = "complete",
            message = "No migrations to roll back",
            migrations_found = 0,
            migrations_reverted = 0,
            migrations_skipped = 0,
            migrations_failed = 0
        }
    end

    -- Enrich migrations with metadata from registry to get creation timestamps
    for i, migration in ipairs(applied_migrations) do
        local registry_entry = registry_finder.get(migration.id)
        if registry_entry and registry_entry.meta and registry_entry.meta.timestamp then
            applied_migrations[i].meta_timestamp = registry_entry.meta.timestamp
        else
            -- Default to empty string if not found
            applied_migrations[i].meta_timestamp = ""
        end
    end

    -- Sort migrations: first by applied_at (descending), then by meta_timestamp (descending)
    table.sort(applied_migrations, function(a, b)
        -- First compare applied_at timestamps
        if a.applied_at ~= b.applied_at then
            return a.applied_at > b.applied_at
        end

        -- If applied_at is the same, use metadata timestamp as secondary sort
        -- Parse the RFC3339 timestamps and compare them properly
        if a.meta_timestamp and b.meta_timestamp then
            -- Try to parse both timestamps
            local time_a, err_a = time.parse(time.RFC3339, a.meta_timestamp)
            local time_b, err_b = time.parse(time.RFC3339, b.meta_timestamp)

            -- If both parsed successfully, compare them
            if time_a and time_b then
                return time_a:after(time_b)
            end

            -- If one failed to parse, fall back to string comparison
            if time_a and not time_b then
                return true  -- a is valid, b is not, so a comes first
            elseif not time_a and time_b then
                return false -- a is not valid, b is, so b comes first
            end
        end

        -- Fall back to string comparison if parsing fails or timestamps don't exist
        return (a.meta_timestamp or "") > (b.meta_timestamp or "")
    end)

    -- Determine how many migrations to roll back
    local count = options.count or 1 -- Default to rolling back just the last migration
    if count > #applied_migrations then
        count = #applied_migrations
    end

    local to_rollback = {}
    for i = 1, count do
        table.insert(to_rollback, applied_migrations[i])
    end

    -- Track results
    local results = {
        status = "running",
        migrations_found = #to_rollback,
        migrations_reverted = 0,
        migrations_skipped = 0,
        migrations_failed = 0,
        migrations = {},
        skipped_details = {} -- Add this field to track skipped migrations details
    }

    -- Start timing
    local start_time = time.now()

    -- Execute rollbacks
    for _, migration in ipairs(to_rollback) do
        -- Set up migration options
        local migration_options = {
            database_id = self.database_id,
            direction = "down",
            id = migration.id
        }

        -- Execute the migration
        local result = execute_migration(migration.id, migration_options)

        if result and result.status == "error" then
            results.migrations_failed = results.migrations_failed + 1
            table.insert(results.migrations, {
                id = migration.id,
                status = "error",
                error = result.error,
                description = migration.description or ""
            })

            -- Stop on first error
            results.status = "error"
            results.error = result.error
            break
        elseif result and result.status == "reverted" then
            results.migrations_reverted = results.migrations_reverted + 1
            table.insert(results.migrations, {
                id = migration.id,
                status = "reverted",
                description = migration.description or "",
                duration = result.duration
            })
        else
            results.migrations_skipped = results.migrations_skipped + 1

            -- Extract reason properly from nested result - UPDATED
            local reason
            if result then
                -- Check if reason is directly available
                if result.reason then
                    reason = result.reason
                    -- Check if it's inside the skipped_reasons structure
                elseif result.name and result.reason then
                    reason = result.reason
                elseif result.skipped_reasons and #result.skipped_reasons > 0 then
                    reason = result.skipped_reasons[1].reason
                else
                    reason = "Unknown"
                end
            else
                reason = "Unknown"
            end

            local skip_details = {
                id = migration.id,
                name = migration.description or "",
                reason = reason
            }
            table.insert(results.skipped_details, skip_details)
            table.insert(results.migrations, {
                id = migration.id,
                status = "skipped",
                reason = reason,
                description = migration.description or ""
            })
        end
    end

    -- Include skipped_reasons if available
    if result and result.skipped_reasons then
        results.skipped_reasons = result.skipped_reasons
    end

    local end_time = time.now()
    results.duration = end_time:sub(start_time):milliseconds() / 1000 -- Convert to seconds

    -- Determine final status
    if results.status ~= "error" then
        results.status = "complete"
    end

    return results
end

-- Get migration status for this database
function Runner:status(options)
    options = options or {}

    -- Find available migrations
    local migrations, find_err = self:find_migrations(options)
    if find_err then
        return create_error(find_err)
    end

    -- Count metrics
    local status_report = {
        database_id = self.database_id,
        db_type = nil, -- Will be filled in below
        total_migrations = #migrations,
        applied_migrations = 0,
        pending_migrations = 0,
        migrations = {}
    }

    -- Get database type
    local db, err = sql.get(self.database_id)
    if err then
        return create_error("Failed to connect to database: " .. tostring(err))
    end

    local db_type, type_err = db:type()
    if type_err then
        db:release()
        return create_error("Failed to determine database type: " .. tostring(type_err))
    end

    status_report.db_type = db_type
    db:release()

    -- Process migrations
    for _, migration in ipairs(migrations) do
        local migration_status = {
            id = migration.id,
            description = migration.meta and migration.meta.description or "",
            timestamp = migration.meta and migration.meta.timestamp or "",
            tags = migration.meta and migration.meta.tags or {},
            status = migration.applied and "applied" or "pending",
            applied_at = migration.applied_at
        }

        if migration.applied then
            status_report.applied_migrations = status_report.applied_migrations + 1
        else
            status_report.pending_migrations = status_report.pending_migrations + 1
        end

        table.insert(status_report.migrations, migration_status)
    end

    return status_report
end

return runner
