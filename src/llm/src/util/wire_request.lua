local wire_request = {}

local function is_map(value: any): boolean
    return type(value) == "table" and #value == 0
end

-- Empty tables are shared, not copied: a fresh table would lose an empty
-- object's shape and encode as []; nothing writes into a merged body's
-- nested tables after the merge.
local function copy(value: any): any
    if type(value) ~= "table" or next(value) == nil then return value end
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

local function names_path(request: table, path: string): boolean
    local node: any = request
    for segment in string.gmatch(path, "[^.]+") do
        if type(node) ~= "table" then return false end
        node = node[segment]
        if node == nil then return false end
    end
    return true
end

-- Deep-merges a declarative options.request into a driver's mapped wire body,
-- after every contract option is mapped, so request values win on conflict.
-- `reserved` lists the wire fields the handler builds structurally, as keys or
-- dotted paths; a request naming one of them is an error naming that field.
function wire_request.apply(body: table, request: any, reserved: {string}): string?
    if request == nil then return nil end
    if not is_map(request) then
        return "options.request must be an object of provider wire fields"
    end
    for _, path in ipairs(reserved) do
        if names_path(request, path) then
            return "options.request." .. path .. " is built by the driver and cannot be set"
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
