# Wippy Framework Development Guide

## Project Layout

Two directory structures exist for framework packages:

**Flat packages** (`migration`, `embeddings`, `views`, `security`, `docs`, `terminal`, `test`):
```
src/<package>/
  _index.yaml       # entry definitions
  wippy.yaml         # publish manifest
  wippy.lock         # dependency lock
  .wippy/            # downloaded dependencies
  *.lua              # source files
```

**Src packages** (`actor`, `agent`, `bootloader`, `llm`, `relay`, `usage`):
```
src/<package>/
  src/
    _index.yaml
    wippy.yaml
    wippy.lock
    .wippy/
    *.lua
  test/              # separate test project
    _index.yaml      # test infrastructure stubs
    wippy.yaml       # test stub manifest
    wippy.lock       # lock with replacements
    .wippy/
```

## Entry Definitions (`_index.yaml`)

Every package has one or more `_index.yaml` files defining its entries. Each entry has a `name`, `kind`, optional `meta`, and kind-specific fields.

### Entry Kinds

| Kind | Purpose |
|------|---------|
| `ns.definition` | Package identity (one per module) |
| `ns.requirement` | Configuration injection point |
| `ns.dependency` | External module dependency |
| `library.lua` | Shared code (imported by other entries) |
| `function.lua` | Callable function (tests, handlers, tools) |
| `process.lua` | Long-running process |
| `process.service` | Service lifecycle wrapper for a process |
| `contract.definition` | Service interface with methods |
| `contract.binding` | Contract implementation |
| `registry.entry` | Generic registry entry (providers, specs, traits) |
| `env.storage.os` | OS environment variable backend |
| `env.variable` | Individual environment variable |
| `security.group` | Security group |
| `security.policy` | Security policy rules |
| `http.service` | HTTP server |
| `http.router` | HTTP router |
| `http.endpoint` | HTTP endpoint |
| `http.static` | Static file serving |
| `fs.directory` | File system directory reference |
| `template.set` | Template engine config |
| `template.jet` | Jet template |

### ns.definition

Every package has exactly one:

```yaml
- name: definition
  kind: ns.definition
  meta:
    title: My Package
    description: What it does
  readme: file://README.md
```

### ns.requirement

Requirements are the dependency injection mechanism. A module declares what values it needs, where to inject them, and optionally provides defaults. The consuming application supplies values via `ns.dependency` parameters.

```yaml
- name: application_host
  kind: ns.requirement
  meta:
    description: "Host ID for processes"
  targets:
    - entry: my_service
      path: ".host"
    - entry: my_service
      path: ".lifecycle.depends_on +="
    - entry: wippy.relay.env:host
      path: ".default"
  default: "app:processes"
```

**Target path syntax:**
- `.host` -- sets the `host` field
- `.default` -- sets the `default` field
- `.storage` -- sets the `storage` field (for env.variable entries)
- `.meta.router` -- sets a nested meta field
- `.lifecycle.depends_on +=` -- appends to an array (the `+=` operator)
- `.meta.depends_on +=` -- appends to a meta array
- `.meta.requires +=` -- appends to a requires array

**Target entry resolution:**
- Cross-namespace: `wippy.relay.env:host` (fully qualified)
- Local namespace: `central.service` (resolved within the requirement's own namespace)

**Resolution flow:**
1. All `ns.requirement` and `ns.dependency` entries are collected
2. For each requirement, dependencies are searched for a `parameters` entry with matching name
3. Parameter matching supports full ID (`wippy.relay:env_storage`) or bare name (`env_storage` when namespaces align)
4. If no parameter found, `default` value is used
5. If no default, the requirement is unresolved (warning, not error)
6. Value is applied to each target via set or append

### ns.dependency

Declares an external module dependency with version constraint and optional parameters:

```yaml
- name: dep.wippy.test
  kind: ns.dependency
  meta:
    description: "Testing component"
    scope: dev
  component: "wippy/test"
  version: ">=v0.4.0"
```

**Naming convention:** `dep.<org>.<module>`.

**Version formats:**
- `"*"` -- any version
- `">=v0.4.0"` -- minimum version

**Supplying requirement values:** The consuming application provides values to module requirements via `parameters`:

```yaml
- name: dep.wippy.relay
  kind: ns.dependency
  component: wippy/relay
  parameters:
    - name: application_host
      value: app:processes
    - name: env_storage
      value: app.env:router
    - name: max_connections_per_user
      value: "12"
```

### process.service

Wraps a `process.lua` entry with lifecycle management:

```yaml
- name: central.service
  kind: process.service
  meta:
    comment: Central relay hub service
  lifecycle:
    auto_start: true
    depends_on: []
    security:
      actor:
        id: relay.central
      groups:
        - wippy.relay.security:root
  process: wippy.relay:central
```

The `host` field is typically injected by an `ns.requirement`. The `depends_on` array is often appended to via `+=`.

### env.variable

```yaml
- name: max_connections_per_user
  kind: env.variable
  meta:
    comment: Maximum WebSocket connections per user
    icon: tabler:server
    private: true
  storage:                                     # set by requirement
  default:                                     # set by requirement
  variable: RELAY_MAX_CONNECTIONS_PER_USER      # OS env var name
  readonly: false
```

The `storage` field references an `env.storage.os` entry. Both `storage` and `default` are typically injected by requirements.

## Linting

### Running

```bash
wippy lint                    # from package src directory
wippy lint --json             # JSON output
wippy lint --cache-reset      # clear cache first
wippy lint --rules            # enable style warnings (W0004, W0006)
wippy lint --summary          # grouped summary by namespace/code
wippy lint --ns wippy.relay   # filter by namespace
wippy lint --code E0000       # filter by error code
wippy lint --level error      # errors only (skip warnings/hints)
wippy lint --limit 10         # cap output
```

### Error Codes

| Code | Severity | Meaning |
|------|----------|---------|
| `E0000` | error | Type mismatch (argument types vs parameter signatures) |
| `E0002` | error | Type narrowed to `never` but used as function |
| `E0003` | error | Not enough arguments |
| `E0004` | error | Field access on type that lacks the field |
| `P0001` | error | Lua parse error |
| `W0002` | warning | General style warning |
| `W0004` | warning | Variable declared but never used |
| `W0006` | warning | Imported module never used |

### Type System

The linter performs Luau-style type checking. All type annotations use inline syntax, not LuaDoc comments (`---@param`, `---@class`, etc. are ignored).

**Variable declarations:**
```lua
local count: number = 0
local name: string? = nil        -- nullable
```

**Function signatures:**
```lua
local function add(a: number, b: number): number
function fetch(url: string): (string?, string?)    -- multiple returns
function sum(...: number): number                    -- variadic
```

**Type aliases:**
```lua
type User = { name: string, age: number, email?: string }
type Status = "pending" | "active" | "done"
type Callback = (string, number) -> boolean
```

**Collections:**
```lua
local arr: {number}               -- array
local map: {[string]: number}     -- map
```

**Generics:**
```lua
function identity<T>(x: T): T
function greet<T: HasName>(obj: T)    -- constrained
```

**Intersection and tagged unions:**
```lua
type Person = Named & Aged
type State =
    | {status: "loading"}
    | {status: "loaded", data: User}
```

**Casts:**
```lua
data :: User          -- unsafe cast
data as any           -- works for method resolution, NOT for argument checking
user!.name            -- non-nil assertion
```

**Linter behaviors:**
- `as any` works for method resolution: `(obj as any):method()` fixes E0002
- `as any` does NOT fix argument type checking
- `tostring()` / `tonumber()` are trusted for type narrowing
- Map literal keys are tracked by the linter; use assignment-based init to avoid issues
- Dynamic table methods (builder pattern) are not tracked
- Named struct types in function params cause false positives with inline table literals. `fn(opts: MyType)` rejects `{field = val}` even when structurally compatible. Fix: remove param type annotation, keep return type.
- Return type casts fix constructors: `return val :: TypeName` fixes "cannot return X, expected Y"
- `:: any` on returns breaks type checking: `return x :: any` causes "cannot return any, expected X". Cast to the declared return type instead.
- LuaDoc annotations (`---@param`, `---@class`, `---@field`, `---@return`, `---@type`, `---@cast`) are ignored by the linter. Use inline Luau-style annotations only.
- Nil narrowing may not propagate into closures: after `if not x then return end`, the linter may still see `x` as nullable inside nested callbacks.

## Testing

### Test Entry Definition

```yaml
- name: consts_test
  kind: function.lua
  meta:
    name: Relay Constants Test
    type: test                    # required for test discovery
    suite: relay                  # groups tests in TUI output
    comment: Tests relay constants
    group: Relay
    tags: [relay, constants]
  source: file://consts_test.lua
  imports:
    consts: wippy.relay:consts
    test: wippy.test:test
  modules: [env, time]
  method: run
```

### Running Tests

```bash
wippy run test                           # all tests
wippy run test consts                    # filter by ID substring
wippy run test openai client             # multiple filters (OR)
wippy run -o ns:entry:field=value test   # with entry overrides
wippy run -x wippy.llm.e2e:test test     # execute specific entry
```

**Override flag (`-o`):** Sets entry field values before the linking stage. Required when a package has mandatory requirements without defaults (e.g., process.service host).

```bash
wippy run -o wippy.relay:central.service:host=app:processes test
```

Format: `namespace:entry:field=value`. Multiple `-o` flags supported.

**Environment variables for integration tests:**
```bash
ENABLE_INTEGRATION_TESTS=true wippy run test
```

### Writing Tests

**Standard pattern** (most common):
```lua
local function define_tests()
    describe("My Suite", function()
        before_each(function()
            -- setup
        end)

        after_each(function()
            -- cleanup
        end)

        it("does something", function()
            expect(value).to_equal(expected)
        end)

        it_skip("not yet implemented", function()
            -- skipped
        end)
    end)
end

return require("test").run_cases(define_tests)
```

`test.run_cases(fn)` returns a function that accepts `options` and handles all process integration, event forwarding, and cleanup.

### Assertion API

**Direct assertions:**

| Function | Description |
|----------|-------------|
| `test.eq(actual, expected, msg?)` | Equal |
| `test.neq(actual, expected, msg?)` | Not equal |
| `test.ok(val, msg?)` | Truthy |
| `test.fail(msg?)` | Unconditional failure |
| `test.is_nil(val, msg?)` | Is nil |
| `test.not_nil(val, msg?)` | Not nil |
| `test.is_true(val, msg?)` | Strictly true |
| `test.is_false(val, msg?)` | Strictly false |
| `test.is_string(val, msg?)` | Type check |
| `test.is_number(val, msg?)` | Type check |
| `test.is_table(val, msg?)` | Type check |
| `test.is_function(val, msg?)` | Type check |
| `test.is_boolean(val, msg?)` | Type check |
| `test.contains(str, substr, msg?)` | String contains |
| `test.matches(str, pattern, msg?)` | Lua pattern match |
| `test.has_key(tbl, key, msg?)` | Table has key |
| `test.len(val, expected, msg?)` | Length equals |
| `test.gt(a, b, msg?)` | Greater than |
| `test.gte(a, b, msg?)` | Greater or equal |
| `test.lt(a, b, msg?)` | Less than |
| `test.lte(a, b, msg?)` | Less or equal |
| `test.throws(fn, msg?)` | Expects error |
| `test.has_error(val, err, msg?)` | val nil, err non-nil |
| `test.no_error(val, err, msg?)` | err nil |

**Fluent expect API:**
```lua
expect(actual).to_equal(expected)
expect(actual).to_be_nil()
expect(actual).not_to_be_nil()
expect(actual).to_be_true()
expect(actual).to_be_false()
expect(actual).to_contain(substr)
expect(actual).to_be_greater_than(other)
expect(actual).to_be_less_than(other)
```

**Error checking pattern:**
```lua
-- Use test.contains with tostring for error assertions
local result, err = some_operation()
expect(result).to_be_nil()
test.contains(tostring(err), "expected error text")
```

The fluent API does not include `to_be_type()`, `to_match()`, or `not_to_equal()`. Use `test.is_table()`, `test.is_string()`, `test.contains()`, and `test.neq()` instead.

### Mocking

```lua
mock("process.send", function(pid, topic, payload)
    -- replacement
end)

mock_process("send", function(pid, topic, payload) end)

restore_mock("process.send")
restore_all_mocks()
```

Mocks of `process.send` automatically preserve `test:*` topic messages for test event delivery.

### Test Infrastructure Stubs

Packages with process.service entries or infrastructure dependencies use separate test projects with stub entries. The test project has its own `wippy.lock` with a `replacements` entry pointing back to source:

```yaml
# test/wippy.lock
directories:
    modules: .wippy
    src: ../src
modules:
    - name: wippy/test
      version: 0.4.9
replacements:
    - from: wippy/facade
      to: ..
```

The test `_index.yaml` provides stub entries that satisfy requirements:

```yaml
# test/_index.yaml (facade example)
version: "1.0"
namespace: app
entries:
  - name: gateway
    kind: http.service
    addr: :19085
    lifecycle:
      auto_start: true

  - name: api.public
    kind: http.router
    prefix: /api/public
```

These stubs provide the exact entry IDs that requirements target (e.g., `app:gateway` satisfies the `server` requirement).

### Test Event Protocol

Tests communicate with the runner via process messages on topic `test:update`:

| Event | Data Fields |
|-------|-------------|
| `test:plan` | `suites: [{name, tests: [{name, skipped}]}]` |
| `test:case:start` | `suite, test, timestamp` |
| `test:case:pass` | `suite, test, duration, timestamp` |
| `test:case:fail` | `suite, test, duration, error, timestamp` |
| `test:case:skip` | `suite, test, timestamp` |
| `test:complete` | `total, passed, failed, skipped, duration, status` |
| `test:error` | `message, context, timestamp` |

## Publishing

### Package Manifest (`wippy.yaml`)

```yaml
organization: wippy
module: relay
description: WebSocket relay and messaging infrastructure
license: MPL-2.0
repository: https://github.com/wippyai/framework
homepage: https://wippy.ai
keywords:
  - relay
  - websocket
exclude_meta:
  type:
    - test
  scope:
    - dev
exclude:
  - "app:**"
```

### Exclusion

Two mechanisms control what gets excluded from published packages:

**`exclude_meta`** filters by entry metadata fields:
```yaml
exclude_meta:
  type: [test]       # excludes entries with meta.type = "test"
  scope: [dev]       # excludes entries with meta.scope = "dev"
```

**`exclude`** filters by entry ID glob patterns:
```yaml
exclude:
  - "app:**"         # excludes all entries in "app" namespace
```

Wildcard syntax: `*` matches one segment, `**` matches zero or more segments.

**Current package exclusion patterns:**

| Pattern | Used By |
|---------|---------|
| `type: [test]` | all packages |
| `scope: [dev]` | llm, agent, views, facade |
| `exclude: ["app:**"]` | facade, views |

### Publishing Command

```bash
wippy publish                         # interactive version bump
wippy publish --version 1.2.0         # specific version
wippy publish --dry-run               # pack only, verify content
wippy publish --label latest          # mutable label
wippy publish --protected             # immutable version
wippy publish --release-notes "..."   # release notes
```

### Framework Makefile

```bash
make publish-all         # publish all packages
make <package>           # publish specific package (e.g., make relay)
```

Flat packages publish from `src/<package>/`, src packages from `src/<package>/src/`.

## Dependency Management

### Lock File (`wippy.lock`)

```yaml
directories:
    modules: .wippy
    src: .
modules:
    - name: wippy/test
      version: 0.4.9
      hash: 31fb7486fae9e47ce33a89782969bfec0a754d13143d2af24ddc46c406717476
replacements:
    - from: wippy/facade
      to: ..
```

- `directories.modules` -- where .wapp files are stored
- `directories.src` -- source directory (`.` for src packages, `../src` for test projects)
- `modules` -- pinned dependencies with SHA-256 hashes
- `replacements` -- local path overrides for development

### Commands

```bash
wippy init                    # create empty lock file
wippy install                 # download all locked modules
wippy install --force         # bypass cache
wippy install --repair        # verify hashes, re-download mismatches
wippy update                  # re-resolve all dependencies
wippy update wippy/test       # update specific module
wippy add wippy/relay         # add new dependency (latest)
wippy add wippy/relay@0.4.0   # add specific version
```

## Runtime Override (`-o`)

Override any entry field at runtime:

```bash
wippy run -o namespace:entry:field=value [command]
```

Overrides are applied before the linking stage, so they can affect requirement resolution.

```bash
# Set host for a service
wippy run -o wippy.relay:central.service:host=app:processes test

# Set addr for HTTP server
wippy run -o app:gateway:addr=:9090
```

Multiple overrides: use multiple `-o` flags.

## Runtime Pipeline

Entry processing follows this stage order:

1. **Override** -- applies `-o` flag values and config overrides
2. **Disable** -- removes entries matching exclusion rules (namespace patterns, entry patterns, meta filters)
3. **Link** -- resolves requirements by matching dependency parameters, applies values to targets

## Pack Files (.wapp)

```bash
wippy pack output.wapp                    # create pack
wippy pack output.wapp --bytecode "**"    # with Lua bytecode compilation
wippy pack output.wapp --exclude "test:*" # exclude entries
wippy pack output.wapp --embed assets     # embed fs.directory entries
wippy run output.wapp                     # run from pack file
```

## Binary Releases

Release binaries are built for 5 platforms (linux/amd64, linux/arm64, darwin/amd64, darwin/arm64, windows/amd64) and signed (Windows via Azure Trusted Signing, macOS via Apple codesign + notarization, binary integrity via Ed25519).

```bash
cd releases
make release WIPPY_VERSION=0.2.7a
make hub-create WIPPY_VERSION=0.2.7a CHANGELOG="..."
make hub-upload WIPPY_VERSION=0.2.7a RELEASE_ID=<id>
make hub-publish RELEASE_ID=<id>
```

## Registry Inspection

```bash
wippy registry list                            # list all entries
wippy registry list --kind "function.lua.*"    # filter by kind
wippy registry list --ns "wippy.relay"         # filter by namespace
wippy registry list --meta "type=test"         # filter by metadata
wippy registry show wippy.relay:central        # show entry details
wippy registry show entry --field source       # specific field
wippy search http                              # search hub modules
wippy readme wippy/terminal                    # fetch module README
```

## Hub Authentication

```bash
wippy auth login                    # interactive
wippy auth login --token wpy_xxx    # with token
wippy auth status                   # check status
wippy auth logout                   # remove credentials
```
