local registry = require("registry")
local contract = require("contract")

-- Main module
local providers = {
    _registry = registry,
    _contract = contract
}

local CONTRACT_ID = "wippy.llm:provider"

---------------------------
-- Provider Discovery Functions
---------------------------

-- Get all available providers
function providers.get_all()
    -- Find all provider entries from registry
    local entries, err = providers._registry.find({
        [".kind"] = "registry.entry",
        ["meta.type"] = "llm.provider"
    })

    if err then
        return nil, "Registry error: " .. err
    end

    if not entries then
        return {}
    end

    -- Pre-allocate table with known size to avoid extra allocations
    local all_providers = table.create(#entries, 0)

    -- Build provider info from entry.data (flattened YAML structure)
    for i, entry in ipairs(entries) do
        local provider_info = {
            id = entry.id,
            name = entry.meta and entry.meta.name or "",
            title = entry.meta and entry.meta.title or "",
            description = entry.meta and entry.meta.comment or "",
            driver_id = entry.data and entry.data.driver and entry.data.driver.id or ""
        }
        all_providers[i] = provider_info
    end

    -- Sort providers by name for consistency
    table.sort(all_providers, function(a, b)
        return (a.name or "") < (b.name or "")
    end)

    return all_providers
end

-- Open a provider and return contract instance
function providers.open(provider_id, context_overrides)
    if not provider_id then
        return nil, "Provider ID is required"
    end

    context_overrides = context_overrides or {}

    -- Get the specific provider by ID directly
    local provider_entry, err = providers._registry.get(provider_id)
    if err then
        return nil, "Registry error: " .. err
    end

    if not provider_entry then
        return nil, "Provider not found: " .. provider_id
    end

    -- Validate this is actually a provider entry
    if not provider_entry.meta or provider_entry.meta.type ~= "llm.provider" then
        return nil, "Entry is not a provider: " .. provider_id
    end

    -- Validate driver configuration from entry.data (flattened YAML)
    if not provider_entry.data or not provider_entry.data.driver or not provider_entry.data.driver.id then
        return nil, "Provider missing driver configuration: " .. provider_id
    end

    local binding_id = provider_entry.data.driver.id
    local base_options = provider_entry.data.driver.options or {}

    -- Merge base options with context overrides
    local final_context = {}
    for k, v in pairs(base_options) do
        final_context[k] = v
    end
    for k, v in pairs(context_overrides) do
        final_context[k] = v
    end

    -- Get the base provider contract using injected contract module
    local provider_contract, err = providers._contract.get(CONTRACT_ID)
    if err then
        return nil, "Failed to get provider contract: " .. err
    end

    -- Open the binding with merged context
    local instance, err = provider_contract
        :with_context(final_context)
        :open(binding_id)

    if err then
        return nil, "Failed to open provider binding: " .. err
    end

    return instance
end

return providers
