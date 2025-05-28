local time = require("time")
local json = require("json")
local sql = require("sql")
local env = require("env")
local logger = require("logger")
local migration_registry = require("migration_registry")
local runner = require("runner")
local funcs = require("funcs")

local log = logger:named("boot")

-- Main bootloader function
local function run()
    log:info("Initializing migration bootloader")

    -- Check APP_DB environment variable
    local db_resource = env.get("APP_DB")
    if not db_resource then
        log:error("APP_DB environment variable not set")
        return false, "APP_DB environment variable not set"
    end

    log:info("Connecting to database", { db = db_resource })

    -- Get database connection
    local db, err = sql.get(db_resource)
    if err then
        log:error("Connection failed", { error = err })
        return false, "Connection failed: " .. err
    end

    -- Get database type
    local db_type, type_err = db:type()
    if not type_err then
        log:info("Connected to database", { type = db_type })
    end

    -- Fetch migrations
    local migrations, find_err = migration_registry.find({
        meta = { target_db = db_resource }
    })

    if find_err then
        log:error("Failed to find migrations", { error = find_err })
        return false, "Failed to find migrations: " .. find_err
    end

    -- Sort migrations by timestamp and then by name
    table.sort(migrations, function(a, b)
        local a_time = a.meta and a.meta.timestamp or ""
        local b_time = b.meta and b.meta.timestamp or ""

        -- First sort by timestamp
        if a_time ~= b_time then
            return a_time < b_time
        end

        -- Secondary sort by name if timestamps are equal
        local a_id = a.id or ""
        local b_id = b.id or ""

        local _, a_name = a_id:match("([^:]+):([^:]+)")
        local _, b_name = b_id:match("([^:]+):([^:]+)")

        a_name = a_name or ""
        b_name = b_name or ""

        return a_name < b_name
    end)

    if #migrations == 0 then
        log:info("No migrations to apply")
        return true, "No migrations to apply"
    end

    log:info("Found migrations to apply", { count = #migrations })

    -- Statistics counters
    local applied_count = 0
    local failed_count = 0
    local skipped_count = 0

    -- Check already applied migrations
    local applied_migrations = {}
    local check_query = "SELECT id FROM _migrations" -- todo: use repository
    local check_result, check_err = db:query(check_query)

    if not check_err and check_result then
        for _, row in ipairs(check_result) do
            applied_migrations[row.id] = true
        end
    end

    -- Execute each migration
    local had_failure = false
    for i, migration in ipairs(migrations) do
        local id = migration.id
        local _, name = id:match("([^:]+):([^:]+)")
        name = name or "unknown"

        -- Skip if previous migration failed
        if had_failure then
            log:warn("Skipping migration due to previous failure", {
                migration = name,
                index = i,
                total = #migrations
            })
            skipped_count = skipped_count + 1
            goto continue
        end

        -- Skip if already applied
        if applied_migrations[id] then
            log:info("Skipping migration (already applied)", {
                migration = name,
                index = i,
                total = #migrations
            })
            skipped_count = skipped_count + 1
            goto continue
        end

        log:info("Running migration", {
            migration = name,
            index = i,
            total = #migrations
        })

        -- Find migration function
        local executor = funcs.new()
        local options = {
            database_id = db_resource,
            direction = "up",
            id = id
        }

        -- Call the migration directly and capture detailed results
        local result, err = executor:call(id, options)

        -- Process based on result
        if err then
            failed_count = failed_count + 1
            log:error("Execution error", {
                migration = name,
                error = tostring(err)
            })
            had_failure = true
        elseif result then
            -- Process various success statuses
            if result.status == "applied" or result.status == "complete" then
                applied_count = applied_count + 1
                log:info("Successfully applied migration", { migration = name })
            elseif result.status == "error" then
                failed_count = failed_count + 1
                log:error("Migration failed", {
                    migration = name,
                    error = result.error or "Unknown error"
                })
                had_failure = true
            elseif result.status == "skipped" then
                skipped_count = skipped_count + 1
                log:info("Migration skipped", {
                    migration = name,
                    reason = result.reason or "Unknown"
                })
            elseif result.migrations and #result.migrations > 0 then
                -- Try to get status from nested migration result
                local migration_result = result.migrations[1]
                if migration_result.status == "applied" then
                    applied_count = applied_count + 1
                    log:info("Successfully applied migration", { migration = name })
                elseif migration_result.status == "error" then
                    failed_count = failed_count + 1
                    log:error("Migration failed", {
                        migration = name,
                        error = migration_result.error or "Unknown error"
                    })
                    had_failure = true
                elseif migration_result.status == "skipped" then
                    skipped_count = skipped_count + 1
                    log:info("Migration skipped", {
                        migration = name,
                        reason = migration_result.reason or "Unknown"
                    })
                else
                    skipped_count = skipped_count + 1
                end
            else
                skipped_count = skipped_count + 1
            end
        else
            skipped_count = skipped_count + 1
        end

        ::continue::
    end

    -- Log completion message with statistics
    local completion_status = (applied_count > 0)
        and "Migrations complete"
        or (failed_count > 0)
        and "Migrations failed"
        or "No migrations applied"

    log:info(completion_status, {
        applied = applied_count,
        failed = failed_count,
        skipped = skipped_count,
        total = #migrations
    })

    -- Close database connection if open
    if db then
        local release_ok, release_err = db:release()
        if release_err then
            log:warn("Error releasing database connection", { error = release_err })
        end
    end

    -- Return result
    return failed_count == 0, {
        status = failed_count == 0 and "success" or "error",
        applied = applied_count,
        failed = failed_count,
        skipped = skipped_count,
        total = #migrations
    }
end

return { run = run }