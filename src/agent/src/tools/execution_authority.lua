local security = require("security")
local M = {}

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
    if err then return nil, err end
    if type(context) ~= "table" or getmetatable(context) ~= nil then
        return nil, errors.new({message = "Execution authority capture must return a plain table", kind = errors.INVALID, retryable = false})
    end
    return {resolver = resolver, subject_id = actor:id(), actor_meta = actor:meta(), authority_context = context,
        actor_type = getmetatable(actor), scope_type = getmetatable(scope)}, nil
end

function M.executor(saved: any, executor: any, context: table, registry_id: string): any
    if saved ~= nil then
        local actor, scope, err = saved.resolver.resolve({
            subject_id = saved.subject_id,
            authority_only = true,
            actor_meta = saved.actor_meta,
            authority_context = saved.authority_context,
        })
        if err then return nil, err end
        if type(actor) ~= "userdata" or type(scope) ~= "userdata"
            or getmetatable(actor) ~= saved.actor_type or getmetatable(scope) ~= saved.scope_type then
            return nil, errors.new({message = "Execution identity resolver must return a native actor and scope", kind = errors.INVALID, retryable = false})
        end
        if actor:id() ~= saved.subject_id then
            return nil, errors.new({message = "Execution identity resolver returns a different subject",
                kind = errors.INVALID, retryable = false})
        end
        local decision = (scope :: security.Scope):evaluate(actor, "funcs.call", registry_id)
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
    return capture_authority(resolver)
end

return M
