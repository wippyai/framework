local test = require("test")
local providers = require("providers")
local store = require("store")

local function define_tests()
    describe("Provider Retry Delivery", function()
        local s

        local function generate(instance)
            return (instance :: any):generate({
                messages = {{ role = "user", content = {{ type = "text", text = "hello" }} }},
                model = "test-model",
            })
        end

        before_each(function()
            s = store.get("app:test_store")
            s:set("flaky_generate_count", 0)
            s:set("flaky_generate_retry", false)
            s:set("permanent_fail_count", 0)
        end)

        describe("retry options", function()
            it("delivers retry to the driver through its context", function()
                local instance, err = providers.open("app:flaky_provider", {
                    retry = { attempts = 3, backoff_ms = 0 }
                })
                test.is_nil(err)
                test.not_nil(instance)

                local _, gen_err = generate(instance)

                test.not_nil(gen_err)
                local retry = s:get("flaky_generate_retry")
                test.eq(retry.attempts, 3)
                test.eq(retry.backoff_ms, 0)
            end)

            it("invokes the driver once per call on retryable errors", function()
                local instance, err = providers.open("app:flaky_provider", {
                    retry = { attempts = 3, backoff_ms = 0 }
                })
                test.is_nil(err)
                test.not_nil(instance)

                local _, first_err = generate(instance)
                test.not_nil(first_err)
                test.eq(first_err:kind(), "Unavailable")
                test.eq(first_err:retryable(), true)
                test.eq(s:get("flaky_generate_count"), 1)

                local _, second_err = generate(instance)
                test.not_nil(second_err)
                test.eq(s:get("flaky_generate_count"), 2)

                local result, third_err = generate(instance)
                test.is_nil(third_err)
                test.is_true(result.success)
                test.contains(result.result.content, "after 3 attempts")
                test.eq(s:get("flaky_generate_count"), 3)
            end)
        end)

        describe("without retry options", function()
            it("opens the driver without retry and fails on the first attempt", function()
                local instance, err = providers.open("app:flaky_provider")
                test.is_nil(err)
                test.not_nil(instance)

                local _, gen_err = generate(instance)

                test.not_nil(gen_err)
                test.eq(gen_err:kind(), "Unavailable")
                test.eq(gen_err:retryable(), true)
                test.eq(s:get("flaky_generate_count"), 1)
                test.eq(s:get("flaky_generate_retry"), false)
            end)
        end)

        describe("non-retryable errors", function()
            it("returns authentication errors from a single driver call", function()
                local instance, err = providers.open("app:permanent_fail_provider", {
                    retry = { attempts = 5, backoff_ms = 0 }
                })
                test.is_nil(err)
                test.not_nil(instance)

                local _, gen_err = generate(instance)

                test.not_nil(gen_err)
                test.eq(gen_err:kind(), "PermissionDenied")
                test.eq(gen_err:retryable(), false)
                test.eq(s:get("permanent_fail_count"), 1)
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
