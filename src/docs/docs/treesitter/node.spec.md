# Tree-sitter Node Specification

## Core Usage

### Basic Properties

```lua
-- Get node type
local kind = node:kind()  -- or node:type() (alias)
-- Raises error if node from closed tree

-- Check if node is named 
local is_named = node:is_named()
-- Raises error if node from closed tree

-- Get text content (IMPORTANT: requires source code)
local ok, text = pcall(function()
    return node:text(source_code)
end)
-- Raises errors:
-- - "source reference is empty" if no source provided
-- - "invalid byte range" if node positions outside source
-- - Tree closed errors
```

### Navigation

```lua
-- Parent-child navigation
local parent = node:parent()          -- Returns parent or nil
local child = node:child(0)           -- Returns child at index or nil
local count = node:child_count()      -- Number of children

-- Sibling navigation 
local next_sib = node:next_sibling()  -- Returns next sibling or nil
local prev_sib = node:prev_sibling()  -- Returns previous sibling or nil

-- Named nodes (excludes syntax tokens)
local named_child = node:named_child(0)
local named_count = node:named_child_count()
local next_named = node:next_named_sibling()
local prev_named = node:prev_named_sibling()
```

### Field Access

```lua
-- Get node by field name
local name_node = node:child_by_field_name("name")     -- Returns node or nil
local field = node:field_name_for_child(child_index)   -- Returns string or nil
```

## Error Handling

### Syntax Errors

```lua
-- Check if node or descendants have errors
local has_err = node:has_error()    -- true if any errors in subtree
local is_err = node:is_error()      -- true if this node is an error

-- Example handling syntax errors
local function check_syntax(node)
    if node:is_error() then
        local start = node:start_point()
        print(string.format("Error at line %d, column %d", 
            start.row + 1, start.column + 1))
        return false
    end
    return true
end
```

### Text Operations

```lua
-- Text access requires valid source code
local ok, text = pcall(function()
    return node:text(source_code)
end)
if not ok then
    -- Handle invalid byte range error
end

-- Common text errors:
-- - Missing source code string
-- - Invalid byte range (node positions outside source)
-- - Closed/invalid tree
```

### Node Positions

```lua
-- Get node positions
local start_byte = node:start_byte()    -- Returns byte offset
local end_byte = node:end_byte()        -- Returns byte offset

local start_point = node:start_point()  -- Returns {row=n, column=n}
local end_point = node:end_point()      -- Returns {row=n, column=n}
```

## Common Patterns

### Walking Child Nodes

```lua
-- Walk all children
for i = 0, node:child_count() - 1 do
    local child = node:child(i)
    -- Process child...
end

-- Walk only named nodes
for i = 0, node:named_child_count() - 1 do
    local child = node:named_child(i)
    -- Process named child...
end
```

### Finding Nodes By Type

```lua
local function find_nodes(node, target_type)
    local matches = {}
    
    if node:kind() == target_type then
        table.insert(matches, node)
    end
    
    for i = 0, node:child_count() - 1 do
        local child = node:child(i)
        local child_matches = find_nodes(child, target_type)
        for _, match in ipairs(child_matches) do
            table.insert(matches, match)
        end
    end
    
    return matches
end
```

### Safe Text Access

```lua
local function get_text_safe(node, source)
    if not node then return nil end
    
    -- Check valid range
    local start = node:start_byte()
    local end_pos = node:end_byte()
    if start < 0 or end_pos < 0 or
       start > end_pos or 
       end_pos > #source then
        return nil
    end
    
    local ok, text = pcall(function()
        return node:text(source)
    end)
    return ok and text or nil
end
```

## Additional Features

### Debug Information

```lua
-- Get node structure as S-expression 
local sexp = node:to_sexp()

-- Grammar information
local grammar = node:grammar_name()
local is_extra = node:is_extra()
local is_missing = node:is_missing()
```

### Descendant Operations

```lua
-- Count all descendants
local count = node:descendant_count()

-- Find named node at position
local node = node:named_descendant_for_point_range(
    {row = 1, column = 0},  -- Start point
    {row = 1, column = 10}  -- End point
)
```

## Best Practices

1. Error Handling
    - Always check for syntax errors when parsing
    - Use pcall around text() operations
    - Validate node positions before use

2. Text Access
    - Cache source code when processing multiple nodes
    - Always validate byte ranges
    - Handle missing/invalid text gracefully

3. Navigation
    - Check for nil before using child/sibling nodes
    - Use named_child for semantic elements
    - Cache frequently accessed nodes