# Lua JSON Module Specification

## Overview

The `json` module provides functions for encoding Lua values into JSON (JavaScript Object Notation) strings and decoding
JSON strings into Lua values. It handles basic Lua types (strings, numbers, booleans, nil) as well as tables used as
arrays or objects.

## Module Interface

### Module Loading

```lua
local json = require("json")
```

### Global Functions

#### json.encode(value: any)

Encodes a Lua value into a JSON string.

Parameters:

- `value`: The Lua value to encode.

Returns:

- `encoded`: The JSON string representation of the value (or nil on error).
- `error`: Error message string (or nil on success).

#### json.decode(str: string)

Decodes a JSON string into a Lua value.

Parameters:

- `str`: The JSON string to decode.

Returns:

- `decoded`: The Lua value represented by the JSON string (or nil on error).
- `error`: Error message string (or nil on success).

## Error Handling

The module functions may return errors in the following cases:

1. **Invalid Input Type (Encoding):** If the input to `encode` is not a valid Lua type for JSON encoding (nil, boolean,
   number, string, table).

    ```lua
    local encoded, err = json.encode(function() end) -- encoded: nil, err: "cannot encode function to JSON"
    ```

2. **Invalid JSON String (Decoding):** If the input to `decode` is not a valid JSON string.

    ```lua
    local decoded, err = json.decode("invalid json") -- decoded: nil, err: specific JSON parsing error message
    ```
3. **Empty String (Decoding):** If the input to `decode` is an empty string

    ```lua
    local decoded, err = json.decode("") -- decoded: nil, err: "empty string is not valid JSON"
    ```

4. **Recursively Nested Tables (Encoding):** If a table to be encoded contains itself, directly or indirectly.

    ```lua
    local t = {}
    t.x = t
    local encoded, err = json.encode(t) -- encoded: nil, err: "cannot encode recursively nested tables to JSON"
    ```

5. **Sparse Arrays (Encoding):** If a table used as an array has non-sequential numeric keys (e.g., missing index 2).

    ```lua
    local t = {1, [3] = 3}
    local encoded, err = json.encode(t) -- encoded: nil, err: "cannot encode sparse array"
    ```

6. **Mixed or Invalid Key Types (Encoding):** If a table used as an object has mixed key types (e.g., both numbers and
   strings) or invalid key types (e.g., booleans).

    ```lua
    local t = {[1] = 1, ["key"] = 2}
    local encoded, err = json.encode(t) -- encoded: nil, err: "cannot encode mixed or invalid key types"
    ```

## Behavior

### Encoding

1. **Basic Types:**
    - `nil` is encoded as `null`.
    - Booleans are encoded as `true` or `false`.
    - Numbers are encoded as JSON numbers (integers or floating-point).
    - Strings are encoded as JSON strings, with proper escaping.

2. **Tables:**
    - Tables used as **arrays** (sequential numeric keys starting from 1) are encoded as JSON arrays.
    - Tables used as **objects** (string keys) are encoded as JSON objects.
    - Nested tables are supported, as long as they are not recursive.

### Decoding

1. **JSON Types to Lua Types:**
    - `null` is decoded as `nil`.
    - `true` and `false` are decoded as booleans.
    - Numbers are decoded as Lua numbers.
    - Strings are decoded as Lua strings.
    - Arrays are decoded as Lua tables with sequential numeric keys starting from 1.
    - Objects are decoded as Lua tables with string keys.

## Thread Safety

- The `json` module is designed to be thread-safe in common cases.
- Encoding and decoding operations do not share any mutable state.
- However, if you are modifying a table while encoding it from another thread, the behavior is undefined.

## Best Practices

1. **Always check for errors:** Check the returned `error` value from both `encode` and `decode`.
2. **Validate input:** Ensure the input to `encode` is a valid Lua type, and the input to `decode` is a valid JSON
   string.
3. **Avoid recursive tables:** Do not attempt to encode tables that contain themselves.
4. **Use tables consistently:** When encoding, use tables either as arrays (sequential numeric keys) or objects (string
   keys), but not both.
5. **Handle empty arrays and objects:** Be aware that empty tables can be encoded as either `[]` or `{}` depending on
   how they are used.

## Example Usage

```lua
local json = require("json")

-- Encode a Lua table
local myTable = {
  name = "John Doe",
  age = 30,
  city = "New York",
  hobbies = {"reading", "coding", "hiking"}
}
local encoded, err = json.encode(myTable)
if err then
  print("Encoding error:", err)
else
  print("Encoded:", encoded)
  -- Output: Encoded: {"name":"John Doe","age":30,"city":"New York","hobbies":["reading","coding","hiking"]}
end

-- Decode a JSON string
local jsonString = '{"name":"Jane Doe","age":25,"city":"Los Angeles","active":true}'
local decoded, err = json.decode(jsonString)
if err then
  print("Decoding error:", err)
else
  print("Decoded name:", decoded.name) -- Output: Decoded name: Jane Doe
  print("Decoded age:", decoded.age)  -- Output: Decoded age: 25
end

-- Handle errors
local invalidJson = "invalid json"
local decoded, err = json.decode(invalidJson)
if err then
  print("Error:", err) -- Output: Error: specific JSON parsing error message
end

-- Round trip
local original = {a = 1, b = {c = true, d = {2, 3}}}
local encoded = json.encode(original)
local decoded, err = json.decode(encoded)
if err then
    print("Round trip error:", err)
else
    print("Original a:", original.a)
    print("Decoded a:", decoded.a)
    print("Original b.c:", original.b.c)
    print("Decoded b.c:", decoded.b.c)
end
```
