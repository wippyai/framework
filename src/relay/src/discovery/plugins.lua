local registry = require("registry")
local consts = require("consts")

type PluginConfig = {
    prefix: string,
    process_id: string,
    host: string?,
    auto_start: boolean,
}

local discovery = {}

local function extract_plugin_config(entry: any): PluginConfig?
    if not entry.meta or not entry.meta.command_prefix then
        return nil
    end

    return {
        prefix = string(entry.meta.command_prefix),
        process_id = string(entry.id),
        host = entry.meta.default_host or consts.get_config().user_hub_host,
        auto_start = entry.meta.auto_start or false
    } :: PluginConfig
end

function discovery.get_plugins(): ({[string]: PluginConfig}?, string?)
    local entries, err = registry.find({
        [".kind"] = "process.lua",
        ["meta.type"] = consts.PLUGIN_META_TYPE
    })

    if err then
        return nil, "Failed to discover plugins: " .. tostring(err)
    end

    if not entries or #entries == 0 then
        return {}, nil
    end

    local plugins: {[string]: PluginConfig} = {}

    for _, entry in ipairs(entries) do
        local plugin_config = extract_plugin_config(entry)
        if plugin_config then
            plugins[plugin_config.prefix] = plugin_config
        end
    end

    return plugins, nil
end

return discovery
