local registry = require("registry")
local traits = require("traits")

---------------------------
-- Main module
---------------------------
local agent_registry = {}

-- Constants
agent_registry.AGENT_TYPE = "agent.gen1"

---------------------------
-- Dependency Injection Support
---------------------------
-- Allow for dependency injection for testing
agent_registry._registry = nil
agent_registry._traits = nil

-- Internal: Get registry instance - use injected registry or require it
local function get_registry()
    return agent_registry._registry or registry
end

-- Internal: Get traits instance - use injected traits or require it
local function get_traits()
    return agent_registry._traits or traits
end

---------------------------
-- Helper Functions
---------------------------

-- Internal: Check if an array contains a value
local function contains(array, value)
    for _, item in ipairs(array) do
        if item == value then
            return true
        end
    end
    return false
end

-- Internal: Check if an entry is a valid agent
local function is_valid_agent(entry)
    return entry and entry.meta and entry.meta.type == agent_registry.AGENT_TYPE
end

-- Internal: Get agent metadata with default values
local function get_agent_metadata(entry)
    return {
        id = entry.id,
        name = (entry.meta and entry.meta.name) or "",
        description = (entry.meta and entry.meta.comment) or "",
    }
end

-- Internal: Add unique items to target array
local function add_unique_items(target_array, source_array)
    if not source_array then
        return
    end

    for _, item in ipairs(source_array) do
        if not contains(target_array, item) then
            table.insert(target_array, item)
        end
    end
end

-- Internal: Process traits and incorporate their prompts
local function process_traits(agent_spec)
    if #agent_spec.traits == 0 then
        return
    end

    local trait_prompts = {}
    local traits_lib = get_traits()
    for _, trait_name in ipairs(agent_spec.traits) do
        local trait, err = traits_lib.get_by_name(trait_name)
        if trait and trait.prompt and #trait.prompt > 0 then
            table.insert(trait_prompts, trait.prompt)
        else
            -- try by id
            trait, err = traits_lib.get_by_id(trait_name)
            if trait and trait.prompt and #trait.prompt > 0 then
                table.insert(trait_prompts, trait.prompt)
            end
        end
    end

    -- Combine trait prompts with the agent's base prompt
    if #trait_prompts > 0 then
        -- Store the original trait prompts for reference
        agent_spec.trait_prompts = trait_prompts

        -- If the agent has a base prompt, combine it with trait prompts
        if agent_spec.prompt and #agent_spec.prompt > 0 then
            local combined_prompt = agent_spec.prompt
            for _, trait_prompt in ipairs(trait_prompts) do
                combined_prompt = combined_prompt .. "\n\n" .. trait_prompt
            end
            agent_spec.prompt = combined_prompt
        else
            -- If no base prompt, just concatenate trait prompts
            agent_spec.prompt = table.concat(trait_prompts, "\n\n")
        end
    end
end

-- NEW: Resolve tool namespace wildcards
-- Helper: Check if an array contains a value
local function contains(array, value)
    for _, item in ipairs(array) do
        if item == value then
            return true
        end
    end
    return false
end

-- Resolve tool namespace wildcards
local function resolve_tool_wildcards(tools_array)
    if not tools_array or #tools_array == 0 then
        return {}
    end

    local resolved_tools = {}
    local reg = get_registry()

    for _, tool_id in ipairs(tools_array) do
        -- Check if this is a namespace wildcard (ends with :*)
        if type(tool_id) == "string" and tool_id:match(":%*$") then
            local namespace = tool_id:gsub(":%*$", "")

            -- Get all entries in this namespace
            -- Use the special .namespace field for matching
            local matching_entries = reg.find({
                [".ns"] = namespace,
                ["meta.type"] = "tool"
            })

            -- Add all matching tools to the resolved list
            if matching_entries and #matching_entries > 0 then
                for _, entry in ipairs(matching_entries) do
                    if not contains(resolved_tools, entry.id) then
                        table.insert(resolved_tools, entry.id)
                    end
                end
            end
        else
            -- Regular tool ID, add it directly if not already present
            if not contains(resolved_tools, tool_id) then
                table.insert(resolved_tools, tool_id)
            end
        end
    end

    return resolved_tools
end

---------------------------
-- Core Build Function
---------------------------

-- Internal: Process inheritance from parent agents
local function process_inheritance(agent_spec, inherit_list, visited_ids)
    local reg = get_registry()

    for _, parent_id in ipairs(inherit_list) do
        -- Skip if we've already processed this parent (prevents recursion)
        if not visited_ids[parent_id] then
            local parent_entry, err = reg.get(parent_id)

            if is_valid_agent(parent_entry) then
                -- Process parent and its inheritance tree recursively
                local parent_spec = agent_registry._build_agent_spec(parent_entry, visited_ids)

                -- Add traits, tools, and memories from parent if not already present
                add_unique_items(agent_spec.traits, parent_spec.traits)
                add_unique_items(agent_spec.tools, parent_spec.tools)
                add_unique_items(agent_spec.memory, parent_spec.memory)
            end
        end
    end
end

-- Internal: Process delegate entries
local function process_delegates(agent_spec, delegate_map)
    if not delegate_map or type(delegate_map) ~= "table" then
        return
    end

    -- Initialize delegates array if not present
    agent_spec.delegates = agent_spec.delegates or {}

    -- Process each delegate entry from the map structure
    for agent_id, delegate_config in pairs(delegate_map) do
        -- Create delegate entry with direct ID reference
        table.insert(agent_spec.delegates, {
            id = agent_id,
            name = delegate_config.name,
            rule = delegate_config.rule,
        })
    end
end

-- Internal: Build a complete agent specification with resolved dependencies
function agent_registry._build_agent_spec(entry, visited_ids)
    -- Initialize visited_ids on first call to prevent infinite recursion
    visited_ids = visited_ids or {}

    -- Start with a complete agent spec from the entry data
    local agent_spec = {
        id = entry.id,
        name = (entry.meta and entry.meta.name) or "",
        title = (entry.meta and entry.meta.title) or "",
        description = (entry.meta and entry.meta.comment) or "",
        prompt = entry.data.prompt or "",
        model = entry.data.model or "",
        max_tokens = entry.data.max_tokens or 0,
        temperature = entry.data.temperature or 0,
        thinking_effort = entry.data.thinking_effort or 0,
        traits = {},
        tools = {},
        memory = {},
        delegates = {}
    }

    -- Mark this ID as visited
    visited_ids[entry.id] = true

    -- Add the agent's own traits, tools, and memories first
    add_unique_items(agent_spec.traits, entry.data.traits)
    add_unique_items(agent_spec.tools, entry.data.tools)
    add_unique_items(agent_spec.memory, entry.data.memory)

    -- Process parent agents (inheritance)
    if entry.data.inherit and #entry.data.inherit > 0 then
        process_inheritance(agent_spec, entry.data.inherit, visited_ids)
    end

    -- Process delegate entries using new map format
    if entry.data.delegate then
        process_delegates(agent_spec, entry.data.delegate)
    end

    -- Process traits and incorporate their prompts
    process_traits(agent_spec)

    -- NEW: Resolve any tool namespace wildcards
    agent_spec.tools = resolve_tool_wildcards(agent_spec.tools)

    return agent_spec
end

---------------------------
-- Public API Functions
---------------------------

-- Get agent specification by ID
function agent_registry.get_by_id(agent_id)
    if not agent_id then
        return nil, "Agent ID is required"
    end

    -- Get agent directly from registry without snapshot
    local reg = get_registry()
    local entry, err = reg.get(agent_id)

    if not entry then
        return nil, "No agent found with ID: " .. tostring(agent_id) .. ", error: " .. tostring(err)
    end

    -- Verify it's an agent
    if not is_valid_agent(entry) then
        return nil, "Entry is not a gen1 agent: " .. tostring(agent_id)
    end

    -- Build and return the full agent specification
    return agent_registry._build_agent_spec(entry)
end

-- Get agent specification by name
function agent_registry.get_by_name(name)
    if not name then
        return nil, "Agent name is required"
    end

    -- Find agents with matching name directly from registry
    local reg = get_registry()
    local entries = reg.find({
        [".kind"] = "registry.entry",
        ["meta.type"] = agent_registry.AGENT_TYPE,
        ["meta.name"] = name
    })

    if not entries or #entries == 0 then
        return nil, "No agent found with name: " .. name
    end

    -- Build and return the full agent specification for the first match
    return agent_registry._build_agent_spec(entries[1])
end

-- For backward compatibility, export _contains function
agent_registry._contains = contains

-- NEW: Export resolve_tool_wildcards for testing
agent_registry._resolve_tool_wildcards = resolve_tool_wildcards

return agent_registry
