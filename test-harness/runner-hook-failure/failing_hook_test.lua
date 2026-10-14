local test = require("test")

local function define_tests()
    test.describe("hook failure", function()
        test.describe("first group", function()
            test.it("executes before the hook fails", function()
                test.eq(1, 1)
            end)
        end)
        test.describe("second group", function()
            test.before_all(function()
                error("expected hook failure before second case")
            end)
            test.it("must not be counted as passed", function()
                test.eq(2, 2)
            end)
        end)
    end)
end

return {run = test.run_cases(define_tests)}
