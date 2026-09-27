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

        test.it("an entry that outlives its timeout and then emits events must not affect the next entry verdict and the timed-out process is gone", function()
            local time = require("time")
            -- Spawn slow_worker process representing a test entry that will exceed timeout
            local pid = process.spawn("app:slow_worker", "app:processes", {
                pid = process.pid(),
                topic = "test:update",
                ref_id = "app:slow_entry",
            })
            test.not_nil(pid)
            process.monitor(pid)

            -- Wait briefly for slow_worker to register
            time.sleep(10 * time.MILLISECOND)
            test.not_nil(process.registry.lookup("slow_worker_proc"))

            -- Simulate timeout expiry: runner marks entry timed_out and terminates the process
            local timeout_err = verdict.check({ entry_id = "app:slow_entry", timed_out = true })
            test.not_nil(timeout_err)
            test.eq(timeout_err.message, "test timed out")

            -- Runner termination of entry's process (and anything it links/monitors)
            process.unmonitor(pid)
            process.unlink(pid)
            process.terminate(pid)

            -- Verify the timed-out process is gone
            time.sleep(30 * time.MILLISECOND)
            local lookup = process.registry.lookup("slow_worker_proc")
            test.is_nil(lookup)

            -- Now next entry runs: "app:next_entry"
            local next_entry_id = "app:next_entry"
            local next_status = "running"
            local next_observed = 0

            -- Suppose a late event from the timed-out entry arrives
            local late_event_ref = "app:slow_entry"
            if verdict.is_event_applicable(late_event_ref, next_entry_id, next_status) then
                next_observed = next_observed + 1
            end
            test.eq(next_observed, 0) -- Late event from timed-out entry did NOT count!

            -- Next entry emits its own case event
            if verdict.is_event_applicable(next_entry_id, next_entry_id, next_status) then
                next_observed = next_observed + 1
            end
            test.eq(next_observed, 1)

            -- Even if late completion from slow_entry was presented to next_entry, verdict rejects it
            local leaked_completion = { ref_id = "app:slow_entry", total = 1, passed = 1, failed = 0, skipped = 0 }
            local leak_err = verdict.check({
                entry_id = next_entry_id,
                declared = 1,
                observed = next_observed,
                completed = leaked_completion,
            })
            test.not_nil(leak_err)
            test.eq(leak_err.kind, "runner_failure")

            -- Next entry's own completion produces a clean passing verdict
            local own_completion = { ref_id = next_entry_id, total = 1, passed = 1, failed = 0, skipped = 0 }
            local verdict_err = verdict.check({
                entry_id = next_entry_id,
                declared = 1,
                observed = next_observed,
                completed = own_completion,
            })
            test.is_nil(verdict_err)
        end)
    end)
end

return { run = test.run_cases(define_tests) }
