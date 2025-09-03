local test = {}
local time = require("time")
local json = require("json")

-- Store original process.send for communication
local _original_process_send = nil
if process and process.send then
    _original_process_send = process.send
end

-- Event types for test operations (aligned with protocol spec)
test.event = {
    DISCOVER = "test:discover",
    PLAN = "test:plan",
    CASE_START = "test:case:start",
    CASE_PASS = "test:case:pass",
    CASE_FAIL = "test:case:fail",
    CASE_SKIP = "test:case:skip",
    COMPLETE = "test:complete",
    ERROR = "test:error"
}

-- Internal state now contained in a singleton context
local _default_context = {
    tests = {},
    suites_hierarchy = {}, -- New: to track top-level suites with their children
    current_describe = nil,
    current_test = nil,
    results = {
        total = 0,
        passed = 0,
        failed = 0,
        skipped = 0,
        tests = {}
    },
    message_topic = "test:update",
    target_pid = nil,
    ref_id = nil,
    -- Default no-op function
    send_message = function(type, data) end,

    -- Mocking system state for immutable tables
    mocks = {
        registry = {}, -- Stores original table states
        namespace = {} -- For generating unique IDs for tables
    }
}

-- MOCKING SYSTEM FOR IMMUTABLE TABLES
-- Deep copy function to preserve table contents
local function deep_copy_table(original)
    if type(original) ~= "table" then
        return original
    end

    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = deep_copy_table(value)
        else
            copy[key] = value
        end
    end

    -- Preserve metatable if it exists
    local mt = getmetatable(original)
    if mt then
        setmetatable(copy, mt)
    end

    return copy
end

-- Parse a mock path string like "process.send" into path components
local function parse_mock_path(path)
    local parts = {}
    for part in string.gmatch(path, "[^.]+") do
        table.insert(parts, part)
    end
    return parts
end

-- Get a reference to a nested object by path (e.g., "process" -> _G.process)
local function get_target_info(path)
    local parts = parse_mock_path(path)
    if #parts ~= 2 then
        error("Invalid mock path: " .. path .. ". Expected format: 'object.field'")
    end

    local obj_name, field_name = parts[1], parts[2]
    local obj = _G[obj_name]

    if obj == nil then
        error("Cannot find object '" .. obj_name .. "' in global scope")
    end

    return _G, obj_name, obj, field_name
end

-- Register a named table for better identification in mocks
function test.register_mock_namespace(target, name)
    _default_context.mocks.namespace[target] = name
    return test
end

-- Helper function to create a proxy function for process.send
local function create_process_send_proxy(replacement)
    return function(pid, topic, payload)
        -- For test framework messages, use the original process.send
        if topic == _default_context.message_topic or topic:match("^test:") then
            if _original_process_send then
                return _original_process_send(pid, topic, payload)
            end
        end

        -- For other messages, use the replacement mock
        return replacement(pid, topic, payload)
    end
end

-- Setup a mock and store the original value
function test.mock(target_or_path, field_or_replacement, replacement_optional)
    local container, container_key, target, field, replacement

    -- Case 1: mock("process.send", function) - path as string
    if type(target_or_path) == "string" and field_or_replacement ~= nil then
        container, container_key, target, field = get_target_info(target_or_path)
        replacement = field_or_replacement

    -- Case 2: mock(process, "send", function) - object, field, replacement
    elseif replacement_optional ~= nil then
        -- For immutable tables, we need to find where this object is stored
        -- This is more complex, so we'll require using string paths for now
        error("With immutable tables, please use string path format: mock('object.field', replacement)")
    else
        error("Invalid mock arguments. Use: mock('object.field', replacement)")
    end

    if type(target) ~= "table" then
        error("Target must be a table, got " .. type(target))
    end

    local mock_id = target_or_path -- Use the path as ID for string-based mocks

    -- Store original table only if not already mocked
    if _default_context.mocks.registry[mock_id] == nil then
        _default_context.mocks.registry[mock_id] = {
            container = container,
            container_key = container_key,
            original_table = deep_copy_table(target)
        }
    end

    -- Create new table with the mocked field
    local new_table = deep_copy_table(target)

    -- Special case for process.send - create proxy
    if container_key == "process" and field == "send" then
        -- Store original once if not already stored
        if not _original_process_send and target.send then
            _original_process_send = target.send
        end
        new_table[field] = create_process_send_proxy(replacement)
    else
        new_table[field] = replacement
    end

    -- Replace the entire table in its container
    container[container_key] = new_table

    return test
end

-- Restore a specific mock
function test.restore_mock(target_or_path, field_optional)
    local mock_id

    -- Case 1: restore_mock("process.send")
    if type(target_or_path) == "string" and field_optional == nil then
        mock_id = target_or_path
    -- Case 2: restore_mock(process, "send") - not supported with immutable tables
    else
        error("With immutable tables, please use string path format: restore_mock('object.field')")
    end

    local entry = _default_context.mocks.registry[mock_id]

    if entry then
        -- Restore the original table
        entry.container[entry.container_key] = entry.original_table
        _default_context.mocks.registry[mock_id] = nil
    end

    -- Special case for process.send - ensure we update our send function
    if mock_id == "process.send" then
        _update_send_message_function()
    end

    return test
end

-- Restore all mocks
function test.restore_all_mocks()
    -- Create a copy of registry keys to avoid modification during iteration
    local registry_keys = {}
    for id, _ in pairs(_default_context.mocks.registry) do
        table.insert(registry_keys, id)
    end

    -- Process each mock
    for _, id in ipairs(registry_keys) do
        local entry = _default_context.mocks.registry[id]
        if entry then
            local success, err = pcall(function()
                entry.container[entry.container_key] = entry.original_table
            end)

            if not success then
                -- Log error but continue with other mocks
                print("Error restoring mock: " .. tostring(err))
            end

            _default_context.mocks.registry[id] = nil
        end
    end

    -- Ensure process.send is properly set
    if process and _original_process_send then
        -- Find if we have a process mock and restore it properly
        if _G.process then
            local restored_process = deep_copy_table(_G.process)
            restored_process.send = _original_process_send
            _G.process = restored_process
        end
        _update_send_message_function()
    end

    return test
end

-- Special handling for process object since it's commonly mocked
function test.mock_process(field, replacement)
    -- Ensure _G.process exists before mocking
    if not _G.process then
        -- Save the original state (nil) before creating it
        local process_id = "process"
        if not _default_context.mocks.registry[process_id] then
            _default_context.mocks.registry[process_id] = {
                container = _G,
                container_key = "process",
                original_table = nil -- Was nil originally
            }
        end

        -- Create an empty process table
        _G.process = {}
    end

    -- Now mock the specific field using the string path approach
    if field then
        return test.mock("process." .. field, replacement)
    end

    return test
end

-- Function to update the send_message based on current process.send
function _update_send_message_function()
    -- Set up the messaging to send messages on the configured topic
    if _default_context.target_pid and _original_process_send then
        _default_context.send_message = function(type, data)
            -- Include ref_id if available
            if _default_context.ref_id and not data.ref_id then
                data.ref_id = _default_context.ref_id
            end

            -- Format according to spec: { type: "string", data: {} }
            _original_process_send(_default_context.target_pid, _default_context.message_topic, {
                type = type,
                data = data
            })
        end
    end
end

-- END OF MOCKING SYSTEM

-- Setup process integration with configurable topic (backward compatible)
function test.setup_process_integration(options)
    -- Check if we're in a process context
    if not process or not process.pid then
        return false
    end

    -- Options must be a table with pid field
    if type(options) ~= "table" or not options.pid then
        return false
    end

    _default_context.target_pid = options.pid

    -- Store ref_id if provided
    if options.ref_id then
        _default_context.ref_id = options.ref_id
    end

    -- Configure message topic if provided
    if options.topic then
        _default_context.message_topic = options.topic
    end

    -- Capture the original process.send first
    if not _original_process_send and process.send then
        _original_process_send = process.send
    end

    -- Update the send_message function
    _update_send_message_function()

    return true
end

-- Default message sending (does nothing by default)
test.send_message = function(type, data)
    return _default_context.send_message(type, data)
end

-- Create a new test suite
function test.suite(name)
    return {
        name = name,
        tests = {},
        before_all = nil,
        after_all = nil,
        before_each = nil,
        after_each = nil,
        parent = nil,      -- Reference to parent suite
        children = {},     -- Child suites
        full_path = name   -- Full path including parent names
    }
end

-- Define a test suite (maintains backward compatibility)
function test.describe(name, fn)
    local old_describe = _default_context.current_describe
    local new_suite = test.suite(name)

    -- Set up parent-child relationship
    if old_describe then
        new_suite.parent = old_describe
        table.insert(old_describe.children, new_suite)
        new_suite.full_path = old_describe.full_path .. " > " .. name
    else
        -- This is a top-level suite
        table.insert(_default_context.suites_hierarchy, new_suite)
    end

    _default_context.current_describe = new_suite

    -- Run the suite definition function
    fn()

    -- Add the suite to our flat test list for backward compatibility
    table.insert(_default_context.tests, new_suite)
    _default_context.current_describe = old_describe

    return new_suite
end

-- Add a before all hook
function test.before_all(fn)
    if not _default_context.current_describe then
        error("before_all must be called within a describe block")
    end
    _default_context.current_describe.before_all = fn
end

-- Add an after all hook
function test.after_all(fn)
    if not _default_context.current_describe then
        error("after_all must be called within a describe block")
    end
    _default_context.current_describe.after_all = fn
end

-- Add a before each hook
function test.before_each(fn)
    if not _default_context.current_describe then
        error("before_each must be called within a describe block")
    end
    _default_context.current_describe.before_each = fn
end

-- Add an after each hook
function test.after_each(fn)
    if not _default_context.current_describe then
        error("after_each must be called within a describe block")
    end

    -- If there's an existing after_each, wrap it
    local existing_after_each = _default_context.current_describe.after_each

    if existing_after_each then
        _default_context.current_describe.after_each = function()
            -- Run the user-provided after_each first
            existing_after_each()

            -- Then run the provided function
            fn()

            -- Always restore mocks at the end of each test
            test.restore_all_mocks()
        end
    else
        -- Just set the new after_each with automatic mock restoration
        _default_context.current_describe.after_each = function()
            -- Run the provided function
            fn()

            -- Always restore mocks at the end of each test
            test.restore_all_mocks()
        end
    end
end

-- Define a test case
function test.it(name, fn)
    if not _default_context.current_describe then
        error("test must be called within a describe block")
    end

    table.insert(_default_context.current_describe.tests, {
        name = name,
        fn = fn,
        skipped = false
    })
end

-- Define a skipped test case
function test.it_skip(name, fn)
    if not _default_context.current_describe then
        error("test must be called within a describe block")
    end

    table.insert(_default_context.current_describe.tests, {
        name = name,
        fn = fn,
        skipped = true
    })
end

-- Assertion helpers
local function format_value(val)
    if type(val) == "string" then
        return string.format("%q", val)
    elseif type(val) == "table" then
        if val._tostring then
            return val:_tostring()
        else
            local str = "{"
            for k, v in pairs(val) do
                str = str .. (type(k) == "number" and "" or k .. "=") .. format_value(v) .. ","
            end
            return str .. "}"
        end
    else
        return tostring(val)
    end
end

-- Helper function to get debug info for assertions, skipping test framework internals
local function get_debug_info()
    local level = 3 -- Start 3 levels up from assertion functions
    local max_level = 10 -- Don't go too deep

    while level <= max_level do
        local info = debug.getinfo(level)
        if not info then
            break
        end

        -- Skip internal test framework functions
        local source = info.source or ""
        local name = info.name or ""

        -- Skip if it's from test framework internals
        if not (source:match("test%.lua") and (name:match("assert") or name:match("expect") or name == "")) then
            return {
                line = info.currentline,
                source = source
            }
        end

        level = level + 1
    end

    -- Fallback to level 3 if we can't find a good frame
    local info = debug.getinfo(3)
    return {
        line = info and info.currentline or 0,
        source = info and info.source or "unknown"
    }
end

-- Helper to format error message consistently
local function format_error_msg(template, actual, expected, message)
    local info = get_debug_info()
    local base_msg = string.format(template, format_value(expected), format_value(actual))

    if message and message ~= "" then
        return string.format("%s:%d: %s (%s)", info.source, info.line, base_msg, message)
    else
        return string.format("%s:%d: %s", info.source, info.line, base_msg)
    end
end

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error(format_error_msg("Expected %s but got %s", actual, expected, message), 2)
    end
    return true
end

local function assert_not_equal(actual, expected, message)
    if actual == expected then
        error(format_error_msg("Expected %s to not equal %s", actual, expected, message), 2)
    end
    return true
end

local function assert_true(actual, message)
    if actual ~= true then
        local info = get_debug_info()
        local base_msg = string.format("Expected true but got %s", format_value(actual))
        if message and message ~= "" then
            error(string.format("%s:%d: %s (%s)", info.source, info.line, base_msg, message), 2)
        else
            error(string.format("%s:%d: %s", info.source, info.line, base_msg), 2)
        end
    end
    return true
end

local function assert_false(actual, message)
    if actual ~= false then
        local info = get_debug_info()
        local base_msg = string.format("Expected false but got %s", format_value(actual))
        if message and message ~= "" then
            error(string.format("%s:%d: %s (%s)", info.source, info.line, base_msg, message), 2)
        else
            error(string.format("%s:%d: %s", info.source, info.line, base_msg), 2)
        end
    end
    return true
end

local function assert_nil(actual, message)
    if actual ~= nil then
        local info = get_debug_info()
        local base_msg = string.format("Expected nil but got %s", format_value(actual))
        if message and message ~= "" then
            error(string.format("%s:%d: %s (%s)", info.source, info.line, base_msg, message), 2)
        else
            error(string.format("%s:%d: %s", info.source, info.line, base_msg), 2)
        end
    end
    return true
end

local function assert_not_nil(actual, message)
    if actual == nil then
        local info = get_debug_info()
        local base_msg = "Expected value to not be nil"
        if message and message ~= "" then
            error(string.format("%s:%d: %s (%s)", info.source, info.line, base_msg, message), 2)
        else
            error(string.format("%s:%d: %s", info.source, info.line, base_msg), 2)
        end
    end
    return true
end

local function assert_match(str, pattern, message)
    if not string.match(str, pattern) then
        error(format_error_msg("Expected %s to match pattern %s", str, pattern, message), 2)
    end
    return true
end

local function assert_not_match(str, pattern, message)
    if string.match(str, pattern) then
        error(format_error_msg("Expected %s to not match pattern %s", str, pattern, message), 2)
    end
    return true
end

-- Expect function that returns assertion methods
function test.expect(actual)
    return {
        to_equal = function(expected, message)
            return assert_equal(actual, expected, message)
        end,
        not_to_equal = function(expected, message)
            return assert_not_equal(actual, expected, message)
        end,
        to_be_true = function(message)
            return assert_true(actual, message)
        end,
        to_be_false = function(message)
            return assert_false(actual, message)
        end,
        to_be_nil = function(message)
            return assert_nil(actual, message)
        end,
        not_to_be_nil = function(message)
            return assert_not_nil(actual, message)
        end,
        to_match = function(pattern, message)
            return assert_match(actual, pattern, message)
        end,
        not_to_match = function(pattern, message)
            return assert_not_match(actual, pattern, message)
        end,
        to_be_type = function(expected_type, message)
            local actual_type = type(actual)
            if actual_type ~= expected_type then
                error(format_error_msg("Expected type %s but got type %s", actual_type, expected_type, message), 2)
            end
            return true
        end,
        to_contain = function(expected, message)
            if type(actual) == "table" then
                local found = false
                for _, v in pairs(actual) do
                    if v == expected then
                        found = true
                        break
                    end
                end
                if not found then
                    local info = get_debug_info()
                    local base_msg = string.format("Expected table to contain %s", format_value(expected))
                    if message and message ~= "" then
                        error(string.format("%s:%d: %s (%s)", info.source, info.line, base_msg, message), 2)
                    else
                        error(string.format("%s:%d: %s", info.source, info.line, base_msg), 2)
                    end
                end
                return true
            elseif type(actual) == "string" then
                if not string.find(actual, expected, 1, true) then
                    local info = get_debug_info()
                    local base_msg = string.format("Expected string %s to contain %s", format_value(actual), format_value(expected))
                    if message and message ~= "" then
                        error(string.format("%s:%d: %s (%s)", info.source, info.line, base_msg, message), 2)
                    else
                        error(string.format("%s:%d: %s", info.source, info.line, base_msg), 2)
                    end
                end
                return true
            else
                local info = get_debug_info()
                local base_msg = "Expected a table or string to check contents"
                if message and message ~= "" then
                    error(string.format("%s:%d: %s (%s)", info.source, info.line, base_msg, message), 2)
                else
                    error(string.format("%s:%d: %s", info.source, info.line, base_msg), 2)
                end
            end
        end,
        not_to_contain = function(expected, message)
            if type(actual) == "table" then
                local found = false
                for _, v in pairs(actual) do
                    if v == expected then
                        found = true
                        break
                    end
                end
                if found then
                    local info = get_debug_info()
                    local base_msg = string.format("Expected table to not contain %s", format_value(expected))
                    if message and message ~= "" then
                        error(string.format("%s:%d: %s (%s)", info.source, info.line, base_msg, message), 2)
                    else
                        error(string.format("%s:%d: %s", info.source, info.line, base_msg), 2)
                    end
                end
                return true
            elseif type(actual) == "string" then
                if string.find(actual, expected, 1, true) then
                    local info = get_debug_info()
                    local base_msg = string.format("Expected string %s to not contain %s", format_value(actual), format_value(expected))
                    if message and message ~= "" then
                        error(string.format("%s:%d: %s (%s)", info.source, info.line, base_msg, message), 2)
                    else
                        error(string.format("%s:%d: %s", info.source, info.line, base_msg), 2)
                    end
                end
                return true
            else
                local info = get_debug_info()
                local base_msg = "Expected a table or string to check contents"
                if message and message ~= "" then
                    error(string.format("%s:%d: %s (%s)", info.source, info.line, base_msg, message), 2)
                else
                    error(string.format("%s:%d: %s", info.source, info.line, base_msg), 2)
                end
            end
        end,
        to_have_key = function(key, message)
            if type(actual) ~= "table" then
                local info = get_debug_info()
                local base_msg = "Expected a table to check for key"
                if message and message ~= "" then
                    error(string.format("%s:%d: %s (%s)", info.source, info.line, base_msg, message), 2)
                else
                    error(string.format("%s:%d: %s", info.source, info.line, base_msg), 2)
                end
            end

            if actual[key] == nil then
                local info = get_debug_info()
                local base_msg = string.format("Expected table to have key %s", format_value(key))
                if message and message ~= "" then
                    error(string.format("%s:%d: %s (%s)", info.source, info.line, base_msg, message), 2)
                else
                    error(string.format("%s:%d: %s", info.source, info.line, base_msg), 2)
                end
            end
            return true
        end,
        not_to_have_key = function(key, message)
            if type(actual) ~= "table" then
                local info = get_debug_info()
                local base_msg = "Expected a table to check for key"
                if message and message ~= "" then
                    error(string.format("%s:%d: %s (%s)", info.source, info.line, base_msg, message), 2)
                else
                    error(string.format("%s:%d: %s", info.source, info.line, base_msg), 2)
                end
            end

            if actual[key] ~= nil then
                local info = get_debug_info()
                local base_msg = string.format("Expected table to not have key %s", format_value(key))
                if message and message ~= "" then
                    error(string.format("%s:%d: %s (%s)", info.source, info.line, base_msg, message), 2)
                else
                    error(string.format("%s:%d: %s", info.source, info.line, base_msg), 2)
                end
            end
            return true
        end,
        to_be_greater_than = function(expected, message)
            if not (actual > expected) then
                error(format_error_msg("Expected %s to be greater than %s", actual, expected, message), 2)
            end
            return true
        end,
        to_be_less_than = function(expected, message)
            if not (actual < expected) then
                error(format_error_msg("Expected %s to be less than %s", actual, expected, message), 2)
            end
            return true
        end,
        to_be_greater_than_or_equal = function(expected, message)
            if not (actual >= expected) then
                error(format_error_msg("Expected %s to be greater than or equal to %s", actual, expected, message), 2)
            end
            return true
        end,
        to_be_less_than_or_equal = function(expected, message)
            if not (actual <= expected) then
                error(format_error_msg("Expected %s to be less than or equal to %s", actual, expected, message), 2)
            end
            return true
        end
    }
end

-- Format error with stack trace into a structured object
local function format_error_message(err)
    -- For error objects, first get the basic message
    local error_message = tostring(err)

    -- Check if the error message itself indicates it's an assertion error
    if string.match(error_message, "Expected") then
        -- Just return it without adding any stack trace
        return error_message
    end

    -- Only add stack trace for non-assertion errors (like runtime errors)
    -- and only if the errors.call_stack function is available
    if errors and errors.call_stack then
        -- Get the call stack
        local call_stack = errors.call_stack(err)
        if call_stack and call_stack.frames and #call_stack.frames > 0 then
            -- Don't add stack trace info for assertion errors
            for _, frame in ipairs(call_stack.frames) do
                -- If this appears to be from our assertion system, skip stack trace
                if frame.source and frame.line and string.match(frame.name or "", "assert") then
                    return error_message
                end
            end

            -- For non-assertion errors, add the stack trace
            local stack_text = "\nStack trace:"
            for i, frame in ipairs(call_stack.frames) do
                local source = frame.source and frame.source:gsub("[<>]", "") or "unknown"
                local line = frame.line and frame.line > 0 and frame.line or "?"
                local func_name = frame.name and frame.name:gsub("[<>]", "") or "unknown"

                -- Don't include any frames from assertion functions or test framework internals
                if not (string.match(func_name or "", "assert") or
                       string.match(source or "", "test%.lua")) then
                    local prefix = i > 1 and "  " or "->"
                    stack_text = stack_text .. string.format("\n%s %s:%s in %s",
                                                           prefix, source, line, func_name)
                end
            end

            error_message = error_message .. stack_text
        end
    end

    return error_message
end

-- Get all parent suites in order from root to the target suite
local function get_suite_ancestry(suite)
    local ancestry = {}
    local current = suite

    while current do
        table.insert(ancestry, 1, current) -- Insert at beginning to get root->child order
        current = current.parent
    end

    return ancestry
end

-- Run a single test with proper parent inheritance
local function run_test(suite, test_case)
    local result = {
        suite = suite.full_path or suite.name, -- Use full path for nested suites
        name = test_case.name,
        status = "pending"
    }

    if test_case.skipped then
        result.status = "skip"
        _default_context.results.skipped = _default_context.results.skipped + 1

        -- Get current timestamp
        local current_time = time.now()
        local timestamp = current_time:unix()

        -- Send skip notification according to spec
        _default_context.send_message(test.event.CASE_SKIP, {
            suite = result.suite,
            test = test_case.name,
            timestamp = timestamp
        })

        return result
    end

    _default_context.current_test = test_case

    -- Use time module for precise timing
    local start_time = time.now()

    -- Get timestamp for start event
    local start_timestamp = start_time:unix()

    -- Send test case start event according to protocol
    _default_context.send_message(test.event.CASE_START, {
        suite = result.suite,
        test = test_case.name,
        timestamp = start_timestamp
    })

    -- Execute before_each hooks from ancestors to current suite
    local ancestry = get_suite_ancestry(suite)
    for _, ancestor in ipairs(ancestry) do
        if ancestor.before_each then
            ancestor.before_each()
        end
    end

    -- we are using cpcall since it allows coroutine yields inside it
    local success, err = cpcall(test_case.fn)

    -- Execute after_each hooks from current suite to ancestors (reverse order)
    for i = #ancestry, 1, -1 do
        local ancestor = ancestry[i]
        if ancestor.after_each then
            ancestor.after_each()
        end
    end

    -- Ensure mocks are restored
    test.restore_all_mocks()

    -- Calculate duration using time module with millisecond precision
    local end_time = time.now()
    local duration = end_time:sub(start_time):milliseconds() / 1000 -- Convert to seconds but preserve ms precision

    result.duration = duration

    -- Get completion timestamp
    local completion_timestamp = end_time:unix()

    if success then
        result.status = "pass"
        _default_context.results.passed = _default_context.results.passed + 1

        -- Send pass event according to protocol
        _default_context.send_message(test.event.CASE_PASS, {
            suite = result.suite,
            test = test_case.name,
            duration = duration,
            timestamp = completion_timestamp
        })
    else
        -- Format error message without additional prefixes or redundant data
        local error_text = format_error_message(err)

        result.status = "fail"
        result.error = error_text
        _default_context.results.failed = _default_context.results.failed + 1

        -- Send fail event according to protocol
        _default_context.send_message(test.event.CASE_FAIL, {
            suite = result.suite,
            test = test_case.name,
            duration = duration,
            error = error_text,
            timestamp = completion_timestamp
        })
    end

    _default_context.current_test = nil
    return result
end

-- Run all tests in a suite and its child suites
local function run_suite_with_children(suite)
    local results = {}

    -- Get all ancestors to run their before_all hooks in order
    local ancestry = get_suite_ancestry(suite)

    -- Execute before_all hooks from ancestors to the current suite
    for _, ancestor in ipairs(ancestry) do
        if ancestor.before_all then
            ancestor.before_all()
        end
    end

    -- Run the tests in this suite
    for _, test_case in ipairs(suite.tests) do
        local result = run_test(suite, test_case)
        table.insert(results, result)
        table.insert(_default_context.results.tests, result)
    end

    -- Run tests in child suites if we're running the parent suite directly
    -- (When the parent is processed, its children will be visited as well)
    if not suite.parent then
        for _, child in ipairs(suite.children) do
            local child_results = run_suite_with_children(child)
            for _, result in ipairs(child_results) do
                table.insert(results, result)
            end
        end
    end

    -- Execute after_all hooks from current suite to ancestors (reverse order)
    for i = #ancestry, 1, -1 do
        local ancestor = ancestry[i]
        if ancestor.after_all then
            ancestor.after_all()
        end
    end

    -- Make sure all mocks are restored after the suite
    test.restore_all_mocks()

    return results
end

-- Collect all test cases from a suite and its children
local function collect_all_tests_from_suite(suite, collection)
    collection = collection or {}

    for _, test_case in ipairs(suite.tests) do
        table.insert(collection, {
            suite = suite.full_path or suite.name,
            name = test_case.name,
            skipped = test_case.skipped
        })
    end

    for _, child_suite in ipairs(suite.children) do
        collect_all_tests_from_suite(child_suite, collection)
    end

    return collection
end

-- Run all tests
function test.run()
    -- Reset results for this run
    _default_context.results = {
        total = 0,
        passed = 0,
        failed = 0,
        skipped = 0,
        tests = {}
    }

    local start_time = time.now()

    -- First, report all test suites and cases
    local test_plan = {
        suites = {}
    }

    -- Collect all test cases from all suites, using hierarchy
    local all_test_cases = {}
    for _, top_suite in ipairs(_default_context.suites_hierarchy) do
        local suite_info = {
            name = top_suite.name,
            tests = {}
        }

        -- Collect tests from this suite and all its children
        local suite_tests = collect_all_tests_from_suite(top_suite)
        for _, test_info in ipairs(suite_tests) do
            _default_context.results.total = _default_context.results.total + 1
            table.insert(suite_info.tests, {
                name = test_info.name,
                skipped = test_info.skipped
            })
        end

        table.insert(test_plan.suites, suite_info)
    end

    -- Report the test plan according to protocol
    _default_context.send_message(test.event.PLAN, test_plan)

    -- Run tests in hierarchy, starting with top-level suites
    for _, suite in ipairs(_default_context.suites_hierarchy) do
        run_suite_with_children(suite)
    end

    -- Calculate total duration using time module with millisecond precision
    local end_time = time.now()
    local duration = end_time:sub(start_time):milliseconds() / 1000 -- Convert to seconds but preserve ms precision
    _default_context.results.duration = duration

    -- Get completion timestamp
    local completion_timestamp = end_time:unix()

    -- Determine overall status
    local overall_status = _default_context.results.failed > 0 and "failed" or "passed"

    -- Report final results according to protocol
    _default_context.send_message(test.event.COMPLETE, {
        total = _default_context.results.total,
        passed = _default_context.results.passed,
        failed = _default_context.results.failed,
        skipped = _default_context.results.skipped,
        duration = duration,
        timestamp = completion_timestamp,
        status = overall_status
    })

    return _default_context.results
end

-- Clean up test resources to avoid memory leaks
local function cleanup_test_resources()
    -- Clean up all mocks
    test.restore_all_mocks()

    -- Clear any potential circular references
    local function clear_suite_references(suite)
        if suite.tests then
            for i, test_case in ipairs(suite.tests) do
                -- Clear function references
                suite.tests[i].fn = nil
            end
        end

        -- Clear lifecycle hooks
        suite.before_all = nil
        suite.after_all = nil
        suite.before_each = nil
        suite.after_each = nil

        -- Break circular references
        -- Don't clear parent references - needed for cleanup
        suite.children = {}

        -- Process child suites recursively
        for _, child in ipairs(suite.children or {}) do
            clear_suite_references(child)
        end
    end

    -- Clear hierarchy and references
    for _, suite in ipairs(_default_context.suites_hierarchy) do
        clear_suite_references(suite)
    end

    -- Clear test results to avoid memory leaks
    for i, result in ipairs(_default_context.results.tests) do
        -- Remove any large error messages that might hold references
        _default_context.results.tests[i].error = nil
    end

    -- Reset mock registry and namespace tables
    _default_context.mocks.registry = {}
    _default_context.mocks.namespace = {}

    -- Clear test list
    _default_context.tests = {}
    _default_context.suites_hierarchy = {}
    _default_context.current_describe = nil
    _default_context.current_test = nil

    -- Reset results
    _default_context.results = {
        total = 0,
        passed = 0,
        failed = 0,
        skipped = 0,
        tests = {}
    }
end

-- Run test cases from a test definition function
function test.run_cases(define_cases_fn)
    return function(options)
        -- Ensure we're starting fresh - clean up any resources from previous runs
        cleanup_test_resources()

        -- Reset state for a fresh test run
        _default_context.tests = {}
        _default_context.suites_hierarchy = {}

        -- Keep any existing options.ref_id
        if options and options.ref_id then
            _default_context.ref_id = options.ref_id
        end

        -- Capture the original process.send if it exists
        if not _original_process_send and process and process.send then
            _original_process_send = process.send
        end

        -- Setup globals for easier writing of test cases
        _G.it = test.it
        _G.it_skip = test.it_skip
        _G.describe = test.describe
        _G.expect = test.expect
        _G.before_each = test.before_each
        _G.after_each = test.after_each
        _G.before_all = test.before_all
        _G.after_all = test.after_all

        -- Setup mocking globals
        _G.mock = test.mock
        _G.mock_process = test.mock_process
        _G.restore_mock = test.restore_mock
        _G.restore_all_mocks = test.restore_all_mocks

        -- Set up process integration with options (PID and topic)
        test.setup_process_integration(options)

        -- Let the test file define its cases
        define_cases_fn()

        -- Run all the tests
        local results = test.run()

        -- Format results for healthcheck
        local healthcheck_result = {
            timestamp = time.now():unix(),
            status = results.failed > 0 and "error" or "ok",
            total_tests = results.total,
            passed_tests = results.passed,
            failed_tests = results.failed,
            duration_ms = results.duration * 1000,
            test_suites = {}
        }

        -- Include ref_id if it was provided
        if _default_context.ref_id then
            healthcheck_result.ref_id = _default_context.ref_id
        end

        -- Format detailed test results
        local suite_objects = {}
        for _, test_result in ipairs(results.tests) do
            if not suite_objects[test_result.suite] then
                suite_objects[test_result.suite] = {
                    name = test_result.suite,
                    status = "ok",
                    tests = {}
                }
                healthcheck_result.test_suites[test_result.suite] = suite_objects[test_result.suite]
            end

            local suite = suite_objects[test_result.suite]

            -- Add this test to the suite
            table.insert(suite.tests, {
                name = test_result.name,
                status = test_result.status,
                duration_ms = test_result.duration and (test_result.duration * 1000) or nil,
                error = test_result.error
            })

            -- Update suite status if any test failed
            if test_result.status == "fail" then
                suite.status = "error"
            end
        end

        -- Clean up globals
        _G.it = nil
        _G.describe = nil
        _G.expect = nil
        _G.before_each = nil
        _G.after_each = nil
        _G.before_all = nil
        _G.after_all = nil
        _G.mock = nil
        _G.mock_process = nil
        _G.restore_mock = nil
        _G.restore_all_mocks = nil

        -- Complete cleanup to prevent memory leaks
        cleanup_test_resources()

        return healthcheck_result
    end
end

-- Report test error according to protocol
function test.report_error(message, context)
    local current_time = time.now()
    _default_context.send_message(test.event.ERROR, {
        message = message,
        context = context or "test",
        timestamp = current_time:unix()
    })
end

-- Aliases for BDD-style syntax
test.spec = test.describe
test.context = test.describe
test.assert = test.expect

return test