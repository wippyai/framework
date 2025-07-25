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

-- Resolve tool namespace wildcards
local function resolve_tool_wildcards(tools_array)
    if not tools_array or #tools_array == 0 then
        return {}
    end

    local resolved_tools = {}
    local reg = get_registry()

    for _, tool_id in ipairs(tools_array) do
        if type(tool_id) == "string" and tool_id:match(":%*$") then
            local namespace = tool_id:gsub(":%*$", "")
            local matching_entries = reg.find({
                [".ns"] = namespace,
                ["meta.type"] = "tool" -- Assuming tools have meta.type = "tool"
            })

            if matching_entries and #matching_entries > 0 then
                for _, entry in ipairs(matching_entries) do
                    if not contains(resolved_tools, entry.id) then
                        table.insert(resolved_tools, entry.id)
                    end
                end
            end
        else
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

-- Internal: Process traits and incorporate their prompts and tools
local function process_traits(agent_spec)
    if not agent_spec.traits or #agent_spec.traits == 0 then
        return
    end

    local trait_prompts = {}
    local traits_lib = get_traits()
    -- agent_spec.tools already contains tools from the agent's direct definition.
    -- We will use add_unique_items to add trait tools to it.

    for _, trait_identifier in ipairs(agent_spec.traits) do
        local trait = nil
        local err = nil

        -- First, try to get by name (as trait names are common in agent definitions)
        trait, err = traits_lib.get_by_name(trait_identifier)

        -- If not found by name, try by ID
        if not trait then
            trait, err = traits_lib.get_by_id(trait_identifier)
        end

        if trait then
            -- Add trait prompt
            if trait.prompt and #trait.prompt > 0 then
                table.insert(trait_prompts, trait.prompt)
            end

            -- Add trait tools (uniquely)
            if trait.tools and #trait.tools > 0 then
                add_unique_items(agent_spec.tools, trait.tools)
            end
        else
            -- Optional: Log a warning if a trait specified by the agent is not found
            -- print("Warning: Trait not found: " .. tostring(trait_identifier))
        end
    end

    -- Combine trait prompts with the agent's base prompt
    if #trait_prompts > 0 then
        agent_spec.trait_prompts = trait_prompts -- Store original trait prompts for reference

        if agent_spec.prompt and #agent_spec.prompt > 0 then
            local combined_prompt = agent_spec.prompt
            for _, trait_prompt in ipairs(trait_prompts) do
                combined_prompt = combined_prompt .. "\n\n" .. trait_prompt
            end
            agent_spec.prompt = combined_prompt
        else
            agent_spec.prompt = table.concat(trait_prompts, "\n\n")
        end
    end
end

-- Internal: Process delegate entries
local function process_delegates(agent_spec, delegate_map)
    if not delegate_map or type(delegate_map) ~= "table" then
        return
    end
    agent_spec.delegates = agent_spec.delegates or {}
    for agent_id, delegate_config in pairs(delegate_map) do
        table.insert(agent_spec.delegates, {
            id = agent_id,
            name = delegate_config.name,
            rule = delegate_config.rule,
        })
    end
end

-- Internal: Build a complete agent specification with resolved dependencies
function agent_registry._build_agent_spec(entry, visited_ids) -- visited_ids is no longer used for inheritance recursion
    visited_ids = visited_ids or {} -- Retained for consistency, though its primary use (inheritance recursion) is gone
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
        delegates = {},
        memory_contract = entry.data.memory_contract -- Add memory contract support
    }
    visited_ids[entry.id] = true -- Mark this entry as visited in the current build context

    add_unique_items(agent_spec.traits, entry.data.traits)
    add_unique_items(agent_spec.tools, entry.data.tools)
    add_unique_items(agent_spec.memory, entry.data.memory)

    -- Inheritance processing removed
    -- if entry.data.inherit and #entry.data.inherit > 0 then
    --     process_inheritance(agent_spec, entry.data.inherit, visited_ids)
    -- end

    if entry.data.delegate then
        process_delegates(agent_spec, entry.data.delegate)
    end

    -- Process traits (prompts and tools) after direct definitions
    process_traits(agent_spec)

    -- Resolve any tool namespace wildcards from all sources (direct, traits)
    agent_spec.tools = resolve_tool_wildcards(agent_spec.tools)

    return agent_spec
end

---------------------------
-- Public API Functions
---------------------------

function agent_registry.get_by_id(agent_id)
    if not agent_id then
        return nil, "Agent ID is required"
    end
    local reg = get_registry()
    local entry, err = reg.get(agent_id)
    if not entry then
        return nil, "No agent found with ID: " .. tostring(agent_id) .. ", error: " .. tostring(err)
    end
    if not is_valid_agent(entry) then
        return nil, "Entry is not a gen1 agent: " .. tostring(agent_id)
    end
    return agent_registry._build_agent_spec(entry) -- No need to pass visited_ids from here for non-inheritance build
end

function agent_registry.get_by_name(name)
    if not name then
        return nil, "Agent name is required"
    end
    local reg = get_registry()
    local entries = reg.find({
        [".kind"] = "registry.entry",
        ["meta.type"] = agent_registry.AGENT_TYPE,
        ["meta.name"] = name
    })
    if not entries or #entries == 0 then
        return nil, "No agent found with name: " .. name
    end
    return agent_registry._build_agent_spec(entries[1]) -- No need to pass visited_ids from here for non-inheritance build
end

-- Return full entries (id, meta, data) for every agent that belongs to
-- the given class.  The call never fetches heavy prompt bodies twice,
-- because we only call registry.get once per match.
function agent_registry.list_by_class(class_name, opts)
    assert(class_name ~= nil and #class_name > 0, "class_name required")
    opts = opts or {}

    local reg   = get_registry()
    local query = {
        [".kind"]     = "registry.entry",
        ["meta.type"] = agent_registry.AGENT_TYPE,
        ["*meta.class"] = class_name
    }

    -- first pass – light filter server-side
    local entries = reg.find(query) or {}

    -- second pass – exact match (handles array vs string)
    local out = {}
    for _, e in ipairs(entries) do
        local c = e.meta and e.meta.class
        if type(c) == "string" then
            if c == class_name or c:find(class_name, 1, true) then
                table.insert(out, e)                      -- include data
            end
        elseif type(c) == "table" then
            for _, v in ipairs(c) do
                if v == class_name then
                    table.insert(out, e)
                    break
                end
            end
        end
    end
    return out
end

agent_registry._contains = contains
agent_registry._resolve_tool_wildcards = resolve_tool_wildcards

return agent_registry