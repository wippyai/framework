### Global Functions

#### ctx.get(key: string)

Retrieves a value from the context associated with the given key.

Parameters:

- `key`: String identifier for the value to retrieve

Returns:

- `value`: The value associated with the key (or nil if not found or an error occurs)
- `error`: Error message string (or nil on success)

#### ctx.set(key: string, value: any)

Sets a value in the context for the given key.

Parameters:

- `key`: String identifier for the value to set
- `value`: The value to associate with the key

Returns:

- `ok`: Boolean indicating success (true) or failure (false)
- `error`: Error message string (or nil on success)

#### ctx.all()

Retrieves all values from the context as a table.

Parameters:
- None

Returns:
- `table`: Table containing all key-value pairs from the context
- `error`: Error message string (or nil on success)

## Example Usage with all

```lua
local ctx = require("ctx")

-- Set some values in the context
ctx.set("user", "john")
ctx.set("role", "admin")
ctx.set("preferences", { theme = "dark", notifications = true })

-- Get all values from the context
local allValues, err = ctx.all()
if err then
  print("Error getting all values:", err)
else
  -- Access specific values from the table
  print("User:", allValues.user)
  print("Role:", allValues.role)
  print("Theme preference:", allValues.preferences.theme)
  
  -- Iterate over all values
  for key, value in pairs(allValues) do
    if type(value) ~= "table" then
      print(key, "=", value)
    else
      print(key, "= [table]")
    end
  end
end
```