local traits = require("traits")
local tools = require("tools")
local funcs = require("funcs")
local json = require("json")

local compiler = {}

compiler._traits = nil
compiler._tools = nil
compiler._funcs = nil

local function get_table_keys(tbl)
    local keys = {}
    for k, _ in pairs(tbl) do
        table.insert(keys, tostring(k))
    end
    return keys
end

local function get_traits()
    return compiler._traits or traits
end

local function get_tools()
    return compiler._tools or tools
end

local function get_funcs()
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

local function merge_config(user_config)
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

local function get_canonical_tool_name(tool_id, tool_def)
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

local function process_traits(raw_spec, config)
    local additional_prompts = {}
    local additional_tools = {}
    local trait_contexts = {}
    local trait_tool_schemas = {}
    local additional_delegates = {}
    local prompt_funcs = {}
    local step_funcs = {}

    if not raw_spec.traits or #raw_spec.traits == 0 then
        return additional_prompts, additional_tools, trait_contexts, trait_tool_schemas, additional_delegates, prompt_funcs, step_funcs
    end

    for i, trait_config in ipairs(raw_spec.traits) do
        local trait_id = type(trait_config) == "string" and trait_config or trait_config.id
        local trait_instance_context = type(trait_config) == "table" and trait_config.context or {}

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
            end
        end

        ::continue::
    end

    return additional_prompts, additional_tools, trait_contexts, trait_tool_schemas, additional_delegates, prompt_funcs, step_funcs
end

local function process_tools(raw_spec, additional_tools, trait_contexts, trait_tool_schemas, config)
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
            tool_entry.schema = tool_info.inline_schema
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

local function process_delegates(raw_spec, additional_delegates, config)
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

function compiler.compile(raw_spec, user_config)
    if not raw_spec then
        return nil, "Raw spec is required"
    end

    local config = merge_config(user_config)

    local additional_prompts, additional_tools, trait_contexts, trait_tool_schemas, additional_delegates, prompt_funcs, step_funcs = process_traits(
        raw_spec, config)

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
        prompt_funcs = prompt_funcs,
        step_funcs = step_funcs
    }

    return compiled_spec
end

return compiler
