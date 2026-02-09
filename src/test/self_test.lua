-- Self-test for the test framework
local test = require("test")

local function define_tests()
    test.describe("assertions", function()
        test.it("eq passes for equal values", function()
            test.eq(1, 1)
            test.eq("hello", "hello")
            test.eq(true, true)
        end)

        test.it("neq passes for different values", function()
            test.neq(1, 2)
            test.neq("a", "b")
        end)

        test.it("ok passes for truthy values", function()
            test.ok(true)
            test.ok(1)
            test.ok("string")
            test.ok({})
        end)

        test.it("is_nil passes for nil", function()
            test.is_nil(nil)
        end)

        test.it("not_nil passes for non-nil", function()
            test.not_nil(1)
            test.not_nil("")
        end)

        test.it("is_true and is_false work", function()
            test.is_true(true)
            test.is_false(false)
        end)

        test.it("type checks work", function()
            test.is_string("hello")
            test.is_number(42)
            test.is_table({})
            test.is_function(function() end)
        end)

        test.it("contains checks substring", function()
            test.contains("hello world", "world")
            test.contains("testing", "est")
        end)

        test.it("matches checks patterns", function()
            test.matches("hello123", "%d+")
            test.matches("test@example.com", "@")
        end)

        test.it("has_key checks table keys", function()
            local t = {name = "test", value = 42}
            test.has_key(t, "name")
            test.has_key(t, "value")
        end)

        test.it("len checks length", function()
            test.len("hello", 5)
            test.len({1, 2, 3}, 3)
        end)

        test.it("comparison assertions work", function()
            test.gt(5, 3)
            test.gte(5, 5)
            test.lt(3, 5)
            test.lte(5, 5)
        end)

        test.it("throws catches errors", function()
            local err = test.throws(function()
                error("expected error")
            end)
            test.ok(err)
        end)
    end)

    test.describe("suites", function()
        local setup_called = false
        local teardown_called = false

        test.before_all(function()
            setup_called = true
        end)

        test.after_all(function()
            teardown_called = true
        end)

        test.it("before_all runs before tests", function()
            test.is_true(setup_called)
        end)

        test.describe("nested", function()
            test.it("nested suites work", function()
                test.ok(true)
            end)
        end)
    end)

    test.describe("lifecycle", function()
        local counter = 0

        test.before_each(function()
            counter = counter + 1
        end)

        test.it("before_each runs before each test", function()
            test.eq(counter, 1)
        end)

        test.it("before_each runs again", function()
            test.eq(counter, 2)
        end)
    end)

    test.describe("skip", function()
        test.it("this test runs", function()
            test.ok(true)
        end)

        test.it_skip("this test is skipped", function()
            test.fail("should not run")
        end)
    end)
end

local run_cases = test.run_cases(define_tests)

local function run(options: any): any
    local result = run_cases(options)
    if result.failed_tests > 0 then
        error("self-test failed: " .. result.failed_tests .. " test(s) failed")
    end
    return result
end

return { run = run }
