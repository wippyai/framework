# wippy/test

BDD-style testing framework with direct assertions, lifecycle hooks, and mocking.

## Usage

```lua
local test = require("test")

local function define_tests()
    test.describe("My Feature", function()
        test.before_each(function()
            -- setup
        end)

        test.it("does something", function()
            test.eq(1 + 1, 2)
        end)

        test.it("handles strings", function()
            test.contains("hello world", "world")
        end)
    end)
end

return { run = test.run_cases(define_tests) }
```

## Assertions

```lua
test.eq(actual, expected, msg?)        -- equality
test.neq(actual, expected, msg?)       -- inequality
test.ok(val, msg?)                     -- truthy
test.fail(msg?)                        -- unconditional failure

test.is_nil(val, msg?)                 -- nil check
test.not_nil(val, msg?)                -- non-nil check
test.is_true(val, msg?)                -- strict true
test.is_false(val, msg?)               -- strict false

test.is_string(val, msg?)              -- type checks
test.is_number(val, msg?)
test.is_table(val, msg?)
test.is_function(val, msg?)
test.is_boolean(val, msg?)

test.contains(str, substr, msg?)       -- substring match
test.matches(str, pattern, msg?)       -- pattern match
test.has_key(tbl, key, msg?)           -- table key exists
test.len(val, expected, msg?)          -- length check

test.gt(a, b, msg?)                    -- a > b
test.gte(a, b, msg?)                   -- a >= b
test.lt(a, b, msg?)                    -- a < b
test.lte(a, b, msg?)                   -- a <= b

test.throws(fn, msg?)                  -- expects error, returns it
test.has_error(val, err, msg?)         -- val is nil, err is not nil
test.no_error(val, err, msg?)          -- err is nil
```

## Lifecycle Hooks

```lua
test.before_all(fn)    -- once before all tests in a suite
test.after_all(fn)     -- once after all tests in a suite
test.before_each(fn)   -- before each test
test.after_each(fn)    -- after each test
```

## Mocking

```lua
test.mock("process.send", function(pid, topic, payload)
    return true
end)

test.restore_mock("process.send")
test.restore_all_mocks()
```

Mocks are automatically restored after each test.

## Test Runner

```
wippy test
wippy test <filter>
```

Discovers tests via `meta.type = "test"` in the registry, groups by `meta.suite`, sorts by `meta.order`.
