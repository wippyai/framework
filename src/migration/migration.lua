local migration = {}
local sql = require("sql")
local time = require("time")

local migration_core = require("core")
local repository = require("repository")

type RunOptions = {
    database_id: string?,
    db: any?,
    db_type: string?,
    direction: string?,
    force: boolean?,
    id: string?,
    aliases: {string}?,
}

type RunResult = {
    status: string,
    migrations: {any},
    total: number,
    applied: number,
    skipped: number,
    failed: number,
    duration: number?,
}

local function execute_batch(tx: any, impl: any, progress_table: string, progress_ids: {string}, migration_id: string): string?
    local cursor, progress_err = repository.get_progress(tx, progress_table, progress_ids)
    if progress_err then error(progress_err) end
    local next_cursor = impl.up_batch(tx, cursor)
    if next_cursor ~= nil then
        if type(next_cursor) ~= "string" or next_cursor == "" or next_cursor == cursor then
            error("Batched migration checkpoint must be a non-empty string different from the previous checkpoint")
        end
        local saved, save_err = repository.record_progress(tx, progress_table, migration_id, next_cursor)
        if not saved then error(save_err) end
    end
    return next_cursor
end

local function execute_page(migration_item: any, options: any): any
    if not migration_item or not options or not options.db or not options.db_type then
        return {
            status = "error",
            error = "Invalid migration or options"
        }
    end

    local db = options.db
    local db_type = options.db_type
    local direction = options.direction or "up"

    local migration_id: string
    if options.id then
        migration_id = tostring(options.id)
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

    if (impl.up_batch or impl.up_external_batch) and (migration_id == "" or #migration_id > 512) then
        return {status = "error", description = migration_item.description,
            name = migration_item.description, error = "Batched migration ID must contain 1 to 512 characters"}
    end

    if (impl.up_batch or impl.up_external_batch) and db_type ~= sql.type.SQLITE and db_type ~= sql.type.POSTGRES then
        return {status = "error", description = migration_item.description,
            name = migration_item.description, error = "Batched migrations support only SQLite and PostgreSQL"}
    end

    if direction == "up" and not impl.up and not impl.up_batch and not impl.up_external_batch then
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

    -- READ COMMITTED ensures a waiter sees the winner's committed ledger entry.
    local tx_options = db_type == sql.type.POSTGRES and {isolation = sql.isolation.READ_COMMITTED} or nil
    local tx, tx_err = db:begin(tx_options)
    if tx_err then
        return {
            status = "error",
            description = migration_item.description,
            error = "Failed to start transaction: " .. tostring(tx_err),
            name = migration_item.description
        }
    end

    local _, lock_err
    if db_type == sql.type.POSTGRES then
        -- Database-scoped ledger lock, also used when creating the tracking table.
        -- It covers DDL, hooks and recording, and releases on commit/rollback.
        _, lock_err = tx:query("SELECT pg_advisory_xact_lock(hashtext(current_database()), hashtext('wippy.migration:_migrations'))")
    elseif db_type == sql.type.SQLITE then
        -- Acquire SQLite's writer lock BEFORE reading: a deferred read snapshot
        -- cannot safely upgrade to a writer after another runner commits.
        _, lock_err = tx:execute("UPDATE _migrations SET id = id WHERE 0")
    end
    if lock_err then
        tx:rollback()
        return {
            status = "error",
            description = migration_item.description,
            error = "Failed to lock migration target: " .. tostring(lock_err),
            name = migration_item.description
        }
    end

    if direction == "up" then
        local is_applied, check_err = repository.is_applied(tx, migration_id)
        if check_err then
            tx:rollback()
            return {
                status = "error",
                description = migration_item.description,
                error = "Failed to check migration status: " .. tostring(check_err),
                name = migration_item.description
            }
        end

        if not is_applied and type(options.aliases) == "table" then
            for _, alias in ipairs(options.aliases) do
                local alias_applied, alias_err = repository.is_applied(tx, tostring(alias))
                if alias_err then
                    tx:rollback()
                    return {
                        status = "error",
                        description = migration_item.description,
                        error = "Failed to check migration status: " .. tostring(alias_err),
                        name = migration_item.description
                    }
                end

                if alias_applied then
                    is_applied = true
                    break
                end
            end
        end

        if is_applied and options.force and (impl.up_batch or impl.up_external_batch) then
            tx:rollback()
            return {status = "error", description = migration_item.description,
                name = migration_item.description, error = "Cannot force an applied batched migration"}
        end

        if is_applied and not options.force then
            tx:rollback()
            return {
                status = "skipped",
                description = migration_item.description,
                reason = "Migration already applied",
                name = migration_item.description
            }
        end
    end

    local start_time = time.now()
    local success, err
    local more = false
    local progress_ids: {string}? = nil
    local progress_table = options.progress_table
    if impl.up_batch or impl.up_external_batch then
        progress_ids = {migration_id}
        for _, alias in ipairs(options.aliases or {}) do
            table.insert(progress_ids, tostring(alias))
        end
        if not progress_table then
            local progress_err
            progress_table, progress_err = repository.init_progress_table(tx, db_type)
            if not progress_table then
                tx:rollback()
                return {status = "error", description = migration_item.description,
                    name = migration_item.description, error = "Failed to initialize migration progress: " .. tostring(progress_err)}
            end
        end
    end

    if direction == "up" and impl.up_external_batch then
        local cursor, cursor_err = repository.get_progress(tx, progress_table, progress_ids :: {string})
        if cursor_err then
            tx:rollback()
            return {status = "error", name = migration_item.description, error = tostring(cursor_err)}
        end
        if not options.external_ready then
            -- Release the ledger lock before any caller-owned work. The same
            -- runner validates and commits its checkpoint in a fresh page.
            local committed, commit_err = tx:commit()
            if not committed or commit_err then
                tx:rollback()
                return {status = "error", name = migration_item.description,
                    error = "Failed to commit external batch snapshot: " .. tostring(commit_err)}
            end
            options.progress_table = progress_table
            return {status = "prepared", cursor = cursor}
        end
        if cursor ~= options.external_cursor then
            tx:rollback()
            return {status = "pending"}
        end
        local next_cursor = options.external_next_cursor
        if next_cursor ~= nil and (type(next_cursor) ~= "string" or next_cursor == "" or next_cursor == cursor) then
            tx:rollback()
            return {status = "error", name = migration_item.description,
                error = "Batched migration checkpoint must be a non-empty string different from the previous checkpoint"}
        end
        success, err = true, nil
        if next_cursor ~= nil then
            local saved, save_err = repository.record_progress(tx, progress_table, migration_id, next_cursor)
            success, err = saved ~= nil and saved ~= false and save_err == nil, save_err
            more = success
        end
    elseif direction == "up" and impl.up_batch then
        success, err = pcall(execute_batch, tx, impl, progress_table, progress_ids :: {string}, migration_id)
        more = success and err ~= nil
    elseif direction == "up" then
        success, err = pcall(impl.up, tx)
    else
        success, err = pcall(impl.down, tx)

        if success then
            local ids_to_remove = { migration_id }
            if type(options.aliases) == "table" then
                for _, alias in ipairs(options.aliases) do
                    table.insert(ids_to_remove, tostring(alias))
                end
            end

            for _, remove_id in ipairs(ids_to_remove) do
                local remove_ok, remove_err = repository.remove_migration(tx, remove_id)
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

    if direction == "up" and not more then
        local record_ok, record_err = repository.record_migration(
            tx,
            migration_id,
            tostring(migration_item.description)
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

    if direction == "up" and not more and impl.after then
        local after_success, after_err = pcall(impl.after, tx)
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

    if (impl.up_batch or impl.up_external_batch) and not more then
        local removed, remove_err = repository.remove_progress(tx, progress_table, progress_ids :: {string})
        if not removed then
            tx:rollback()
            return {status = "error", description = migration_item.description,
                name = migration_item.description, error = "Failed to remove migration progress: " .. tostring(remove_err)}
        end
    end

    local commit_success, commit_err = tx:commit()
    if not commit_success or commit_err then
        tx:rollback()
        return {
            status = "error",
            description = migration_item.description,
            error = "Failed to commit transaction: " .. tostring(commit_err),
            name = migration_item.description
        }
    end

    options.progress_table = progress_table
    local end_time = time.now()
    local duration = end_time:sub(start_time)

    local status
    if more then
        status = "pending"
    elseif direction == "up" then
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

local function execute_batched_migration(migration_item: any, options: any): any
    local started = time.now()
    local external = migration_item.database_implementations[options.db_type].up_external_batch
    local contention_attempts = 0
    while true do
        local result = execute_page(migration_item, options)
        if result.status == "prepared" then
            local success, next_cursor = pcall(external, options.db, result.cursor)
            if success then
                options.external_ready = true
                options.external_cursor = result.cursor
                options.external_next_cursor = next_cursor
                result = execute_page(migration_item, options)
                options.external_ready = nil
                options.external_cursor = nil
                options.external_next_cursor = nil
            else
                result = {status = "error", name = migration_item.description, error = tostring(next_cursor)}
            end
        end
        -- Only the opt-in external mode can replay committed caller work.
        -- Every such callback must be idempotent, including its final action.
        local contended = false
        if external and options.db_type == sql.type.SQLITE and result.status == "error" then
            local message = tostring(result.error):lower()
            contended = message:find("database is locked", 1, true) ~= nil
                or message:find("database table is locked", 1, true) ~= nil
                or message:find("database schema is locked", 1, true) ~= nil
        end
        if contended and contention_attempts < 4 then
            time.sleep(tostring(50 * 2 ^ contention_attempts) .. "ms")
            contention_attempts = contention_attempts + 1
        elseif result.status ~= "pending" then
            result.duration = time.now():sub(started):milliseconds() / 1000
            return result
        else
            contention_attempts = 0
        end
    end
end

function migration.run(fn: () -> (), options: RunOptions?): any
    local opts: RunOptions = options or {} :: RunOptions

    if not opts.database_id and not opts.db then
        return {
            status = "error",
            error = "Database ID or connection is required"
        }
    end

    opts.direction = opts.direction or "up"
    if opts.direction ~= "up" and opts.direction ~= "down" then
        return {
            status = "error",
            error = "Invalid direction: must be 'up' or 'down'"
        }
    end

    local db: any
    local db_err: string?
    local need_release = false

    if opts.db then
        db = opts.db
    else
        db, db_err = sql.get(tostring(opts.database_id))
        if db_err then
            return {
                status = "error",
                error = "Failed to connect to database: " .. tostring(db_err)
            }
        end
        need_release = true
    end

    if not db then
        return {
            status = "error",
            error = "Failed to obtain database connection"
        }
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

    local success, implementations_or_err = pcall(migration_core.define, fn)
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
            local execute = execute_page
            if opts.direction == "up" and (m.database_implementations[db_type].up_batch
                or m.database_implementations[db_type].up_external_batch) then
                execute = execute_batched_migration
            end
            local result = execute(m, {
                db = db,
                db_type = db_type,
                direction = opts.direction,
                force = opts.force,
                id = opts.id,
                aliases = opts.aliases,
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

                if not opts.force then
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

function migration.define(fn: () -> ()): (RunOptions?) -> any
    if not fn or type(fn) ~= "function" then
        error("Migration definition must be a function")
    end

    return function(options: RunOptions?): any
        return migration.run(fn, options)
    end
end

return migration
