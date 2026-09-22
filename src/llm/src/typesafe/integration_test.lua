local contract = require("contract")
local env = require("env")
local test = require("test")

local DRIVER_ID = "wippy.llm.typesafe:driver"

local function define_tests()
    -- Toggle to enable/disable real API integration tests
    -- A provider-specific opt-in exercises Jev without enabling unrelated
    -- integration suites that require other vendors' credentials.
    local RUN_INTEGRATION_TESTS = env.get("ENABLE_INTEGRATION_TESTS") or env.get("TYPESAFE_INTEGRATION_TESTS")

    describe("TypeSafe Integration Tests", function()
        local actual_api_key = nil

        before_all(function()
            actual_api_key = env.get("TYPESAFE_API_KEY")

            if not RUN_INTEGRATION_TESTS then
                print("Integration tests disabled - set TYPESAFE_INTEGRATION_TESTS=true to enable")
                return
            end

            if actual_api_key and #actual_api_key > 10 then
                print("Integration tests will run with real API key")
            else
                print("Integration tests disabled - TYPESAFE_API_KEY is not set")
                RUN_INTEGRATION_TESTS = false
            end
        end)

        local function open_driver(contract_id: string): any
            local driver_contract, contract_err = contract.get(contract_id)
            test.is_nil(contract_err)
            assert(driver_contract)

            local instance, open_err = driver_contract
                :with_context({ api_key = actual_api_key })
                :open(DRIVER_ID)
            test.is_nil(open_err)
            assert(instance)

            return instance
        end

        local function sum_of(values: any): number
            local total: number = 0
            for _, value in pairs(values) do
                total = total + (value :: number)
            end
            return total
        end

        describe("Evaluation Contract Integration", function()
            it("should read every declared slot of a support ticket", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping integration test - not enabled")
                    return
                end

                local driver = open_driver("wippy.llm:evaluator")

                local response, err = driver:evaluate({
                    model = "jev-latest",
                    state = {
                        ticket = "My card was charged twice this month and nobody answers. I am furious.",
                        channel = "email"
                    },
                    questions = {
                        topic = {
                            type = "choice",
                            instructions = "Which department should own this ticket?",
                            domain = {
                                billing = "payments, charges and refunds",
                                technical = "product defects and outages",
                                sales = "pricing and upgrades"
                            }
                        },
                        escalate = {
                            type = "predicate",
                            instructions = "Should this ticket be escalated to a human supervisor?",
                            domain = { yes = "escalate now", no = "routine handling" }
                        },
                        anger = {
                            type = "score",
                            instructions = "How angry is the customer?",
                            domain = { "Calm", "Frustrated", "Very angry" }
                        }
                    }
                })

                test.is_nil(err, "Evaluation request failed: " .. tostring(err))
                assert(response)
                test.is_true(response.success)

                local readings = response.result.readings

                test.eq(readings.topic.type, "choice")
                test.eq(type(readings.topic.choice), "string")
                test.not_nil(readings.topic.probabilities[readings.topic.choice])
                test.not_nil(readings.topic.probabilities.billing)
                test.not_nil(readings.topic.probabilities.technical)
                test.not_nil(readings.topic.probabilities.sales)
                test.is_true(math.abs(sum_of(readings.topic.probabilities) - 1) < 0.002,
                    "Choice probabilities do not sum to 1")

                test.eq(readings.escalate.type, "predicate")
                test.eq(type(readings.escalate.probability), "number")
                test.is_true(readings.escalate.probability >= 0 and readings.escalate.probability <= 1,
                    "Predicate probability is outside the unit interval")

                test.eq(readings.anger.type, "score")
                test.eq(#readings.anger.probabilities, 3)
                test.is_true(readings.anger.level >= 1 and readings.anger.level <= 3,
                    "Score level is outside the declared domain")
                test.is_true(readings.anger.score >= 1 and readings.anger.score <= 3,
                    "Score is outside the declared domain")
                test.is_true(math.abs(sum_of(readings.anger.probabilities) - 1) < 0.002,
                    "Score probabilities do not sum to 1")

                test.is_true(response.tokens.prompt_tokens > 0, "No prompt tokens reported")
                test.is_true(response.tokens.completion_tokens > 0, "No completion tokens reported")
                test.eq(response.tokens.total_tokens,
                    response.tokens.prompt_tokens + response.tokens.completion_tokens)

                test.eq(tostring(response.metadata.model):sub(1, 4), "jev-")
                test.eq(type(response.metadata.request_id), "string")
            end)
        end)

        describe("Provider Contract Integration", function()
            it("should report the TypeSafe API healthy", function()
                if not RUN_INTEGRATION_TESTS then
                    print("Skipping integration test - not enabled")
                    return
                end

                local driver = open_driver("wippy.llm:provider")

                local response, err = driver:status()

                test.is_nil(err)
                assert(response)
                test.is_true(response.success)
                test.eq(response.status, "healthy")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
