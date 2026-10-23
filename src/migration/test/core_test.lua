local test = require("test")
local core = require("core")

local function define_tests()
    test.describe("define", function()
        test.it("returns implementations for single migration", function()
            local implementations = core.define(function()
                migration("create users table", function()
                    database("postgres", function()
                        up(function(db) end)
                        down(function(db) end)
                    end)
                end)
            end)

            test.eq(#implementations, 1)
            test.eq(implementations[1].description, "create users table")
        end)

        test.it("collects multiple migrations", function()
            local implementations = core.define(function()
                migration("first migration", function()
                    database("postgres", function()
                        up(function(db) end)
                        down(function(db) end)
                    end)
                end)

                migration("second migration", function()
                    database("postgres", function()
                        up(function(db) end)
                        down(function(db) end)
                    end)
                end)
            end)

            test.eq(#implementations, 2)
            test.eq(implementations[1].description, "first migration")
            test.eq(implementations[2].description, "second migration")
        end)

        test.it("captures database-specific up/down/after", function()
            local up_called = false
            local down_called = false
            local after_called = false

            local implementations = core.define(function()
                migration("test migration", function()
                    database("sqlite", function()
                        up(function(db) up_called = true end)
                        down(function(db) down_called = true end)
                        after(function(db) after_called = true end)
                    end)
                end)
            end)

            local impl = implementations[1].database_implementations["sqlite"]
            test.not_nil(impl)
            test.is_function(impl.up)
            test.is_function(impl.down)
            test.is_function(impl.after)

            impl.up(nil)
            test.is_true(up_called)

            impl.down(nil)
            test.is_true(down_called)

            impl.after(nil)
            test.is_true(after_called)
        end)
    end)

    test.describe("batched definitions", function()
        test.it("accepts an opt-in external batch implementation", function()
            local implementations = core.define(function()
                migration("external repair", function()
                    database("sqlite", function()
                        up(function(db, cursor) return nil end, "external_batch")
                        down(function() end)
                    end)
                end)
            end)
            test.is_function(implementations[1].database_implementations.sqlite.up_external_batch)
            test.is_true(core.validate_implementation(implementations[1], "sqlite"))
        end)
        for _, other in ipairs({"atomic", "batch"}) do
            for _, external_first in ipairs({false, true}) do
                test.it("rejects external batch mixed with " .. other .. "/" .. tostring(external_first), function()
                    local ok = pcall(core.define, function()
                        migration("mixed repair", function()
                            database("sqlite", function()
                                if external_first then up(function() end, "external_batch") end
                                if other == "atomic" then up(function() end) else up(function() end, "batch") end
                                if not external_first then up(function() end, "external_batch") end
                            end)
                        end)
                    end)
                    test.is_false(ok)
                end)
            end
        end

        test.it("accepts a batched implementation without adding a DSL global", function()
            local implementations = core.define(function()
                migration("paged update", function()
                    database("sqlite", function()
                        up(function(tx, cursor) return nil end, "batch")
                        down(function(tx) end)
                    end)
                end)
            end)
            test.is_function(implementations[1].database_implementations.sqlite.up_batch)
            local ok, err = core.validate_implementation(implementations[1], "sqlite")
            test.is_true(ok, tostring(err))
            test.is_nil(_G.up_batch)
        end)

        for _, batch_first in ipairs({false, true}) do
            test.it("rejects mixed atomic and batched callbacks in order " .. tostring(batch_first), function()
                local ok, err = pcall(core.define, function()
                    migration("ambiguous update", function()
                        database("sqlite", function()
                            if batch_first then up(function() end, "batch") end
                            up(function() end)
                            if not batch_first then up(function() end, "batch") end
                        end)
                    end)
                end)
                test.is_false(ok)
                test.contains(tostring(err), "cannot be combined")
                test.is_nil(_G.up_batch)
            end)
        end
    end)

    test.describe("validate_implementation", function()
        test.it("passes with up and down", function()
            local implementations = core.define(function()
                migration("valid migration", function()
                    database("postgres", function()
                        up(function(db) end)
                        down(function(db) end)
                    end)
                end)
            end)

            local ok, err = core.validate_implementation(implementations[1], "postgres")
            test.is_true(ok)
            test.is_nil(err)
        end)

        test.it("fails without up", function()
            local implementations = core.define(function()
                migration("no up", function()
                    database("postgres", function()
                        down(function(db) end)
                    end)
                end)
            end)

            local ok, err = core.validate_implementation(implementations[1], "postgres")
            test.is_false(ok)
            test.not_nil(err)
            test.contains(tostring(err), "up")
        end)

        test.it("fails without down", function()
            local implementations = core.define(function()
                migration("no down", function()
                    database("postgres", function()
                        up(function(db) end)
                    end)
                end)
            end)

            local ok, err = core.validate_implementation(implementations[1], "postgres")
            test.is_false(ok)
            test.not_nil(err)
            test.contains(tostring(err), "down")
        end)

        test.it("fails for missing db type", function()
            local implementations = core.define(function()
                migration("postgres only", function()
                    database("postgres", function()
                        up(function(db) end)
                        down(function(db) end)
                    end)
                end)
            end)

            local ok, err = core.validate_implementation(implementations[1], "mysql")
            test.is_false(ok)
            test.not_nil(err)
            test.contains(tostring(err), "mysql")
        end)
    end)

    test.describe("globals cleanup", function()
        test.it("removes DSL globals after define", function()
            core.define(function()
                migration("temp", function()
                    database("postgres", function()
                        up(function(db) end)
                        down(function(db) end)
                    end)
                end)
            end)

            test.is_nil(_G.migration)
            test.is_nil(_G.database)
            test.is_nil(_G.up)
            test.is_nil(_G.after)
            test.is_nil(_G.down)
        end)
    end)
end

local run_cases = test.run_cases(define_tests)

local function run(options: any): any
    return run_cases(options)
end

return { run = run }
