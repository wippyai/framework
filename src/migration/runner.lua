local sql = require("sql")
local repository = require("repository")
local registry_finder = require("migration_registry")
local candidate = require("candidate")
local runner_util = require("runner_util")
local runner_apply = require("runner_apply")

type RunnerOptions = {
    tags: {string}?,
    allowed_ids: {string}?,
    count: number?,
}

local runner = {}

local function compare_applied(a: any, b: any): boolean
    local a_applied_at = tostring(a.applied_at or "")
    local b_applied_at = tostring(b.applied_at or "")
    if a_applied_at ~= b_applied_at then
        return a_applied_at < b_applied_at
    end
    return registry_finder.compare(a, b)
end

local Runner = {}
Runner.__index = Runner

function runner.setup(database_id: string): any
    if not database_id then
        error("Database ID is required for migration runner setup")
    end

    local self = setmetatable({}, Runner)
    self.database_id = database_id

    return self
end

function Runner:find_migrations(options: RunnerOptions?): ({any}?, string?)
    options = options or {}

    local db, err = sql.get(tostring(self.database_id))
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

    local find_options: any = {
        target_db = tostring(self.database_id),
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
        local content_hash, hash_err = candidate.entry_hash(migration)
        if hash_err then
            return nil, "Failed to hash migration " .. tostring(migration_id)
                .. ": " .. tostring(hash_err)
        end
        migration.content_hash = content_hash
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

    table.sort(applied, compare_applied)
    table.sort(pending, registry_finder.compare)

    local sorted = {}
    for _, m in ipairs(applied) do
        table.insert(sorted, m)
    end
    for _, m in ipairs(pending) do
        table.insert(sorted, m)
    end

    return sorted
end

function Runner:get_next_migration(options: RunnerOptions?): (any?, string?)
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

function Runner:run(options: RunnerOptions?): any
    return runner_apply.run(self, options)
end

function Runner:run_next(options: RunnerOptions?): any
    return runner_apply.run_next(self, options)
end

function Runner:rollback(options: RunnerOptions?): any
    return runner_apply.rollback(self, options)
end

function Runner:status(options: RunnerOptions?): any
    options = options or {}

    local migrations, find_err = self:find_migrations(options)
    if find_err then
        return runner_util.create_error(find_err)
    end

    local status_report = {
        database_id = self.database_id,
        db_type = nil,
        total_migrations = #migrations,
        applied_migrations = 0,
        pending_migrations = 0,
        migrations = {}
    }

    local db, err = sql.get(tostring(self.database_id))
    if err then
        return runner_util.create_error("Failed to connect to database: " .. tostring(err))
    end

    local db_type, type_err = db:type()
    if type_err then
        db:release()
        return runner_util.create_error("Failed to determine database type: " .. tostring(type_err))
    end

    status_report.db_type = db_type
    db:release()

    for _, migration in ipairs(migrations) do
        local migration_status = {
            id = migration.id,
            description = runner_util.get_description(migration),
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
