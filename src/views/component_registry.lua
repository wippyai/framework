local registry = require("registry")
local security = require("security")
local env = require("env")

type ComponentInfo = {
    id: string,
    name: string,
    title: string,
    tag_name: string?,
    base_path: string?,
    entry_point: string?,
    auto_register: boolean,
    secure: boolean,
    announced: boolean,
    url: string?,
    props: any?,
    events: any?,
}

local components = {}

-- Extract component-specific metadata from a registry entry
local function extract_component_info(entry)
    local meta = entry.meta
    return {
        id = entry.id,
        name = meta.name or "",
        title = meta.title or "",
        tag_name = meta.tag_name,
        base_path = meta.base_path,
        entry_point = meta.entry_point or "index.js",
        auto_register = meta.auto_register or false,
        secure = meta.secure or false,
        announced = meta.announced or meta.public or false,
        url = meta.url or meta.public_url,
        props = meta.props,
        events = meta.events,
    }
end

-- Find all view components in the registry
function components.find_all()
    local entries, err = registry.find({
        ["meta.type"] = "view.component"
    })

    if err then
        return nil, "Failed to find view components: " .. tostring(err)
    end

    if not entries or #entries == 0 then
        return {}
    end

    local components_list = {}
    for _, entry in ipairs(entries) do
        if entry.meta then
            table.insert(components_list, extract_component_info(entry))
        end
    end

    table.sort(components_list, function(a, b)
        return a.name < b.name
    end)

    return components_list
end

-- Get a single component by ID
function components.get(component_id)
    if not component_id then
        return nil, "Component ID is required"
    end

    local entry, err = registry.get(component_id)
    if err or not entry then
        return nil, "Component not found: " .. (err or "unknown error")
    end

    local meta_type = entry.meta and entry.meta.type
    if meta_type ~= "view.component" then
        return nil, "Invalid component type for ID: " .. component_id
    end

    return extract_component_info(entry)
end

-- Resolve a component URL to an absolute base URL with trailing slash.
-- When base_path is set, it is appended to the URL to form the project root.
-- Entry point paths are relative to this resolved base.
function components.resolve_base_url(component)
    local base_url = component.url or ""

    -- Append base_path to get the project root
    local base_path = component.base_path or ""
    if base_path ~= "" then
        if not base_url:match("/$") then
            base_url = base_url .. "/"
        end
        base_url = base_url .. base_path
    end

    local origin = env.get("PUBLIC_API_URL") or ""

    if origin ~= "" and base_url ~= "" and not base_url:match("^https?://") then
        base_url = origin .. base_url
    end

    if base_url ~= "" and not base_url:match("/$") then
        base_url = base_url .. "/"
    end

    return base_url
end

-- Check if the current actor can access a component
function components.can_access(component)
    if not component.secure then
        return true
    end

    local actor = security.actor()
    local scope = security.scope()

    if not actor or not scope then
        return false
    end

    local resource_id = "component:" .. component.id
    return security.can("view", resource_id)
end

return components
