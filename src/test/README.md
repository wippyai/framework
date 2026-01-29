# wippy/test

BDD-style testing framework for Lua applications with support for test suites, assertions, lifecycle hooks, and mocking.

Part of the [Wippy Framework](https://github.com/wippyai/framework).

## Installation

```
wippy add wippy/test
```

## Usage

```lua
local test = require("wippy.test:test")

test.describe("My Feature", function()
    test.before_each(function()
        -- setup
    end)

    test.it("does something", function()
        test.expect(1 + 1).to_equal(2)
    end)

    test.it("handles strings", function()
        test.expect("hello").to_contain("ell")
    end)
end)

return test.run_cases(test.describe)
```

## Assertions

```lua
test.expect(value).to_equal(expected)
test.expect(value).not_to_equal(unexpected)
test.expect(value).to_be_true()
test.expect(value).to_be_false()
test.expect(value).to_be_nil()
test.expect(value).not_to_be_nil()
test.expect(value).to_be_type("string")
test.expect(value).to_match(pattern)
test.expect(value).to_contain(element)
test.expect(value).to_have_key(key)
test.expect(value).to_be_greater_than(n)
test.expect(value).to_be_less_than(n)
```

## Lifecycle Hooks

- `test.before_all(fn)` - runs once before all tests in a suite
- `test.after_all(fn)` - runs once after all tests in a suite
- `test.before_each(fn)` - runs before each test
- `test.after_each(fn)` - runs after each test

## Mocking

```lua
test.mock(object, "method", function() return "mocked" end)
test.mock("module.function", replacement)
test.restore_mock(object, "method")
test.restore_all_mocks()
```

Mocks are automatically restored after each test.

## Test Discovery

The `registry` library provides test discovery and grouping:

```lua
local registry = require("wippy.test:registry")

local all_tests = registry.find()
local groups = registry.get_groups()
local group_tests = registry.get_by_group("My Group")
```

## License

Apache-2.0
