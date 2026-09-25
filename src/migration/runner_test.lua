local test = require("test")
local sql = require("sql")
local candidate = require("candidate")
local runner = require("runner")
local repository = require("repository")
local migration_registry = require("migration_registry")

local function entry(id: string, timestamp: string, statement: string)
    return {
        id = id,
        kind = "function.lua",
        meta = { type = "migration", target_db = "app:db", timestamp = timestamp },
        data = {
            source = [[return require("migration").define(function()
                migration("candidate fixture", function()
                    database("sqlite", function()
                        up(function(db)
                            local _, err = db:execute(]] .. string.format("%q", statement) .. [[)
                            if err then error(err) end
                        end)
                    end)
                    database("postgres", function()
                        up(function(db)
                            local _, err = db:execute(]] .. string.format("%q", statement) .. [[)
                            if err then error(err) end
                        end)
                    end)
                end)
            end)]],
            imports = { migration = "wippy.migration:migration" },
            method = "migrate",
        },
    }
end

local function run_candidate(entries)
    local closure = { { module = "test", migrations = entries, entries = entries } }
    local expected = {}
    for _, item in ipairs(entries) do
        expected[item.id] = candidate.entry_hash(item)
    end
    return candidate.candidate_migrations_up({
        candidate_closure = closure,
        target_db = "app:db",
        resolver = candidate.staged_resolver(closure),
        expected_hashes = expected,
        installer_lock_token = "candidate-test-lock",
    })
end

local function up(entries, overrides: any?)
    local closure = { { module = "test", migrations = entries, entries = entries } }
    local args = {
        candidate_closure = closure,
        target_db = "app:db",
        resolver = candidate.staged_resolver(closure),
        installer_lock_token = "candidate-test-lock",
    }
    if overrides ~= nil then
        for key, value in pairs(overrides) do args[key] = value end
    end
    return candidate.candidate_migrations_up(args)
end

local function define_tests()
    test.describe("staged candidate migrations", function()
        test.it("runs unpublished source in timestamp order and resumes without duplicate ledger rows", function()
            local db, err = sql.get("app:db")
            test.is_nil(err)
            db:execute("DROP TABLE IF EXISTS candidate_order")
            db:execute("DELETE FROM _migrations WHERE id LIKE 'candidate-test:%'")
            db:execute("CREATE TABLE candidate_order (id TEXT PRIMARY KEY)")
            local later = entry("candidate-test:later", "2026-02", "INSERT INTO candidate_order VALUES ('later')")
            local first = entry("candidate-test:first", "2026-01", "INSERT INTO candidate_order VALUES ('first')")
            local part, part_err = run_candidate({ first })
            test.is_nil(part_err)
            test.eq(part.applied[1].id, first.id)
            local result, run_err = run_candidate({ later, first })
            test.is_nil(run_err)
            test.eq(result.skipped[1].id, first.id)
            test.eq(result.applied[1].id, later.id)
            local rows = db:query("SELECT id FROM candidate_order ORDER BY id")
            test.eq(#rows, 2)
            local ledger = db:query("SELECT id, content_hash FROM _migrations WHERE id LIKE 'candidate-test:%' ORDER BY id")
            test.eq(#ledger, 2)
            test.eq(ledger[1].content_hash, candidate.entry_hash(first))
            local again, again_err = run_candidate({ later, first })
            test.is_nil(again_err)
            test.eq(#again.applied, 0)
            test.eq(#again.skipped, 2)
            db:release()
        end)

        test.it("refuses changed source under an applied id", function()
            local changed = entry("candidate-test:first", "2026-01", "INSERT INTO candidate_order VALUES ('changed')")
            local result, run_err = run_candidate({ changed })
            test.is_nil(result)
            test.eq(run_err:kind(), errors.CONFLICT)
            test.eq(run_err:details().code, "MIGRATION_HASH_MISMATCH")
        end)

        test.it("reports INVALID for malformed arguments", function()
            local result, run_err = candidate.candidate_migrations_up({
                target_db = "app:db",
            })
            test.is_nil(result)
            test.eq(run_err:kind(), errors.INVALID)
            test.eq(run_err:details().code, "CANDIDATE_INVALID")
        end)

        test.it("reports NOT_FOUND for staged ids outside expected_hashes", function()
            local unknown = entry("candidate-test:stray", "2026-03",
                "INSERT INTO candidate_order VALUES ('stray')")
            local result, run_err = up({ unknown }, { expected_hashes = {} })
            test.is_nil(result)
            test.eq(run_err:kind(), errors.NOT_FOUND)
            test.eq(run_err:details().code, "CANDIDATE_UNKNOWN")
        end)

        test.it("reports CONFLICT when staged bytes differ from the expected hash", function()
            local item = entry("candidate-test:drift", "2026-04",
                "INSERT INTO candidate_order VALUES ('drift')")
            local result, run_err = up({ item }, {
                expected_hashes = { ["candidate-test:drift"] = string.rep("0", 64) },
            })
            test.is_nil(result)
            test.eq(run_err:kind(), errors.CONFLICT)
            test.eq(run_err:details().code, "CANDIDATE_HASH_MISMATCH")
        end)

        test.it("reports UNAVAILABLE when staged discovery fails", function()
            local broken_resolver = {
                find = function(_self: any, _options: any?): (nil, any)
                    return nil, "resolver exploded"
                end,
            }
            local result, run_err = up({}, { resolver = broken_resolver })
            test.is_nil(result)
            test.eq(run_err:kind(), errors.UNAVAILABLE)
            test.eq(run_err:details().code, "CANDIDATE_UNAVAILABLE")
        end)

        test.it("reports UNAVAILABLE for an unknown target database", function()
            local item = entry("candidate-test:lost", "2026-05",
                "INSERT INTO candidate_order VALUES ('lost')")
            local closure = { { module = "test", migrations = { item } } }
            local result, run_err = candidate.candidate_migrations_up({
                candidate_closure = closure,
                target_db = "app:no-such-db",
                resolver = candidate.staged_resolver(closure),
                installer_lock_token = "candidate-test-lock",
            })
            test.is_nil(result)
            test.eq(run_err:kind(), errors.UNAVAILABLE)
            test.eq(run_err:details().code, "CANDIDATE_TARGET_UNAVAILABLE")
        end)

        test.it("reports INTERNAL when a staged migration fails", function()
            local broken = entry("candidate-test:broken-sql", "2026-06",
                "INSERT INTO candidate_missing_table_xyz VALUES ('boom')")
            local result, run_err = up({ broken })
            test.is_nil(result)
            test.eq(run_err:kind(), errors.INTERNAL)
            test.eq(run_err:details().code, "CANDIDATE_MIGRATION_FAILED")
        end)
    end)

    test.describe("registry tag filter", function()
        test.it("finds registry migrations by tag", function()
            local found, err = migration_registry.find({ target_db = "app:db", tags = { "ledger-hash" } })
            test.is_nil(err)
            test.eq(#found, 1)
            test.eq(found[1].id, "app:ledger_hash_fixture")
        end)
    end)

    test.describe("registry single-step apply", function()
        test.it("records the content hash when run_next applies a registry migration", function()
            local db, err = sql.get("app:db")
            test.is_nil(err)
            db:execute("DROP TABLE IF EXISTS ledger_hash_fixture")
            db:execute("DELETE FROM _migrations WHERE id = 'app:ledger_hash_fixture'")
            db:release()

            local fixture_runner = runner.setup("app:db")
            local found, find_err = fixture_runner:find_migrations()
            test.is_nil(find_err)
            local expected_hash = nil
            for _, migration in ipairs(found or {}) do
                if migration.id == "app:ledger_hash_fixture" then expected_hash = migration.content_hash end
            end
            test.not_nil(expected_hash)

            local result = fixture_runner:run_next({ allowed_ids = { "app:ledger_hash_fixture" } })
            test.eq(result.status, "complete")
            test.eq(result.migrations_applied, 1)

            local verify_db, verify_err = sql.get("app:db")
            test.is_nil(verify_err)
            local record, record_err = repository.get_migration(verify_db, "app:ledger_hash_fixture")
            verify_db:release()
            test.is_nil(record_err)
            test.not_nil(record)
            test.eq(record.content_hash, expected_hash)
        end)
    end)
end

local run_cases = test.run_cases(define_tests)

local function run(options: any): any
    return run_cases(options)
end

return { run = run }
