local test = require("test")
local security = require("security")
local funcs = require("funcs")

local function track_under(policies: { string })
    local scope = security.new_scope()
    for _, id in ipairs(policies) do
        scope = scope:with(assert(security.policy(id)))
    end
    local actor = security.new_actor("app.usage_tracker:test", {})
    local result, err = funcs.new():with_actor(actor):with_scope(scope):call("app.usage_tracker:worker")
    test.is_nil(err)
    return result
end

local function define_tests()
    describe("LLM usage tracker contract", function()
        it("records usage through the bound tracker", function()
            local result = track_under({ "app.usage_tracker:allow_all" })
            test.eq(result.usage_id, "usage-1")
        end)

        it("returns a refused usage tracker binding open as its native error", function()
            local result = track_under({ "app.usage_tracker:allow_all", "app.usage_tracker:deny_open" })
            test.eq(result.kind, errors.PERMISSION_DENIED)
            test.is_false(result.retryable)
            test.eq(result.message, "not allowed to open binding: app.usage_tracker:tracker")
        end)

        it("returns a refused usage tracker contract read as its native error", function()
            local result = track_under({ "app.usage_tracker:allow_all", "app.usage_tracker:deny_get" })
            test.eq(result.kind, errors.PERMISSION_DENIED)
            test.is_false(result.retryable)
            test.eq(result.message, "not allowed to access contract: wippy.llm:usage_tracker")
        end)
    end)
end

return { run_tests = test.run_cases(define_tests) }
