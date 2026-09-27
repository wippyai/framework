local test = require("test")
local verdict = require("verdict")

local function define_tests()
    test.describe("runner result validation", function()
        test.it("fails a hook error after a case passed", function()
            local err = verdict.check({ declared = 2, observed = 1,
                completed = nil, result_error = "after_all failed" })
            test.not_nil(err)
            test.eq(err.kind, "runner_failure")
            test.is_true(string.find(err.message, "after_all failed", 1, true) ~= nil)
        end)

        test.it("fails a declared case missing after a partial run", function()
            local err = verdict.check({ declared = 2, observed = 1,
                completed = { total = 2, passed = 1, failed = 0, skipped = 0 } })
            test.not_nil(err)
            test.eq(err.kind, "runner_failure")
            test.is_true(string.find(err.message, "2 declared", 1, true) ~= nil)
        end)

        test.it("accepts all declared cases with a successful completion", function()
            local err = verdict.check({ declared = 2, observed = 2,
                completed = { total = 2, passed = 2, failed = 0, skipped = 0 } })
            test.is_nil(err)
        end)
    end)
end

return { run = test.run_cases(define_tests) }
