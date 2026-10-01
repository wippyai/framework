local test = require("test")
local sql = require("sql")
local runner = require("runner")
local repository = require("repository")
local migration_registry = require("migration_registry")

local function define_tests()
    test.describe("rollback", function()
        local original_registry = migration_registry._registry

        test.before_each(function()
            local db, err = sql.get("app:db")
            test.is_nil(err)
            if not db then
                test.fail("database is available")
                return
            end
            local _, init_err = repository.init_tracking_table(db)
            test.is_nil(init_err)
            db:execute("DELETE FROM _migrations")
            for _, name in ipairs({ "alpha", "beta", "legacy", "newest" }) do
                local _, insert_err = db:execute(
                    "INSERT INTO _migrations (id, applied_at, description) VALUES ($1, $2, $3)",
                    { "app:rollback_" .. name,
                        name == "newest" and "2026-09-30 12:00:00" or 100,
                        "revert " .. name })
                test.is_nil(insert_err)
            end
            db:release()
            migration_registry._registry = {
                get = function(id: string)
                    if id == "app:rollback_legacy" then return nil end
                    return { id = id, kind = "function.lua", meta = { timestamp = "2024-01-01" } }
                end,
            }
        end)

        test.after_each(function()
            migration_registry._registry = original_registry
            local db = sql.get("app:db")
            if not db then
                test.fail("database is available for cleanup")
                return
            end
            db:execute("DELETE FROM _migrations")
            db:release()
        end)

        test.it("orders mixed SQL timestamps and registry ties in reverse", function()
            local result = runner.setup("app:db"):rollback({ count = 4 })
            test.eq(result.status, "complete")
            test.eq(result.migrations_reverted, 4)
            local expected = { "newest", "beta", "alpha", "legacy" }
            for i, name in ipairs(expected) do
                test.eq(result.migrations[i].id, "app:rollback_" .. name)
                test.eq(result.migrations[i].description, "revert " .. name)
            end
        end)

        test.it("filters allowed ids before applying the rollback count", function()
            local result = runner.setup("app:db"):rollback({
                allowed_ids = { "app:rollback_alpha", "app:rollback_beta" },
                count = 1,
            })
            test.eq(result.status, "complete")
            test.eq(result.migrations_found, 1)
            test.eq(result.migrations_reverted, 1)
            test.eq(result.migrations[1].id, "app:rollback_beta")
        end)
    end)
end

local run_cases = test.run_cases(define_tests)

return { run = run_cases }
