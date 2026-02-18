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

        test.it("not_nil narrows nullable to non-nil", function()
            local val: string? = "hello"
            test.not_nil(val)
            test.eq(#val, 5)
        end)

        test.it("not_nil narrows multi-return nullable", function()
            local function fetch(): ({id: string, name: string}?, string?)
                return {id = "x", name = "y"}, nil
            end

            local result, err = fetch()
            test.is_nil(err)
            test.not_nil(result)
            test.eq(result.id, "x")
            test.eq(result.name, "y")
        end)

        test.it("is_string narrows any to string", function()
            local val: any = "hello"
            local s = test.is_string(val)
            test.eq(#s, 5)
            test.eq(s:upper(), "HELLO")
        end)

        test.it("is_number narrows any to number", function()
            local val: any = 42
            local n = test.is_number(val)
            test.eq(n + 1, 43)
        end)

        test.it("is_table narrows any to table", function()
            local val: any = {a = 1}
            local t = test.is_table(val)
            test.not_nil(t)
        end)

        test.it("is_boolean narrows any to boolean", function()
            local val: any = true
            local b = test.is_boolean(val)
            test.is_true(b)
        end)

        test.it("ok narrows falsy values", function()
            local val: string? = "present"
            local v = test.ok(val)
            test.not_nil(v)
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

        test.it("contains narrows and returns string", function()
            local val: any = "hello world"
            local s = test.contains(val, "world")
            test.eq(#s, 11)
        end)

        test.it("matches narrows and returns string", function()
            local val: any = "hello123"
            local s = test.matches(val, "%d+")
            test.eq(s:sub(1, 5), "hello")
        end)

        test.it("has_key returns the value", function()
            local t = {name = "test", value = 42}
            local v = test.has_key(t, "name")
            test.eq(v, "test")
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

        test.it("throws catches errors and returns it", function()
            local err = test.throws(function()
                error("expected error")
            end)
            test.ok(err)
            test.contains(tostring(err), "expected")
        end)

        test.it("has_error validates nil result with error", function()
            test.has_error(nil, "something went wrong")
        end)

        test.it("no_error validates present result without error", function()
            test.no_error("result", nil)
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
