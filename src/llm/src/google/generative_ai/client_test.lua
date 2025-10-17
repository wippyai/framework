local client = require("generative_ai_client")
local json = require("json")
local tests = require("test")

local function define_tests()
    describe("Google Generative AI Client", function()

        after_each(function()
            client._client = nil
            client._config = nil
        end)

        describe("API Key Handling", function()
            it("should return 401 error when API key is missing", function()
                client._config = {
                    get_gemini_api_key = function()
                        return nil
                    end
                }

                local response = client.request({})

                expect(response.status_code).to_equal(401)
                expect(response.message).to_equal("Google Gemini API key is missing")
            end)

            it("should use API key from config", function()
                client._config = {
                    get_gemini_api_key = function()
                        return "test-gemini-api-key"
                    end,

                    get_generative_ai_base_url = function()
                        return "https://generativelanguage.googleapis.com/v1beta/models"
                    end,

                    get_generative_ai_timeout = function()
                        return 60
                    end
                }

                client._client = {
                    request = function(method, url, options)
                        expect(options.headers["x-goog-api-key"]).to_equal("test-gemini-api-key")
                        return nil
                    end
                }

                client.request({
                    model = "gemini-pro",
                    endpoint_path = "generateContent",
                    payload = { contents = {} }
                })
            end)
        end)

        describe("HTTP Method Support", function()
            it("should default to POST method", function()
                client._config = {
                    get_gemini_api_key = function()
                        return "test-gemini-api-key"
                    end,

                    get_generative_ai_base_url = function()
                        return "https://generativelanguage.googleapis.com/v1beta/models"
                    end,

                    get_generative_ai_timeout = function()
                        return 60
                    end
                }

                client._client = {
                    request = function(method, url, options)
                        expect(method).to_equal("POST")
                        return nil
                    end
                }

                client.request({
                    model = "gemini-pro",
                    endpoint_path = "generateContent"
                })
            end)

            it("should support GET method", function()
                client._config = {
                    get_gemini_api_key = function()
                        return "test-gemini-api-key"
                    end,

                    get_generative_ai_base_url = function()
                        return "https://generativelanguage.googleapis.com/v1beta/models"
                    end,

                    get_generative_ai_timeout = function()
                        return 60
                    end
                }

                client._client = {
                    request = function(method, url, options)
                        expect(method).to_equal("GET")
                        expect(options.body).to_be_nil()
                        return nil
                    end
                }

                client.request({
                    model = "gemini-pro",
                    options = { method = "GET" }
                })
            end)
        end)

        describe("Request Body Handling", function()
            it("should encode payload as JSON for POST requests", function()
                local test_payload = {
                    contents = {
                        { role = "user", parts = { { text = "Hello" } } }
                    },
                    generationConfig = {
                        temperature = 0.7,
                        maxOutputTokens = 100
                    }
                }

                client._config = {
                    get_gemini_api_key = function()
                        return "test-gemini-api-key"
                    end,

                    get_generative_ai_base_url = function()
                        return "https://generativelanguage.googleapis.com/v1beta/models"
                    end,

                    get_generative_ai_timeout = function()
                        return 60
                    end
                }

                client._client = {
                    request = function(method, url, options)
                        local body = json.decode(options.body)
                        expect(body.contents[1].role).to_equal("user")
                        expect(body.contents[1].parts[1].text).to_equal("Hello")
                        expect(body.generationConfig.temperature).to_equal(0.7)
                        expect(body.generationConfig.maxOutputTokens).to_equal(100)
                        return nil
                    end
                }

                client.request({
                    model = "gemini-pro",
                    endpoint_path = "generateContent",
                    payload = test_payload
                })
            end)

            it("should encode empty payload as empty object for POST", function()
                client._config = {
                    get_gemini_api_key = function()
                        return "test-gemini-api-key"
                    end,

                    get_generative_ai_base_url = function()
                        return "https://generativelanguage.googleapis.com/v1beta/models"
                    end,

                    get_generative_ai_timeout = function()
                        return 60
                    end
                }

                client._client = {
                    request = function(method, url, options)
                        expect(options.body).to_equal(json.encode({}))
                        return nil
                    end
                }

                client.request({
                    model = "gemini-pro",
                    endpoint_path = "generateContent"
                })
            end)

            it("should not include body for GET requests", function()
                client._config = {
                    get_gemini_api_key = function()
                        return "test-gemini-api-key"
                    end,

                    get_generative_ai_base_url = function()
                        return "https://generativelanguage.googleapis.com/v1beta/models"
                    end,

                    get_generative_ai_timeout = function()
                        return 60
                    end
                }

                client._client = {
                    request = function(method, url, options)
                        expect(options.body).to_be_nil()
                        return nil
                    end
                }

                client.request({
                    model = "gemini-pro",
                    options = { method = "GET" },
                    payload = { should = "be_ignored" }
                })
            end)
        end)

        describe("URL Construction", function()
            it("should construct URL with model and endpoint_path", function()
                client._config = {
                    get_gemini_api_key = function()
                        return "test-gemini-api-key"
                    end,

                    get_generative_ai_base_url = function()
                        return "https://generativelanguage.googleapis.com/v1beta/models"
                    end,

                    get_generative_ai_timeout = function()
                        return 60
                    end
                }

                client._client = {
                    request = function(method, url, options)
                        expect(url).to_equal("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent")
                        return nil
                    end
                }

                client.request({
                    model = "gemini-1.5-pro",
                    endpoint_path = "generateContent"
                })
            end)

            it("should construct URL with only model when endpoint_path is missing", function()
                client._config = {
                    get_gemini_api_key = function()
                        return "test-gemini-api-key"
                    end,

                    get_generative_ai_base_url = function()
                        return "https://generativelanguage.googleapis.com/v1beta/models"
                    end,

                    get_generative_ai_timeout = function()
                        return 60
                    end
                }

                client._client = {
                    request = function(method, url, options)
                        expect(url).to_equal("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro")
                        return nil
                    end
                }

                client.request({
                    model = "gemini-1.5-pro"
                })
            end)

            it("should use base URL without model when model is empty", function()
                client._config = {
                    get_gemini_api_key = function()
                        return "test-gemini-api-key"
                    end,

                    get_generative_ai_base_url = function()
                        return "https://generativelanguage.googleapis.com/v1beta/models"
                    end,

                    get_generative_ai_timeout = function()
                        return 60
                    end
                }

                client._client = {
                    request = function(method, url, options)
                        expect(url).to_equal("https://generativelanguage.googleapis.com/v1beta/models")
                        return nil
                    end
                }

                client.request({})
            end)

            it("should use custom base URL from options", function()
                client._config = {
                    get_gemini_api_key = function()
                        return "test-gemini-api-key"
                    end,

                    get_generative_ai_base_url = function()
                        return "https://generativelanguage.googleapis.com/v1beta/models"
                    end,

                    get_generative_ai_timeout = function()
                        return 60
                    end
                }

                client._client = {
                    request = function(method, url, options)
                        expect(url).to_equal("https://custom.api.com/v2/models/gemini-pro:generateContent")
                        return nil
                    end
                }

                client.request({
                    model = "gemini-pro",
                    endpoint_path = "generateContent",
                    options = {
                        base_url = "https://custom.api.com/v2/models"
                    }
                })
            end)
        end)

        describe("Timeout Handling", function()
            it("should use default timeout from config", function()
                client._config = {
                    get_gemini_api_key = function()
                        return "test-gemini-api-key"
                    end,

                    get_generative_ai_base_url = function()
                        return "https://generativelanguage.googleapis.com/v1beta/models"
                    end,

                    get_generative_ai_timeout = function()
                        return 120
                    end
                }

                client._client = {
                    request = function(method, url, options)
                        expect(options.timeout).to_equal(120)
                        return nil
                    end
                }

                client.request({
                    model = "gemini-pro",
                    endpoint_path = "generateContent"
                })
            end)

            it("should use custom timeout from options", function()
                client._config = {
                    get_gemini_api_key = function()
                        return "test-gemini-api-key"
                    end,

                    get_generative_ai_base_url = function()
                        return "https://generativelanguage.googleapis.com/v1beta/models"
                    end,

                    get_generative_ai_timeout = function()
                        return 60
                    end
                }

                client._client = {
                    request = function(method, url, options)
                        expect(options.timeout).to_equal(180)
                        return nil
                    end
                }

                client.request({
                    model = "gemini-pro",
                    endpoint_path = "generateContent",
                    options = {
                        timeout = 180
                    }
                })
            end)
        end)

        describe("Response Handling", function()
            it("should return successful response", function()
                local test_response = {
                    status_code = 200,
                    candidates = {
                        {
                            content = {
                                parts = { { text = "Hello, world!" } }
                            },
                            finishReason = "STOP"
                        }
                    }
                }

                client._config = {
                    get_gemini_api_key = function()
                        return "test-gemini-api-key"
                    end,

                    get_generative_ai_base_url = function()
                        return "https://generativelanguage.googleapis.com/v1beta/models"
                    end,

                    get_generative_ai_timeout = function()
                        return 60
                    end
                }

                client._client = {
                    request = function(method, url, options)
                        return test_response
                    end
                }

                local response = client.request({
                    model = "gemini-pro",
                    endpoint_path = "generateContent"
                })

                expect(response.status_code).to_equal(test_response.status_code)
                expect(response.candidates[1].content.parts[1].text).to_equal("Hello, world!")
                expect(response.candidates[1].finishReason).to_equal("STOP")
            end)

            it("should return error response", function()
                local test_response = {
                    status_code = 400,
                    error = {
                        code = 400,
                        message = "Invalid request",
                        status = "INVALID_ARGUMENT"
                    }
                }

                client._config = {
                    get_gemini_api_key = function()
                        return "test-gemini-api-key"
                    end,

                    get_generative_ai_base_url = function()
                        return "https://generativelanguage.googleapis.com/v1beta/models"
                    end,

                    get_generative_ai_timeout = function()
                        return 60
                    end
                }

                client._client = {
                    request = function(method, url, options)
                        return test_response
                    end
                }

                local response = client.request({
                    model = "gemini-pro",
                    endpoint_path = "generateContent"
                })

                expect(response.status_code).to_equal(test_response.status_code)
                expect(response.error.code).to_equal(test_response.error.code)
                expect(response.error.message).to_equal(test_response.error.message)
                expect(response.error.status).to_equal(test_response.error.status)
            end)
        end)
    end)
end

return tests.run_cases(define_tests)
