local agent_registry = require("agent_registry")
local compiler = require("compiler")
local agent = require("agent")

local agent_context = {}
agent_context.__index = agent_context

agent_context._agent_registry = nil
agent_context._compiler = nil
agent_context._agent = nil

local function get_agent_registry() return agent_context._agent_registry or agent_registry end
local function get_compiler() return agent_context._compiler or compiler end
local function get_agent() return agent_context._agent or agent end

local function merge_contexts(base_context, override_context)
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

function agent_context.new(config)
    config = config or {}

    local self = setmetatable({}, agent_context)

    self.enable_cache = config.enable_cache ~= nil and config.enable_cache or true
    self.base_context = config.context or {}

    self.current_agent = nil
    self.current_agent_id = nil
    self.current_model = nil

    self.additional_tools = {}
    self.additional_delegates = {}
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

local function clear_current_agent(self)
    self.current_agent = nil
    self.current_agent_id = nil
    self.current_model = nil
end

function agent_context:add_tools(tool_specs)
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

function agent_context:add_delegates(delegate_specs)
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

function agent_context:configure_delegate_tools(config)
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

function agent_context:set_memory_contract(contract)
    self.memory_contract = contract
    clear_current_agent(self)
    return self
end

function agent_context:set_context_merger(merger_fn)
    self.compilation_config.context_merger = merger_fn
    clear_current_agent(self)
    return self
end

function agent_context:update_context(context_updates)
    if not context_updates or type(context_updates) ~= "table" then
        return self
    end

    for k, v in pairs(context_updates) do
        self.base_context[k] = v
    end

    clear_current_agent(self)
    return self
end

function agent_context:load_agent(agent_spec_or_id, options)
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
        local registry = get_agent_registry()
        local err
        raw_spec, err = registry.get_by_id(agent_identifier)
        if not raw_spec then
            raw_spec, err = registry.get_by_name(agent_identifier)
        end
        if not raw_spec then
            return nil, "Failed to load agent '" .. agent_identifier .. "': " .. (err or "not found")
        end
    end

    if model_override then
        raw_spec.model = model_override
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
    local compiled_spec, compile_err = compiler_instance.compile(raw_spec, self.compilation_config)
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

function agent_context:get_current_agent()
    if not self.current_agent then
        return nil, "No agent loaded"
    end
    return self.current_agent, nil
end

function agent_context:switch_to_agent(agent_identifier, options)
    if not agent_identifier then
        return false, "Agent spec or identifier is required"
    end

    options = options or {}
    local new_agent, err = self:load_agent(agent_identifier, options)
    if not new_agent then
        return false, err
    end

    return true, nil
end

function agent_context:switch_to_model(model_name)
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

function agent_context:get_config()
    return {
        current_agent_id = self.current_agent_id,
        current_model = self.current_model,
        additional_tools_count = #self.additional_tools,
        additional_delegates_count = #self.additional_delegates,
        has_memory_contract = self.memory_contract ~= nil,
        cache_enabled = self.enable_cache,
        delegate_tools_enabled = self.compilation_config.delegates.generate_tool_schemas
    }
end

return agent_context