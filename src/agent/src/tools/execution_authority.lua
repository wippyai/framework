local security = require("security")
local M = {}

local function authority_error(err: any): any
    local denied = errors.is(err, errors.PERMISSION_DENIED)
    return errors.new({
        message = "Tool execution authority resolution fails: " .. tostring(err),
        kind = denied and errors.PERMISSION_DENIED or errors.UNAVAILABLE,
        retryable = not denied,
        details = {cause = tostring(err)},
    })
end

local function capture_authority(resolver: any): any
    if type(resolver) ~= "table" or type(resolver.capture) ~= "function" or type(resolver.resolve) ~= "function" then
        return nil, errors.new({message = "Execution identity resolver must provide capture and resolve", kind = errors.INVALID, retryable = false})
    end
    local actor, actor_err = security.actor()
    if actor_err then return nil, actor_err end
    local scope, scope_err = security.scope()
    if scope_err then return nil, scope_err end
    if not actor or not scope then
        return nil, errors.new({message = "Current execution identity is unavailable", kind = errors.UNAVAILABLE, retryable = true})
    end
    local context, err = resolver.capture(actor, scope)
    if err then return nil, authority_error(err) end
    if type(context) ~= "table" or getmetatable(context) ~= nil then
        return nil, errors.new({message = "Execution authority capture must return a plain table", kind = errors.INVALID, retryable = false})
    end
    return {resolver = resolver, subject_id = actor:id(), actor_meta = actor:meta(), authority_context = context}, nil
end

function M.executor(saved: any, executor: any, context: table, registry_id: string): any
    if saved ~= nil then
        local ok, actor, scope, err = pcall(saved.resolver.resolve, {
            subject_id = saved.subject_id,
            authority_only = true,
            actor_meta = saved.actor_meta,
            authority_context = saved.authority_context,
        })
        if not ok then return nil, authority_error(actor) end
        if err then return nil, authority_error(err) end
        if type(actor) ~= "userdata" or type(scope) ~= "userdata" then
            return nil, errors.new({message = "Execution identity resolver must return a native actor and scope", kind = errors.INVALID, retryable = false})
        end
        local valid, validation_err = pcall(function()
            if actor:id() ~= saved.subject_id then
                error("Execution identity resolver returns a different subject")
            end
            (scope :: security.Scope):policies()
        end)
        if not valid then
            return nil, errors.new({message = "Invalid execution identity: " .. tostring(validation_err), kind = errors.INVALID, retryable = false})
        end
        local evaluated, decision = pcall(function()
            return (scope :: security.Scope):evaluate(actor, "funcs.call", registry_id)
        end)
        if not evaluated then return nil, authority_error(decision) end
        if decision ~= "allow" then
            return nil, errors.new({message = "Tool execution is not allowed: " .. registry_id,
                kind = errors.PERMISSION_DENIED, retryable = false})
        end
        local actor_err
        executor, actor_err = executor:with_actor(actor)
        if actor_err then return nil, actor_err end
        local scope_err
        executor, scope_err = executor:with_scope(scope)
        if scope_err then return nil, scope_err end
    end
    return executor:with_context(context)
end

function M.capture(resolver: any): any
    resolver = resolver or execution_identity_resolver
    if resolver == nil then return nil, nil end
    local ok, authority, err = pcall(capture_authority, resolver)
    if not ok then return nil, authority_error(authority) end
    return authority, err
end

return M
