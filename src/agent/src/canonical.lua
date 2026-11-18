local json = require("json")

-- Serializes a JSON-shaped value with object keys in byte order, so equal values
-- always produce equal text and different values never do. Scalars are written
-- by the runtime JSON encoder, so the text matches what the wire encoder sends.
--
-- Accepted values:
--   - strings, booleans, finite numbers, json.null and nil (written as null);
--   - tables whose keys are all strings (objects);
--   - tables whose keys are all whole positive numbers (arrays). An array is
--     written up to its largest index, and a missing item (the JSON decoder
--     leaves one for null) is written as null. An empty table is [].
-- Everything else is refused instead of being replaced: functions, other
-- userdata, NaN and infinities, tables that mix string and number keys, keys
-- that are not strings or whole positive numbers, tables that contain
-- themselves, and arrays with more holes than MAX_HOLES allows.
local canonical = {}

-- An array may have as many missing items as it has items, and at least this
-- many. A table such as {[1e9] = 1} would otherwise expand to a billion nulls.
canonical.MAX_HOLES = 1024

local function refuse(message: string)
    error({ canonical = message }, 0)
end

local function write(value: any, out: {string}, active: {[any]: boolean})
    local kind = type(value)
    if kind == "table" then
        if active[value] then refuse("a table contains itself") end
        active[value] = true
        local string_keys, count, max_index = 0, 0, 0
        for key in pairs(value) do
            if type(key) == "string" then
                string_keys = string_keys + 1
            elseif type(key) == "number" and key >= 1 and key % 1 == 0 then
                -- The runtime does not always report array keys as integers
                -- through math.type, so a whole positive number is an index.
                count = count + 1
                if key > max_index then max_index = key end
            else
                refuse("a table key must be a string or a whole positive number, got "
                    .. type(key) .. " " .. tostring(key))
            end
        end
        if string_keys > 0 and count > 0 then refuse("a table mixes string and number keys") end
        if string_keys > 0 then
            local keys = {}
            for key in pairs(value) do keys[#keys + 1] = key end
            table.sort(keys)
            out[#out + 1] = "{"
            for index, key in ipairs(keys) do
                if index > 1 then out[#out + 1] = "," end
                write(key, out, active)
                out[#out + 1] = ":"
                write(value[key], out, active)
            end
            out[#out + 1] = "}"
        else
            local holes = max_index - count
            if holes > math.max(count, canonical.MAX_HOLES) then
                refuse("an array has " .. holes .. " holes and " .. count .. " items")
            end
            out[#out + 1] = "["
            for index = 1, max_index do
                if index > 1 then out[#out + 1] = "," end
                local item = value[index]
                if item == nil then out[#out + 1] = "null" else write(item, out, active) end
            end
            out[#out + 1] = "]"
        end
        active[value] = nil
        return
    end
    if kind == "nil" then
        out[#out + 1] = "null"
        return
    end
    if kind == "number" and (value ~= value or value == math.huge or value == -math.huge) then
        refuse("a number is not finite")
    end
    if kind ~= "string" and kind ~= "number" and kind ~= "boolean" and value ~= json.null then
        refuse("a " .. kind .. " value is not JSON")
    end
    local encoded = json.encode(value)
    if type(encoded) ~= "string" then refuse("the JSON encoder refused a " .. kind .. " value") end
    out[#out + 1] = encoded
end

-- Returns the canonical text, or nil and the reason the value is not JSON-shaped.
function canonical.try_encode(value: any): (string?, string?)
    local out: {string} = {}
    local ok, err = pcall(write, value, out, {})
    if not ok then
        if type(err) == "table" and err.canonical then return nil, tostring(err.canonical) end
        return nil, tostring(err)
    end
    return table.concat(out), nil
end

-- Returns the canonical text and raises an error for a value that is not
-- JSON-shaped. Values decoded from JSON always encode.
function canonical.encode(value: any): string
    local text, err = canonical.try_encode(value)
    if not text then error("canonical JSON: " .. tostring(err), 2) end
    return text
end

return canonical
