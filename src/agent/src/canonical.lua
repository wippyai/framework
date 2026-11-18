local json = require("json")

-- Serializes a JSON-shaped value with object keys in byte order, so equal values
-- always produce equal text. Different values never produce equal text, except
-- values the runtime JSON decoder or encoder already make equal: the decoder
-- drops null object members and trailing null array items, and the encoder
-- replaces invalid UTF-8 bytes with U+FFFD. Scalars are written by the runtime
-- JSON encoder, so the text matches what the wire encoder sends.
--
-- Accepted values:
--   - strings, booleans, finite numbers, json.null and nil (written as null);
--   - tables whose keys are all strings (objects);
--   - tables whose keys are all whole positive numbers (arrays). An array is
--     written up to its largest index, and a missing item (the JSON decoder
--     leaves one for null) is written as null;
--   - empty tables, which keep the runtime JSON encoder's choice of {} or [].
-- Everything else is refused instead of being replaced: functions, other
-- userdata, NaN and infinities, tables that mix string and number keys, keys
-- that are not strings or whole positive numbers, tables that contain
-- themselves, and arrays whose largest index is above MAX_INDEX when more than
-- half of the indexes from 1 to that index are missing.
--
-- The encoder walks the value with its own stack instead of recursion, so the
-- deepest JSON the runtime decoder accepts never reaches the Lua call limit.
local canonical = {}

-- An array is refused when its largest index is above this and more than half
-- of the indexes from 1 to that index are missing, so a Lua table such as
-- {[1e9] = 1} cannot expand to a billion nulls. For decoded JSON this needs one
-- array of more than MAX_INDEX items with more than half of them null.
canonical.MAX_INDEX = 1000000

local function refuse(message: string)
    error({ canonical = message }, 0)
end

local function scalar(value: any, out: {string})
    local kind = type(value)
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

-- Writes the opening of a table and returns the frame that walks its items,
-- or nil when the table is empty and already written.
local function open(value: table, out: {string}, active: {[any]: boolean}): table?
    if active[value] then refuse("a table contains itself") end
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
    if string_keys == 0 and count == 0 then
        -- Only the runtime encoder knows whether an empty table is an object.
        local encoded = json.encode(value)
        if encoded ~= "{}" and encoded ~= "[]" then refuse("the JSON encoder refused an empty table") end
        out[#out + 1] = encoded
        return nil
    end
    active[value] = true
    if string_keys > 0 then
        local keys = {}
        for key in pairs(value) do keys[#keys + 1] = key end
        table.sort(keys)
        out[#out + 1] = "{"
        return { value = value, keys = keys, size = #keys, index = 0, close = "}" }
    end
    if max_index > canonical.MAX_INDEX and max_index - count > count then
        refuse("an array has index " .. max_index .. " but only " .. count .. " items")
    end
    out[#out + 1] = "["
    return { value = value, size = max_index, index = 0, close = "]" }
end

local function write(root: any, out: {string})
    if type(root) ~= "table" then
        scalar(root, out)
        return
    end
    local active: {[any]: boolean} = {}
    local stack: {table} = {}
    local first = open(root, out, active)
    if first then stack[1] = first end
    while #stack > 0 do
        local frame = stack[#stack]
        frame.index = frame.index + 1
        if frame.index > frame.size then
            out[#out + 1] = frame.close
            active[frame.value] = nil
            stack[#stack] = nil
        else
            if frame.index > 1 then out[#out + 1] = "," end
            local child
            if frame.keys then
                local key = frame.keys[frame.index]
                scalar(key, out)
                out[#out + 1] = ":"
                child = frame.value[key]
            else
                child = frame.value[frame.index]
            end
            if type(child) == "table" then
                local nested = open(child, out, active)
                if nested then stack[#stack + 1] = nested end
            else
                scalar(child, out)
            end
        end
    end
end

-- Returns the canonical text, or nil and the reason the value is not JSON-shaped.
function canonical.try_encode(value: any): (string?, string?)
    local out: {string} = {}
    local ok, err = pcall(write, value, out)
    if not ok then
        if type(err) == "table" and err.canonical then return nil, tostring(err.canonical) end
        return nil, tostring(err)
    end
    return table.concat(out), nil
end

-- Returns the canonical text and raises an error for a value that is not
-- JSON-shaped. A value decoded from JSON is refused only when one array has
-- more than MAX_INDEX items and more than half of them are null.
function canonical.encode(value: any): string
    local text, err = canonical.try_encode(value)
    if not text then error("canonical JSON: " .. tostring(err), 2) end
    return text
end

return canonical
