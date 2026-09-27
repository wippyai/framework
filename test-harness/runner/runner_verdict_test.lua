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

        test.it("fails when all cases ran but completion is missing", function()
            local err = verdict.check({ declared = 2, observed = 2, completed = nil })
            test.not_nil(err)
            test.eq(err.kind, "runner_failure")
            test.eq(err.message, "test process did not report completion")
        end)

        test.it("accepts all declared cases with a successful completion", function()
            local err = verdict.check({ declared = 2, observed = 2,
                completed = { total = 2, passed = 2, failed = 0, skipped = 0 } })
            test.is_nil(err)
        end)

        test.it("fails when test execution timed out", function()
            local err = verdict.check({ entry_id = "app:test1", timed_out = true })
            test.not_nil(err)
            test.eq(err.kind, "runner_failure")
            test.eq(err.message, "test timed out")
        end)

        test.it("keeps timeout attribution when cancellation has a result error", function()
            local err = verdict.check({ entry_id = "app:test1", timed_out = true,
                result_error = "context canceled" })
            test.not_nil(err)
            test.eq(err.kind, "runner_failure")
            test.eq(err.message, "test timed out")
        end)

        test.it("reports failed termination as a typed runner failure", function()
            local err = verdict.check({ entry_id = "app:test1", timed_out = true,
                lifecycle_error = "test process termination failed: denied" })
            test.not_nil(err)
            test.eq(err.kind, "runner_failure")
            test.eq(err.message, "test process termination failed: denied")
        end)

        test.it("rejects an unplanned completion from another entry", function()
            local err = verdict.check({ entry_id = "app:next", observed = 0,
                completed = { ref_id = "app:old" } })
            test.not_nil(err)
            test.eq(err.kind, "runner_failure")
            test.eq(err.message, "test completion attributed to app:old, expected app:next")
        end)

        test.it("rejects a completion without an entry identity", function()
            local err = verdict.check({ entry_id = "app:next", observed = 0,
                completed = { total = 0 } })
            test.not_nil(err)
            test.eq(err.kind, "runner_failure")
            test.eq(err.message, "test completion attributed to <missing>, expected app:next")
        end)

        test.it("reports attribution before a count mismatch", function()
            local err = verdict.check({ entry_id = "app:next", declared = 2, observed = 1,
                completed = { ref_id = "app:old" } })
            test.not_nil(err)
            test.eq(err.kind, "runner_failure")
            test.eq(err.message, "test completion attributed to app:old, expected app:next")
        end)

        test.it("rejects completion attributed to a different entry", function()
            local err = verdict.check({
                entry_id = "app:entry2",
                declared = 2,
                observed = 2,
                completed = { ref_id = "app:entry1", total = 2, passed = 2, failed = 0, skipped = 0 },
            })
            test.not_nil(err)
            test.eq(err.kind, "runner_failure")
            test.is_true(string.find(err.message, "app:entry1", 1, true) ~= nil)
        end)

        test.it("rejects late events when entry is no longer running", function()
            test.is_false(verdict.is_event_applicable("app:entry1", "app:entry2", "running"))
            test.is_false(verdict.is_event_applicable("app:entry1", "app:entry1", "timed_out"))
            test.is_false(verdict.is_event_applicable("app:entry1", "app:entry1", "completed"))
            test.is_false(verdict.is_event_applicable("", "app:entry1", "running"))
            test.is_true(verdict.is_event_applicable("app:entry2", "app:entry2", "running"))
        end)

    end)
end

return { run = test.run_cases(define_tests) }
