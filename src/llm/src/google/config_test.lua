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
                expect(result).to_equal("direct_value")
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
                expect(result).to_equal("env_ref_value")
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
                expect(result).to_equal("default_env_value")
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
                expect(result).to_be_nil()
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
                expect(result).to_equal("fallback_value")
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

                expect(config.has_credentials()).to_be_true()
                expect(config.get_token_uri()).to_equal("https://oauth2.googleapis.com/token")
                expect(config.get_client_email()).to_equal("test@project.iam.gserviceaccount.com")
                expect(config.get_private_key_id()).to_equal("key123")
                expect(config.get_private_key()).to_contain("BEGIN PRIVATE KEY")
                expect(config.get_project_id()).to_equal("test-project")
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

                expect(config.has_credentials()).to_be_false()
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

                expect(config.has_credentials()).to_be_false()
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

                expect(config.has_credentials()).to_be_false()
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

                expect(err).to_be_nil()
                expect(token).not_to_be_nil()
                expect(token.access_token).to_equal("cached_token_123")
                expect(token.expires_at).to_equal(1234567890)
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
                        expect(cache_id).to_equal(custom_cache_id)
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
                        expect(cache_id).to_equal(config.DEFAULT_CACHE_ID)
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

                expect(token).to_be_nil()
                expect(err).to_contain("Failed to access cache store")
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

                expect(token).to_be_nil()
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
                expect(api_key).to_equal("test-api-key-123")
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
                expect(api_key).to_equal("env-api-key-456")
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
                expect(err).to_be_nil()
                expect(base_url).to_equal("https://us-central1-aiplatform.googleapis.com/v1")
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
                expect(err).to_be_nil()
                expect(base_url).to_equal("https://aiplatform.googleapis.com/v1")
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
                expect(err).to_be_nil()
                expect(base_url).to_equal("https://europe-west1-aiplatform.googleapis.com/v1")
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
                expect(location).to_equal("asia-northeast1")
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
                expect(timeout).to_equal(120)
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
                expect(timeout).to_equal(600)
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
                expect(base_url).to_equal("https://custom.generativelanguage.googleapis.com/v1")
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
                expect(base_url).to_equal("https://generativelanguage.googleapis.com/v1beta")
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
                expect(timeout).to_equal("90")
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
                expect(timeout).to_equal("180")
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
                expect(api_key).to_equal("fallback-key")
            end)
        end)

        describe("Constants", function()
            it("should have correct cache key constant", function()
                expect(config.OAUTH2_TOKEN_CACHE_KEY).to_equal("google_oauth2_token")
            end)

            it("should have correct default cache ID constant", function()
                expect(config.DEFAULT_CACHE_ID).to_equal("app:cache")
            end)

            it("should have correct client contract ID constant", function()
                expect(config.CLIENT_CONTRACT_ID).to_equal("wippy.llm.google:client_contract")
            end)
        end)
    end)
end

return tests.run_cases(define_tests)
