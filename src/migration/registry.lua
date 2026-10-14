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

local function migration_timestamp(entry: any): string
    local meta = entry and entry.meta
    if type(meta) ~= "table" or meta.timestamp == nil then
        return ""
    end
    return tostring(meta.timestamp)
end

-- Timestamp is optional. Full id is the deterministic tie-breaker so legacy
-- migrations without timestamps still run in a stable, inspectable order.
function migrations.compare(a: any, b: any): boolean
    local a_time = migration_timestamp(a)
    local b_time = migration_timestamp(b)
    if a_time ~= b_time then
        return a_time < b_time
    end
    return tostring(a and a.id or "") < tostring(b and b.id or "")
end

function migrations.get_aliases(entry: any): {string}
    local meta = entry and entry.meta
    if type(meta) ~= "table" or meta.alias == nil then
        return {}
    end

    local candidates: any
    if type(meta.alias) == "string" then
        candidates = { meta.alias }
    elseif type(meta.alias) == "table" then
        candidates = meta.alias
    else
        return {}
    end

    local own_id = tostring(entry and entry.id or "")
    local seen = {}
    local result = {}
    for _, alias in ipairs(candidates) do
        if type(alias) == "string" and alias ~= "" and alias ~= own_id and not seen[alias] then
            seen[alias] = true
            table.insert(result, alias)
        end
    end

    return result
end

function migrations.validate_aliases(entries: {any}?): (boolean?, string?)
    local by_id = {}
    for _, entry in ipairs(entries or {}) do
        by_id[tostring(entry.id)] = entry
    end

    local claimed_by = {}
    for _, entry in ipairs(entries or {}) do
        local raw = entry.meta and entry.meta.alias
        if raw ~= nil then
            local values: any = type(raw) == "string" and {raw} or raw
            if type(values) ~= "table" then
                return nil, "alias on migration '" .. tostring(entry.id) .. "' must be a string or an array of strings"
            end
            local count = 0
            for index, alias in pairs(values) do
                count = count + 1
                if type(index) ~= "number" or index < 1 or index > #values or index % 1 ~= 0
                    or type(alias) ~= "string" or #alias > 512
                    or not alias:match("^[^:%s]+:[^:%s]+$") then
                    return nil, "alias '" .. tostring(alias) .. "' on migration '" .. tostring(entry.id)
                        .. "' must contain full ids in namespace:name form (at most 512 characters)"
                end
                if alias == entry.id then
                    return nil, "alias '" .. alias .. "' collides with its own migration id"
                end
            end
            if count ~= #values then
                return nil, "alias on migration '" .. tostring(entry.id) .. "' must be a contiguous array"
            end
        end
        for _, alias in ipairs(migrations.get_aliases(entry)) do
            if by_id[alias] then
                return nil, "alias '" .. alias .. "' on migration '" .. tostring(entry.id)
                    .. "' collides with an existing migration id"
            end
            if claimed_by[alias] then
                return nil, "alias '" .. alias .. "' is claimed by both '"
                    .. tostring(claimed_by[alias].id) .. "' and '" .. tostring(entry.id) .. "'"
            end
            claimed_by[alias] = entry
        end
    end

    return true
end

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

    table.sort(entries, migrations.compare)

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
    local target_dbs: {[string]: boolean} = {}
    for _, entry in ipairs(entries) do
        local target_db = entry.meta and entry.meta.target_db
        if type(target_db) == "string" then
            target_dbs[target_db] = true
        end
    end

    -- Convert to sorted array
    local result: {string} = {}
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
    local tags_map: {[string]: boolean} = {}
    for _, entry in ipairs(entries) do
        if entry.meta and entry.meta.tags then
            for _, tag in ipairs(entry.meta.tags) do
                if type(tag) == "string" then
                    tags_map[tag] = true
                end
            end
        end
    end

    -- Convert to sorted array
    local result: {string} = {}
    for tag in pairs(tags_map) do
        table.insert(result, tag)
    end

    table.sort(result)
    return result
end

return migrations
