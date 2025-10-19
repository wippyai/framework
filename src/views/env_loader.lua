local registry = require("registry")
local env = require("env")

local env_loader = {}

-- Framework priority conventions
local PRIORITY_CONVENTIONS = table.freeze({
    FRAMEWORK_DEFAULTS = table.freeze({min = 0, max = 9}),
    SYSTEM_OVERRIDES = table.freeze({min = 10, max = 19}),
    APPLICATION_MAPPINGS = table.freeze({min = 20, max = 29}),
    ENVIRONMENT_OVERRIDES = table.freeze({min = 30, max = 100})
})

-- Load all view.env_mapping entries from registry
function env_loader.load_mappings(filter)
    local mappings_data = {}

    -- Build registry query
    local query = {
        meta = {
            type = "view.env_mapping"
        }
    }

    -- Apply optional filter
    if filter then
        for key, value in pairs(filter) do
            query[key] = value
        end
    end

    -- Find all entries with meta.type = "view.env_mapping"
    local entries, err = registry.find(query)

    if err then
        return nil, "Failed to find env_mapping entries: " .. err
    end

    if not entries then
        return {}, nil
    end

    -- Process each entry
    for _, entry in ipairs(entries) do
        local mapping_data = {
            id = entry.id,
            priority = (entry.meta and entry.meta.priority) or 0,
            mappings = {}
        }

        -- Extract mappings from entry.data (registry wraps content in data field)
        if entry.data and entry.data.mappings then
            mapping_data.mappings = entry.data.mappings
        end

        -- Validate priority range
        if mapping_data.priority < 0 or mapping_data.priority > 100 then
            return nil, "Invalid priority " .. mapping_data.priority .. " for entry " .. mapping_data.id ..
                       " (must be 0-100)"
        end

        table.insert(mappings_data, mapping_data)
    end

    return mappings_data, nil
end

-- Build environment context by merging mappings with priority
function env_loader.build_env_context(mappings_data)
    if not mappings_data then
        return {}, nil
    end

    -- Sort by priority (ascending order so higher priority overrides)
    table.sort(mappings_data, function(a, b)
        return a.priority < b.priority
    end)

    local context = {}

    -- Merge mappings in priority order
    for _, mapping_data in ipairs(mappings_data) do
        if mapping_data.mappings then
            for context_key, env_var in pairs(mapping_data.mappings) do
                context[context_key] = env_var
            end
        end
    end

    return context, nil
end

-- Get complete environment context for views
function env_loader.get_env_context(filter)
    local mappings_data, err = env_loader.load_mappings(filter)
    if err then
        return nil, "Failed to load mappings: " .. err
    end

    local context, err = env_loader.build_env_context(mappings_data)
    if err then
        return nil, "Failed to build context: " .. err
    end

    return context, nil
end

-- Resolve environment variable values from context
function env_loader.resolve_env_values(context)
    if not context then
        return {}, nil
    end

    local resolved = {}

    for context_key, env_var in pairs(context) do
        local value = env.get(env_var)
        if value then
            resolved[context_key] = value
        end
    end

    return resolved, nil
end

-- Complete workflow: load mappings and resolve values
function env_loader.get_resolved_env(filter)
    local context, err = env_loader.get_env_context(filter)
    if err then
        return nil, err
    end

    local resolved, err = env_loader.resolve_env_values(context)
    if err then
        return nil, "Failed to resolve environment values: " .. err
    end

    return resolved, nil
end

-- Framework utility: Get priority conventions
function env_loader.get_priority_conventions()
    return PRIORITY_CONVENTIONS
end

-- Framework utility: Validate priority against conventions
function env_loader.validate_priority(priority, category)
    if not priority or type(priority) ~= "number" then
        return false, "Priority must be a number"
    end

    if priority < 0 or priority > 100 then
        return false, "Priority must be between 0 and 100"
    end

    if category then
        local conv = PRIORITY_CONVENTIONS[category]
        if conv and (priority < conv.min or priority > conv.max) then
            return false, "Priority " .. priority .. " outside " .. category ..
                         " range (" .. conv.min .. "-" .. conv.max .. ")"
        end
    end

    return true, nil
end

-- Framework utility: Get recommended priority for category
function env_loader.get_recommended_priority(category)
    local conv = PRIORITY_CONVENTIONS[category]
    if not conv then
        return nil, "Unknown category: " .. tostring(category)
    end

    return conv.min, nil
end

-- Contract interface: Load mappings (contract-compatible)
function env_loader.contract_load_mappings(params)
    local filter = params and params.filter or nil
    local mappings, err = env_loader.load_mappings(filter)

    if err then
        return {
            success = false,
            error = err
        }
    end

    return {
        success = true,
        mappings = mappings
    }
end

-- Contract interface: Resolve environment values (contract-compatible)
function env_loader.contract_resolve_env_values(params)
    if not params or not params.context then
        return {
            success = false,
            error = "Missing required parameter: context"
        }
    end

    local resolved, err = env_loader.resolve_env_values(params.context)

    if err then
        return {
            success = false,
            error = err
        }
    end

    return {
        success = true,
        resolved = resolved
    }
end

return env_loader
