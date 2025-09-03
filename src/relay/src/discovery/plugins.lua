local registry = require("registry")
local consts = require("consts")

local discovery = {}

-- Extract plugin configuration from registry entry
local function extract_plugin_config(entry)
    if not entry.meta or not entry.meta.command_prefix then
        return nil
    end

    return {
        prefix = entry.meta.command_prefix,
        process_id = entry.id,
        host = entry.meta.default_host or consts.get_config().user_hub_host,
        auto_start = entry.meta.auto_start or false
    }
end

-- Get all relay plugins from registry
function discovery.get_plugins()
    local entries, err = registry.find({
        [".kind"] = "process.lua",
        ["meta.type"] = consts.PLUGIN_META_TYPE
    })

    if err then
        return nil, "Failed to discover plugins: " .. err
    end

    if not entries or #entries == 0 then
        return {}, nil
    end

    local plugins = {}

    for _, entry in ipairs(entries) do
        local plugin_config = extract_plugin_config(entry)
        if plugin_config then
            plugins[plugin_config.prefix] = plugin_config
        end
    end

    return plugins, nil
end

return discovery