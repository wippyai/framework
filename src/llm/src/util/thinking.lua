local thinking = {}

-- Beta that admits thinking.block_binding and adds input_transformations to responses.
thinking.BINDING_BETA = "thinking-binding-controls-2026-08-01"

-- block_binding rides only on a thinking object of type adaptive or enabled; the API
-- rejects it alongside disabled or between_tools thinking and without a thinking object.
local BINDABLE_TYPES: {[string]: boolean} = { adaptive = true, enabled = true }

-- Sets drop_block on a thinking object that replays earlier thinking blocks, so the API
-- drops blocks bound to a different conversation instead of rejecting the request.
-- A block_binding the object already carries stays as set.
function thinking.bind_replayed_blocks(config: {[string]: any}?)
    if type(config) ~= "table" or not BINDABLE_TYPES[config.type] or config.block_binding ~= nil then
        return
    end
    config.block_binding = { prefix_mismatch_behavior = "drop_block" }
end

-- Whether a thinking object carries block_binding, which the API admits only with BINDING_BETA.
function thinking.is_bound(config: {[string]: any}?): boolean
    return type(config) == "table" and config.block_binding ~= nil
end

function thinking.effort_level(effort: number): string
    if effort >= 100 then return "max" end
    if effort >= 80 then return "xhigh" end
    if effort > 50 then return "high" end
    if effort >= 20 then return "medium" end
    return "low"
end

return thinking
