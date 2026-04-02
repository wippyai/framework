local bedrock_client = require("bedrock_client")
local json = require("json")

local function define_tests()
    describe("Bedrock Client", function()

        after_each(function()
            bedrock_client._credentials = nil
            bedrock_client._sigv4 = nil
            bedrock_client._http_client = nil
            bedrock_client._ctx = nil
            bedrock_client._env = nil
        end)

        describe("Path Building", function()
            it("should build invoke path", function()
                local path = bedrock_client.invoke_path("us.anthropic.claude-haiku-4-5-20251001-v1:0")
                test.eq(path, "/model/us.anthropic.claude-haiku-4-5-20251001-v1:0/invoke")
            end)

            it("should build stream path", function()
                local path = bedrock_client.invoke_stream_path("us.anthropic.claude-haiku-4-5-20251001-v1:0")
                test.eq(path, "/model/us.anthropic.claude-haiku-4-5-20251001-v1:0/invoke-with-response-stream")
            end)
        end)

        describe("Request Signing", function()
            it("should add anthropic_version to payload", function()
                bedrock_client._ctx = {
                    all = function() return {} end
                }
                bedrock_client._env = {
                    get = function(key) return nil end
                }
                bedrock_client._credentials = {
                    resolve = function()
                        return {
                            access_key = "AKID",
                            secret_key = "SECRET",
                            session_token = "TOKEN"
                        }
                    end
                }
                bedrock_client._sigv4 = {
                    sign_request = function(params)
                        return params.headers
                    end
                }

                local captured_body = nil
                bedrock_client._http_client = {
                    post = function(url, options)
                        captured_body = options.body
                        return {
                            status_code = 200,
                            body = '{"content":[]}',
                            headers = {}
                        }
                    end
                }

                local response, err = bedrock_client.request("test-model", { messages = {} })
                test.is_nil(err)

                local decoded = json.decode(captured_body :: string)
                test.eq(decoded.anthropic_version, "bedrock-2023-05-31")
            end)

            it("should put model in URL not body", function()
                bedrock_client._ctx = {
                    all = function() return {} end
                }
                bedrock_client._env = {
                    get = function(key) return nil end
                }
                bedrock_client._credentials = {
                    resolve = function()
                        return {
                            access_key = "AKID",
                            secret_key = "SECRET"
                        }
                    end
                }
                bedrock_client._sigv4 = {
                    sign_request = function(params)
                        return params.headers
                    end
                }

                local captured_url = nil
                local captured_body = nil
                bedrock_client._http_client = {
                    post = function(url, options)
                        captured_url = url
                        captured_body = options.body
                        return {
                            status_code = 200,
                            body = '{"content":[]}',
                            headers = {}
                        }
                    end
                }

                bedrock_client.request("my-model-id", { messages = {} })

                test.contains(captured_url, "/model/my-model-id/invoke")
                local decoded = json.decode(captured_body :: string)
                test.is_nil(decoded.model)
            end)

            it("should sign request with correct parameters", function()
                bedrock_client._ctx = {
                    all = function() return {} end
                }
                bedrock_client._env = {
                    get = function(key) return nil end
                }
                bedrock_client._credentials = {
                    resolve = function()
                        return {
                            access_key = "AKID_TEST",
                            secret_key = "SECRET_TEST",
                            session_token = "SESSION_TEST"
                        }
                    end
                }

                local captured_sign_params = nil
                bedrock_client._sigv4 = {
                    sign_request = function(params)
                        captured_sign_params = params
                        return params.headers
                    end
                }

                bedrock_client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = '{"content":[]}',
                            headers = {}
                        }
                    end
                }

                bedrock_client.request("test-model", { messages = {} })

                test.not_nil(captured_sign_params)
                test.eq((captured_sign_params :: any).method, "POST")
                test.eq((captured_sign_params :: any).service, "bedrock")
                test.eq((captured_sign_params :: any).access_key, "AKID_TEST")
                test.eq((captured_sign_params :: any).secret_key, "SECRET_TEST")
                test.eq((captured_sign_params :: any).session_token, "SESSION_TEST")
                test.eq((captured_sign_params :: any).region, "us-east-1")
                test.contains((captured_sign_params :: any).uri, "/model/test-model/invoke")
            end)
        end)

        describe("Missing Credentials", function()
            it("should return error when credentials are not available", function()
                bedrock_client._ctx = {
                    all = function() return {} end
                }
                bedrock_client._env = {
                    get = function(key) return nil end
                }
                bedrock_client._credentials = {
                    resolve = function()
                        return nil, "AWS credentials not found"
                    end
                }

                local response, err = bedrock_client.request("test-model", { messages = {} })
                test.is_nil(response)
                test.not_nil(err)
                test.eq(err.status_code, 401)
            end)
        end)

        describe("Signing Failure", function()
            it("should return error when signing fails", function()
                bedrock_client._ctx = {
                    all = function() return {} end
                }
                bedrock_client._env = {
                    get = function(key) return nil end
                }
                bedrock_client._credentials = {
                    resolve = function()
                        return {
                            access_key = "AKID",
                            secret_key = "SECRET"
                        }
                    end
                }
                bedrock_client._sigv4 = {
                    sign_request = function(params)
                        return nil, "HMAC computation failed"
                    end
                }

                local response, err = bedrock_client.request("test-model", { messages = {} })
                test.is_nil(response)
                test.not_nil(err)
                test.contains(err.message, "Request signing failed")
            end)
        end)

        describe("Custom Base URL", function()
            it("should use base URL from environment", function()
                bedrock_client._ctx = {
                    all = function() return {} end
                }
                bedrock_client._env = {
                    get = function(key)
                        if key == "BEDROCK_BASE_URL" then
                            return "https://custom-bedrock.example.com"
                        end
                        return nil
                    end
                }
                bedrock_client._credentials = {
                    resolve = function()
                        return {
                            access_key = "AKID",
                            secret_key = "SECRET"
                        }
                    end
                }
                bedrock_client._sigv4 = {
                    sign_request = function(params)
                        test.eq(params.host, "custom-bedrock.example.com")
                        return params.headers
                    end
                }

                local captured_url = nil
                bedrock_client._http_client = {
                    post = function(url, options)
                        captured_url = url
                        return {
                            status_code = 200,
                            body = '{"content":[]}',
                            headers = {}
                        }
                    end
                }

                bedrock_client.request("test-model", { messages = {} })
                test.contains(captured_url, "https://custom-bedrock.example.com")
            end)
        end)

        describe("Default Region", function()
            it("should default to us-east-1 when no region configured", function()
                bedrock_client._ctx = {
                    all = function() return {} end
                }
                bedrock_client._env = {
                    get = function(key) return nil end
                }
                bedrock_client._credentials = {
                    resolve = function()
                        return {
                            access_key = "AKID",
                            secret_key = "SECRET"
                        }
                    end
                }

                local captured_region = nil
                bedrock_client._sigv4 = {
                    sign_request = function(params)
                        captured_region = params.region
                        return params.headers
                    end
                }

                bedrock_client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = '{"content":[]}',
                            headers = {}
                        }
                    end
                }

                bedrock_client.request("test-model", { messages = {} })
                test.eq(captured_region, "us-east-1")
            end)
        end)

        describe("HTTP Error Handling", function()
            it("should handle 400 error response", function()
                bedrock_client._ctx = {
                    all = function() return {} end
                }
                bedrock_client._env = {
                    get = function(key) return nil end
                }
                bedrock_client._credentials = {
                    resolve = function()
                        return {
                            access_key = "AKID",
                            secret_key = "SECRET"
                        }
                    end
                }
                bedrock_client._sigv4 = {
                    sign_request = function(params)
                        return params.headers
                    end
                }
                bedrock_client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 400,
                            body = json.encode({
                                message = "Malformed input request"
                            }),
                            headers = {}
                        }
                    end
                }

                local response, err = bedrock_client.request("test-model", { messages = {} })
                test.is_nil(response)
                test.not_nil(err)
                test.eq(err.status_code, 400)
                test.contains(err.message, "Malformed input request")
            end)

            it("should handle connection failure", function()
                bedrock_client._ctx = {
                    all = function() return {} end
                }
                bedrock_client._env = {
                    get = function(key) return nil end
                }
                bedrock_client._credentials = {
                    resolve = function()
                        return {
                            access_key = "AKID",
                            secret_key = "SECRET"
                        }
                    end
                }
                bedrock_client._sigv4 = {
                    sign_request = function(params)
                        return params.headers
                    end
                }
                bedrock_client._http_client = {
                    post = function(url, options)
                        return nil, "connection refused"
                    end
                }

                local response, err = bedrock_client.request("test-model", { messages = {} })
                test.is_nil(response)
                test.not_nil(err)
                test.eq(err.status_code, 0)
                test.contains(err.message, "Connection failed")
            end)

            it("should handle JSON parse error in response", function()
                bedrock_client._ctx = {
                    all = function() return {} end
                }
                bedrock_client._env = {
                    get = function(key) return nil end
                }
                bedrock_client._credentials = {
                    resolve = function()
                        return {
                            access_key = "AKID",
                            secret_key = "SECRET"
                        }
                    end
                }
                bedrock_client._sigv4 = {
                    sign_request = function(params)
                        return params.headers
                    end
                }
                bedrock_client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = "not valid json {{{",
                            headers = {}
                        }
                    end
                }

                local response, err = bedrock_client.request("test-model", { messages = {} })
                test.is_nil(response)
                test.not_nil(err)
                test.contains(err.message, "Failed to parse")
            end)
        end)
        describe("Response Metadata", function()
            it("should extract rate limit headers", function()
                bedrock_client._ctx = {
                    all = function() return { region = "us-east-1" } end
                }
                bedrock_client._env = {
                    get = function() return nil end
                }
                bedrock_client._credentials = {
                    resolve = function()
                        return { access_key = "AKID", secret_key = "SECRET", region = "us-east-1" }
                    end
                }
                bedrock_client._sigv4 = {
                    sign_request = function(params)
                        local headers = params.headers or {}
                        headers["Authorization"] = "AWS4-HMAC-SHA256 Credential=test"
                        headers["x-amz-date"] = "20240101T000000Z"
                        headers["host"] = params.host
                        return headers
                    end
                }
                bedrock_client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = '{"content":[{"type":"text","text":"ok"}],"stop_reason":"end_turn","usage":{"input_tokens":1,"output_tokens":1}}',
                            headers = {
                                ["x-amzn-requestid"] = "req-abc-123",
                                ["x-amzn-bedrock-input-token-count"] = "10",
                                ["x-amzn-bedrock-output-token-count"] = "5",
                                ["anthropic-ratelimit-requests-remaining"] = "99"
                            }
                        }
                    end
                }

                local response, err = bedrock_client.request("model", { messages = {} })
                test.is_nil(err)
                test.not_nil(response)
                test.not_nil(response.metadata)
                test.eq(response.metadata.request_id, "req-abc-123")
                test.not_nil(response.metadata.rate_limits)
                test.eq(response.metadata.rate_limits.input_token_count, 10)
                test.eq(response.metadata.rate_limits.output_token_count, 5)
                test.eq(response.metadata.rate_limits.requests_remaining, 99)
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
