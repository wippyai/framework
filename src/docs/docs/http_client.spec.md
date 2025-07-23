# Lua HTTP Module Specification

## Overview

The `http_client` module provides functions for performing HTTP requests in Lua. It supports various HTTP methods,
request options (headers, cookies, body, query parameters, timeout, authentication, file uploads), and batch requests.
It also handles response data, including headers, cookies, status code, URL, and body. Additionally, it supports
streaming responses for handling large data efficiently and Unix socket connections for local services.

## Module Interface

### Module Loading

```lua
local http_client = require("http_client")
```

### Global Functions

#### `http_client.get(url: string, options: table)`

Sends an HTTP GET request.

Parameters:

- `url`: The URL to request.
- `options`: (Optional) A table of request options.

Returns:

- `response`: An `http.response` object (or nil on error).
- `error`: An error message string (or nil on success).

#### `http_client.post(url: string, options: table)`

Sends an HTTP POST request.

Parameters:

- `url`: The URL to request.
- `options`: (Optional) A table of request options.

Returns:

- `response`: An `http.response` object (or nil on error).
- `error`: An error message string (or nil on success).

#### `http_client.put(url: string, options: table)`

Sends an HTTP PUT request.

Parameters:

- `url`: The URL to request.
- `options`: (Optional) A table of request options.

Returns:

- `response`: An `http.response` object (or nil on error).
- `error`: An error message string (or nil on success).

#### `http_client.delete(url: string, options: table)`

Sends an HTTP DELETE request.

Parameters:

- `url`: The URL to request.
- `options`: (Optional) A table of request options.

Returns:

- `response`: An `http.response` object (or nil on error).
- `error`: An error message string (or nil on success).

#### `http_client.head(url: string, options: table)`

Sends an HTTP HEAD request.

Parameters:

- `url`: The URL to request.
- `options`: (Optional) A table of request options.

Returns:

- `response`: An `http.response` object (or nil on error).
- `error`: An error message string (or nil on success).

#### `http_client.patch(url: string, options: table)`

Sends an HTTP PATCH request.

Parameters:

- `url`: The URL to request.
- `options`: (Optional) A table of request options.

Returns:

- `response`: An `http.response` object (or nil on error).
- `error`: An error message string (or nil on success).

#### `http_client.request(method: string, url: string, options: table)`

Sends an HTTP request with the specified method.

Parameters:

- `method`: The HTTP method (e.g., "GET", "POST").
- `url`: The URL to request.
- `options`: (Optional) A table of request options.

Returns:

- `response`: An `http.response` object (or nil on error).
- `error`: An error message string (or nil on success).

#### `http_client.request_batch(requests: table)`

Sends multiple HTTP requests concurrently.

Parameters:

- `requests`: A table of request tables. Each request table contains:
  1. `method`: The HTTP method.
  2. `url`: The URL.
  3. `options`: (Optional) A table of request options.

Returns:

- `responses`: A table of `http.response` objects, indexed in the same order as the requests.
- `errors`: A table of error messages, indexed in the same order as the requests (or nil if no errors occurred).

#### `http_client.encode_uri(str: string)`

Encodes a string for use in a URL.

Parameters:

- `str`: The string to encode.

Returns:

- `encoded`: The encoded string.

#### `http_client.decode_uri(str: string)`

Decodes a URL-encoded string.

Parameters:

- `str`: The string to decode.

Returns:

- `decoded`: The decoded string (or nil on error).
- `error`: An error message string (or nil on success).

## Request Options

The `options` table can contain the following fields:

- `headers`: A table of HTTP headers (key-value pairs).
- `cookies`: A table of cookies (key-value pairs).
- `body`: The request body (string).
- `form`: Form data (string, will set `Content-Type` to `application/x-www-form-urlencoded`).
- `query`: The query string to append to the URL.
- `timeout`: The request timeout (number in seconds or string parsable by `time.ParseDuration`).
- `auth`: A table with `user` and `pass` fields for basic authentication.
- `stream`: A table for stream configuration for streaming requests.
- `files`: A table of file specifications for file uploads (will set `Content-Type` to `multipart/form-data`).
- `unix_socket`: A string path to a Unix socket for local service communication (e.g., "/var/run/docker.sock").

### Unix Socket Support

When the `unix_socket` option is specified:

- The request will be sent over the Unix socket instead of a TCP connection
- The URL host and port are ignored; only the path is used
- All other request options (headers, body, timeout, etc.) work normally
- Requires `http_client.unix_socket` security permission for the socket path
- Commonly used for Docker API, systemd services, and other local daemons

### File Upload Options

The `files` option should be a table (array) of file specification tables, each containing:

- `name`: The form field name for the file (required).
- `filename`: The filename to use in the request (required).
- `content_type`: The content type of the file (optional, defaults to "application/octet-stream").
- `content`: The file content as a string (use either `content` OR `reader`).
- `reader`: An object implementing the `io.Reader` interface for the file content (use either `content` OR `reader`).

When `files` is present:

- The request will automatically use `multipart/form-data` encoding
- If `form` is also present, those form fields will be included in the multipart request
- The `Content-Type` header is set automatically and should not be manually specified
- If both `body` and `files` are specified, `body` will be ignored

## HTTP Response Object

The `http_client.Response` object has the following fields:

- `headers`: A table of response headers (key-value pairs).
- `cookies`: A table of response cookies (key-value pairs).
- `status_code`: The HTTP status code (number).
- `url`: The final URL of the response (after redirects).
- `body`: The response body (string, nil if streaming is used).
- `body_size`: The size of the response body in bytes (-1 if streaming is used).
- `stream`: A `Stream` object for streamed responses (or nil if not a streaming response).

## Streamed Responses

- When the `stream` option is used, the response body will be `nil`, and `body_size` will be `-1`.
- The `stream` field will contain a `Stream` object that can be used to read the response body in chunks.
- The `read()` method of the `Stream` object will return chunks of data.
- The `close()` method of the `Stream` object should be called when finished to release resources.

## Security Permissions

The HTTP client module requires specific security permissions to function:

### `http_client.request`

Required for all HTTP/HTTPS requests. The security system can:
- Whitelist specific URLs or URL patterns
- Block requests to internal networks
- Restrict access to specific domains
- Apply rate limiting per endpoint

### `http_client.unix_socket`

Required for Unix socket connections. The security system can:
- Whitelist specific socket paths (e.g., `/var/run/docker.sock`)
- Deny access to sensitive system sockets
- Apply path-based restrictions (e.g., only `/tmp/` or `/var/run/` paths)
- Prevent access to privileged socket files

Example security configuration might allow:
- `http_client.request` for `https://api.trusted-service.com/*`
- `http_client.unix_socket` for `/var/run/docker.sock`
- `http_client.unix_socket` for `/tmp/app-*.sock`

## Error Handling

- Functions return an error message as the second return value if an error occurs.
- The `request_batch` function returns a table of error messages as the second return value.
- For streamed responses, errors during reading will be returned by the `read()` method of the `Stream` object.
- For file uploads, invalid file specifications are skipped rather than causing the entire request to fail.
- Security permission violations result in immediate errors before network requests are made.

## Behavior

- The module handles encoding of request bodies, headers, and cookies.
- It parses response headers and cookies.
- It supports concurrent requests with `request_batch`.
- It allows setting a timeout for requests.
- It supports basic authentication.
- It supports file uploads using `multipart/form-data` encoding.
- For `request_batch`, it validates each request entry and builds requests with provided options.
- `request_batch` processes requests concurrently and returns results in order.
- Streaming file uploads are supported by providing an `io.Reader` implementation to the `reader` field.
- Unix socket connections bypass DNS resolution and connect directly to local services.

## Thread Safety

- The `http_client` module is not inherently thread-safe for concurrent access to the same `http_client.Response` object
  from multiple threads.
- Streamed responses using the same `Stream` object from multiple threads will lead to undefined behavior.

## Best Practices

- Check for errors after each function call.
- Use `request_batch` for efficient concurrent requests.
- Set appropriate timeouts for requests.
- Use the `stream` option for handling large responses efficiently.
- Close the stream when finished to release resources.
- Use `encode_uri` and `decode_uri` for proper URL handling.
- For file uploads with potentially large files, use the `reader` approach rather than loading the entire file into
  memory.
- When uploading multiple files, ensure each file specification has a unique `name` field.
- For Unix socket access, ensure proper security permissions are configured.
- Validate Unix socket paths and restrict access to known safe sockets.
- Use Unix sockets for local services to avoid network overhead and improve security.

## Example Usage

### Basic Requests

```lua
local http_client = require("http_client")

-- GET request
local response, err = http_client.get("https://api.example.com/data", {
  headers = {
    ["User-Agent"] = "Lua HTTP Client"
  },
  timeout = 5
})
if err then
  print("GET request failed:", err)
else
  print("Status:", response.status_code)
  print("Body:", response.body)
end

-- POST request with form data
local response, err = http_client.post("https://api.example.com/submit", {
  form = "name=John+Doe&age=30"
})
if err then
  print("POST request failed:", err)
else
  print("Response:", response.body)
end

-- Batch requests
local requests = {
  { "GET", "https://api.example.com/users" },
  { "GET", "https://api.example.com/posts", { timeout = 2 } }
}
local responses, errors = http_client.request_batch(requests)
for i, res in ipairs(responses) do
  if res then
    print("Request", i, "Status:", res.status_code)
  else
    print("Request", i, "Error:", errors[i])
  end
end

-- Streaming response
local response, err = http_client.get("https://api.example.com/largefile", { stream = true })
if err then
  print("Streaming request failed:", err)
else
  local stream = response.stream
  local chunk, err = stream:read(4096)
  while chunk and not err do
    -- Process each chunk
    print("Chunk:", chunk)
    chunk, err = stream:read(4096)
  end
  stream:close()
end
```

### Unix Socket Usage

```lua
local http_client = require("http_client")

-- Docker API via Unix socket
local function docker_api(endpoint, method, body)
  method = method or "GET"
  local opts = {
    unix_socket = "/var/run/docker.sock",
    headers = { ["Content-Type"] = "application/json" },
    timeout = 30
  }
  
  if body then
    opts.body = body
  end
  
  return http_client.request(method, "http://docker" .. endpoint, opts)
end

-- List Docker containers
local containers, err = docker_api("/containers/json")
if err then
  print("Failed to list containers:", err)
else
  print("Containers:", containers.body)
end

-- Get Docker system info
local info, err = docker_api("/info")
if err then
  print("Failed to get Docker info:", err)
else
  print("Docker info:", info.body)
end

-- Create a new container
local create_req = '{"Image":"nginx","Cmd":["nginx","-g","daemon off;"]}'
local created, err = docker_api("/containers/create", "POST", create_req)
if err then
  print("Failed to create container:", err)
else
  print("Container created:", created.body)
end

-- Batch requests over Unix socket
local requests = {
  { "GET", "http://docker/containers/json", { unix_socket = "/var/run/docker.sock" } },
  { "GET", "http://docker/images/json", { unix_socket = "/var/run/docker.sock" } },
  { "GET", "http://docker/info", { unix_socket = "/var/run/docker.sock" } }
}

local responses, errors = http_client.request_batch(requests)
for i, res in ipairs(responses) do
  if res then
    print("Docker request", i, "Status:", res.status_code)
  else
    print("Docker request", i, "Error:", errors[i])
  end
end

-- Streaming container logs over Unix socket
local log_response, err = http_client.get("http://docker/containers/myapp/logs?follow=true&stdout=true", {
  unix_socket = "/var/run/docker.sock",
  stream = true
})

if not err then
  local stream = log_response.stream
  local chunk, err = stream:read(1024)
  while chunk and not err do
    io.write(chunk)  -- Stream container logs to stdout
    chunk, err = stream:read(1024)
  end
  stream:close()
end
```

### File Upload Examples

```lua
local http_client = require("http_client")
local fs = require("fs")

-- Upload a file using string content
local response, err = http_client.post("https://api.example.com/upload", {
  files = {
    {
      name = "document",         -- Form field name
      filename = "report.txt",   -- Filename to use in the request
      content_type = "text/plain", -- Content type (optional)
      content = "This is the content of my file" -- Direct string content
    }
  }
})

-- Upload a file using a file reader
local file, err = fs.open("/path/to/document.pdf", "r")
if err then
  print("Failed to open file:", err)
  return
end

local response, err = http_client.post("https://api.example.com/upload", {
  files = {
    {
      name = "document",
      filename = "report.pdf",
      content_type = "application/pdf",
      reader = file -- Using file as reader
    }
  }
})

-- Close the file when done
file:close()

-- Upload files to Docker container via Unix socket
local tar_file, err = fs.open("/tmp/app.tar", "r")
if not err then
  local upload_response, err = http_client.put("http://docker/containers/myapp/archive?path=/app", {
    unix_socket = "/var/run/docker.sock",
    headers = { ["Content-Type"] = "application/x-tar" },
    files = {
      {
        name = "archive",
        filename = "app.tar",
        content_type = "application/x-tar",
        reader = tar_file
      }
    }
  })
  
  tar_file:close()
  
  if err then
    print("Failed to upload to container:", err)
  else
    print("Upload successful:", upload_response.status_code)
  end
end

-- Upload multiple files with form data
local file1, err1 = fs.open("/path/to/image1.jpg", "r")
local file2, err2 = fs.open("/path/to/image2.jpg", "r")

local response, err = http_client.post("https://api.example.com/gallery", {
  -- Form fields
  form = "title=My%20Vacation&description=Photos%20from%20my%20recent%20trip",
  
  -- Files to upload
  files = {
    {
      name = "image1",
      filename = "beach.jpg", 
      content_type = "image/jpeg",
      reader = file1
    },
    {
      name = "image2",
      filename = "mountain.jpg",
      content_type = "image/jpeg",
      reader = file2
    }
  }
})

-- Close files when done
file1:close()
file2:close()
```