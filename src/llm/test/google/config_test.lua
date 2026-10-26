local config = require("google_config")
local tests = require("test")
local base64 = require("base64")
local json = require("json")

local function define_tests()
    describe("Google Config", function()

        after_each(function()
            config._env = nil
            config._ctx = nil
            config._store = nil
        end)

        describe("get_value function", function()
            it("should return direct context value when available", function()
                config._ctx = {
                    get = function(key)
                        if key == "api_key" then
                            return "direct_value"
                        end
                        return nil
                    end
                }

                local result = config.get_gemini_api_key()
                tests.eq(result, "direct_value")
            end)

            it("should return env variable reference when direct value is missing", function()
                config._ctx = {
                    get = function(key)
                        if key == "api_key_env" then
                            return "CUSTOM_API_KEY"
                        end
                        return nil
                    end
                }

                config._env = {
                    get = function(key)
                        if key == "CUSTOM_API_KEY" then
                            return "env_ref_value"
                        end
                        return nil
                    end
                }

                local result = config.get_gemini_api_key()
                tests.eq(result, "env_ref_value")
            end)

            it("should return default env variable when others are missing", function()
                config._ctx = {
                    get = function(key)
                        return nil
                    end
                }

                config._env = {
                    get = function(key)
                        if key == "GEMINI_API_KEY" then
                            return "default_env_value"
                        end
                        return nil
                    end
                }

                local result = config.get_gemini_api_key()
                tests.eq(result, "default_env_value")
            end)

            it("should return nil when no values are available", function()
                config._ctx = {
                    get = function(key)
                        return nil
                    end
                }

                config._env = {
                    get = function(key)
                        return nil
                    end
                }

                local result = config.get_gemini_api_key()
                tests.is_nil(result)
            end)

            it("should ignore empty string values", function()
                config._ctx = {
                    get = function(key)
                        if key == "api_key" then
                            return ""
                        end
                        return nil
                    end
                }

                config._env = {
                    get = function(key)
                        if key == "GEMINI_API_KEY" then
                            return "fallback_value"
                        end
                        return nil
                    end
                }

                local result = config.get_gemini_api_key()
                tests.eq(result, "fallback_value")
            end)
        end)

        describe("Credentials Handling", function()
            it("should decode and parse credentials successfully", function()
                local credentials = {
                    token_uri = "https://oauth2.googleapis.com/token",
                    client_email = "test@project.iam.gserviceaccount.com",
                    private_key_id = "key123",
                    private_key = "-----BEGIN PRIVATE KEY-----\ntest\n-----END PRIVATE KEY-----",
                    project_id = "test-project"
                }

                local encoded = base64.encode(json.encode(credentials))

                config._ctx = {
                    get = function(key)
                        return nil
                    end
                }

                config._env = {
                    get = function(key)
                        if key == "GOOGLE_CREDENTIALS" then
                            return encoded
                        end
                        return nil
                    end
                }

                tests.is_true(config.has_credentials())
                tests.eq(config.get_token_uri(), "https://oauth2.googleapis.com/token")
                tests.eq(config.get_client_email(), "test@project.iam.gserviceaccount.com")
                tests.eq(config.get_private_key_id(), "key123")
                tests.contains(tostring(config.get_private_key()), "BEGIN PRIVATE KEY")
                tests.eq(config.get_project_id(), "test-project")
            end)

            it("should return false when credentials are missing", function()
                config._ctx = {
                    get = function(key)
                        return nil
                    end
                }

                config._env = {
                    get = function(key)
                        return nil
                    end
                }

                tests.is_false(config.has_credentials())
            end)

            it("should handle invalid base64 credentials", function()
                config._ctx = {
                    get = function(key)
                        return nil
                    end
                }

                config._env = {
                    get = function(key)
                        if key == "GOOGLE_CREDENTIALS" then
                            return "invalid_base64!!!"
                        end
                        return nil
                    end
                }

                tests.is_false(config.has_credentials())
            end)

            it("should handle invalid JSON credentials", function()
                config._ctx = {
                    get = function(key)
                        return nil
                    end
                }

                config._env = {
                    get = function(key)
                        if key == "GOOGLE_CREDENTIALS" then
                            return base64.encode("not a json")
                        end
                        return nil
                    end
                }

                tests.is_false(config.has_credentials())
            end)
        end)

        describe("OAuth2 Token", function()
            local function profile(email, issuer, key_id)
                config._ctx = {get = function(key)
                    if key == "google_credentials" then
                        return base64.encode(json.encode({
                            client_email = email or "a@example.invalid",
                            token_uri = issuer or "https://issuer.invalid/token",
                            private_key_id = key_id or "test-key",
                            private_key = "private-key-must-not-appear",
                        }))
                    end
                end}
            end

            before_each(function()
                profile()
                config._env = {get = function() return nil end}
            end)

            it("isolates profiles, issuers and key rotations without exposing identity", function()
                local a, err = config.get_oauth2_cache_key()
                tests.is_nil(err)
                tests.eq(a, config.get_oauth2_cache_key())
                tests.is_true(string.find(a, "example", 1, true) == nil)
                tests.is_true(string.find(a, "private-key", 1, true) == nil)
                profile("b@example.invalid")
                tests.is_true(a ~= config.get_oauth2_cache_key())
                profile(nil, "https://other.invalid/token")
                tests.is_true(a ~= config.get_oauth2_cache_key())
                profile(nil, nil, "rotated-key")
                tests.is_true(a ~= config.get_oauth2_cache_key())
            end)

            it("reads only the selected profile and releases its store handle", function()
                local a = config.get_oauth2_cache_key()
                profile("b@example.invalid")
                local b = config.get_oauth2_cache_key()
                local entries = {
                    [a] = {access_token = "token-a"}, [b] = {access_token = "token-b"},
                    [config.OAUTH2_TOKEN_CACHE_KEY] = {access_token = "legacy-token"},
                }
                local released = 0
                config._store = {get = function(cache_id)
                    tests.eq(cache_id, config.DEFAULT_CACHE_ID)
                    return {
                        get = function(_, key) return entries[key] end,
                        release = function() released = released + 1 end,
                    }
                end}
                tests.eq(config.get_oauth2_token().access_token, "token-b")
                profile()
                tests.eq(config.get_oauth2_token().access_token, "token-a")
                entries[a] = nil
                local token, err = config.get_oauth2_token()
                tests.is_nil(token)
                tests.is_nil(err)
                tests.eq(released, 3)
            end)

            it("uses the configured cache and releases it after a read error", function()
                config._env = {get = function(key) if key == "APP_CACHE" then return "custom:cache" end end}
                local released = false
                config._store = {get = function(cache_id)
                    tests.eq(cache_id, "custom:cache")
                    return {
                        get = function() return nil, "read failed" end,
                        release = function() released = true end,
                    }
                end}
                local token, err = config.get_oauth2_token()
                tests.is_nil(token)
                tests.eq(err, "read failed")
                tests.is_true(released)
            end)

            it("returns cache access errors", function()
                config._store = {get = function() return nil, "Store connection failed" end}
                local token, err = config.get_oauth2_token()
                tests.is_nil(token)
                tests.contains(tostring(err), "Failed to access cache store")
            end)

            it("rejects unavailable, scalar and incomplete credentials before cache lookup", function()
                config._store = {get = function() error("must not open cache") end}
                for _, value in ipairs({"", base64.encode("42"), base64.encode("{}"), base64.encode('{"client_email":"a"}')}) do
                    config._ctx = {get = function(key) if key == "google_credentials" then return value end end}
                    local token, err = config.get_oauth2_token()
                    tests.is_nil(token)
                    tests.is_true(type(err) == "string")
                end
            end)
        end)

        describe("Gemini API Key", function()
            it("should return API key from context", function()
                config._ctx = {
                    get = function(key)
                        if key == "api_key" then
                            return "test-api-key-123"
                        end
                        return nil
                    end
                }

                local api_key = config.get_gemini_api_key()
                tests.eq(api_key, "test-api-key-123")
            end)

            it("should return API key from environment", function()
                config._ctx = {
                    get = function(key)
                        return nil
                    end
                }

                config._env = {
                    get = function(key)
                        if key == "GEMINI_API_KEY" then
                            return "env-api-key-456"
                        end
                        return nil
                    end
                }

                local api_key = config.get_gemini_api_key()
                tests.eq(api_key, "env-api-key-456")
            end)
        end)

        describe("Vertex AI Configuration", function()
            it("should construct base URL with location prefix", function()
                config._ctx = {
                    get = function(key)
                        if key == "location" then
                            return "us-central1"
                        end
                        return nil
                    end
                }

                config._env = {
                    get = function(key)
                        if key == "VERTEX_AI_BASE_URL" then
                            return "https://%saiplatform.googleapis.com/v1"
                        elseif key == "GOOGLE_CREDENTIALS" then
                            return base64.encode(json.encode({ project_id = "test" }))
                        end
                        return nil
                    end
                }

                local base_url, err = config.get_vertex_base_url()
                tests.is_nil(err)
                tests.eq(base_url, "https://us-central1-aiplatform.googleapis.com/v1")
            end)

            it("should construct base URL without prefix for global location", function()
                config._ctx = {
                    get = function(key)
                        return nil
                    end
                }

                config._env = {
                    get = function(key)
                        if key == "VERTEX_AI_LOCATION" then
                            return "global"
                        elseif key == "VERTEX_AI_BASE_URL" then
                            return "https://%saiplatform.googleapis.com/v1"
                        elseif key == "GOOGLE_CREDENTIALS" then
                            return base64.encode(json.encode({ project_id = "test" }))
                        end
                        return nil
                    end
                }

                local base_url, err = config.get_vertex_base_url()
                tests.is_nil(err)
                tests.eq(base_url, "https://aiplatform.googleapis.com/v1")
            end)

            it("should accept custom location parameter", function()
                config._ctx = {
                    get = function(key)
                        return nil
                    end
                }

                config._env = {
                    get = function(key)
                        if key == "VERTEX_AI_BASE_URL" then
                            return "https://%saiplatform.googleapis.com/v1"
                        elseif key == "GOOGLE_CREDENTIALS" then
                            return base64.encode(json.encode({ project_id = "test" }))
                        end
                        return nil
                    end
                }

                local base_url, err = config.get_vertex_base_url("europe-west1")
                tests.is_nil(err)
                tests.eq(base_url, "https://europe-west1-aiplatform.googleapis.com/v1")
            end)

            it("should return location from context", function()
                config._ctx = {
                    get = function(key)
                        if key == "location" then
                            return "asia-northeast1"
                        end
                        return nil
                    end
                }

                config._env = {
                    get = function(key)
                        return nil
                    end
                }

                local location = config.get_vertex_location()
                tests.eq(location, "asia-northeast1")
            end)

            it("should return timeout as number", function()
                config._ctx = {
                    get = function(key)
                        if key == "timeout" then
                            return "120"
                        end
                        return nil
                    end
                }

                config._env = {
                    get = function(key)
                        return nil
                    end
                }

                local timeout = config.get_vertex_timeout()
                tests.eq(timeout, 120)
            end)

            it("should return default timeout when not configured", function()
                config._ctx = {
                    get = function(key)
                        return nil
                    end
                }

                config._env = {
                    get = function(key)
                        return nil
                    end
                }

                local timeout = config.get_vertex_timeout()
                tests.eq(timeout, 600)
            end)
        end)

        describe("Generative AI Configuration", function()
            it("should return base URL from context", function()
                config._ctx = {
                    get = function(key)
                        if key == "base_url" then
                            return "https://custom.generativelanguage.googleapis.com/v1"
                        end
                        return nil
                    end
                }

                config._env = {
                    get = function(key)
                        return nil
                    end
                }

                local base_url = config.get_generative_ai_base_url()
                tests.eq(base_url, "https://custom.generativelanguage.googleapis.com/v1")
            end)

            it("should return base URL from environment", function()
                config._ctx = {
                    get = function(key)
                        return nil
                    end
                }

                config._env = {
                    get = function(key)
                        if key == "GEN_AI_API_BASE_URL" then
                            return "https://generativelanguage.googleapis.com/v1beta"
                        end
                        return nil
                    end
                }

                local base_url = config.get_generative_ai_base_url()
                tests.eq(base_url, "https://generativelanguage.googleapis.com/v1beta")
            end)

            it("should return timeout from context", function()
                config._ctx = {
                    get = function(key)
                        if key == "timeout" then
                            return "90"
                        end
                        return nil
                    end
                }

                config._env = {
                    get = function(key)
                        return nil
                    end
                }

                local timeout = config.get_generative_ai_timeout()
                tests.eq(timeout, "90")
            end)

            it("should return timeout from environment", function()
                config._ctx = {
                    get = function(key)
                        return nil
                    end
                }

                config._env = {
                    get = function(key)
                        if key == "GEN_AI_TIMEOUT" then
                            return "180"
                        end
                        return nil
                    end
                }

                local timeout = config.get_generative_ai_timeout()
                tests.eq(timeout, "180")
            end)
        end)

        describe("Context Error Handling", function()
            it("should handle context.get errors gracefully", function()
                config._ctx = {
                    get = function(key)
                        error("Context access failed")
                    end
                }

                config._env = {
                    get = function(key)
                        if key == "GEMINI_API_KEY" then
                            return "fallback-key"
                        end
                        return nil
                    end
                }

                local api_key = config.get_gemini_api_key()
                tests.eq(api_key, "fallback-key")
            end)
        end)

        describe("Constants", function()
            it("should have correct cache key constant", function()
                tests.eq(config.OAUTH2_TOKEN_CACHE_KEY, "google_oauth2_token")
            end)

            it("should have correct default cache ID constant", function()
                tests.eq(config.DEFAULT_CACHE_ID, "app:cache")
            end)

            it("should have correct client contract ID constant", function()
                tests.eq(config.CLIENT_CONTRACT_ID, "wippy.llm.google:client_contract")
            end)
        end)

        describe("Retry Configuration", function()
            it("should normalize retry from context", function()
                config._ctx = {
                    get = function(key)
                        if key == "retry" then
                            return { attempts = 2, backoff_ms = 0 }
                        end
                        return nil
                    end
                }

                local retry = config.get_retry()
                tests.eq(retry.attempts, 2)
                tests.eq(retry.backoff_ms, 0)
            end)

            it("should return nil when retry is not configured", function()
                config._ctx = {
                    get = function(key)
                        return nil
                    end
                }

                tests.is_nil(config.get_retry())
            end)
        end)
    end)
end

return tests.run_cases(define_tests)
