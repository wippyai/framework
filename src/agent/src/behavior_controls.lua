local json = require("json")

-- The shared, declarative subset of the hosts' existing tool-control protocol.
-- Validation is separate from application: hosts own authorization, durability,
-- transitions, and the boundary at which a proposal can take effect.
local behavior_controls = {}

local function nonempty_string(value)
    return type(value) == "string" and string.find(value, "%S") ~= nil
end

local function object(value, allowed)
    if type(value) ~= "table" then return false end
    for key in pairs(value) do
        if type(key) ~= "string" or not allowed[key] then return false end
    end
    return true
end

local function list(value, predicate)
    if type(value) ~= "table" then return false end
    local count = 0
    for key, item in pairs(value) do
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0 or not predicate(item) then return false end
        count = count + 1
    end
    return count == #value
end

local function attachment(value)
    return nonempty_string(value) or (type(value) == "table" and nonempty_string(value.id))
end

local function context_operations(value, public)
    if not object(value, { set = true, delete = true, clear = public }) then return false end
    if value.set ~= nil then
        if type(value.set) ~= "table" then return false end
        for key, item in pairs(value.set) do
            if not nonempty_string(key) or (public and type(item) ~= "table") then return false end
        end
    end
    if value.delete ~= nil and not list(value.delete, nonempty_string) then return false end
    if value.clear ~= nil and not nonempty_string(value.clear) then return false end
    return true
end

local function persistent_value(value, seen, depth)
    local kind = type(value)
    if kind == "string" or kind == "boolean" or kind == "nil" then return true end
    if kind == "number" then return value == value and value ~= math.huge and value ~= -math.huge end
    if kind ~= "table" or seen[value] or depth > 32 then return false end
    seen[value] = true
    local numeric_keys, string_keys = 0, 0
    for key, item in pairs(value) do
        if type(key) == "number" then
            if key < 1 or key % 1 ~= 0 then seen[value] = nil; return false end
            numeric_keys = numeric_keys + 1
        elseif type(key) == "string" then
            string_keys = string_keys + 1
        else
            seen[value] = nil
            return false
        end
        if not persistent_value(item, seen, depth + 1) then
            seen[value] = nil
            return false
        end
    end
    seen[value] = nil
    if numeric_keys > 0 and (string_keys > 0 or numeric_keys ~= #value) then return false end
    return true
end

function behavior_controls.validate(control)
    if not object(control, { config = true, context = true, memory = true }) then
        return nil, "behavior control only supports config, context and memory"
    end
    if control.config ~= nil then
        local config = control.config
        if not object(config, { agent = true, model = true, traits = true, tools = true }) then
            return nil, "behavior config only supports agent, model, traits and tools"
        end
        for _, key in ipairs({ "agent", "model" }) do
            if config[key] ~= nil and not nonempty_string(config[key]) then
                return nil, "behavior config." .. key .. " must be a non-empty string"
            end
        end
        for _, key in ipairs({ "traits", "tools" }) do
            if config[key] ~= nil and not list(config[key], attachment) then
                return nil, "behavior config." .. key .. " must be a dense attachment list"
            end
        end
    end
    if control.context ~= nil then
        local context = control.context
        if not object(context, { session = true, public_meta = true }) then
            return nil, "behavior context only supports session and public_meta"
        end
        for _, key in ipairs({ "session", "public_meta" }) do
            if context[key] ~= nil and not context_operations(context[key], key == "public_meta") then
                return nil, "invalid behavior context." .. key .. " operations"
            end
        end
    end
    if control.memory ~= nil then
        if not object(control.memory, { compact = true }) or
            (control.memory.compact ~= nil and type(control.memory.compact) ~= "boolean") then
            return nil, "behavior memory only supports boolean compact"
        end
    end
    return true
end

-- Copy through the canonical serializer: proposals must be persistence-safe,
-- not closures, userdata, cyclic tables, or references to mutable handler state.
function behavior_controls.prepare(controls)
    if controls == nil then return {} end
    if not list(controls, function(value) return type(value) == "table" end) then
        return nil, "behavior controls must be a dense list"
    end
    for _, control in ipairs(controls) do
        local valid, err = behavior_controls.validate(control)
        if not valid then return nil, err end
    end
    if #controls == 0 then return {} end
    if not persistent_value(controls, {}, 0) then return nil, "behavior controls contain non-persistent values" end
    local encoded, encode_err = json.encode(controls)
    if encode_err then return nil, "behavior controls are not serializable: " .. tostring(encode_err) end
    local copied, decode_err = json.decode(encoded)
    if decode_err then return nil, tostring(decode_err) end
    return copied
end

return behavior_controls
