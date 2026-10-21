local test = require("test")
local repository = require("repository")
local registry = require("registry")
local sql = require("sql")
local env = require("env")
local uuid = require("uuid")

local function execute(db: any, statement: string)
    local _, err = db:execute(statement)
    test.is_nil(err)
end

local function define_tests()
    test.describe("migration ledger schema", function()
        test.it("opens the active SQLite ledger", function()
            local db, err = sql.get("app:db")
            test.is_nil(err)
            local initialized, init_err = repository.init_tracking_table(db)
            test.is_nil(init_err)
            test.ok(initialized)
            local exists, exists_err = repository.table_exists(db)
            db:release()
            test.is_nil(exists_err)
            test.is_true(exists)
        end)

        if env.get("app:enable_postgres") == "true" then
            test.it("keeps a non-default schema ledger separate from the public ledger", function()
                local public, public_err = sql.get("app:concurrent_pg_a")
                test.is_nil(public_err)
                local _, init_err = repository.init_tracking_table(public)
                test.is_nil(init_err)
                local suffix, id_err = uuid.v4()
                test.is_nil(id_err)
                local schema = "ledger_fixture_" .. suffix:gsub("-", "")
                local fallback_schema = schema .. "_fallback"
                execute(public, 'CREATE SCHEMA "' .. schema .. '"')
                execute(public, 'CREATE SCHEMA "' .. fallback_schema .. '"')
                local database_ids = {}
                local isolated = nil
                local ok, failure = pcall(function()
                    for index, fixture in ipairs({
                        { path = schema, owner = schema, exists = false },
                        { path = fallback_schema .. ",public", owner = "public", exists = true },
                    }) do
                        local database_id = "app:ledger_" .. suffix:gsub("-", "") .. tostring(index)
                        local entry = assert(registry.get("app:concurrent_pg_a"))
                        entry.id = database_id
                        entry.data.options = entry.data.options or {}
                        entry.data.options.search_path = fixture.path
                        local changes = assert(registry.snapshot()):changes()
                        changes:create(entry)
                        local applied, apply_err = changes:apply()
                        test.is_nil(apply_err)
                        test.ok(applied)
                        database_ids[#database_ids + 1] = database_id
                        local db, db_err = sql.get(database_id)
                        test.is_nil(db_err)
                        isolated = db
                        local exists, exists_err = repository.table_exists(db)
                        test.is_nil(exists_err)
                        test.eq(exists, fixture.exists, "ledger detection follows the connection search path")
                        local initialized, initialize_err = repository.init_tracking_table(db)
                        test.is_nil(initialize_err)
                        test.ok(initialized)
                        local rows, query_err = db:query([[SELECT n.nspname AS name FROM pg_class c
                            JOIN pg_namespace n ON n.oid = c.relnamespace WHERE c.oid = to_regclass('_migrations')]])
                        test.is_nil(query_err)
                        test.eq(rows[1].name, fixture.owner)
                        local key = "schema-fixture:" .. suffix .. ":" .. tostring(index)
                        local _, record_err = repository.record_migration(db, key, "schema fixture")
                        test.is_nil(record_err)
                        local local_applied, local_err = repository.is_applied(db, key)
                        test.is_nil(local_err)
                        test.is_true(local_applied)
                        local public_applied, public_read_err = repository.is_applied(public, key)
                        test.is_nil(public_read_err)
                        test.eq(public_applied, fixture.owner == "public")
                        local reopened, reopen_err = repository.init_tracking_table(db)
                        test.is_nil(reopen_err)
                        test.ok(reopened)
                        local _, remove_err = repository.remove_migration(db, key)
                        test.is_nil(remove_err)
                        db:release()
                        isolated = nil
                    end
                end)
                if isolated then isolated:release() end
                local cleanup = assert(registry.snapshot()):changes()
                for _, database_id in ipairs(database_ids) do cleanup:delete(database_id) end
                local removed, remove_err = cleanup:apply()
                test.is_nil(remove_err)
                test.ok(removed)
                execute(public, 'DROP SCHEMA "' .. fallback_schema .. '" CASCADE')
                execute(public, 'DROP SCHEMA "' .. schema .. '" CASCADE')
                public:release()
                if not ok then error(failure, 0) end
            end)
        end
    end)
end

return { run = test.run_cases(define_tests) }
