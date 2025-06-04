local registry = require("registry")

-- Main module
local models = {}

-- Allow for registry injection for testing
models._registry = nil

-- Get registry - use injected registry or require it
local function get_registry()
    return models._registry or registry
end

---------------------------
-- Constants
---------------------------

-- Model capability identifiers
models.CAPABILITY = {
    TOOL_USE = "tool_use",       -- Tool calling capability
    VISION = "vision",           -- Image/visual input capability
    THINKING = "thinking",       -- Extended thinking/reasoning
    CACHING = "caching",         -- Response caching capability
    MULTILINGUAL = "multilingual" -- Support for multiple languages
}

---------------------------
-- Model Discovery Functions
---------------------------

-- Find a model by its name
function models.get_by_name(name)
    if not name then
        return nil, "Model name is required"
    end

    local reg = get_registry()

    -- Find models with matching name
    local entries = reg.find({
        [".kind"] = "registry.entry",
        ["meta.name"] = name
    })

    if not entries or #entries == 0 then
        return nil, "No model found with name: " .. name
    end

    return models._build_model_card(entries[1])
end

-- Get all available models
function models.get_all()
    local reg = get_registry()

    -- !todo: optimize
    -- Find all model entries from registry
    local entries = reg.find({
        [".kind"] = "registry.entry",
    })

    local all_models = {}

    -- Filter entries to only include models and build model cards
    for _, entry in ipairs(entries) do
        if entry.meta and (entry.meta.type == "llm.model" or entry.meta.type == "llm.embedding") then
            local model_card = models._build_model_card(entry)
            table.insert(all_models, model_card)
        end
    end

    -- Sort models by name for consistency
    table.sort(all_models, function(a, b)
        return a.name < b.name
    end)

    return all_models
end

-- Get models grouped by provider
function models.get_by_provider()
    local all_models = models.get_all()
    local providers = {}

    -- Group models by provider
    for _, model in ipairs(all_models) do
        local provider = "unknown"
        if model.handlers and model.handlers.generate then
            -- Extract provider from handler path (e.g., "wippy.llm.openai:text_generation" -> "openai")
            local provider_match = model.handlers.generate:match("wippy%.llm%.([^:]+):")
            if provider_match then
                provider = provider_match
            end
        elseif model.handlers and model.handlers.embeddings then
            local provider_match = model.handlers.embeddings:match("wippy%.llm%.([^:]+):")
            if provider_match then
                provider = provider_match
            end
        end

        if not providers[provider] then
            providers[provider] = {
                name = provider,
                models = {}
            }
        end

        table.insert(providers[provider].models, model)
    end

    -- Convert providers map to array and sort
    local grouped_providers = {}
    for _, provider in pairs(providers) do
        -- Sort models within each provider
        table.sort(provider.models, function(a, b)
            return a.name < b.name
        end)
        table.insert(grouped_providers, provider)
    end

    -- Sort providers by name
    table.sort(grouped_providers, function(a, b)
        return a.name < b.name
    end)

    return grouped_providers
end

---------------------------
-- Utility Functions
---------------------------

-- Build a model card from a registry entry
function models._build_model_card(entry)
    -- All model information is stored in the "data" field
    local data = entry.data or {}

    -- Start with a complete default structure
    local model_card = {
        id = entry.id or "",
        name = (entry.meta and entry.meta.name) or (data.meta and data.meta.name) or "",
        title = (entry.meta and entry.meta.title) or (data.meta and data.meta.title) or "",
        provider_model = data.provider_model or "",
        description = (entry.meta and entry.meta.comment) or (data.meta and data.meta.comment) or "",
        capabilities = (entry.meta and entry.meta.capabilities) or (data.meta and data.meta.capabilities) or {},
        max_tokens = data.max_tokens or 0,
        output_tokens = data.output_tokens or 0,
        pricing = data.pricing or {},
        handlers = data.handlers or {},
        provider_options = data.provider_options or {}
    }

    -- Add any additional metadata that might be useful
    -- First check data.meta, then check entry.meta
    local meta = data.meta or entry.meta or {}

    if meta.knowledge_cutoff then
        model_card.knowledge_cutoff = meta.knowledge_cutoff
    end

    if meta.mteb_performance then
        model_card.mteb_performance = meta.mteb_performance
    end

    if meta.model_family then
        model_card.model_family = meta.model_family
    end

    if meta.type then
        model_card.type = meta.type
    end

    -- Some fields might be directly in data instead of in meta
    if data.dimensions then
        model_card.dimensions = data.dimensions
    end

    if data.model_family then
        model_card.model_family = data.model_family
    end

    if data.knowledge_cutoff then
        model_card.knowledge_cutoff = data.knowledge_cutoff
    end

    if data.mteb_performance then
        model_card.mteb_performance = data.mteb_performance
    end

    return model_card
end

return models