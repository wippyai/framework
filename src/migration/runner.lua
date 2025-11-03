local sql = require("sql")
local time = require("time")
local funcs = require("funcs")
local repository = require("repository")
local registry_finder = require("registry")

local runner = {}

local function create_error(message)
    return {
        status = "error",
        error = tostring(message)
    }
end

local function get_description(migration)
    if migration.meta and migration.meta.description and migration.meta.description ~= "" then
        return migration.meta.description
    end
    if migration.comment and migration.comment ~= "" then
        return migration.comment
    end
    return ""
end

local Runner = {}
Runner.__index = Runner

function runner.setup(database_id)
    if not database_id then
        error("Database ID is required for migration runner setup")
    end

    local self = setmetatable({}, Runner)
    self.database_id = database_id

    return self
end

function Runner:find_migrations(options)
    options = options or {}

    local db, err = sql.get(self.database_id)
    if err then
        return nil, "Failed to connect to database: " .. tostring(err)
    end

    local db_type, type_err = db:type()
    if type_err then
        db:release()
        return nil, "Failed to determine database type: " .. tostring(type_err)
    end

    local init_ok, init_err = repository.init_tracking_table(db)
    if not init_ok then
        db:release()
        return nil, "Failed to initialize migration tracking table: " .. tostring(init_err)
    end

    local applied_migrations, applied_err = repository.get_migrations(db)
    if applied_err then
        db:release()
        return nil, "Failed to get applied migrations: " .. tostring(applied_err)
    end

    local applied_map = {}
    for _, m in ipairs(applied_migrations or {}) do
        applied_map[m.id] = m
    end

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

    local applied = {}
    local pending = {}

    for _, migration in ipairs(migrations) do
        local migration_id = migration.id
        if applied_map[migration_id] then
            migration.applied = true
            migration.applied_at = applied_map[migration_id].applied_at
            table.insert(applied, migration)
        else
            migration.applied = false
            migration.applied_at = nil
            table.insert(pending, migration)
        end
    end

    table.sort(applied, function(a, b)
        return (a.applied_at or "") < (b.applied_at or "")
    end)

    table.sort(pending, function(a, b)
        local a_time = a.meta and a.meta.timestamp or ""
        local b_time = b.meta and b.meta.timestamp or ""
        return a_time < b_time
    end)

    local sorted = {}
    for _, m in ipairs(applied) do
        table.insert(sorted, m)
    end
    for _, m in ipairs(pending) do
        table.insert(sorted, m)
    end

    return sorted
end

function Runner:get_next_migration(options)
    local migrations, err = self:find_migrations(options)
    if err then
        return nil, err
    end

    if not migrations or #migrations == 0 then
        return nil, "No migrations found"
    end

    for _, migration in ipairs(migrations) do
        if not migration.applied then
            return migration
        end
    end

    return nil, "All migrations have been applied"
end

local function execute_migration(migration_id, options)
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

function Runner:run(options)
    options = options or {}

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
                name = get_description(migration),
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
                description = get_description(migration)
            })
            goto continue
        end

        local migration_options = {
            database_id = self.database_id,
            direction = "up",
            id = migration.id
        }

        local result = execute_migration(migration.id, migration_options)

        if result and result.status == "error" then
            results.migrations_failed = results.migrations_failed + 1
            table.insert(results.migrations, {
                id = migration.id,
                status = "error",
                error = result.error,
                description = get_description(migration)
            })

            results.status = "error"
            results.error = result.error
            break
        elseif result and result.status == "applied" then
            results.migrations_applied = results.migrations_applied + 1
            table.insert(results.migrations, {
                id = migration.id,
                status = "applied",
                description = get_description(migration),
                duration = result.duration
            })
        else
            results.migrations_skipped = results.migrations_skipped + 1

            local reason = result and result.reason or "Unknown"

            if result and result.skipped_reasons and #result.skipped_reasons > 0 then
                reason = result.skipped_reasons[1].reason
            end

            local skip_details = {
                id = migration.id,
                name = get_description(migration),
                reason = reason,
                skip_type = "other"
            }
            table.insert(results.skipped_details, skip_details)
            table.insert(results.migrations, {
                id = migration.id,
                status = "skipped",
                skip_type = "other",
                reason = reason,
                description = get_description(migration)
            })
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

function Runner:run_next(options)
    options = options or {}

    local migrations, err = self:find_migrations(options)
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
                        name = get_description(migration),
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
        database_id = self.database_id,
        direction = "up",
        id = target_migration.id
    }

    local result = execute_migration(target_migration.id, migration_options)

    if result and result.status == "error" then
        results.migrations_failed = 1
        table.insert(results.migrations, {
            id = target_migration.id,
            status = "error",
            error = result.error,
            description = get_description(target_migration)
        })
        results.status = "error"
        results.error = result.error
    elseif result and result.status == "applied" then
        results.migrations_applied = 1
        table.insert(results.migrations, {
            id = target_migration.id,
            status = "applied",
            description = get_description(target_migration),
            duration = result.duration
        })
    else
        results.migrations_skipped = results.migrations_skipped + 1

        local reason = result and result.reason or "Unknown"

        if result and result.skipped_reasons and #result.skipped_reasons > 0 then
            reason = result.skipped_reasons[1].reason
        end

        local skip_details = {
            id = target_migration.id,
            name = get_description(target_migration),
            reason = reason,
            skip_type = "other"
        }
        table.insert(results.skipped_details, skip_details)
        table.insert(results.migrations, {
            id = target_migration.id,
            status = "skipped",
            skip_type = "other",
            reason = reason,
            description = get_description(target_migration)
        })
    end

    local end_time = time.now()
    results.duration = end_time:sub(start_time):milliseconds() / 1000

    if results.status ~= "error" then
        results.status = "complete"
    end

    return results
end

function Runner:rollback(options)
    options = options or {}

    local db, err = sql.get(self.database_id)
    if err then
        return create_error("Failed to connect to database: " .. tostring(err))
    end

    local init_ok, init_err = repository.init_tracking_table(db)
    if not init_ok then
        db:release()
        return create_error("Failed to initialize migration tracking table: " .. tostring(init_err))
    end

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

    for i, migration in ipairs(applied_migrations) do
        local registry_entry = registry_finder.get(migration.id)
        if registry_entry then
            applied_migrations[i].registry_entry = registry_entry
        end
    end

    table.sort(applied_migrations, function(a, b)
        return (a.applied_at or "") > (b.applied_at or "")
    end)

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
            database_id = self.database_id,
            direction = "down",
            id = migration.id
        }

        local result = execute_migration(migration.id, migration_options)

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

            local reason = result and result.reason or "Unknown"

            if result and result.skipped_reasons and #result.skipped_reasons > 0 then
                reason = result.skipped_reasons[1].reason
            end

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

function Runner:status(options)
    options = options or {}

    local migrations, find_err = self:find_migrations(options)
    if find_err then
        return create_error(find_err)
    end

    local status_report = {
        database_id = self.database_id,
        db_type = nil,
        total_migrations = #migrations,
        applied_migrations = 0,
        pending_migrations = 0,
        migrations = {}
    }

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

    for _, migration in ipairs(migrations) do
        local migration_status = {
            id = migration.id,
            description = get_description(migration),
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