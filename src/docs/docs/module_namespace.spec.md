# Module Namespace Specification for Wippy Framework

## Overview

This specification defines the naming conventions and directory structure requirements for modules in the Wippy Framework. It establishes consistent patterns for vendor names, package names, and namespace hierarchy to ensure proper module organization and registry integration.

## Namespace Components

### 1. Vendor Name

The vendor name represents the organization or individual who owns and maintains the module.

**Requirements:**
- Must be registered in the Wippy Registry
- Use kebab-case format (e.g., `wippy`, `my-company`, `openai`)
- Should be unique across the registry
- Recommended length: 3-20 characters
- Must start with a letter
- Can contain lowercase letters, numbers, and hyphens
- Cannot start or end with a hyphen

**Examples:**
- `wippy` - Official Wippy framework modules
- `openai` - OpenAI integration modules
- `google-cloud` - Google Cloud service modules
- `acme-corp` - Third-party vendor modules

### 2. Package Name

The package name identifies the specific functionality or service domain within a vendor's namespace.

**Requirements:**
- Use kebab-case format (e.g., `llm`, `database-orm`, `terminal-ui`)
- Should be descriptive of the module's primary purpose
- Recommended length: 2-20 characters
- Must be unique within the vendor namespace
- Avoid generic names like `utils` or `core`

**Examples:**
- `llm` - Large Language Model integrations
- `database-orm` - Database connectivity and ORM
- `terminal-ui` - Terminal UI components
- `auth-service` - Authentication and authorization

### 3. Namespace Hierarchy

Namespaces follow a dot-separated hierarchy that maps directly to the directory structure within the module.

**Format:** `{vendor}.{package}.{component}.{subcomponent}`

**Rules:**
- Always lowercase in namespace declarations
- Components separated by dots (`.`)
- Each level corresponds to a directory level within the module
- Maximum recommended depth: 4 levels

## Module Directory Structure

### Standard Module Structure

```
src/
├── _index.yaml                 # Root registry file
├── {component}/               # Component directories
│   ├── _index.yaml            # Component registry file
│   ├── {subcomponent}/        # Subcomponent directories (optional)
│   │   ├── _index.yaml        # Subcomponent registry file
│   │   └── *.lua              # Implementation files
│   └── *.lua                  # Component implementation files
└── *.lua                      # Root module implementation files
```

### Registry File Hierarchy

Each directory level must contain an `_index.yaml` file that declares the namespace for that level.

**Root Level** (`src/_index.yaml`):
```yaml
namespace: {vendor}.{package}
entries:
  - name: main-component
    # ... other configuration
```

**Component Level** (`src/{component}/_index.yaml`):
```yaml
namespace: {vendor}.{package}.{component}
entries:
  - name: sub-component
    # ... other configuration
```

**Subcomponent Level** (`src/{component}/{subcomponent}/_index.yaml`):
```yaml
namespace: {vendor}.{package}.{component}.{subcomponent}
entries:
  - name: specific-function
    # ... other configuration
```

## Naming Examples

### Example 1: Official Wippy LLM Module

**Vendor:** `wippy`
**Package:** `llm`
**Directory Structure:**
```
src/
├── _index.yaml                 # namespace: wippy.llm
├── providers/
│   ├── _index.yaml            # namespace: wippy.llm.providers
│   ├── vertex/
│   │   ├── _index.yaml        # namespace: wippy.llm.providers.vertex
│   │   └── client.lua
│   ├── openai/
│   │   ├── _index.yaml        # namespace: wippy.llm.providers.openai
│   │   ├── chat.lua
│   │   └── embeddings.lua
│   └── anthropic/
│       ├── _index.yaml        # namespace: wippy.llm.providers.anthropic
│       └── claude.lua
├── tools/
│   ├── _index.yaml            # namespace: wippy.llm.tools
│   ├── function-calling.lua
│   └── structured-output.lua
└── core.lua
```

**Resulting Namespaces:**
- `wippy.llm` - Root LLM module
- `wippy.llm.providers` - LLM provider integrations
- `wippy.llm.providers.vertex` - Google Vertex AI integration
- `wippy.llm.providers.openai` - OpenAI integration
- `wippy.llm.providers.anthropic` - Anthropic integration
- `wippy.llm.tools` - LLM utility tools

### Example 2: Third-party Database Module

**Vendor:** `acme-corp`
**Package:** `database-orm`
**Directory Structure:**
```
src/
├── _index.yaml                 # namespace: acme-corp.database-orm
├── drivers/
│   ├── _index.yaml            # namespace: acme-corp.database-orm.drivers
│   ├── postgres/
│   │   ├── _index.yaml        # namespace: acme-corp.database-orm.drivers.postgres
│   │   ├── connection.lua
│   │   └── pool.lua
│   ├── mysql/
│   │   ├── _index.yaml        # namespace: acme-corp.database-orm.drivers.mysql
│   │   └── client.lua
│   └── sqlite/
│       ├── _index.yaml        # namespace: acme-corp.database-orm.drivers.sqlite
│       └── adapter.lua
├── query-builder/
│   ├── _index.yaml            # namespace: acme-corp.database-orm.query-builder
│   ├── select.lua
│   ├── insert.lua
│   └── update.lua
└── models/
    ├── _index.yaml            # namespace: acme-corp.database-orm.models
    ├── base.lua
    └── relations.lua
```

**Resulting Namespaces:**
- `acme-corp.database-orm` - Root database ORM module
- `acme-corp.database-orm.drivers` - Database drivers
- `acme-corp.database-orm.drivers.postgres` - PostgreSQL driver
- `acme-corp.database-orm.drivers.mysql` - MySQL driver
- `acme-corp.database-orm.drivers.sqlite` - SQLite driver
- `acme-corp.database-orm.query-builder` - Query building utilities
- `acme-corp.database-orm.models` - Model definitions and relations

### Example 3: Terminal UI Components Module

**Vendor:** `ui-components`
**Package:** `terminal-widgets`
**Directory Structure:**
```
src/
├── _index.yaml                 # namespace: ui-components.terminal-widgets
├── forms/
│   ├── _index.yaml            # namespace: ui-components.terminal-widgets.forms
│   ├── input.lua
│   ├── textarea.lua
│   └── button.lua
├── layout/
│   ├── _index.yaml            # namespace: ui-components.terminal-widgets.layout
│   ├── grid.lua
│   ├── flex.lua
│   └── stack.lua
├── navigation/
│   ├── _index.yaml            # namespace: ui-components.terminal-widgets.navigation
│   ├── menu.lua
│   ├── tabs.lua
│   └── breadcrumb.lua
└── theme.lua
```

**Resulting Namespaces:**
- `ui-components.terminal-widgets` - Root terminal widgets module
- `ui-components.terminal-widgets.forms` - Form components
- `ui-components.terminal-widgets.layout` - Layout components
- `ui-components.terminal-widgets.navigation` - Navigation components

## Best Practices

### 1. Namespace Design

- **Keep it simple:** Avoid deep nesting beyond 4 levels
- **Be descriptive:** Names should clearly indicate functionality
- **Stay consistent:** Use consistent naming patterns across components
- **Avoid conflicts:** Check registry for existing namespaces before choosing

### 2. Directory Organization

- **Logical grouping:** Group related functionality in component directories
- **Single responsibility:** Each namespace should have a clear, focused purpose
- **Modular design:** Design for reusability and composability
- **Clear hierarchy:** Structure should reflect functional relationships

### 3. Registry Integration

- **Complete declarations:** Every directory level needs an `_index.yaml`
- **Proper inheritance:** Child namespaces inherit from parent context
- **Clear documentation:** Include descriptions and metadata in registry files

### 4. Version Management

- **Semantic versioning:** Follow semantic versioning for module releases
- **Namespace stability:** Avoid changing established namespaces
- **Deprecation strategy:** Plan for graceful deprecation of old namespaces

## Reserved Namespaces

The following vendor names are reserved for official use:

- `wippy.*` - Official Wippy framework modules
- `system.*` - Core system modules
- `runtime.*` - Runtime environment modules

## Validation Rules

Namespace declarations must pass these validation checks:

1. **Format validation:** Must match pattern `^[a-z][a-z0-9-]*(\.[a-z][a-z0-9-]*)*$`
2. **Kebab-case compliance:** Each component must use kebab-case format
3. **Length limits:** Each component must be 2-30 characters
4. **Registry uniqueness:** Must not conflict with existing registrations
5. **Directory mapping:** Must correspond to actual directory structure
6. **File presence:** Each namespace level must have corresponding `_index.yaml`
7. **No consecutive hyphens:** Components cannot contain consecutive hyphens
8. **Valid boundaries:** Components cannot start or end with hyphens

## Migration Guidelines

When reorganizing existing modules:

1. **Maintain compatibility:** Keep old namespaces working during transition
2. **Deprecation notices:** Announce changes with sufficient advance notice
3. **Alias support:** Provide aliases for commonly used old namespaces
4. **Documentation updates:** Update all references in documentation
5. **Community notification:** Inform the community about namespace changes

## Component Organization Principles

### Functional Grouping

Components should be organized by functional areas:
- `providers/` - External service integrations
- `drivers/` - Low-level adapters and drivers
- `utils/` - Utility functions and helpers
- `models/` - Data models and structures
- `handlers/` - Event and request handlers

### Naming Conventions for Components

- Use descriptive, action-oriented names
- Prefer specific over generic terms
- Keep names concise but clear
- Use consistent terminology across related components

## Conclusion

Following these namespace conventions ensures:
- Consistent module organization across the Wippy ecosystem
- Clear ownership and responsibility boundaries
- Efficient module discovery and loading
- Reduced naming conflicts and confusion
- Better maintainability and documentation

All module developers should adhere to these specifications when creating or maintaining Wippy Framework modules.
