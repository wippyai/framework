# Tree-sitter Query Specification

## Core Usage

```lua
-- Create query
local query = treesitter.query("go", "(function_declaration) @function")
-- Returns query object on success
-- Returns nil, error_message on failure

-- Execute query
local matches = query:matches(root_node, source_code)

-- Clean up
query:close()
```

## Query Syntax

### Basic Patterns

```scheme
; Single node capture
(identifier) @name

; Field capture
(function_declaration
  name: (identifier) @func_name)

; Multiple captures
(binary_expression
  left: (_) @left
  operator: (_) @op
  right: (_) @right)

; Optional nodes
(if_statement
  condition: (_) @cond
  consequence: (_) @then
  alternative: (_)? @else)  ; ? marks optional

; Nested captures
(function_declaration
  name: (identifier) @name
  parameters: (parameter_list
    (parameter_declaration 
      name: (identifier) @param_name
      type: (type_identifier) @param_type)))
```

### Predicates

```scheme
; Match regex pattern
((identifier) @id
 (#match? @id "^[A-Z]"))  ; Starts with capital letter

; Exact text match
((type_identifier) @type
 (#eq? @type "string"))

; Multiple possibilities
((identifier) @name
 (#any-of? @name "init" "new" "create"))

; Combine predicates
((identifier) @id
 (#match? @id "^[A-Z]")
 (#not? (#match? @id "^Test")))

; Multiple captures in predicate
((binary_expression
  operator: _ @op
  left: (identifier) @left
  right: (identifier) @right)
 (#eq? @op "+")
 (#eq? @left @right))  ; Same identifier on both sides
```

## Error Handling

### Query Creation Errors

```lua
-- Invalid language
local query, err = treesitter.query("invalid", pattern)
-- Returns: nil, "unsupported language: invalid"

-- Syntax errors
local query, err = treesitter.query("go", "(()")
-- Returns: nil, "Query error at 1:3. Invalid syntax"

-- Invalid node type
local query, err = treesitter.query("go", "(nonexistent_node)")
-- Returns: nil, "Query error at 1:1. Invalid node type"

-- Invalid predicate
local query, err = treesitter.query("go", "(node) @n (#invalid?)")
-- Returns: nil, "Query error at 1:20. Invalid predicate"

-- Invalid capture
local query, err = treesitter.query("go", "(node) @1invalid")
-- Returns: nil, "Query error at 1:14. Invalid capture name"

-- Invalid predicate
local query, err = treesitter.query("go", "((identifier) @id (#unknown? @id))")
-- err: "Query error at 1:20. Invalid predicate '#unknown?'"

-- Malformed predicate
local query, err = treesitter.query("go", "((identifier) @id (#match?))")
-- err: "Query error at 1:20. Invalid predicate arguments"

-- Invalid capture name
local query, err = treesitter.query("go", "(identifier) @1name")
-- err: "Query error at 1:14. Invalid capture name"
```

### Execution Errors

```lua
-- Handle match limit exceeded
query:set_match_limit(100)
local matches = query:matches(node, code)
if query:did_exceed_match_limit() then
    -- Handle too many matches...
end

-- Handle timeouts
query:set_timeout(1000000)  -- 1 second
local matches = query:matches(node, code)
-- Returns available matches if timeout occurs
```

## Match Results Structure

```lua
-- Matches structure
matches = {
    {
        id = number,       -- Match ID
        pattern = number,  -- Pattern index
        captures = {
            {
                node = node,    -- Captured node
                name = string,  -- Capture name
                index = number  -- Capture index
            }
        }
    }
}

-- Access match information
for _, match in ipairs(matches) do
    for _, capture in ipairs(match.captures) do
        local node = capture.node
        local text = node:text(source_code)
        print(capture.name, text)
    end
end
```

## Performance Controls

```lua
-- Limit search range
query:set_byte_range(start_byte, end_byte)
query:set_point_range(
    {row = start_row, column = start_col},
    {row = end_row, column = end_col}
)

-- Control match depth
query:set_max_start_depth(5)

-- Disable unused patterns/captures
query:disable_pattern(pattern_index)
query:disable_capture(capture_name)
```

## Best Practices

1. Error Handling
   ```lua
   -- Always check query creation
   local query, err = treesitter.query("go", pattern)
   if not query then
       print("Query error:", err)
       return
   end

   -- Handle match limits
   query:set_match_limit(1000)
   local matches = query:matches(node, code)
   if query:did_exceed_match_limit() then
       print("Warning: Match limit exceeded")
   end
   ```

2. Resource Management
   ```lua
   -- Clean up queries when done
   local query = treesitter.query("go", pattern)
   -- Use query...
   query:close()
   ```

3. Performance
   ```lua
   -- Reuse queries for multiple nodes
   local query = treesitter.query("go", pattern)
   for _, node in ipairs(nodes) do
       local matches = query:matches(node, code)
   end
   query:close()

   -- Set appropriate ranges for large files
   query:set_byte_range(start, end)
   ```