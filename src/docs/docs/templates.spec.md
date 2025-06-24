# Templates Module Documentation

## Overview

The `templates` module provides a way to access and render templates in Lua scripts. It allows you to retrieve template sets from the resource registry, render templates with variables, and properly release resources when done.

## Module Loading

```lua
local templates = require("templates")
```

## Functions

### templates.get(id)

Retrieves a template set from the resource registry.

**Parameters:**
- `id` (string): Resource ID of the template set in the format "namespace:name" (e.g., "app:my_templates")

**Returns:**
- A template set object that can be used to render templates

**Errors:**
- Raises an error if the resource ID is invalid
- Raises an error if the resource is not found
- Raises an error if the resource is not a template set

**Example:**
```lua
local templates = require("templates")
local tmpl = templates.get("app:my_templates")
```

## Template Set Methods

### tmpl:render(name, data)

Renders a template by name with the provided variable data.

**Parameters:**
- `name` (string): The name of the template to render
- `data` (table): A table containing the variables to pass to the template

**Returns:**
- `result` (string): The rendered template content on success
- `nil, error_message` (nil, string): If an error occurs

**Example:**
```lua
local result, err = tmpl:render("welcome", {
    name = "John",
    user = {
        age = 30,
        email = "john@example.com"
    },
    items = {"apple", "banana", "orange"}
})

if err then
    -- Handle error
    print("Error rendering template:", err)
else
    -- Use the rendered content
    print(result)
end
```

### tmpl:release()

Releases the template set resource. This should be called when you're done with the template set to free up resources.

**Returns:**
- `true` (boolean): Indicates successful release

**Example:**
```lua
local ok = tmpl:release()
```

## Resource Management

Template resources are automatically released when the unit of work (UoW) completes, but you can explicitly release them earlier with `tmpl:release()`.

## Complete Example

```lua
local templates = require("templates")

-- Get the template set
local tmpl = templates.get("app:email_templates")

-- Render a welcome email template
local email, err = tmpl:render("welcome_email", {
    user = {
        name = "Alice Smith",
        email = "alice@example.com"
    },
    subscription = {
        level = "Premium",
        expires = "2023-12-31"
    },
    features = {"Unlimited Access", "Priority Support", "Custom Templates"}
})

if err then
    print("Failed to render email template:", err)
else
    -- Use the rendered email
    print("Email content:", email)
end

-- Explicitly release the template resource
tmpl:release()
```

## Best Practices

1. **Always check for errors** when rendering templates.
2. **Release template resources** when you're done with them.
3. **Structure your data** in a way that matches your template's expectations.
4. **Use consistent naming conventions** for your templates and variables.
5. **Keep templates and code separate** - templates should focus on presentation while Lua code handles the logic.