local test = require("test")
local migration_registry = require("migration_registry")

local original_registry

local function mock_registry(entries)
    local store = {}
    for _, entry in ipairs(entries) do
        store[entry.id] = entry
    end

    return {
        find = function(criteria)
            local results = {}
            for _, entry in ipairs(entries) do
                local match = true
                if criteria["meta.target_db"] and entry.meta.target_db ~= criteria["meta.target_db"] then
                    match = false
                end
                if match then
                    table.insert(results, entry)
                end
            end
            return results
        end,
        get = function(id)
            return store[id]
        end,
    }
end

local function save_registry()
    original_registry = migration_registry._registry
end

local function restore_registry()
    migration_registry._registry = original_registry
end

local function define_tests()
    test.describe("find", function()
        test.before_each(save_registry)
        test.after_each(restore_registry)

        test.it("returns empty when no migrations", function()
            migration_registry._registry = mock_registry({})

            local results, err = migration_registry.find()
            test.is_nil(err)
            test.eq(#results, 0)
        end)

        test.it("sorts by timestamp", function()
            migration_registry._registry = mock_registry({
                { id = "m:second", kind = "function.lua", meta = { type = "migration", timestamp = "2024-02-01" } },
                { id = "m:first", kind = "function.lua", meta = { type = "migration", timestamp = "2024-01-01" } },
                { id = "m:third", kind = "function.lua", meta = { type = "migration", timestamp = "2024-03-01" } },
            })

            local results, err = migration_registry.find()
            test.is_nil(err)
            test.eq(#results, 3)
            test.eq(results[1].id, "m:first")
            test.eq(results[2].id, "m:second")
            test.eq(results[3].id, "m:third")
        end)

        test.it("sorts untimestamped migrations by id", function()
            migration_registry._registry = mock_registry({
                { id = "keeper.mcp.migrations:migration_06", kind = "function.lua", meta = { type = "migration" } },
                { id = "keeper.mcp.migrations:migration_01", kind = "function.lua", meta = { type = "migration" } },
                { id = "keeper.mcp.migrations:migration_02", kind = "function.lua", meta = { type = "migration" } },
            })

            local results, err = migration_registry.find()
            test.is_nil(err)
            test.eq(#results, 3)
            test.eq(results[1].id, "keeper.mcp.migrations:migration_01")
            test.eq(results[2].id, "keeper.mcp.migrations:migration_02")
            test.eq(results[3].id, "keeper.mcp.migrations:migration_06")
        end)

        test.it("uses id as a timestamp tie-breaker", function()
            migration_registry._registry = mock_registry({
                { id = "m:beta", kind = "function.lua", meta = { type = "migration", timestamp = "2024-01-01" } },
                { id = "m:alpha", kind = "function.lua", meta = { type = "migration", timestamp = "2024-01-01" } },
                { id = "m:later", kind = "function.lua", meta = { type = "migration", timestamp = "2024-02-01" } },
            })

            local results, err = migration_registry.find()
            test.is_nil(err)
            test.eq(#results, 3)
            test.eq(results[1].id, "m:alpha")
            test.eq(results[2].id, "m:beta")
            test.eq(results[3].id, "m:later")
        end)

        test.it("orders untimestamped migrations identically across shuffled inputs", function()
            -- gopher-lua's table.sort is not stable. Without the id tie-break,
            -- migration_NN entries without `meta.timestamp` arrived in a
            -- different order on each process restart because the comparator
            -- always returned false and the underlying Go sort.Slice picked
            -- whatever permutation the hash seed produced. This regression
            -- guard rebuilds the input in 100 distinct permutations and
            -- asserts the output is byte-identical.
            local canonical_ids = {
                "keeper.mcp.migrations:migration_01",
                "keeper.mcp.migrations:migration_02",
                "keeper.mcp.migrations:migration_03",
                "keeper.mcp.migrations:migration_04",
                "keeper.mcp.migrations:migration_05",
                "keeper.mcp.migrations:migration_06",
            }
            local expected_order = {}
            for i, id in ipairs(canonical_ids) do
                expected_order[i] = id
            end

            for seed = 1, 100 do
                math.randomseed(seed)
                local shuffled = {}
                for i, id in ipairs(canonical_ids) do
                    shuffled[i] = id
                end
                for i = #shuffled, 2, -1 do
                    local j = math.random(i)
                    shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
                end

                local entries = {}
                for _, id in ipairs(shuffled) do
                    table.insert(entries, {
                        id = id,
                        kind = "function.lua",
                        meta = { type = "migration" },
                    })
                end

                migration_registry._registry = mock_registry(entries)
                local results, err = migration_registry.find()
                test.is_nil(err)
                test.eq(#results, #expected_order)
                for i, want in ipairs(expected_order) do
                    test.eq(results[i].id, want)
                end
            end
        end)

        test.it("orders timestamp-tied migrations identically across shuffled inputs", function()
            -- Mixed scenario: some entries share a timestamp, others have
            -- unique timestamps, others have no timestamp. The sort must
            -- order primarily by timestamp ("" sorting first), with id as
            -- the deterministic secondary key. Shuffle the input across 100
            -- seeds; the output must never differ.
            local canonical = {
                { id = "m:no_ts_a",   meta = { type = "migration" } },
                { id = "m:no_ts_b",   meta = { type = "migration" } },
                { id = "m:tie_alpha", meta = { type = "migration", timestamp = "2024-02-01" } },
                { id = "m:tie_beta",  meta = { type = "migration", timestamp = "2024-02-01" } },
                { id = "m:tie_gamma", meta = { type = "migration", timestamp = "2024-02-01" } },
                { id = "m:single",    meta = { type = "migration", timestamp = "2024-03-15" } },
            }
            for _, entry in ipairs(canonical) do
                entry.kind = "function.lua"
            end

            local function deep_copy(t)
                local out = {}
                for k, v in pairs(t) do
                    if type(v) == "table" then
                        out[k] = deep_copy(v)
                    else
                        out[k] = v
                    end
                end
                return out
            end

            -- Build the expected order: no timestamp first (sorted by id),
            -- then unique-timestamp groups (sorted by id), then the lone
            -- later timestamp.
            local expected_ids = {
                "m:no_ts_a", "m:no_ts_b",
                "m:tie_alpha", "m:tie_beta", "m:tie_gamma",
                "m:single",
            }

            for seed = 1, 100 do
                math.randomseed(seed * 7919)
                local shuffled = {}
                for i, entry in ipairs(canonical) do
                    shuffled[i] = deep_copy(entry)
                end
                for i = #shuffled, 2, -1 do
                    local j = math.random(i)
                    shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
                end

                migration_registry._registry = mock_registry(shuffled)
                local results, err = migration_registry.find()
                test.is_nil(err)
                test.eq(#results, #expected_ids)
                for i, want in ipairs(expected_ids) do
                    test.eq(results[i].id, want)
                end
            end
        end)

        test.it("filters by target_db", function()
            migration_registry._registry = mock_registry({
                { id = "m:pg", kind = "function.lua", meta = { type = "migration", target_db = "app:db", timestamp = "2024-01-01" } },
                { id = "m:other", kind = "function.lua", meta = { type = "migration", target_db = "other:db", timestamp = "2024-02-01" } },
            })

            local results, err = migration_registry.find({ target_db = "app:db" })
            test.is_nil(err)
            test.eq(#results, 1)
            test.eq(results[1].id, "m:pg")
        end)
    end)

    test.describe("get", function()
        test.before_each(save_registry)
        test.after_each(restore_registry)

        test.it("returns entry by id", function()
            migration_registry._registry = mock_registry({
                { id = "m:target", kind = "function.lua", meta = { type = "migration" } },
            })

            local entry, err = migration_registry.get("m:target")
            test.is_nil(err)
            test.not_nil(entry)
            test.eq(entry.id, "m:target")
        end)
    end)

    test.describe("get_target_dbs", function()
        test.before_each(save_registry)
        test.after_each(restore_registry)

        test.it("returns unique target databases", function()
            migration_registry._registry = mock_registry({
                { id = "m:one", kind = "function.lua", meta = { type = "migration", target_db = "app:db" } },
                { id = "m:two", kind = "function.lua", meta = { type = "migration", target_db = "app:db" } },
                { id = "m:three", kind = "function.lua", meta = { type = "migration", target_db = "other:db" } },
            })

            local dbs, err = migration_registry.get_target_dbs()
            test.is_nil(err)
            test.eq(#dbs, 2)
            test.eq(dbs[1], "app:db")
            test.eq(dbs[2], "other:db")
        end)
    end)

    test.describe("get_tags", function()
        test.before_each(save_registry)
        test.after_each(restore_registry)

        test.it("returns unique tags", function()
            migration_registry._registry = mock_registry({
                { id = "m:one", kind = "function.lua", meta = { type = "migration", tags = { "core", "auth" } } },
                { id = "m:two", kind = "function.lua", meta = { type = "migration", tags = { "core", "data" } } },
            })

            local tags, err = migration_registry.get_tags()
            test.is_nil(err)
            test.eq(#tags, 3)
            test.eq(tags[1], "auth")
            test.eq(tags[2], "core")
            test.eq(tags[3], "data")
        end)
    end)
end

local run_cases = test.run_cases(define_tests)

local function run(options: any): any
    return run_cases(options)
end

return { run = run }
