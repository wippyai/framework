local test = require("test")
local security = require("security")
local funcs = require("funcs")
local tool_caller = require("tool_caller")
local execution_authority = require("execution_authority")
local original_refresh_perms = execution_authority.refresh_perms

local function run_tests()
    test.describe("UPSTREAM-AGENT-TOOL-LIVE-AUTHORITY resolver contract", function()
        local actor
        local scope
        local dispatched
        local captures
        local resolutions
        local resolver
        test.before_each(function()
            execution_authority.refresh_perms = true
            actor = assert(security.actor())
            scope = assert(security.scope())
            dispatched, captures, resolutions = 0, 0, 0
            resolver = {
                capture = function(captured_actor, captured_scope)
                    captures = captures + 1
                    test.eq(captured_actor:id(), actor:id())
                    test.eq(captured_scope:evaluate(actor, "funcs.call", "test:effect"), "allow")
                    return {restriction = "credential"}
                end,
                resolve = function(args)
                    resolutions = resolutions + 1
                    test.eq(args.subject_id, actor:id())
                    test.is_true(args.authority_only)
                    test.eq(args.authority_context.restriction, "credential")
                    return actor, scope
                end,
            }
            tool_caller._identity_resolver = resolver
            tool_caller._funcs = {new = function()
                local executor = {}
                function executor:with_actor(current)
                    test.eq(current:id(), actor:id())
                    return self
                end
                function executor:with_scope(current)
                    test.eq(current, scope, "the provider's native scope is passed unchanged")
                    return self
                end
                function executor:with_context(context) return self end
                function executor:call(id, args)
                    dispatched = dispatched + 1
                    return {effect = dispatched}
                end
                function executor:async(id, args)
                    local result = self:call(id, args)
                    return {
                        response = function() return {receive = function() return {}, true end} end,
                        is_canceled = function() return false end,
                        result = function() return {data = function() return result end} end,
                    }
                end
                return executor
            end}
        end)
        test.after_each(function()
            execution_authority.refresh_perms = original_refresh_perms
            tool_caller._identity_resolver = nil
            tool_caller._funcs = nil
        end)
        local function execute(caller, count)
            local calls = {}
            for i = 1, count do
                calls[tostring(i)] = {valid = true, call_id = tostring(i), registry_id = "test:effect", args = {}}
            end
            return caller:execute({}, calls)
        end

        for _, strategy in ipairs({"sequential", "parallel"}) do
            test.it(strategy .. " does not call the resolver unless refresh_perms is true", function()
                for _, disabled in ipairs({false, "true"}) do
                    execution_authority.refresh_perms = disabled
                    local results = execute(tool_caller.new():set_strategy(strategy), 2)
                    test.is_nil(results["1"].error)
                    test.is_nil(results["2"].error)
                end
                test.eq(captures, 0)
                test.eq(resolutions, 0)
                test.eq(dispatched, 4)
            end)
            test.it(strategy .. " ignores a malformed binding while refresh is disabled", function()
                execution_authority.refresh_perms = false
                tool_caller._identity_resolver = {}
                local results = execute(tool_caller.new():set_strategy(strategy), 1)
                test.is_nil(results["1"].error)
                test.eq(dispatched, 1)
                test.eq(captures, 0)
                test.eq(resolutions, 0)
            end)
            test.it(strategy .. " retains normal execution with no resolver binding", function()
                tool_caller._identity_resolver = nil
                local results = execute(tool_caller.new():set_strategy(strategy), 2)
                test.is_nil(results["1"].error)
                test.is_nil(results["2"].error)
                test.eq(captures, 0)
                test.eq(resolutions, 0)
                test.eq(dispatched, 2)
            end)
            test.it(strategy .. " does not refresh empty or invalid-only batches", function()
                local caller = tool_caller.new():set_strategy(strategy)
                execute(caller, 0)
                caller:execute({}, {invalid = {valid = false, error = "invalid tool"}})
                test.eq(resolutions, 0)
                test.eq(dispatched, 0)
            end)
            for _, stage in ipairs({"capture", "resolve"}) do
                for _, spec in ipairs({
                    {kind = errors.INVALID, retryable = false},
                    {kind = errors.UNAVAILABLE, retryable = true},
                    {kind = errors.TIMEOUT, retryable = false},
                    {kind = errors.PERMISSION_DENIED, retryable = true},
                    {kind = errors.INTERNAL, retryable = false},
                    {kind = errors.CONFLICT, retryable = true},
                    {kind = errors.CANCELED, retryable = false},
                }) do
                    test.it(strategy .. " preserves native " .. stage .. " error " .. spec.kind, function()
                        local cause = errors.new({message = "provider read fails", kind = spec.kind,
                            retryable = spec.retryable, details = {operation = stage, subject_id = actor:id()}})
                        local provider_error = errors.wrap(cause, "authority provider")
                        if stage == "capture" then
                            resolver.capture = function() return nil, provider_error end
                        else
                            resolver.resolve = function() return nil, nil, provider_error end
                        end
                        local results = execute(tool_caller.new():set_strategy(strategy), 1)
                        local actual = results["1"].error
                        test.eq(dispatched, 0)
                        test.is_nil(results["1"].result)
                        test.not_nil(actual)
                        test.eq(actual:kind(), provider_error:kind())
                        test.eq(actual:retryable(), provider_error:retryable())
                        local actual_details, expected_details = actual:details(), provider_error:details()
                        test.not_nil(actual_details)
                        for key, value in pairs(expected_details) do test.eq(actual_details[key], value) end
                        for key, value in pairs(actual_details) do test.eq(value, expected_details[key]) end
                        test.eq(actual:message(), provider_error:message())
                        test.is_true(actual == provider_error, "native error identity and cause remain intact")
                    end)
                end
            end
            test.it(strategy .. " refreshes at execution boundaries without reusing a previous batch", function()
                local caller = tool_caller.new():set_strategy(strategy)
                execute(caller, 2)
                execute(caller, 1)
                test.eq(captures, 1)
                test.eq(resolutions, strategy == "parallel" and 2 or 3)
                test.eq(dispatched, 3)
            end)
            test.it(strategy .. " observes native scope reduction at the next execution boundary", function()
                resolver.resolve = function()
                    resolutions = resolutions + 1
                    if resolutions >= 2 then scope = assert(security.new_scope({})) end
                    return actor, scope
                end
                local caller = tool_caller.new():set_strategy(strategy)
                local results = execute(caller, 2)
                if strategy == "parallel" then
                    test.eq(resolutions, 1)
                    test.eq(dispatched, 2)
                    test.is_nil(results["1"].error)
                    test.is_nil(results["2"].error)
                    local denied = execute(caller, 1)
                    test.is_true(errors.is(denied["1"].error, errors.PERMISSION_DENIED))
                    test.eq(resolutions, 2)
                    test.eq(dispatched, 2)
                    return
                end
                test.eq(resolutions, 2)
                test.eq(dispatched, 1)
                local failures = 0
                for _, result in pairs(results) do
                    if result.error then
                        failures = failures + 1
                        test.is_true(errors.is(result.error, errors.PERMISSION_DENIED))
                    end
                end
                test.eq(failures, 1)
            end)
            for _, mode in ipairs({"different_subject", "non_native", "wrong_native", "denied", "exception", "capture_error", "capture_exception", "invalid_contract", "invalid_context"}) do
                test.it(strategy .. " fails closed for " .. mode, function()
                    if mode == "different_subject" then
                        resolver.resolve = function() return assert(security.new_actor("other.subject", {})), scope end
                    elseif mode == "non_native" then
                        resolver.resolve = function() return {id = function() return actor:id() end}, {} end
                    elseif mode == "wrong_native" then
                        resolver.resolve = function() return scope, actor end
                    elseif mode == "denied" then
                        resolver.resolve = function()
                            return nil, nil, errors.new({message = "subject is inactive", kind = errors.PERMISSION_DENIED, retryable = false})
                        end
                    elseif mode == "exception" then
                        resolver.resolve = function()
                            local _, err = funcs.call("app:authority_provider_failure")
                            return nil, nil, err
                        end
                    elseif mode == "capture_error" then
                        resolver.capture = function() return nil, errors.new({message = "authority provider is offline", kind = errors.UNAVAILABLE, retryable = true}) end
                    elseif mode == "capture_exception" then
                        resolver.capture = function() return funcs.call("app:authority_provider_failure") end
                    elseif mode == "invalid_contract" then
                        resolver.resolve = nil
                    elseif mode == "invalid_context" then
                        resolver.capture = function() return nil end
                    end
                    local results = execute(tool_caller.new():set_strategy(strategy), 1)
                    test.eq(dispatched, 0)
                    test.not_nil(results["1"].error)
                    test.is_nil(results["1"].result)
                    local unavailable = mode == "exception" or mode == "capture_error" or mode == "capture_exception"
                    test.is_true(errors.is(results["1"].error, unavailable and errors.UNAVAILABLE or (mode == "denied" and errors.PERMISSION_DENIED or errors.INVALID)))
                    test.eq(results["1"].error:retryable(), unavailable)
                end)
            end
            test.it(strategy .. " retries live resolution without reusing a successful scope", function()
                local caller = tool_caller.new():set_strategy(strategy)
                execute(caller, 1)
                resolver.resolve = function() return nil, nil, errors.new({message = "authority provider is offline", kind = errors.UNAVAILABLE, retryable = true}) end
                local denied = execute(caller, 1)
                test.is_true(errors.is(denied["1"].error, errors.UNAVAILABLE))
                resolver.resolve = function() return actor, scope end
                execute(caller, 1)
                test.eq(dispatched, 2)
            end)
        end
        test.it("shares a parallel refresh failure across the batch and retries at the next batch", function()
            local failure = errors.new({kind = errors.UNAVAILABLE, message = "authority offline", retryable = true})
            local original_resolve = resolver.resolve
            resolver.resolve = function()
                resolutions = resolutions + 1
                return nil, nil, failure
            end
            local caller = tool_caller.new():set_strategy("parallel")
            local results = execute(caller, 3)
            test.eq(resolutions, 1)
            test.eq(dispatched, 0)
            for _, result in pairs(results) do test.eq(result.error, failure) end
            resolver.resolve = original_resolve
            execute(caller, 2)
            test.eq(resolutions, 2)
            test.eq(dispatched, 2)
        end)
    end)
end

return {
    run_tests = test.run_cases(run_tests),
    provider_failure = function()
        error(errors.new({message = "authority provider is offline", kind = errors.UNAVAILABLE, retryable = true}))
    end,
}
