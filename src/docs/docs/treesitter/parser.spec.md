# Tree-sitter Parser Specification

## Core Usage

```lua
-- Create parser
local parser = treesitter.parser()

-- Set language
parser:set_language("go")  -- Raises error if language not found
                          -- Returns false, error_message if setup fails

-- Parse code
local tree = parser:parse("package main")

-- Get current language
local lang = parser:get_language()  -- Raises error if no language set
```

## Supported Languages

- go, golang
- js, javascript
- ts, typescript
- tsx
- python, py
- php
- html, html5
- csharp, c#, cs
- lua

## Error Handling

```lua
-- Invalid language
local ok, err = pcall(function()
    parser:set_language("invalid")
end)
-- Error: language 'invalid' not found

-- Invalid binding
local ok, err = pcall(function()
    parser:set_language("unsupported")  
end)
-- Error: language 'unsupported' does not have a Tree-sitter language binding

-- Parse without language
local ok, err = pcall(function()
    parser:parse("code")
end)
-- Error: language is not set
```

## Incremental Parsing

For efficient updates to existing code:

```lua
local old_tree = parser:parse(old_code)
local new_tree = parser:parse(new_code, old_tree)
```

## Resource Management

```lua
-- Reset parser (keeps language setting)
parser:reset()

-- Free resources
parser:close()

-- After close, operations fail with error
local ok, err = pcall(function()
    parser:parse("code")  -- Fails after close
end)
```

## Advanced Usage

### Timeout Setting

```lua
parser:set_timeout(0.1)  -- 100ms timeout
```

### Parsing Ranges

For embedded languages (e.g., Go in HTML):

```lua
parser:set_ranges({
    {
        start_byte = number,
        end_byte = number,
        start_row = number,
        start_col = number,
        end_row = number,
        end_col = number
    }
})
```

## Best Practices

1. Parser Lifecycle
   ```lua
   local parser = treesitter.parser()
   assert(parser:set_language("go"))
   
   -- Reuse for multiple parses
   for _, code in ipairs(files) do
       parser:reset()
       local tree = parser:parse(code)
       -- Use tree...
   end
   
   parser:close()
   ```

2. Performance
    - Reuse parser instances
    - Use reset() between unrelated parses
    - Use incremental parsing for code updates
    - Set timeouts for large files