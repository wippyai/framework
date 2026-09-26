-- Coordinates agent transitions for hosts. The host owns state and supplies
-- payloads/dispatch so session and dataflow keep their own refs and policies.
local lifecycle_controller = {}

local function copy_value(value: any, seen: table?): any
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local out = {}
    seen[value] = out
    for key, item in pairs(value) do
        out[copy_value(key, seen)] = copy_value(item, seen)
    end
    return out
end

local function equal_value(a: any, b: any, seen: table?): boolean
    if type(a) ~= type(b) then
        return false
    end
    if type(a) ~= "table" then
        return a == b
    end
    seen = seen or {}
    if seen[a] and seen[a][b] then
        return true
    end
    seen[a] = seen[a] or {}
    seen[a][b] = true
    for key, value in pairs(a) do
        if not equal_value(value, b[key], seen) then
            return false
        end
    end
    for key, _ in pairs(b) do
        if a[key] == nil then
            return false
        end
    end
    return true
end

local function empty_result(): table
    return {
        activated = false,
        deactivated = false,
        refreshed = false,
        activation = nil,
        deactivation = nil,
    }
end

local function active_descriptor(state: table): table?
    if state.active_agent_id == nil or state.active_agent == nil then
        return nil
    end
    return {
        id = state.active_agent_id,
        model = state.active_model,
        agent = state.active_agent,
        revision = state.active_revision,
        variant = state.active_variant,
    }
end

local function prior_descriptor(state: table, opts: table): table?
    local active = active_descriptor(state)
    if active then
        return active
    end
    -- A fallback recovers a missing agent object for an already active state.
    -- It must not cause a never-activated agent to receive deactivate.
    if state.active_agent_id ~= nil then
        if type(opts.fallback) ~= "table" then
            return nil
        end
        return {
            id = state.active_agent_id,
            model = state.active_model,
            agent = opts.fallback.agent,
            revision = state.active_revision,
            variant = state.active_variant,
        }
    end
    return nil
end

local function clear_active(state: table)
    state.active_agent_id = nil
    state.active_model = nil
    state.active_agent = nil
    state.active_revision = nil
    state.active_variant = nil
end

local function set_active(state: table, descriptor: table)
    state.active_agent_id = descriptor.id
    state.active_model = descriptor.model
    state.active_agent = descriptor.agent
    state.active_revision = descriptor.revision
    state.active_variant = copy_value(descriptor.variant)
end

local function validate(state: any, opts: any): string?
    if type(state) ~= "table" then
        return "lifecycle state must be a table"
    end
    if type(opts) ~= "table" or type(opts.dispatch) ~= "function" then
        return "lifecycle dispatch function is required"
    end
    if type(opts.payload) ~= "function" then
        return "lifecycle payload function is required"
    end
    return nil
end

local function dispatch(opts: table, descriptor: table, phase: string): (any, string?)
    local payload = opts.payload(phase, descriptor)
    return opts.dispatch(descriptor.agent, phase, payload)
end

-- Revision and variant are optional for backward compatibility. A variant is
-- compared by value and snapshotted so in-place overlay edits are detected.
function lifecycle_controller.activate(state: any, target: any, opts: any): (table, string?)
    local result = empty_result()
    local err = validate(state, opts)
    if err then
        return result, err
    end
    if type(target) ~= "table" or target.agent == nil or target.id == nil then
        return result, "lifecycle target agent is required"
    end

    local previous = prior_descriptor(state, opts)
    if state.active_agent_id ~= nil and previous == nil then
        return result, "lifecycle fallback agent is required"
    end
    if previous and (type(previous) ~= "table" or previous.agent == nil) then
        return result, "lifecycle fallback agent is required"
    end
    if previous and previous.id == target.id and previous.model == target.model
        and previous.revision == target.revision
        and equal_value(previous.variant, target.variant) then
        set_active(state, target)
        result.refreshed = true
        return result, nil
    end

    if previous then
        local deactivation, deactivation_err = dispatch(opts, previous, "deactivate")
        result.deactivation = deactivation
        if deactivation_err then
            return result, deactivation_err
        end
        result.deactivated = true
        clear_active(state)
    end

    local activation, activation_err = dispatch(opts, target, "activate")
    result.activation = activation
    if activation_err then
        clear_active(state)
        return result, activation_err
    end

    set_active(state, target)
    result.activated = true
    return result, nil
end

function lifecycle_controller.deactivate(state: any, opts: any): (table, string?)
    local result = empty_result()
    local err = validate(state, opts)
    if err then
        return result, err
    end

    local previous = prior_descriptor(state, opts)
    if state.active_agent_id ~= nil and previous == nil then
        return result, "lifecycle fallback agent is required"
    end
    if previous == nil then
        return result, nil
    end
    if type(previous) ~= "table" or previous.agent == nil then
        return result, "lifecycle fallback agent is required"
    end

    local deactivation, deactivation_err = dispatch(opts, previous, "deactivate")
    result.deactivation = deactivation
    if deactivation_err then
        return result, deactivation_err
    end

    clear_active(state)
    result.deactivated = true
    return result, nil
end

return lifecycle_controller
