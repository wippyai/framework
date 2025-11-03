local time = require("time")
local registry = require("base_registry")

-- Base criteria for identifying migration entries in the registry
local BASE_MIGRATION_CRITERIA = {
    [".kind"] = "function.lua",
    ["meta.type"] = "migration",
}

local migrations = {}

-- Find migrations in registry based on provided options
function migrations.find(options)
    options = options or {}

    -- Start with base criteria
    local criteria = {}
    for k, v in pairs(BASE_MIGRATION_CRITERIA) do
        criteria[k] = v
    end

    -- Apply filtering options
    if options.target_db then
        criteria["meta.target_db"] = options.target_db
    end

    if options.tags and #options.tags > 0 then
        criteria["meta.tags"] = options.tags
    end

    -- Query the registry
    local entries, err = registry.find(criteria)
    if err then
        return nil, "Failed to find migrations: " .. err
    end

    if not entries or #entries == 0 then
        return {}
    end

    -- Sort entries by timestamp (ascending)
    table.sort(entries, function(a, b)
        local a_time = a.meta and a.meta.timestamp or ""
        local b_time = b.meta and b.meta.timestamp or ""
        return a_time < b_time
    end)

    return entries
end

-- Get specific migration by ID
function migrations.get(id)
    if not id or id == "" then
        return nil, "Migration ID is required"
    end

    local entry, err = registry.get(id)
    if err then
        return nil, "Failed to get migration: " .. err
    end

    return entry
end

-- Get all target databases used in migrations
function migrations.get_target_dbs()
    -- Find all migration entries using the base criteria
    local entries, err = registry.find(BASE_MIGRATION_CRITERIA)

    if err then
        return nil, "Failed to query registry: " .. err
    end

    if not entries or #entries == 0 then
        return {}
    end

    -- Extract unique target databases
    local target_dbs = {}
    for _, entry in ipairs(entries) do
        if entry.meta and entry.meta.target_db then
            target_dbs[entry.meta.target_db] = true
        end
    end

    -- Convert to sorted array
    local result = {}
    for db in pairs(target_dbs) do
        table.insert(result, db)
    end

    table.sort(result)
    return result
end

-- Get all tags used in migrations
function migrations.get_tags()
    -- Find all migration entries using the base criteria
    local entries, err = registry.find(BASE_MIGRATION_CRITERIA)

    if err then
        return nil, "Failed to query registry: " .. err
    end

    if not entries or #entries == 0 then
        return {}
    end

    -- Extract unique tags
    local tags_map = {}
    for _, entry in ipairs(entries) do
        if entry.meta and entry.meta.tags then
            for _, tag in ipairs(entry.meta.tags) do
                tags_map[tag] = true
            end
        end
    end

    -- Convert to sorted array
    local result = {}
    for tag in pairs(tags_map) do
        table.insert(result, tag)
    end

    table.sort(result)
    return result
end

return migrations
