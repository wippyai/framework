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
wippy test test -- <filter>
```

Discovers tests via `meta.type = "test"` in the registry, groups by `meta.suite`, sorts by `meta.order`.

Each test entry executes in a runner-owned process. A timeout cancels its function
command, waits for cancellation to settle, and terminates the wrapper; late events
from that entry cannot count toward a subsequent test. Processes spawned independently
by test code are not automatically terminated and remain the test's responsibility.

Simple tests may return `true` or `nil` for success; `false`, an execution error, or
an error-status result fails the run. BDD entries must report their plan, every
declared case, and completion with matching pass/fail/skip counts. An aborted hook,
missing case, replaced plan, or inconsistent completion fails the run even if earlier cases passed.
An error-status result also fails when a BDD entry reported otherwise successful cases.

CI can set `WIPPY_TEST_REQUIRE_CASES=1` to reject empty discovery, filters with no matches,
entries without a BDD plan, and skipped-only plans. Without that opt-in, simple tests,
empty plans, and intentionally skipped suites retain their existing behavior.

### Deadlines and teardown

There is no implicit suite or entry deadline. Set `meta.suite_timeout: 2m` on
any entry in a `meta.suite` group to set one shared elapsed-time budget for the
whole group. Conflicting values are rejected. Existing `meta.timeout` remains an
explicit per-entry budget. Expiry calls `cancel()` and receives on the same
future before starting another entry or suite; remaining entries in an expired group
fail without starting. Cancellation failure aborts the run.

This requires the runtime completion semantics in
[wippyai/runtime#961](https://github.com/wippyai/runtime/pull/961): `cancel()`
requests cancellation without waiting, and the future completes only after the
function and its execution frame finish teardown. The runner uses the existing
`cancel()` and `response():receive()` methods, with no teardown deadline.
