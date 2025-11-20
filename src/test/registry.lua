local registry = require("base_registry")
local time = require("time")

local test_registry = {}

-- Find test entries in registry
function test_registry.find(options)
    options = options or {}

    local criteria = {
        ["meta.type"] = options.type or "test",
    }

    -- Apply group filter if provided
    if options.group then
        criteria["meta.group"] = options.group
    end

    -- Get registry snapshot
    local snapshot, err = registry.snapshot()
    if err then
        return nil, "Failed to get registry snapshot: " .. tostring(err)
    end

    -- Find test entries
    local entries = snapshot:find(criteria)

    -- Process and transform test entries
    local tests = {}
    for i, entry in ipairs(entries) do
        local meta = entry.meta or {}
        local display_name = meta.name or ("Unnamed test " .. i)
        local group = meta.group or "default"

        table.insert(tests, {
            id = entry.id,
            name = display_name,
            group = group,
            meta = meta
        })
    end

    -- Sort tests by group and name
    table.sort(tests, function(a, b)
        if a.group ~= b.group then
            return a.group < b.group
        else
            return a.name < b.name
        end
    end)

    return tests
end

-- Get specific test by ID
function test_registry.get(id)
    local entry = registry.get(id)
    if not entry then
        return nil, "Test not found: " .. id
    end

    local meta = entry.meta or {}
    return {
        id = entry.id,
        name = meta.name or "Unnamed test",
        group = meta.group or "default",
        meta = meta
    }
end

-- Get all test groups
function test_registry.get_groups()
    local entries = registry.find({
        ["meta.type"] = "test"
    })

    local groups = {}
    for _, entry in ipairs(entries) do
        if entry.meta and entry.meta.group then
            groups[entry.meta.group] = true
        else
            groups["default"] = true
        end
    end

    local result = {}
    for group in pairs(groups) do
        table.insert(result, group)
    end

    table.sort(result)
    return result
end

-- Get all tests in a specific group
function test_registry.get_by_group(group)
    if not group then
        return nil, "Group name is required"
    end

    return test_registry.find({ ["meta.group"] = group })
end

return test_registry
