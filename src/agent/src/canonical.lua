local json = require("json")

-- Serializes a value with object keys in sorted order, so equal values always
-- produce equal text. Tables keep the array/object shape used by the wire encoder.
local canonical = {}

function canonical.encode(value: any): string
    if type(value) ~= "table" then return json.encode(value) or "null" end
    local keys, out = {}, {}
    local encoded = json.encode(value)
    if encoded and encoded:sub(1, 1) == "[" then
        for _, child in ipairs(value) do out[#out+1] = canonical.encode(child) end
        return "[" .. table.concat(out, ",") .. "]"
    end
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
