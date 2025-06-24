# Jet Templates Specification for AI Systems

## Overview

This specification provides comprehensive guidance for AI systems working with Jet templates, focusing on proper syntax, inheritance patterns, and common pitfalls.

> This engine is based on https://github.com/CloudyKit/jet

## Template Basics

### Delimiters

Templates use double curly braces for actions:
```
{{ expression }}
```

Whitespace can be trimmed using dashes:
```
{{- expression -}}
```

### Comments

Comments use special delimiters and are excluded during rendering:
```
{* This is a comment *}
```

## Variables and Expressions

### Variable Declaration and Assignment
```
{{ name := "value" }}  <!-- Declaration -->
{{ name = "newvalue" }} <!-- Assignment -->
```

### Variable Usage
```
Hello, {{ name }}!
```

### Expressions
```
{{ 1 + 2 * 3 }}
{{ "Hello " + "World" }}
{{ user.Name }}
{{ user["Name"] }}
{{ items[0] }}
{{ len(items) > 0 ? "Has items" : "Empty" }}
```

## Control Structures

### Conditional Logic
```
{{ if condition }}
    <!-- content -->
{{ else if otherCondition }}
    <!-- alternative content -->
{{ else }}
    <!-- fallback content -->
{{ end }}
```

### Iteration
```
{{ range items }}
    {{ . }}  <!-- Current item -->
{{ end }}

{{ range i, item := items }}
    {{ i }}: {{ item }}
{{ end }}
```

### Error Handling
```
{{ try }}
    <!-- potentially failing code -->
{{ catch err }}
    <!-- error handling -->
{{ end }}
```

## Template Inheritance

### Template Organization
Templates are organized within a template set using simple names:
```
"layout"
"section_layout"
"header"
"footer" 
"home_page"
"about_page"
```

### Extending Templates
The `extends` statement must be at the very top of the template:
```
{{ extends "layout" }}
```

### Importing Templates
Import templates to access their blocks:
```
{{ import "common_blocks" }}
```

## Block System

### Block Definition
Blocks define reusable template sections:
```
{{ block blockName() }}
    <!-- block content -->
{{ end }}
```

Blocks with parameters:
```
{{ block headerSection(title, showNav=true) }}
    <header>
        <h1>{{ title }}</h1>
        {{ if showNav }}
            <nav><!-- navigation content --></nav>
        {{ end }}
    </header>
{{ end }}
```

### Block Usage
Use yield to render a block:
```
{{ yield blockName() }}
```

With parameters:
```
{{ yield headerSection(title="Welcome", showNav=false) }}
```

### Content Blocks
For nested content:
```
{{ block wrapper(class="") }}
    <div class="{{ class }}">
        {{ yield content }}
    </div>
{{ end }}

{{ yield wrapper(class="container") content }}
    <p>This content goes inside the wrapper</p>
{{ end }}
```

## Template Inheritance Patterns

### Base Layout Pattern
```
<!-- Template: "layout" -->
<!DOCTYPE html>
<html>
<head>
    <title>{{ yield title() }}</title>
    <meta name="description" content="{{ yield metaDescription() }}">
</head>
<body>
    <header>{{ yield header() }}</header>
    <main>{{ yield mainContent() }}</main>
    <footer>{{ yield footer() }}</footer>
</body>
</html>

<!-- Template: "page" -->
{{ extends "layout" }}

{{ block title() }}Page Title{{ end }}
{{ block metaDescription() }}Page description...{{ end }}
{{ block header() }}Page Header{{ end }}
{{ block mainContent() }}
    <!-- Main content here -->
{{ end }}
{{ block footer() }}Page Footer{{ end }}
```

### Section Layout Pattern
```
<!-- Template: "section_layout" -->
{{ extends "layout" }}

{{ block header() }}
    <nav>
        <!-- Section navigation -->
    </nav>
{{ end }}

{{ block footer() }}
    <p>Section Footer</p>
{{ end }}

<!-- Template: "section_page" -->
{{ extends "section_layout" }}

{{ block title() }}Page Title{{ end }}
{{ block mainContent() }}
    <!-- Main content here -->
{{ end }}
```

## Critical Pitfalls

### Reserved Keywords
The following names cannot be used as block names:
- `content`
- `yield`
- `block`
- `end`
- `if`
- `else`
- `range`
- `try`
- `catch`
- `extends`
- `import`
- `return`

### Block Syntax
Always use parentheses with block names, even if there are no parameters:
```
{{ block footer() }}
    <!-- content -->
{{ end }}
```

### Yield Syntax
Always use parentheses with yield statements:
```
{{ yield footer() }}
```

### Extends Statement Location
The `extends` statement must be the first non-comment statement in a template.

### Recursive References
Avoid accidental recursion in block definitions:
```
{{ block menu() }}
    <ul>
        <!-- Careful with recursive yields -->
        {{ if hasChildren }}
            {{ yield menu() children }} <!-- Could cause infinite recursion -->
        {{ end }}
    </ul>
{{ end }}
```

## Integrated Functions

### String Functions
```
{{ lower(string) }}              <!-- Convert to lowercase -->
{{ upper(string) }}              <!-- Convert to uppercase -->
{{ hasPrefix(string, prefix) }}  <!-- Check if string starts with prefix -->
{{ hasSuffix(string, suffix) }}  <!-- Check if string ends with suffix -->
{{ repeat(string, count) }}      <!-- Repeat string n times -->
{{ replace(string, old, new, n) }} <!-- Replace old with new n times -->
{{ split(string, separator) }}   <!-- Split string into array -->
{{ trimSpace(string) }}          <!-- Remove whitespace from start/end -->
```

### Data Functions
```
{{ len(value) }}                 <!-- Get length of string/array/map -->
{{ isset(value) }}               <!-- Check if value is set/not nil -->
{{ json(value) }}                <!-- Encode value as JSON -->
```

### Template Functions
```
{{ include "template_name" [context] }} <!-- Include another template -->
{{ exec("template_name" [context]) }}   <!-- Execute template, capture return value -->
{{ ints(start, end) }}                  <!-- Generate range of integers -->
{{ dump() }}                           <!-- Debug available variables -->
```

### HTML Escaping
```
{{ html(string) }}               <!-- Escape HTML -->
{{ safeHtml(string) }}           <!-- Mark as safe HTML -->
{{ safeJs(string) }}             <!-- Mark as safe JavaScript -->
{{ raw(string) }}                <!-- Output without escaping (unsafe) -->
{{ url(string) }}                <!-- URL encode string -->
```

### Custom Functions
Templates can also access custom functions registered in the template set configuration.

### Function Syntax Variations
Functions can be called using different syntaxes:

1. Standard call:
```
{{ len(items) }}
```

2. Prefix syntax:
```
{{ len: items }}
```

3. Pipeline syntax:
```
{{ items | len }}
{{ "hello" | upper | repeat: 2 }}
```

4. Piped argument slot (specify where piped value goes):
```
{{ 2 | repeat("hello", _) }}  <!-- Places 2 as second argument -->
```

## Data Passing Patterns

### Context Inheritance
Data available in parent templates is available in child templates.

### Explicit Parameter Passing
```
{{ yield userCard(user=currentUser, showDetails=true) }}
```

### Block Return Values
```
{{ block getUserName(user) }}
    {{ return user.FirstName + " " + user.LastName }}
{{ end }}

{{ userName := yield getUserName(user) }}
Hello, {{ userName }}!
```

### Block Default Propagation and Inheritance in Jet Templates
Jet template blocks function as inherited components with cascading defaults. Parent templates define blocks ({{ block name() }}content{{ end }}) that establish default content. Child templates can override blocks entirely or inherit defaults by omission. Block parameters support default values ({{ block header(title="Default", showNav=true) }}) which apply when not explicitly provided during yield. Blocks defined in directly executed templates render immediately at definition point, while blocks in extended/imported templates remain dormant until yielded. During inheritance, a block's default content remains available via {{ yield super() }}, allowing child templates to extend rather than replace parent content. Template order matters: the extends directive must be first, block overrides must match parent signatures exactly, and scope inheritance follows the template hierarchy chain. Default propagation respects the most specific template in the inheritance tree.

## Common Templates in a Set

### Layout Templates
- Base layout with common page structure ("layout")
- Section layouts for different areas ("admin_layout", "public_layout")

### Component Templates
- Form elements ("input_field", "button", "select_field")
- Cards and panels ("card", "panel")
- Headers and footers ("header", "footer")
- Navigation elements ("navigation", "sidebar")

### Page Templates
- Specific pages that extend layouts ("home_page", "about_page")
- Templates for dynamic content sections ("hero_section", "features_section")