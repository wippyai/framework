local registry = require("registry")

-- Main module
local traits = {}

-- Allow for registry injection for testing
traits._registry = nil

-- Get registry - use injected registry or require it
local function get_registry()
    return traits._registry or registry
end

---------------------------
-- Constants
---------------------------

-- Trait type identifier
traits.TRAIT_TYPE = "agent.trait"

---------------------------
-- Trait Discovery Functions
---------------------------

-- Get trait by ID
function traits.get_by_id(trait_id)
    if not trait_id then
        return nil, "Trait ID is required"
    end

    -- Get trait directly from registry using the getter function
    local reg = get_registry()

    local entry, err = reg.get(trait_id)
    if not entry then
        return nil, "No trait found with ID: " .. tostring(trait_id) .. ", error: " .. tostring(err)
    end

    -- Verify it's a trait
    if not entry.meta or entry.meta.type ~= traits.TRAIT_TYPE then
        return nil, "Entry is not a trait: " .. tostring(trait_id)
    end

    -- Return trait spec
    return {
        id = entry.id,
        name = (entry.meta and entry.meta.name) or "",
        description = (entry.meta and entry.meta.comment) or "",
        prompt = (entry.data and entry.data.prompt) or ""
    }
end

-- Get trait by name
function traits.get_by_name(name)
    if not name then
        return nil, "Trait name is required"
    end

    -- Find traits with matching name directly from registry using the getter function
    local reg = get_registry()
    local entries = reg.find({
        [".kind"] = "registry.entry",
        ["meta.type"] = traits.TRAIT_TYPE,
        ["meta.name"] = name
    })

    if not entries or #entries == 0 then
        return nil, "No trait found with name: " .. name
    end

    -- Return the first match
    local entry = entries[1]
    return {
        id = entry.id,
        name = (entry.meta and entry.meta.name) or "",
        description = (entry.meta and entry.meta.comment) or "",
        prompt = (entry.data and entry.data.prompt) or ""
    }
end

-- Get all available traits
function traits.get_all()
    -- Find all traits from registry using the getter function
    local reg = get_registry()
    local entries = reg.find({
        [".kind"] = "registry.entry",
        ["meta.type"] = traits.TRAIT_TYPE
    })

    if not entries or #entries == 0 then
        return {}
    end

    -- Build trait specs
    local trait_specs = {}
    for _, entry in ipairs(entries) do
        table.insert(trait_specs, {
            id = entry.id,
            name = (entry.meta and entry.meta.name) or "",
            description = (entry.meta and entry.meta.comment) or "",
            prompt = (entry.data and entry.data.prompt) or ""
        })
    end

    return trait_specs
end

return traits