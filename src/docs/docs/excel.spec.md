# Lua Excel API Module Specification

## Overview

The `excel` module provides a simple interface for reading, writing, and manipulating Excel files (XLSX format) within a Lua environment.

## Module Interface

### Module Loading

```lua
local excel = require("excel")
```

### Module Functions

#### `excel.new()`

Creates a new Excel workbook.

Returns:

- `workbook`: A workbook object (or nil on error).
- `error`: Error message (string, or nil on success).

#### `excel.open(reader)`

Opens an existing Excel file from a reader object.

Parameters:

- `reader`: A file or stream object obtained from the filesystem module.

Returns:

- `workbook`: A workbook object (or nil on error).
- `error`: Error message (string, or nil on success).

### Workbook Methods

#### `workbook:new_sheet(name: string)`

Creates a new sheet with the given name, or returns the existing sheet with that name.

Parameters:

- `name`: Name for the new sheet.

Returns:

- `index`: Index of the new sheet (or nil on error).
- `error`: Error message (string, or nil on success).

#### `workbook:get_sheet_list()`

Returns a list of all sheet names in the workbook.

Returns:

- `sheets`: Array of sheet names.
- `error`: Error message (string, or nil on success).

#### `workbook:get_rows(sheet_name: string)`

Gets all rows from a sheet. All values are returned as strings.

Parameters:

- `sheet_name`: Name of the sheet.

Returns:

- `rows`: Two-dimensional array containing row values.
- `error`: Error message (string, or nil on success).

#### `workbook:set_cell_value(sheet: string, cell: string, value: any)`

Sets the value of a cell.

Parameters:

- `sheet`: Name of the sheet.
- `cell`: Cell reference (e.g., "A1").
- `value`: Value to set (string, number, boolean).

Returns:

- `error`: Error message (string, or nil on success).

#### `workbook:write_to(writer)`

Writes the workbook to an object with :write method.

Parameters:

- `writer`: An object that have :write method.

Returns:

- `error`: Error message (string, or nil on success).

#### `workbook:close()`

Closes the workbook and releases resources.

Returns:

- `error`: Error message (string, or nil on success).

## Error Handling

Most methods return either the expected value and nil (for success) or nil and an error message (for failure). The `set_cell_value`, `write_to`, and `close` methods return only an error message or nil.

Example error handling:

```lua
local wb, err = excel.new()
if err then
    print("Failed to create workbook:", err)
    return
end

local index, err = wb:new_sheet("MySheet")
if err then
    print("Failed to create sheet:", err)
    return
end

-- Always close the workbook when done
local err = wb:close()
if err then
    print("Failed to close workbook:", err)
end
```

## Example Usage

### Creating a New Workbook

```lua
local excel = require("excel")

-- Create a new workbook
local wb, err = excel.new()
if err then
    print("Error creating workbook:", err)
    return
end

-- Add a new sheet
local index, err = wb:new_sheet("Data")
if err then
    print("Error creating sheet:", err)
    return
end

-- Write data to cells
wb:set_cell_value("Data", "A1", "Name")
wb:set_cell_value("Data", "B1", "Score")
wb:set_cell_value("Data", "A2", "Alice")
wb:set_cell_value("Data", "B2", 95)

-- Get sheet list
local sheets, err = wb:get_sheet_list()
if err then
    print("Error getting sheet list:", err)
    return
end

print("Sheets in the workbook:")
for i, name in ipairs(sheets) do
    print(i, name)
end

-- Close the workbook when done
local err = wb:close()
if err then
    print("Error closing workbook:", err)
end
```

### Opening an Existing Workbook

```lua
local excel = require("excel")
local fs = require("fs")

-- Get access to the filesystem
local fsObj = fs.default()

-- Open an Excel file
local file = fsObj:open("data.xlsx", "r")
if not file then
    print("Error opening file")
    return
end

-- Open the workbook from the file reader
local wb, err = excel.open(file)
file:close()  -- Close the file after reading

if err then
    print("Error opening workbook:", err)
    return
end

-- Read data from a sheet
local rows, err = wb:get_rows("Sheet1")
if err then
    print("Error reading rows:", err)
    return
end

-- Process the data
for i, row in ipairs(rows) do
    local rowData = {}
    for j, cell in ipairs(row) do
        table.insert(rowData, cell)
    end
    print(table.concat(rowData, ", "))
end

-- Close the workbook when done
wb:close()
```

### Writing a Workbook to a File

```lua
local excel = require("excel")
local fs = require("fs")

-- Get access to the filesystem
local fsObj = fs.default()

-- Create a new workbook
local wb, err = excel.new()
if err then
    print("Error creating workbook:", err)
    return
end

-- Add data to the workbook
wb:new_sheet("Report")
wb:set_cell_value("Report", "A1", "Monthly Report")
wb:set_cell_value("Report", "A2", "Month")
wb:set_cell_value("Report", "B2", "Sales")

for i = 1, 12 do
    local month = os.date("%B", os.time({year=2023, month=i, day=1}))
    wb:set_cell_value("Report", "A" .. (i+2), month)
    wb:set_cell_value("Report", "B" .. (i+2), math.random(1000, 5000))
end

-- Open a file for writing
local file = fsObj:open("report.xlsx", "w")
if not file then
    print("Error opening output file")
    wb:close()
    return
end

-- Write the workbook to the file
local err = wb:write_to(file)
if err then
    print("Error writing workbook:", err)
    file:close()
    wb:close()
    return
end

-- Close the file and workbook
file:close()
wb:close()

print("Report successfully written to report.xlsx")
```

### Report Generation Example

```lua
local excel = require("excel")
local fs = require("fs")

-- Get the filesystem
local fsObj = fs.default()

-- Open a file for reading
local file = fsObj:open("input.xlsx", "r")
if not file then
    print("Error opening input file")
    return
end

-- Open the workbook
local wb, err = excel.open(file)
file:close()

if err then
    print("Error opening workbook:", err)
    return
end

-- Modify the workbook
wb:new_sheet("Report")
wb:set_cell_value("Report", "A1", "Generated Report")
wb:set_cell_value("Report", "A2", "Date")
wb:set_cell_value("Report", "B2", os.date("%Y-%m-%d"))

-- Read data from one sheet and write to another
local data, err = wb:get_rows("RawData")
if err then
    print("Error reading data:", err)
    wb:close()
    return
end

-- Process data
for i, row in ipairs(data) do
    if i > 1 then  -- Skip header row
        wb:set_cell_value("Report", "A" .. (i + 2), row[1])
        wb:set_cell_value("Report", "B" .. (i + 2), row[2])
    end
end

-- Open an output file
local outFile = fsObj:open("output.xlsx", "w")
if not outFile then
    print("Error opening output file")
    wb:close()
    return
end

-- Write the workbook to the output file
local err = wb:write_to(outFile)
if err then
    print("Error writing workbook:", err)
    outFile:close()
    wb:close()
    return
end

outFile:close()

-- Close workbook to ensure all resources are released
local err = wb:close()
if err then
    print("Error closing workbook:", err)
    return
end

print("Report generation complete")
```
