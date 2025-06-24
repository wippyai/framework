# Lua Base64 Module Specification

## Overview

The `base64` module provides functions for encoding and decoding data using the Base64 encoding scheme. It allows Lua
code to easily convert strings to and from their Base64 representations.

## Module Interface

### Module Loading

```lua
local base64 = require("base64")
```

### Global Functions

#### base64.encode(str: string)

Encodes a string using the Base64 encoding.

Parameters:

- `str`: The string to encode.

Returns:

- `encoded`: The Base64 encoded string.
- `error`: Error message string (or nil on success).

#### base64.decode(encoded: string)

Decodes a Base64 encoded string.

Parameters:

- `encoded`: The Base64 encoded string to decode.

Returns:

- `decoded`: The decoded string.
- `error`: Error message string (or nil on success).

### Error Handling

The module returns errors in the following cases:

1. **Invalid Input Type:** If the input to `encode` or `decode` is not a string.

    ```lua
    local encoded = base64.encode(123)  -- Returns nil, error: "string expected"
    local decoded = base64.decode(true) -- Returns nil, error: "string expected"
    ```

2. **Invalid Base64 String:** If the input to `decode` is not a valid Base64 string.

    ```lua
    local decoded, err = base64.decode("invalid!base64") -- decoded: nil, err: specific error message from base64 library
    ```

## Behavior

1. **Encoding:**
    - The `encode` function takes any string as input.
    - It returns the Base64 encoded representation of the input string.
    - Empty strings are valid input and result in an empty string output.

2. **Decoding:**
    - The `decode` function takes a Base64 encoded string as input.
    - It returns the decoded string if the input is valid.
    - Empty strings are valid input and result in an empty string output.
    - If the input is not a valid Base64 string, it returns `nil` and an error message.

## Thread Safety

- The `base64` module is designed to be thread-safe.
- It does not maintain any internal state that could be affected by concurrent access.

## Best Practices

1. **Always check for errors:** When using `decode`, always check the returned `error` value to handle potential
   decoding failures.
2. **Validate input:** Ensure that the input to `encode` and `decode` is of the correct type (string) before calling the
   function.
3. **Handle empty strings:** Be aware that empty strings are valid input and will result in empty string output for both
   `encode` and `decode`.

## Example Usage

```lua
local base64 = require("base64")

-- Encode a string
local encoded = base64.encode("Hello, world!")
print("Encoded:", encoded) -- Output: Encoded: SGVsbG8sIHdvcmxkIQ==

-- Decode a string
local decoded, err = base64.decode(encoded)
if err then
  print("Error decoding:", err)
else
  print("Decoded:", decoded) -- Output: Decoded: Hello, world!
end

-- Handle invalid input
local decoded, err = base64.decode("invalid base64")
if err then
  print("Decoding error:", err) -- Output: Decoding error: <specific error message>
end

-- Encode and decode an empty string
local encodedEmpty = base64.encode("")
print("Encoded empty string:", encodedEmpty) -- Output: Encoded empty string:
local decodedEmpty, err = base64.decode(encodedEmpty)
if err then
    print("Error decoding empty string:", err)
else
    print("Decoded empty string:", decodedEmpty) -- Output: Decoded empty string:
end
```
