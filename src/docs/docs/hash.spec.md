# Lua Hash Module Specification

## Overview

The `hash` module provides a set of functions for calculating various cryptographic and non-cryptographic hash values of strings. It includes implementations of MD5, SHA-1, SHA-256, SHA-512, FNV-1 32-bit, and FNV-1 64-bit hash algorithms.

## Module Interface

### Module Loading

```lua
local hash = require("hash")
```

### Global Functions

#### hash.md5(str: string, raw: boolean?)

Calculates the MD5 hash of a string.

Parameters:

- `str`: The string to hash.
- `raw`: (Optional) If true, returns the raw binary digest instead of hexadecimal string. Default is false.

Returns:

- `digest`: The hash digest, either as a hexadecimal string or raw binary data (or nil on error).
- `error`: Error message string (or nil on success).

#### hash.sha1(str: string, raw: boolean?)

Calculates the SHA-1 hash of a string.

Parameters:

- `str`: The string to hash.
- `raw`: (Optional) If true, returns the raw binary digest instead of hexadecimal string. Default is false.

Returns:

- `digest`: The hash digest, either as a hexadecimal string or raw binary data (or nil on error).
- `error`: Error message string (or nil on success).

#### hash.sha256(str: string, raw: boolean?)

Calculates the SHA-256 hash of a string.

Parameters:

- `str`: The string to hash.
- `raw`: (Optional) If true, returns the raw binary digest instead of hexadecimal string. Default is false.

Returns:

- `digest`: The hash digest, either as a hexadecimal string or raw binary data (or nil on error).
- `error`: Error message string (or nil on success).

#### hash.sha512(str: string, raw: boolean?)

Calculates the SHA-512 hash of a string.

Parameters:

- `str`: The string to hash.
- `raw`: (Optional) If true, returns the raw binary digest instead of hexadecimal string. Default is false.

Returns:

- `digest`: The hash digest, either as a hexadecimal string or raw binary data (or nil on error).
- `error`: Error message string (or nil on success).

#### hash.fnv32(str: string)

Calculates the FNV-1 32-bit hash of a string.

Parameters:

- `str`: The string to hash.

Returns:

- `value`: The 32-bit FNV-1 hash value as a number (or nil on error).
- `error`: Error message string (or nil on success).

#### hash.fnv64(str: string)

Calculates the FNV-1 64-bit hash of a string.

Parameters:

- `str`: The string to hash.

Returns:

- `value`: The 64-bit FNV-1 hash value as a number (or nil on error).
- `error`: Error message string (or nil on success).

## Error Handling

The module functions return errors in the following cases:

1. **Invalid Input Type:** If the input to any hash function is not a string.

    ```lua
    local digest, err = hash.md5(123)  -- digest: nil, err: "string expected"
    ```

2. **Internal Errors:** If an error occurs during the hash computation, the function will return `nil` and an error
   message.

## Behavior

1. **Hash Output:**
   - `md5`, `sha1`, `sha256`, and `sha512` return the hash digest as a hexadecimal string by default.
   - When the `raw` parameter is set to `true`, these functions return the raw binary digest instead.
   - `fnv32` and `fnv64` return the hash value as a Lua number.

2. **Raw Binary Output:**
   - MD5: Returns a 16-byte binary string
   - SHA-1: Returns a 20-byte binary string
   - SHA-256: Returns a 32-byte binary string
   - SHA-512: Returns a 64-byte binary string

3. **Error Handling**
   - Lua's `pcall` can be used to catch errors that occur.

## Thread Safety

- The `hash` module is designed to be thread-safe.
- It does not maintain any internal state that could be affected by concurrent access.

## Best Practices

1. **Always check for errors:** Always check the returned `error` value to handle potential errors.
2. **Validate input:** Ensure that the input to the hash functions is of the correct type (string) before calling them.
3. **Use appropriate hash function:** Choose the hash function that best suits your needs in terms of security and performance.
4. **Binary vs Hex:** Use raw binary output when working with other binary data or for more efficient storage. Use hex output for human-readable representations.

## Example Usage

```lua
local hash = require("hash")

-- Calculate MD5 hash (hex format)
local digest, err = hash.md5("Hello, world!")
if err then
  print("MD5 Error:", err)
else
  print("MD5 (hex):", digest) -- Output: MD5 (hex): 65a8e27d8879283831b664bd8b7f0ad4
end

-- Calculate MD5 hash (binary format)
local digest_bin, err = hash.md5("Hello, world!", true)
if err then
  print("MD5 Binary Error:", err)
else
  print("MD5 (binary) length:", #digest_bin) -- Output: MD5 (binary) length: 16
end

-- Calculate SHA-256 hash (hex format)
local digest, err = hash.sha256("Hello, world!")
if err then
  print("SHA-256 Error:", err)
else
  print("SHA-256 (hex):", digest) -- Output: SHA-256 (hex): 315f5bdb76d078c43b8ac0064e4a0164612b1fce77c869345bfc94c75894edd3
end

-- Calculate SHA-256 hash (binary format)
local digest_bin, err = hash.sha256("Hello, world!", true)
if err then
  print("SHA-256 Binary Error:", err)
else
  print("SHA-256 (binary) length:", #digest_bin) -- Output: SHA-256 (binary) length: 32
end

-- Calculate FNV-1 32-bit hash
local value, err = hash.fnv32("Hello, world!")
if err then
  print("FNV32 Error:", err)
else
  print("FNV32:", value) -- Output: FNV32: <a number>
end

-- Binary output example for cryptographic operations
local code_verifier = "BoocIEyqWI-m4uYi006AMyea8C8eue486eoasqcEyqMK6Y0eMOcCAWCkW8a266gq"
local challenge = hash.sha256(code_verifier, true)  -- Raw binary output
local base64_challenge = require("base64").encode(challenge)  -- Encoding binary output as base64
print("Base64 Challenge:", base64_challenge)
```