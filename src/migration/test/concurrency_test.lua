local test = require("test")
local runner_lib = require("runner_lib")
local sql = require("sql")
local channel = require("channel")
local env = require("env")

type MigrationResult = {
    status: string,
    error: string?,
}

type RunnerResult = {
    status: string,
    error: string?,
    migrations_applied: number,
    migrations_skipped: number,
    migrations_failed: number,
    migrations: {MigrationResult},
}

local function execute(db: any, query: string)
    local ok, err = db:execute(query)
    test.is_nil(err, tostring(err))
    test.ok(ok)
end

local function run_set(database_id: string)
    local runner = runner_lib.setup(database_id)
    -- Both runners deliberately discover the same stale pending plan. Execution
    -- must consult the ledger again under the DB lock, not trust discovery.
    runner.find_migrations = function()
        local pending = {}
        for i = 1, 3 do
            pending[i] = {id = "app:concurrency_" .. tostring(i), applied = false}
        end
        return pending
    end
    return runner:run()
end

local function concurrent_set(primary_id, competing_id, cold)
    local a, a_err = sql.get(primary_id)
    test.is_nil(a_err)
    local b, b_err = sql.get(competing_id)
    test.is_nil(b_err)
    -- Distinct resource pools point at the same database, including on SQLite.
    for i = 1, 3 do execute(a, "DROP TABLE IF EXISTS concurrency_probe_" .. tostring(i)) end
    execute(a, "DROP TABLE IF EXISTS _migrations")
    if not cold then
        execute(a, "CREATE TABLE _migrations (id VARCHAR(512) PRIMARY KEY, applied_at INTEGER DEFAULT 0, description TEXT)")
    end

    local start = channel.new(2)
    local done = channel.new(2)
    a:release()
    b:release()
    for _, database_id in ipairs({primary_id, competing_id}) do
        coroutine.spawn(function()
            start:receive()
            local ok, results = pcall(run_set, database_id)
            done:send({ok = ok, results = results})
        end)
    end
    start:send(true)
    start:send(true)
    local first: any = done:receive()
    local second: any = done:receive()
    test.is_true(first.ok, tostring(first.results))
    test.is_true(second.ok, tostring(second.results))
    local rfirst = first.results :: RunnerResult
    local rsecond = second.results :: RunnerResult
    test.eq(rfirst.status, "complete", tostring(rfirst.error))
    test.eq(rsecond.status, "complete", tostring(rsecond.error))
    test.eq(rfirst.migrations_applied + rsecond.migrations_applied, 3)
    test.eq(rfirst.migrations_skipped + rsecond.migrations_skipped, 3)
    test.eq(rfirst.migrations_failed + rsecond.migrations_failed, 0)
    for i = 1, 3 do
        local r1 = rfirst.migrations[i] :: MigrationResult
        local r2 = rsecond.migrations[i] :: MigrationResult
        test.ok((r1.status == "applied" and r2.status == "skipped")
            or (r1.status == "skipped" and r2.status == "applied"))
    end
    local db, err = sql.get(primary_id)
    test.is_nil(err)
    local records, query_err = db:query("SELECT id FROM _migrations ORDER BY id")
    test.is_nil(query_err)
    test.eq(#records, 3)
    for i = 1, 3 do
        test.eq(records[i].id, "app:concurrency_" .. tostring(i))
        local rows, row_err = db:query("SELECT value FROM concurrency_probe_" .. tostring(i) .. " ORDER BY value")
        test.is_nil(row_err)
        test.eq(#rows, 2)
        test.eq(rows[1].value, 1)
        test.eq(rows[2].value, 2)
        execute(db, "DROP TABLE concurrency_probe_" .. tostring(i))
    end
    execute(db, "DROP TABLE _migrations")
    db:release()
end

local function define_tests()
    describe("Concurrent migration runners", function()
        for _, cold in ipairs({false, true}) do
            local label = cold and "cold ledger" or "existing ledger"
            it("applies each SQLite migration once with " .. label, function()
                concurrent_set("app:concurrent_sqlite_a", "app:concurrent_sqlite_b", cold)
            end)
            if env.get("app:enable_postgres") == "true" then
                it("applies each PostgreSQL migration once with " .. label, function()
                    concurrent_set("app:concurrent_pg_a", "app:concurrent_pg_b", cold)
                end)
            end
        end
    end)
end

return test.run_cases(define_tests)
