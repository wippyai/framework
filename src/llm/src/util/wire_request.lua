local wire_request = {}

local function is_map(value: any): boolean
    return type(value) == "table" and #value == 0
end

local function copy(value: any): any
    if type(value) ~= "table" then return value end
    local out = {}
    for key, item in pairs(value) do out[key] = copy(item) end
    return out
end

-- A new table holding `base` with `overlay` merged on top: maps merge
-- recursively, every other value replaces. Neither input is written to.
local function merged(base: any, overlay: any): table
    local out = {}
    for key, value in pairs(base) do out[key] = value end
    for key, value in pairs(overlay) do
        if is_map(value) and is_map(out[key]) then
            out[key] = merged(out[key], value)
        else
            out[key] = copy(value)
        end
    end
    return out
end

-- Deep-merges a declarative options.request into a driver's mapped wire body,
-- after every contract option is mapped, so request values win on conflict.
-- `reserved` lists the wire keys the driver builds structurally; a request
-- naming one of them is an error naming that key.
function wire_request.apply(body: table, request: any, reserved: {string}): string?
    if request == nil then return nil end
    if not is_map(request) then
        return "options.request must be an object of provider wire fields"
    end
    for _, key in ipairs(reserved) do
        if request[key] ~= nil then
            return "options.request." .. key .. " is built by the driver and cannot be set"
        end
    end
    for key, value in pairs(request) do
        if is_map(value) and is_map(body[key]) then
            body[key] = merged(body[key], value)
        else
            body[key] = copy(value)
        end
    end
    return nil
end

return wire_request
