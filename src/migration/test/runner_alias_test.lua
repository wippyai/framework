local test = require("test")
local sql = require("sql")
local funcs = require("funcs")
local runner = require("runner")
local repository = require("repository")
local migration_registry = require("migration_registry")
local migration_api = require("migration_api")
local env = require("env")

local function define_database_tests(DB_ID: string)
    local native_registry = migration_registry._registry
    local MIG_ONE = "app:alias_mig_one"
    local MIG_TWO = "app:alias_mig_two"
    local OLD_ONE = "app.legacy:alias_mig_one"
    local OLD_TWO_A = "app.legacy:alias_mig_two_a"
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

    local function with_mock_registry(entries: {any}, fn: () -> ())
        local original = migration_registry._registry
        migration_registry._registry = {
            find = function(criteria)
                local results = {}
                for _, entry in ipairs(entries) do
                    local tags_match = true
                    for _, wanted in ipairs(criteria["meta.tags"] or {}) do
                        local found = false
                        for _, tag in ipairs(entry.meta.tags or {}) do
                            if tag == wanted then found = true end
                        end
                        if not found then tags_match = false end
                    end
                    if entry.meta.target_db == criteria["meta.target_db"] and tags_match then
                        table.insert(results, entry)
                    end
                end
                return results
            end,
            get = function(id)
                for _, entry in ipairs(entries) do
                    if entry.id == id then
                        return entry
                    end
                end
                return nil
            end,
        }

        local ok, err = pcall(fn)
        migration_registry._registry = original
        if not ok then
            error(err, 0)
        end
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
        test.describe("runner with aliases on " .. DB_ID, function()
            test.before_each(function()
                reset()
                if DB_ID ~= "app:db" then
                    -- Reuse the registered fixture functions with a second SQL
                    -- backend, without requiring PostgreSQL during ordinary boot.
                    migration_registry._registry = {
                        get = native_registry.get,
                        find = function(criteria)
                            local mapped = {}
                            for key, value in pairs(criteria) do mapped[key] = value end
                            if mapped["meta.target_db"] == DB_ID then mapped["meta.target_db"] = "app:db" end
                            return native_registry.find(mapped)
                        end,
                    }
                end
            end)
            test.after_each(function()
                migration_registry._registry = native_registry
                reset()
            end)

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

            test.it("rollback runs down once when both old and current rows exist", function()
                seed(MIG_ONE)
                seed(OLD_ONE)

                local result = runner.setup(DB_ID):rollback({ count = 2 })
                test.eq(result.status, "complete")
                test.eq(result.migrations_found, 1)
                test.eq(result.migrations_reverted, 1)
                test.eq(result.migrations_failed, 0)
                test.eq(result.migrations[1].id, MIG_ONE)

                test.is_nil(next(ledger_ids()))

                local report = runner.setup(DB_ID):status()
                test.eq(find_status_row(report, MIG_ONE).status, "pending")
            end)

            test.it("rollback allowed_ids accepts the current id for an old row", function()
                seed(OLD_ONE)

                local result = runner.setup(DB_ID):rollback({ allowed_ids = { MIG_ONE } })
                test.eq(result.status, "complete")
                test.eq(result.migrations_reverted, 1)

                test.is_nil(next(ledger_ids()))
            end)

            test.it("rollback allowed_ids accepts an old id for a row applied under the current id", function()
                seed(MIG_ONE)

                local result = runner.setup(DB_ID):rollback({ allowed_ids = { OLD_ONE } })
                test.eq(result.status, "complete")
                test.eq(result.migrations_reverted, 1)

                test.is_nil(next(ledger_ids()))
            end)

            test.it("rollback allowed_ids accepts a sibling old id of the recorded row", function()
                seed(OLD_TWO_A)

                local result = runner.setup(DB_ID):rollback({ allowed_ids = { OLD_TWO_B } })
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

            test.it("run surfaces an invalid alias configuration as an error", function()
                with_mock_registry({
                    {
                        id = "app.mock:one",
                        kind = "function.lua",
                        meta = { type = "migration", target_db = DB_ID, alias = "app.legacy:shared" },
                    },
                    {
                        id = "app.mock:two",
                        kind = "function.lua",
                        meta = { type = "migration", target_db = DB_ID, alias = "app.legacy:shared" },
                    },
                }, function()
                    local result = runner.setup(DB_ID):run()
                    test.eq(result.status, "error")
                    test.contains(tostring(result.error), "Invalid migration aliases")
                    test.contains(tostring(result.error), "app.legacy:shared")
                end)
            end)

            test.it("run_next surfaces invalid aliases as an error", function()
                with_mock_registry({
                    { id = MIG_ONE, kind = "function.lua", meta = {
                        type = "migration", target_db = DB_ID, alias = "app.legacy:shared" } },
                    { id = MIG_TWO, kind = "function.lua", meta = {
                        type = "migration", target_db = DB_ID, alias = "app.legacy:shared" } },
                }, function()
                    local result = runner.setup(DB_ID):run_next()
                    test.eq(result.status, "error", "alias collision must not report successful completion")
                end)
            end)

            test.it("tags cannot hide an alias collision with another migration id", function()
                seed(MIG_TWO)
                with_mock_registry({
                    { id = MIG_ONE, kind = "function.lua", meta = {
                        type = "migration", target_db = DB_ID, tags = { "selected" }, alias = MIG_TWO } },
                    { id = MIG_TWO, kind = "function.lua", meta = {
                        type = "migration", target_db = DB_ID, tags = { "other" } } },
                }, function()
                    local result = runner.setup(DB_ID):run({ tags = { "selected" } })
                    test.eq(result.status, "error", "an unrelated ledger row must not silently skip a migration")
                end)
            end)

            test.it("tags cannot hide duplicate alias claims", function()
                with_mock_registry({
                    { id = MIG_ONE, kind = "function.lua", meta = {
                        type = "migration", target_db = DB_ID, tags = {"selected"}, alias = OLD_ONE } },
                    { id = MIG_TWO, kind = "function.lua", meta = {
                        type = "migration", target_db = DB_ID, tags = {"other"}, alias = OLD_ONE } },
                }, function()
                    local result = runner.setup(DB_ID):run({tags = {"selected"}})
                    test.eq(result.status, "error")
                    test.contains(result.error, "claimed by both")
                    test.is_nil(next(ledger_ids()))
                end)
            end)

            test.it("preserves tag selection when the aliases are valid", function()
                with_mock_registry({
                    { id = MIG_ONE, kind = "function.lua", meta = {
                        type = "migration", target_db = DB_ID, tags = {"selected"}, alias = OLD_ONE } },
                    { id = MIG_TWO, kind = "function.lua", meta = {
                        type = "migration", target_db = DB_ID, tags = {"other"}, alias = OLD_TWO_A } },
                }, function()
                    local result = runner.setup(DB_ID):run({tags = {"selected"}})
                    test.eq(result.status, "complete")
                    test.eq(result.migrations_applied, 1)
                    local ids = ledger_ids()
                    test.is_true(ids[MIG_ONE])
                    test.is_nil(ids[MIG_TWO])
                end)
            end)

            test.it("rolls back a failed alias lookup and leaves the database usable", function()
                with_db(function(db)
                    local active_tx: any = nil
                    local rolled_back = false
                    local alias_queries = 0
                    local body_ran = false
                    local adapter = {
                        type = function() return db:type() end,
                        query = function(_, query, params) return db:query(query, params) end,
                        execute = function(_, query, params) return db:execute(query, params) end,
                        begin = function(_, options)
                            local tx, err = db:begin(options)
                            if not tx then return nil, err end
                            active_tx = tx
                            return {
                                query = function(_, query, params)
                                    if params and params[1] == OLD_ONE then
                                        alias_queries = alias_queries + 1
                                        return nil, "injected alias lookup failure"
                                    end
                                    return tx:query(query, params)
                                end,
                                execute = function(_, query, params) return tx:execute(query, params) end,
                                rollback = function()
                                    rolled_back = true
                                    return tx:rollback()
                                end,
                                commit = function() return tx:commit() end,
                            }
                        end,
                    }
                    local dialect = db:type()
                    local ok, result = pcall(migration_api.run, function()
                        migration("Alias lookup rollback", function()
                            database(dialect, function()
                                up(function() body_ran = true end)
                            end)
                        end)
                    end, {db = adapter, id = MIG_ONE, aliases = {OLD_ONE}})
                    -- Clean up even if the regression returns without rolling back.
                    if active_tx and not rolled_back then active_tx:rollback() end
                    test.is_true(ok, tostring(result))
                    test.eq(alias_queries, 1, "alias lookup must use the locked transaction")
                    test.is_true(rolled_back, "failed alias lookup must release the transaction")
                    test.is_false(body_ran)
                    test.eq(result.status, "error")
                    test.contains(result.error, "injected alias lookup failure")
                end)
                local result = runner.setup(DB_ID):run()
                test.eq(result.status, "complete")
                test.eq(result.migrations_applied, 2)
            end)

            test.it("rollback surfaces a malformed alias as an error", function()
                seed(MIG_ONE)

                with_mock_registry({
                    {
                        id = "app.mock:one",
                        kind = "function.lua",
                        meta = { type = "migration", target_db = DB_ID, alias = "alias_without_namespace" },
                    },
                }, function()
                    local result = runner.setup(DB_ID):rollback({ count = 1 })
                    test.eq(result.status, "error")
                    test.contains(tostring(result.error), "Invalid migration aliases")
                    test.contains(tostring(result.error), "alias_without_namespace")
                end)
            end)
        end)
    end

    define_tests()
end

local function define_tests()
    define_database_tests("app:db")
    if env.get("app:enable_postgres") == "true" then
        define_database_tests("app:concurrent_pg_a")
    end
end

local run_cases = test.run_cases(define_tests)

local function run(options: any): any
    return run_cases(options)
end

return { run = run }
