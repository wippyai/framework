# Lua HTML Module Specification

## Overview

The `html` module provides HTML sanitization via bluemonday. Create policies fresh each time.

## Module Interface

```lua
local html = require("html")
```

## Policy Creation

### `html.sanitize.new_policy()`
Returns empty policy. Add allowlists explicitly.

```lua
local policy, err = html.sanitize.new_policy()
```

### `html.sanitize.ugc_policy()`
Returns policy for user-generated content with common formatting elements.

### `html.sanitize.strict_policy()`
Returns policy that strips all HTML, leaving plain text.

## Policy Methods

### Element Control
- `policy:allow_elements(element1, element2, ...)` - Allow specific HTML elements
- `policy:allow_images()` - Allow img elements and standard attributes
- `policy:allow_lists()` - Allow ul, ol, dl and related elements
- `policy:allow_tables()` - Allow table elements and attributes

### Attribute Control
- `policy:allow_attrs(attr1, attr2, ...)` - Returns AttrBuilder for configuration
- `policy:allow_standard_attributes()` - Allow dir, id, lang, title globally

### URL Security
- `policy:allow_standard_urls()` - Enable standard URL handling with security
- `policy:allow_url_schemes(scheme1, scheme2, ...)` - Restrict URL schemes
- `policy:require_nofollow_on_links(bool)` - Add rel="nofollow" to links
- `policy:require_noreferrer_on_links(bool)` - Add rel="noreferrer" to links
- `policy:allow_relative_urls(bool)` - Allow relative URLs
- `policy:allow_data_uri_images()` - Allow base64 image data URIs

### Sanitization
- `policy:sanitize(html_string)` - Sanitize HTML string

## AttrBuilder Methods

Returned by `policy:allow_attrs()`:

- `attr_builder:on_elements(element1, element2, ...)` - Restrict to specific elements
- `attr_builder:globally()` - Allow on any permitted element
- `attr_builder:matching(pattern)` - Validate with regex pattern

## Examples

```lua
-- Custom policy
local policy, err = html.sanitize.new_policy()
policy:allow_elements("p", "strong", "em")
policy:allow_attrs("href"):on_elements("a")
policy:allow_attrs("class"):matching("^[a-zA-Z0-9_-]+$"):globally()
local clean = policy:sanitize(dirty_html)

-- UGC with restrictions
local policy, err = html.sanitize.ugc_policy()
policy:allow_url_schemes("https", "mailto")
policy:require_nofollow_on_links(true)
local clean = policy:sanitize(user_content)

-- Strip everything
local policy, err = html.sanitize.strict_policy()  
local text_only = policy:sanitize(html_content)
```

## Security Notes

- Create fresh policies per sanitization operation
- Use regex patterns to validate attribute values
- Restrict URL schemes to https/mailto for user content
- Enable nofollow/noreferrer on links for UGC