local time = require("time")
local json = require("json")
local logger = require("logger")
local migration_registry = require("migration_registry")
local runner = require("runner")
local sql = require("sql")

local log = logger:named("boot")

local function get_description(skip)
    if skip.name and skip.name ~= "" then
        return skip.name
    end
    return "No description"
end

local function wait_for_database(db_id, max_attempts, sleep_ms)
    for attempt = 1, max_attempts do
        local db, err = sql.get(db_id)
        if not err then
            db:release()
            if attempt > 1 then
                log:info("Database connection established", {
                    database = db_id,
                    attempts = attempt
                })
            end
            return true, nil
        end

        if attempt < max_attempts then
            log:warn("Database not ready, retrying...", {
                database = db_id,
                attempt = attempt,
                max_attempts = max_attempts,
                error = err
            })
            time.sleep(sleep_ms .. "ms")
        else
            log:error("Database connection failed after max attempts", {
                database = db_id,
                attempts = max_attempts,
                error = err
            })
            return false, err
        end
    end

    return false, "Max retry attempts reached"
end

local function log_migration(migration, database)
    local prefix
    local log_level

    if migration.status == "applied" then
        prefix = "APPLIED"
        log_level = "info"
    elseif migration.status == "reverted" then
        prefix = "REVERTED"
        log_level = "info"
    elseif migration.status == "error" then
        prefix = "FAILED"
        log_level = "error"
    elseif migration.status == "skipped" then
        if migration.skip_type == "already_applied" then
            prefix = "EXISTING"
            log_level = "info"
        else
            prefix = "SKIPPED"
            log_level = "warn"
        end
    else
        prefix = "UNKNOWN"
        log_level = "warn"
    end

    local log_data = {
        database = database,
        description = migration.description or "No description"
    }

    if migration.status == "error" then
        log_data.error = migration.error
    elseif migration.status == "applied" or migration.status == "reverted" then
        log_data.duration = migration.duration
    elseif migration.status == "skipped" then
        log_data.reason = migration.reason
    end

    if log_level == "error" then
        log:error(prefix .. ": " .. migration.id, log_data)
    elseif log_level == "warn" then
        log:warn(prefix .. ": " .. migration.id, log_data)
    else
        log:info(prefix .. ": " .. migration.id, log_data)
    end
end

local function run()
    log:info("Initializing migration bootloader")

    local target_dbs, err = migration_registry.get_target_dbs()
    if err then
        log:error("Failed to discover target databases", { error = err })
        return false, "Failed to discover target databases: " .. err
    end

    if not target_dbs or #target_dbs == 0 then
        log:info("No target databases found")
        return true, "No migrations to apply"
    end

    log:info("Discovered target databases", {
        count = #target_dbs,
        databases = target_dbs
    })

    local total_stats = {
        applied = 0,
        failed = 0,
        skipped = 0,
        total = 0,
        databases = {}
    }

    local had_failure = false

    for _, db_resource in ipairs(target_dbs) do
        log:info("Processing migrations for database", { database = db_resource })

        local db_ready, db_err = wait_for_database(db_resource, 20, 500)
        if not db_ready then
            had_failure = true
            log:error("Database unavailable, skipping migrations", {
                database = db_resource,
                error = db_err
            })

            local db_stats = {
                database = db_resource,
                applied = 0,
                failed = 0,
                skipped = 0,
                total = 0,
                status = "error",
                duration = 0
            }
            table.insert(total_stats.databases, db_stats)
            break
        end

        local db_runner = runner.setup(db_resource)
        local result = db_runner:run()

        local db_stats = {
            database = db_resource,
            applied = result.migrations_applied or 0,
            failed = result.migrations_failed or 0,
            skipped = result.migrations_skipped or 0,
            total = result.migrations_found or 0,
            status = result.status,
            duration = result.duration
        }

        table.insert(total_stats.databases, db_stats)

        total_stats.applied = total_stats.applied + db_stats.applied
        total_stats.failed = total_stats.failed + db_stats.failed
        total_stats.skipped = total_stats.skipped + db_stats.skipped
        total_stats.total = total_stats.total + db_stats.total

        if result.status == "error" then
            had_failure = true
            log:error("Migration failed", {
                database = db_resource,
                error = result.error,
                applied = db_stats.applied,
                failed = db_stats.failed
            })

            if result.migrations and #result.migrations > 0 then
                for _, migration in ipairs(result.migrations) do
                    log_migration(migration, db_resource)
                end
            end

            break
        else
            log:info("Completed migrations", {
                database = db_resource,
                applied = db_stats.applied,
                skipped = db_stats.skipped,
                failed = db_stats.failed,
                duration = db_stats.duration
            })

            if result.migrations and #result.migrations > 0 then
                for _, migration in ipairs(result.migrations) do
                    log_migration(migration, db_resource)
                end
            end
        end
    end

    local completion_status = had_failure and "error" or "success"
    local completion_message = had_failure
        and "Migration bootloader completed with errors"
        or "Migration bootloader completed successfully"

    log:info(completion_message, {
        status = completion_status,
        databases_processed = #total_stats.databases,
        total_migrations = total_stats.total,
        applied = total_stats.applied,
        failed = total_stats.failed,
        skipped = total_stats.skipped
    })

    return not had_failure, {
        status = completion_status,
        databases_processed = #total_stats.databases,
        applied = total_stats.applied,
        failed = total_stats.failed,
        skipped = total_stats.skipped,
        total = total_stats.total,
        databases = total_stats.databases
    }
end

return { run = run }