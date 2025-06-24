# Lua YAML Module Specification

## Overview

The `yaml` module provides functions for encoding Lua tables into YAML (YAML Ain't Markup Language) strings and decoding
YAML strings into Lua tables. It handles nested structures and preserves multiline strings using the literal style for
better readability. The module supports advanced formatting options including customizable indentation, field ordering,
and different style options for various YAML node types.

## Module Interface

### Module Loading

```lua
local yaml = require("yaml")
```

### Global Functions

#### yaml.encode(value: table[, options: table])

Encodes a Lua table into a YAML string.

Parameters:

- `value`: The Lua table to encode.
- `options` (optional): A table of formatting and encoding options. See "Formatting Options" below.

Returns:

- `encoded`: The YAML string representation of the table (or nil on error).
- `error`: Error message string (or nil on success).

#### yaml.decode(str: string)

Decodes a YAML string into a Lua table.

Parameters:

- `str`: The YAML string to decode.

Returns:

- `decoded`: The Lua table represented by the YAML string (or nil on error).
- `error`: Error message string (or nil on success).

## Formatting Options

The `options` table passed to `yaml.encode()` can include the following fields:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `indent` | number | 2 | Number of spaces to use for indentation |
| `field_order` | table | {} | List of field names in the desired order |
| `sort_unordered` | boolean | false | Sort fields not in `field_order` alphabetically |
| `scalar_style` | string | "" | Style for scalar values: `"plain"`, `"single"`, `"double"`, `"literal"`, `"folded"` |
| `mapping_style` | string | "" | Style for mappings: `"flow"`, `"block"` |
| `sequence_style` | string | "" | Style for sequences: `"flow"`, `"block"` |
| `compact_sequences` | boolean | false | Use flow style for short sequences |
| `compact_sequence_limit` | number | 5 | Maximum items for a sequence to be considered "short" |
| `compact_nested_sequences` | boolean | true | Apply compact style to sequences inside other structures |
| `emit_defaults` | boolean | true | Emit zero/default values |

## Error Handling

The module functions may return errors in the following cases:

1. **Missing Input:** If no input is provided to `encode` or `decode`.

    ```lua
    local encoded, err = yaml.encode() -- encoded: nil, err: "missing input table"
    local decoded, err = yaml.decode() -- decoded: nil, err: "missing input YAML string"
    ```

2. **Invalid Input Type (Encoding):** If the input to `encode` is not a table.

    ```lua
    local encoded, err = yaml.encode("not a table") -- encoded: nil, err: "first argument must be a table"
    ```

3. **Invalid YAML String (Decoding):** If the input to `decode` is not a valid YAML string.

    ```lua
    local decoded, err = yaml.decode("this is not valid yaml: :") -- decoded: nil, err: specific YAML parsing error message
    ```

4. **Empty String (Decoding):** If the input to `decode` is an empty string.

    ```lua
    local decoded, err = yaml.decode("") -- decoded: nil, err: "first argument must be a string"
    ```

## Behavior and Style Options

### Indentation

Controls the number of spaces used for indentation:

```lua
local data = {
  nested = {
    deep = "value"
  }
}

-- Default 2-space indentation
local yaml_default, err = yaml.encode(data)
print(yaml_default)
-- Output:
-- nested:
--   deep: value

-- Custom 4-space indentation
local yaml_custom, err = yaml.encode(data, {indent = 4})
print(yaml_custom)
-- Output:
-- nested:
--     deep: value
```

### Field Ordering

Orders fields based on their position in the `field_order` list:

```lua
local data = {
  c_field = "third",
  a_field = "first",
  b_field = "second"
}

-- Without field ordering (order may be unpredictable)
local yaml_default, err = yaml.encode(data)

-- With field ordering
local yaml_ordered, err = yaml.encode(data, {
  field_order = {"a_field", "b_field", "c_field"}
})
print(yaml_ordered)
-- Output:
-- a_field: first
-- b_field: second
-- c_field: third
```

### Alphabetical Sorting

Sorts fields not in `field_order` alphabetically:

```lua
local data = {
  version = "1.0",
  z_field = "last",
  a_field = "first",
  m_field = "middle"
}

-- With field ordering and alphabetical sorting
local yaml_sorted, err = yaml.encode(data, {
  field_order = {"version"},  -- version comes first
  sort_unordered = true       -- rest is alphabetical
})
print(yaml_sorted)
-- Output:
-- version: "1.0"
-- a_field: first
-- m_field: middle
-- z_field: last
```

### Scalar Style Options

Controls how scalar values are rendered:

```lua
local data = {
  plain = "value",
  multiline = "This is a\nmultiline string\nwith several lines"
}

-- Default (automatic style selection)
local yaml_default, err = yaml.encode(data)
print(yaml_default)
-- Output:
-- multiline: |-
--   This is a
--   multiline string
--   with several lines
-- plain: value

-- Literal style for all scalars
local yaml_literal, err = yaml.encode(data, {scalar_style = "literal"})
print(yaml_literal)
-- Output:
-- multiline: |-
--   This is a
--   multiline string
--   with several lines
-- plain: |-
--   value

-- Double quoted style
local yaml_quoted, err = yaml.encode(data, {scalar_style = "double"})
print(yaml_quoted)
-- Output:
-- multiline: "This is a\nmultiline string\nwith several lines"
-- plain: "value"
```

Available scalar styles:
- `"plain"` - No quotes, most compact representation
- `"single"` - Single quoted strings ('like this')
- `"double"` - Double quoted strings ("like this")
- `"literal"` - Literal block style with pipe character (|)
- `"folded"` - Folded block style with greater-than character (>)

### Mapping Style Options

Controls how mapping (object) blocks are rendered:

```lua
local data = {
  nested = {
    a = 1,
    b = 2,
    c = 3
  }
}

-- Default block style
local yaml_block, err = yaml.encode(data)
print(yaml_block)
-- Output:
-- nested:
--   a: 1
--   b: 2
--   c: 3

-- Flow style (JSON-like)
local yaml_flow, err = yaml.encode(data, {mapping_style = "flow"})
print(yaml_flow)
-- Output:
-- {nested: {a: 1, b: 2, c: 3}}
```

### Sequence Style Options

Controls how sequence (array) blocks are rendered:

```lua
local data = {
  items = {"one", "two", "three"},
  longer_list = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
}

-- Default block style
local yaml_block, err = yaml.encode(data)
print(yaml_block)
-- Output:
-- items:
--   - one
--   - two
--   - three
-- longer_list:
--   - 1
--   - 2
--   ... etc.

-- Flow style (JSON-like)
local yaml_flow, err = yaml.encode(data, {sequence_style = "flow"})
print(yaml_flow)
-- Output:
-- items: [one, two, three]
-- longer_list: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
```

### Compact Sequences

Makes short sequences more compact by using flow style:

```lua
local data = {
  short_list = {1, 2, 3},
  medium_list = {1, 2, 3, 4, 5},
  longer_list = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
  nested = {
    inner_list = {1, 2, 3}
  }
}

-- Basic compact sequences option (default limit of 5)
local yaml_compact, err = yaml.encode(data, {compact_sequences = true})
print(yaml_compact)
-- Output:
-- longer_list:
--   - 1
--   - 2
--   ... etc.
-- medium_list: [1, 2, 3, 4, 5]
-- nested:
--   inner_list: [1, 2, 3]
-- short_list: [1, 2, 3]

-- Custom sequence length limit
local yaml_custom_limit, err = yaml.encode(data, {
  compact_sequences = true,
  compact_sequence_limit = 10  -- Consider sequences with 10 or fewer items as "short"
})
print(yaml_custom_limit)
-- Output:
-- longer_list: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
-- medium_list: [1, 2, 3, 4, 5]
-- nested:
--   inner_list: [1, 2, 3]
-- short_list: [1, 2, 3]

-- Disable compact style for nested sequences
local yaml_no_nested, err = yaml.encode(data, {
  compact_sequences = true,
  compact_nested_sequences = false  -- Only apply to top-level sequences
})
print(yaml_no_nested)
-- Output:
-- longer_list:
--   - 1
--   - 2
--   ... etc.
-- medium_list: [1, 2, 3, 4, 5]
-- nested:
--   inner_list:
--     - 1
--     - 2
--     - 3
-- short_list: [1, 2, 3]
```

## Thread Safety

- The `yaml` module is designed to be thread-safe in common cases.
- Encoding and decoding operations do not share any mutable state.
- However, if you are modifying a table while encoding it from another thread, the behavior is undefined.

## Best Practices

1. **Always check for errors:** Check the returned `error` value from both `encode` and `decode`.
2. **Validate input:** Ensure the input to `encode` is a valid Lua table, and the input to `decode` is a valid YAML string.
3. **Use appropriate styles:** Choose styles that enhance readability for your specific data:
    - Use `compact_sequences` for short arrays to make them more readable
    - Use `flow` style for mappings that are simple key-value pairs
    - Use `block` style for complex, nested structures
    - Use `literal` style for multiline strings (happens automatically by default)
4. **Consistent indentation:** Choose an indentation that matches your project's style guide, typically 2 or 4 spaces.
5. **Field ordering for clarity:** Order fields in a logical way, with key identifiers first:
    - Put identifiers like `name`, `version`, and `id` near the top
    - Group related fields together
    - Put large arrays and complex nested structures toward the end
6. **Enable alphabetical sorting for stable output:** When generating YAML that will be compared or version-controlled, enable the `sort_unordered` option to ensure stable, deterministic output.

## Complete Example

```lua
local yaml = require("yaml")

-- Create a complex data structure
local config = {
  version = "1.0",
  name = "My Application",
  settings = {
    timeout = 30,
    retry = 3,
    endpoints = {"api.example.com", "backup.example.com"}
  },
  users = {
    {id = 1, username = "admin", active = true},
    {id = 2, username = "guest", active = false}
  },
  description = [[
This is a sample configuration file
with multiple lines of description
that explains the purpose of this config.]]
}

-- Define formatting options for nice, readable output
local options = {
  indent = 2,                  -- 2-space indentation
  field_order = {              -- Logical field ordering
    "version", 
    "name", 
    "description", 
    "settings", 
    "users"
  },
  sort_unordered = true,       -- Sort remaining fields alphabetically
  compact_sequences = true,    -- Make short arrays more compact
  mapping_style = "block",     -- Use block style for objects (default)
  sequence_style = "block"     -- Use block style for arrays (default)
}

-- Generate YAML with the specified options
local yamlString, err = yaml.encode(config, options)
if err then
  print("Error:", err)
else
  print(yamlString)
  -- Output will be formatted according to the specified options
end

-- Parse the YAML back into a Lua table
local decoded, err = yaml.decode(yamlString)
if err then
  print("Decode error:", err)
else
  -- Access the decoded data
  print("App name:", decoded.name)
  print("First endpoint:", decoded.settings.endpoints[1])
end
```

Example output:

```yaml
version: "1.0"
name: My Application
description: |-
  This is a sample configuration file
  with multiple lines of description
  that explains the purpose of this config.
settings:
  endpoints: [api.example.com, backup.example.com]
  retry: 3
  timeout: 30
users:
  - active: true
    id: 1
    username: admin
  - active: false
    id: 2
    username: guest
```