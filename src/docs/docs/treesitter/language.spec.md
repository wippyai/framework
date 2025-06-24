# Tree-sitter Language Specification

## Core Concepts

The Language module manages supported programming languages and provides access to their syntax features. Languages:

- Define what kinds of nodes can appear in the syntax tree
- Specify fields that nodes can have
- Maintain version information

## Supported Languages

```lua
-- Get supported languages
local langs = treesitter.supported_languages()

-- Available languages:
"go", "golang"        -- Go
"js", "javascript"    -- JavaScript
"ts", "typescript"    -- TypeScript
"tsx"                 -- TypeScript + JSX
"python", "py"        -- Python
"php"                 -- PHP
"html", "html5"       -- HTML
"csharp", "c#", "cs"  -- C#
"lua"                 -- Lua
```

## Basic Usage

```lua
-- Get language info from tree
local tree = treesitter.parse("go", "package main")
local lang = tree:language()

-- Get version
local version = lang:version()  -- Returns version number

-- Get node kind information
local kind_count = lang:node_kind_count()  -- Total number of node types
local kind_name = lang:node_kind_for_id(id)  -- Get name for node type ID
local kind_id = lang:id_for_node_kind(name, is_named)  -- Get ID for node type
local is_named = lang:node_kind_is_named(id)  -- Check if node type is named

-- Get field information
local field_count = lang:field_count()  -- Total number of fields
local field_name = lang:field_name_for_id(id)  -- Get name for field ID
local field_id = lang:field_id_for_name(name)  -- Get ID for field name

-- Get parse state count
local state_count = lang:parse_state_count()
```

## Common Fields

Most languages share these field names:

```lua
"name"       -- Identifiers (e.g., function names)
"type"       -- Type annotations
"body"       -- Function/block bodies
"condition"  -- Conditional expressions
"left"       -- Left side of binary operations
"right"      -- Right side of binary operations
"arguments"  -- Function call arguments
```

## Error Handling

```lua
-- Invalid language name
local ok, err = pcall(function()
    treesitter.parse("invalid", "code")
end)
-- Raises error: "language 'invalid' not found"

-- Language operations return nil for invalid IDs
local invalid_name = lang:field_name_for_id(65535)  -- Returns empty string
local invalid_id = lang:field_id_for_name("nonexistent")  -- Returns 0
```

## Best Practices

1. Language Selection
   ```lua
   -- Use standard language identifiers
   treesitter.parse("go", code)     -- Good
   treesitter.parse("golang", code)  -- Also works
   ```

2. Field Access
   ```lua
   -- Check field existence
   local field_id = lang:field_id_for_name("name")
   if field_id > 0 then
       -- Field exists
   end
   ```

3. Node Kind Usage
   ```lua
   -- Get node type info
   local kind_id = lang:id_for_node_kind("function_declaration", true)
   local is_named = lang:node_kind_is_named(kind_id)
   ```