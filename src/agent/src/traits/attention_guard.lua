local contract = require("contract")
local read = require("attention_read")

local M = {}
local PREFIX = "wippy.agent.tools:"
local function static_read(name)
    return name == "attention_find_semantic" or name == "attention_find_css" or name == "attention_get_tree" or name == "attention_get_node"
end

local function read_history(payload)
    local pointer = payload.run_context
    if type(pointer) ~= "table" or type(pointer.binding) ~= "string" or pointer.contract ~= "wippy.agent:run_context" then
        return nil
    end
    local definition = contract.get(pointer.contract)
    if not definition then return nil end
    local instance = definition:open(pointer.binding)
    if not instance then return nil end
    return instance:get_history({host=payload.host, selector={mode="window", last=64, max_chars=262144}})
end

-- Pure application is exported for the owning test suite. Production gets history
-- only through the authenticated run-context binding, never tool arguments.
function M.apply_history(payload, history)
    local calls = payload.tool_calls or {}
    local needed = false
    for _, call in ipairs(calls) do if read.is_read(call.registry_id) then needed = true end end
    if not needed then return {tool_calls=calls} end
    local boundary
    if type(history) == "table" and history.truncated == false and type(history.events) == "table" then
        for index, event in ipairs(history.events) do
            if event.role == "user" and type(event.id) == "string" then boundary = index end
        end
    end
    local attempts, invalid, seen, latest_tree = 0, 0, {}, nil
    if boundary then
        for index = boundary + 1, #history.events do
            local event = history.events[index]
            local meta = event.metadata or {}
            local id = meta.registry_id
            -- Count persisted function records only, never model/user prose.
            if event.role == "private_function" or event.role == "function" then
                if read.is_read(id) or id == read.receipt_id then
                    attempts = attempts + 1
                    local result: any = type(meta.result) == "table" and meta.result or {}
                    if result.invalid == true then invalid = invalid + 1 end
                    local revision = type(result.revisions) == "table" and result.revisions.tree
                    if revision ~= nil and latest_tree ~= revision then seen = {}; latest_tree = revision end
                    if read.is_read(id) and type(event.content) == "table" then
                        local name = tostring(id):sub(#PREFIX+1)
                        local normalized = read.normalize(name, event.content)
                        if normalized and (meta.stale == nil or meta.stale == false) and static_read(name) and result.status == "inspected"
                            and (result.outcome == "ok" or result.outcome == "partial" or result.outcome == "empty") then
                            seen[read.canonical(normalized)] = true
                        end
                    end
                elseif type(id) == "string" and id:sub(1, #PREFIX+10) == PREFIX .. "ui_action_" then
                    -- An explicit interaction can change the page without another read.
                    seen = {}
                end
            end
        end
    end
    local result, admitted, refusals = {}, false, {}
    for _, call in ipairs(calls) do
        if not read.is_read(call.registry_id) then
            result[#result+1] = call
        else
            local name = call.registry_id:sub(#PREFIX+1)
            local normalized, validation_error = read.normalize(name, call.arguments)
            local reason
            if not boundary then reason = "history-unavailable"
            elseif attempts >= 4 then reason = "read-budget-exhausted"
            elseif invalid >= 2 then reason = "repair-budget-exhausted"
            elseif not normalized then reason = validation_error or "invalid-request"
            elseif admitted then reason = "one-read-per-batch"
            elseif static_read(name) and seen[read.canonical(normalized)] then reason = "duplicate-read" end
            attempts = attempts + 1
            if reason then
                local invalid_call = normalized == nil
                if invalid_call then invalid = invalid + 1 end
                -- Preserve provider pairing and metadata, replacing only execution.
                local receipt = {}
                for key, value in pairs(call) do receipt[key] = value end
                receipt.registry_id = read.receipt_id
                receipt.arguments = {reason=reason, original_registry_id=call.registry_id, invalid=invalid_call}
                result[#result+1] = receipt
                refusals[#refusals+1] = {call_id=call.id, reason=reason, original_registry_id=call.registry_id}
            else
                admitted = true
                result[#result+1] = call
            end
        end
    end
    return {tool_calls=result, metadata={attention_refusals=refusals}}
end

function M.apply(payload)
    if payload.phase ~= "before_execute" then return {skipped=true} end
    local needed = false
    for _, call in ipairs(payload.tool_calls or {}) do if read.is_read(call.registry_id) then needed = true end end
    if not needed then return {tool_calls=payload.tool_calls} end
    local ok, history = pcall(read_history, payload)
    return M.apply_history(payload, ok and history or nil)
end

return M
