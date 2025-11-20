# Lua WebSocket Client Module Specification

## Overview

The `websocket` module provides a client-side WebSocket implementation for Lua that integrates seamlessly with our Wippy
coroutine VM and channel system. It leverages a thread context automatically behind the scenes and exposes a clean,
idiomatic API for establishing connections, sending/receiving messages, and managing connection lifecycles.

Library automatically handles ping requests.

---

## Module Interface

Since the module is globally available, you can directly use the WebSocket functionality without an explicit `require`
call.

## Constants

### Message Types

```lua
websocket.TYPE_TEXT    = "text"    -- Text frame
websocket.TYPE_BINARY  = "binary"  -- Binary frame
websocket.TYPE_PING    = "ping"    -- Ping control frame
websocket.TYPE_PONG    = "pong"    -- Pong control frame
websocket.TYPE_CLOSE   = "close"   -- Close control frame
```

### Close Status Codes

```lua
websocket.CLOSE_CODES = {
    NORMAL              = 1000,  -- Normal closure
    GOING_AWAY          = 1001,  -- Going away (endpoint shutting down)
    PROTOCOL_ERROR      = 1002,  -- Protocol error
    UNSUPPORTED_DATA    = 1003,  -- Unsupported data type
    RESERVED            = 1004,  -- Reserved
    NO_STATUS           = 1005,  -- No status received
    ABNORMAL_CLOSURE    = 1006,  -- Abnormal closure
    INVALID_PAYLOAD     = 1007,  -- Invalid frame payload data
    POLICY_VIOLATION    = 1008,  -- Policy violation
    MESSAGE_TOO_BIG     = 1009,  -- Message too large
    MANDATORY_EXTENSION = 1010,  -- Mandatory extension missing
    INTERNAL_ERROR      = 1011,  -- Internal server error
    SERVICE_RESTART     = 1012,  -- Service restart
    TRY_AGAIN_LATER    = 1013,  -- Try again later (temporary)
    BAD_GATEWAY        = 1014,  -- Bad gateway
    TLS_HANDSHAKE      = 1015   -- TLS handshake failure
}
```

---

## Global Functions

### `websocket.connect(url: string, options?: table)`

**Description:**  
Establishes a WebSocket connection to the given URL.

**Parameters:**

- **`url`** (string): The WebSocket URL (e.g., `"ws://example.com/socket"` or `"wss://..."`).
- **`options`** (table, optional): A table with connection options:
    - **`headers`** (table): Additional HTTP headers.
    - **`protocols`** (array): List of sub-protocols to request.
    - **`dial_timeout`** (number|string): Timeout for the initial connection (milliseconds if number, or duration
      string, e.g., `"5s"`).
    - **`read_timeout`** (number|string): Timeout for read operations (e.g., `"30s"`).
    - **`write_timeout`** (number|string): Timeout for write operations (e.g., `"10s"`).

**Returns:**

- **On success:** A WebSocket client object (userdata) with instance methods.
- **On failure:** `nil` and an error message string.

**Example:**

```lua
local client, err = websocket.connect("ws://example.com/socket", {
    headers = { ["User-Agent"] = "Lua WebSocket Client" },
    dial_timeout = "5s",
    read_timeout = "30s",
    write_timeout = "10s"
})
if not client then
    error("Connection failed: " .. tostring(err))
end
```

---

## WebSocket Client Object Methods

Once connected, the returned client object provides the following methods:

### `client:send(data: string)`

**Description:**  
Sends a text message over the WebSocket connection.

**Parameters:**

- **`data`** (string): The text message to send.

**Returns:**

- `true` on success, or `false` and an error message if sending fails.

**Example:**

```lua
local ok, err = client:send("Hello, WebSocket!")
if not ok then
    print("Send failed:", err)
end
```

---

### `client:close(code?: number, reason?: string)`

**Description:**  
Gracefully closes the WebSocket connection. Will close receive channel if such exists.

**Parameters:**

- **`code`** (number, optional): The close status code (default is websocket.CLOSE_CODES.NORMAL).
- **`reason`** (string, optional): A reason for closing.

**Returns:**

- `true` on success, or `false` and an error message if closing fails.

**Example:**

```lua
local ok, err = client:close(websocket.CLOSE_CODES.NORMAL, "Goodbye")
if not ok then
    print("Close error:", err)
end
```

---

### `client:receive()`

**Description:**  
Returns a channel object dedicated to receiving messages from the WebSocket. Internally, a goroutine reads from the
connection and pushes incoming messages into this channel.

**Returns:**

- A channel object that emits message tables.

**Channel Message Format:**

Each message received via the channel is a table structured as follows:

```lua
{
    type = websocket.TYPE_TEXT | websocket.TYPE_BINARY | websocket.TYPE_PING | 
           websocket.TYPE_PONG | websocket.TYPE_CLOSE,
    data = string,  -- Message payload
    code = number,  -- For close messages (optional)
    reason = string -- For close messages (optional)
}
```

**Example:**

```lua
local ch = client:receive()
coroutine.spawn(function()
    while true do
        local msg, ok = ch:receive()
        if not ok then
            print("Connection closed or error occurred")
            break
        end

        if msg.type == websocket.TYPE_TEXT then
            print("Received text:", msg.data)
        elseif msg.type == websocket.TYPE_CLOSE then
            print("Server closed connection:", msg.code, msg.reason)
            break
        end
    end
end)
```

---

## Error Handling

The module returns errors in cases such as:

1. Connection failures (e.g., invalid URL, network issues)
2. Protocol errors
3. Timeouts during dialing or message exchange
4. Invalid message types or operations

Each function returns an error message string on failure that should be checked by the caller.

---

## Concurrency and Thread Safety

- **Safe for Multiple Coroutines:** All operations are designed to be safe when called from different coroutines.
- **Internal State Management:** The module manages the connection state internally.
- **Synchronized Sends:** Concurrent send operations are automatically synchronized.
- **Channel-Based Receives:** The receive channel uses our runtime's channel system, ensuring asynchronous delivery of
  messages. The channel is automatically closed once the connection terminates.

---

## Best Practices

1. **Error Checking:** Always verify return values from `connect`, `send`, and other methods.
2. **Coroutines for Receives:** Use coroutines (or select operations) to process incoming messages from the receive
   channel.
3. **Graceful Shutdown:** Use `client:close()` to close connections and free associated resources.
4. **Timeout Management:** Set appropriate timeouts (dial, read, write, ping, pong) to prevent indefinite blocking.
5. **Message Handling:** Check the `type` field of received messages to handle text, binary, or control frames (like
   close) appropriately.
6. **Use Constants:** Always use the provided constants for message types and close codes instead of magic numbers or
   strings.

---

## Complete Example Usage

```lua
-- Connect to the WebSocket server
local client, err = websocket.connect("ws://example.com/socket", {
    headers = { ["User-Agent"] = "Lua WebSocket Client" },
    dial_timeout = "5s",
    read_timeout = "30s",
    write_timeout = "10s",
    ping_interval = "15s",
    pong_timeout = "20s"
})
if not client then
    error("Connection failed: " .. tostring(err))
end

-- Start a receive loop in a coroutine
coroutine.spawn(function()
    local ch = client:receive()
    while true do
        local msg, ok = ch:receive()
        if not ok then
            print("Connection closed")
            break
        end

        if msg.type == websocket.TYPE_TEXT then
            print("Received:", msg.data)
        elseif msg.type == websocket.TYPE_CLOSE then
            print("Server closed connection:", msg.code, msg.reason)
            break
        elseif msg.type == websocket.TYPE_PING then
            -- Library handles pings automatically, but you can still observe them
            print("Received ping")
        end
    end
end)

-- Send a message
local ok, err = client:send("Hello")
if not ok then
    print("Send failed:", err)
end

-- Later, gracefully close the connection
client:close(websocket.CLOSE_CODES.NORMAL, "Goodbye")
```

---

This complete spec includes all WebSocket message type constants and close codes, uses the global context automatically
behind the scenes, and provides fine-grained timeout controls that align with idiomatic patterns.
