local registry = require("base_registry")

type MigrationEntry = {
    id: string,
    kind: string,
    meta: {[string]: any},
}

type FindOptions = {
    target_db: string?,
    tags: {string}?,
}

-- Base criteria for identifying migration entries in the registry
local BASE_MIGRATION_CRITERIA = {
    [".kind"] = "function.*",
    ["meta.type"] = "migration",
}

local migrations = {}

migrations._registry = registry

-- Find migrations in registry based on provided options
function migrations.find(options: any?): ({MigrationEntry}?, string?)
    local opts = options or {}

    -- Start with base criteria
    local criteria = {}
    for k, v in pairs(BASE_MIGRATION_CRITERIA) do
        criteria[k] = v
    end

    -- Apply filtering options
    if opts.target_db then
        criteria["meta.target_db"] = opts.target_db
    end

    if opts.tags and #opts.tags > 0 then
        criteria["meta.tags"] = opts.tags
    end

    -- Query the registry
    local entries, err = migrations._registry.find(criteria)
    if err then
        return nil, "Failed to find migrations: " .. tostring(err)
    end

    if not entries or #entries == 0 then
        return {}
    end

    -- Sort entries by timestamp (ascending)
    table.sort(entries, function(a: MigrationEntry, b: MigrationEntry): boolean
        local a_time = a.meta and a.meta.timestamp or ""
        local b_time = b.meta and b.meta.timestamp or ""
        return a_time < b_time
    end)

    return entries
end

-- Get specific migration by ID
function migrations.get(id: string): (MigrationEntry?, string?)
    if not id or id == "" then
        return nil, "Migration ID is required"
    end

    local entry, err = migrations._registry.get(id)
    if err then
        return nil, "Failed to get migration: " .. tostring(err)
    end

    return entry
end

-- Get all target databases used in migrations
function migrations.get_target_dbs(): ({string}?, string?)
    -- Find all migration entries using the base criteria
    local entries, err = migrations._registry.find(BASE_MIGRATION_CRITERIA)

    if err then
        return nil, "Failed to query registry: " .. tostring(err)
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
function migrations.get_tags(): ({string}?, string?)
    -- Find all migration entries using the base criteria
    local entries, err = migrations._registry.find(BASE_MIGRATION_CRITERIA)

    if err then
        return nil, "Failed to query registry: " .. tostring(err)
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
