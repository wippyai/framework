# Lua Test Framework Documentation

## Overview

This test framework provides a BDD-style testing solution for Lua applications. It includes support for test suites,
individual test cases, various assertion types, lifecycle hooks, and a powerful mocking system.

Every test must be a valid function, read appropriate documentation.

## Getting Started

### Basic Test Structure

```lua
-- Import the test framework
local test = require("test")

-- Define your test cases
local function define_tests()
    describe("My Test Suite", function()
        it("should perform a basic test", function()
            local result = 1 + 1
            expect(result).to_equal(2)
        end)
        
        it("should handle another case", function()
            expect("hello").to_be_type("string")
        end)
    end)
end

-- Run the tests
return test.run_cases(define_tests)
```

### Running Tests

To run tests, call `test.run_cases(define_tests_fn)` with a function that defines your tests. This returns a function
that can be called with options:

```lua
local runner = test.run_cases(define_tests)
local results = runner({
    pid = process.pid,  -- Process ID for messaging
    ref_id = "my-test", -- Optional reference ID
    topic = "test:update" -- Optional custom topic
})
```

## Writing Tests

### Test Suites and Cases

```lua
describe("Suite Name", function()
    -- Test cases go here
    it("should do something", function()
        -- Test logic
    end)
    
    it("should do something else", function()
        -- More test logic
    end)
    
    -- Skip a test
    it_skip("not ready yet", function()
        -- This test will be skipped
    end)
end)
```

### Assertions

The framework provides many assertion methods through the `expect` function:

```lua
-- Basic equality
expect(value).to_equal(expected)
expect(value).not_to_equal(unexpected)

-- Truth testing
expect(value).to_be_true()
expect(value).to_be_false()

-- Nil checks
expect(value).to_be_nil()
expect(value).not_to_be_nil()

-- Type checking
expect(value).to_be_type("string")

-- String pattern matching
expect("test string").to_match("^test")

-- Table assertions
expect(table).to_contain(expected_value)
expect(table).to_have_key(key_name)

-- Error message checking
local response = function_that_returns_error()
expect(response.error_message).to_contain("expected error text")
```

## Lifecycle Hooks

You can define hooks that run before or after tests:

```lua
describe("Suite with hooks", function()
    before_all(function()
        -- Runs once before all tests in this suite
        setup_database()
    end)
    
    after_all(function()
        -- Runs once after all tests in this suite
        cleanup_database()
    end)
    
    before_each(function()
        -- Runs before each test
        reset_state()
    end)
    
    after_each(function()
        -- Runs after each test
        clear_cache()
    end)
    
    it("test with hooks", function()
        -- Test code
    end)
end)
```

## Mocking System

The framework includes a powerful mocking system for replacing functions during tests.

### Basic Mocking

```lua
-- Mock a function on an object
mock(object, "method_name", function(...)
    -- Replacement implementation
    return mock_result
end)

-- Mock using a string path (for global objects)
mock("process.send", function(pid, topic, payload)
    -- Replacement implementation
    return true
end)

-- Restore a specific mock
restore_mock(object, "method_name")
-- Or by string path
restore_mock("process.send")

-- Restore all mocks (done automatically at the end of each test)
restore_all_mocks()
```

### Tracking Mock Calls

A common pattern is to track calls to a mocked function:

```lua
it("should call the right function", function()
    local calls = {}
    
    mock(object, "method", function(arg1, arg2)
        table.insert(calls, {arg1, arg2})
        return true
    end)
    
    -- Call code that should use the mocked function
    some_function()
    
    -- Verify the mock was called with expected arguments
    expect(#calls).to_equal(1)
    expect(calls[1][1]).to_equal("expected_arg1")
end)
```

## Effective Debugging Strategies

### Troubleshooting Failing Tests

When tests fail, use these strategies to diagnose the issue:

```lua
it("should work correctly", function()
    -- Add debug prints with descriptive labels
    print("DEBUG: Starting test 'should work correctly'")
    
    -- Log important state information
    print("DEBUG: Initial state:", json.encode(some_state))
    
    -- Track function execution
    local original_func = module.function_name
    mock(module, "function_name", function(...)
        print("DEBUG: function_name called with args:", json.encode({...}))
        return original_func(...)
    end)
    
    -- Log assertions before making them
    local result = complex_operation()
    print("DEBUG: Operation result:", json.encode(result))
    expect(result.status).to_equal("success")
})
```

### Isolating Components

When testing complex modules, isolate the component under test:

```lua
it("should validate inputs correctly", function()
    -- Mock dependencies to isolate the component being tested
    mock(dependency, "validate", function() return true end)
    mock(logger, "log", function() end)
    
    -- Now the test focuses only on the target component's logic
    local result = component.process_input("test")
    expect(result.success).to_be_true()
end)
```

### Progressive Mocking

For complex test scenarios, apply mocks progressively:

```lua
it("should handle a complex workflow", function()
    -- First, test with minimal mocking
    local result1 = workflow.start("task")
    print("DEBUG: Initial result:", json.encode(result1))
    
    -- If failing, add more mocks to isolate the issue
    mock(database, "query", function() return {row1={}, row2={}} end)
    local result2 = workflow.start("task")
    print("DEBUG: Result with DB mock:", json.encode(result2))
    
    -- Continue adding mocks until the failure point is identified
    mock(api_client, "request", function() return {status=200, data={}} end)
    local result3 = workflow.start("task")
    print("DEBUG: Result with DB and API mocks:", json.encode(result3))
})
```

## Advanced Mocking Techniques

### Mocking Module Exports

When testing modules that export functions, use this pattern:

```lua
-- Module structure designed for testability
local my_module = {}

function my_module.validate_data(data)
    -- Validation logic
end

function my_module.process_data(data)
    if not my_module.validate_data(data) then
        return nil, "Invalid data"
    end
    -- Processing logic
end

return my_module

-- In tests:
it("should process data without validation", function()
    -- Mock the validation function to always return true
    mock(my_module, "validate_data", function() return true end)
    
    -- Now we can test process_data without validation interference
    local result = my_module.process_data({invalid_data=true})
    expect(result).not_to_be_nil()
})
```

### Mocking Internal Functions

To mock internal functions during tests:

```lua
-- Module with internal functions
local function _private_function(arg)
    -- Internal logic
end

local module = {}
function module.public_function(arg)
    return _private_function(arg)
end

-- Expose private functions for testing
if _ENV.TEST_MODE then
    module._private_function = _private_function
end

return module

-- In tests:
local TEST_MODE = true
local module = require("module")

it("should allow mocking internal functions", function()
    mock(module, "_private_function", function() return "mocked" end)
    expect(module.public_function()).to_equal("mocked")
})
```

### Mocking Environment Variables

Test different environment configurations:

```lua
it("should respect environment settings", function()
    local original_get = env.get
    mock(env, "get", function(key)
        if key == "API_TIMEOUT" then
            return "5000"
        end
        return original_get(key)
    end)
    
    expect(client.get_timeout()).to_equal(5000)
})
```

## Test Organization Best Practices

### Grouping Related Tests

Organize tests for better readability and focus:

```lua
describe("User Module", function()
    describe("Authentication", function()
        it("should login valid users", function() end)
        it("should reject invalid credentials", function() end)
    end)
    
    describe("Profile Management", function()
        it("should update user profiles", function() end)
        it("should validate profile data", function() end)
    end)
})
```