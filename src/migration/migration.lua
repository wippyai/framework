local migration = {}
local sql = require("sql")
local time = require("time")

local migration_core = require("core")
local repository = require("repository")

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

    local migration_id
    if options.id then
        migration_id = options.id
    else
        return {
            status = "error",
            error = "Migration ID is required",
        }
    end

    local impl = migration_item.database_implementations[db_type]
    if not impl then
        return {
            status = "skipped",
            description = migration_item.description,
            reason = "No implementation for database type: " .. tostring(db_type),
            name = migration_item.description
        }
    end

    if direction == "up" and not impl.up then
        return {
            status = "error",
            description = migration_item.description,
            error = "Missing 'up' implementation for " .. tostring(db_type),
            name = migration_item.description
        }
    elseif direction == "down" and not impl.down then
        return {
            status = "error",
            description = migration_item.description,
            error = "Missing 'down' implementation for " .. tostring(db_type),
            name = migration_item.description
        }
    end

    if direction == "up" then
        local is_applied, check_err = repository.is_applied(db, migration_id)
        if check_err then
            return {
                status = "error",
                description = migration_item.description,
                error = "Failed to check migration status: " .. tostring(check_err),
                name = migration_item.description
            }
        end

        if is_applied and not options.force then
            return {
                status = "skipped",
                description = migration_item.description,
                reason = "Migration already applied",
                name = migration_item.description
            }
        end
    end

    local tx, tx_err = db:begin()
    if tx_err then
        return {
            status = "error",
            description = migration_item.description,
            error = "Failed to start transaction: " .. tostring(tx_err),
            name = migration_item.description
        }
    end

    local start_time = time.now()
    local success, err

    if direction == "up" then
        success, err = cpcall(impl.up, tx)
    else
        success, err = cpcall(impl.down, tx)

        if success then
            local remove_ok, remove_err = repository.remove_migration(tx, migration_id)
            if not remove_ok then
                tx:rollback()
                return {
                    status = "error",
                    description = migration_item.description,
                    error = "Failed to remove migration record: " .. tostring(remove_err),
                    name = migration_item.description
                }
            end
        end
    end

    if not success then
        tx:rollback()

        return {
            status = "error",
            description = migration_item.description,
            error = tostring(err),
            name = migration_item.description
        }
    end

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
                error = "Failed to record migration: " .. tostring(record_err),
                name = migration_item.description
            }
        end
    end

    if direction == "up" and impl.after then
        local after_success, after_err = cpcall(impl.after, tx)
        if not after_success then
            tx:rollback()

            return {
                status = "error",
                description = migration_item.description,
                error = "After hook failed: " .. tostring(after_err),
                name = migration_item.description
            }
        end
    end

    local commit_success, commit_err = tx:commit()
    if not commit_success then
        return {
            status = "error",
            description = migration_item.description,
            error = "Failed to commit transaction: " .. tostring(commit_err),
            name = migration_item.description
        }
    end

    local end_time = time.now()
    local duration = end_time:sub(start_time)

    local status
    if direction == "up" then
        status = "applied"
    else
        status = "reverted"
    end

    return {
        status = status,
        description = migration_item.description,
        duration = duration:milliseconds() / 1000,
        name = migration_item.description
    }
end

function migration.run(fn, options)
    options = options or {}

    if not options.database_id and not options.db then
        return {
            status = "error",
            error = "Database ID or connection is required"
        }
    end

    options.direction = options.direction or "up"
    if options.direction ~= "up" and options.direction ~= "down" then
        return {
            status = "error",
            error = "Invalid direction: must be 'up' or 'down'"
        }
    end

    local db, db_err
    local need_release = false

    if options.db then
        db = options.db
    else
        db, db_err = sql.get(options.database_id)
        if db_err then
            return {
                status = "error",
                error = "Failed to connect to database: " .. tostring(db_err)
            }
        end
        need_release = true
    end

    local init_ok, init_err = repository.init_tracking_table(db)
    if not init_ok then
        if need_release then db:release() end

        return {
            status = "error",
            error = "Failed to initialize migration tracking table: " .. tostring(init_err)
        }
    end

    local db_type, type_err = db:type()
    if type_err then
        if need_release then db:release() end

        return {
            status = "error",
            error = "Failed to determine database type: " .. tostring(type_err)
        }
    end

    local success, implementations_or_err = cpcall(migration_core.define, fn)
    if not success then
        if need_release then db:release() end

        return {
            status = "error",
            error = "Failed to define migration: " .. tostring(implementations_or_err)
        }
    end

    local implementations = implementations_or_err

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

    for _, m in ipairs(implementations) do
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

                if not options.force then
                    results.status = "error"
                    results.error = tostring(result.error)
                    break
                end
            end
        else
            results.skipped = results.skipped + 1
            local skipped_info = {
                name = m.description,
                reason = "No implementation for database type: " .. tostring(db_type)
            }
            table.insert(results.skipped_reasons, skipped_info)
        end
    end

    local end_time = time.now()
    results.duration = end_time:sub(start_time):milliseconds() / 1000

    if not results.status then
        results.status = results.failed > 0 and "failed" or "complete"
    end

    if need_release then
        db:release()
    end

    return results
end

function migration.define(fn)
    if not fn or type(fn) ~= "function" then
        error("Migration definition must be a function")
    end

    return function(options)
        return migration.run(fn, options)
    end
end

return migration