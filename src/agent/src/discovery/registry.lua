local registry = require("registry")

type RegistryEntry = {
    id: string,
    meta: {
        type: string?,
        name: string?,
        title: string?,
        comment: string?,
        class: string | {string}?,
    }?,
    data: {
        model: string?,
        max_tokens: number?,
        temperature: number?,
        thinking_effort: string?,
        prompt: string?,
        traits: {string}?,
        tools: {string}?,
        memory: {any}?,
        delegates: {any}?,
        memory_contract: any?,
        agent_options: any?,
        context: {[string]: any}?,
        start_prompts: {any}?,
    },
}

type RawAgentSpec = {
    id: string,
    name: string,
    title: string,
    description: string,
    meta: table,
    model: string?,
    max_tokens: number?,
    temperature: number?,
    thinking_effort: string?,
    prompt: string?,
    traits: {string},
    tools: {string},
    memory: {any},
    delegates: {any},
    memory_contract: any?,
    agent_options: any?,
    context: {[string]: any},
    start_prompts: {any},
}

type ListByClassOpts = {
    raw_entries: boolean?,
}

---------------------------
-- Main module
---------------------------
local agent_registry = {}

-- Constants
agent_registry.AGENT_TYPE = "agent.gen1"

---------------------------
-- Dependency Injection Support
---------------------------
agent_registry._registry = nil

-- Internal: Get registry instance
local function get_registry(): typeof(registry)
    return agent_registry._registry or registry
end

---------------------------
-- Helper Functions
---------------------------

-- Internal: Check if an entry is a valid agent
local function is_valid_agent(entry: RegistryEntry?): boolean?
    return entry and entry.meta and entry.meta.type == agent_registry.AGENT_TYPE
end

-- Internal: Convert registry entry to raw agent spec
local function entry_to_raw_spec(entry: any): any
    return {
        id = entry.id,
        name = (entry.meta and entry.meta.name) or "",
        title = (entry.meta and entry.meta.title) or "",
        description = (entry.meta and entry.meta.comment) or "",
        meta = entry.meta or {},
        model = entry.data.model,
        max_tokens = entry.data.max_tokens,
        temperature = entry.data.temperature,
        thinking_effort = entry.data.thinking_effort,
        prompt = entry.data.prompt,
        traits = entry.data.traits or {},
        tools = entry.data.tools or {},
        memory = entry.data.memory or {},
        delegates = entry.data.delegates or {},
        memory_contract = entry.data.memory_contract,
        agent_options = entry.data.agent_options,
        context = entry.data.context or {},
        start_prompts = entry.data.start_prompts or {},
    }
end

---------------------------
-- Public API Functions
---------------------------

function agent_registry.get_by_id(agent_id: string): (any, string?)
    if not agent_id then
        return nil, "Agent ID is required"
    end

    local reg = get_registry()
    local entry, err = reg.get(tostring(agent_id))
    if not entry then
        return nil, "No agent found with ID: " .. tostring(agent_id) .. (err and ", error: " .. tostring(err) or "")
    end

    if not is_valid_agent(entry) then
        return nil, "Entry is not a gen1 agent: " .. tostring(agent_id)
    end

    return entry_to_raw_spec(entry)
end

function agent_registry.get_by_name(name: string): (any, string?)
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

    return entry_to_raw_spec(entries[1])
end

function agent_registry.list_by_class(class_name: string, opts: ListByClassOpts?): ({any}?, string?)
    if not class_name or #class_name == 0 then
        return nil, "class_name required"
    end

    opts = (opts or {}) :: ListByClassOpts
    local reg = get_registry()
    local query = {
        [".kind"] = "registry.entry",
        ["meta.type"] = agent_registry.AGENT_TYPE,
        ["*meta.class"] = class_name
    }

    -- First pass – light filter server-side
    local entries = reg.find(query) or {}

    -- Second pass – exact match (handles array vs string)
    local results = {}
    for _, entry in ipairs(entries) do
        local class_meta = entry.meta and entry.meta.class
        local matches = false

        if type(class_meta) == "string" then
            matches = class_meta == class_name or class_meta:find(class_name, 1, true)
        elseif type(class_meta) == "table" then
            for _, v in ipairs(class_meta) do
                if v == class_name then
                    matches = true
                    break
                end
            end
        end

        if matches then
            if opts.raw_entries then
                table.insert(results, entry)
            else
                table.insert(results, entry_to_raw_spec(entry))
            end
        end
    end

    return results
end

return agent_registry
