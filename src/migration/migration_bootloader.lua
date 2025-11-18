local time = require("time")
local sql = require("sql")
local logger = require("logger")
local migration_registry = require("migration_registry")
local runner = require("runner")

local log = logger:named("boot.migrations")

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

local function run(options)
    log:info("Starting migration bootloader")

    -- Find target databases
    local target_dbs, err = migration_registry.get_target_dbs()
    if err then
        return {
            status = "error",
            message = "Failed to discover target databases: " .. err
        }
    end

    if not target_dbs or #target_dbs == 0 then
        log:info("No target databases found")
        return {
            status = "skipped",
            message = "No migrations to apply"
        }
    end

    log:info("Discovered target databases", {
        count = #target_dbs,
        databases = target_dbs
    })

    local total_applied = 0
    local total_failed = 0
    local total_skipped = 0
    local databases_processed = {}

    -- Execute migrations for each target database
    for _, db_resource in ipairs(target_dbs) do
        log:info("Processing migrations for database", { database = db_resource })

        local db_ready, db_err = wait_for_database(db_resource, 20, 500)
        if not db_ready then
            log:error("Database unavailable, skipping migrations", {
                database = db_resource,
                error = db_err
            })

            return {
                status = "error",
                message = "Database unavailable: " .. db_err,
                details = {
                    database = db_resource,
                    databases_processed = databases_processed
                }
            }
        end

        local db_runner = runner.setup(db_resource)
        local result = db_runner:run()

        table.insert(databases_processed, {
            database = db_resource,
            applied = result.migrations_applied or 0,
            failed = result.migrations_failed or 0,
            skipped = result.migrations_skipped or 0,
            status = result.status
        })

        total_applied = total_applied + (result.migrations_applied or 0)
        total_failed = total_failed + (result.migrations_failed or 0)
        total_skipped = total_skipped + (result.migrations_skipped or 0)

        if result.status == "error" then
            log:error("Migration failed for database", {
                database = db_resource,
                error = result.error
            })

            return {
                status = "error",
                message = "Migration failed: " .. result.error,
                details = {
                    databases_processed = databases_processed,
                    total_applied = total_applied,
                    total_failed = total_failed,
                    total_skipped = total_skipped
                }
            }
        end

        log:info("Completed migrations for database", {
            database = db_resource,
            applied = result.migrations_applied,
            skipped = result.migrations_skipped
        })
    end

    return {
        status = "success",
        message = string.format(
            "Processed %d database(s): %d applied, %d skipped",
            #target_dbs,
            total_applied,
            total_skipped
        ),
        details = {
            databases_processed = databases_processed,
            total_applied = total_applied,
            total_failed = total_failed,
            total_skipped = total_skipped
        }
    }
end

return { run = run }
