local agent_registry = require("agent_registry")
local compiler = require("compiler")
local agent = require("agent")
local contract = require("contract")

type ToolSpec = string | { id: string, alias: string?, description: string?, context: table? }
type DelegateSpec = { id: string, name: string?, rule: string?, schema: table?, context: table? }
type MemoryContractConfig = { implementation_id: string, context: table? }

type DelegateToolsConfig = {
    enabled: boolean?,
    description_suffix: string?,
    default_schema: table?,
}

type CompilationDelegatesConfig = {
    generate_tool_schemas: boolean,
    description_suffix: string?,
    tool_schema: table,
}

type CompilationConfig = {
    delegates: CompilationDelegatesConfig,
    context_merger: any?,
}

type AgentContextConfig = {
    enable_cache: boolean?,
    context: {[string]: any}?,
    delegate_tools: DelegateToolsConfig?,
    memory_contract: MemoryContractConfig?,
    context_merger: any?,
}

type LoadOptions = {
    model: string?,
}

type ConfigSummary = {
    current_agent_id: string?,
    current_model: string?,
    additional_tools_count: number,
    additional_delegates_count: number,
    has_active_traits: boolean,
    has_active_tools: boolean,
    has_memory_contract: boolean,
    cache_enabled: boolean,
    delegate_tools_enabled: boolean,
}

local agent_context = {}
agent_context.__index = agent_context

agent_context._agent_registry = nil
agent_context._compiler = nil
agent_context._agent = nil
agent_context._resolver = nil
agent_context._resolver_checked = false

local RESOLVER_CONTRACT = "wippy.agent:resolver"

local function get_agent_registry(): any return agent_context._agent_registry or agent_registry end
local function get_compiler(): any return agent_context._compiler or compiler end
local function get_agent(): any return agent_context._agent or agent end

local function get_resolver(): any?
    if agent_context._resolver_checked then
        return agent_context._resolver
    end
    agent_context._resolver_checked = true

    local resolver_contract, err = contract.get(RESOLVER_CONTRACT)
    if err or not resolver_contract then
        return nil
    end

    local instance, open_err = resolver_contract:open()
    if open_err or not instance then
        return nil
    end

    agent_context._resolver = instance
    return instance
end

local function resolve_agent_via_contract(agent_id: string): table?
    local resolver = get_resolver()
    if not resolver then
        return nil
    end

    local spec, resolve_err = resolver:resolve({ agent_id = agent_id })
    if resolve_err or not spec then
        return nil
    end

    return spec :: {}?
end

local function merge_contexts(base_context: {[string]: any}?, override_context: {[string]: any}?): {[string]: any}
    local merged = {}
    if base_context then
        for k, v in pairs(base_context) do
            merged[k] = v
        end
    end
    if override_context then
        for k, v in pairs(override_context) do
            merged[k] = v
        end
    end
    return merged
end

function agent_context.new(config: {
    enable_cache: boolean?,
    context: {[string]: any}?,
    delegate_tools: DelegateToolsConfig?,
    memory_contract: MemoryContractConfig?,
    context_merger: any?,
}?): any
    config = config or {}

    local self = setmetatable({}, agent_context)

    self.enable_cache = config.enable_cache ~= nil and config.enable_cache or true
    self.base_context = config.context or {}

    self.current_agent = nil
    self.current_agent_id = nil
    self.current_model = nil

    self.additional_tools = {}
    self.additional_delegates = {}
    -- Declarative active overlays: nil means "use the agent's own set"; a list is
    -- the full desired set that replaces it on the next compile (see set_active_*).
    self.active_traits = nil
    self.active_tools = nil
    self.memory_contract = config.memory_contract

    self.compilation_config = {
        delegates = {
            generate_tool_schemas = config.delegate_tools and config.delegate_tools.enabled or false,
            description_suffix = config.delegate_tools and config.delegate_tools.description_suffix,
            tool_schema = config.delegate_tools and config.delegate_tools.default_schema or {
                type = "object",
                properties = {
                    message = {
                        type = "string",
                        description = "The message to forward to the agent"
                    }
                },
                required = { "message" }
            }
        },
        context_merger = config.context_merger
    }

    return self
end

local function clear_current_agent(self: any)
    self.current_agent = nil
    self.current_agent_id = nil
    self.current_model = nil
end

function agent_context:add_tools(tool_specs): any
    if not tool_specs then
        return self
    end

    if type(tool_specs) == "string" or (type(tool_specs) == "table" and tool_specs.id) then
        tool_specs = { tool_specs }
    end

    for _, tool_spec in ipairs(tool_specs) do
        if type(tool_spec) == "string" then
            table.insert(self.additional_tools, { id = tool_spec })
        else
            table.insert(self.additional_tools, tool_spec)
        end
    end

    clear_current_agent(self)
    return self
end

function agent_context:add_delegates(delegate_specs): any
    if not delegate_specs then
        return self
    end

    if delegate_specs.id then
        delegate_specs = { delegate_specs }
    end

    for _, delegate_spec in ipairs(delegate_specs) do
        table.insert(self.additional_delegates, delegate_spec)

        if not self.compilation_config.delegates.generate_tool_schemas then
            self.compilation_config.delegates.generate_tool_schemas = true
        end
    end

    clear_current_agent(self)
    return self
end

-- Declares the full desired trait set for the current agent. This is a replace,
-- not an append: the list becomes the agent's traits on the next compile, and the
-- compiler reconciles (resolving trait prompts/tools/contexts) accordingly. Pass nil
-- to drop the override and fall back to the agent's own traits.
function agent_context:set_active_traits(traits: {any}?): any
    if traits == nil then
        self.active_traits = nil
    else
        if type(traits) == "string" or (type(traits) == "table" and (traits.id or traits.name)) then
            traits = { traits }
        end
        local list = {}
        for _, trait in ipairs(traits) do
            table.insert(list, trait)
        end
        self.active_traits = list
    end

    clear_current_agent(self)
    return self
end

-- Declares the full desired explicit tool set for the current agent (replace, not
-- append). Arena/runtime add_tools still layer on top, and trait-contributed tools
-- are resolved independently by the compiler. Pass nil to fall back to the agent's
-- own tools.
function agent_context:set_active_tools(tools: {any}?): any
    if tools == nil then
        self.active_tools = nil
    else
        if type(tools) == "string" or (type(tools) == "table" and tools.id) then
            tools = { tools }
        end
        local list = {}
        for _, tool in ipairs(tools) do
            table.insert(list, tool)
        end
        self.active_tools = list
    end

    clear_current_agent(self)
    return self
end

function agent_context:configure_delegate_tools(config: DelegateToolsConfig): any
    if config.enabled ~= nil then
        self.compilation_config.delegates.generate_tool_schemas = config.enabled
    end
    if config.description_suffix then
        self.compilation_config.delegates.description_suffix = config.description_suffix
    end
    if config.default_schema then
        self.compilation_config.delegates.tool_schema = config.default_schema
    end

    clear_current_agent(self)
    return self
end

function agent_context:set_memory_contract(memory_contract: MemoryContractConfig): any
    self.memory_contract = memory_contract
    clear_current_agent(self)
    return self
end

function agent_context:set_context_merger(merger_fn: any): any
    self.compilation_config.context_merger = merger_fn
    clear_current_agent(self)
    return self
end

function agent_context:update_context(context_updates: {[string]: any}?): any
    if not context_updates or type(context_updates) ~= "table" then
        return self
    end

    for k, v in pairs(context_updates) do
        self.base_context[k] = v
    end

    clear_current_agent(self)
    return self
end

function agent_context:load_agent(agent_spec_or_id: string | table, options: LoadOptions?): (any?, string?)
    if not agent_spec_or_id then
        return nil, "Agent spec or identifier is required"
    end

    options = options or {}
    local model_override = options.model
    local raw_spec
    local agent_identifier

    if type(agent_spec_or_id) == "table" then
        raw_spec = agent_spec_or_id
        agent_identifier = raw_spec.id or raw_spec.name or "inline-agent"
    else
        agent_identifier = agent_spec_or_id

        raw_spec = resolve_agent_via_contract(agent_identifier)

        if not raw_spec then
            local registry = get_agent_registry()
            local err
            raw_spec, err = registry.get_by_id(tostring(agent_identifier))
            if not raw_spec then
                raw_spec, err = registry.get_by_name(tostring(agent_identifier))
            end
            if not raw_spec then
                return nil, "Failed to load agent '" .. agent_identifier .. "': " .. (err or "not found")
            end
        end
    end

    if model_override then
        raw_spec.model = model_override
    end

    -- Declarative overlays replace the agent's own sets before compilation; the
    -- compiler then reconciles (re-resolving traits, re-deriving tools). Copy the
    -- tool list so the additional_tools append below cannot mutate the stored overlay.
    if self.active_traits ~= nil then
        local traits = {}
        for _, trait_spec in ipairs(self.active_traits) do
            table.insert(traits, trait_spec)
        end
        raw_spec.traits = traits
    end

    if self.active_tools ~= nil then
        local tools = {}
        for _, tool_spec in ipairs(self.active_tools) do
            table.insert(tools, tool_spec)
        end
        raw_spec.tools = tools
    end

    if #self.additional_tools > 0 then
        raw_spec.tools = raw_spec.tools or {}
        for _, tool_spec in ipairs(self.additional_tools) do
            table.insert(raw_spec.tools, tool_spec)
        end
    end

    if #self.additional_delegates > 0 then
        raw_spec.delegates = raw_spec.delegates or {}
        for _, delegate_spec in ipairs(self.additional_delegates) do
            table.insert(raw_spec.delegates, delegate_spec)
        end
    end

    if self.memory_contract then
        raw_spec.memory_contract = self.memory_contract
    end

    local agent_registry_context = raw_spec.context or {}
    raw_spec.context = merge_contexts(self.base_context, agent_registry_context)

    local compiler_instance = get_compiler()
    local compiled_spec, compile_err = (compiler_instance :: any).compile(raw_spec, self.compilation_config)
    if not compiled_spec then
        return nil, "Failed to compile agent '" .. agent_identifier .. "': " .. (compile_err or "compilation error")
    end

    local agent_module = get_agent()
    local agent_instance, agent_err = agent_module.new(compiled_spec)
    if not agent_instance then
        return nil, "Failed to create agent '" .. agent_identifier .. "': " .. (agent_err or "creation error")
    end

    self.current_agent = agent_instance
    self.current_agent_id = agent_identifier
    self.current_model = compiled_spec.model

    return agent_instance, nil
end

function agent_context:get_current_agent(): (any?, string?)
    if not self.current_agent then
        return nil, "No agent loaded"
    end
    return self.current_agent, nil
end

function agent_context:switch_to_agent(agent_identifier: string | table, options: LoadOptions?): (boolean, string?)
    if not agent_identifier then
        return false, "Agent spec or identifier is required"
    end

    options = options or {}

    -- Switching to a different agent drops the declarative trait/tool overlays: they
    -- describe the current agent's active set and must not be applied to another agent
    -- (e.g. agent A's trait list is meaningless for agent B). add_tools/add_delegates
    -- are an agent-agnostic additive layer and intentionally persist across switches.
    -- switch_to_model reloads the same agent and preserves the overlays.
    local target_id = type(agent_identifier) == "table"
        and (agent_identifier.id or agent_identifier.name)
        or agent_identifier
    if target_id == nil or target_id ~= self.current_agent_id then
        self.active_traits = nil
        self.active_tools = nil
    end

    local new_agent, err = self:load_agent(agent_identifier, options)
    if not new_agent then
        return false, err
    end

    return true, nil
end

function agent_context:switch_to_model(model_name: string?): (boolean, string?)
    if not model_name or model_name == "" then
        return false, "Model name is required"
    end

    if not self.current_agent_id then
        return false, "No current agent to change model for"
    end

    local new_agent, err = self:load_agent(self.current_agent_id, { model = model_name })
    if not new_agent then
        return false, err
    end

    return true, nil
end

function agent_context:get_config(): ConfigSummary
    return {
        current_agent_id = self.current_agent_id,
        current_model = self.current_model,
        additional_tools_count = #self.additional_tools,
        additional_delegates_count = #self.additional_delegates,
        has_active_traits = self.active_traits ~= nil,
        has_active_tools = self.active_tools ~= nil,
        has_memory_contract = self.memory_contract ~= nil,
        cache_enabled = self.enable_cache,
        delegate_tools_enabled = self.compilation_config.delegates.generate_tool_schemas
    } :: ConfigSummary
end

return agent_context
