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
                tests.contains(config.get_private_key(), "BEGIN PRIVATE KEY")
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
            it("should retrieve token from cache store", function()
                local mock_store_instance = {
                    get = function(self, key)
                        if key == config.OAUTH2_TOKEN_CACHE_KEY then
                            return {
                                access_token = "cached_token_123",
                                expires_at = 1234567890
                            }
                        end
                        return nil
                    end
                }

                config._store = {
                    get = function(cache_id)
                        return mock_store_instance, nil
                    end
                }

                config._env = {
                    get = function(key)
                        return nil
                    end
                }

                local token, err = config.get_oauth2_token()

                tests.is_nil(err)
                assert(token)
                tests.eq(token.access_token, "cached_token_123")
                tests.eq(token.expires_at, 1234567890)
            end)

            it("should use custom cache ID from APP_CACHE env", function()
                local custom_cache_id = "custom:cache:id"
                local mock_store_instance = {
                    get = function(self, key)
                        return { access_token = "token" }
                    end
                }

                config._store = {
                    get = function(cache_id)
                        tests.eq(cache_id, custom_cache_id)
                        return mock_store_instance, nil
                    end
                }

                config._env = {
                    get = function(key)
                        if key == "APP_CACHE" then
                            return custom_cache_id
                        end
                        return nil
                    end
                }

                config.get_oauth2_token()
            end)

            it("should use default cache ID when APP_CACHE is not set", function()
                local mock_store_instance = {
                    get = function(self, key)
                        return { access_token = "token" }
                    end
                }

                config._store = {
                    get = function(cache_id)
                        tests.eq(cache_id, config.DEFAULT_CACHE_ID)
                        return mock_store_instance, nil
                    end
                }

                config._env = {
                    get = function(key)
                        return nil
                    end
                }

                config.get_oauth2_token()
            end)

            it("should return error when store fails", function()
                config._store = {
                    get = function(cache_id)
                        return nil, "Store connection failed"
                    end
                }

                config._env = {
                    get = function(key)
                        return nil
                    end
                }

                local token, err = config.get_oauth2_token()

                tests.is_nil(token)
                tests.contains(err, "Failed to access cache store")
            end)

            it("should return nil when token is not in cache", function()
                local mock_store_instance = {
                    get = function(self, key)
                        return nil
                    end
                }

                config._store = {
                    get = function(cache_id)
                        return mock_store_instance, nil
                    end
                }

                config._env = {
                    get = function(key)
                        return nil
                    end
                }

                local token, err = config.get_oauth2_token()

                tests.is_nil(token)
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
    end)
end

return tests.run_cases(define_tests)
