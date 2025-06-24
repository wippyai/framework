# SQL Package Specification

## Overview

The SQL package provides a Lua interface to SQL databases. It exposes a consistent API for database operations that
works across different database engines (PostgreSQL, SQLite, etc.).

## Module Interface

### Loading the Module

```lua
local sql = require("sql")
```

### Constants

#### Database Type Constants

Available in `sql.type`:

- `POSTGRES` (string): PostgreSQL database
- `MYSQL` (string): MySQL database
- `SQLITE` (string): SQLite database
- `MSSQL` (string): Microsoft SQL Server database
- `ORACLE` (string): Oracle database
- `UNKNOWN` (string): Unknown or unsupported database type

### Type Conversions

The `sql.as` submodule provides functions for explicit type conversion between Lua values and SQL-specific types:

- `sql.as.int(value)`: Converts the value to a SQL INTEGER type
- `sql.as.float(value)`: Converts the value to a SQL FLOAT/REAL type
- `sql.as.binary(value)`: Converts the value to a SQL BINARY/BLOB type
- `sql.as.text(value)`: Converts the value to a SQL TEXT type
- `sql.as.null()`: Explicitly represents a SQL NULL value

These functions help ensure type compatibility between Lua's dynamic typing and SQL's strict typing system, particularly useful when Lua's number type (float) needs to be treated as a specific SQL type.

## Core Concepts

### Resource Management

- Database connections are obtained from the resource registry
- All resources (connections, statements, transactions) are automatically cleaned up when the containing unit of work
  completes
- Resources can be explicitly released earlier if needed

### Error Handling

- Most operations return nil + error message on failure
- Success is indicated by a result value + nil
- Database connections are managed as resources with proper cleanup

## Database Operations

### Getting a Database Connection

```lua
local db, err = sql.get("resource_id")
-- Parameters: resource_id (string) - Resource ID for the database
-- Returns on success: database object, nil
-- Returns on error: nil, error message
```

### Execute Query

```lua
local result, err = db:query(sql_query[, params])
-- Parameters:
--   sql_query (string): SQL query to execute
--   params (table, optional): Array of parameter values
-- Returns on success: table of result rows, nil
-- Returns on error: nil, error message
-- Note: Each row is a table with column names as keys
```

### Execute Update/Insert/Delete

```lua
local result, err = db:execute(sql_statement[, params])
-- Parameters:
--   sql_statement (string): SQL statement to execute
--   params (table, optional): Array of parameter values
-- Returns on success: result table, nil
--   result.rows_affected: Number of rows affected
--   result.last_insert_id: Last insert ID (if applicable)
-- Returns on error: nil, error message
```

### Prepare Statement

```lua
local stmt, err = db:prepare(sql_query)
-- Parameters: sql_query (string) - SQL query to prepare
-- Returns on success: statement object, nil
-- Returns on error: nil, error message
```

### Begin Transaction

```lua
local tx, err = db:begin()
-- Returns on success: transaction object, nil
-- Returns on error: nil, error message
```

### Get Database Type

```lua
local type, err = db:type()
-- Returns on success: string representing the database type, nil
-- Returns on error: nil, error message
-- Note: The returned type will be one of the constants in sql.type
```

### Release Connection

```lua
local ok, err = db:release()
-- Returns on success: true, nil
-- Returns on error: nil, error message
```

## Prepared Statement Operations

### Execute Prepared Query

```lua
local rows, err = stmt:query([params])
-- Parameters: params (table, optional) - Array of parameter values
-- Returns on success: table of result rows, nil
-- Returns on error: nil, error message
```

### Execute Prepared Statement

```lua
local result, err = stmt:execute([params])
-- Parameters: params (table, optional) - Array of parameter values
-- Returns on success: result table, nil
--   result.rows_affected: Number of rows affected
--   result.last_insert_id: Last insert ID (if applicable)
-- Returns on error: nil, error message
```

### Close Statement

```lua
local ok, err = stmt:close()
-- Returns on success: true, nil
-- Returns on error: nil, error message
```

## Transaction Operations

### Execute Query in Transaction

```lua
local rows, err = tx:query(sql_query[, params])
-- Parameters:
--   sql_query (string): SQL query to execute
--   params (table, optional): Array of parameter values
-- Returns on success: table of result rows, nil
-- Returns on error: nil, error message
```

### Execute Statement in Transaction

```lua
local result, err = tx:execute(sql_statement[, params])
-- Parameters:
--   sql_statement (string): SQL statement to execute
--   params (table, optional): Array of parameter values
-- Returns on success: result table, nil
--   result.rows_affected: Number of rows affected
--   result.last_insert_id: Last insert ID (if applicable)
-- Returns on error: nil, error message
```

### Prepare Statement in Transaction

```lua
local stmt, err = tx:prepare(sql_query)
-- Parameters: sql_query (string) - SQL query to prepare
-- Returns on success: statement object, nil
-- Returns on error: nil, error message
```

### Create Savepoint

```lua
local ok, err = tx:savepoint(name)
-- Parameters: name (string) - Savepoint name
-- Returns on success: true, nil
-- Returns on error: nil, error message
```

### Rollback to Savepoint

```lua
local ok, err = tx:rollback_to(name)
-- Parameters: name (string) - Savepoint name
-- Returns on success: true, nil
-- Returns on error: nil, error message
```

### Release Savepoint

```lua
local ok, err = tx:release(name)
-- Parameters: name (string) - Savepoint name
-- Returns on success: true, nil
-- Returns on error: nil, error message
```

### Commit Transaction

```lua
local ok, err = tx:commit()
-- Returns on success: true, nil
-- Returns on error: nil, error message
```

### Rollback Transaction

```lua
local ok, err = tx:rollback()
-- Returns on success: true, nil
-- Returns on error: nil, error message
```

## SQL Query Builder

The SQL package includes a powerful query builder that allows for creating SQL queries programmatically. This provides a
structured approach to building complex queries with proper parameter binding and escaping.

### Builder Components

The query builder is available under the `sql.builder` namespace with the following main components:

- `sql.builder.select`: Creates a SELECT query builder
- `sql.builder.insert`: Creates an INSERT query builder
- `sql.builder.update`: Creates an UPDATE query builder
- `sql.builder.delete`: Creates a DELETE query builder
- `sql.builder.expr`: Creates a raw SQL expression
- Expression conditions (`eq`, `not_eq`, `lt`, `lte`, `gt`, `gte`, `like`, `not_like`, `and_`, `or_`)
- Placeholder formats (`question`, `dollar`, `at`, `colon`)

### SELECT Builder

```lua
local select_query = sql.builder.select("column1", "column2")
  :from("table_name")
  :where("column1 = ?", value)
  :order_by("column2 DESC")
  :limit(10)
```

#### SELECT Methods

- `from(table_name)`: Specifies the FROM table
- `join(expr[, args...])`: Adds a JOIN clause
- `left_join(expr[, args...])`: Adds a LEFT JOIN clause
- `right_join(expr[, args...])`: Adds a RIGHT JOIN clause
- `inner_join(expr[, args...])`: Adds an INNER JOIN clause
- `where(condition[, args...])`: Adds a WHERE condition (can be a string, table, or Sqlizer)
- `order_by(clauses...)`: Adds ORDER BY clauses
- `group_by(columns...)`: Adds GROUP BY columns
- `having(condition[, args...])`: Adds a HAVING condition
- `limit(count)`: Adds a LIMIT clause
- `offset(count)`: Adds an OFFSET clause
- `columns(columns...)`: Adds additional columns
- `distinct()`: Adds DISTINCT to the query
- `suffix(expr[, args...])`: Adds a suffix to the query
- `placeholder_format(format)`: Sets the placeholder format
- `to_sql()`: Returns the SQL string and parameter values
- `run_with(db|tx)`: Creates an executor for this query

### INSERT Builder

```lua
local insert_query = sql.builder.insert("table_name")
  :columns("column1", "column2")
  :values(value1, value2)
```

#### INSERT Methods

- `into(table_name)`: Specifies the table to insert into
- `columns(columns...)`: Specifies the columns to insert into
- `values(values...)`: Adds a row of values
- `set_map(table)`: Sets columns and values from a table
- `select(select_builder)`: Sets a SELECT query as the source of values
- `suffix(expr[, args...])`: Adds a suffix to the query
- `options(options...)`: Adds options to the INSERT statement
- `placeholder_format(format)`: Sets the placeholder format
- `to_sql()`: Returns the SQL string and parameter values
- `run_with(db|tx)`: Creates an executor for this query

### UPDATE Builder

```lua
local update_query = sql.builder.update("table_name")
  :set("column1", value1)
  :set("column2", value2)
  :where("id = ?", id)
```

#### UPDATE Methods

- `table(table_name)`: Specifies the table to update
- `set(column, value)`: Sets a column to a value
- `set_map(table)`: Sets multiple columns from a table
- `where(condition[, args...])`: Adds a WHERE condition
- `order_by(clauses...)`: Adds ORDER BY clauses
- `limit(count)`: Adds a LIMIT clause
- `offset(count)`: Adds an OFFSET clause
- `suffix(expr[, args...])`: Adds a suffix to the query
- `from(table_name)`: Adds a FROM clause (for Postgres)
- `from_select(select_builder, alias)`: Adds a FROM (SELECT...) clause
- `placeholder_format(format)`: Sets the placeholder format
- `to_sql()`: Returns the SQL string and parameter values
- `run_with(db|tx)`: Creates an executor for this query

### DELETE Builder

```lua
local delete_query = sql.builder.delete("table_name")
  :where("id = ?", id)
```

#### DELETE Methods

- `from(table_name)`: Specifies the table to delete from
- `where(condition[, args...])`: Adds a WHERE condition
- `order_by(clauses...)`: Adds ORDER BY clauses
- `limit(count)`: Adds a LIMIT clause
- `offset(count)`: Adds an OFFSET clause
- `suffix(expr[, args...])`: Adds a suffix to the query
- `placeholder_format(format)`: Sets the placeholder format
- `to_sql()`: Returns the SQL string and parameter values
- `run_with(db|tx)`: Creates an executor for this query

### Expression Builders

```lua
-- Equality condition
local equals = sql.builder.eq({id = 1, name = "test"})

-- Inequality condition
local not_equals = sql.builder.not_eq({active = false})

-- Comparison conditions
local less_than = sql.builder.lt({age = 30})
local greater_than = sql.builder.gt({price = 100})

-- LIKE condition
local like_pattern = sql.builder.like({name = "A%"})

-- AND/OR conditions
local combined = sql.builder.and_({
  sql.builder.eq({status = "active"}),
  sql.builder.gt({created_at = "2023-01-01"})
})
```

#### Expression Methods

- `to_sql()`: Returns the SQL string and parameter values

### Query Execution

Queries built with the builder can be executed directly on a database connection or transaction:

```lua
-- Create a query
local select_query = sql.builder.select("id", "name")
  :from("users")
  :where("id > ?", 100)
  :order_by("id ASC")
  :limit(10)

-- Execute the query
local executor = select_query:run_with(db)
local results, err = executor:query()
```

#### Executor Methods

- `exec()`: Executes the query and returns results (for INSERT, UPDATE, DELETE)
- `query()`: Executes the query and returns all rows

## Example Usage

### Database Type Check

```lua
-- Get database connection from resource registry
local db, err = sql.get("main_db")
if err then error(err) end

-- Check database type
local dbType, err = db:type()
if err then error(err) end

-- Use type-specific features
if dbType == sql.type.postgres then
    -- Use PostgreSQL-specific features
elseif dbType == sql.type.sqlite then
    -- Use SQLite-specific features
else
    print("Using generic SQL features for " .. dbType)
end
```

### Basic Query Operations

```lua
-- Get database connection from resource registry
local db, err = sql.get("main_db")
if err then error(err) end

-- Execute a simple query
local users, err = db:query("SELECT * FROM users WHERE active = ?", {true})
if err then error(err) end

-- Process results
for i, user in ipairs(users) do
    print(string.format("User %d: %s (%s)", i, user.name, user.email))
end

-- Release the database when done
db:release()
```

### Transaction Example

```lua
-- Get database connection
local db, err = sql.get("main_db")
if err then error(err) end

-- Begin transaction
local tx, err = db:begin()
if err then error(err) end

-- Perform multiple operations
local ok, err = tx:execute("UPDATE accounts SET balance = balance - ? WHERE id = ?", {100, 1})
if err then
    tx:rollback()
    error("Transfer failed: " .. err)
end

ok, err = tx:execute("UPDATE accounts SET balance = balance + ? WHERE id = ?", {100, 2})
if err then
    tx:rollback()
    error("Transfer failed: " .. err)
end

-- Commit the transaction
ok, err = tx:commit()
if err then error("Commit failed: " .. err) end

-- Release the database when done
db:release()
```

### Prepared Statement Example

```lua
-- Get database connection
local db, err = sql.get("main_db")
if err then error(err) end

-- Prepare a statement
local stmt, err = db:prepare("INSERT INTO logs (timestamp, level, message) VALUES (?, ?, ?)")
if err then error(err) end

-- Execute it multiple times
local now = sql.as.int(os.time())
local result, err = stmt:execute({now, "INFO", "Application started"})
if err then error(err) end

-- Later...
result, err = stmt:execute({sql.as.int(os.time() + 60), "ERROR", "Connection failed"})
if err then error(err) end

-- Release the database when done
db:release()
```

### Savepoint Example

```lua
-- Get database connection
local db, err = sql.get("main_db")
if err then error(err) end

-- Begin transaction
local tx, err = db:begin()
if err then error(err) end

-- First operation
local ok, err = tx:execute("INSERT INTO products (name, price) VALUES (?, ?)", {"Widget", 9.99})
if err then
    tx:rollback()
    error(err)
end

-- Create savepoint
ok, err = tx:savepoint("product_added")
if err then
    tx:rollback()
    error(err)
end

-- Second operation
ok, err = tx:execute("UPDATE inventory SET count = count - 1 WHERE product_id = ?", {last_id})
if err then
    -- Roll back to savepoint instead of whole transaction
    tx:rollback_to("product_added")
    
    -- Still commit the product addition
    tx:commit()
    print("Product added but inventory not updated")
else
    -- Everything succeeded
    tx:commit()
    print("Product added and inventory updated")
end

-- Release the database when done
db:release()
```

### Type Conversion Example

```lua
-- Get database connection
local db, err = sql.get("main_db")
if err then error(err) end

-- Example using explicit type conversions
local result, err = db:execute(
    "INSERT INTO token_usage (usage_id, prompt_tokens, timestamp) VALUES (?, ?, ?)",
    { 
        usage_id,
        sql.as.int(prompt_tokens),  -- Ensure integer type for count
        sql.as.int(os.time())       -- Ensure integer type for timestamp
    }
)
if err then error(err) end

-- Example with NULL values
local description = has_description and description_text or sql.as.null()
result, err = db:execute(
    "INSERT INTO products (name, price, description) VALUES (?, ?, ?)",
    { "Widget", 9.99, description }  -- description will be NULL if has_description is false
)
if err then error(err) end

-- Release the database when done
db:release()
```

### Query Builder Examples

#### SELECT Query

```lua
-- Get database connection
local db, err = sql.get("main_db")
if err then error(err) end

-- Build a SELECT query
local query = sql.builder.select("id", "name", "email")
    :from("users")
    :where(sql.builder.and_({
        sql.builder.eq({active = true}),
        sql.builder.gt({created_at = "2023-01-01"})
    }))
    :order_by("name ASC")
    :limit(10)
    :offset(20)

-- Execute the query
local executor = query:run_with(db)
local results, err = executor:query()
if err then error(err) end

-- Process results
for i, row in ipairs(results) do
    print(string.format("User %d: %s (%s)", row.id, row.name, row.email))
end

-- Alternatively, get the SQL and execute manually
local sql_str, args = query:to_sql()
local results, err = db:query(sql_str, args)
if err then error(err) end

-- Release the database
db:release()
```

#### INSERT Query

```lua
-- Get database connection
local db, err = sql.get("main_db")
if err then error(err) end

-- Build an INSERT query with set_map
local query = sql.builder.insert("users")
    :set_map({
        name = "John Doe",
        email = "john@example.com",
        created_at = sql.as.int(os.time()),
        active = true
    })

-- Execute the query
local executor = query:run_with(db)
local result, err = executor:exec()
if err then error(err) end

print("Inserted user with ID: " .. result.last_insert_id)

-- Another example with columns and multiple rows
local batch_insert = sql.builder.insert("logs")
    :columns("timestamp", "level", "message")
    :values(sql.as.int(os.time()), "INFO", "System started")
    :values(sql.as.int(os.time()), "INFO", "User logged in")

local sql_str, args = batch_insert:to_sql()
print("SQL: " .. sql_str)

-- Release the database
db:release()
```

#### UPDATE Query

```lua
-- Get database connection
local db, err = sql.get("main_db")
if err then error(err) end

-- Build an UPDATE query
local query = sql.builder.update("users")
    :set("last_login", sql.as.int(os.time()))
    :set("login_count", sql.builder.expr("login_count + 1"))
    :where("id = ?", user_id)

-- Execute the query
local executor = query:run_with(db)
local result, err = executor:exec()
if err then error(err) end

print("Updated " .. result.rows_affected .. " rows")

-- Example with set_map and multiple conditions
local update_inactive = sql.builder.update("users")
    :set_map({
        active = false,
        updated_at = sql.as.int(os.time())
    })
    :where(sql.builder.and_({
        sql.builder.lt({last_login = sql.as.int(os.time() - 30*24*60*60)}),
        sql.builder.eq({active = true})
    }))

local sql_str, args = update_inactive:to_sql()
print("SQL: " .. sql_str)

-- Release the database
db:release()
```

#### DELETE Query

```lua
-- Get database connection
local db, err = sql.get("main_db")
if err then error(err) end

-- Build a DELETE query
local query = sql.builder.delete("logs")
    :where(sql.builder.lt({created_at = sql.as.int(os.time() - 30*24*60*60)}))
    :limit(1000)

-- Execute the query
local executor = query:run_with(db)
local result, err = executor:exec()
if err then error(err) end

print("Deleted " .. result.rows_affected .. " old log entries")

-- Example with complex conditions
local delete_inactive = sql.builder.delete("user_sessions")
    :where(sql.builder.or_({
        sql.builder.lt({last_active = sql.as.int(os.time() - 24*60*60)}),
        sql.builder.eq({valid = false})
    }))

local sql_str, args = delete_inactive:to_sql()
print("SQL: " .. sql_str)

-- Release the database
db:release()
```

#### Complex Joins

```lua
-- Get database connection
local db, err = sql.get("main_db")
if err then error(err) end

-- Build a complex SELECT with multiple joins
local query = sql.builder.select("u.id", "u.name", "p.phone", "a.city", "a.country")
    :from("users u")
    :left_join("profiles p ON u.id = p.user_id")
    :left_join("addresses a ON u.id = a.user_id AND a.is_primary = ?", true)
    :where(sql.builder.and_({
        sql.builder.eq({["u.active"] = true}),
        sql.builder.or_({
            sql.builder.like({["u.name"] = "A%"}),
            sql.builder.like({["u.name"] = "B%"})
        })
    }))
    :group_by("u.id", "u.name", "p.phone", "a.city", "a.country")
    :having("COUNT(a.id) > 0")
    :order_by("u.name ASC")

-- Execute the query
local executor = query:run_with(db)
local results, err = executor:query()
if err then error(err) end

-- Process results
for i, row in ipairs(results) do
    print(string.format("%s lives in %s, %s", row["u.name"], row["a.city"], row["a.country"]))
end

-- Release the database
db:release()
```

#### Transaction with Query Builder

```lua
-- Get database connection
local db, err = sql.get("main_db")
if err then error(err) end

-- Begin transaction
local tx, err = db:begin()
if err then error(err) end

-- Create a "transfer funds" operation using query builder
local withdraw = sql.builder.update("accounts")
    :set("balance", sql.builder.expr("balance - ?", 100))
    :where("id = ? AND balance >= ?", 1, 100)

-- Execute within transaction
local withdraw_exec = withdraw:run_with(tx)
local withdraw_result, err = withdraw_exec:exec()
if err then
    tx:rollback()
    error("Transfer failed: " .. err)
end

if withdraw_result.rows_affected == 0 then
    tx:rollback()
    error("Insufficient funds")
end

-- Deposit to the second account
local deposit = sql.builder.update("accounts")
    :set("balance", sql.builder.expr("balance + ?", 100))
    :where("id = ?", 2)

-- Execute within transaction
local deposit_exec = deposit:run_with(tx)
local deposit_result, err = deposit_exec:exec()
if err then
    tx:rollback()
    error("Transfer failed: " .. err)
end

-- Create a transaction record
local transaction_insert = sql.builder.insert("transactions")
    :set_map({
        from_account = 1,
        to_account = 2,
        amount = 100,
        timestamp = sql.as.int(os.time()),
        status = "completed"
    })

-- Execute within transaction
local trans_exec = transaction_insert:run_with(tx)
local trans_result, err = trans_exec:exec()
if err then
    tx:rollback()
    error("Transfer recording failed: " .. err)
end

-- Commit the transaction
local ok, err = tx:commit()
if err then error("Commit failed: " .. err) end

print("Transfer completed successfully")

-- Release the database
db:release()
```

#### Using Raw Expressions

```lua
-- Get database connection
local db, err = sql.get("main_db")
if err then error(err) end

-- Build a query with raw SQL expressions
local query = sql.builder.select("id", "name", 
                               sql.builder.expr("EXTRACT(YEAR FROM created_at) AS year"),
                               sql.builder.expr("COUNT(*) AS count"))
    :from("posts")
    :where(sql.builder.expr("created_at BETWEEN ? AND ?", 
                          "2023-01-01", "2023-12-31"))
    :group_by("id", "name", "year")
    :having(sql.builder.expr("COUNT(*) > ?", 5))

-- Execute the query
local executor = query:run_with(db)
local results, err = executor:query()
if err then error(err) end

-- Process results
for i, row in ipairs(results) do
    print(string.format("%s created %d posts in %d", 
                       row.name, row.count, row.year))
end

-- Release the database
db:release()
```

#### Subqueries

```lua
-- Get database connection
local db, err = sql.get("main_db")
if err then error(err) end

-- Create a subquery to find active users
local active_users = sql.builder.select("id")
    :from("users")
    :where(sql.builder.eq({active = true}))

-- Use the subquery in the main query
local query = sql.builder.select("p.id", "p.title", "u.name AS author")
    :from("posts p")
    :join("users u ON p.user_id = u.id")
    :where(sql.builder.expr("p.user_id IN (?)", 
                         sql.builder.expr("SELECT id FROM users WHERE active = ?", true)))
    :order_by("p.created_at DESC")
    :limit(10)

-- Execute the query
local executor = query:run_with(db)
local results, err = executor:query()
if err then error(err) end

-- Process results
for i, row in ipairs(results) do
    print(string.format("Post: %s by %s", row.title, row.author))
end

-- Release the database
db:release()
```

> Note: all queries are immutable, to change query make sure to create a new query object, query = query:method()