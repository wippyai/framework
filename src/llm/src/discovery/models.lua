local registry = require("registry")

-- Main module
local models = {}

-- Allow for registry injection for testing
models._registry = registry

---------------------------
-- Model Discovery Functions
---------------------------

-- Find a model by its name
function models.get_by_name(name)
    if not name then
        return nil, "Model name is required"
    end

    -- Find models with matching name
    local entries, err = models._registry.find({
        [".kind"] = "registry.entry",
        ["meta.type"] = "llm.model",
        ["meta.name"] = name
    })

    if err then
        return nil, "Registry error: " .. err
    end

    if not entries or #entries == 0 then
        return nil, "No model found with name: " .. name
    end

    return models._build_model_card(entries[1])
end

-- Get models by class with priority sorting
function models.get_by_class(class_name)
    if not class_name then
        return nil, "Class name is required"
    end

    -- Find all models
    local entries, err = models._registry.find({
        [".kind"] = "registry.entry",
        ["meta.type"] = "llm.model"
    })

    if err then
        return nil, "Registry error: " .. err
    end

    if not entries then
        return {}
    end

    -- Filter models that belong to the specified class
    local matching_models = {}
    for _, entry in ipairs(entries) do
        local classes = (entry.meta and entry.meta.class) or {}
        for _, model_class in ipairs(classes) do
            if model_class == class_name then
                local model_card = models._build_model_card(entry)
                if model_card then
                    table.insert(matching_models, model_card)
                end
                break
            end
        end
    end

    -- Sort by priority (descending - higher priority first)
    table.sort(matching_models, function(a, b)
        local priority_a = a.priority or 0
        local priority_b = b.priority or 0
        return priority_a > priority_b
    end)

    return matching_models
end

-- Get all available models
function models.get_all()
    -- Find all model entries from registry
    local entries, err = models._registry.find({
        [".kind"] = "registry.entry",
        ["meta.type"] = "llm.model"
    })

    if err then
        return nil, "Registry error: " .. err
    end

    if not entries then
        return {}
    end

    local all_models = {}

    -- Build model cards
    for _, entry in ipairs(entries) do
        local model_card = models._build_model_card(entry)
        if model_card then
            table.insert(all_models, model_card)
        end
    end

    -- Sort models by name for consistency
    table.sort(all_models, function(a, b)
        return a.name < b.name
    end)

    return all_models
end

-- Get all available classes with basic info
function models.get_all_classes()
    -- Find all class entries from registry
    local entries, err = models._registry.find({
        [".kind"] = "registry.entry",
        ["meta.type"] = "llm.model.class"
    })

    if err then
        return nil, "Registry error: " .. err
    end

    if not entries then
        return {}
    end

    local all_classes = {}

    -- Extract class info from registry entries
    for _, entry in ipairs(entries) do
        if entry.meta then
            local class_info = {
                id = entry.id or entry.name,
                name = entry.meta.name,
                title = entry.meta.title,
                description = entry.meta.comment
            }
            table.insert(all_classes, class_info)
        end
    end

    -- Sort classes by name for consistency
    table.sort(all_classes, function(a, b)
        return (a.name or "") < (b.name or "")
    end)

    return all_classes
end

---------------------------
-- Utility Functions
---------------------------

-- Build a model card from a registry entry
function models._build_model_card(entry)
    if not entry then
        return nil
    end

    -- Build model card from registry entry structure
    local model_card = {
        id = entry.id or "",
        name = entry.meta and entry.meta.name or "",
        title = entry.meta and entry.meta.title or "",
        description = entry.meta and entry.meta.comment or "",
        capabilities = entry.meta and entry.meta.capabilities or {},
        class = entry.meta and entry.meta.class or {},
        priority = entry.meta and entry.meta.priority or 0,
        max_tokens = entry.data and entry.data.max_tokens or 0,
        output_tokens = entry.data and entry.data.output_tokens or 0,
        pricing = entry.data and entry.data.pricing or {},
        providers = entry.data and entry.data.providers or {}
    }

    -- Add any additional fields that might be directly in entry.data
    if entry.data and entry.data.dimensions then
        model_card.dimensions = entry.data.dimensions
    end

    return model_card
end

return models