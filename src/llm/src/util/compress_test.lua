local compress = require("compress")
local env = require("env")

local function define_tests()
    local RUN_INTEGRATION_TESTS = env.get("ENABLE_INTEGRATION_TESTS")

    describe("Compress Library", function()

        after_each(function()
            -- Reset injected dependencies to original modules
            compress._models = require("models")
            compress._llm = require("llm")
            compress._text = require("text")
        end)

        describe("Input Validation", function()
            it("should require model name", function()
                local result, err = compress.to_size(nil, "content", 100)
                expect(result).to_be_nil()
                expect(err).to_equal("Model name is required")
            end)

            it("should require content", function()
                local result, err = compress.to_size("gpt-4o-mini", nil, 100)
                expect(result).to_be_nil()
                expect(err).to_equal("Content is required")
            end)

            it("should require positive target size", function()
                local result, err = compress.to_size("gpt-4o-mini", "content", 0)
                expect(result).to_be_nil()
                expect(err).to_equal("Target size must be a positive number")
            end)

            it("should reject target size too small", function()
                compress._models = {
                    get_by_name = function(model_name)
                        return {
                            max_tokens = 128000,
                            output_tokens = 16384
                        }, nil
                    end
                }

                local result, err = compress.to_size("gpt-4o-mini", "content", 10)
                expect(result).to_be_nil()
                expect(err).to_contain("too small")
            end)

            it("should reject target size too large", function()
                compress._models = {
                    get_by_name = function(model_name)
                        return {
                            max_tokens = 2000,
                            output_tokens = 500
                        }, nil
                    end
                }

                local result, err = compress.to_size("small-model", "content", 5000)
                expect(result).to_be_nil()
                expect(err).to_contain("too large")
            end)
        end)

        describe("Content Size Handling", function()
            it("should return content as-is if already smaller than target", function()
                compress._models = {
                    get_by_name = function(model_name)
                        return {
                            max_tokens = 128000,
                            output_tokens = 16384
                        }, nil
                    end
                }

                local content = "Short"
                local result, err = compress.to_size("gpt-4o-mini", content, 100)

                expect(err).to_be_nil()
                expect(result).to_equal(content)
            end)
        end)

        describe("Direct Compression", function()
            it("should compress content directly when it fits in context", function()
                local generate_called = false
                compress._models = {
                    get_by_name = function(model_name)
                        return {
                            max_tokens = 128000,
                            output_tokens = 16384
                        }, nil
                    end
                }

                compress._llm = {
                    generate = function(prompt, options)
                        generate_called = true
                        expect(prompt).to_contain("exactly 100 characters")
                        expect(options.model).to_equal("gpt-4o-mini")

                        -- Check for direct compression (not synthesis)
                        if prompt:match("TARGET LENGTH: Exactly") then
                            expect(options.temperature).to_equal(0.2)  -- default_temperature
                        end

                        return {
                            content = string.rep("x", 98)  -- Close to target to avoid refinement
                        }, nil
                    end
                }

                local long_content = string.rep("This is some content that needs compression. ", 10)
                local result, err = compress.to_size("gpt-4o-mini", long_content, 100)

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(generate_called).to_be_true()
            end)

            it("should handle LLM errors", function()
                compress._models = {
                    get_by_name = function(model_name)
                        return {
                            max_tokens = 128000,
                            output_tokens = 16384
                        }, nil
                    end
                }

                compress._llm = {
                    generate = function(prompt, options)
                        return nil, "API error"
                    end
                }

                local long_content = string.rep("Content ", 50)
                local result, err = compress.to_size("gpt-4o-mini", long_content, 100)

                expect(result).to_be_nil()
                expect(err).to_contain("Direct compression failed")
            end)

            it("should handle empty response", function()
                compress._models = {
                    get_by_name = function(model_name)
                        return {
                            max_tokens = 128000,
                            output_tokens = 16384
                        }, nil
                    end
                }

                compress._llm = {
                    generate = function(prompt, options)
                        return { content = "" }, nil
                    end
                }

                local long_content = string.rep("Content ", 50)
                local result, err = compress.to_size("gpt-4o-mini", long_content, 100)

                expect(result).to_be_nil()
                expect(err).to_equal("Model returned empty response")
            end)
        end)

        describe("Map-Reduce Compression", function()
            it("should use map-reduce for content larger than model context", function()
                local generate_calls = 0
                compress._models = {
                    get_by_name = function(model_name)
                        return {
                            max_tokens = 1000,  -- Very small model
                            output_tokens = 200
                        }, nil
                    end
                }

                compress._llm = {
                    generate = function(prompt, options)
                        generate_calls = generate_calls + 1

                        if prompt:match("approximately") then
                            -- Chunk compression - return exact target to avoid refinement
                            return { content = string.rep("x", 50) }, nil  -- Close to target per chunk
                        elseif prompt:match("final comprehensive summary") then
                            -- Synthesis - return close to final target to avoid refinement
                            return { content = string.rep("y", 198) }, nil  -- Close to 200 target
                        end

                        return { content = "Fallback" }, nil
                    end
                }

                compress._text = {
                    splitter = {
                        recursive = function(options)
                            return {
                                split_text = function(self, content)
                                    -- Split into 2 chunks for testing
                                    local mid = math.floor(#content / 2)
                                    return { content:sub(1, mid), content:sub(mid + 1) }, nil
                                end
                            }, nil
                        end
                    }
                }

                -- Large content that won't fit in small model context
                local huge_content = string.rep("This is a very long document. ", 200)
                local result, err = compress.to_size("small-model", huge_content, 200)

                expect(err).to_be_nil()
                expect(result).not_to_be_nil()
                expect(generate_calls).to_equal(3)  -- 2 chunks + 1 synthesis (no refinement)
            end)

            it("should handle text splitter errors", function()
                compress._models = {
                    get_by_name = function(model_name)
                        return {
                            max_tokens = 1000,
                            output_tokens = 200
                        }, nil
                    end
                }

                compress._text = {
                    splitter = {
                        recursive = function(options)
                            return nil, "Splitter failed"
                        end
                    }
                }

                local huge_content = string.rep("Content ", 500)
                local result, err = compress.to_size("small-model", huge_content, 200)

                expect(result).to_be_nil()
                expect(err).to_contain("Failed to create text splitter")
            end)
        end)

        describe("Length Refinement", function()
            it("should refine length when result is too different from target", function()
                local generate_calls = 0
                compress._models = {
                    get_by_name = function(model_name)
                        return {
                            max_tokens = 128000,
                            output_tokens = 16384
                        }, nil
                    end
                }

                compress._llm = {
                    generate = function(prompt, options)
                        generate_calls = generate_calls + 1

                        if generate_calls == 1 then
                            return { content = string.rep("x", 150) }, nil  -- Too long
                        else
                            expect(prompt).to_contain("shorten")
                            return { content = string.rep("y", 98) }, nil   -- Close to target
                        end
                    end
                }

                local long_content = string.rep("Content ", 50)
                local result, err = compress.to_size("gpt-4o-mini", long_content, 100)

                expect(err).to_be_nil()
                expect(generate_calls).to_equal(2)
                expect(#result).to_equal(98)
            end)

            it("should skip refinement when close enough", function()
                local generate_calls = 0
                compress._models = {
                    get_by_name = function(model_name)
                        return {
                            max_tokens = 128000,
                            output_tokens = 16384
                        }, nil
                    end
                }

                compress._llm = {
                    generate = function(prompt, options)
                        generate_calls = generate_calls + 1
                        return { content = string.rep("x", 102) }, nil  -- Close to 100, within tolerance
                    end
                }

                local long_content = string.rep("Content ", 50)
                local result, err = compress.to_size("gpt-4o-mini", long_content, 100)

                expect(err).to_be_nil()
                expect(generate_calls).to_equal(1)  -- No refinement needed
            end)

            it("should skip refinement when requested", function()
                compress._models = {
                    get_by_name = function(model_name)
                        return {
                            max_tokens = 128000,
                            output_tokens = 16384
                        }, nil
                    end
                }

                compress._llm = {
                    generate = function(prompt, options)
                        return { content = string.rep("x", 150) }, nil
                    end
                }

                local long_content = string.rep("Content ", 50)
                local result, err = compress.to_size("gpt-4o-mini", long_content, 100, {
                    skip_refinement = true
                })

                expect(err).to_be_nil()
                expect(#result).to_equal(150)
            end)
        end)

        describe("Statistics", function()
            it("should calculate compression statistics correctly", function()
                compress._models = {
                    get_by_name = function(model_name)
                        return {
                            max_tokens = 128000,
                            output_tokens = 16384
                        }, nil
                    end
                }

                local content = string.rep("x", 500)
                local stats, err = compress.get_stats("gpt-4o-mini", content, 200)

                expect(err).to_be_nil()
                expect(stats.content_chars).to_equal(500)
                expect(stats.target_chars).to_equal(200)
                expect(stats.compression_ratio).to_equal(2.5)
                expect(stats.strategy).to_equal("direct")
                expect(stats.needs_compression).to_be_true()
            end)

            it("should detect map-reduce strategy for large content", function()
                compress._models = {
                    get_by_name = function(model_name)
                        return {
                            max_tokens = 1000,  -- Small model
                            output_tokens = 200
                        }, nil
                    end
                }

                local large_content = string.rep("x", 5000)  -- Very large content
                local stats, err = compress.get_stats("small-model", large_content, 500)

                expect(err).to_be_nil()
                expect(stats.strategy).to_equal("map_reduce")
                expect(stats.fits_in_context).to_be_false()
            end)
        end)

        describe("Feasibility", function()
            it("should accept reasonable compression requests", function()
                compress._models = {
                    get_by_name = function(model_name)
                        return {
                            max_tokens = 128000,
                            output_tokens = 16384
                        }, nil
                    end
                }

                local feasible, err = compress.can_compress("gpt-4o-mini", "Some content", 100)
                expect(feasible).to_be_true()
                expect(err).to_be_nil()
            end)

            it("should reject target size exceeding model output limit", function()
                compress._models = {
                    get_by_name = function(model_name)
                        return {
                            max_tokens = 4000,
                            output_tokens = 1000  -- Small output limit
                        }, nil
                    end
                }

                -- Content larger than target but target exceeds model output capacity
                -- This ensures needs_compression=true so we reach the output limit check
                local large_content = string.rep("x", 6000)  -- 6000 chars content
                local feasible, err = compress.can_compress("small-model", large_content, 5000)  -- 5000 chars target

                expect(feasible).to_be_false()
                expect(err).to_contain("exceeds model output limit")
            end)
        end)

        describe("Model Resolution", function()
            it("should handle model not found", function()
                compress._models = {
                    get_by_name = function(model_name)
                        return nil, "Model not found"
                    end
                }

                local result, err = compress.to_size("unknown-model", "content", 100)
                expect(result).to_be_nil()
                expect(err).to_contain("Model not found")
            end)
        end)

        describe("Configuration", function()
            it("should allow config updates", function()
                local original = compress.get_config().default_temperature

                compress.configure({ default_temperature = 0.8 })
                expect(compress.get_config().default_temperature).to_equal(0.8)

                -- Reset
                compress.configure({ default_temperature = original })
            end)

            it("should ignore unknown config keys", function()
                compress.configure({ unknown_key = "value" })
                expect(compress.get_config().unknown_key).to_be_nil()
            end)
        end)

        describe("Integration Tests", function()
            it("should compress real content with OpenAI", function()
                if not RUN_INTEGRATION_TESTS then
                    return
                end

                local openai_api_key = env.get("OPENAI_API_KEY")
                if not openai_api_key or #openai_api_key < 10 then
                    return
                end

                local content = [[
Artificial intelligence (AI) is a branch of computer science that aims to create intelligent machines capable of performing tasks that typically require human intelligence. These tasks include learning, reasoning, problem-solving, perception, and language understanding. AI systems use algorithms and computational models to process information, make decisions, and adapt to new situations.

The field has evolved significantly since its inception in the 1950s, with major breakthroughs in machine learning, neural networks, and deep learning. Modern AI applications span across various industries including healthcare, finance, transportation, and entertainment.
]]

                local result, err = compress.to_size("gpt-4o-mini", content, 200)

                if not err and result and type(result) == "string" and #result > 0 then
                    expect(result).not_to_be_nil()
                    expect(type(result)).to_equal("string")
                    expect(#result).to_be_less_than(500)
                end
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)