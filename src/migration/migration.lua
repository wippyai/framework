--[[
Migration System
---------------

A self-contained migration system for database schema changes.
This module provides a simplified interface for database migrations
with transaction support and automatic migration tracking.

Usage:
local migration = require("migration")

-- Define a migration (in a separate migration file)
local my_migration = migration.define(function()
  migration("Add users table", function()
    database("sqlite", function()
      up(function(db)
        -- Forward migration logic
      end)

      down(function(db)
        -- Rollback logic
      end)
    end)
  end)
end)

-- Run the migration
local result = my_migration({
  database_id = "my_database",
  direction = "up" -- or "down" for rollback
})
]]

local migration = {}
local sql = require("sql")
local time = require("time")

-- Import required modules
local migration_core = require("core")
local repository = require("repository")

-- Execute a single migration with proper transaction handling
local function execute_migration(migration_item, options)
    if not migration_item or not options or not options.db or not options.db_type then
        return {
            status = "error",
            error = "Invalid migration or options"
        }
    end

    local db = options.db
    local db_type = options.db_type
    local direction = options.direction or "up"

    -- Modified migration ID determination
    local migration_id
    if options.id then
        migration_id = options.id
    else
        return {
            status = "error",
            error = "Migration ID is required",
        }
    end

    -- Find the implementation for this database type
    local impl = migration_item.database_implementations[db_type]
    if not impl then
        return {
            status = "skipped",
            description = migration_item.description,
            reason = "No implementation for database type: " .. db_type,
            name = migration_item.description -- Add migration name
        }
    end

    -- Validate implementation for requested direction
    if direction == "up" and not impl.up then
        return {
            status = "error",
            description = migration_item.description,
            error = "Missing 'up' implementation for " .. db_type,
            name = migration_item.description -- Add migration name
        }
    elseif direction == "down" and not impl.down then
        return {
            status = "error",
            description = migration_item.description,
            error = "Missing 'down' implementation for " .. db_type,
            name = migration_item.description -- Add migration name
        }
    end

    -- Check if already applied for up direction
    if direction == "up" then
        local is_applied, check_err = repository.is_applied(db, migration_id)
        if check_err then
            return {
                status = "error",
                description = migration_item.description,
                error = "Failed to check migration status: " .. check_err,
                name = migration_item.description -- Add migration name
            }
        end

        if is_applied and not options.force then
            return {
                status = "skipped",
                description = migration_item.description,
                reason = "Migration already applied",
                name = migration_item.description -- Add migration name
            }
        end
    end

    -- Start transaction for atomic migration application
    local tx, tx_err = db:begin()
    if tx_err then
        return {
            status = "error",
            description = migration_item.description,
            error = "Failed to start transaction: " .. tx_err,
            name = migration_item.description -- Add migration name
        }
    end

    -- Apply migration
    local start_time = time.now()
    local success, err

    if direction == "up" then
        success, err = cpcall(impl.up, tx)
    else
        success, err = cpcall(impl.down, tx)

        if success then
            -- Remove migration record for down migrations
            local remove_ok, remove_err = repository.remove_migration(tx, migration_id)
            if not remove_ok then
                tx:rollback()
                return {
                    status = "error",
                    description = migration_item.description,
                    error = "Failed to remove migration record: " .. remove_err,
                    name = migration_item.description -- Add migration name
                }
            end
        end
    end

    if not success then
        -- Rollback transaction
        tx:rollback()

        return {
            status = "error",
            description = migration_item.description,
            error = err,
            name = migration_item.description -- Add migration name
        }
    end

    -- For up migrations, record in tracking table
    if direction == "up" then
        local record_ok, record_err = repository.record_migration(
            tx,
            migration_id,
            migration_item.description
        )

        if not record_ok then
            tx:rollback()

            return {
                status = "error",
                description = migration_item.description,
                error = "Failed to record migration: " .. record_err,
                name = migration_item.description -- Add migration name
            }
        end
    end

    -- Apply after hooks if available (for up migrations)
    if direction == "up" and impl.after then
        local after_success, after_err = cpcall(impl.after, tx)
        if not after_success then
            tx:rollback()

            return {
                status = "error",
                description = migration_item.description,
                error = "After hook failed: " .. after_err,
                name = migration_item.description -- Add migration name
            }
        end
    end

    -- Commit transaction
    local commit_success, commit_err = tx:commit()
    if not commit_success then
        return {
            status = "error",
            description = migration_item.description,
            error = "Failed to commit transaction: " .. commit_err,
            name = migration_item.description -- Add migration name
        }
    end

    local end_time = time.now()
    local duration = end_time:sub(start_time)

    -- Set status based on direction
    local status
    if direction == "up" then
        status = "applied"
    else
        status = "reverted"
    end

    return {
        status = status,
        description = migration_item.description,
        duration = duration:milliseconds() / 1000, -- Convert to seconds
        name = migration_item.description          -- Add migration name
    }
end

-- Run a migration function
function migration.run(fn, options)
    -- Default options
    options = options or {}

    if not options.database_id and not options.db then
        return {
            status = "error",
            error = "Database ID or connection is required"
        }
    end

    -- Default direction is "up"
    options.direction = options.direction or "up"
    if options.direction ~= "up" and options.direction ~= "down" then
        return {
            status = "error",
            error = "Invalid direction: must be 'up' or 'down'"
        }
    end

    -- Get database connection
    local db, db_err
    local need_release = false

    if options.db then
        db = options.db
    else
        db, db_err = sql.get(options.database_id)
        if db_err then
            return {
                status = "error",
                error = "Failed to connect to database: " .. db_err
            }
        end
        need_release = true
    end

    -- Initialize tracking table
    local init_ok, init_err = repository.init_tracking_table(db)
    if not init_ok then
        if need_release then db:release() end

        return {
            status = "error",
            error = "Failed to initialize migration tracking table: " .. init_err
        }
    end

    -- Get database type
    local db_type, type_err = db:type()
    if type_err then
        if need_release then db:release() end

        return {
            status = "error",
            error = "Failed to determine database type: " .. type_err
        }
    end

    -- Define migrations using the core DSL
    local success, implementations_or_err = cpcall(migration_core.define, fn)
    if not success then
        if need_release then db:release() end

        return {
            status = "error",
            error = "Failed to define migration: " .. implementations_or_err
        }
    end

    local implementations = implementations_or_err

    -- Results container
    local results = {
        migrations = {},
        total = #implementations,
        applied = 0,
        skipped = 0,
        skipped_reasons = {},
        failed = 0,
        db_type = db_type
    }

    local start_time = time.now()

    -- Apply each migration
    for _, m in ipairs(implementations) do
        -- Only process migrations with an implementation for this DB type
        if m.database_implementations[db_type] then
            local result = execute_migration(m, {
                db = db,
                db_type = db_type,
                direction = options.direction,
                force = options.force,
                id = options.id,
            })

            table.insert(results.migrations, result)

            if result.status == "applied" or result.status == "reverted" then
                results.applied = results.applied + 1
            elseif result.status == "skipped" then
                results.skipped = results.skipped + 1
                local skipped_info = {
                    name = result.name,
                    reason = result.reason
                }
                table.insert(results.skipped_reasons, skipped_info)
            elseif result.status == "error" then
                results.failed = results.failed + 1

                -- Stop on first error unless force option is set
                if not options.force then
                    results.status = "error"
                    results.error = tostring(result.error)
                    break
                end
            end
        else
            -- No implementation for this DB type
            results.skipped = results.skipped + 1
            local skipped_info = {
                name = m.description,
                reason = "No implementation for database type: " .. db_type
            }
            table.insert(results.skipped_reasons, skipped_info)
        end
    end

    local end_time = time.now()
    results.duration = end_time:sub(start_time):milliseconds() / 1000 -- Convert to seconds

    -- Determine final status
    if not results.status then
        results.status = results.failed > 0 and "failed" or "complete"
    end

    -- Release DB connection if we opened it
    if need_release then
        db:release()
    end

    return results
end

-- Creating a migration definition function
function migration.define(fn)
    if not fn or type(fn) ~= "function" then
        error("Migration definition must be a function")
    end

    return function(options)
        return migration.run(fn, options)
    end
end

return migration
