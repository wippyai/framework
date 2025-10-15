local client = require("vertex_client")
local json = require("json")
local tests = require("test")

local function define_tests()
    describe("Google Vertex AI Client", function()

        after_each(function()
            client._client = nil
            client._config = nil
        end)

        describe("OAuth2 Token Handling", function()
            it("should return 401 error when OAuth2 token is missing", function()
                client._config = {
                    get_oauth2_token = function()
                        return nil
                    end
                }

                local response = client.request({})

                expect(response.status_code).to_equal(401)
                expect(response.message).to_equal("Google OAuth2 token is missing")
            end)

            it("should use OAuth2 token from config", function()
                client._config = {
                    get_oauth2_token = function()
                        return { access_token = "test-oauth2-token" }
                    end,

                    get_vertex_base_url = function()
                        return "https://us-central1-aiplatform.googleapis.com/v1", nil
                    end,

                    get_vertex_timeout = function()
                        return 60
                    end,

                    get_project_id = function()
                        return "test-project"
                    end,

                    get_vertex_location = function()
                        return "us-central1"
                    end
                }

                client._client = {
                    request = function(method, url, options)
                        expect(options.headers["Authorization"]).to_equal("Bearer test-oauth2-token")
                        return nil
                    end
                }

                client.request({
                    model = "gemini-pro",
                    endpoint_path = "generateContent"
                })
            end)
        end)

        describe("HTTP Method Support", function()
            it("should default to POST method", function()
                client._config = {
                    get_oauth2_token = function()
                        return { access_token = "test-oauth2-token" }
                    end,

                    get_vertex_base_url = function()
                        return "https://us-central1-aiplatform.googleapis.com/v1", nil
                    end,

                    get_vertex_timeout = function()
                        return 60
                    end,

                    get_project_id = function()
                        return "test-project"
                    end,

                    get_vertex_location = function()
                        return "us-central1"
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
                    get_oauth2_token = function()
                        return { access_token = "test-oauth2-token" }
                    end,

                    get_vertex_base_url = function()
                        return "https://us-central1-aiplatform.googleapis.com/v1", nil
                    end,

                    get_vertex_timeout = function()
                        return 60
                    end,

                    get_project_id = function()
                        return "test-project"
                    end,

                    get_vertex_location = function()
                        return "us-central1"
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
                    get_oauth2_token = function()
                        return { access_token = "test-oauth2-token" }
                    end,

                    get_vertex_base_url = function()
                        return "https://us-central1-aiplatform.googleapis.com/v1", nil
                    end,

                    get_vertex_timeout = function()
                        return 60
                    end,

                    get_project_id = function()
                        return "test-project"
                    end,

                    get_vertex_location = function()
                        return "us-central1"
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
                    get_oauth2_token = function()
                        return { access_token = "test-oauth2-token" }
                    end,

                    get_vertex_base_url = function()
                        return "https://us-central1-aiplatform.googleapis.com/v1", nil
                    end,

                    get_vertex_timeout = function()
                        return 60
                    end,

                    get_project_id = function()
                        return "test-project"
                    end,

                    get_vertex_location = function()
                        return "us-central1"
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
                    get_oauth2_token = function()
                        return { access_token = "test-oauth2-token" }
                    end,

                    get_vertex_base_url = function()
                        return "https://us-central1-aiplatform.googleapis.com/v1", nil
                    end,

                    get_vertex_timeout = function()
                        return 60
                    end,

                    get_project_id = function()
                        return "test-project"
                    end,

                    get_vertex_location = function()
                        return "us-central1"
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
            it("should construct URL with project, location, model and endpoint_path", function()
                client._config = {
                    get_oauth2_token = function()
                        return { access_token = "test-oauth2-token" }
                    end,

                    get_vertex_base_url = function()
                        return "https://us-central1-aiplatform.googleapis.com/v1", nil
                    end,

                    get_vertex_timeout = function()
                        return 60
                    end,

                    get_project_id = function()
                        return "test-project"
                    end,

                    get_vertex_location = function()
                        return "us-central1"
                    end
                }

                client._client = {
                    request = function(method, url, options)
                        expect(url).to_equal("https://us-central1-aiplatform.googleapis.com/v1/projects/test-project/locations/us-central1/publishers/google/models/gemini-1.5-pro:generateContent")
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
                    get_oauth2_token = function()
                        return { access_token = "test-oauth2-token" }
                    end,

                    get_vertex_base_url = function()
                        return "https://us-central1-aiplatform.googleapis.com/v1", nil
                    end,

                    get_vertex_timeout = function()
                        return 60
                    end,

                    get_project_id = function()
                        return "test-project"
                    end,

                    get_vertex_location = function()
                        return "us-central1"
                    end
                }

                client._client = {
                    request = function(method, url, options)
                        expect(url).to_equal("https://us-central1-aiplatform.googleapis.com/v1/publishers/google/models/gemini-1.5-pro")
                        return nil
                    end
                }

                client.request({
                    model = "gemini-1.5-pro"
                })
            end)

            it("should use base URL without model when model is empty", function()
                client._config = {
                    get_oauth2_token = function()
                        return { access_token = "test-oauth2-token" }
                    end,

                    get_vertex_base_url = function()
                        return "https://us-central1-aiplatform.googleapis.com/v1", nil
                    end,

                    get_vertex_timeout = function()
                        return 60
                    end,

                    get_project_id = function()
                        return "test-project"
                    end,

                    get_vertex_location = function()
                        return "us-central1"
                    end
                }

                client._client = {
                    request = function(method, url, options)
                        expect(url).to_equal("https://us-central1-aiplatform.googleapis.com/v1/publishers/google/models")
                        return nil
                    end
                }

                client.request({})
            end)

            it("should use custom project and location from options", function()
                client._config = {
                    get_oauth2_token = function()
                        return { access_token = "test-oauth2-token" }
                    end,

                    get_vertex_base_url = function()
                        return "https://europe-west1-aiplatform.googleapis.com/v1", nil
                    end,

                    get_vertex_timeout = function()
                        return 60
                    end,

                    get_project_id = function()
                        return "default-project"
                    end,

                    get_vertex_location = function()
                        return "us-central1"
                    end
                }

                client._client = {
                    request = function(method, url, options)
                        expect(url).to_equal("https://europe-west1-aiplatform.googleapis.com/v1/projects/custom-project/locations/europe-west1/publishers/google/models/gemini-pro:generateContent")
                        return nil
                    end
                }

                client.request({
                    model = "gemini-pro",
                    endpoint_path = "generateContent",
                    options = {
                        project = "custom-project",
                        location = "europe-west1"
                    }
                })
            end)

            it("should use custom base URL from options", function()
                client._config = {
                    get_oauth2_token = function()
                        return { access_token = "test-oauth2-token" }
                    end,

                    get_vertex_timeout = function()
                        return 60
                    end,

                    get_project_id = function()
                        return "test-project"
                    end,

                    get_vertex_location = function()
                        return "us-central1"
                    end
                }

                client._client = {
                    request = function(method, url, options)
                        expect(url).to_equal("https://custom.api.com/v2/projects/test-project/locations/us-central1/publishers/google/models/gemini-pro:generateContent")
                        return nil
                    end
                }

                client.request({
                    model = "gemini-pro",
                    endpoint_path = "generateContent",
                    options = {
                        base_url = "https://custom.api.com/v2"
                    }
                })
            end)

            it("should not include project and location for non-required endpoints", function()
                client._config = {
                    get_oauth2_token = function()
                        return { access_token = "test-oauth2-token" }
                    end,

                    get_vertex_base_url = function()
                        return "https://us-central1-aiplatform.googleapis.com/v1", nil
                    end,

                    get_vertex_timeout = function()
                        return 60
                    end,

                    get_project_id = function()
                        return "test-project"
                    end,

                    get_vertex_location = function()
                        return "us-central1"
                    end
                }

                client._client = {
                    request = function(method, url, options)
                        expect(url).to_equal("https://us-central1-aiplatform.googleapis.com/v1/publishers/google/models/gemini-pro:otherEndpoint")
                        return nil
                    end
                }

                client.request({
                    model = "gemini-pro",
                    endpoint_path = "otherEndpoint"
                })
            end)
        end)

        describe("Timeout Handling", function()
            it("should use default timeout from config", function()
                client._config = {
                    get_oauth2_token = function()
                        return { access_token = "test-oauth2-token" }
                    end,

                    get_vertex_base_url = function()
                        return "https://us-central1-aiplatform.googleapis.com/v1", nil
                    end,

                    get_vertex_timeout = function()
                        return 120
                    end,

                    get_project_id = function()
                        return "test-project"
                    end,

                    get_vertex_location = function()
                        return "us-central1"
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
                    get_oauth2_token = function()
                        return { access_token = "test-oauth2-token" }
                    end,

                    get_vertex_base_url = function()
                        return "https://us-central1-aiplatform.googleapis.com/v1", nil
                    end,

                    get_vertex_timeout = function()
                        return 60
                    end,

                    get_project_id = function()
                        return "test-project"
                    end,

                    get_vertex_location = function()
                        return "us-central1"
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

        describe("Error Handling", function()
            it("should return error when base URL config returns error", function()
                client._config = {
                    get_oauth2_token = function()
                        return { access_token = "test-oauth2-token" }
                    end,

                    get_vertex_base_url = function()
                        return nil, "Failed to get base URL"
                    end,

                    get_vertex_timeout = function()
                        return 60
                    end,

                    get_project_id = function()
                        return "test-project"
                    end,

                    get_vertex_location = function()
                        return "us-central1"
                    end
                }

                local response = client.request({
                    model = "gemini-pro",
                    endpoint_path = "generateContent"
                })

                expect(response.status_code).to_equal(401)
                expect(response.message).to_equal("Failed to get base URL")
            end)

            it("should return error from HTTP client", function()
                client._config = {
                    get_oauth2_token = function()
                        return { access_token = "test-oauth2-token" }
                    end,

                    get_vertex_base_url = function()
                        return "https://us-central1-aiplatform.googleapis.com/v1", nil
                    end,

                    get_vertex_timeout = function()
                        return 60
                    end,

                    get_project_id = function()
                        return "test-project"
                    end,

                    get_vertex_location = function()
                        return "us-central1"
                    end
                }

                local test_error = {
                    status_code = 500,
                    message = "Connection failed"
                }

                client._client = {
                    request = function(method, url, options)
                        return nil, test_error
                    end
                }

                local response = client.request({
                    model = "gemini-pro",
                    endpoint_path = "generateContent"
                })

                expect(response).to_equal(test_error)
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
                    get_oauth2_token = function()
                        return { access_token = "test-oauth2-token" }
                    end,

                    get_vertex_base_url = function()
                        return "https://us-central1-aiplatform.googleapis.com/v1", nil
                    end,

                    get_vertex_timeout = function()
                        return 60
                    end,

                    get_project_id = function()
                        return "test-project"
                    end,

                    get_vertex_location = function()
                        return "us-central1"
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
                    get_oauth2_token = function()
                        return { access_token = "test-oauth2-token" }
                    end,

                    get_vertex_base_url = function()
                        return "https://us-central1-aiplatform.googleapis.com/v1", nil
                    end,

                    get_vertex_timeout = function()
                        return 60
                    end,

                    get_project_id = function()
                        return "test-project"
                    end,

                    get_vertex_location = function()
                        return "us-central1"
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
                expect(response.error.code).to_equal(400)
                expect(response.error.message).to_equal("Invalid request")
                expect(response.error.status).to_equal("INVALID_ARGUMENT")
            end)
        end)
    end)
end

return tests.run_cases(define_tests)
