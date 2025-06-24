# Lua Logger Module Specification

## Overview

The `logger` module provides a Lua interface for structured logging. It allows Lua scripts to log messages at different
levels (debug, info, warn, error) with optional fields for additional context. It also supports creating new loggers
with pre-defined fields or names.

## Module Interface

### Module Loading

```lua
local logger = require("logger")
```

### Logger Object

The `logger` module returns a single userdata object representing the initial logger. This object has methods for
logging and creating new loggers.

### Methods

#### logger:debug(message: string, fields?: table)

Logs a debug message.

- **message:** The message string.
- **fields:** (Optional) A table containing key-value pairs to be added as structured fields to the log entry.

#### logger:info(message: string, fields?: table)

Logs an info message.

- **message:** The message string.
- **fields:** (Optional) A table containing key-value pairs to be added as structured fields to the log entry.

#### logger:warn(message: string, fields?: table)

Logs a warning message.

- **message:** The message string.
- **fields:** (Optional) A table containing key-value pairs to be added as structured fields to the log entry.

#### logger:error(message: string, fields?: table)

Logs an error message.

- **message:** The message string.
- **fields:** (Optional) A table containing key-value pairs to be added as structured fields to the log entry. The
  `error` field in this table is treated specially, and if present its value is used to construct an error log entry.

#### logger:with(fields: table)

Creates a new logger that includes the specified fields in every log entry.

- **fields:** A table containing key-value pairs to be added as structured fields to all log entries made with the new
  logger.

Returns:

- A new logger object.

#### logger:named(name: string)

Creates a new logger with a specific name. This is useful for categorizing logs from different parts of an application.

- **name:** The name of the new logger.

Returns:

- A new logger object.

## Field Handling

- The `fields` table in logging methods can contain string, number, and boolean values, these will be logged as
  corresponding types in the log output.
- The `fields` table can contain values that are not strings, numbers, or booleans. These will be logged using a
  generic "any" type representation.
- The `error` field in `logger:error()` is handled specially. When included in the fields table, the value associated
  with `error` will be used as the error message in the log.

## Error Handling

- If any of the methods are called with incorrect argument types (e.g., a number instead of a string for the message),
  an error will be raised.
- If `logger:named()` is called with an empty string as the name, an error will be raised.

## Behavior

- The logger methods (`debug`, `info`, `warn`, `error`) log messages to the underlying logging system.
- The `with` method creates a new logger that inherits the properties of the original logger but also includes the
  specified fields in all subsequent log entries made with that logger.
- The `named` method creates a new logger that inherits the properties of the original logger but also includes the
  specified name in all subsequent log entries made with that logger.
- Log entries are structured and may include a timestamp, log level, message, and any fields provided.

## Thread Safety

- The `logger` module relies on the underlying logging implementation to handle thread safety.

## Best Practices

- Use the `with` method to create loggers with contextual information that is common to multiple log entries (e.g.,
  request ID, user ID).
- Use the `named` method to categorize logs from different parts of your application.
- Use descriptive field names to make logs easier to understand.
- Check for errors returned by the logger methods, especially when using `with` or `named`.
- Use `logger:error()` with an `error` field in the fields table to clearly denote errors in the log output.

## Example Usage

```lua
local logger = require("logger")

-- Log a simple info message
logger:info("application started")

-- Log a debug message with fields
logger:debug("processing request", {
  request_id = "req-123",
  method = "GET",
  path = "/api/users"
})

-- Create a new logger with context
local reqLogger = logger:with({request_id = "req-456"})
reqLogger:info("handling request")
reqLogger:warn("slow database query", {duration_ms = 250})

-- Create a named logger
local authLogger = logger:named("auth")
authLogger:info("user logged in", {user_id = 123, username = "johndoe"})

-- Log an error with a special error field
logger:error("operation failed", {
  error = "file not found",
  operation = "read_file",
  filename = "/tmp/data.txt"
})
```
