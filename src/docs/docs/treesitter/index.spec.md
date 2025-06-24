# Tree-sitter Core Usage

## Module Import & Functions

```lua
local treesitter = require("treesitter")

-- Create parser explicitly
local parser = treesitter.parser()
parser:set_language("go")
local tree = parser:parse(code)

-- Or use shorthand parse
local tree = treesitter.parse("go", code)

-- Get available languages
local langs = treesitter.supported_languages()  -- Returns table with language names as keys

-- Create language instance
local lang = treesitter.language("go")  -- Returns language or nil, error_message

-- Create query
local query = treesitter.query("go", pattern)  -- Returns query or nil, error_message
```

## Error Handling

### Language Errors

```lua
-- Invalid language
local tree, err = treesitter.parse("invalid", code)
-- Returns: nil, "unsupported language: invalid"

local lang, err = treesitter.language("invalid")
-- Returns: nil, "unsupported language: invalid"

-- Missing language binding
local lang, err = treesitter.language("unsupported")
-- Returns: nil, "language 'unsupported' does not have a Tree-sitter language binding"
```

### Parse Errors

```lua
-- Basic parse error
local tree, err = treesitter.parse("go", "invalid { syntax")
-- Returns: tree with error nodes

-- Check for errors
if tree:root_node():has_error() then
    -- Handle syntax errors
end
```

### Query Errors

```lua
-- Invalid query syntax
local query, err = treesitter.query("go", "((invalid query")
-- Returns: nil, "Query error at 1:3. Invalid syntax"

-- Invalid node type
local query, err = treesitter.query("go", "(nonexistent_node)")
-- Returns: nil, "Query error at 1:1. Invalid node type"
```

## Language Support

```lua
-- Core supported languages:
{
    go = true,
    golang = true,        -- Alias
    javascript = true, 
    js = true,           -- Alias
    typescript = true,
    ts = true,           -- Alias
    tsx = true,
    python = true,
    py = true,           -- Alias
    php = true,
    html = true,
    html5 = true,        -- Alias
    csharp = true,
    ["c#"] = true,       -- Alias
    cs = true,           -- Alias
    lua = true
}
```

## Best Practices

1. Language Selection
   ```lua
   -- Check language support first
   local langs = treesitter.supported_languages()
   if langs[lang_name] then
       local tree = treesitter.parse(lang_name, code)
   end
   ```

2. Error Handling Pattern
   ```lua
   local ok, result = pcall(function()
       local tree = treesitter.parse("go", code)
       -- Use tree...
   end)
   if not ok then
       -- Handle error
   end
   ```

3. Resource Management
   ```lua
   -- Create parsers for long-term use
   local parser = treesitter.parser()
   parser:set_language("go")
   
   for _, code in ipairs(files) do
       parser:reset()
       local tree = parser:parse(code)
   end
   
   parser:close()
   
   -- Use direct parse for one-off parsing
   local tree = treesitter.parse("go", code)
   ```

4. Query Creation
   ```lua
   -- Create queries once and reuse
   local query = treesitter.query("go", pattern)
   
   for _, node in ipairs(nodes) do
       local matches = query:matches(node, code)
   end
   
   query:close()
   ```