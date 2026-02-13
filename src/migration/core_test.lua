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
