local contract = require("contract")
local env = require("env")
local test = require("test")

local function define_tests()
    describe("OpenAI Decisions Contract Integration", function()
        it("binds evaluation on native OpenAI and rejects unsupported options before HTTP", function()
            local evaluator, get_err = contract.get("wippy.llm:evaluator")
            test.is_nil(get_err)
            assert(evaluator)
            local driver, open_err = evaluator:with_context({ api_key = "test-key" }):open("wippy.llm.openai:driver")
            test.is_nil(open_err)
            assert(driver)
            local response, err = driver:evaluate({ model = "gpt-6-luna", state = "text",
                questions = { truth = { type = "predicate", instructions = "True?" } }, options = { temperature = 0.5 } })
            test.is_nil(response)
            test.not_nil(err)
            test.contains(err:message(), "temperature")
            local compat, compat_err = evaluator:open("wippy.llm.openai_compat:driver")
            test.is_nil(compat_err)
            assert(compat)
            -- Opening a binding is lazy. Methods come from the contracts the
            -- binding actually implements, so unsupported evaluation is absent.
            test.is_nil(compat.evaluate)
        end)

        it("evaluates predicates, choices and scores through the native OpenAI binding", function()
            -- This dedicated opt-in does not follow ENABLE_INTEGRATION_TESTS:
            -- adding Decisions must not cause existing live suites to spend more.
            if env.get("ENABLE_DECISIONS_INTEGRATION_TESTS") ~= "true" then
                print("Skipping live Decisions test - set ENABLE_DECISIONS_INTEGRATION_TESTS=true to enable")
                return
            end
            local key = env.get("OPENAI_API_KEY")
            test.not_nil(key, "OPENAI_API_KEY is required for the opted-in Decisions test")
            local evaluator, get_err = contract.get("wippy.llm:evaluator")
            test.is_nil(get_err)
            assert(evaluator)
            local driver, open_err = evaluator:with_context({ api_key = key }):open("wippy.llm.openai:driver")
            test.is_nil(open_err)
            assert(driver)
            local response, err = driver:evaluate({
                model = "gpt-6-luna",
                state = "The delivered phone has a broken screen and cannot be used.",
                questions = {
                    damaged = { type = "predicate", instructions = "Does the customer report physical damage?" },
                    department = { type = "choice", instructions = "Which department should handle this complaint?",
                        domain = { billing = "payment errors", support = "damaged or broken products" } },
                    severity = { type = "score", instructions = "Rate the problem's severity.",
                        domain = { "cosmetic only", "usable with a workaround", "unusable" } }
                }
            })
            test.is_nil(err)
            assert(response)
            test.is_true(response.success)
            test.eq(response.result.readings.damaged.type, "predicate")
            test.is_true(response.result.readings.damaged.probability >= 0 and response.result.readings.damaged.probability <= 1)
            test.eq(response.result.readings.department.type, "choice")
            test.not_nil(response.result.readings.department.probabilities.billing)
            test.not_nil(response.result.readings.department.probabilities.support)
            test.eq(response.result.readings.severity.type, "score")
            test.is_true(response.result.readings.severity.score >= 1 and response.result.readings.severity.score <= 3)
            test.eq(#response.result.readings.severity.probabilities, 3)
            test.is_true(response.metadata.usage.input_tokens > 0)
            test.eq(response.tokens.prompt_tokens + (response.tokens.cache_read_tokens or 0) + (response.tokens.cache_write_tokens or 0),
                response.metadata.usage.input_tokens)
            test.eq(response.tokens.completion_tokens, 0)
            test.eq(response.tokens.total_tokens, response.metadata.usage.input_tokens + response.metadata.usage.output_tokens)
            test.not_nil(response.metadata.model)
        end)
    end)
end

return require("test").run_cases(define_tests)
