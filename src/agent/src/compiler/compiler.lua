local traits = require("traits")
local tools = require("tools")
local funcs = require("funcs")
local json = require("json")

type ToolDef = string | { id: string, alias: string?, context: table?, description: string?, schema: table? }
type TraitConfig = string | { id: string, context: table?, options: table?, agent_options: table? }
type DelegateConfig = { id: string, name: string?, rule: string?, context: table? }

type RawAgentSpec = {
    id: string,
    name: string?,
    description: string?,
    meta: table?,
    model: string?,
    max_tokens: number?,
    temperature: number?,
    thinking_effort: string?,
    prompt: string?,
    tools: {ToolDef}?,
    traits: {TraitConfig}?,
    delegates: {DelegateConfig}?,
    context: table?,
    memory: table?,
    memory_contract: any?,
    agent_options: table?,
}

type CompilerConfig = {
    context_merger: any,
    delegates: any,
}

type CompiledTool = {
    name: string,
    description: string?,
    schema: table?,
    context: table,
    agent_id: string?,
    registry_id: string?,
    meta: table?,
}

type PromptFunc = { trait_id: string, func_id: string, context: table }
type StepFunc = { trait_id: string, func_id: string, context: table }
type ToolWrapperSpec = {
    id: string?,
    trait_id: string,
    phases: {string},
    binding: string,
    context: table,
    options: table,
    priority: number,
    strict: boolean?,
    order: number,
}
type BindingSpec = {
    id: string?,
    kind: string,
    trait_id: string?,
    contract: string,
    binding: string,
    phases: {string},
    context: table,
    options: table,
    priority: number,
    strict: boolean?,
    order: number,
    source: string?,
}

type CompiledAgentSpec = {
    id: string,
    name: string?,
    description: string?,
    meta: table,
    model: string?,
    max_tokens: number?,
    temperature: number?,
    thinking_effort: string?,
    prompt: string,
    tools: {[string]: CompiledTool},
    memory: table,
    memory_contract: any?,
    agent_options: table,
    prompt_funcs: {PromptFunc},
    step_funcs: {StepFunc},
    tool_wrappers: {ToolWrapperSpec},
    bindings: {[string]: {BindingSpec}},
}

local compiler = {}

compiler._traits = nil
compiler._tools = nil
compiler._funcs = nil

local function get_table_keys(tbl: table): {string}
    local keys = {}
    for k, _ in pairs(tbl) do
        table.insert(keys, tostring(k))
    end
    return keys
end

local function get_traits(): any
    return compiler._traits or traits
end

local function get_tools(): any
    return compiler._tools or tools
end

local function get_funcs(): any
    return compiler._funcs or funcs
end

local DEFAULT_CONFIG = {
    context_merger = function(trait_ctx, agent_ctx, tool_ctx)
        local merged = {}
        for k, v in pairs(trait_ctx or {}) do merged[k] = v end
        for k, v in pairs(agent_ctx or {}) do merged[k] = v end
        for k, v in pairs(tool_ctx or {}) do merged[k] = v end
        return merged
    end,

    delegates = {
        generate_tool_schemas = false,
        description_suffix = nil,
        tool_schema = {
            type = "object",
            properties = {
                message = {
                    type = "string",
                    description = "The message to forward to the agent"
                }
            },
            required = { "message" }
        }
    }
}

local function merge_config(user_config: table?): CompilerConfig
    if not user_config then
        return DEFAULT_CONFIG
    end

    local config = {
        context_merger = user_config.context_merger or DEFAULT_CONFIG.context_merger,
        delegates = {
            generate_tool_schemas = user_config.delegates and user_config.delegates.generate_tool_schemas or
                DEFAULT_CONFIG.delegates.generate_tool_schemas,
            description_suffix = user_config.delegates and user_config.delegates.description_suffix or
                DEFAULT_CONFIG.delegates.description_suffix,
            tool_schema = user_config.delegates and user_config.delegates.tool_schema or
                DEFAULT_CONFIG.delegates.tool_schema
        }
    }

    return config
end

local function deep_copy(value: any): any
    if type(value) ~= "table" then
        return value
    end

    local copied = {}
    for key, item in pairs(value) do
        copied[key] = deep_copy(item)
    end
    return copied
end

local function is_map(value: any): boolean
    return type(value) == "table" and value[1] == nil
end

local function merge_agent_options(base_options: any, override_options: any): table
    local merged = {}

    if type(base_options) == "table" then
        for key, value in pairs(base_options) do
            merged[key] = deep_copy(value)
        end
    end

    if type(override_options) == "table" then
        for key, value in pairs(override_options) do
            if is_map(merged[key]) and is_map(value) then
                merged[key] = merge_agent_options(merged[key], value)
            else
                merged[key] = deep_copy(value)
            end
        end
    end

    return merged
end

local function normalize_binding_kind(kind_hint: any, raw_binding: any): string?
    local raw_kind = raw_binding and (raw_binding.kind or raw_binding.type) or kind_hint
    if type(raw_kind) ~= "string" or raw_kind == "" then
        return nil
    end

    local aliases = {
        checkpoint = "checkpoint",
        lifecycle = "lifecycle",
        memory = "memory",
        tool_wrapper = "tool_wrapper",
        tool_wrappers = "tool_wrapper",
    }

    return aliases[raw_kind] or raw_kind
end

local function normalize_binding_phases(raw_binding: any): {string}
    local phases: {string} = {}
    local raw_phases = raw_binding and (raw_binding.phases or raw_binding.phase)

    if type(raw_phases) == "string" then
        phases[#phases + 1] = raw_phases
        return phases :: {string}
    end

    if type(raw_phases) == "table" then
        for _, phase in ipairs(raw_phases) do
            if type(phase) == "string" and phase ~= "" then
                phases[#phases + 1] = phase
            end
        end
    end

    return phases :: {string}
end

local function normalize_raw_binding(kind_hint: any, raw_binding: any): any?
    if type(raw_binding) ~= "table" then
        return nil
    end

    local contract_id = raw_binding.contract or raw_binding.contract_id
    local binding_id = raw_binding.binding or raw_binding.binding_id or raw_binding.implementation_id
    if type(contract_id) ~= "string" or contract_id == "" then
        return nil
    end
    if type(binding_id) ~= "string" or binding_id == "" then
        return nil
    end

    local kind = normalize_binding_kind(kind_hint, raw_binding)
    if type(kind) ~= "string" or kind == "" then
        return nil
    end

    return {
        id = raw_binding.id or raw_binding.name,
        kind = kind,
        contract = contract_id,
        binding = binding_id,
        phases = normalize_binding_phases(raw_binding),
        context = type(raw_binding.context) == "table" and raw_binding.context or {},
        options = type(raw_binding.options) == "table" and raw_binding.options or {},
        priority = tonumber(raw_binding.priority) or 100,
        strict = raw_binding.strict == true,
    }
end

local function collect_raw_bindings(out: {any}, kind_hint: any, raw_bindings: any)
    if type(raw_bindings) ~= "table" then
        return
    end

    if raw_bindings[1] ~= nil then
        for _, raw_binding in ipairs(raw_bindings) do
            local normalized = normalize_raw_binding(kind_hint, raw_binding)
            if normalized then
                out[#out + 1] = normalized
            end
        end
        return
    end

    local direct = normalize_raw_binding(kind_hint, raw_bindings)
    if direct then
        out[#out + 1] = direct
        return
    end

    for key, nested in pairs(raw_bindings) do
        collect_raw_bindings(out, key, nested)
    end
end

local function raw_bindings_from_trait(trait_def: any): {any}
    local out = {}
    if type(trait_def) ~= "table" then
        return out
    end

    collect_raw_bindings(out, nil, trait_def.bindings)
    collect_raw_bindings(out, nil, trait_def.binding)
    return out
end

local function list_from_map_or_array(value: any): {string}
    local out: {string} = {}
    if type(value) == "string" and value ~= "" then
        out[#out + 1] = value
        return out
    end

    if type(value) ~= "table" then
        return out
    end

    if value[1] ~= nil then
        for _, item in ipairs(value) do
            if type(item) == "string" and item ~= "" then
                out[#out + 1] = item
            end
        end
        return out
    end

    for key, enabled in pairs(value) do
        if type(key) == "string" and key ~= "" and enabled ~= false then
            out[#out + 1] = key
        end
    end
    return out
end

local function set_from_list(values: {string}): {[string]: boolean}
    local out = {}
    for _, value in ipairs(values) do
        out[value] = true
    end
    return out
end

local function behaviors_from_trait(trait_def: any): {any}
    local out = {}
    if type(trait_def) ~= "table" or type(trait_def.behaviors) ~= "table" then
        return out
    end

    if trait_def.behaviors[1] ~= nil then
        for _, behavior in ipairs(trait_def.behaviors) do
            if type(behavior) == "table" then
                out[#out + 1] = behavior
            end
        end
        return out
    end

    for id, behavior in pairs(trait_def.behaviors) do
        if type(behavior) == "table" then
            local normalized = deep_copy(behavior)
            if normalized.id == nil and type(id) == "string" then
                normalized.id = id
            end
            out[#out + 1] = normalized
        end
    end
    return out
end

local function behavior_handler(behavior: any, handler_name: string): string?
    if type(behavior) ~= "table" then
        return nil
    end

    if type(behavior.handlers) == "table" then
        local handler = behavior.handlers[handler_name]
        if type(handler) == "string" and handler ~= "" then
            return handler
        end
    end

    local handler = behavior.handler
    if type(handler) == "string" and handler ~= "" then
        return handler
    end

    return nil
end

local function append_binding_spec(
    bindings: {[string]: {BindingSpec}},
    kind: string,
    spec: BindingSpec
)
    bindings[kind] = bindings[kind] or {}
    spec.kind = kind
    spec.order = #bindings[kind] + 1
    bindings[kind][#bindings[kind] + 1] = spec
end

local function merge_binding_options(trait_options: any, attachment_options: any, binding: any): table
    local merged = merge_agent_options(trait_options, binding and binding.options or nil)
    if type(binding) == "table" and type(binding.context) == "table" then
        merged = merge_agent_options(merged, binding.context.options)
    end
    merged = merge_agent_options(merged, attachment_options)
    return merged
end

local function attach_options_to_context(context: table, options: any): table
    if type(options) == "table" and next(options) ~= nil then
        context.options = merge_agent_options(context.options, options)
    end
    return context
end

local TOOL_WRAPPER_PHASES = {
    before_execute = true,
    after_execute = true,
}

local TOOL_WRAPPER_PHASE_ORDER = { "before_execute", "after_execute" }

local LIFECYCLE_PHASES = {
    activate = true,
    before_step = true,
    after_step = true,
    deactivate = true,
}

local LIFECYCLE_PHASE_ORDER = { "activate", "before_step", "after_step", "deactivate" }

local CHECKPOINT_AGENT_OPTION_KEYS = {
    function_id = true,
    max_memory_chars = true,
    max_tokens = true,
    strict = true,
    token_threshold = true,
}

local function normalize_tool_wrapper_phases(raw_hook: any): {string}
    local phases: {string} = {}
    local raw_phases = raw_hook and (raw_hook.phases or raw_hook.phase)

    if raw_phases == nil then
        return { "before_execute", "after_execute" }
    end

    if type(raw_phases) == "string" then
        if TOOL_WRAPPER_PHASES[raw_phases] then
            phases[#phases + 1] = raw_phases
        end
        return phases :: {string}
    end

    if type(raw_phases) == "table" then
        for _, phase in ipairs(raw_phases) do
            if type(phase) == "string" and TOOL_WRAPPER_PHASES[phase] then
                phases[#phases + 1] = phase
            end
        end
    end

    return phases :: {string}
end

local function append_raw_tool_wrapper(out: {any}, raw_wrapper: any)
    if type(raw_wrapper) ~= "table" then
        return
    end

    local binding = raw_wrapper.binding or raw_wrapper.binding_id or raw_wrapper.implementation_id
    if type(binding) ~= "string" or binding == "" then
        return
    end

    local phases = normalize_tool_wrapper_phases(raw_wrapper)
    if #phases == 0 then
        return
    end

    out[#out + 1] = {
        id = raw_wrapper.id or raw_wrapper.name,
        phases = phases,
        binding = binding,
        context = type(raw_wrapper.context) == "table" and raw_wrapper.context or {},
        options = type(raw_wrapper.options) == "table" and raw_wrapper.options or {},
        priority = tonumber(raw_wrapper.priority) or 100,
        strict = raw_wrapper.strict == true,
    }
end

local function collect_raw_tool_wrappers(out: {any}, raw_wrappers: any)
    if type(raw_wrappers) ~= "table" then
        return
    end

    if raw_wrappers[1] ~= nil then
        for _, raw_wrapper in ipairs(raw_wrappers) do
            append_raw_tool_wrapper(out, raw_wrapper)
        end
        return
    end

    append_raw_tool_wrapper(out, raw_wrappers)
end

local function tool_wrappers_from_trait(trait_def: any): {any}
    local out = {}
    if type(trait_def) ~= "table" then
        return out
    end

    collect_raw_tool_wrappers(out, trait_def.tool_wrappers)
    collect_raw_tool_wrappers(out, trait_def.tool_wrapper)
    return out
end

local function append_tool_wrappers(
    tool_wrappers: {ToolWrapperSpec},
    trait_id: string,
    trait_def: any,
    trait_context: table,
    raw_spec: any,
    config: CompilerConfig
)
    local wrappers = tool_wrappers_from_trait(trait_def)
    if #wrappers == 0 then
        return
    end

    for _, wrapper in ipairs(wrappers) do
        local wrapper_context = config.context_merger(
            trait_context or {},
            raw_spec.context or {},
            wrapper.context or {}
        )
        wrapper_context.agent_id = raw_spec.id
        wrapper_context.trait_id = trait_id

        tool_wrappers[#tool_wrappers + 1] = {
            id = wrapper.id,
            trait_id = trait_id,
            phases = wrapper.phases,
            binding = wrapper.binding,
            context = wrapper_context,
            options = wrapper.options or {},
            priority = wrapper.priority or 100,
            strict = wrapper.strict == true,
            order = #tool_wrappers + 1,
        }
    end
end

local function append_bindings(
    bindings: {[string]: {BindingSpec}},
    trait_id: string,
    trait_def: any,
    trait_context: table,
    attachment_options: table,
    raw_spec: any,
    config: CompilerConfig
)
    local raw_bindings = raw_bindings_from_trait(trait_def)
    if #raw_bindings == 0 then
        return
    end

    local trait_options = type(trait_def.options) == "table" and trait_def.options or {}

    for _, binding in ipairs(raw_bindings) do
        local binding_context = config.context_merger(
            trait_context or {},
            raw_spec.context or {},
            binding.context or {}
        )
        binding_context.agent_id = raw_spec.id
        binding_context.trait_id = trait_id

        local binding_options = merge_binding_options(trait_options, attachment_options, binding)
        attach_options_to_context(binding_context, binding_options)

        local kind = binding.kind
        append_binding_spec(bindings, kind, {
            id = binding.id,
            kind = kind,
            trait_id = trait_id,
            contract = binding.contract,
            binding = binding.binding,
            phases = binding.phases or {},
            context = binding_context,
            options = binding_options,
            priority = binding.priority or 100,
            strict = binding.strict == true,
            order = 0,
        })
    end
end

local function append_behavior_tool_wrapper(
    tool_wrappers: {ToolWrapperSpec},
    trait_id: string,
    behavior: any,
    handles: {[string]: boolean},
    base_context: table,
    base_options: table
)
    local binding = behavior_handler(behavior, "tool_wrapper")
    if not binding then
        return
    end

    local phases = {}
    for _, phase in ipairs(TOOL_WRAPPER_PHASE_ORDER) do
        if handles[phase] then
            phases[#phases + 1] = phase
        end
    end
    if #phases == 0 then
        return
    end

    for _, phase in ipairs(phases) do
        local options = merge_agent_options(base_options, type(behavior[phase]) == "table" and behavior[phase] or nil)
        local context = deep_copy(base_context)
        attach_options_to_context(context, options)
        tool_wrappers[#tool_wrappers + 1] = {
            id = behavior.id,
            trait_id = trait_id,
            phases = { phase },
            binding = binding,
            context = context,
            options = options,
            priority = tonumber(behavior.priority) or 100,
            strict = behavior.strict == true,
            order = #tool_wrappers + 1,
        }
    end
end

local function append_behavior_lifecycle(
    bindings: {[string]: {BindingSpec}},
    trait_id: string,
    behavior: any,
    handles: {[string]: boolean},
    base_context: table,
    base_options: table
)
    local binding = behavior_handler(behavior, "lifecycle")
    if not binding then
        return
    end

    local phases = {}
    for _, phase in ipairs(LIFECYCLE_PHASE_ORDER) do
        if handles[phase] then
            phases[#phases + 1] = phase
        end
    end
    if #phases == 0 then
        return
    end

    for _, phase in ipairs(phases) do
        local options = merge_agent_options(base_options, behavior.lifecycle)
        options = merge_agent_options(options, type(behavior[phase]) == "table" and behavior[phase] or nil)

        local context = deep_copy(base_context)
        attach_options_to_context(context, options)
        append_binding_spec(bindings, "lifecycle", {
            id = behavior.id,
            kind = "lifecycle",
            trait_id = trait_id,
            contract = "wippy.agent:lifecycle",
            binding = binding,
            phases = { phase },
            context = context,
            options = options,
            priority = tonumber(behavior.priority) or 100,
            strict = behavior.strict == true,
            order = 0,
        })
    end
end

local function checkpoint_agent_options(checkpoint_config: any): table
    local out = {}
    if type(checkpoint_config) ~= "table" then
        return out
    end

    local checkpoint = {}
    for key, value in pairs(checkpoint_config) do
        if CHECKPOINT_AGENT_OPTION_KEYS[key] then
            checkpoint[key] = deep_copy(value)
        end
    end

    if next(checkpoint) ~= nil then
        out.checkpoint = checkpoint
    end
    return out
end

local function append_behavior_checkpoint(
    bindings: {[string]: {BindingSpec}},
    trait_id: string,
    behavior: any,
    handles: {[string]: boolean},
    base_context: table,
    base_options: table
): table
    if not handles.checkpoint then
        return {}
    end

    local binding = behavior_handler(behavior, "checkpoint")
    local checkpoint_config = type(behavior.checkpoint) == "table" and behavior.checkpoint or {}
    local agent_options = checkpoint_agent_options(checkpoint_config)

    if not binding then
        return agent_options
    end

    local options = merge_agent_options(base_options, behavior.checkpoint)
    attach_options_to_context(base_context, options)
    append_binding_spec(bindings, "checkpoint", {
        id = behavior.id,
        kind = "checkpoint",
        trait_id = trait_id,
        contract = "wippy.agent:checkpoint",
        binding = binding,
        phases = { "checkpoint" },
        context = base_context,
        options = options,
        priority = tonumber(behavior.priority) or 100,
        strict = behavior.strict == true,
        order = 0,
    })

    return agent_options
end

local function append_behaviors(
    bindings: {[string]: {BindingSpec}},
    tool_wrappers: {ToolWrapperSpec},
    trait_id: string,
    trait_def: any,
    trait_context: table,
    attachment_options: table,
    raw_spec: any,
    config: CompilerConfig
): table
    local behaviors = behaviors_from_trait(trait_def)
    local behavior_agent_options = {}
    if #behaviors == 0 then
        return behavior_agent_options
    end

    local trait_options = type(trait_def.options) == "table" and trait_def.options or {}

    for _, behavior in ipairs(behaviors) do
        local handles = set_from_list(list_from_map_or_array(behavior.handles))
        for phase, _ in pairs(LIFECYCLE_PHASES) do
            if behavior[phase] == false then
                handles[phase] = nil
            end
        end
        for phase, _ in pairs(TOOL_WRAPPER_PHASES) do
            if behavior[phase] == false then
                handles[phase] = nil
            end
        end
        if behavior.checkpoint == false then
            handles.checkpoint = nil
        end

        local behavior_context = config.context_merger(
            trait_context or {},
            raw_spec.context or {},
            type(behavior.context) == "table" and behavior.context or {}
        )
        behavior_context.agent_id = raw_spec.id
        behavior_context.trait_id = trait_id
        if type(behavior.id) == "string" and behavior.id ~= "" then
            behavior_context.behavior_id = behavior.id
        end
        if type(behavior.kind) == "string" and behavior.kind ~= "" then
            behavior_context.behavior_kind = behavior.kind
        end

        local base_options = merge_agent_options(trait_options, behavior.options)
        base_options = merge_agent_options(base_options, attachment_options)

        append_behavior_lifecycle(
            bindings,
            trait_id,
            behavior,
            handles,
            deep_copy(behavior_context),
            base_options
        )

        local checkpoint_options = append_behavior_checkpoint(
            bindings,
            trait_id,
            behavior,
            handles,
            deep_copy(behavior_context),
            base_options
        )
        behavior_agent_options = merge_agent_options(behavior_agent_options, checkpoint_options)

        append_behavior_tool_wrapper(
            tool_wrappers,
            trait_id,
            behavior,
            handles,
            deep_copy(behavior_context),
            base_options
        )
    end

    return behavior_agent_options
end

local function get_canonical_tool_name(tool_id: any, tool_def: any): any
    if type(tool_def) == "table" and tool_def.alias then
        return tool_def.alias
    end

    local original_schema, err = get_tools().get_tool_schema(tool_id)
    if original_schema then
        return original_schema.name
    end

    local parts = {}
    for part in string.gmatch(tool_id, "[^:]+") do
        table.insert(parts, part)
    end

    local name = #parts >= 2 and parts[#parts] or tool_id
    name = name:gsub("[^%w]", "_"):gsub("([A-Z])", function(c) return "_" .. c:lower() end)
    name = name:gsub("__+", "_"):gsub("^_", "")

    return name
end

local function process_traits(raw_spec: any, config: CompilerConfig): (any, any, any, any, any, any, any, any, any, any)
    local additional_prompts = {}
    local additional_tools = {}
    local trait_contexts = {}
    local trait_tool_schemas = {}
    local additional_delegates = {}
    local prompt_funcs = {}
    local step_funcs = {}
    local tool_wrappers = {}
    local bindings = {}
    local agent_options = {}

    if not raw_spec.traits or #raw_spec.traits == 0 then
        return additional_prompts, additional_tools, trait_contexts, trait_tool_schemas, additional_delegates, prompt_funcs, step_funcs, tool_wrappers, bindings, agent_options
    end

    for i, trait_config in ipairs(raw_spec.traits) do
        local trait_id = type(trait_config) == "string" and trait_config or trait_config.id
        local trait_instance_context = type(trait_config) == "table" and trait_config.context or {}
        local trait_instance_options = type(trait_config) == "table" and trait_config.options or {}

        if type(trait_id) ~= "string" or trait_id == "" then
            goto continue
        end

        local trait_def, err = get_traits().get_by_id(trait_id)
        if not trait_def then
            if not string.find(trait_id, ":") then
                trait_def, err = get_traits().get_by_name(trait_id)
            end
        end

        if not trait_def then
            goto continue
        end

        -- FIX: Always merge trait_instance_context into trait_contexts
        trait_contexts[trait_id] = config.context_merger(
            trait_def.context or {},
            {},  -- No agent context here since we're processing traits
            trait_instance_context
        )

        additional_tools[trait_id] = {}

        if trait_def.prompt and #trait_def.prompt > 0 then
            table.insert(additional_prompts, trait_def.prompt)
        end

        for j, tool in ipairs(trait_def.tools or {}) do
            table.insert(additional_tools[trait_id], tool)
        end

        if trait_def.prompt_func_id then
            table.insert(prompt_funcs, {
                trait_id = trait_id,
                func_id = trait_def.prompt_func_id,
                context = trait_contexts[trait_id]  -- Use the merged context
            })
        end

        if trait_def.step_func_id then
            table.insert(step_funcs, {
                trait_id = trait_id,
                func_id = trait_def.step_func_id,
                context = trait_contexts[trait_id]  -- Use the merged context
            })
        end

        local behavior_agent_options = append_behaviors(
            bindings,
            tool_wrappers,
            trait_id,
            trait_def,
            trait_contexts[trait_id],
            trait_instance_options,
            raw_spec,
            config
        )
        agent_options = merge_agent_options(agent_options, behavior_agent_options)

        append_tool_wrappers(tool_wrappers, trait_id, trait_def, trait_contexts[trait_id], raw_spec, config)
        append_bindings(bindings, trait_id, trait_def, trait_contexts[trait_id], trait_instance_options, raw_spec, config)

        agent_options = merge_agent_options(agent_options, trait_def.agent_options)
        if type(trait_config) == "table" then
            agent_options = merge_agent_options(agent_options, trait_config.agent_options)
        end

        if trait_def.build_func_id then
            local merged_context = config.context_merger(
                trait_contexts[trait_id],  -- Use already merged trait context
                raw_spec.context or {},
                {}  -- trait_instance_context already merged above
            )

            merged_context.agent_id = raw_spec.id

            local executor = get_funcs().new()
            local contribution, err = executor:with_context(merged_context):call(
                trait_def.build_func_id,
                trait_def.prompt,
                merged_context
            )

            if not err and contribution then
                if contribution.prompt then
                    table.insert(additional_prompts, contribution.prompt)
                end

                if contribution.tools then
                    for k, tool in ipairs(contribution.tools) do
                        table.insert(additional_tools[trait_id], tool)

                        if tool.schema then
                            local canonical_name = get_canonical_tool_name(tool.id, tool)
                            trait_tool_schemas[canonical_name] = tool.schema
                        end
                    end
                end

                if contribution.delegates then
                    for _, delegate in ipairs(contribution.delegates) do
                        table.insert(additional_delegates, delegate)
                    end
                end

                if contribution.context then
                    trait_contexts[trait_id] = config.context_merger(
                        trait_contexts[trait_id],
                        contribution.context,
                        {}
                    )
                end

                if contribution.agent_options then
                    agent_options = merge_agent_options(agent_options, contribution.agent_options)
                end
            end
        end

        ::continue::
    end

    table.sort(tool_wrappers, function(a, b)
        local ap = a.priority or 100
        local bp = b.priority or 100
        if ap == bp then
            return (a.order or 0) < (b.order or 0)
        end
        return ap < bp
    end)

    for _, binding_list in pairs(bindings) do
        table.sort(binding_list, function(a, b)
            local ap = a.priority or 100
            local bp = b.priority or 100
            if ap == bp then
                return (a.order or 0) < (b.order or 0)
            end
            return ap < bp
        end)
    end

    return additional_prompts, additional_tools, trait_contexts, trait_tool_schemas, additional_delegates, prompt_funcs, step_funcs, tool_wrappers, bindings, agent_options
end

local function process_tools(raw_spec: any, additional_tools: any, trait_contexts: any, trait_tool_schemas: any, config: CompilerConfig): any
    local all_tools = {}

    for i, tool in ipairs(raw_spec.tools or {}) do
        table.insert(all_tools, {
            tool_def = tool,
            source_trait = nil
        })
    end

    for trait_id, tool_list in pairs(additional_tools) do
        for j, tool in ipairs(tool_list) do
            table.insert(all_tools, {
                tool_def = tool,
                source_trait = trait_id
            })
        end
    end

    local resolved_tools = {}
    for i, tool_info in ipairs(all_tools) do
        local tool_def = tool_info.tool_def
        local tool_id = type(tool_def) == "string" and tool_def or tool_def.id

        if type(tool_id) == "string" and tool_id:match(":%*$") then
            local namespace = tool_id:gsub(":%*$", "")
            local tool_list = get_tools().find_tools({
                namespace = namespace
            }) or {}

            for _, tool in ipairs(tool_list) do
                table.insert(resolved_tools, {
                    id = tool.id,
                    context = type(tool_def) == "table" and tool_def.context or nil,
                    description = type(tool_def) == "table" and tool_def.description or nil,
                    alias = type(tool_def) == "table" and tool_def.alias or nil,
                    source_trait = tool_info.source_trait,
                    inline_schema = nil
                })
            end
        else
            local inline_schema = nil
            if type(tool_def) == "table" and tool_def.schema then
                inline_schema = tool_def.schema
            end

            table.insert(resolved_tools, {
                id = tool_id,
                context = type(tool_def) == "table" and tool_def.context or nil,
                description = type(tool_def) == "table" and tool_def.description or nil,
                alias = type(tool_def) == "table" and tool_def.alias or nil,
                source_trait = tool_info.source_trait,
                inline_schema = inline_schema
            })
        end
    end

    local tools = {}

    for i, tool_info in ipairs(resolved_tools) do
        local canonical_name = get_canonical_tool_name(tool_info.id, tool_info)

        local tool_trait_context = {}
        if tool_info.source_trait and trait_contexts[tool_info.source_trait] then
            tool_trait_context = trait_contexts[tool_info.source_trait]
        end

        local final_context = config.context_merger(
            tool_trait_context,
            raw_spec.context or {},
            tool_info.context or {}
        )

        final_context.agent_id = raw_spec.id

        local tool_entry = {
            name = canonical_name,
            context = final_context,
            agent_id = nil
        }

        if tool_info.inline_schema then
            tool_entry.description = tool_info.description or ("Inline tool: " .. canonical_name)
            tool_entry.schema = get_tools().run_input_schema_processors(tool_info.inline_schema, tool_info.id, canonical_name)
            tool_entry.registry_id = tool_info.id  -- FIX: Preserve registry_id even with inline schema
            tool_entry.meta = {}
        else
            if trait_tool_schemas[canonical_name] then
                tool_entry.description = tool_info.description or trait_tool_schemas[canonical_name].description or ("Trait tool: " .. canonical_name)
                tool_entry.schema = trait_tool_schemas[canonical_name].schema
                tool_entry.registry_id = tool_info.id
                tool_entry.meta = trait_tool_schemas[canonical_name].meta or {}
            else
                local original_schema, err = get_tools().get_tool_schema(tool_info.id)
                if original_schema then
                    tool_entry.description = tool_info.description or original_schema.description
                    tool_entry.schema = original_schema.schema
                    tool_entry.registry_id = tool_info.id
                    tool_entry.meta = original_schema.meta or {}
                else
                    tool_entry.description = tool_info.description or ("Tool: " .. canonical_name)
                    tool_entry.schema = nil
                    tool_entry.registry_id = tool_info.id
                    tool_entry.meta = {}
                end
            end
        end

        tools[canonical_name] = tool_entry
    end

    return tools
end

local function process_delegates(raw_spec: any, additional_delegates: any, config: CompilerConfig): (any, any)
    local delegate_tools = {}
    local delegate_contexts = {}

    local all_delegates = {}

    for _, delegate in ipairs(raw_spec.delegates or {}) do
        table.insert(all_delegates, delegate)
    end

    for _, delegate in ipairs(additional_delegates) do
        table.insert(all_delegates, delegate)
    end

    if #all_delegates == 0 then
        return delegate_tools, delegate_contexts
    end

    if config.delegates.generate_tool_schemas then
        for _, delegate in ipairs(all_delegates) do
            if not delegate.name then
                goto continue
            end

            local description = "Forward the request to " .. (delegate.rule or "when appropriate")
            if config.delegates.description_suffix then
                description = description .. config.delegates.description_suffix
            end

            -- FIX: Properly merge agent context with delegate context
            local merged_context = config.context_merger(
                {},                          -- No trait context for delegates
                raw_spec.context or {},      -- Agent context
                delegate.context or {}       -- Delegate-specific context
            )

            delegate_tools[delegate.name] = {
                name = delegate.name,
                description = description,
                schema = config.delegates.tool_schema,
                agent_id = delegate.id,
                context = merged_context  -- Use merged context instead
            }

            if delegate.context then
                delegate_contexts[delegate.name] = delegate.context
            end

            ::continue::
        end
    end

    return delegate_tools, delegate_contexts
end

local function append_memory_contract_binding(bindings: {[string]: {BindingSpec}}, raw_spec: any, config: CompilerConfig)
    local memory_contract = raw_spec and raw_spec.memory_contract
    if type(memory_contract) ~= "table" or type(memory_contract.implementation_id) ~= "string" or memory_contract.implementation_id == "" then
        return
    end

    local binding_context = config.context_merger(
        {},
        raw_spec.context or {},
        type(memory_contract.context) == "table" and memory_contract.context or {}
    )
    binding_context.agent_id = raw_spec.id

    local binding_options = type(memory_contract.options) == "table" and deep_copy(memory_contract.options) or {}
    attach_options_to_context(binding_context, binding_options)

    append_binding_spec(bindings, "memory", {
        id = "memory_contract",
        kind = "memory",
        trait_id = nil,
        contract = "wippy.agent:memory",
        binding = memory_contract.implementation_id,
        phases = {},
        context = binding_context,
        options = binding_options,
        priority = 1000,
        strict = false,
        order = 0,
        source = "memory_contract",
    })
end

function compiler.compile(raw_spec: table?, user_config: table?): (any, string?)
    if not raw_spec then
        return nil, "Raw spec is required"
    end

    local config = merge_config(user_config)

    local additional_prompts, additional_tools, trait_contexts, trait_tool_schemas, additional_delegates, prompt_funcs, step_funcs, tool_wrappers, bindings, trait_agent_options = process_traits(
        raw_spec, config)

    append_memory_contract_binding(bindings :: {[string]: {BindingSpec}}, raw_spec, config)

    local tools = process_tools(raw_spec, additional_tools, trait_contexts, trait_tool_schemas, config)

    local delegate_tools, delegate_contexts = process_delegates(raw_spec, additional_delegates, config)

    for delegate_name, delegate_tool in pairs(delegate_tools) do
        tools[delegate_name] = delegate_tool
    end

    local final_prompt = raw_spec.prompt or ""
    if #additional_prompts > 0 then
        local all_prompts = { final_prompt }
        for _, prompt in ipairs(additional_prompts) do
            table.insert(all_prompts, prompt)
        end
        final_prompt = table.concat(all_prompts, "\n\n")
    end

    local compiled_spec = {
        id = raw_spec.id,
        name = raw_spec.name,
        description = raw_spec.description,
        meta = raw_spec.meta or {},
        model = raw_spec.model,
        max_tokens = raw_spec.max_tokens,
        temperature = raw_spec.temperature,
        thinking_effort = raw_spec.thinking_effort,
        prompt = final_prompt,
        tools = tools,
        memory = raw_spec.memory or {},
        memory_contract = raw_spec.memory_contract,
        agent_options = merge_agent_options(trait_agent_options, raw_spec.agent_options),
        prompt_funcs = prompt_funcs,
        step_funcs = step_funcs,
        tool_wrappers = tool_wrappers,
        bindings = bindings,
    }

    return compiled_spec
end

return compiler
