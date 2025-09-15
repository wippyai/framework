# Lua Stream Module Specification

## Overview

The `Stream` module provides a Lua interface for reading data from streams. It supports chunk-based reading and token-based scanning with configurable delimiters.

## Module Interface

### Module Loading

```lua
local Stream = require("stream")
```

## Stream Object

Stream objects represent readable data sources and are created externally, not directly from Lua.

### Stream:read([size])

Reads a chunk of data from the stream.

**Parameters:**
- `size` (optional number): Maximum bytes to read. Default: 32KB.

**Returns:**
- On success: `string` (data), `nil`
- On EOF: `nil`
- On error: `nil`, `string` (error message)

**Behavior:**
- In coroutine VMs: yields if no data available, resumes when ready
- In sync VMs: blocks until data available or error/EOF

### Stream:close()

Closes the stream and releases resources.

**Returns:**
- On success: `true`
- On error: `nil`, `string` (error message)

### Stream:bytes_read()

Returns total bytes read from stream since creation.

**Returns:**
- `number`: Cumulative bytes read

### Stream:scanner([split_type])

Creates a Scanner for token-based reading.

**Parameters:**
- `split_type` (optional string): Token delimiter type
    - `"lines"` (default): Split on newlines
    - `"words"`: Split on whitespace
    - `"bytes"`: Split on individual bytes
    - `"runes"`: Split on UTF-8 runes

**Returns:**
- `Scanner` object

**Errors:**
- Raises error if split_type is invalid

### Stream.__call([size])

Iterator for chunk-based reading in for loops.

**Parameters:**
- `size` (optional number): Chunk size per iteration. Default: 32KB.

**Returns:**
- Iterator function that returns next chunk or `nil` on EOF/error

## Scanner Object

Scanner provides token-based reading using Go's bufio.Scanner semantics.

### Scanner:scan()

Advances to next token.

**Returns:**
- `boolean`: `true` if token available, `false` on EOF or error

**Behavior:**
- In coroutine VMs: yields if no complete token available
- In sync VMs: blocks until token ready or EOF/error
- After returning `false`, use `err()` to distinguish EOF from error

### Scanner:text()

Returns current token text.

**Returns:**
- `string`: Token text from last successful `scan()` call

**Behavior:**
- Only valid after `scan()` returns `true`
- Text buffer may be overwritten by subsequent `scan()` calls

### Scanner:err()

Returns first non-EOF error encountered.

**Returns:**
- `nil`: No error (including EOF)
- `string`: Error message

## Lifecycle and Resource Management

**Stream Lifecycle:**
- Streams are created externally with UnitOfWork integration
- Closing stream automatically stops associated scanners
- UnitOfWork cleanup automatically closes unclosed streams

**Scanner Lifecycle:**
- Scanners follow underlying stream lifecycle
- No explicit close method - cleanup handled by stream
- Multiple scanners can be created from same stream

## Async Behavior

**Coroutine VMs:**
- `stream:read()` and `scanner:scan()` are non-blocking
- Operations yield when waiting for data
- Resume when data available or EOF/error occurs

**Sync VMs:**
- All operations block until completion
- No yielding behavior

## Error Handling

**Stream Errors:**
- Context cancellation propagated as error
- IO errors wrapped with descriptive messages
- EOF distinguished from errors in return values

**Scanner Errors:**
- Split configuration errors raised immediately
- Reading errors available via `err()` method
- EOF is not considered an error
