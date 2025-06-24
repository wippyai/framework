# Lua HTTP Context Module Specification

## Overview

The `http` module provides access to the current HTTP request and response within a Lua environment, typically in the
context of a web server handler. It allows reading request data (method, path, headers, query parameters, body) and
writing response data (status, headers, body). It also supports advanced features like streaming request bodies, chunked
transfer encoding, and server-sent events.

## Module Interface

### Module Loading

```lua
local http = require("http")
```

### Constants

The module provides several tables containing constants for common HTTP elements:

#### `http.METHOD`

- `GET`
- `POST`
- `PUT`
- `DELETE`
- `PATCH`
- `HEAD`
- `OPTIONS`

#### `http.STATUS`

- `OK` (200)
- `CREATED` (201)
- `NO_CONTENT` (204)
- `BAD_REQUEST` (400)
- `UNAUTHORIZED` (401)
- `NOT_FOUND` (404)
- `INTERNAL_ERROR` (500)

#### `http.CONTENT`

- `JSON` ("application/json")
- `FORM` ("application/x-www-form-urlencoded")
- `MULTIPART` ("multipart/form-data")
- `TEXT` ("text/plain")
- `STREAM` ("application/octet-stream")

#### `http.TRANSFER`

- `CHUNKED` ("chunked")
- `SSE` ("sse")

#### `http.ERROR`

- `PARSE_FAILED`
- `INVALID_STATE`
- `WRITE_FAILED`
- `STREAM_ERROR`

### Request Object

The `http.request()` function creates a new `Request` object representing the current HTTP request.

#### `http.request(options: table)`

Creates a new `Request` object.

Parameters:

- `options`: (Optional) A table with the following optional fields:
  - `timeout`: Request timeout in milliseconds (number).
  - `max_body`: Maximum request body size in bytes (number).

Returns:

- `request`: A `Request` object (or nil on error).
- `error`: An error message string (or nil on success).

#### Request Methods

##### `request:method()`

Returns the HTTP method of the request.

Returns:

- `method`: The HTTP method (string).
- `error`: nil

##### `request:path()`

Returns the path of the request.

Returns:

- `path`: The request path (string).
- `error`: nil

##### `request:query(key: string)`

Returns the value of the specified query parameter.

Parameters:

- `key`: The query parameter name.

Returns:

- `value`: The value of the query parameter (string, or nil if not found).
- `error`: Error message (string, or nil on success).

##### `request:header(key: string)`

Returns the value of the specified header.

Parameters:

- `key`: The header name.

Returns:

- `value`: The value of the header (string, or nil if not found).
- `error`: Error message (string, or nil on success).

##### `request:content_type()`

Returns the Content-Type of the request.

Returns:

- `content_type`: The Content-Type header value (string, or nil if not set).
- `error`: nil

##### `request:content_length()`

Returns the Content-Length of the request.

Returns:

- `content_length`: The Content-Length header value (number).
- `error`: nil

##### `request:host()`

Returns the Host header of the request.

Returns:

- `host`: The Host header value (string).
- `error`: nil

##### `request:remote_addr()`

Returns the remote address of the client.

Returns:

- `remote_addr`: The remote address (string).
- `error`: nil

##### `request:body()`

Returns the raw request body.

Returns:

- `body`: The request body (string, or nil if no body or error).
- `error`: Error message (string, or nil on success).

##### `request:body_json()`

Parses the request body as JSON and returns the decoded value.

Returns:

- `value`: The decoded JSON value (Lua table, or nil on error).
- `error`: Error message (string, or nil on success).

##### `request:has_body()`

Checks if the request has a body.

Returns:

- `has_body`: True if the request has a body, false otherwise.
- `error`: nil

##### `request:accepts(content_type: string)`

Checks if the request accepts the specified content type.

Parameters:

- `content_type`: The content type to check.

Returns:

- `accepts`: True if the content type is accepted, false otherwise.
- `error`: Error message (string, or nil on success).

##### `request:is_content_type(content_type: string)`

Checks if the request's Content-Type matches the specified content type.

Parameters:

- `content_type`: The content type to check.

Returns:

- `is_content_type`: True if the Content-Type matches, false otherwise.
- `error`: Error message (string, or nil on success).

##### `request:stream_body(options: table)`

Returns an iterator function for streaming the request body.

Parameters:

- `options`: (Optional) A table with the following optional fields:
  - `buffer_size`: The buffer size to use for reading (number, defaults to 32KB).

Returns:

- `iterator`: An iterator function that returns the next chunk of the body (string) on each call, and nil when the body
  is exhausted.
- `error`: Error message (string, or nil on success).

##### `request:parse_multipart(max_memory: number)`

Parses multipart form data from the request and returns file attachments.

Parameters:
- `max_memory`: (Optional) Maximum memory in bytes to use for parsing the multipart form. Default is 10MB.

Returns:
- `form`: A table containing the form data with these fields:
  - `files`: A table mapping field names to arrays of file objects
- `error`: Error message (string, or nil on success)

##### MultipartFile Object Methods

When using `request:parse_multipart()`, each file is represented as a MultipartFile object with the following methods:

###### `file:name()`

Returns the original filename of the file as sent by the client.

Returns:
- `name`: The filename (string)
- `error`: nil

###### `file:size()`

Returns the size of the file in bytes.

Returns:
- `size`: The file size in bytes (number)
- `error`: nil

###### `file:stream()`

Creates a Stream object for reading the file contents incrementally.

Returns:
- `stream`: A Stream object for reading the file
- `error`: Error message (string, or nil on success)

### Response Object

The `http.response()` function creates a new `Response` object representing the current HTTP response.

#### `http.response()`

Creates a new `Response` object.

Returns:

- `response`: A `Response` object.

#### Response Methods

##### `response:set_status(code: number)`

Sets the HTTP status code.

Parameters:

- `code`: The HTTP status code.

Returns:

- `error`: Error message (string, or nil on success).

##### `response:set_header(key: string, value: string)`

Sets a response header.

Parameters:

- `key`: The header name.
- `value`: The header value.

Returns:

- `error`: Error message (string, or nil on success).

##### `response:write(data: string)`

Writes data to the response body.

Parameters:

- `data`: The data to write.

Returns:

- `error`: Error message (string, or nil on success).

##### `response:flush()`

Flushes the response writer.

Returns:

- `error`: Error message (string, or nil on success).

##### `response:write_json(value: any)`

Encodes the given Lua value as JSON and writes it to the response body. Sets the `Content-Type` to `application/json` if
not already set.

Parameters:

- `value`: The Lua value to encode (typically a table).

Returns:

- `error`: Error message (string, or nil on success).

##### `response:set_content_type(content_type: string)`

Sets the Content-Type of the response.

Parameters:

- `content_type`: The Content-Type to set.

Returns:

- `error`: Error message (string, or nil on success).

##### `response:write_event(event: table)`

Writes a Server-Sent Event to the response.

Parameters:

- `event`: A table with the following fields:
  - `name`: The event name (string).
  - `data`: The event data (any).

Returns:

- `error`: Error message (string, or nil on success).

##### `response:set_transfer(transfer_type: string)`

Sets the transfer encoding for the response.

Parameters:

- `transfer_type`: The transfer type (`http.TRANSFER.CHUNKED` or `http.TRANSFER.SSE`).

Returns:

- `error`: Error message (string, or nil on success).

## Error Handling

- Most methods return an error message as their last return value if an error occurs.
- Errors typically occur due to invalid input, invalid state (e.g., setting headers after they have been sent), or I/O
  errors.
- `request:stream_body` iterator function returns chunks of data until the body is exhausted, then it returns `nil`. Any
  error during reading will be returned by the `read()` method of the underlying `Stream` object.

## Behavior

- The module provides a way to interact with the underlying HTTP request and response objects.
- Request methods provide read-only access to request data.
- Response methods allow writing to the response.
- `response:set_status`, `response:set_header`, and `response:set_content_type` must be called before any data is
  written to the response body.
- `response:write_json` automatically sets the `Content-Type` to `application/json` if it hasn't already been set.
- `response:set_transfer` can be used to enable chunked transfer encoding or server-sent events.
- `response:write_event` is used for sending server-sent events. It automatically sets the necessary headers for SSE if
  `set_transfer` hasn't been called with `http.TRANSFER.SSE`.
- The `request:stream_body` method allows streaming the request body in chunks.
- The `options` parameter in `http.request()` and `request:stream_body()` allows configuring request handling behavior.

## Best Practices

- Always check for errors returned by methods.
- Set response headers and status code before writing any body data.
- Use `request:stream_body` for efficiently handling large request bodies.
- Use `response:set_transfer` and `response:write_event` for implementing server-sent events.
- Be mindful of potential concurrency issues if accessing `Request` or `Response` objects from multiple threads.

## Example Usage

```lua
local http = require("http")

-- Get request and response objects
local req = http.request()
local res = http.response()

-- Handle GET request
if req:method() == http.METHOD.GET then
  local name = req:query("name")
  if name then
    res:set_status(http.STATUS.OK)
    res:write("Hello, " .. name .. "!")
  else
    res:set_status(http.STATUS.BAD_REQUEST)
    res:write("Missing 'name' parameter")
  end
end

-- Handle POST request with JSON body
if req:method() == http.METHOD.POST and req:is_content_type(http.CONTENT.JSON) then
  local data, err = req:body_json()
  if err then
    res:set_status(http.STATUS.BAD_REQUEST)
    res:write_json({ error = http.ERROR.PARSE_FAILED, message = err })
  else
    res:set_status(http.STATUS.CREATED)
    res:write_json({ message = "Received data", data = data })
  end
end

-- Handle large request body with streaming
if req:method() == http.METHOD.POST and req:content_type() == http.CONTENT.STREAM then
    local iterator, err = req:stream_body({ buffer_size = 4096 })
    if err then
      res:set_status(http.STATUS.INTERNAL_ERROR)
      res:write(err)
    else
      res:set_status(http.STATUS.OK)
      res:set_transfer(http.TRANSFER.CHUNKED)

      for chunk in iterator do
        if chunk == nil then break end
        -- Process each chunk (e.g., calculate a checksum, store, etc.)
        res:write("Received chunk: " .. chunk .. "\n")
      end
    end
end

-- Handle server-sent events
if req:method() == http.METHOD.GET and req:path() == "/events" then
  res:set_transfer(http.TRANSFER.SSE)

  res:write_event({ name = "start", data = { message = "Starting event stream" } })

  for i = 1, 5 do
    res:write_event({ name = "progress", data = { percent = i * 20 } })
    res:flush() -- Important to send the event immediately
  end

  res:write_event({ name = "end", data = { message = "Event stream finished" } })
end
```
### Example: Handling Multipart Form Uploads

```lua
local http = require("http")

-- Get request object
local req = http.request()
local res = http.response()

-- Check if the request is multipart/form-data
if req:is_content_type(http.CONTENT.MULTIPART) then
  -- Parse multipart form with 20MB limit
  local form, err = req:parse_multipart(20 * 1024 * 1024)
  if err then
    res:set_status(http.STATUS.BAD_REQUEST)
    res:write("Failed to parse form: " .. err)
    return
  end
  
  -- Process uploaded files
  if form.files.avatar and #form.files.avatar > 0 then
    local avatar = form.files.avatar[1]
    local filename = avatar:name()
    local size = avatar:size()
    local stream, err = avatar:stream()
    if err then
      res:set_status(http.STATUS.INTERNAL_ERROR)
      res:write("Failed to create stream: " .. err)
      return
    end
    
    -- Use the filesystem module to write the stream to a file
    local fsObj = fs.get("local")  -- Get the local filesystem
    local targetPath = "/uploads/" .. image:name()
    
    -- Write the stream directly to a file
    local success, err = fsObj:writefile(targetPath, stream)
    if not success then
      res:set_status(http.STATUS.INTERNAL_ERROR)
      res:write("Failed to save file: " .. err)
      return
    end
    
    res:set_status(http.STATUS.OK)
    res:write_json({
      message = "Image saved to filesystem",
      path = targetPath,
      size = image:size()
    })
  end
end
```

##### `request:param(name: string)`

Returns the value of a named parameter from the route path.

Parameters:

- `name`: The parameter name as defined in the route path (without the colon or curly braces).

Returns:

- `value`: The value of the route parameter (string, or nil if not found).
- `error`: Error message (string, or nil on success).

Examples:

For a route defined as `/users/:id` or `/users/{id}`:
```lua
local id, err = request:param("id")
if err then
  -- Handle error
elseif not id then
  -- Parameter not found
else
  -- Use the id parameter
end
```

> Use params() to get all params table.

Notes:
- Route parameters are extracted from the URL path based on pattern matching.
- Parameter names in route definitions can use either `:param` or `{param}` syntax.
- If the parameter doesn't exist in the current route, nil is returned (not an error).
- Errors are only returned if there's no route information in the request context.