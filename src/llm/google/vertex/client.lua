local json = require("json")
local http_client = require("http_client")
local env = require("env")
local output = require("output")
local store = require("store")
local ctx = require("ctx")

-- Vertex Client Library
local vertex = {}

-- Constants
vertex.DEFAULT_API_ENDPOINT = "https://%saiplatform.googleapis.com/v1/projects/%s/locations/%s/publishers/google/models"
vertex.DEFAULT_GENERATE_CONTENT_ENDPOINT = "generateContent"

-- Map Vertex AI finish reasons to standardized finish reasons
vertex.FINISH_REASON_MAP = {
    ["STOP"] = output.FINISH_REASON.STOP,
    ["MAX_TOKENS"] = output.FINISH_REASON.LENGTH,
    ["SAFETY"] = output.FINISH_REASON.CONTENT_FILTER,
    ["RECITATION"] = output.FINISH_REASON.CONTENT_FILTER,
    ["LANGUAGE"] = output.FINISH_REASON.CONTENT_FILTER,
    ["BLOCKLIST"] = output.FINISH_REASON.CONTENT_FILTER,
    ["PROHIBITED_CONTENT"] = output.FINISH_REASON.CONTENT_FILTER,
    ["SPII"] = output.FINISH_REASON.CONTENT_FILTER,
    ["IMAGE_SAFETY"] = output.FINISH_REASON.CONTENT_FILTER,
    ["MALFORMED_FUNCTION_CALL"] = output.FINISH_REASON.ERROR,
    ["OTHER"] = output.FINISH_REASON.ERROR
}

-- Error type mapping function for Vertex errors
-- Maps specific error messages to standardized error types
function vertex.map_error(err)
    if not err then
        return {
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "Unknown error (nil error object)"
        }
    end

    -- Default to server error unless we determine otherwise
    local error_type = output.ERROR_TYPE.SERVER_ERROR

    -- Special cases for common error types based on status code
    if err.status_code == 400 then
            error_type = output.ERROR_TYPE.INVALID_REQUEST
    elseif err.status_code == 401 or err.status_code == 403 then
        error_type = output.ERROR_TYPE.AUTHENTICATION
    elseif err.status_code == 404 then
        error_type = output.ERROR_TYPE.MODEL_ERROR
    elseif err.status_code == 429 then
        error_type = output.ERROR_TYPE.RATE_LIMIT
    elseif err.status_code >= 500 then
        error_type = output.ERROR_TYPE.SERVER_ERROR
    end

    -- Special cases based on error message content
    if err.message then
        -- Check for context length errors
        if err.message:match("context length") or
            err.message:match("string too long") or
            err.message:match("maximum.+tokens") then
            error_type = output.ERROR_TYPE.CONTEXT_LENGTH
        end

        -- Check for content filter errors
        if err.message:match("content policy") or
            err.message:match("content filter") then
            error_type = output.ERROR_TYPE.CONTENT_FILTER
        end
    end

    -- Return already in the format expected by the text generation handler
    return {
        error = error_type,
        error_message = err.message or "Unknown Vertex AI error"
    }
end

-- Extract metadata from Vertex HTTP response
local function extract_response_metadata(response_body)
    if not response_body then
        return {}
    end

    local metadata = {}

    -- Extract main metadata fields
    metadata.model_version = response_body.modelVersion
    metadata.response_id = response_body.responseId
    metadata.create_time = response_body.createTime

    return metadata
end

-- Parse error from Vertex response
local function parse_error(http_response)
    -- Always include status code to help with error type mapping
    local error_info = {
        status_code = http_response.status_code,
        message = "Vertex API error: " .. (http_response.status_code or "unknown status")
    }

    -- Try to parse error body as JSON
    if http_response.body then
        local parsed, decode_err = json.decode(http_response.body)
        if not decode_err and parsed and parsed.error then
            error_info.message = parsed.error.message or error_info.message
            error_info.code = parsed.error.code
            error_info.param = parsed.error.param
            error_info.type = parsed.error.type
        end
    end

    -- Add metadata from headers
    error_info.metadata = extract_response_metadata(http_response)

    return error_info
end

-- Make a request to the Vertex API
function vertex.request(endpoint_path, model, payload, options)
    options = options or {}

    local storeObj, err = store.get("app:cache")
    local token, err = storeObj:get("vertex_oauth_token")
    if not token then
        return nil, {
            status_code = 401,
            message = "Vertex API key is required"
        }
    end

    -- Prepare headers
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. token.access_token
    }

    -- the `provider_options` field from the Model card
    local provider_options = ctx.get("provider_options") or {}

    local location = provider_options.location or env.get("VERTEX_AI_LOCATION")
    local project = provider_options.project or env.get("VERTEX_AI_PROJECT")

    -- Prepare endpoint URL
    local prefix_location = location == "global" and "" or location .. "-"
    local base_url = provider_options.base_url or vertex.DEFAULT_API_ENDPOINT
    local full_url = string.format(base_url, prefix_location, project, location) .. "/" .. model .. ":" .. endpoint_path

    -- Make the request
    local http_options = {
        headers = headers,
        timeout = options.timeout or 120
    }

    -- Make the request
    http_options.body = json.encode(payload)

    -- Send the request
    local response = http_client.post(full_url, http_options)

    -- Check for errors
    if response.status_code < 200 or response.status_code >= 300 then
        return nil, parse_error(response)
    end

    -- Parse successful response
    local parsed, parse_err = json.decode(response.body)
    if parse_err then
        return nil, {
            status_code = response.status_code,
            message = "Failed to parse Vertex AI response: " .. parse_err,
            metadata = extract_response_metadata(response)
        }
    end

    -- Add metadata to the response
    parsed.metadata = extract_response_metadata(parsed)

    return parsed
end

return vertex
