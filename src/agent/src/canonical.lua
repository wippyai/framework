local json = require("json")

-- Serializes a value with object keys in sorted order, so equal values always
-- produce equal text. Array indices are written as keys, which keeps sparse
-- tables unambiguous.
local canonical = {}

function canonical.encode(value: any): string
    if type(value) ~= "table" then return json.encode(value) or "null" end
    local keys, out = {}, {}
    for key in pairs(value) do keys[#keys+1] = tostring(key) end
    table.sort(keys)
    for _, key in ipairs(keys) do
        local child = value[key]
        if child == nil then child = value[tonumber(key)] end
        out[#out+1] = (json.encode(key) or '""') .. ":" .. canonical.encode(child)
    end
    return "{" .. table.concat(out, ",") .. "}"
end

return canonical
