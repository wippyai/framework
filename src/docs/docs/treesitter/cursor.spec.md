# Tree-sitter Cursor Specification

## Core Concepts

Cursors provide navigation through syntax trees. Each cursor:

- Maintains its current position in the tree
- Provides methods to move up/down/sideways
- Can inspect nodes at current position
- Is independent from other cursors on same tree

## Basic Usage

```lua
-- Create cursor at root node
local cursor = tree:walk()

-- Get current node
local node = cursor:current_node() -- Returns current node or nil

-- Get position info
local depth = cursor:current_depth()  -- How deep in tree
local field_name = cursor:current_field_name()  -- Field name if any
local field_id = cursor:current_field_id()  -- Field ID number
```

## Navigation

### Core Navigation

```lua
-- All return true/false for success
cursor:goto_parent()            -- Move up to parent
cursor:goto_first_child()       -- Move to first child
cursor:goto_last_child()        -- Move to last child  
cursor:goto_next_sibling()      -- Move to next sibling
cursor:goto_previous_sibling()  -- Move to previous sibling
```

### Advanced Navigation

```lua
-- Move to descendant by index
cursor:goto_descendant(index)  -- Moves to specific index

-- Position-based navigation
local index = cursor:goto_first_child_for_byte(byte_offset)
local index = cursor:goto_first_child_for_point({
    row = number,
    column = number
})
-- Both return child index or nil if not found
```

## State Management

```lua
-- Copy cursor (creates independent cursor at same position)
local new_cursor = cursor:copy()

-- Reset cursor position
cursor:reset(node)              -- Reset to specific node
cursor:reset_to(other_cursor)   -- Reset to match other cursor's position

-- Clean up
cursor:close()  -- Free resources (optional, happens on GC)
```

## Common Patterns

1. Basic Tree Walking

```lua
local function walk_tree(cursor)
    local node = cursor:current_node()
    print(node:kind())  -- Process current node
    
    if cursor:goto_first_child() then
        walk_tree(cursor)
        cursor:goto_parent()
    end
    
    if cursor:goto_next_sibling() then
        walk_tree(cursor)
    end
end

local cursor = tree:walk()
walk_tree(cursor)
```

2. Finding Nodes

```lua
local function find_node(cursor, kind)
    if cursor:current_node():kind() == kind then
        return cursor:current_node()
    end
    
    if cursor:goto_first_child() then
        local result = find_node(cursor, kind)
        cursor:goto_parent()
        if result then return result end
    end
    
    if cursor:goto_next_sibling() then
        return find_node(cursor, kind)
    end
    
    return nil
end
```

## Best Practices

1. Navigation
    - Always check return values of navigation methods
    - Use goto_parent() to restore position after descending
    - Cache current_node() results if reusing

2. Resource Management
    - Use copy() for independent traversal paths
    - Reuse cursors when possible
    - close() not required but good practice

3. Error Handling
    - Navigation methods return false on failure
    - Current position maintained on failed moves
    - Verify cursor after tree modifications