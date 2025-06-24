# Lua CloudStorage API Module Specification

## Overview

The `cloudstorage` module provides an interface for interacting with cloud storage providers within a Lua environment.
It allows operations such as listing, uploading, downloading, and deleting objects, as well as generating presigned URLs
for temporary access.

## Module Interface

### Module Loading

```lua
local cloudstorage = require("cloudstorage")
```

### Module Functions

#### `cloudstorage.get(resource_id)`

Retrieves a cloud storage instance by its resource ID.

Parameters:

- `resource_id`: String identifier for the cloud storage resource.

Returns:

- `storage`: A cloud storage object (or nil on error).
- `error`: Error message (string, or nil on success).

## Storage Methods

### Object Listing

#### `storage:list_objects([options])`

Lists objects in the cloud storage bucket with optional filtering.

Parameters:

- `options`: (optional) Table containing listing options:
    - `prefix`: String prefix to filter objects by key.
    - `max_keys`: Maximum number of keys to return.
    - `continuation_token`: Token for pagination from a previous truncated response.

Returns:

- `result`: Table containing:
    - `objects`: Array of object metadata tables, each with:
        - `key`: Object key (string).
        - `size`: Object size in bytes (number).
        - `content_type`: MIME type of the object (string).
        - `etag`: Entity tag for the object (string).
    - `is_truncated`: Boolean indicating if more results are available.
    - `next_continuation_token`: Token to use for the next page of results (if truncated).

### Object Download

#### `storage:download_object(key, writer, [options])`

Downloads an object from cloud storage to a writer.

Parameters:

- `key`: Object key to download.
- `writer`: An object that have obj:write operation.
- `options`: (optional) Table containing download options:
    - `range`: HTTP range header value (e.g., "bytes=0-1023").

Returns:

- `success`: Boolean indicating if the download was successful.
- `error`: Error message (string, or nil on success).

### Object Upload

#### `storage:upload_object(key, content)`

Uploads content to cloud storage.

Parameters:

- `key`: Object key to create or overwrite.
- `content`: Either a string or an object that has obj:read operation.

Returns:

- `success`: Boolean indicating if the upload was successful.
- `error`: Error message (string, or nil on success).

### Object Deletion

#### `storage:delete_objects(keys)`

Deletes one or more objects from cloud storage.

Parameters:

- `keys`: Array of object keys to delete.

Returns:

- `success`: Boolean indicating if all deletes were successful.
- `error`: Error message (string, or nil on success).

### Presigned URLs

#### `storage:presigned_get_url(key, [options])`

Generates a presigned URL for temporary GET access to an object.

Parameters:

- `key`: Object key to generate the URL for.
- `options`: (optional) Table containing URL options:
    - `expiration`: Duration in seconds for URL validity (defaults to 3600).

Returns:

- `url`: Presigned URL as a string (or nil on error).
- `error`: Error message (string, or nil on success).

#### `storage:presigned_put_url(key, [options])`

Generates a presigned URL for temporary PUT access to upload an object.

Parameters:

- `key`: Object key to generate the URL for.
- `options`: (optional) Table containing URL options:
    - `expiration`: Duration in seconds for URL validity (defaults to 3600).
    - `content_type`: MIME type for the uploaded content.
    - `content_length`: Expected size of the uploaded content in bytes.

Returns:

- `url`: Presigned URL as a string (or nil on error).
- `error`: Error message (string, or nil on success).

## Error Handling

Most methods return either the expected value and nil (for success) or nil and an error message (for failure). Some
methods like `download_object`, `upload_object`, and `delete_objects` return a boolean success value and an optional
error message.

Example error handling:

```lua
local cloudstorage = require("cloudstorage")
local storage, err = cloudstorage.get("my_bucket")
if err then
    print("Failed to get storage:", err)
    return
end

local result, err = storage:list_objects()
if err then
    print("Failed to list objects:", err)
    return
end

-- Process the results
for _, obj in ipairs(result.objects) do
    print(obj.key, obj.size, obj.content_type)
end
```

## Example Usage

### Listing Objects

```lua
local cloudstorage = require("cloudstorage")

-- Get the storage resource
local storage, err = cloudstorage.get("my_bucket")
if err then
    print("Error getting storage:", err)
    return
end

-- List all objects
local result = storage:list_objects()
print("Objects in storage:")
for i, obj in ipairs(result.objects) do
    print(i, obj.key, obj.size, obj.content_type)
end

-- List objects with a prefix and limit
local filtered = storage:list_objects({
    prefix = "documents/",
    max_keys = 10
})

print("Filtered objects:")
for i, obj in ipairs(filtered.objects) do
    print(i, obj.key, obj.size)
end

-- Handle pagination if results were truncated
if filtered.is_truncated then
    local next_page = storage:list_objects({
        prefix = "documents/",
        max_keys = 10,
        continuation_token = filtered.next_continuation_token
    })
    
    print("Additional objects:")
    for i, obj in ipairs(next_page.objects) do
        print(i, obj.key, obj.size)
    end
end
```

### Downloading and Uploading Objects

```lua
local cloudstorage = require("cloudstorage")
local fs = require("fs")  -- Assuming a filesystem module is available

-- Get the storage resource
local storage, err = cloudstorage.get("my_bucket")
if err then
    print("Error getting storage:", err)
    return
end

-- Create a buffer for downloading
local fs_instance = fs.get("system:fs")
local file = fs_instance:open("downloaded_file.txt", "w")
if not file then
    print("Error opening file for writing")
    return
end

-- Download an object to the file
local success = storage:download_object("readme.txt", file)
if not success then
    print("Failed to download object")
    file:close()
    return
end

file:close()
print("File downloaded successfully")

-- Upload a string as an object
local content = "Hello, this is a test upload!"
local success = storage:upload_object("hello.txt", content)
if not success then
    print("Failed to upload string content")
    return
end

print("String content uploaded successfully")

-- Upload a file
local upload_file = fs_instance:open("local_file.txt", "r")
if not upload_file then
    print("Error opening file for reading")
    return
end

local success = storage:upload_object("uploaded_file.txt", upload_file)
upload_file:close()

if not success then
    print("Failed to upload file")
    return
end

print("File uploaded successfully")
```

### Generating Presigned URLs

```lua
local cloudstorage = require("cloudstorage")

-- Get the storage resource
local storage, err = cloudstorage.get("my_bucket")
if err then
    print("Error getting storage:", err)
    return
end

-- Generate a presigned URL for downloading
local get_url = storage:presigned_get_url("documents/report.pdf", {
    expiration = 1800  -- 30 minutes
})

print("Download URL (valid for 30 minutes):", get_url)

-- Generate a presigned URL for uploading
local put_url = storage:presigned_put_url("uploads/user_photo.jpg", {
    expiration = 3600,  -- 1 hour
    content_type = "image/jpeg",
    content_length = 1024 * 1024  -- 1MB
})

print("Upload URL (valid for 1 hour):", put_url)
```

### Deleting Objects

```lua
local cloudstorage = require("cloudstorage")

-- Get the storage resource
local storage, err = cloudstorage.get("my_bucket")
if err then
    print("Error getting storage:", err)
    return
end

-- Delete a single object
local success = storage:delete_objects({"temporary.txt"})
if not success then
    print("Failed to delete object")
    return
end

print("Object deleted successfully")

-- Delete multiple objects at once
local success = storage:delete_objects({
    "logs/2023-01-01.log",
    "logs/2023-01-02.log",
    "logs/2023-01-03.log"
})

if not success then
    print("Failed to delete multiple objects")
    return
end

print("Multiple objects deleted successfully")
```

### Complete Storage Workflow

```lua
local cloudstorage = require("cloudstorage")
local fs = require("fs")

-- Get the filesystem
local fs_instance = fs.default()

-- Get the storage resource
local storage, err = cloudstorage.get("my_bucket")
if err then
    print("Error getting storage:", err)
    return
end

-- Create a text file
local content = "This is a test file for cloud storage operations."
local success = storage:upload_object("test/sample.txt", content)
if not success then
    print("Failed to upload test file")
    return
end

-- List the objects in the test directory
local result = storage:list_objects({
    prefix = "test/"
})

print("Objects in test directory:")
for _, obj in ipairs(result.objects) do
    print(obj.key, obj.size, "bytes")
end

-- Generate a download URL
local url = storage:presigned_get_url("test/sample.txt", {
    expiration = 300  -- 5 minutes
})

print("You can download the file using this URL for the next 5 minutes:")
print(url)

-- Download the file we just uploaded
local file = fs_instance:open("downloaded_sample.txt", "w")
if not file then
    print("Error opening local file for writing")
    return
end

local success = storage:download_object("test/sample.txt", file)
file:close()

if not success then
    print("Failed to download test file")
    return
end

print("File downloaded successfully")

-- Clean up by deleting the test file
local success = storage:delete_objects({"test/sample.txt"})
if not success then
    print("Failed to delete test file")
    return
end

print("Test file deleted successfully")
```
