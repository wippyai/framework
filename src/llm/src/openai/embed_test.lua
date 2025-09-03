local embed_handler = require("embed_handler")
local json = require("json")

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

                local response = embed_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_contain("Model is required")
            end)

            it("should require input parameter", function()
                local contract_args = {
                    model = "text-embedding-3-small"
                }

                local response = embed_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("invalid_request")
                expect(response.error_message).to_contain("Input is required")
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
                        local payload = json.decode(options.body)
                        expect(payload.input).to_equal("Test input string")
                        expect(type(payload.input)).to_equal("string")

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

                local response = embed_handler.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.result.embeddings).not_to_be_nil()
                expect(type(response.result.embeddings)).to_equal("table")
                expect(#response.result.embeddings).to_equal(1)
                expect(type(response.result.embeddings[1])).to_equal("table")
                expect(#response.result.embeddings[1]).to_equal(3)
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
                        local payload = json.decode(options.body)
                        expect(type(payload.input)).to_equal("table")
                        expect(#payload.input).to_equal(2)
                        expect(payload.input[1]).to_equal("First text")
                        expect(payload.input[2]).to_equal("Second text")

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

                local response = embed_handler.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.result.embeddings).not_to_be_nil()
                expect(type(response.result.embeddings)).to_equal("table")
                expect(#response.result.embeddings).to_equal(2)
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
                        expect(url).to_contain("/embeddings")

                        local payload = json.decode(options.body)
                        expect(payload.model).to_equal("text-embedding-3-small")
                        expect(payload.input).to_equal("Test embedding input")
                        expect(payload.encoding_format).to_equal("float")

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

                local response = embed_handler.handler(contract_args)

                expect(response.success).to_be_true()
                expect(response.result).not_to_be_nil()
                expect(response.result.embeddings).not_to_be_nil()
                expect(type(response.result.embeddings)).to_equal("table")
                expect(#response.result.embeddings).to_equal(1)
                expect(type(response.result.embeddings[1])).to_equal("table")
                expect(#response.result.embeddings[1]).to_equal(3)
                expect(response.result.embeddings[1][1]).to_equal(0.123)
                expect(response.result.embeddings[1][2]).to_equal(-0.456)
                expect(response.result.embeddings[1][3]).to_equal(0.789)
                expect(response.tokens.prompt_tokens).to_equal(5)
                expect(response.tokens.total_tokens).to_equal(5)
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
                        local payload = json.decode(options.body)
                        expect(payload.dimensions).to_equal(512)

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

                local response = embed_handler.handler(contract_args)

                expect(response.success).to_be_true()
                expect(#response.result.embeddings[1]).to_equal(2)
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
                        local payload = json.decode(options.body)
                        expect(payload.user).to_equal("test-user-id")

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

                local response = embed_handler.handler(contract_args)

                expect(response.success).to_be_true()
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
                        local payload = json.decode(options.body)
                        expect(type(payload.input)).to_equal("table")
                        expect(#payload.input).to_equal(3)

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

                local response = embed_handler.handler(contract_args)

                expect(response.success).to_be_true()
                expect(type(response.result.embeddings)).to_equal("table")
                expect(#response.result.embeddings).to_equal(3)
                expect(type(response.result.embeddings[1])).to_equal("table")
                expect(type(response.result.embeddings[2])).to_equal("table")
                expect(type(response.result.embeddings[3])).to_equal("table")

                -- Check individual embeddings
                expect(response.result.embeddings[1][1]).to_equal(0.111)
                expect(response.result.embeddings[1][2]).to_equal(-0.222)
                expect(response.result.embeddings[2][1]).to_equal(0.333)
                expect(response.result.embeddings[2][2]).to_equal(-0.444)
                expect(response.result.embeddings[3][1]).to_equal(0.555)
                expect(response.result.embeddings[3][2]).to_equal(-0.666)

                expect(response.tokens.prompt_tokens).to_equal(12)
                expect(response.tokens.total_tokens).to_equal(12)
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

                local response = embed_handler.handler(contract_args)

                expect(response.success).to_be_true()
                expect(#response.result.embeddings).to_equal(2)
                expect(#response.result.embeddings[1]).to_equal(4)
                expect(#response.result.embeddings[2]).to_equal(4)
                expect(#response.result.embeddings[1]).to_equal(#response.result.embeddings[2])
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

                local response = embed_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("model_error")
                expect(response.error_message).to_contain("does not exist")
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

                local response = embed_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("authentication_error")
                expect(response.error_message).to_contain("Invalid API key")
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

                local response = embed_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("rate_limit_exceeded")
                expect(response.error_message).to_contain("Rate limit exceeded")
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

                local response = embed_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("server_error")
                expect(response.error_message).to_contain("Internal server error")
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

                local response = embed_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("server_error")
                expect(response.error_message).to_contain("Invalid or empty response")
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

                local response = embed_handler.handler(contract_args)

                expect(response.success).to_be_false()
                expect(response.error).to_equal("server_error")
                expect(response.error_message).to_contain("Invalid or empty response")
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
                        expect(options.headers["Authorization"]).to_equal("Bearer context-api-key")

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

                local response = embed_handler.handler(contract_args)

                expect(response.success).to_be_true()
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
                        expect(options.headers["Authorization"]).to_equal("Bearer env-api-key")

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

                local response = embed_handler.handler(contract_args)

                expect(response.success).to_be_true()
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
                        expect(url).to_contain("https://custom.openai.proxy/v1/embeddings")

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

                local response = embed_handler.handler(contract_args)

                expect(response.success).to_be_true()
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
                        expect(options.timeout).to_equal(60)

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

                local response = embed_handler.handler(contract_args)

                expect(response.success).to_be_true()
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

                local response = embed_handler.handler(contract_args)

                expect(response.success).to_be_true()
                expect(type(response.result.embeddings)).to_equal("table")
                expect(#response.result.embeddings).to_equal(1)
                expect(type(response.result.embeddings[1])).to_equal("table")
                expect(#response.result.embeddings[1]).to_equal(5)
                expect(response.result.embeddings[1][1]).to_equal(0.1)
                expect(response.result.embeddings[1][5]).to_equal(0.5)
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

                local response = embed_handler.handler(contract_args)

                expect(response.success).to_be_true()
                expect(type(response.result.embeddings)).to_equal("table")
                expect(#response.result.embeddings).to_equal(2)
                expect(type(response.result.embeddings[1])).to_equal("table")
                expect(type(response.result.embeddings[2])).to_equal("table")
                expect(type(response.result.embeddings[1][1])).to_equal("number")
                expect(#response.result.embeddings[1]).to_equal(3)
                expect(#response.result.embeddings[2]).to_equal(3)
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)