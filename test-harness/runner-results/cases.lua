local test = require("test")

return {
    empty_plan = test.run_cases(function() end),
    failing_case = test.run_cases(function()
        test.describe("failed case", function()
            test.it("keeps its failure", function()
                test.eq(1, 2, "expected case failure")
            end)
        end)
    end),
    skipped_case = test.run_cases(function()
        test.describe("skipped case", function()
            test.it_skip("is intentionally skipped", function()
                error("skipped case must not execute")
            end)
        end)
    end),
}
