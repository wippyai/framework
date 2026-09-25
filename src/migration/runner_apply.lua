local sql = require("sql")
local time = require("time")
local funcs = require("funcs")
local repository = require("repository")
local registry_finder = require("migration_registry")
local runner_util = require("runner_util")

type ApplyOptions = {
    tags: {string}?,
    allowed_ids: {string}?,
    count: number?,
}

local runner_apply = {}

local function compare_rollback(a: any, b: any): boolean
    local a_applied_at = tostring(a.applied_at or "")
    local b_applied_at = tostring(b.applied_at or "")
    if a_applied_at ~= b_applied_at then
        return a_applied_at > b_applied_at
    end
    return registry_finder.compare(b.registry_entry or b, a.registry_entry or a)
end

local function execute_migration(migration_id: string, options: any): any
    local executor = funcs.new()
    local result, exec_err = executor:call(migration_id, options)
    if exec_err then
        return {
            status = "error",
            error = "Failed to execute migration: " .. tostring(exec_err)
        }
    end

    if result.migrations and #result.migrations > 0 then
        return result.migrations[1]
    end

    return result
end

local function record_skip(results: any, migration: any, reason: string)
    local skip_details = {
        id = migration.id,
        name = runner_util.get_description(migration),
        reason = reason,
        skip_type = "other"
    }
    table.insert(results.skipped_details, skip_details)
    table.insert(results.migrations, {
        id = migration.id,
        status = "skipped",
        skip_type = "other",
        reason = reason,
        description = runner_util.get_description(migration)
    })
end

local function skip_reason(result: any): string
    local reason: string = "Unknown"
    if result ~= nil then
        if result.skipped_reasons ~= nil and #result.skipped_reasons > 0 then
            reason = tostring(result.skipped_reasons[1].reason)
        elseif result.reason ~= nil then
            reason = tostring(result.reason)
        end
    end
    return reason
end

function runner_apply.run(runner_obj: any, options: ApplyOptions?): any
    options = options or {}

    local migrations, find_err = runner_obj:find_migrations(options)
    if find_err then
        return runner_util.create_error(find_err)
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

    local results = {
        status = "running",
        migrations_found = #migrations,
        migrations_applied = 0,
        migrations_skipped = 0,
        migrations_failed = 0,
        migrations = {},
        skipped_details = {}
    }

    local start_time = time.now()

    for _, migration in ipairs(migrations) do
        if migration.applied then
            results.migrations_skipped = results.migrations_skipped + 1
            local skip_details = {
                id = migration.id,
                name = runner_util.get_description(migration),
                reason = "Already applied",
                skip_type = "already_applied"
            }
            table.insert(results.skipped_details, skip_details)
            table.insert(results.migrations, {
                id = migration.id,
                status = "skipped",
                skip_type = "already_applied",
                reason = "Already applied",
                applied_at = migration.applied_at,
                description = runner_util.get_description(migration)
            })
            goto continue
        end

        local migration_options = {
            database_id = runner_obj.database_id,
            direction = "up",
            id = migration.id,
            content_hash = migration.content_hash
        }

        local result = execute_migration(tostring(migration.id), migration_options)

        if result and result.status == "error" then
            results.migrations_failed = results.migrations_failed + 1
            table.insert(results.migrations, {
                id = migration.id,
                status = "error",
                error = result.error,
                description = runner_util.get_description(migration)
            })

            results.status = "error"
            results.error = result.error
            break
        elseif result and result.status == "applied" then
            results.migrations_applied = results.migrations_applied + 1
            table.insert(results.migrations, {
                id = migration.id,
                status = "applied",
                description = runner_util.get_description(migration),
                duration = result.duration
            })
        else
            results.migrations_skipped = results.migrations_skipped + 1
            record_skip(results, migration, skip_reason(result))
        end

        ::continue::
    end

    local end_time = time.now()
    results.duration = end_time:sub(start_time):milliseconds() / 1000

    if results.status ~= "error" then
        results.status = "complete"
    end

    return results
end

function runner_apply.run_next(runner_obj: any, options: ApplyOptions?): any
    options = options or {}

    local migrations, err = runner_obj:find_migrations(options)
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

    local allowed_ids = options.allowed_ids or {}
    local target_migration = nil
    local skipped_migrations = {}

    for _, migration in ipairs(migrations) do
        if not migration.applied then
            if #allowed_ids > 0 then
                local is_allowed = false
                for _, allowed_id in ipairs(allowed_ids) do
                    if migration.id == allowed_id then
                        is_allowed = true
                        break
                    end
                end

                if is_allowed then
                    target_migration = migration
                    break
                else
                    table.insert(skipped_migrations, {
                        id = migration.id,
                        name = runner_util.get_description(migration),
                        reason = "Not in allowed IDs list",
                        skip_type = "other"
                    })
                end
            else
                target_migration = migration
                break
            end
        end
    end

    if not target_migration then
        local message = #skipped_migrations > 0
            and "No migrations in allowed list found"
            or "All migrations have been applied"

        return {
            status = "complete",
            message = message,
            migrations_found = #skipped_migrations,
            migrations_applied = 0,
            migrations_skipped = #skipped_migrations,
            migrations_failed = 0,
            migrations = {},
            skipped_details = skipped_migrations
        }
    end

    local results = {
        status = "running",
        migrations_found = 1 + #skipped_migrations,
        migrations_applied = 0,
        migrations_skipped = #skipped_migrations,
        migrations_failed = 0,
        migrations = {},
        skipped_details = skipped_migrations
    }

    local start_time = time.now()

    local migration_options = {
        database_id = runner_obj.database_id,
        direction = "up",
        id = target_migration.id
    }

    local result = execute_migration(tostring(target_migration.id), migration_options)

    if result and result.status == "error" then
        results.migrations_failed = 1
        table.insert(results.migrations, {
            id = target_migration.id,
            status = "error",
            error = result.error,
            description = runner_util.get_description(target_migration)
        })
        results.status = "error"
        results.error = result.error
    elseif result and result.status == "applied" then
        results.migrations_applied = 1
        table.insert(results.migrations, {
            id = target_migration.id,
            status = "applied",
            description = runner_util.get_description(target_migration),
            duration = result.duration
        })
    else
        results.migrations_skipped = results.migrations_skipped + 1
        record_skip(results, target_migration, skip_reason(result))
    end

    local end_time = time.now()
    results.duration = end_time:sub(start_time):milliseconds() / 1000

    if results.status ~= "error" then
        results.status = "complete"
    end

    return results
end

function runner_apply.rollback(runner_obj: any, options: ApplyOptions?): any
    options = options or {}

    local db, err = sql.get(tostring(runner_obj.database_id))
    if err then
        return runner_util.create_error("Failed to connect to database: " .. tostring(err))
    end

    local init_ok, init_err = repository.init_tracking_table(db)
    if not init_ok then
        db:release()
        return runner_util.create_error("Failed to initialize migration tracking table: " .. tostring(init_err))
    end

    local applied_migrations, query_err = repository.get_migrations(db)
    if query_err then
        db:release()
        return runner_util.create_error("Failed to get applied migrations: " .. tostring(query_err))
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

    for i, migration in ipairs(applied_migrations) do
        local registry_entry = registry_finder.get(tostring(migration.id))
        if registry_entry then
            applied_migrations[i].registry_entry = registry_entry
        end
    end

    table.sort(applied_migrations, compare_rollback)

    local allowed_ids = options.allowed_ids or {}

    if #allowed_ids > 0 then
        local filtered = {}
        for _, migration in ipairs(applied_migrations) do
            for _, allowed_id in ipairs(allowed_ids) do
                if migration.id == allowed_id then
                    table.insert(filtered, migration)
                    break
                end
            end
        end

        if #filtered == 0 then
            return {
                status = "complete",
                message = "No migrations in allowed list found in applied migrations",
                migrations_found = 0,
                migrations_reverted = 0,
                migrations_skipped = 0,
                migrations_failed = 0
            }
        end

        applied_migrations = filtered
    end

    local count = options.count or 1
    if count > #applied_migrations then
        count = #applied_migrations
    end

    local to_rollback = {}
    for i = 1, count do
        table.insert(to_rollback, applied_migrations[i])
    end

    local results = {
        status = "running",
        migrations_found = #to_rollback,
        migrations_reverted = 0,
        migrations_skipped = 0,
        migrations_failed = 0,
        migrations = {},
        skipped_details = {}
    }

    local start_time = time.now()

    for _, migration in ipairs(to_rollback) do
        local migration_options = {
            database_id = runner_obj.database_id,
            direction = "down",
            id = migration.id
        }

        local result = execute_migration(tostring(migration.id), migration_options)

        if result and result.status == "error" then
            results.migrations_failed = results.migrations_failed + 1
            table.insert(results.migrations, {
                id = migration.id,
                status = "error",
                error = result.error,
                description = migration.description or ""
            })

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
            local reason = skip_reason(result)
            local skip_details = {
                id = migration.id,
                name = migration.description or "",
                reason = reason,
                skip_type = "other"
            }
            table.insert(results.skipped_details, skip_details)
            table.insert(results.migrations, {
                id = migration.id,
                status = "skipped",
                skip_type = "other",
                reason = reason,
                description = migration.description or ""
            })
        end
    end

    local end_time = time.now()
    results.duration = end_time:sub(start_time):milliseconds() / 1000

    if results.status ~= "error" then
        results.status = "complete"
    end

    return results
end

return runner_apply
