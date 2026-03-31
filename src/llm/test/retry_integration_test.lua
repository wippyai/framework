local test = require("test")
local providers = require("providers")
local store = require("store")

local function define_tests()
    describe("Provider Retry Integration", function()
        local s

        before_each(function()
            s = store.get("app:test_store")
            s:set("flaky_generate_count", 0)
            s:set("permanent_fail_count", 0)
        end)

        describe("retryable errors with retry options", function()
            it("retries and succeeds after transient failures", function()
                local instance, err = providers.open("app:flaky_provider", {
                    retry = { max_attempts = 5, initial_delay = 1 }
                })
                test.is_nil(err)
                test.not_nil(instance)

                local result, gen_err = (instance :: any):generate({
                    messages = {{ role = "user", content = {{ type = "text", text = "hello" }} }},
                    model = "test-model",
                })

                test.is_nil(gen_err)
                test.not_nil(result)
                test.is_true(result.success)
                test.contains(result.result.content, "after 3 attempts")
                test.eq(s:get("flaky_generate_count"), 3)
            end)
        end)

        describe("retryable errors without retry options", function()
            it("fails on first attempt", function()
                local instance, err = providers.open("app:flaky_provider")
                test.is_nil(err)
                test.not_nil(instance)

                local _, gen_err = (instance :: any):generate({
                    messages = {{ role = "user", content = {{ type = "text", text = "hello" }} }},
                    model = "test-model",
                })

                test.not_nil(gen_err)
                test.eq(gen_err:kind(), "Unavailable")
                test.eq(gen_err:retryable(), true)
                test.eq(s:get("flaky_generate_count"), 1)
            end)
        end)

        describe("retry exhaustion", function()
            it("gives up after max_attempts", function()
                local instance, err = providers.open("app:flaky_provider", {
                    retry = { max_attempts = 2, initial_delay = 1 }
                })
                test.is_nil(err)
                test.not_nil(instance)

                local _, gen_err = (instance :: any):generate({
                    messages = {{ role = "user", content = {{ type = "text", text = "hello" }} }},
                    model = "test-model",
                })

                test.not_nil(gen_err)
                test.eq(gen_err:retryable(), true)
                test.eq(s:get("flaky_generate_count"), 2)
            end)
        end)

        describe("non-retryable errors", function()
            it("does not retry authentication errors even with retry options", function()
                local instance, err = providers.open("app:permanent_fail_provider", {
                    retry = { max_attempts = 5, initial_delay = 1 }
                })
                test.is_nil(err)
                test.not_nil(instance)

                local _, gen_err = (instance :: any):generate({
                    messages = {{ role = "user", content = {{ type = "text", text = "hello" }} }},
                    model = "test-model",
                })

                test.not_nil(gen_err)
                test.eq(gen_err:kind(), "PermissionDenied")
                test.eq(gen_err:retryable(), false)
                test.eq(s:get("permanent_fail_count"), 1)
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
