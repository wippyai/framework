# Tree-sitter Tree Specification

## Core Usage

```lua
-- Get tree from parser
local tree = parser:parse(code)

-- Get root node
local root = tree:root_node()  -- Returns node or raises error if tree closed

-- Create cursor for traversal
local cursor = tree:walk()     -- Returns cursor or raises error if tree closed

-- Clean up
tree:close()                   -- Free resources explicitly
```

## Tree Modification

### Edit Operations

```lua
-- Apply edit to tree
local edit = {
    start_byte = number,      -- Start position in bytes
    old_end_byte = number,    -- Old end position in bytes
    new_end_byte = number,    -- New end position in bytes
    start_row = number,       -- Starting row (0-based)
    start_column = number,    -- Starting column
    old_end_row = number,     -- Old ending row
    old_end_column = number,  -- Old ending column
    new_end_row = number,     -- New ending row
    new_end_column = number   -- New ending column
}

local ok, err = tree:edit(edit)  -- Returns true/false, error message
```

### Comparing Trees

```lua
-- Get changed ranges between trees
local ranges = tree:changed_ranges(other_tree)
-- Returns array of ranges:
ranges = {
    {
        start_byte = number,
        end_byte = number,
        start_point = {row = number, column = number},
        end_point = {row = number, column = number}
    }
}

-- Get included ranges from parsing
local ranges = tree:included_ranges()
```

## Error Handling

```lua
-- Tree operations after close
local ok, err = pcall(function()
    local root = closed_tree:root_node()
end)
-- Error: "tree is closed"

-- Invalid edit ranges
local bad_edit = {
    start_byte = -1,  -- Invalid negative offset
    old_end_byte = 5,
    new_end_byte = 5,
    start_row = 0,
    start_column = 0,
    old_end_row = 0,
    old_end_column = 5,
    new_end_row = 0,
    new_end_column = 5
}
local ok, err = tree:edit(bad_edit)
-- Returns: false, "invalid byte position"

-- Check for syntax errors
if root:has_error() then
    -- Handle invalid syntax
end
```

## Common Operations

### Tree Management

```lua
-- Copy tree
local copy = tree:copy()  -- Independent copy

-- Get root with offset
local offset_root = tree:root_node_with_offset(
    byte_offset,
    {row = number, column = number}
)

-- Get language
local lang = tree:language()

-- Debug visualization
local dot_graph = tree:dot_graph()
```

### Incremental Parsing

```lua
-- Initial parse
local tree1 = parser:parse(old_code)

-- Apply edit
tree1:edit({
    start_byte = 5,
    old_end_byte = 9,
    new_end_byte = 12,
    start_row = 0,
    start_column = 5,
    old_end_row = 0,
    old_end_column = 9,
    new_end_row = 0,
    new_end_column = 12
})

-- Parse updated code using edited tree
local tree2 = parser:parse(new_code, tree1)

-- Get changes
local changes = tree1:changed_ranges(tree2)
```

## Best Practices

1. Resource Management
   ```lua
   -- Close trees when done
   local tree = parser:parse(code)
   -- Use tree...
   tree:close()  -- Explicit cleanup

   -- Copy for independent modifications
   local working_copy = tree:copy()
   working_copy:edit(some_edit)
   ```

2. Error Handling
   ```lua
   -- Check edit success
   local ok, err = tree:edit(edit)
   if not ok then
       -- Handle edit error
   end

   -- Protect closed tree operations
   local ok, err = pcall(function()
       tree:root_node()
   end)
   if not ok then
       -- Handle closed tree error
   end
   ```

3. Tree Editing
   ```lua
   -- Validate edit ranges
   local edit = {
       start_byte = start,
       old_end_byte = old_end,
       new_end_byte = new_end,
       start_row = row,
       start_column = col,
       old_end_row = old_row,
       old_end_column = old_col,
       new_end_row = new_row,
       new_end_column = new_col
   }
   assert(start_byte >= 0 and old_end_byte >= start_byte)
   ```