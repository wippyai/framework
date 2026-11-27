local test = require("test")
local security = require("security")
local funcs = require("funcs")

local function resolve_under(policies: { string }, model: string)
    local scope = security.new_scope()
    for _, id in ipairs(policies) do
        scope = scope:with(assert(security.policy(id)))
    end
    local actor = security.new_actor("app.model_resolver:test", {})
    local result, err = funcs.new():with_actor(actor):with_scope(scope):call("app.model_resolver:worker", model)
    test.is_nil(err)
    return result
end

local function define_tests()
    describe("LLM model resolver contract", function()
        it("falls back to discovery when the bound resolver declines", function()
            local result = resolve_under({ "app.model_resolver:allow_all" }, "unconfigured")
            test.eq(result.kind, errors.NOT_FOUND)
            test.eq(result.message, "Model or class not found: unconfigured")
        end)

        it("returns a refused resolver binding open as its native error", function()
            local result = resolve_under({ "app.model_resolver:allow_all", "app.model_resolver:deny_open" }, "unconfigured")
            test.eq(result.kind, errors.PERMISSION_DENIED)
            test.is_false(result.retryable)
            test.eq(result.message, "not allowed to open binding: app.model_resolver:resolver")
        end)

        it("returns a refused resolver contract read as its native error", function()
            local result = resolve_under({ "app.model_resolver:allow_all", "app.model_resolver:deny_get" }, "unconfigured")
            test.eq(result.kind, errors.PERMISSION_DENIED)
            test.is_false(result.retryable)
            test.eq(result.message, "not allowed to access contract: wippy.llm:model_resolver")
        end)
    end)
end

return { run_tests = test.run_cases(define_tests) }
