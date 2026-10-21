local test = require("test")
local sql = require("sql")
local env = require("env")
local time = require("time")
local channel = require("channel")
local registry = require("registry")
local uuid = require("uuid")
local migration_api = require("migration_api")
local repository = require("repository")

local function execute(db, statement, params)
    local result, err = db:execute(statement, params)
    if err then error(err) end
    return result
end

local function query(db, statement, params)
    local rows, err = db:query(statement, params)
    if err then error(err) end
    return rows
end

local function with_database(database_id, fn)
    local db = assert(sql.get(database_id))
    local ok, failure = pcall(function()
        assert(repository.init_tracking_table(db))
        execute(db, "DELETE FROM _migrations WHERE id IN ('app:batch', 'app:old_batch')")
        execute(db, "DROP TABLE IF EXISTS batch_rows")
        execute(db, "CREATE TABLE batch_rows (id INTEGER PRIMARY KEY, visits INTEGER NOT NULL DEFAULT 0)")
        execute(db, [[WITH RECURSIVE ids(id) AS (SELECT 1 UNION ALL SELECT id + 1 FROM ids WHERE id < 1000)
            INSERT INTO batch_rows (id) SELECT id FROM ids]])
        fn(db, db:type())
    end)
    execute(db, "DROP TABLE IF EXISTS batch_rows")
    execute(db, "DELETE FROM _migrations WHERE id IN ('app:batch', 'app:old_batch')")
    execute(db, "DROP TABLE IF EXISTS _migration_progress")
    db:release()
    if not ok then error(failure, 0) end
end

local function definition(dialect, page, after_hook)
    return function()
        migration("Update rows in bounded pages", function()
            database(dialect, function()
                up(page, "batch")
                if after_hook then after(after_hook) end
                down(function(tx) execute(tx, "UPDATE batch_rows SET visits = 0") end)
            end)
        end)
    end
end

local function page(tx, cursor)
    local rows = query(tx, "SELECT id FROM batch_rows WHERE id > $1 ORDER BY id LIMIT 201", {tonumber(cursor) or 0})
    if #rows == 0 then return nil end
    local last = rows[math.min(#rows, 200)].id
    execute(tx, "UPDATE batch_rows SET visits = visits + 1 WHERE id > $1 AND id <= $2", {tonumber(cursor) or 0, last})
    if #rows <= 200 then return nil end
    return tostring(last)
end

local function define_tests()
    local databases = {"app:concurrent_sqlite_a"}
    if env.get("app:enable_postgres") == "true" then databases[#databases + 1] = "app:concurrent_pg_a" end
    for _, database_id in ipairs(databases) do
        describe("Batched migrations on " .. database_id, function()
            it("resumes committed pages after interruption and skips an applied rerun", function()
                with_database(database_id, function(db, dialect)
                    local fail = true
                    local seen = {}
                    local hooks = 0
                    local function make_definition()
                        return definition(dialect, function(tx, cursor)
                            seen[#seen + 1] = cursor or "start"
                            local next_cursor = page(tx, cursor)
                            if fail and cursor == "400" then error("interrupted page") end
                            return next_cursor
                        end, function() hooks = hooks + 1 end)
                    end
                    local first = migration_api.run(make_definition(), {database_id = database_id, id = "app:batch"})
                    test.eq(first.status, "error")
                    test.contains(first.error, "interrupted page")
                    test.eq(query(db, "SELECT COUNT(*) AS count FROM batch_rows WHERE visits = 1")[1].count, 400)
                    test.is_false(repository.is_applied(db, "app:batch"))
                    test.eq(query(db, "SELECT cursor FROM _migration_progress WHERE id = 'app:batch'")[1].cursor, "400")
                    test.eq(hooks, 0)
                    fail = false
                    seen = {}
                    local resumed = migration_api.run(make_definition(), {database_id = database_id, id = "app:batch"})
                    test.eq(resumed.status, "complete", tostring(resumed.error))
                    test.eq(seen[1], "400")
                    test.eq(hooks, 1)
                    test.eq(query(db, "SELECT COUNT(*) AS count FROM batch_rows WHERE visits = 1")[1].count, 1000)
                    test.is_true(repository.is_applied(db, "app:batch"))
                    test.eq(#query(db, "SELECT id FROM _migration_progress"), 0)
                    local rerun = migration_api.run(make_definition(), {database_id = database_id, id = "app:batch"})
                    test.eq(rerun.skipped, 1)
                    test.eq(hooks, 1)
                    test.eq(#seen, 3)
                end)
            end)

            it("releases the writer lock between every bounded page", function()
                with_database(database_id, function(db, dialect)
                    local observer_id = dialect == sql.type.POSTGRES and "app:concurrent_pg_b" or "app:concurrent_sqlite_b"
                    local observer = assert(sql.get(observer_id))
                    local commits = 0
                    local max_ms = 0
                    local adapter = {
                        type = function() return db:type() end,
                        query = function(_, statement, params) return db:query(statement, params) end,
                        execute = function(_, statement, params) return db:execute(statement, params) end,
                        begin = function(_, options)
                            local tx, err = db:begin(options)
                            if not tx then return nil, err end
                            local started = time.now()
                            return {
                                query = function(_, statement, params) return tx:query(statement, params) end,
                                execute = function(_, statement, params) return tx:execute(statement, params) end,
                                rollback = function() return tx:rollback() end,
                                commit = function()
                                    local ok, commit_err = tx:commit()
                                    if not ok then return nil, commit_err end
                                    max_ms = math.max(max_ms, time.now():sub(started):milliseconds())
                                    commits = commits + 1
                                    local visible = query(observer, "SELECT COUNT(*) AS count FROM batch_rows WHERE visits = 1")[1].count
                                    test.eq(visible, math.min(commits * 200, 1000))
                                    execute(observer, "UPDATE batch_rows SET visits = visits WHERE id = 1")
                                    test.eq(repository.is_applied(observer, "app:batch"), commits == 5)
                                    return ok
                                end,
                            }
                        end,
                    }
                    local ok, result = pcall(migration_api.run, definition(dialect, page), {db = adapter, id = "app:batch"})
                    observer:release()
                    if not ok then error(result) end
                    test.eq(result.status, "complete", tostring(result.error))
                    test.eq(commits, 5)
                    test.ok(max_ms < 2000, "each 200-row transaction holds locks for less than two seconds")
                end)
            end)

            it("rolls back a final page when its after hook fails", function()
                with_database(database_id, function(db, dialect)
                    local failed = migration_api.run(definition(dialect, page, function() error("hook interruption") end), {db = db, id = "app:batch"})
                    test.eq(failed.status, "error")
                    test.contains(failed.error, "hook interruption")
                    test.is_false(repository.is_applied(db, "app:batch"))
                    test.eq(query(db, "SELECT COUNT(*) AS count FROM batch_rows WHERE visits = 1")[1].count, 800)
                    local resumed = migration_api.run(definition(dialect, page), {db = db, id = "app:batch"})
                    test.eq(resumed.status, "complete", tostring(resumed.error))
                    test.eq(query(db, "SELECT COUNT(*) AS count FROM batch_rows WHERE visits = 1")[1].count, 1000)
                end)
            end)

            it("rejects a non-advancing checkpoint without committing the page", function()
                with_database(database_id, function(db, dialect)
                    local result = migration_api.run(definition(dialect, function(tx, cursor)
                        page(tx, cursor)
                        return cursor or "200"
                    end), {db = db, id = "app:batch"})
                    test.eq(result.status, "error")
                    test.contains(result.error, "checkpoint")
                    test.eq(query(db, "SELECT COUNT(*) AS count FROM batch_rows WHERE visits = 1")[1].count, 200)
                    test.is_false(repository.is_applied(db, "app:batch"))
                end)
            end)

            it("resumes progress stored under an alias", function()
                with_database(database_id, function(db, dialect)
                    local failed = migration_api.run(definition(dialect, function(tx, cursor)
                        if cursor == "200" then error("alias interruption") end
                        return page(tx, cursor)
                    end), {db = db, id = "app:old_batch"})
                    test.eq(failed.status, "error")
                    local seen = nil
                    local resumed = migration_api.run(definition(dialect, function(tx, cursor)
                        if not seen then seen = cursor end
                        return page(tx, cursor)
                    end), {db = db, id = "app:batch", aliases = {"app:old_batch"}})
                    test.eq(resumed.status, "complete", tostring(resumed.error))
                    test.eq(seen, "200")
                    test.eq(#query(db, "SELECT id FROM _migration_progress"), 0)
                    test.eq(query(db, "SELECT COUNT(*) AS count FROM batch_rows WHERE visits = 1")[1].count, 1000)
                    local reverted = migration_api.run(definition(dialect, page), {db = db, id = "app:batch", direction = "down"})
                    test.eq(reverted.status, "complete", tostring(reverted.error))
                    test.is_false(repository.is_applied(db, "app:batch"))
                    test.eq(query(db, "SELECT COUNT(*) AS count FROM batch_rows WHERE visits = 0")[1].count, 1000)
                end)
            end)

            it("serializes competing runners at each checkpoint", function()
                with_database(database_id, function(db, dialect)
                    local competing_id = dialect == sql.type.POSTGRES and "app:concurrent_pg_b" or "app:concurrent_sqlite_b"
                    local start = channel.new(2)
                    local done = channel.new(2)
                    for _, id in ipairs({database_id, competing_id}) do
                        coroutine.spawn(function()
                            start:receive()
                            local ok, result = pcall(migration_api.run, definition(dialect, function(tx, cursor)
                                local next_cursor = page(tx, cursor)
                                time.sleep("5ms")
                                return next_cursor
                            end), {database_id = id, id = "app:batch"})
                            done:send({ok = ok, result = result})
                        end)
                    end
                    start:send(true)
                    start:send(true)
                    local first = done:receive()
                    local second = done:receive()
                    test.is_true(first.ok, tostring(first.result))
                    test.is_true(second.ok, tostring(second.result))
                    test.eq(first.result.status, "complete", tostring(first.result.error))
                    test.eq(second.result.status, "complete", tostring(second.result.error))
                    test.eq(first.result.applied + second.result.applied, 1)
                    test.eq(first.result.skipped + second.result.skipped, 1)
                    test.eq(query(db, "SELECT COUNT(*) AS count FROM batch_rows WHERE visits = 1")[1].count, 1000)
                end)
            end)

            it("does not advance progress when checkpoint persistence fails", function()
                with_database(database_id, function(db, dialect)
                    local failed = migration_api.run(definition(dialect, function(tx, cursor)
                        local next_cursor = page(tx, cursor)
                        if cursor == "200" then execute(tx, "DROP TABLE _migration_progress") end
                        return next_cursor
                    end), {db = db, id = "app:batch"})
                    test.eq(failed.status, "error")
                    test.eq(query(db, "SELECT cursor FROM _migration_progress WHERE id = 'app:batch'")[1].cursor, "200")
                    test.eq(query(db, "SELECT COUNT(*) AS count FROM batch_rows WHERE visits = 1")[1].count, 200)
                    test.is_false(repository.is_applied(db, "app:batch"))
                    local resumed = migration_api.run(definition(dialect, page), {db = db, id = "app:batch"})
                    test.eq(resumed.status, "complete", tostring(resumed.error))
                    test.eq(query(db, "SELECT COUNT(*) AS count FROM batch_rows WHERE visits = 1")[1].count, 1000)
                end)
            end)

            it("keeps 100000-row repairs bounded to 200 rows per transaction", function()
                with_database(database_id, function(db, dialect)
                    execute(db, "DELETE FROM batch_rows")
                    execute(db, [[WITH RECURSIVE ids(id) AS (SELECT 1 UNION ALL SELECT id + 1 FROM ids WHERE id < 100000)
                        INSERT INTO batch_rows (id) SELECT id FROM ids]])
                    local pages = 0
                    local result = migration_api.run(definition(dialect, function(tx, cursor)
                        local before = tonumber(cursor) or 0
                        local next_cursor = page(tx, cursor)
                        local after_id = tonumber(next_cursor) or 100000
                        test.ok(after_id - before <= 200)
                        pages = pages + 1
                        return next_cursor
                    end), {db = db, id = "app:batch"})
                    test.eq(result.status, "complete", tostring(result.error))
                    test.eq(pages, 500)
                    test.eq(query(db, "SELECT COUNT(*) AS count FROM batch_rows WHERE visits = 1")[1].count, 100000)
                end)
            end)

            it("rejects invalid IDs before committing any page", function()
                with_database(database_id, function(db, dialect)
                    for _, id in ipairs({"", string.rep("x", 513)}) do
                        local result = migration_api.run(definition(dialect, page), {db = db, id = id})
                        test.eq(result.status, "error")
                        test.contains(result.error, "ID")
                    end
                    test.eq(query(db, "SELECT COUNT(*) AS count FROM batch_rows WHERE visits <> 0")[1].count, 0)
                end)
            end)

            it("refuses forced replay of an applied batch before writing rows", function()
                with_database(database_id, function(db, dialect)
                    local first = migration_api.run(definition(dialect, page), {db = db, id = "app:batch"})
                    test.eq(first.status, "complete", tostring(first.error))
                    local forced = migration_api.run(definition(dialect, page), {db = db, id = "app:batch", force = true})
                    test.eq(forced.failed, 1)
                    test.contains(forced.migrations[1].error, "Cannot force")
                    test.eq(query(db, "SELECT COUNT(*) AS count FROM batch_rows WHERE visits = 1")[1].count, 1000)
                end)
            end)

            if database_id == "app:concurrent_pg_a" then
                it("keeps checkpoints with the active ledger across search paths", function()
                    with_database(database_id, function(db, dialect)
                        local suffix = assert(uuid.v4()):gsub("-", "")
                        local schema = "batch_fixture_" .. suffix
                        local scoped_id = "app:batch_fixture_" .. suffix
                        execute(db, 'CREATE SCHEMA "' .. schema .. '"')
                        local entry = assert(registry.get(database_id))
                        entry.id = scoped_id
                        entry.data.options = entry.data.options or {}
                        entry.data.options.search_path = schema .. ",public"
                        local changes = assert(registry.snapshot()):changes()
                        changes:create(entry)
                        assert(changes:apply())
                        local ok, failure = pcall(function()
                            local failed = migration_api.run(definition(dialect, function(tx, cursor)
                                if cursor == "200" then error("schema interruption") end
                                return page(tx, cursor)
                            end), {database_id = scoped_id, id = "app:batch"})
                            test.eq(failed.status, "error")
                            test.contains(failed.error, "schema interruption")
                            test.eq(query(db, "SELECT cursor FROM _migration_progress WHERE id = 'app:batch'")[1].cursor, "200")
                            local seen = nil
                            local resumed = migration_api.run(definition(dialect, function(tx, cursor)
                                if not seen then seen = cursor end
                                return page(tx, cursor)
                            end), {db = db, id = "app:batch"})
                            test.eq(resumed.status, "complete", tostring(resumed.error))
                            test.eq(seen, "200")
                            test.eq(query(db, "SELECT COUNT(*) AS count FROM batch_rows WHERE visits = 1")[1].count, 1000)
                        end)
                        local cleanup = assert(registry.snapshot()):changes()
                        cleanup:delete(scoped_id)
                        assert(cleanup:apply())
                        execute(db, 'DROP SCHEMA "' .. schema .. '" CASCADE')
                        if not ok then error(failure, 0) end
                    end)
                end)
            end

            it("keeps ordinary migrations atomic", function()
                with_database(database_id, function(db, dialect)
                    local result = migration_api.run(function()
                        migration("Atomic update", function()
                            database(dialect, function()
                                up(function(tx)
                                    page(tx)
                                    error("atomic interruption")
                                end)
                            end)
                        end)
                    end, {db = db, id = "app:batch"})
                    test.eq(result.status, "error")
                    test.eq(query(db, "SELECT COUNT(*) AS count FROM batch_rows WHERE visits <> 0")[1].count, 0)
                    test.is_false(repository.is_applied(db, "app:batch"))
                end)
            end)
        end)
    end
end

return {run = test.run_cases(define_tests)}
