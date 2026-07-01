local contract = require("contract")

type CheckpointBindingSpec = {
    id: string?,
    trait_id: string?,
    kind: string?,
    contract: string?,
    binding: string?,
    context: table?,
    options: table?,
    priority: number?,
    strict: boolean?,
    order: number?,
}

type CheckpointPayload = {
    host: table,
    agent: table?,
    reason: string?,
    selector: table?,
    refs: table?,
    run_context: table?,
    options: table?,
    context: table?,
}

local checkpoint_runtime = {
    CONTRACT_ID = "wippy.agent:checkpoint",
}

checkpoint_runtime._contract = nil

local function get_contract(): any
    return checkpoint_runtime._contract or contract
end

local function normalize_bindings(bindings: any): {CheckpointBindingSpec}
    local raw = bindings
    if type(raw) == "table" and type(raw.checkpoint) == "table" then
        raw = raw.checkpoint
    end

    local normalized: {CheckpointBindingSpec} = {}
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

    return normalized :: {CheckpointBindingSpec}
end

local function copy_payload(payload: CheckpointPayload?): CheckpointPayload
    local out = {}
    for k, v in pairs(payload or {}) do
        out[k] = v
    end
    return out :: CheckpointPayload
end

local function checkpoint_text(result: any): string?
    if type(result) ~= "table" then
        return nil
    end
    local value = result.memory or result.summary
    if type(value) == "string" and value ~= "" then
        return value
    end
    return nil
end

local function call_binding(binding_spec: CheckpointBindingSpec, payload: CheckpointPayload): (table?, string?)
    local binding = binding_spec.binding
    if type(binding) ~= "string" or binding == "" then
        return nil, "checkpoint binding is required"
    end

    local contract_id = binding_spec.contract
    if type(contract_id) ~= "string" or contract_id == "" then
        contract_id = checkpoint_runtime.CONTRACT_ID
    end
    if contract_id ~= checkpoint_runtime.CONTRACT_ID then
        return nil, "unsupported checkpoint contract: " .. tostring(contract_id)
    end

    local contract_def, contract_err = get_contract().get(checkpoint_runtime.CONTRACT_ID)
    if contract_err or not contract_def then
        return nil, "failed to load checkpoint contract: " .. tostring(contract_err or "not found")
    end

    local opener = contract_def
    if opener.with_context then
        opener = opener:with_context(binding_spec.context or {})
    end

    local instance, open_err = opener:open(tostring(binding))
    if open_err or not instance then
        return nil, "failed to open checkpoint binding: " .. tostring(open_err or "no instance")
    end

    local result, apply_err = instance:create(payload)

    if apply_err then
        return nil, tostring(apply_err)
    end

    if type(result) ~= "table" then
        return nil, "checkpoint binding returned no result"
    end

    if not checkpoint_text(result) then
        return nil, "checkpoint binding returned empty memory"
    end

    return result :: table, nil
end

function checkpoint_runtime.create(bindings: any, payload: any): (table, string?)
    local base_payload: CheckpointPayload = copy_payload(payload :: CheckpointPayload?)
    local normalized = normalize_bindings(bindings)

    local summary = {
        applied = 0,
        skipped = 0,
        result = nil :: table?,
        metadata = {},
        errors = {},
    }

    if #normalized == 0 then
        return summary, nil
    end

    if type(base_payload.host) ~= "table" or type(base_payload.host.kind) ~= "string" or base_payload.host.kind == "" then
        return summary, "checkpoint host is required"
    end

    for _, binding in ipairs(normalized) do
        local current_payload: CheckpointPayload = copy_payload(base_payload)
        current_payload.options = binding.options or {}
        current_payload.context = binding.context or {}

        local result, err = call_binding(binding, current_payload :: CheckpointPayload)
        if err then
            local checkpoint_error = {
                binding_id = binding.id,
                trait_id = binding.trait_id,
                error = tostring(err),
                strict = binding.strict == true,
            }
            summary.errors[#summary.errors + 1] = checkpoint_error
            if binding.strict == true then
                return summary, tostring(err)
            end
        else
            summary.applied = summary.applied + 1
            summary.result = result
            if result.metadata ~= nil then
                summary.metadata[#summary.metadata + 1] = {
                    binding_id = binding.id,
                    trait_id = binding.trait_id,
                    metadata = result.metadata,
                }
            end
            return summary, nil
        end
    end

    return summary, nil
end

return checkpoint_runtime
