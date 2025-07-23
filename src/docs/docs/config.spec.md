# Wippy Runtime System Configuration Specification

## Overview

The Wippy Runtime System is a modular application framework that uses a registry-based architecture with namespaced components and explicit dependencies. This specification documents the configuration structure and variables used throughout the system.

## Core Concepts

### Registry Architecture

The system is built around a registry that stores versioned configuration entries. Each entry has:

- **ID**: Combination of namespace and name (`namespace:name`)
- **Kind**: Type of the component (e.g., `http.service`, `fs.directory`)
- **Metadata**: Arbitrary key-value data associated with the entry
- **Data**: The actual configuration payload

### Configuration Structure

Configuration is primarily defined in YAML files structured as:

```yaml
version: "1.0"
namespace: some.namespace

entries:
  - name: component_name
    kind: component.type
    meta:
      comment: "Description of component"
      # Other metadata
    # Component-specific configuration
```

## Component Types and Configuration

### 1. Contract Components

#### 1.1 Contract Definition (`contract.definition`)

Defines an abstract service contract with methods and schemas.

```yaml
- name: user_service
  kind: contract.definition
  meta:
    comment: "User management service contract"
    tags: ["user", "service"]
  methods:
    - name: get_user
      description: "Retrieve a user by ID"
      input_schemas:
        - format: "application/schema+json"
          definition: |
            {
              "type": "object",
              "properties": {
                "user_id": {"type": "string"}
              },
              "required": ["user_id"]
            }
      output_schemas:
        - format: "application/schema+json"
          definition: |
            {
              "type": "object",
              "properties": {
                "id": {"type": "string"},
                "name": {"type": "string"},
                "email": {"type": "string"}
              }
            }
    - name: create_user
      description: "Create a new user"
      input_schemas:
        - format: "application/schema+json"
          definition: |
            {
              "type": "object",
              "properties": {
                "name": {"type": "string"},
                "email": {"type": "string"}
              },
              "required": ["name", "email"]
            }
      output_schemas:
        - format: "application/schema+json"
          definition: |
            {
              "type": "object",
              "properties": {
                "id": {"type": "string"},
                "created_at": {"type": "string", "format": "date-time"}
              }
            }
```

**Configuration Fields:**
- `methods`: Array of method definitions
    - `name`: Method name (required)
    - `description`: Human-readable description (optional)
    - `input_schemas`: Array of input schema definitions (optional)
    - `output_schemas`: Array of output schema definitions (optional)
        - `format`: MIME type for the schema format (e.g., "application/schema+json")
        - `definition`: The actual schema definition (JSON Schema, etc.)

#### 1.2 Contract Binding (`contract.binding`)

Binds contract definitions to concrete implementations.

```yaml
- name: user_database_impl
  kind: contract.binding
  meta:
    comment: "Database implementation of user service"
    tags: ["database", "implementation"]
  contracts:
    - contract: "user:user_service"
      methods:
        get_user: "user:db_get_user_func"
        create_user: "user:db_create_user_func"
      context_required: ["database_id"]
    - contract: "audit:logging"
      methods:
        log_action: "audit:db_log_func"      
```

**Configuration Fields:**
- `contracts`: Array of contract implementations
    - `contract`: Reference to contract definition ID (namespace:name format)
    - `methods`: Map of method names to implementing function IDs
    - `context_required`: Array of required context keys (optional)

### 2. Filesystem Components

#### 2.1 Directory (`fs.directory`)

Defines a filesystem directory for the application.

```yaml
- name: files
  kind: fs.directory
  meta:
    comment: "User files and content"
  directory: ./path/to/dir/  # Root path
  mode: "0755"               # Permissions (rwxr-xr-x)
  default: true              # Whether this is the default filesystem
```

#### 2.2 S3 Storage (`cloudstorage.s3`)

Configures access to an S3-compatible object storage service.

```yaml
- name: storage
  kind: cloudstorage.s3
  bucket: "my-bucket"       # S3 bucket name
  config: "aws-config"      # Reference to AWS config
  endpoint: "http://..."    # Optional custom endpoint
  access_key_id_env: "AWS_ACCESS_KEY_ID"         # Environment variable name for access key
  secret_access_key_env: "AWS_SECRET_ACCESS_KEY" # Environment variable name for secret key
```

### 3. HTTP Components

#### 3.1 HTTP Service (`http.service`)

Defines an HTTP server instance.

```yaml
- name: gateway
  kind: http.service
  addr: ":8080"          # Listen address
  timeouts:
    read: "30s"          # Read timeout
    write: "30s"         # Write timeout
    idle: "60s"          # Idle connection timeout
  lifecycle:
    auto_start: true     # Start automatically
  host:
    buffer_size: 1024    # Internal job channel buffer size
    worker_count: 8      # Number of worker goroutines
```

#### 3.2 HTTP Router (`http.router`)

Defines a group of endpoints with a common URL prefix.

```yaml
- name: api
  kind: http.router
  meta:
    server: gateway      # Reference to HTTP server
  prefix: /api/v1/       # URL prefix
  middleware:            # Middleware chain to apply
    - cors
    - token_auth
  options:               # Middleware-specific options
    token_store: app.security:tokens
    allow_origins: "*"
```

#### 3.3 HTTP Endpoint (`http.endpoint`)

Defines a single API endpoint.

```yaml
- name: create_page
  kind: http.endpoint
  meta:
    router: app:api      # Reference to router
  method: GET            # HTTP method
  path: /pages/create    # Endpoint path
  func: create_page_func # Function to handle requests
```

#### 3.4 Static Server (`http.static`)

Serves static files from a filesystem.

```yaml
- name: frontend
  kind: http.static
  meta:
    server: gateway
  path: /                # URL path to serve under
  fs: public             # Filesystem to serve from
  directory: /           # Directory within filesystem
  options:
    index: "index.html"  # Index file
    spa: true            # Enable SPA mode (serve index for all paths)
```

### 4. Security Components

#### 4.1 Token Store (`security.token_store`)

Manages authentication tokens.

```yaml
- name: tokens
  kind: security.token_store
  store: session          # Store to use for tokens
  token_length: 32        # Token length in bytes
  token_key: "${ENV_VAR}" # Key for token signing
  default_expiration: 24h # Default token lifetime
```

#### 4.2 Security Policy (`security.policy`)

Defines authorization rules.

```yaml
- name: user.policy
  kind: security.policy
  groups: ["app:user"]    # Group membership
  policy:
    actions: "*"          # Actions covered (wildcard or list)
    resources: "*"        # Resources covered (wildcard or list)
    effect: "allow"       # Effect (allow or deny)
    conditions:           # Optional conditions
      - field: "actor.meta.role"
        operator: "eq"
        value: "admin"
```

### 5. Data Storage Components

#### 5.1 Memory Store (`store.memory`)

In-memory key-value store.

```yaml
- name: cache
  kind: store.memory
  max_size: 5000          # Maximum entries
  cleanup_interval: 5m    # Expired entry cleanup interval
  lifecycle:
    auto_start: true
```

#### 5.2 SQL Database (`db.sql.sqlite`, `db.sql.postgres`, etc.)

SQL database connection.

**SQLite:**
```yaml
- name: db
  kind: db.sql.sqlite
  file: "./data/app.db"   # Database file path
  pool:
    max_open: 10          # Maximum open connections
    max_idle: 5           # Maximum idle connections
    max_lifetime: 1h      # Maximum connection lifetime
```

**PostgreSQL/MySQL/etc:**
```yaml
- name: db
  kind: db.sql.postgres
  host: "localhost"
  port: 5432
  database: "myapp"
  username: "user"
  password: "pass"
  pool:
    max_open: 10
    max_idle: 5
    max_lifetime: 1h
```

### 6. Process Components

#### 6.1 Process Host (`process.host`)

Executes and manages processes.

```yaml
- name: processes
  kind: process.host
  host:
    workers: 8            # Number of worker threads
    max_processes: 1000   # Maximum concurrent processes
  lifecycle:
    auto_start: true
```

#### 6.2 Process Service (`process.service`)

Defines a supervised process.

```yaml
- name: background_job
  kind: process.service
  process: job_processor  # Process to run
  host: system:processes  # Host to run on
  input: []               # Input data
  lifecycle:
    auto_start: true
```

### 7. Lua Components

#### 7.1 Lua Function (`function.lua`)

Defines a Lua function.

```yaml
- name: handler
  kind: function.lua
  source: file://handler.lua  # Source code
  method: handle              # Method to call
  modules: ["http", "json"]   # Required modules
  imports:                    # Library imports
    utils: app.common:utils
```

#### 7.2 Lua Library (`library.lua`)

Reusable Lua code library.

```yaml
- name: utils
  kind: library.lua
  source: file://utils.lua
  modules: ["crypto", "base64"]
```

#### 7.3 Lua Process (`process.lua`)

Long-running Lua process.

```yaml
- name: background_worker
  kind: process.lua
  source: file://worker.lua
  method: run
  modules: ["json", "store"]
```

### 8. Template Components

#### 8.1 Template Set (`template.set`)

Defines a template set with shared configuration.

```yaml
- name: app_templates
  kind: template.set
  engine:
    development_mode: true              # Disables caching for development
    delimiters:
      left: "{{"                        # Left delimiter (default: "{{")
      right: "}}"                       # Right delimiter (default: "}}")
      comment_left: "{*"                # Left comment delimiter (default: "{*")
      comment_right: "*}"               # Right comment delimiter (default: "*}")
    extensions: [".jet", ".html.jet"]   # File extensions for templates
    globals:                            # Global variables for all templates
      siteName: "My Application"
      version: "1.0.3"
      copyrightYear: 2025
```

#### 8.2 Template (`template.jet`)

Defines an individual template within a set.

```yaml
- name: welcome_email
  kind: template.jet
  meta:
    comment: "Welcome email template"
  source: |
    <!DOCTYPE html>
    <html>
    <head>
      <title>Welcome to {{ siteName }}</title>
    </head>
    <body>
      <h1>Hello, {{ user.name }}!</h1>
      <p>Welcome to {{ siteName }}. Your account has been created successfully.</p>
    </body>
    </html>
  set: app:app_templates           # Reference to template set
```

> Read more about using templates in templates and jet docs.

## Lifecycle Configuration

Many components support lifecycle management with the following options:

```yaml
lifecycle:
  auto_start: true         # Start automatically when system starts
  start_timeout: 10s       # Maximum time allowed for start
  stop_timeout: 10s        # Maximum time allowed for stop
  stable_threshold: 5s     # Time running to be considered stable
  depends_on:              # Component dependencies
    - other.component
  restart:                 # Retry policy for failures
    initial_delay: 1s      # Initial retry delay
    max_delay: 90s         # Maximum retry delay
    backoff_factor: 2.0    # Exponential backoff multiplier
    jitter: 0.1            # Random variation factor
    max_attempts: 0        # Maximum retry attempts (0 = infinite)
```

## Registry Metadata

Metadata can be attached to any registry entry as key-value pairs:

```yaml
meta:
  comment: "Description"              # Human-readable description
  depends_on: ["ns:component"]        # Component dependencies
  tags: ["tag1", "tag2"]              # Categorization tags
  server: gateway                     # Component references
  router: api
  type: "component_type"              # Type classification
  timestamp: "2025-03-16T10:00:00Z"   # Timestamps for operations
```

## Environment Variable Interpolation

Configuration values can reference environment variables:

```yaml
token_key: "${ENV_TOKEN_KEY:-default-value}"
```

This syntax allows for:
- Reading from environment variable `ENV_TOKEN_KEY`
- Providing a default value `default-value` if the variable is not set