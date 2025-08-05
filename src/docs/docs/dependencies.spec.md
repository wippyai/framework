# Dependency Injection System Specification

## Overview

The Dependency Injection System provides a declarative parameter injection mechanism in the Wippy Runtime that separates configuration concerns between applications and modules.

## Core Components

### 1. Definitions (`ns.definition`)

Definitions declare how to extract values from dependencies for injection into modules.

**Structure:**
```yaml
- name: DEFINITION_NAME
  kind: ns.definition
  targets:
    - entry: TARGET_DEPENDENCY_ENTRY
      path: JQ_EXTRACTION_PATH
```

**Properties:**
- `name`: Unique identifier for the definition
- `kind`: Must be `ns.definition`
- `targets`: Array of target specifications
  - `entry`: Name of the dependency entry to extract from
  - `path`: jq syntax path to extract the value

**Purpose:**
- Extract specific values from dependency configurations
- Provide values to be injected into module requirements
- Enable dynamic parameter resolution

### 2. Dependencies (`ns.dependency`)

Dependencies declare external components with configurable parameters.

**Structure:**
```yaml
- name: DEPENDENCY_NAME
  kind: ns.dependency
  meta:
    description: "Description of the dependency"
  component: "COMPONENT_PATH"
  version: "VERSION_CONSTRAINT"
  parameters:
    - name: PARAM_NAME
      value: PARAM_VALUE
```

**Properties:**
- `name`: Unique identifier for the dependency
- `kind`: Must be `ns.dependency`
- `meta.description`: Human-readable description
- `component`: Path to the external component
- `version`: Version constraint (e.g., ">=v0.0.1")
- `parameters`: Array of configurable parameters
  - `name`: Parameter identifier
  - `value`: Parameter value

**Purpose:**
- Declare external component dependencies
- Provide configurable parameters for component integration
- Enable version-controlled dependency management

### 3. Requirements (`ns.requirement`)

Requirements specify where definition values should be injected in module entries.

**Structure:**
```yaml
- name: REQUIREMENT_NAME
  kind: ns.requirement
  meta:
    description: "Description of the requirement"
  targets:
    - entry: TARGET_ENTRY_NAME  # Optional
      path: JQ_INJECTION_PATH
```

**Properties:**
- `name`: Must match a definition name for injection pairing
- `kind`: Must be `ns.requirement`
- `meta.description`: Human-readable description
- `targets`: Array of injection targets
  - `entry`: Target entry name (optional, defaults to current entry)
  - `path`: jq syntax path where value should be injected

**Purpose:**
- Specify injection points for definition values
- Enable precise targeting of where values are applied
- Maintain separation between configuration and implementation

## Injection Flow

1. **Definition Resolution**: System locates definition by name
2. **Value Extraction**: Uses jq path to extract value from target dependency
3. **Requirement Matching**: Finds requirement with matching name in module
4. **Target Injection**: Applies extracted value to requirement targets using jq path
5. **Entry Modification**: Target entries receive injected values

## jq Syntax Patterns

### Extraction Patterns (Definitions)
- `.parameters[] | select(.name == "param_name") | .value` - Extract parameter value by name
- `.meta.field_name` - Extract metadata field
- `.config.nested.field` - Extract nested configuration value

### Injection Patterns (Requirements)
- `.meta.field_name` - Set metadata field
- `.meta.array_field +=` - Append to metadata array
- `.config.nested.field` - Set nested configuration value
- `.parameters[] | select(.name == "param") | .value` - Modify parameter value

## Configuration Scope

### Application Level
- Definitions: Declare what values to extract
- Dependencies: Configure external components
- Scope: Application-wide parameter resolution

### Module Level
- Requirements: Specify injection targets
- Target Entries: Receive injected values
- Scope: Module-specific parameter consumption

## Validation Rules

### Definitions
- Must have unique names within application scope
- Target entry must exist in dependencies
- jq extraction path must be valid and return single value

### Dependencies
- Must have unique names within application scope
- Component path must be resolvable
- Version constraint must be valid semver pattern
- Parameters must have unique names within dependency

### Requirements
- Names must match existing definition names for injection
- Target entries must exist within module scope
- jq injection paths must be valid
- Injection must not conflict with existing entry structure

## Error Handling

### Definition Errors
- **Missing Target**: Definition targets non-existent dependency
- **Invalid Path**: jq extraction path is malformed or returns no value
- **Multiple Values**: jq path returns multiple values instead of single value

### Dependency Errors
- **Component Not Found**: Referenced component cannot be resolved
- **Version Mismatch**: Component version doesn't satisfy constraint
- **Parameter Conflict**: Duplicate parameter names within dependency

### Requirement Errors
- **Orphaned Requirement**: No matching definition found
- **Invalid Target**: Target entry doesn't exist in module
- **Injection Conflict**: jq injection path conflicts with existing data

## Best Practices

### Naming Conventions
- Use UPPER_CASE for definition/requirement names
- Use descriptive names that indicate purpose
- Maintain consistency between definition and requirement names

### Path Design
- Keep jq paths as simple as possible
- Use parameter selection patterns for dependency extraction
- Prefer metadata injection for non-functional configuration

### Separation of Concerns
- Applications manage definitions and dependencies
- Modules manage requirements and target entries
- Avoid tight coupling between application and module structure

## Example Implementation

```yaml
# Application (_index.yaml)
entries:
  - name: DATABASE_URL
    kind: ns.definition
    targets:
      - entry: db_dependency
        path: .parameters[] | select(.name == "url") | .value
  
  - name: db_dependency
    kind: ns.dependency
    component: "postgres/client"
    version: ">=v1.0.0"
    parameters:
      - name: url
        value: "postgresql://localhost:5432/app"

# Module (module.yaml)
entries:
  - name: DATABASE_URL
    kind: ns.requirement
    targets:
      - entry: db_handler
        path: .meta.connection_string
  
  - name: db_handler
    kind: function.lua
    source: file://database.lua
    meta:
      comment: "Database handler function"
```

## Integration Points

### Runtime System
- Module loading and dependency resolution
- Parameter injection during entry processing
- Error reporting and validation

### Build System
- Static validation of dependency injection configurations
- Dependency graph analysis
- Configuration merging and optimization