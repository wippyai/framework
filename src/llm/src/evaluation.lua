-- Shared boundary validation for both the public facade and direct evaluator bindings.
local evaluation = {}

local function json_value(value, seen)
    local kind = type(value)
    if kind == "nil" or kind == "string" or kind == "boolean" then return true end
    if kind == "number" then return value == value and value ~= math.huge and value ~= -math.huge end
    if kind ~= "table" or seen[value] then return false end
    seen[value] = true
    for key, item in pairs(value) do
        if type(key) ~= "string" and (type(key) ~= "number" or key % 1 ~= 0 or key < 1) then
            seen[value] = nil
            return false
        end
        if not json_value(item, seen) then
            seen[value] = nil
            return false
        end
    end
    seen[value] = nil
    return true
end

local function dense_array(value)
    if type(value) ~= "table" then return nil end
    local count = 0
    local max_index = 0
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then return nil end
        count = count + 1
        if key > max_index then max_index = key end
    end
    if count ~= max_index then return nil end
    return count
end

local function validate_slot(key, slot)
    local suffix = " in slot: " .. key
    if type(slot) ~= "table" then return "Slot must be a table" .. suffix end
    for field in pairs(slot) do
        if field ~= "type" and field ~= "instructions" and field ~= "domain" then
            return "Unknown slot field '" .. tostring(field) .. "'" .. suffix
        end
    end
    if slot.type == nil then return "Slot type is required" .. suffix end
    if slot.type ~= "choice" and slot.type ~= "predicate" and slot.type ~= "score" then
        return "Unknown slot type '" .. tostring(slot.type) .. "'" .. suffix
    end
    local instructions = slot.instructions
    if instructions == nil then return "Instructions are required" .. suffix end
    if type(instructions) == "string" then
        if instructions == "" then return "Instructions must not be empty" .. suffix end
    elseif type(instructions) ~= "table" or not json_value(instructions, {}) then
        return "Instructions must be a JSON-compatible string or table" .. suffix
    end

    local domain = slot.domain
    if slot.type == "choice" then
        if domain == nil then return "Choice domain is required" .. suffix end
        if type(domain) ~= "table" then return "Choice domain must be an array of options or a map of option to description" .. suffix end
        local count = dense_array(domain)
        if count then
            if count < 2 then return "Choice domain must declare at least two options" .. suffix end
            local names = {}
            for _, name in ipairs(domain) do
                if type(name) ~= "string" or name == "" then return "Choice domain options must be strings" .. suffix end
                if names[name] then return "Choice domain has duplicate option '" .. name .. "'" .. suffix end
                names[name] = true
            end
        else
            local total = 0
            for name, description in pairs(domain) do
                if type(name) ~= "string" or name == "" then
                    return "Choice domain must be a dense array or a map with nonempty string keys" .. suffix
                end
                if type(description) ~= "string" then return "Choice domain descriptions must be strings" .. suffix end
                total = total + 1
            end
            if total < 2 then return "Choice domain must declare at least two options" .. suffix end
        end
    elseif slot.type == "score" then
        local count = dense_array(domain)
        if not count or count < 2 then return "Score domain must be an ordered array of at least two level descriptions" .. suffix end
        for _, level in ipairs(domain) do
            if type(level) ~= "string" or level == "" then return "Score domain levels must be strings" .. suffix end
        end
    elseif domain ~= nil then
        if type(domain) ~= "table" then return "Predicate domain must be a table" .. suffix end
        for outcome, description in pairs(domain) do
            if outcome ~= "yes" and outcome ~= "no" then return "Predicate domain accepts only the keys yes and no" .. suffix end
            if type(description) ~= "string" then return "Predicate domain descriptions must be strings" .. suffix end
        end
    end
    return nil
end

function evaluation.validate(state, questions, model)
    if type(model) ~= "string" or model == "" then return "Model is required" end
    if type(questions) ~= "table" then return "Questions must be a table" end
    if next(questions) == nil then return "Questions must declare at least one slot" end
    if type(state) ~= "string" and type(state) ~= "table" then return "State must be a string or a table" end
    if not json_value(state, {}) then return "State must be JSON-compatible" end
    local count = 0
    for key, slot in pairs(questions) do
        if type(key) ~= "string" or key == "" then return "Question keys must be nonempty strings" end
        local err = validate_slot(key, slot)
        if err then return err end
        count = count + 1
    end
    if count == 0 then return "Questions must declare at least one slot" end
    return nil
end

return evaluation
