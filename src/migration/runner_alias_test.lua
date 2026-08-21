local test = require("test")
local sql = require("sql")
local funcs = require("funcs")
local runner = require("runner")
local repository = require("repository")

local DB_ID = "app:db"
local MIG_ONE = "app:alias_mig_one"
local MIG_TWO = "app:alias_mig_two"
local OLD_ONE = "app.legacy:alias_mig_one"
local OLD_TWO_B = "app.legacy:alias_mig_two_b"

local function with_db(fn: (any) -> any): any
    local conn, err = sql.get(DB_ID)
    test.is_nil(err)
    local db: any = test.not_nil(conn)

    local ok, result = pcall(fn, db)
    db:release()
    if not ok then
        error(result, 0)
    end
    return result
end

local function reset()
    with_db(function(db)
        local _, init_err = repository.init_tracking_table(db)
        test.is_nil(init_err)
        db:execute("DELETE FROM _migrations")
        db:execute("DROP TABLE IF EXISTS alias_one")
        db:execute("DROP TABLE IF EXISTS alias_two")
    end)
end

local function seed(id: string)
    with_db(function(db)
        local _, err = repository.record_migration(db, id, "seeded by runner_alias_test")
        test.is_nil(err)
    end)
end

local function ledger_ids(): any
    return with_db(function(db)
        local rows, err = repository.get_migrations(db)
        test.is_nil(err)

        local ids = {}
        for _, row in ipairs(rows or {}) do
            ids[row.id] = true
        end
        return ids
    end)
end

local function find_status_row(report: any, id: string): any
    for _, m in ipairs(report.migrations) do
        if m.id == id then
            return m
        end
    end
    return nil
end

local function define_tests()
    test.describe("runner with aliases", function()
        test.before_each(reset)

        test.it("applies fixture migrations on an empty ledger", function()
            local result = runner.setup(DB_ID):run()
            test.eq(result.status, "complete")
            test.eq(result.migrations_applied, 2)
            test.eq(result.migrations_failed, 0)

            local ids = ledger_ids()
            test.is_true(ids[MIG_ONE])
            test.is_true(ids[MIG_TWO])
        end)

        test.it("skips migrations recorded under an old id", function()
            seed(OLD_ONE)
            seed(OLD_TWO_B)

            local result = runner.setup(DB_ID):run()
            test.eq(result.status, "complete")
            test.eq(result.migrations_applied, 0)
            test.eq(result.migrations_skipped, 2)
            for _, m in ipairs(result.migrations) do
                test.eq(m.status, "skipped")
                test.eq(m.skip_type, "already_applied")
            end

            -- Ledger is untouched: old rows stay, nothing recorded under new ids
            local ids = ledger_ids()
            test.is_true(ids[OLD_ONE])
            test.is_true(ids[OLD_TWO_B])
            test.is_nil(ids[MIG_ONE])
            test.is_nil(ids[MIG_TWO])
        end)

        test.it("status reports applied_id for alias-matched rows", function()
            seed(OLD_ONE)

            local report = runner.setup(DB_ID):status()
            local one = find_status_row(report, MIG_ONE)
            test.not_nil(one)
            test.eq(one.status, "applied")
            test.eq(one.applied_id, OLD_ONE)

            local two = find_status_row(report, MIG_TWO)
            test.not_nil(two)
            test.eq(two.status, "pending")
        end)

        test.it("status reports applied_id equal to id after a normal apply", function()
            runner.setup(DB_ID):run()

            local report = runner.setup(DB_ID):status()
            local one = find_status_row(report, MIG_ONE)
            test.eq(one.status, "applied")
            test.eq(one.applied_id, MIG_ONE)
        end)

        test.it("prefers the migration's own ledger row over alias rows", function()
            seed(MIG_ONE)
            seed(OLD_ONE)

            local report = runner.setup(DB_ID):status()
            local one = find_status_row(report, MIG_ONE)
            test.eq(one.status, "applied")
            test.eq(one.applied_id, MIG_ONE)
        end)

        test.it("rolls back rows recorded under an old id", function()
            seed(OLD_ONE)
            seed(OLD_TWO_B)

            -- Resolution must call the current entries: a funcs call on the
            -- old ids would fail because those entries no longer exist.
            local result = runner.setup(DB_ID):rollback({ count = 2 })
            test.eq(result.status, "complete")
            test.eq(result.migrations_reverted, 2)
            test.eq(result.migrations_failed, 0)

            test.is_nil(next(ledger_ids()))
        end)

        test.it("rollback allowed_ids accepts the current id for an old row", function()
            seed(OLD_ONE)

            local result = runner.setup(DB_ID):rollback({ allowed_ids = { MIG_ONE } })
            test.eq(result.status, "complete")
            test.eq(result.migrations_reverted, 1)

            test.is_nil(next(ledger_ids()))
        end)

        test.it("run_next allowed_ids accepts an old id for a pending migration", function()
            local result = runner.setup(DB_ID):run_next({ allowed_ids = { OLD_ONE } })
            test.eq(result.status, "complete")
            test.eq(result.migrations_applied, 1)

            local ids = ledger_ids()
            test.is_true(ids[MIG_ONE])
            test.is_nil(ids[MIG_TWO])
        end)

        test.it("direct execution honors aliases in the applied check", function()
            seed(OLD_ONE)

            local executor = funcs.new()
            local result, err = executor:call(MIG_ONE, {
                database_id = DB_ID,
                direction = "up",
                id = MIG_ONE,
                aliases = { OLD_ONE },
            })
            test.is_nil(err)
            test.eq(result.migrations[1].status, "skipped")
            test.eq(result.migrations[1].reason, "Migration already applied")

            local ids = ledger_ids()
            test.is_true(ids[OLD_ONE])
            test.is_nil(ids[MIG_ONE])
        end)
    end)
end

local run_cases = test.run_cases(define_tests)

local function run(options: any): any
    return run_cases(options)
end

return { run = run }
