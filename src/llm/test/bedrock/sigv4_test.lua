local sigv4 = require("sigv4")
local time = require("time")

local function define_tests()
    describe("SigV4 Signing", function()

        describe("URI Encoding", function()
            it("should encode special characters", function()
                test.eq(sigv4.uri_encode("hello world"), "hello%20world")
                test.eq(sigv4.uri_encode("key=value&foo=bar"), "key%3Dvalue%26foo%3Dbar")
                test.eq(sigv4.uri_encode("test/path"), "test%2Fpath")
                test.eq(sigv4.uri_encode("a+b"), "a%2Bb")
            end)

            it("should preserve unreserved characters", function()
                test.eq(sigv4.uri_encode("abc123"), "abc123")
                test.eq(sigv4.uri_encode("test-value"), "test-value")
                test.eq(sigv4.uri_encode("under_score"), "under_score")
                test.eq(sigv4.uri_encode("dot.value"), "dot.value")
                test.eq(sigv4.uri_encode("tilde~char"), "tilde~char")
            end)

            it("should handle empty and nil input", function()
                test.eq(sigv4.uri_encode(""), "")
                test.eq(sigv4.uri_encode(nil), "")
            end)
        end)

        describe("URI Path Encoding", function()
            it("should encode model IDs with colons", function()
                local path = "/model/us.anthropic.claude-haiku-4-5-20251001-v1:0/invoke"
                local encoded = sigv4.encode_uri_path(path)
                test.contains(encoded, "/model/")
                test.contains(encoded, "/invoke")
                test.contains(encoded, "%3A")
            end)

            it("should encode simple paths", function()
                test.eq(sigv4.encode_uri_path("/foo/bar"), "/foo/bar")
                test.eq(sigv4.encode_uri_path("/a/b/c"), "/a/b/c")
            end)

            it("should return root for empty or nil input", function()
                test.eq(sigv4.encode_uri_path(""), "/")
                test.eq(sigv4.encode_uri_path(nil), "/")
            end)

            it("should preserve trailing slash", function()
                test.eq(sigv4.encode_uri_path("/foo/bar/"), "/foo/bar/")
            end)
        end)

        describe("Canonical Query String", function()
            it("should sort parameters alphabetically", function()
                local qs = sigv4.canonical_query_string({
                    zebra = "1",
                    alpha = "2",
                    middle = "3"
                })
                local alpha_pos = string.find(qs, "alpha")
                local middle_pos = string.find(qs, "middle")
                local zebra_pos = string.find(qs, "zebra")
                test.is_true(alpha_pos < middle_pos)
                test.is_true(middle_pos < zebra_pos)
            end)

            it("should encode parameter names and values", function()
                local qs = sigv4.canonical_query_string({
                    ["key with space"] = "value with space"
                })
                test.contains(qs, "key%20with%20space=value%20with%20space")
            end)

            it("should return empty string for nil or empty params", function()
                test.eq(sigv4.canonical_query_string(nil), "")
                test.eq(sigv4.canonical_query_string({}), "")
            end)
        end)

        describe("Signing Key Derivation", function()
            it("should produce a 32-byte key", function()
                local key, err = sigv4.get_signing_key(
                    "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY",
                    "20230101",
                    "us-east-1",
                    "bedrock"
                )
                test.is_nil(err)
                test.not_nil(key)
                test.eq(#key, 32)
            end)

            it("should not produce an error with valid inputs", function()
                local key, err = sigv4.get_signing_key(
                    "testSecretKey",
                    "20260323",
                    "us-west-2",
                    "bedrock"
                )
                test.is_nil(err)
                test.not_nil(key)
            end)
        end)

        describe("Request Signing", function()
            it("should produce Authorization header with correct format", function()
                local t = time.parse(time.RFC3339, "2026-01-15T12:30:00Z")

                local headers, err = sigv4.sign_request({
                    method = "POST",
                    host = "bedrock-runtime.us-east-1.amazonaws.com",
                    uri = "/model/test-model/invoke",
                    headers = { ["content-type"] = "application/json" },
                    body = '{"messages":[]}',
                    region = "us-east-1",
                    service = "bedrock",
                    access_key = "AKIAIOSFODNN7EXAMPLE",
                    secret_key = "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY",
                    timestamp = t
                })

                test.is_nil(err)
                test.not_nil(headers)
                test.not_nil(headers["Authorization"])
                test.contains(headers["Authorization"], "AWS4-HMAC-SHA256")
                test.contains(headers["Authorization"], "Credential=AKIAIOSFODNN7EXAMPLE")
                test.contains(headers["Authorization"], "SignedHeaders=")
                test.contains(headers["Authorization"], "Signature=")
                test.not_nil(headers["x-amz-date"])
            end)

            it("should include session token in signed headers when provided", function()
                local t = time.parse(time.RFC3339, "2026-01-15T12:30:00Z")

                local headers, err = sigv4.sign_request({
                    method = "POST",
                    host = "bedrock-runtime.us-east-1.amazonaws.com",
                    uri = "/model/test-model/invoke",
                    headers = {},
                    body = "{}",
                    region = "us-east-1",
                    service = "bedrock",
                    access_key = "AKIAIOSFODNN7EXAMPLE",
                    secret_key = "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY",
                    session_token = "FwoGZXIvYXdzEBAaDH...",
                    timestamp = t
                })

                test.is_nil(err)
                test.not_nil(headers)
                test.eq(headers["x-amz-security-token"], "FwoGZXIvYXdzEBAaDH...")
                test.contains(headers["Authorization"], "x-amz-security-token")
            end)

            it("should return error for missing host", function()
                local headers, err = sigv4.sign_request({
                    region = "us-east-1",
                    service = "bedrock",
                    access_key = "AKID",
                    secret_key = "SECRET"
                })
                test.is_nil(headers)
                test.contains(err, "Host is required")
            end)

            it("should return error for missing region", function()
                local headers, err = sigv4.sign_request({
                    host = "example.com",
                    service = "bedrock",
                    access_key = "AKID",
                    secret_key = "SECRET"
                })
                test.is_nil(headers)
                test.contains(err, "Region is required")
            end)

            it("should return error for missing access key", function()
                local headers, err = sigv4.sign_request({
                    host = "example.com",
                    region = "us-east-1",
                    service = "bedrock",
                    secret_key = "SECRET"
                })
                test.is_nil(headers)
                test.contains(err, "Access key is required")
            end)

            it("should return error for missing secret key", function()
                local headers, err = sigv4.sign_request({
                    host = "example.com",
                    region = "us-east-1",
                    service = "bedrock",
                    access_key = "AKID"
                })
                test.is_nil(headers)
                test.contains(err, "Secret key is required")
            end)

            it("should produce consistent signatures for same inputs", function()
                local t = time.parse(time.RFC3339, "2026-01-15T12:30:00Z")
                local params = {
                    method = "POST",
                    host = "bedrock-runtime.us-east-1.amazonaws.com",
                    uri = "/model/test-model/invoke",
                    headers = { ["content-type"] = "application/json" },
                    body = '{"test":true}',
                    region = "us-east-1",
                    service = "bedrock",
                    access_key = "AKIAIOSFODNN7EXAMPLE",
                    secret_key = "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY",
                    timestamp = t
                }

                local headers1, err1 = sigv4.sign_request(params)
                test.is_nil(err1)

                -- Reset headers for second call
                params.headers = { ["content-type"] = "application/json" }
                local headers2, err2 = sigv4.sign_request(params)
                test.is_nil(err2)

                test.eq(headers1["Authorization"], headers2["Authorization"])
            end)
        end)

        describe("Date Formatting", function()
            it("should format amz_date correctly", function()
                local t = time.parse(time.RFC3339, "2026-03-23T14:30:45Z")
                local amz = sigv4.format_amz_date(t)
                test.eq(amz, "20260323T143045Z")
            end)

            it("should format date_stamp correctly", function()
                local t = time.parse(time.RFC3339, "2026-03-23T14:30:45Z")
                local ds = sigv4.format_date_stamp(t)
                test.eq(ds, "20260323")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
