local embed_handler = require("embed_handler")
local json = require("json")
local test = require("test")

local function define_tests()
    describe("OpenAI Embed Handler", function()

        after_each(function()
            -- Clean up injected dependencies
            embed_handler._client._ctx = nil
            embed_handler._client._env = nil
            embed_handler._client._http_client = nil
        end)

        describe("Contract Argument Validation", function()
            it("should require model parameter", function()
                local contract_args = {
                    input = "Test input text"
                }

                local response, err = embed_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Invalid")
                test.contains(tostring(err:message()), "Model is required")
            end)

            it("should require input parameter", function()
                local contract_args = {
                    model = "text-embedding-3-small"
                }

                local response, err = embed_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Invalid")
                test.contains(tostring(err:message()), "Input is required")
            end)

            it("should accept string input", function()
                embed_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                embed_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                embed_handler._client._http_client = {
                    post = function(url, options)
                        local payload = json.decode(tostring(options.body))
                        test.eq(payload.input, "Test input string")
                        test.eq(type(payload.input), "string")

                        return {
                            status_code = 200,
                            body = json.encode({
                                data = {
                                    {
                                        embedding = { 0.1, 0.2, 0.3 },
                                        index = 0
                                    }
                                },
                                usage = { prompt_tokens = 5, total_tokens = 5 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "text-embedding-3-small",
                    input = "Test input string"
                }

                local response, err = embed_handler.handler(contract_args)

                test.is_true(response.success)
                test.not_nil(response.result.embeddings)
                test.eq(type(response.result.embeddings), "table")
                test.eq(#response.result.embeddings, 1)
                test.eq(type(response.result.embeddings[1]), "table")
                test.eq(#response.result.embeddings[1], 3)
            end)

            it("should accept array input", function()
                embed_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                embed_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                embed_handler._client._http_client = {
                    post = function(url, options)
                        local payload = json.decode(tostring(options.body))
                        test.eq(type(payload.input), "table")
                        test.eq(#payload.input, 2)
                        test.eq(payload.input[1], "First text")
                        test.eq(payload.input[2], "Second text")

                        return {
                            status_code = 200,
                            body = json.encode({
                                data = {
                                    { embedding = { 0.1, 0.2 }, index = 0 },
                                    { embedding = { 0.3, 0.4 }, index = 1 }
                                },
                                usage = { prompt_tokens = 8, total_tokens = 8 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "text-embedding-3-small",
                    input = { "First text", "Second text" }
                }

                local response, err = embed_handler.handler(contract_args)

                test.is_true(response.success)
                test.not_nil(response.result.embeddings)
                test.eq(type(response.result.embeddings), "table")
                test.eq(#response.result.embeddings, 2)
            end)
        end)

        describe("Single Input Embeddings", function()
            it("should handle successful single embedding", function()
                embed_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                embed_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                embed_handler._client._http_client = {
                    post = function(url, options)
                        test.contains(tostring(url), "/embeddings")

                        local payload = json.decode(tostring(options.body))
                        test.eq(payload.model, "text-embedding-3-small")
                        test.eq(payload.input, "Test embedding input")
                        test.eq(payload.encoding_format, "float")

                        return {
                            status_code = 200,
                            body = json.encode({
                                data = {
                                    {
                                        embedding = { 0.123, -0.456, 0.789 },
                                        index = 0,
                                        object = "embedding"
                                    }
                                },
                                model = "text-embedding-3-small",
                                usage = {
                                    prompt_tokens = 5,
                                    total_tokens = 5
                                }
                            }),
                            headers = { ["X-Request-Id"] = "req_embed123" }
                        }
                    end
                }

                local contract_args = {
                    model = "text-embedding-3-small",
                    input = "Test embedding input"
                }

                local response, err = embed_handler.handler(contract_args)

                test.is_true(response.success)
                test.not_nil(response.result)
                test.not_nil(response.result.embeddings)
                test.eq(type(response.result.embeddings), "table")
                test.eq(#response.result.embeddings, 1)
                test.eq(type(response.result.embeddings[1]), "table")
                test.eq(#response.result.embeddings[1], 3)
                test.eq(response.result.embeddings[1][1], 0.123)
                test.eq(response.result.embeddings[1][2], -0.456)
                test.eq(response.result.embeddings[1][3], 0.789)
                test.eq(response.tokens.prompt_tokens, 5)
                test.eq(response.tokens.total_tokens, 5)
            end)

            it("should handle dimensions parameter", function()
                embed_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                embed_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                embed_handler._client._http_client = {
                    post = function(url, options)
                        local payload = json.decode(tostring(options.body))
                        test.eq(payload.dimensions, 512)

                        return {
                            status_code = 200,
                            body = json.encode({
                                data = {
                                    {
                                        embedding = { 0.1, 0.2 },
                                        index = 0
                                    }
                                },
                                usage = { prompt_tokens = 3, total_tokens = 3 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "text-embedding-3-small",
                    input = "Test with dimensions",
                    options = {
                        dimensions = 512
                    }
                }

                local response, err = embed_handler.handler(contract_args)

                test.is_true(response.success)
                test.eq(#response.result.embeddings[1], 2)
            end)

            it("should handle user parameter", function()
                embed_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                embed_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                embed_handler._client._http_client = {
                    post = function(url, options)
                        local payload = json.decode(tostring(options.body))
                        test.eq(payload.user, "test-user-id")

                        return {
                            status_code = 200,
                            body = json.encode({
                                data = { { embedding = { 0.1, 0.2 }, index = 0 } },
                                usage = { prompt_tokens = 3, total_tokens = 3 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "text-embedding-3-small",
                    input = "Test text",
                    options = {
                        user = "test-user-id"
                    }
                }

                local response, err = embed_handler.handler(contract_args)

                test.is_true(response.success)
            end)
        end)

        describe("Multiple Input Embeddings", function()
            it("should handle multiple inputs", function()
                embed_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                embed_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                embed_handler._client._http_client = {
                    post = function(url, options)
                        local payload = json.decode(tostring(options.body))
                        test.eq(type(payload.input), "table")
                        test.eq(#payload.input, 3)

                        return {
                            status_code = 200,
                            body = json.encode({
                                data = {
                                    {
                                        embedding = { 0.111, -0.222 },
                                        index = 0
                                    },
                                    {
                                        embedding = { 0.333, -0.444 },
                                        index = 1
                                    },
                                    {
                                        embedding = { 0.555, -0.666 },
                                        index = 2
                                    }
                                },
                                usage = {
                                    prompt_tokens = 12,
                                    total_tokens = 12
                                }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "text-embedding-3-small",
                    input = { "First text", "Second text", "Third text" }
                }

                local response, err = embed_handler.handler(contract_args)

                test.is_true(response.success)
                test.eq(type(response.result.embeddings), "table")
                test.eq(#response.result.embeddings, 3)
                test.eq(type(response.result.embeddings[1]), "table")
                test.eq(type(response.result.embeddings[2]), "table")
                test.eq(type(response.result.embeddings[3]), "table")

                -- Check individual embeddings
                test.eq(response.result.embeddings[1][1], 0.111)
                test.eq(response.result.embeddings[1][2], -0.222)
                test.eq(response.result.embeddings[2][1], 0.333)
                test.eq(response.result.embeddings[2][2], -0.444)
                test.eq(response.result.embeddings[3][1], 0.555)
                test.eq(response.result.embeddings[3][2], -0.666)

                test.eq(response.tokens.prompt_tokens, 12)
                test.eq(response.tokens.total_tokens, 12)
            end)

            it("should maintain consistent dimension sizes across embeddings", function()
                embed_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                embed_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                embed_handler._client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = json.encode({
                                data = {
                                    { embedding = { 0.1, 0.2, 0.3, 0.4 }, index = 0 },
                                    { embedding = { 0.5, 0.6, 0.7, 0.8 }, index = 1 }
                                },
                                usage = { prompt_tokens = 8, total_tokens = 8 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "text-embedding-3-small",
                    input = { "Text one", "Text two" }
                }

                local response, err = embed_handler.handler(contract_args)

                test.is_true(response.success)
                test.eq(#response.result.embeddings, 2)
                test.eq(#response.result.embeddings[1], 4)
                test.eq(#response.result.embeddings[2], 4)
                test.eq(#response.result.embeddings[1], #response.result.embeddings[2])
            end)
        end)

        describe("Error Handling", function()
            it("should handle model not found errors", function()
                embed_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                embed_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                embed_handler._client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 404,
                            body = json.encode({
                                error = {
                                    message = "The model 'nonexistent-embedding-model' does not exist",
                                    type = "invalid_request_error"
                                }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "nonexistent-embedding-model",
                    input = "Test input"
                }

                local response, err = embed_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "NotFound")
                test.contains(tostring(err:message()), "does not exist")
            end)

            it("should handle authentication errors", function()
                embed_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                embed_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                embed_handler._client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 401,
                            body = json.encode({
                                error = {
                                    message = "Invalid API key provided",
                                    type = "invalid_request_error"
                                }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "text-embedding-3-small",
                    input = "Test input"
                }

                local response, err = embed_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "PermissionDenied")
                test.contains(tostring(err:message()), "Invalid API key")
            end)

            it("should handle rate limit errors", function()
                embed_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                embed_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                embed_handler._client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 429,
                            body = json.encode({
                                error = {
                                    message = "Rate limit exceeded for embeddings",
                                    type = "rate_limit_exceeded"
                                }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "text-embedding-3-small",
                    input = "Test input"
                }

                local response, err = embed_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "RateLimited")
                test.contains(tostring(err:message()), "Rate limit exceeded")
            end)

            it("should handle server errors", function()
                embed_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                embed_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                embed_handler._client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 500,
                            body = json.encode({
                                error = {
                                    message = "Internal server error",
                                    type = "server_error"
                                }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "text-embedding-3-small",
                    input = "Test input"
                }

                local response, err = embed_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Unavailable")
                test.contains(tostring(err:message()), "Internal server error")
            end)

            it("should handle empty response", function()
                embed_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                embed_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                embed_handler._client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = json.encode({}),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "text-embedding-3-small",
                    input = "Test input"
                }

                local response, err = embed_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Unavailable")
                test.contains(tostring(err:message()), "Invalid or empty response")
            end)

            it("should handle malformed response data", function()
                embed_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                embed_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                embed_handler._client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = json.encode({
                                data = {}
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "text-embedding-3-small",
                    input = "Test input"
                }

                local response, err = embed_handler.handler(contract_args)

                test.is_nil(response)
                test.not_nil(err)
                test.eq(err:kind(), "Unavailable")
                test.contains(tostring(err:message()), "Invalid or empty response")
            end)
        end)

        describe("Context Resolution", function()
            it("should resolve API key from context", function()
                embed_handler._client._ctx = {
                    all = function()
                        return { api_key = "context-api-key" }
                    end
                }

                embed_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                embed_handler._client._http_client = {
                    post = function(url, options)
                        test.eq(options.headers["Authorization"], "Bearer context-api-key")

                        return {
                            status_code = 200,
                            body = json.encode({
                                data = { { embedding = { 0.1, 0.2 }, index = 0 } },
                                usage = { prompt_tokens = 3, total_tokens = 3 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "text-embedding-3-small",
                    input = "Test input"
                }

                local response, err = embed_handler.handler(contract_args)

                test.is_true(response.success)
            end)

            it("should resolve API key from environment variable", function()
                embed_handler._client._ctx = {
                    all = function()
                        return { api_key_env = "CUSTOM_OPENAI_KEY" }
                    end
                }

                embed_handler._client._env = {
                    get = function(key)
                        if key == "CUSTOM_OPENAI_KEY" then return "env-api-key" end
                        return nil
                    end
                }

                embed_handler._client._http_client = {
                    post = function(url, options)
                        test.eq(options.headers["Authorization"], "Bearer env-api-key")

                        return {
                            status_code = 200,
                            body = json.encode({
                                data = { { embedding = { 0.1, 0.2 }, index = 0 } },
                                usage = { prompt_tokens = 3, total_tokens = 3 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "text-embedding-3-small",
                    input = "Test input"
                }

                local response, err = embed_handler.handler(contract_args)

                test.is_true(response.success)
            end)

            it("should use custom base URL from context", function()
                embed_handler._client._ctx = {
                    all = function()
                        return {
                            api_key = "test-key",
                            base_url = "https://custom.openai.proxy/v1"
                        }
                    end
                }

                embed_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                embed_handler._client._http_client = {
                    post = function(url, options)
                        test.contains(tostring(url), "https://custom.openai.proxy/v1/embeddings")

                        return {
                            status_code = 200,
                            body = json.encode({
                                data = { { embedding = { 0.1, 0.2 }, index = 0 } },
                                usage = { prompt_tokens = 3, total_tokens = 3 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "text-embedding-3-small",
                    input = "Test input"
                }

                local response, err = embed_handler.handler(contract_args)

                test.is_true(response.success)
            end)

            it("should use custom timeout from context", function()
                embed_handler._client._ctx = {
                    all = function()
                        return {
                            api_key = "test-key",
                            timeout = 30
                        }
                    end
                }

                embed_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                embed_handler._client._http_client = {
                    post = function(url, options)
                        test.eq(options.timeout, 60)

                        return {
                            status_code = 200,
                            body = json.encode({
                                data = { { embedding = { 0.1, 0.2 }, index = 0 } },
                                usage = { prompt_tokens = 3, total_tokens = 3 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "text-embedding-3-small",
                    input = "Test input",
                    timeout = 60
                }

                local response, err = embed_handler.handler(contract_args)

                test.is_true(response.success)
            end)
        end)

        describe("Response Format Compliance", function()
            it("should return consistent single embedding format", function()
                embed_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                embed_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                embed_handler._client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = json.encode({
                                data = {
                                    {
                                        embedding = { 0.1, 0.2, 0.3, 0.4, 0.5 },
                                        index = 0
                                    }
                                },
                                usage = { prompt_tokens = 4, total_tokens = 4 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "text-embedding-3-small",
                    input = "Single text input"
                }

                local response, err = embed_handler.handler(contract_args)

                test.is_true(response.success)
                test.eq(type(response.result.embeddings), "table")
                test.eq(#response.result.embeddings, 1)
                test.eq(type(response.result.embeddings[1]), "table")
                test.eq(#response.result.embeddings[1], 5)
                test.eq(response.result.embeddings[1][1], 0.1)
                test.eq(response.result.embeddings[1][5], 0.5)
            end)

            it("should return array of arrays for multiple embeddings", function()
                embed_handler._client._ctx = {
                    all = function()
                        return { api_key = "test-api-key" }
                    end
                }

                embed_handler._client._env = {
                    get = function(key)
                        return nil
                    end
                }

                embed_handler._client._http_client = {
                    post = function(url, options)
                        return {
                            status_code = 200,
                            body = json.encode({
                                data = {
                                    { embedding = { 0.1, 0.2, 0.3 }, index = 0 },
                                    { embedding = { 0.4, 0.5, 0.6 }, index = 1 }
                                },
                                usage = { prompt_tokens = 8, total_tokens = 8 }
                            }),
                            headers = {}
                        }
                    end
                }

                local contract_args = {
                    model = "text-embedding-3-small",
                    input = { "Text one", "Text two" }
                }

                local response, err = embed_handler.handler(contract_args)

                test.is_true(response.success)
                test.eq(type(response.result.embeddings), "table")
                test.eq(#response.result.embeddings, 2)
                test.eq(type(response.result.embeddings[1]), "table")
                test.eq(type(response.result.embeddings[2]), "table")
                test.eq(type(response.result.embeddings[1][1]), "number")
                test.eq(#response.result.embeddings[1], 3)
                test.eq(#response.result.embeddings[2], 3)
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
