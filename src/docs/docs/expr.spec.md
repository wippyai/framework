# Lua Expr Module Specification

## Overview

The Expr module provides dynamic expression compilation and evaluation capabilities for Lua, based on the expr-lang/expr Go library. Supports compile-once-run-many pattern for optimal performance with caching, type safety, and extensive built-in functionality.

## Module Interface

### Module Loading
```lua
local expr = require("expr")
```

### Methods

#### eval(expression, environment)
Direct expression evaluation with automatic caching.

```lua
local result, err = expr.eval("2 + 3 * 4")                    -- 14
local result, err = expr.eval("price * quantity", {price = 10, quantity = 3})  -- 30
local result, err = expr.eval("all(items, {.price > 0})", {items = products})
```

Parameters:
- `expression`: String containing the expression to evaluate
- `environment`: Optional table containing variables accessible in expression

Returns:
- `result`: Evaluated result or nil on error
- `err`: Error message string or nil on success

Caching: Expressions are automatically cached by string content for performance

#### compile(expression)
Compile expression into reusable program object.

```lua
local program, err = expr.compile("price * (1 - discount)")
local result1, err1 = program:run({price = 100, discount = 0.1})  -- 90
local result2, err2 = program:run({price = 50, discount = 0.2})   -- 40
```

Parameters:
- `expression`: String containing the expression to compile

Returns:
- `program`: Program userdata object or nil on error
- `err`: Error message string or nil on success

Performance: Programs can be reused multiple times with different environments

Compiled applications not cached by default. Use `eval()` for automatic caching.

## Program Object

Compiled expression program providing efficient repeated evaluation.

### Methods

#### run(environment)
Execute compiled program with given environment.

```lua
local result, err = program:run({x = 10, y = 20})
```

Parameters:
- `environment`: Optional table containing variables accessible during execution

Returns:
- `result`: Execution result or nil on error
- `err`: Error message string or nil on success

## Expression Syntax

### Literals
- **Numbers**: `42`, `3.14`, `1e-5`, `0x1A`, `0b1010`, `0o755`
- **Strings**: `"hello"`, `'world'`, `"multi\nline"`
- **Booleans**: `true`, `false`
- **Arrays**: `[1, 2, 3]`, `["a", "b", "c"]`
- **Objects**: Access with dot notation `user.profile.age`

### Arithmetic Operators
- **Addition**: `a + b`
- **Subtraction**: `a - b`
- **Multiplication**: `a * b`
- **Division**: `a / b`
- **Modulo**: `a % b`
- **Power**: `a ** b`
- **Unary minus**: `-a`
- **Unary plus**: `+a`

### Comparison Operators
- **Equal**: `a == b`
- **Not equal**: `a != b`
- **Less than**: `a < b`
- **Less than or equal**: `a <= b`
- **Greater than**: `a > b`
- **Greater than or equal**: `a >= b`
- **In operator**: `item in array`
- **Matches operator**: `string matches "regex"`

### Logical Operators
- **Logical AND**: `a && b`
- **Logical OR**: `a || b`
- **Logical NOT**: `!a`

### Bitwise Operators
- **Bitwise AND**: `a & b`
- **Bitwise OR**: `a | b`
- **Bitwise XOR**: `a ^ b`
- **Left shift**: `a << b`
- **Right shift**: `a >> b`

### Ternary Operator
```expr
condition ? true_value : false_value
age >= 18 ? "adult" : "minor"
```

### String Operations
- **Concatenation**: `"hello" + " " + "world"`
- **Contains**: `"hello world" contains "world"`
- **Starts with**: `"hello" startsWith "hel"`
- **Ends with**: `"world" endsWith "rld"`

### Array/Slice Operations
- **Indexing**: `array[0]`, `array[-1]` (negative indexing)
- **Slicing**: `array[1:3]`, `array[:5]`, `array[2:]`
- **Range**: `1..10`, `0..len(array)-1`

### Member Access
- **Property access**: `user.name`, `config.database.host`
- **Optional chaining**: `user?.profile?.age` (returns nil if any part is nil)
- **Array element**: `items[0].price`
- **Dynamic access**: `object[key]`

## Built-in Functions

### Array Functions
- **all(array, predicate)**: `all(numbers, {# > 0})` - All elements match predicate
- **any(array, predicate)**: `any(numbers, {# > 10})` - Any element matches predicate
- **none(array, predicate)**: `none(numbers, {# < 0})` - No elements match predicate
- **one(array, predicate)**: `one(numbers, {# == 5})` - Exactly one element matches
- **filter(array, predicate)**: `filter(numbers, {# > 5})` - Filter elements
- **map(array, transform)**: `map(numbers, {# * 2})` - Transform elements
- **count(array, predicate)**: `count(numbers, {# > 5})` - Count matching elements
- **len(array)**: `len([1, 2, 3])` - Array length
- **first(array)**: `first([1, 2, 3])` - First element
- **last(array)**: `last([1, 2, 3])` - Last element

### Closure Syntax
- **Predicate**: `{# > 5}` where `#` represents current element
- **Transform**: `{# * 2}` where `#` represents current element
- **Property access**: `{.price > 100}` where `.` accesses element properties

### Math Functions
- **max(a, b, ...)**: `max(1, 2, 3)` - Maximum value
- **min(a, b, ...)**: `min(1, 2, 3)` - Minimum value
- **abs(x)**: `abs(-5)` - Absolute value
- **ceil(x)**: `ceil(3.2)` - Ceiling
- **floor(x)**: `floor(3.8)` - Floor
- **round(x)**: `round(3.6)` - Round to nearest integer
- **sqrt(x)**: `sqrt(16)` - Square root
- **pow(x, y)**: `pow(2, 8)` - Power function

### String Functions
- **len(string)**: `len("hello")` - String length
- **upper(string)**: `upper("hello")` - Uppercase
- **lower(string)**: `lower("HELLO")` - Lowercase
- **trim(string)**: `trim(" hello ")` - Remove whitespace
- **contains(string, substr)**: `contains("hello", "ell")` - Contains substring
- **startsWith(string, prefix)**: `startsWith("hello", "hel")` - Starts with prefix
- **endsWith(string, suffix)**: `endsWith("hello", "llo")` - Ends with suffix
- **split(string, separator)**: `split("a,b,c", ",")` - Split string
- **join(array, separator)**: `join(["a", "b"], ",")` - Join array elements

### Type Functions
- **type(value)**: `type(42)` - Returns type name ("int", "float", "string", "bool", "array", "map")
- **int(value)**: `int("42")` - Convert to integer
- **float(value)**: `float("3.14")` - Convert to float
- **string(value)**: `string(42)` - Convert to string

### Date/Time Functions
- **now()**: `now()` - Current timestamp
- **date(format)**: `date("2006-01-02")` - Parse date
- **duration(string)**: `duration("1h30m")` - Parse duration

## Environment Variables

Variables accessible within expressions through the environment parameter.

### Variable Access
```lua
-- Simple variables
{price = 100, quantity = 3}
-- Expression: price * quantity

-- Nested objects  
{user = {profile = {age = 25, active = true}}}
-- Expression: user.profile.age >= 18 && user.profile.active

-- Arrays
{items = {{price = 100}, {price = 50}}}
-- Expression: all(items, {.price > 0})
```

### Special Variables
- **#**: Current element in array iteration contexts
- **.**: Property accessor for current element
- **$**: Root context (implementation dependent)

## Error Handling

### Compile-time Errors
- **Syntax errors**: Invalid expression syntax
- **Type errors**: Incompatible operations
- **Undefined functions**: Unknown function calls
- **Invalid operations**: Type mismatches

### Runtime Errors
- **Division by zero**: `5 / 0`
- **Index out of bounds**: `array[100]`
- **Null access**: `nil.property`
- **Type conversion**: Cannot convert incompatible types
- **Undefined variables**: Variable not in environment

### Error Messages
```lua
local program, err = expr.compile("2 +")
-- err: "unexpected end of expression"

local result, err = program:run({})  
-- err: "undefined variable: x"
```

### Safety Features
- **Side-effect free**: Expressions cannot modify state
- **Always terminating**: No infinite loops possible
- **Sandboxed**: No access to system functions
- **Type safe**: Runtime type checking prevents errors

### Permissions
Expression evaluation requires no special permissions. All operations are read-only on provided environment data.
