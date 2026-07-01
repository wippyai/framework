local contract = require("contract")

type LifecycleBindingSpec = {
    id: string?,
    trait_id: string?,
    kind: string?,
    contract: string?,
    binding: string?,
    phases: {string}?,
    context: table?,
    options: table?,
    priority: number?,
    strict: boolean?,
    order: number?,
}

type LifecyclePayload = {
    phase: string,
    host: table,
    agent: table?,
    reason: string?,
    outcome: table?,
    refs: table?,
    run_context: table?,
    options: table?,
}

local PHASE = {
    ACTIVATE = "activate",
    BEFORE_STEP = "before_step",
    AFTER_STEP = "after_step",
    DEACTIVATE = "deactivate",
}

local lifecycle_runtime = {
    PHASE = PHASE,
    CONTRACT_ID = "wippy.agent:lifecycle",
}

lifecycle_runtime._contract = nil

local function get_contract(): any
    return lifecycle_runtime._contract or contract
end

local function normalize_bindings(bindings: any): {LifecycleBindingSpec}
    local raw = bindings
    if type(raw) == "table" and type(raw.lifecycle) == "table" then
        raw = raw.lifecycle
    end

    local normalized: {LifecycleBindingSpec} = {}
    for _, binding in ipairs(raw or {}) do
        if type(binding) == "table" then
            normalized[#normalized + 1] = binding
        end
    end

    table.sort(normalized, function(a, b)
        local ap = tonumber(a.priority) or 100
        local bp = tonumber(b.priority) or 100
        if ap == bp then
            return (tonumber(a.order) or 0) < (tonumber(b.order) or 0)
        end
        return ap < bp
    end)

    return normalized :: {LifecycleBindingSpec}
end

local function supports_phase(binding: LifecycleBindingSpec, phase: string): boolean
    if type(binding.phases) ~= "table" or #binding.phases == 0 then
        return true
    end

    for _, binding_phase in ipairs(binding.phases) do
        if binding_phase == phase then
            return true
        end
    end

    return false
end

local function copy_payload(payload: LifecyclePayload?): LifecyclePayload
    local out = {}
    for k, v in pairs(payload or {}) do
        out[k] = v
    end
    return out :: LifecyclePayload
end

local function merge_context(target: table, source: any)
    if type(source) ~= "table" then
        return
    end
    for k, v in pairs(source) do
        target[k] = v
    end
end

local function call_binding(binding_spec: LifecycleBindingSpec, payload: LifecyclePayload): (table?, string?)
    local binding = binding_spec.binding
    if type(binding) ~= "string" or binding == "" then
        return nil, "lifecycle binding is required"
    end

    local contract_def, contract_err = get_contract().get(lifecycle_runtime.CONTRACT_ID)
    if contract_err or not contract_def then
        return nil, "failed to load lifecycle contract: " .. tostring(contract_err or "not found")
    end

    local opener = contract_def
    if opener.with_context then
        opener = opener:with_context(binding_spec.context or {})
    end

    local instance, open_err = opener:open(tostring(binding))
    if open_err or not instance then
        return nil, "failed to open lifecycle binding: " .. tostring(open_err or "no instance")
    end

    local result, apply_err = instance:apply(payload)
    if apply_err then
        return nil, tostring(apply_err)
    end

    return (type(result) == "table" and result or {}) :: table, nil
end

function lifecycle_runtime.apply(bindings: any, payload: any): (table, string?)
    local current_payload: LifecyclePayload = copy_payload(payload :: LifecyclePayload?)
    local phase = current_payload.phase
    local normalized = normalize_bindings(bindings)

    local summary = {
        applied = 0,
        skipped = 0,
        messages = {},
        context = {},
        observations = {},
        metadata = {},
        errors = {},
    }

    if #normalized == 0 then
        return summary, nil
    end

    if type(phase) ~= "string" or phase == "" then
        return summary, "lifecycle phase is required"
    end

    if type(current_payload.host) ~= "table" or type(current_payload.host.kind) ~= "string" or current_payload.host.kind == "" then
        return summary, "lifecycle host is required"
    end

    for _, binding in ipairs(normalized) do
        if supports_phase(binding, phase) then
            current_payload.options = binding.options or {}
            local result, err = call_binding(binding, current_payload :: LifecyclePayload)
            if err then
                local lifecycle_error = {
                    binding_id = binding.id,
                    trait_id = binding.trait_id,
                    phase = phase,
                    error = tostring(err),
                    strict = binding.strict == true,
                }
                summary.errors[#summary.errors + 1] = lifecycle_error
                if binding.strict == true then
                    return summary, tostring(err)
                end
            else
                summary.applied = summary.applied + 1
                for _, message in ipairs(result.messages or {}) do
                    summary.messages[#summary.messages + 1] = message
                end
                for _, observation in ipairs(result.observations or {}) do
                    summary.observations[#summary.observations + 1] = observation
                end
                merge_context(summary.context, result.context)
                if result.metadata ~= nil then
                    summary.metadata[#summary.metadata + 1] = {
                        binding_id = binding.id,
                        trait_id = binding.trait_id,
                        phase = phase,
                        metadata = result.metadata,
                    }
                end
            end
        else
            summary.skipped = summary.skipped + 1
        end
    end

    return summary, nil
end

return lifecycle_runtime
