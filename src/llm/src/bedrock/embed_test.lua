local embed_handler = require("embed_handler")
local json = require("json")

local function define_tests()
    describe("Bedrock Embed Handler", function()

        after_each(function()
            embed_handler._client = nil
        end)

        describe("Contract Validation", function()
            it("should require model parameter", function()
                local response = embed_handler.handler({ input = "test" })
                test.is_false(response.success)
                test.eq(response.error, "invalid_request")
                test.contains(response.error_message, "Model is required")
            end)

            it("should require input parameter", function()
                local response = embed_handler.handler({ model = "amazon.titan-embed-text-v2:0" })
                test.is_false(response.success)
                test.eq(response.error, "invalid_request")
                test.contains(response.error_message, "Input is required")
            end)

            it("should reject unsupported model family", function()
                local response = embed_handler.handler({
                    model = "unknown.model-v1",
                    input = "test"
                })
                test.is_false(response.success)
                test.eq(response.error, "model_error")
                test.contains(response.error_message, "Unsupported")
            end)
        end)

        describe("Titan Embed", function()
            it("should handle single text input", function()
                embed_handler._client = {
                    invoke = function(model_id, payload, options)
                        test.eq(model_id, "amazon.titan-embed-text-v2:0")
                        test.eq(payload.inputText, "Hello world")
                        return {
                            embedding = { 0.1, 0.2, 0.3 },
                            inputTextTokenCount = 3
                        }
                    end
                }

                local response = embed_handler.handler({
                    model = "amazon.titan-embed-text-v2:0",
                    input = "Hello world"
                })

                test.is_true(response.success)
                test.eq(#response.result.embeddings, 1)
                test.eq(#response.result.embeddings[1], 3)
                test.eq(response.result.embeddings[1][1], 0.1)
                test.eq(response.tokens.prompt_tokens, 3)
            end)

            it("should handle array input with multiple calls", function()
                local call_count = 0
                embed_handler._client = {
                    invoke = function(model_id, payload, options)
                        call_count = call_count + 1
                        return {
                            embedding = { 0.1 * call_count, 0.2 * call_count },
                            inputTextTokenCount = 2
                        }
                    end
                }

                local response = embed_handler.handler({
                    model = "amazon.titan-embed-text-v2:0",
                    input = { "First", "Second", "Third" }
                })

                test.is_true(response.success)
                test.eq(call_count, 3)
                test.eq(#response.result.embeddings, 3)
                test.eq(response.tokens.prompt_tokens, 6)
            end)

            it("should pass dimensions option", function()
                local captured_payload = nil
                embed_handler._client = {
                    invoke = function(model_id, payload, options)
                        captured_payload = payload
                        return { embedding = { 0.1 }, inputTextTokenCount = 1 }
                    end
                }

                embed_handler.handler({
                    model = "amazon.titan-embed-text-v2:0",
                    input = "test",
                    options = { dimensions = 256 }
                })

                test.eq((captured_payload :: any).dimensions, 256)
            end)

            it("should handle v1 model", function()
                embed_handler._client = {
                    invoke = function(model_id, payload, options)
                        test.eq(model_id, "amazon.titan-embed-text-v1")
                        return { embedding = { 0.1, 0.2 }, inputTextTokenCount = 2 }
                    end
                }

                local response = embed_handler.handler({
                    model = "amazon.titan-embed-text-v1",
                    input = "test"
                })

                test.is_true(response.success)
                test.eq(#response.result.embeddings, 1)
            end)
        end)

        describe("Cohere Embed", function()
            it("should handle single text input as batch of one", function()
                embed_handler._client = {
                    invoke = function(model_id, payload, options)
                        test.eq(model_id, "cohere.embed-v4:0")
                        test.eq(type(payload.texts), "table")
                        test.eq(#payload.texts, 1)
                        test.eq(payload.texts[1], "Hello world")
                        test.eq(payload.input_type, "search_document")
                        return {
                            embeddings = { { 0.1, 0.2, 0.3 } },
                            response_type = "embeddings_floats"
                        }
                    end
                }

                local response = embed_handler.handler({
                    model = "cohere.embed-v4:0",
                    input = "Hello world"
                })

                test.is_true(response.success)
                test.eq(#response.result.embeddings, 1)
                test.eq(#response.result.embeddings[1], 3)
            end)

            it("should handle batch input", function()
                embed_handler._client = {
                    invoke = function(model_id, payload, options)
                        test.eq(#payload.texts, 3)
                        return {
                            embeddings = { { 0.1 }, { 0.2 }, { 0.3 } },
                            response_type = "embeddings_floats"
                        }
                    end
                }

                local response = embed_handler.handler({
                    model = "cohere.embed-v4:0",
                    input = { "One", "Two", "Three" }
                })

                test.is_true(response.success)
                test.eq(#response.result.embeddings, 3)
            end)

            it("should pass dimensions as output_dimension", function()
                local captured_payload = nil
                embed_handler._client = {
                    invoke = function(model_id, payload, options)
                        captured_payload = payload
                        return { embeddings = { { 0.1 } }, response_type = "embeddings_floats" }
                    end
                }

                embed_handler.handler({
                    model = "cohere.embed-v4:0",
                    input = "test",
                    options = { dimensions = 512 }
                })

                test.eq((captured_payload :: any).output_dimension, 512)
            end)

            it("should handle embeddings_by_type response", function()
                embed_handler._client = {
                    invoke = function(model_id, payload, options)
                        return {
                            embeddings = {
                                float = { { 0.1, 0.2 }, { 0.3, 0.4 } }
                            },
                            response_type = "embeddings_by_type"
                        }
                    end
                }

                local response = embed_handler.handler({
                    model = "cohere.embed-v4:0",
                    input = { "one", "two" }
                })

                test.is_true(response.success)
                test.eq(#response.result.embeddings, 2)
            end)

            it("should allow custom input_type", function()
                local captured_payload = nil
                embed_handler._client = {
                    invoke = function(model_id, payload, options)
                        captured_payload = payload
                        return { embeddings = { { 0.1 } }, response_type = "embeddings_floats" }
                    end
                }

                embed_handler.handler({
                    model = "cohere.embed-v4:0",
                    input = "query text",
                    options = { input_type = "search_query" }
                })

                test.eq((captured_payload :: any).input_type, "search_query")
            end)

            it("should handle cohere v3 model", function()
                embed_handler._client = {
                    invoke = function(model_id, payload, options)
                        test.eq(model_id, "cohere.embed-english-v3")
                        return { embeddings = { { 0.1, 0.2 } }, response_type = "embeddings_floats" }
                    end
                }

                local response = embed_handler.handler({
                    model = "cohere.embed-english-v3",
                    input = "test"
                })

                test.is_true(response.success)
            end)
        end)

        describe("Error Handling", function()
            it("should handle API errors for Titan", function()
                embed_handler._client = {
                    invoke = function(model_id, payload, options)
                        return nil, { status_code = 404, message = "Model not found" }
                    end
                }

                local response = embed_handler.handler({
                    model = "amazon.titan-embed-text-v2:0",
                    input = "test"
                })

                test.is_false(response.success)
                test.eq(response.error, "model_error")
            end)

            it("should handle API errors for Cohere", function()
                embed_handler._client = {
                    invoke = function(model_id, payload, options)
                        return nil, { status_code = 429, message = "Rate limited" }
                    end
                }

                local response = embed_handler.handler({
                    model = "cohere.embed-v4:0",
                    input = "test"
                })

                test.is_false(response.success)
                test.eq(response.error, "rate_limit_exceeded")
            end)

            it("should handle auth errors", function()
                embed_handler._client = {
                    invoke = function(model_id, payload, options)
                        return nil, { status_code = 403, message = "Access denied" }
                    end
                }

                local response = embed_handler.handler({
                    model = "amazon.titan-embed-text-v2:0",
                    input = "test"
                })

                test.is_false(response.success)
                test.eq(response.error, "authentication_error")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
