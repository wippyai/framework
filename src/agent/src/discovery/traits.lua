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
-- Helper Functions
---------------------------

-- Process tools array to handle both old and new formats
local function process_tools(tools_data)
    if not tools_data or #tools_data == 0 then
        return {}
    end

    local tools_count = #tools_data
    local processed_tools = table.create(tools_count, 0)
    local output_index = 1

    for _, tool_def in ipairs(tools_data) do
        local tool_entry = nil

        if type(tool_def) == "string" then
            -- Old format: "tool:id"
            tool_entry = table.create(0, 1)
            tool_entry.id = tool_def
        elseif type(tool_def) == "table" and tool_def.id then
            -- Enhanced format with optional description/alias/context
            tool_entry = table.create(0, 4)
            tool_entry.id = tool_def.id

            if tool_def.context and next(tool_def.context) ~= nil then
                tool_entry.context = tool_def.context
            end

            if tool_def.description then
                tool_entry.description = tool_def.description
            end

            if tool_def.alias then
                tool_entry.alias = tool_def.alias
            end
        end

        if tool_entry then
            processed_tools[output_index] = tool_entry
            output_index = output_index + 1
        end
    end

    -- If we filtered out some tools, resize the array
    if output_index <= tools_count then
        local final_tools = table.create(output_index - 1, 0)
        for i = 1, output_index - 1 do
            final_tools[i] = processed_tools[i]
        end
        return final_tools
    end

    return processed_tools
end

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

    -- Process tools to handle both formats
    local processed_tools = process_tools(entry.data and entry.data.tools)

    -- Build trait spec
    local trait_spec = table.create(0, 9)
    trait_spec.id = entry.id
    trait_spec.name = (entry.meta and entry.meta.name) or ""
    trait_spec.description = (entry.meta and entry.meta.comment) or ""
    trait_spec.prompt = (entry.data and entry.data.prompt) or ""
    trait_spec.tools = processed_tools
    trait_spec.build_func_id = (entry.data and entry.data.build_func_id)
    trait_spec.prompt_func_id = (entry.data and entry.data.prompt_func_id)
    trait_spec.step_func_id = (entry.data and entry.data.step_func_id)
    trait_spec.context = (entry.data and entry.data.context) or {}

    return trait_spec
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

    -- Return the first match with enhanced processing
    local entry = entries[1]
    local processed_tools = process_tools(entry.data and entry.data.tools)

    local trait_spec = table.create(0, 9)
    trait_spec.id = entry.id
    trait_spec.name = (entry.meta and entry.meta.name) or ""
    trait_spec.description = (entry.meta and entry.meta.comment) or ""
    trait_spec.prompt = (entry.data and entry.data.prompt) or ""
    trait_spec.tools = processed_tools
    trait_spec.build_func_id = (entry.data and entry.data.build_func_id)
    trait_spec.prompt_func_id = (entry.data and entry.data.prompt_func_id)
    trait_spec.step_func_id = (entry.data and entry.data.step_func_id)
    trait_spec.context = (entry.data and entry.data.context) or {}

    return trait_spec
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

    -- Build trait specs with processing
    local entries_count = #entries
    local trait_specs = table.create(entries_count, 0)

    for i, entry in ipairs(entries) do
        local processed_tools = process_tools(entry.data and entry.data.tools)

        local trait_spec = table.create(0, 9)
        trait_spec.id = entry.id
        trait_spec.name = (entry.meta and entry.meta.name) or ""
        trait_spec.description = (entry.meta and entry.meta.comment) or ""
        trait_spec.prompt = (entry.data and entry.data.prompt) or ""
        trait_spec.tools = processed_tools
        trait_spec.build_func_id = (entry.data and entry.data.build_func_id)
        trait_spec.prompt_func_id = (entry.data and entry.data.prompt_func_id)
        trait_spec.step_func_id = (entry.data and entry.data.step_func_id)
        trait_spec.context = (entry.data and entry.data.context) or {}

        trait_specs[i] = trait_spec
    end

    return trait_specs
end

return traits