local json = require("json")
local http_client = require("http_client")

local client = {}

local function extract_response_metadata(response_body)
    if not response_body then
        return {}
    end

    local metadata = {}

    metadata.model_version = response_body.modelVersion
    metadata.response_id = response_body.responseId
    metadata.create_time = response_body.createTime

    return metadata
end

local function parse_error_response(http_response)
    local error_info = {
        status_code = http_response.status_code,
        message = "Google API error: " .. (http_response.status_code or "unknown status")
    }

    if http_response.body then
        local parsed, decode_err = json.decode(http_response.body)
        if not decode_err and parsed and parsed.error then
            error_info.message = parsed.error.message or error_info.message
            error_info.code = parsed.error.code
            error_info.param = parsed.error.param
            error_info.type = parsed.error.type
        end
    end

    error_info.metadata = extract_response_metadata(http_response)

    return error_info
end

function client.request(method, url, http_options)
    http_options.headers["Accept"] = "application/json"

    local response = nil
    local err = nil
    if method == "GET" then
        response, err = http_client.get(url, http_options)
    else
        http_options.headers["Content-Type"] = "application/json"
        response, err = http_client.post(url, http_options)
    end

    if not response then
        return nil, {
            status_code = 0,
            message = "Connection failed: " .. tostring(err)
        }
    end

    if response.status_code < 200 or response.status_code >= 300 then
        local parsed_error = parse_error_response(response)
        return nil, parsed_error
    end

    local parsed, parse_err = json.decode(response.body)
    if parse_err then
        local parse_error = {
            status_code = response.status_code,
            message = "Failed to parse Google response: " .. parse_err,
            metadata = extract_response_metadata(response)
        }
        return nil, parse_error
    end

    parsed.metadata = extract_response_metadata(response)

    return parsed
end

return client
