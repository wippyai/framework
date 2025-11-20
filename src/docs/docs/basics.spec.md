# Wippy Runtime System: Basics for AI Developers

## Overview

This document provides a practical introduction to developing code for the Wippy Runtime System, focusing on code
patterns and best practices that AI developers should follow when writing Lua code for this environment.

## Code Structure

### Module Organization

Follow this structure for organizing your Lua modules:

```lua
-- 1. IMPORTS (system modules first, then libraries)
local json = require("json")
local time = require("time")
local http_client = require("http_client")
local utils = require("utils")  -- imported library

-- 2. CONSTANTS
local DEFAULT_TIMEOUT = 30000  -- in milliseconds
local MAX_RETRIES = 3
local STATUS = {
    OK = 200,
    NOT_FOUND = 404,
    ERROR = 500
}

-- 3. IMPLEMENTATION
local function process_data(data)
    -- Implementation
end

-- Function implementation continues...
```

This organization makes your code more maintainable and easier to review.

## Writing Functions

### Function Handlers

When creating a function handler (typically for API endpoints), use this pattern:

```lua
-- Imports
local json = require("json")
local http = require("http")

-- Constants
local STATUS = {
    OK = 200,
    BAD_REQUEST = 400,
    SERVER_ERROR = 500
}

-- Implementation
local function handler(args)
    -- IMPORTANT: Always return a single result for function handlers
    -- NOT the data, error pattern used in libraries
    
    -- Process arguments and validate
    if not args.id then
        return {
            status = STATUS.BAD_REQUEST,
            error = "Missing required id parameter"
        }
    end
    
    -- Do your work
    local result, err = process_data(args)
    if err then
        return {
            status = STATUS.SERVER_ERROR,
            error = err
        }
    end
    
    -- Return single formatted result
    return {
        status = STATUS.OK,
        data = result
    }
end

-- Export the function to be called by the system
return { handler = handler }
```

### HTTP Request Handlers

For HTTP endpoint functions:

```lua
-- Imports
local http = require("http")
local json = require("json")

-- Constants
local METHODS = http.METHOD
local STATUS = http.STATUS

-- Implementation
local function handler()
    local req = http.request()
    local res = http.response()
    
    if req:method() == METHODS.GET then
        -- Handle GET request
        local id = req:query("id")
        if not id then
            res:set_status(STATUS.BAD_REQUEST)
            res:write_json({ error = "Missing id parameter" })
            return
        end
        
        -- Process request
        local data, err = fetch_data(id)
        if err then
            res:set_status(STATUS.INTERNAL_ERROR)
            res:write_json({ error = err })
            return
        end
        
        res:set_status(STATUS.OK)
        res:write_json({ data = data })
    else
        res:set_status(STATUS.METHOD_NOT_ALLOWED)
        res:write_json({ error = "Method not allowed" })
    end
end

-- Export the function
return { handler = handler }
```

## Writing Libraries

For reusable libraries, follow this pattern:

```lua
-- Imports
local json = require("json")
local time = require("time")
local http_client = require("http_client")

-- Constants
local DEFAULT_TIMEOUT = 5000
local API_VERSION = "v1"
local CONTENT_TYPES = {
    JSON = "application/json",
    FORM = "application/x-www-form-urlencoded"
}

-- Create the library table
local my_library = {}

-- Library methods should use the data, error return pattern
function my_library.process_data(input)
    -- Validate input
    if not input then
        return nil, "Invalid input: nil value provided"
    end
    
    -- Process data
    local result, err = do_processing(input)
    if err then
        return nil, err
    end
    
    -- Return success
    return result
end

-- Return the library
return my_library
```

## Environment Variables

Always access environment variables inside handler functions, not at the module level:

```lua
-- Imports
local env = require("env")

-- Constants
local DEFAULT_API_VERSION = "v1"

-- Implementation
local function handler(args)
    -- Get environment variables INSIDE the function
    local api_key, err = env.get("API_KEY")
    if err or not api_key then
        return { error = "API key not configured" }
    end
    
    -- Use the environment variable
    local result = make_api_call(api_key, args)
    
    return { data = result }
end

-- Export the function
return { handler = handler }
```

❌ **INCORRECT** - Don't do this:

```lua
local env = require("env")
-- WRONG: Don't access env variables at module level
local API_KEY = env.get("API_KEY")  -- DON'T DO THIS

local function handler(args)
    -- Using the global env variable
    local result = make_api_call(API_KEY, args)
    return { data = result }
end
```

## Working with Time

Since direct OS time functions are not available, use the `time` module:

```lua
-- Imports
local time = require("time")

-- Implementation
local function process_with_timeout(work_fn, timeout_ms)
    -- Create a timer
    local timer = time.timer(timeout_ms)
    
    -- Create a channel for the result
    local result_channel = channel.new(1)
    
    -- Start the work in a coroutine
    coroutine.spawn(function()
        local result = work_fn()
        result_channel:send(result)
    end)
    
    -- Wait for either result or timeout
    local result = channel.select({
        result_channel:case_receive(),
        timer:channel():case_receive()
    })
    
    if result.channel == timer:channel() then
        return nil, "Operation timed out"
    else
        return result.value
    end
end
```

## Common Patterns

### HTTP Client Requests

```lua
-- Imports
local http_client = require("http_client")
local json = require("json")

-- Constants
local DEFAULT_TIMEOUT = 5000

-- Implementation
local function fetch_data(url, options)
    options = options or {}
    local timeout = options.timeout or DEFAULT_TIMEOUT
    
    -- Make HTTP request
    local response, err = http_client.get(url, {
        headers = options.headers or {},
        timeout = timeout
    })
    
    if err then
        return nil, "HTTP request failed: " .. tostring(err)
    end
    
    if response.status_code >= 400 then
        return nil, "API error: " .. response.status_code
    end
    
    -- Parse JSON response
    local data, parse_err = json.decode(response.body)
    if parse_err then
        return nil, "Failed to parse response: " .. parse_err
    end
    
    return data
end
```

### JSON Processing

```lua
-- Imports
local json = require("json")

-- Implementation
local function process_json_data(json_string)
    -- Parse JSON
    local data, err = json.decode(json_string)
    if err then
        return nil, "Failed to parse JSON: " .. tostring(err)
    end
    
    -- Process data
    -- ...
    
    -- Convert back to JSON
    local result_json, err = json.encode(result)
    if err then
        return nil, "Failed to encode result: " .. tostring(err)
    end
    
    return result_json
end
```

## Core Services Overview

Wippy provides a lot of core modules that you'll commonly use. Use appropriate functions to get list
of currently available modules.

## Best Practices

1. **Module Structure**
    - Always place imports first, then constants, then implementation
    - Use meaningful constant names and organize related constants in tables
    - Keep modules focused on a single responsibility

2. **Return Patterns**
    - For libraries: Use the `data, error` return pattern
    - For function handlers: Return a single result (usually a table with status and data)

3. **Error Handling**
    - Always check for errors from function calls
    - Provide meaningful error messages
    - In libraries, propagate errors with context

4. **Environment Variables**
    - Only access environment variables inside handler functions
    - Always check for errors when getting environment variables
    - Use default values for non-critical environment variables

5. **Time Operations**
    - Always use the `time` module for time-related operations
    - Use timeouts for operations that might block
    - Consider using tickers for periodic tasks

6. **Resource Management**
    - Release resources when done (e.g., file handles, database connections)
    - Implement proper cleanup in termination handlers
    - Use appropriate buffer sizes for streams

7. **Testing**
    - Create unit tests for all functions
    - Mock external dependencies
    - Test both success and error cases
