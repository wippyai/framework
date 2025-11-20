# FS Package Specification

## Overview

The FS package provides a universal filesystem abstraction layer for Lua. It exposes a consistent API for file and
directory operations that can work across different storage backends (local filesystem, S3, etc.).

## Module Interface

### Loading the Module

```lua
local fs = require("fs")
```

### Constants

#### File Type Constants

Available in `fs.type`:

- `FILE` (string): Represents a regular file
- `DIR` (string): Represents a directory

#### Seek Constants

Available in `fs.seek`:

- `SET` (string): Seek from start of file
- `CUR` (string): Seek from current position
- `END` (string): Seek from end of file

## Core Concepts

### Path Handling

- All paths are normalized internally
- Absolute paths (starting with '/') are treated relative to filesystem root
- Relative paths are resolved against current working directory
- Path separators are forward slashes ('/')
- '.' represents current directory
- '..' represents parent directory

### Error Handling

- Most operations raise errors on failure
- File operations (read/write/seek) return nil + error message on failure
- EOF is indicated by nil + "EOF" return values

## Filesystem Instance

### Obtaining a Filesystem Instance

```lua
-- Get named filesystem
local fs = fs.get("name")
-- Returns: filesystem instance
-- Errors: raises if named filesystem doesn't exist
```

### Directory Operations

#### Change Directory

```lua
fs:chdir(path)
-- Parameters: path (string) - Target directory path
-- Returns: true on success
-- Errors: raises if
--   - path doesn't exist
--   - path is not a directory
--   - insufficient permissions
```

#### Print Working Directory

```lua
local path = fs:pwd()
-- Returns: string - Current working directory (always starts with '/')
```

#### Make Directory

```lua
fs:mkdir(path)
-- Parameters: path (string) - Directory to create
-- Returns: true on success
-- Errors: raises if
--   - directory already exists
--   - parent directory doesn't exist
--   - insufficient permissions
```

#### Read Directory

```lua
for entry in fs:readdir(path) do
    -- entry is a table with:
    --   entry.name (string): Entry name
    --   entry.type (string): Either fs.type.FILE or fs.type.DIR
end
-- Parameters: path (string) - Directory to list
-- Returns: iterator function
-- Errors: raises if
--   - directory doesn't exist
--   - not a directory
--   - insufficient permissions
```

### File Operations

#### Open File

```lua
local file = fs:open(path, mode)
-- Parameters:
--   path (string): File path
--   mode (string): One of:
--     "r"  - Read mode
--     "w"  - Write mode (create/truncate)
--     "wx" - Write mode (create only/fail if exists)
--     "a"  - Append mode (create if needed)
-- Returns: file object
-- Errors: raises if
--   - invalid mode
--   - file doesn't exist (read mode)
--   - file exists (wx mode)
--   - insufficient permissions
```

#### Read from File

```lua
local data, err = file:read([size])
-- Parameters: 
--   size (number, optional): Maximum bytes to read, defaults to 4096
-- Returns on success: string (data read)
-- Returns on EOF: nil, "EOF"
-- Returns on error: nil, error message
```

#### Write to File

```lua
local ok, err = file:write(data)
-- Parameters: 
--   data (string): Data to write
-- Returns on success: true
-- Returns on error: nil, error message
```

#### Seek in File

```lua
local pos, err = file:seek(whence, offset)
-- Parameters:
--   whence (string): One of fs.seek.SET, fs.seek.CUR, fs.seek.END
--   offset (number): Offset in bytes
-- Returns on success: new position (number)
-- Returns on error: nil, error message
```

#### Sync File

```lua
local ok, err = file:sync()
-- Returns on success: true
-- Returns on error: nil, error message
-- Description: Ensures all buffered writes are committed to stable storage
-- Errors: raises if
--   - file doesn't support sync operations
--   - sync operation fails
--   - file is closed
```

#### Close File

```lua
file:close()
-- Returns: nothing
-- Errors: raises if already closed
```

#### Read Entire File

```lua
local content = fs:readfile(path)
-- Parameters: path (string) - File to read
-- Returns: string with entire file content
-- Errors: raises if
--   - file doesn't exist
--   - insufficient permissions
--   - read error occurs
-- Note: Yields during read for large files
```

#### Write Entire File

```lua
fs:writefile(path, data, mode)
-- Parameters:
--   path (string): File to write
--   data: Content to write, can be:
--     - string: Raw data
--     - userdata: File, Stream and etc
--   mode (string, optional): Open mode (defaults to "w")
--     - "w": Create/truncate
--     - "wx": Create new only
--     - "a": Append
-- Returns: true on success
-- Errors: raises if
--   - file operation fails
--   - write error occurs
--   - invalid input type
-- Note: Yields during write for large files
```

### Information Operations

#### File Statistics

```lua
local info = fs:stat(path)
-- Parameters: path (string) - Path to check
-- Returns: table with
--   info.name (string): Base name
--   info.size (number): Size in bytes
--   info.mode (number): File mode/permissions
--   info.modified (number): Modification time (Unix timestamp)
--   info.is_dir (boolean): True if directory
--   info.type (string): Either fs.type.FILE or fs.type.DIR
-- Errors: raises if
--   - path doesn't exist
--   - insufficient permissions
```

#### Check if Directory

```lua
local isdir = fs:isdir(path)
-- Parameters: path (string) - Path to check
-- Returns: boolean - true if path exists and is directory
-- Errors: raises if insufficient permissions
```

#### Check if Exists

```lua
local exists = fs:exists(path)
-- Parameters: path (string) - Path to check
-- Returns: boolean - true if path exists
-- Errors: raises if permission error
```

### Resource Operations

#### Remove File/Directory

```lua
fs:remove(path)
-- Parameters: path (string) - Path to remove
-- Returns: true on success
-- Errors: raises if
--   - path doesn't exist
--   - insufficient permissions
--   - directory not empty
```

## Example Usage

### Basic File Operations

```lua
local fs = require("fs").get("system:name")

-- Write data to file
fs:writefile("test.txt", "Hello World")

-- Read entire file
local content = fs:readfile("test.txt")
print(content) -- Outputs: Hello World

-- Copy between files using io.Reader
local src = fs:open("source.txt", "r")
fs:writefile("dest.txt", src)
src:close()

-- Stream processing with explicit open/close
local f = fs:open("data.txt", "w")
f:write("Line 1\n")
f:write("Line 2\n")
f:sync() -- Ensure data is written to disk
f:close()
```

### Directory Operations

```lua
-- List directory contents
for entry in fs:readdir("/data") do
    if entry.type == fs.type.FILE then
        local info = fs:stat("/data/" .. entry.name)
        print(string.format("%s: %d bytes", entry.name, info.size))
    end
end

-- Create and navigate directories
fs:mkdir("newdir")
fs:chdir("newdir")
print(fs:pwd()) -- Shows current directory

-- Clean up
fs:chdir("..")
fs:remove("newdir")
```

### Error Handling

```lua
-- Handle potential errors
local ok, err = pcall(function()
    local f = fs:open("nonexistent.txt", "r")
end)
if not ok then
    print("Error:", err)
end

-- Check EOF condition
local f = fs:open("data.txt", "r")
while true do
    local data, err = f:read(1024)
    if err == "EOF" then
        break
    elseif err then
        error("Read error: " .. tostring(err))
    end
    -- Process data
end
f:close()

-- Handle sync errors
local f = fs:open("important.txt", "w")
f:write("critical data")
local ok, err = f:sync()
if not ok then
    error("Failed to sync: " .. tostring(err))
end
f:close()
```
