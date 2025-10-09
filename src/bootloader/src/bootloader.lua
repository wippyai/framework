local time = require("time")
local json = require("json")
local logger = require("logger")
local migration_registry = require("migration_registry")
local runner = require("runner")

local log = logger:named("boot")

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
            log:error("Migration failed for database", {
                database = db_resource,
                error = result.error,
                applied = db_stats.applied,
                failed = db_stats.failed
            })

            if result.skipped_details and #result.skipped_details > 0 then
                for _, skip in ipairs(result.skipped_details) do
                    log:info("Skipped migration", {
                        database = db_resource,
                        migration = skip.name,
                        reason = skip.reason
                    })
                end
            end

            break
        else
            log:info("Completed migrations for database", {
                database = db_resource,
                applied = db_stats.applied,
                skipped = db_stats.skipped,
                failed = db_stats.failed,
                duration = db_stats.duration
            })

            if result.skipped_details and #result.skipped_details > 0 then
                for _, skip in ipairs(result.skipped_details) do
                    log:info("Skipped migration", {
                        database = db_resource,
                        migration = skip.name,
                        reason = skip.reason
                    })
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
