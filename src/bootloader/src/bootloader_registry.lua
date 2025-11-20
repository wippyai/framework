local registry = require("registry")

-- Base criteria for finding bootloaders
local BASE_BOOTLOADER_CRITERIA = {
    [".kind"] = "function.lua",
    ["meta.type"] = "bootloader",
}

local bootloaders = {}

-- Find all bootloaders with optional filtering
function bootloaders.find(options)
    options = options or {}

    local criteria = {}
    for k, v in pairs(BASE_BOOTLOADER_CRITERIA) do
        criteria[k] = v
    end

    local entries, err = registry.find(criteria)
    if err then
        return nil, "Failed to find bootloaders: " .. tostring(err)
    end

    if not entries or #entries == 0 then
        return {}
    end

    -- Sort by order (ascending), then by ID (alphabetical)
    table.sort(entries, function(a, b)
        local a_order = a.meta and a.meta.order or 999
        local b_order = b.meta and b.meta.order or 999

        if a_order ~= b_order then
            return a_order < b_order
        end

        return a.id < b.id
    end)

    return entries
end

-- Get specific bootloader by ID
function bootloaders.get(id)
    if not id or id == "" then
        return nil, "Bootloader ID is required"
    end

    local entry, err = registry.get(id)
    if err then
        return nil, "Failed to get bootloader: " .. tostring(err)
    end

    return entry
end

return bootloaders
