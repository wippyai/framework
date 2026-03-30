local crypto = require("crypto")
local hash = require("hash")
local time = require("time")

local sigv4 = {}

sigv4._crypto = crypto
sigv4._hash = hash
sigv4._time = time

local function hex_to_bin(hex_str)
    local result = hex_str:gsub('..', function(cc)
        return string.char(tonumber(cc, 16) :: integer)
    end)
    return result
end

-- URI-encode per AWS SigV4 spec (unreserved: A-Z a-z 0-9 - _ . ~)
function sigv4.uri_encode(str)
    if not str then return "" end
    local result = str:gsub('[^A-Za-z0-9%-_%.~]', function(c)
        return string.format('%%%02X', string.byte(c))
    end)
    return result
end

-- Encode URI path: each segment is URI-encoded, slashes preserved
function sigv4.encode_uri_path(path)
    if not path or path == "" then return "/" end
    local segments = {}
    for segment in path:gmatch("[^/]+") do
        local encoded = sigv4.uri_encode(segment)
        table.insert(segments, encoded)
    end
    if #segments == 0 then return "/" end
    local encoded = "/" .. table.concat(segments, "/")
    if path:sub(-1) == "/" then
        encoded = encoded .. "/"
    end
    return encoded
end

-- Build canonical query string from sorted parameters
function sigv4.canonical_query_string(query_params)
    if not query_params or next(query_params) == nil then
        return ""
    end

    local sorted_keys = {}
    for k, _ in pairs(query_params) do
        table.insert(sorted_keys, k)
    end
    table.sort(sorted_keys)

    local parts = {}
    for _, k in ipairs(sorted_keys) do
        table.insert(parts, sigv4.uri_encode(k) .. "=" .. sigv4.uri_encode(tostring(query_params[k])))
    end

    return table.concat(parts, "&")
end

-- Derive the SigV4 signing key via HMAC chain
function sigv4.get_signing_key(secret_key, date_stamp, region, service)
    local k_date, err = sigv4._crypto.hmac.sha256("AWS4" .. secret_key, date_stamp)
    if err then return nil, "kDate: " .. tostring(err) end

    local k_region
    k_region, err = sigv4._crypto.hmac.sha256(hex_to_bin(k_date), region)
    if err then return nil, "kRegion: " .. tostring(err) end

    local k_service
    k_service, err = sigv4._crypto.hmac.sha256(hex_to_bin(k_region), service)
    if err then return nil, "kService: " .. tostring(err) end

    local k_signing
    k_signing, err = sigv4._crypto.hmac.sha256(hex_to_bin(k_service), "aws4_request")
    if err then return nil, "kSigning: " .. tostring(err) end

    return hex_to_bin(k_signing)
end

function sigv4.format_amz_date(t)
    t = t:utc()
    return string.format("%04d%02d%02dT%02d%02d%02dZ",
        t:year(), t:month(), t:day(), t:hour(), t:minute(), t:second())
end

function sigv4.format_date_stamp(t)
    t = t:utc()
    return string.format("%04d%02d%02d", t:year(), t:month(), t:day())
end

-- Sign a request using AWS SigV4.
-- Returns the headers table with Authorization, x-amz-date, and optionally x-amz-security-token.
function sigv4.sign_request(params)
    local method = params.method or "POST"
    local host = params.host
    local uri = params.uri or "/"
    local query_params = params.query_params
    local headers = params.headers or {}
    local body = params.body or ""
    local region = params.region
    local service = params.service
    local access_key = params.access_key
    local secret_key = params.secret_key
    local session_token = params.session_token
    local timestamp = params.timestamp

    if not host then return nil, "Host is required" end
    if not region then return nil, "Region is required" end
    if not service then return nil, "Service is required" end
    if not access_key then return nil, "Access key is required" end
    if not secret_key then return nil, "Secret key is required" end

    local t = timestamp or sigv4._time.now()
    local amz_date = sigv4.format_amz_date(t)
    local date_stamp = sigv4.format_date_stamp(t)

    headers["host"] = tostring(host)
    headers["x-amz-date"] = amz_date
    if session_token then
        headers["x-amz-security-token"] = tostring(session_token)
    end

    local canonical_uri = sigv4.encode_uri_path(uri)
    local canonical_querystring = sigv4.canonical_query_string(query_params)

    -- Build sorted canonical headers
    local lower_headers = {}
    for k, v in pairs(headers) do
        local lower_k = string.lower(k)
        lower_headers[lower_k] = tostring(v):match('^%s*(.-)%s*$')
    end

    local sorted_header_keys = {}
    for k, _ in pairs(lower_headers) do
        table.insert(sorted_header_keys, k)
    end
    table.sort(sorted_header_keys)

    local canonical_headers_str = ""
    for _, k in ipairs(sorted_header_keys) do
        canonical_headers_str = canonical_headers_str .. k .. ":" .. lower_headers[k] .. "\n"
    end

    local signed_headers = table.concat(sorted_header_keys, ";")

    local payload_hash, hash_err = sigv4._hash.sha256(body)
    if hash_err then return nil, "Payload hash failed: " .. tostring(hash_err) end

    local canonical_request = method .. "\n" ..
        canonical_uri .. "\n" ..
        canonical_querystring .. "\n" ..
        canonical_headers_str .. "\n" ..
        signed_headers .. "\n" ..
        payload_hash

    local credential_scope = date_stamp .. "/" .. region .. "/" .. service .. "/aws4_request"

    local cr_hash, cr_err = sigv4._hash.sha256(canonical_request)
    if cr_err then return nil, "Canonical request hash failed: " .. tostring(cr_err) end

    local string_to_sign = "AWS4-HMAC-SHA256\n" ..
        amz_date .. "\n" ..
        credential_scope .. "\n" ..
        cr_hash

    local signing_key, sk_err = sigv4.get_signing_key(secret_key, date_stamp, region, service)
    if sk_err then return nil, sk_err end

    local signature, sig_err = sigv4._crypto.hmac.sha256(signing_key :: string, string_to_sign)
    if sig_err then return nil, "Signature computation failed: " .. tostring(sig_err) end

    headers["Authorization"] = "AWS4-HMAC-SHA256 Credential=" .. access_key .. "/" .. credential_scope ..
        ", SignedHeaders=" .. signed_headers ..
        ", Signature=" .. signature

    return headers
end

return sigv4
