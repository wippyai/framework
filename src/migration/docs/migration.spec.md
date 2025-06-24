# Database Migration Guide for AI Systems

## Overview

This guide outlines the best practices for creating and managing database migrations in a structured, reliable way. As
an AI system tasked with writing database migrations, following these patterns will ensure consistent, maintainable, and
reversible database schema changes.

## Migration Architecture

The migration system is built on several core components:

1. **Migration Core**: Provides the DSL (Domain-Specific Language) for defining migrations
2. **Migration Repository**: Tracks which migrations have been applied in the database
3. **Migration Runner**: Handles discovery and execution of migrations
4. **SQL Module**: Provides the underlying database access layer

## Migration Structure

### Core Components

Each migration consists of:

1. **Description**: A concise, meaningful description of what the migration does
2. **Database Type**: The specific database engine (SQLite, PostgreSQL, MySQL)
3. **Up Migration**: Forward operation that applies the schema change
4. **Down Migration**: Rollback operation that reverts the schema change
5. **Post-Migration Tasks** (optional): Additional operations after the main migration

### Migration Template

```lua
local function define_migration()
    migration("Description of what this migration does", function()
        -- Define database-specific implementation
        database("sqlite", function()
            -- Define forward migration
            up(function(db)
                -- SQL or code to apply changes
                -- The `db` parameter is a transaction object, not a connection
                return db:execute([[
                    CREATE TABLE example (
                        id INTEGER PRIMARY KEY,
                        name TEXT NOT NULL
                    )
                ]])
            end)
            
            -- Define rollback
            down(function(db)
                -- SQL or code to revert changes
                db:execute("DROP TABLE IF EXISTS example")
                
                
            end)
            
            -- Optional post-migration tasks
            after(function(db)
                -- Additional operations after successful migration
                -- The `db` parameter is the same transaction object
            end)
        end)
        
        -- You can define implementations for multiple database types
        database("postgres", function()
            -- PostgreSQL-specific implementation
        end)
    end)
end

-- Return the migration function
return require("migration").define(define_migration)
```

## Understanding the SQL Transaction Interface

In migration functions (`up`, `down`, and `after`), the `db` parameter is a **transaction object**, not a direct
database connection. This is crucial to understand as:

1. The transaction automatically rolls back if any error occurs
2. You must return an error explicitly to trigger a rollback
3. All operations in the migration run in a single transaction

### Key Transaction Methods

```lua
-- Execute a SQL query that returns rows
local rows, err = db:query(sql_query[, params])
-- Parameters:
--   sql_query (string): SQL query to execute (SELECT, etc.)
--   params (table, optional): Array of parameter values to bind
-- Returns on success: table of result rows, nil
-- Returns on error: nil, error message

-- Execute a SQL statement that modifies data
local result, err = db:execute(sql_statement[, params])
-- Parameters:
--   sql_statement (string): SQL statement (CREATE, ALTER, INSERT, etc.)
--   params (table, optional): Array of parameter values to bind
-- Returns on success: result table, nil
--   result.rows_affected: Number of rows affected
--   result.last_insert_id: Last insert ID (if available)
-- Returns on error: nil, error message

-- Prepare a SQL statement
local stmt, err = db:prepare(sql_query)
-- Parameters: sql_query (string) - SQL query to prepare
-- Returns on success: statement object, nil
-- Returns on error: nil, error message
```

### Binding Parameters

Always use parameterized queries to prevent SQL injection:

```lua
-- CORRECT: Using parameters (question mark placeholders)
db:execute("CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT)")
db:execute("INSERT INTO users (name) VALUES (?)", {"John"})

-- INCORRECT: String concatenation (vulnerable to SQL injection)
local name = "John"
db:execute("INSERT INTO users (name) VALUES ('" .. name .. "')")
```

Parameter binding works like an ordered array:

```lua
-- The parameters array maps to the question marks in order
db:execute("INSERT INTO users (name, email, age) VALUES (?, ?, ?)", 
           {"John", "john@example.com", 30})
```

## Best Practices

### 1. Descriptive Naming

Use clear, descriptive names that indicate exactly what the migration does:

```lua
migration("Create users table with authentication fields", function()
    -- Migration code
end)
```

### 2. Atomic Changes

Each migration should perform a single logical operation:

✅ **Good**: Create a table, Add a column, Create an index  
❌ **Avoid**: Multiple unrelated schema changes in one migration

### 3. Complete Rollbacks

Always provide a thorough `down` function that fully reverses the migration:

```lua
up(function(db)
    db:execute("ALTER TABLE users ADD COLUMN email TEXT")
end)

down(function(db)
    db:execute("ALTER TABLE users DROP COLUMN email")
end)
```

### 4. Transaction Safety

All migrations run in transactions, which means:

- All changes in a migration succeed or fail together
- Some DDL operations may implicitly commit in certain databases
- Return errors explicitly to trigger a rollback:

```lua
up(function(db)
    local result, err = db:execute("CREATE TABLE users (...)")
    if err then
         error(err)
    end
    
    result, err = db:execute("CREATE INDEX idx_user_email ON users(email)")
    if err then
          error(err)
    end
end)
```

### 5. Database-Specific Code

Provide separate implementations for each database type:

```lua
database("sqlite", function()
    up(function(db)
        -- SQLite implementation
        db:execute("CREATE TABLE users (id INTEGER PRIMARY KEY, ...)")
    end)
end)

database("postgres", function()
    up(function(db)
        -- PostgreSQL implementation
        db:execute("CREATE TABLE users (id SERIAL PRIMARY KEY, ...)")
    end)
end)
```

### 6. Error Handling

Return errors clearly for better diagnostics:

```lua
up(function(db)
    local success, err = db:execute([[
        CREATE TABLE users (
            id INTEGER PRIMARY KEY,
            username TEXT NOT NULL UNIQUE
        )
    ]])
    
    if err then
          error(err)
    end
end)
```

### 7. Idempotent Migrations

When possible, make migrations that can be applied multiple times without error:

```lua
up(function(db)
    db:execute("CREATE TABLE IF NOT EXISTS users (...)")
end)
```

## Common Migration Patterns

### Creating Tables

```lua
up(function(db)
    db:execute([[
        CREATE TABLE products (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            price REAL NOT NULL,
            created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
    ]])
end)

down(function(db)
    db:execute("DROP TABLE IF EXISTS products")
end)
```

### Adding Columns

```lua
up(function(db)
    db:execute("ALTER TABLE products ADD COLUMN description TEXT")
end)

down(function(db)
    -- SQLite doesn't support DROP COLUMN directly
    -- For SQLite, you might need a more complex migration
    -- For other databases:
    db:execute("ALTER TABLE products DROP COLUMN description")
end)
```

### Creating Indexes

```lua
up(function(db)
     db:execute("CREATE INDEX idx_products_name ON products(name)")
end)

down(function(db)
     db:execute("DROP INDEX IF EXISTS idx_products_name")
end)
```

### Seeding Data

```lua
up(function(db)
    -- Insert multiple rows
     db:execute([[
        INSERT INTO roles (name) VALUES 
        ('admin'), ('user'), ('guest')
    ]])
end)

down(function(db)
     db:execute("DELETE FROM roles WHERE name IN ('admin', 'user', 'guest')")
end)
```

### Using Prepared Statements

For multiple similar operations:

```lua
up(function(db)
    -- Create prepared statement
    local stmt, err = db:prepare("INSERT INTO users (name, email) VALUES (?, ?)")
    if err then
          error(err)
    end
    
    -- Execute for multiple rows
    local users = {
        {"Alice", "alice@example.com"},
        {"Bob", "bob@example.com"},
        {"Charlie", "charlie@example.com"}
    }
    
    for _, user in ipairs(users) do
        local result, err = stmt:execute(user)
        if err then
              error(err)
        end
    end
end)
```

### Complex Schema Changes

For SQLite, which has limited ALTER TABLE support:

```lua
up(function(db)
    -- Start transaction (already in a transaction, but shown for clarity)
    
    -- 1. Create temporary table with new schema
    local result, err = db:execute([[
        CREATE TABLE users_new (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT NOT NULL,  -- New column
            created_at INTEGER NOT NULL
        )
    ]])
    if err then   error(err) end
    
    -- 2. Copy data from old table to new table
    result, err = db:execute([[
        INSERT INTO users_new (id, name, created_at)
        SELECT id, name, created_at FROM users
    ]])
    if err then   error(err) end
    
    -- 3. Drop old table
    result, err = db:execute("DROP TABLE users")
    if err then   error(err) end
    
    -- 4. Rename new table to old table name
    result, err = db:execute("ALTER TABLE users_new RENAME TO users")
    if err then   error(err) end
    
    return true
end)
```

## Testing Migrations

Before finalizing any migration:

1. Test the `up` migration to ensure it applies correctly
2. Test the `down` migration to verify it properly rolls back changes
3. Verify that running `up` followed by `down` returns the database to its original state
4. Check that running `up` twice (with proper error handling) doesn't break the system

## Troubleshooting

Common issues to watch for:

- **Syntax errors**: Ensure SQL is compatible with the target database version
- **Missing dependencies**: Make sure referenced tables/columns exist
- **Constraint violations**: Check if data meets new constraints
- **Transaction limitations**: Be aware of operations that can't be in transactions
- **Permission issues**: Verify the database user has appropriate permissions

## Database-Specific Considerations

### SQLite

- Limited ALTER TABLE support (can't drop columns directly)
- INTEGER PRIMARY KEY is autoincrement
- Transaction behavior differs from other databases

### PostgreSQL

- Use SERIAL for auto-incrementing integers
- Has rich constraint and index options
- Supports schema namespaces

### MySQL/MariaDB

- InnoDB engine needed for transactions
- AUTO_INCREMENT requires PRIMARY KEY
- Case sensitivity depends on collation

By following these guidelines, you'll create robust, maintainable database migrations that can be confidently applied
and rolled back when needed.