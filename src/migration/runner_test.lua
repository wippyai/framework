local test = require("test")
local sql = require("sql")
local candidate = require("candidate")

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
            test.eq(run_err.code, "MIGRATION_HASH_MISMATCH")
        end)
    end)
end

local run_cases = test.run_cases(define_tests)

local function run(options: any): any
    return run_cases(options)
end

return { run = run }
