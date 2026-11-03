-- Structural equality of two values: tables compare key by key, recursively.
local function deep_equal(a: any, b: any): boolean
    if type(a) ~= "table" or type(b) ~= "table" then
        return a == b
    end
    for key, value in pairs(a) do
        if not deep_equal(value, b[key]) then
            return false
        end
    end
    for key in pairs(b) do
        if a[key] == nil then
            return false
        end
    end
    return true
end

return deep_equal
