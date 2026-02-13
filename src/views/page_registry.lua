local registry = require("registry")
local security = require("security")
local env = require("env")

type ProxyCss = {
    fonts: boolean,
    theme_config: boolean,
    iframe: boolean,
    prime_vue: boolean,
    markdown: boolean,
    custom_css: boolean,
    custom_variables: boolean,
}

type ProxyConfig = {
    enabled: boolean,
    css: ProxyCss,
    tailwind_config: boolean,
    resize_observer: boolean,
    prevent_link_clicks: boolean,
    iconify_icons: boolean,
}

type PageInfo = {
    id: string,
    name: string,
    title: string,
    icon: string,
    order: number,
    group: string,
    group_icon: string,
    group_order: number,
    group_placement: string,
    secure: boolean,
    parent: string?,
    public: boolean,
    announced: boolean,
    inline: boolean,
    kind: string,
    url: string?,
}

type PageDetail = PageInfo & {
    template_set: string?,
    template_name: string?,
    data_func: string?,
    resources: {string}?,
    content_type: string,
    source: string?,
    proxy: ProxyConfig?,
    entry_point: string?,
}

local DEFAULT_PROXY = {
    enabled = true,
    css = {
        fonts = true,
        theme_config = true,
        iframe = true,
        prime_vue = false,
        markdown = false,
        custom_css = false,
        custom_variables = false,
    },
    tailwind_config = false,
    resize_observer = true,
    prevent_link_clicks = true,
    iconify_icons = false,
}

-- Deep merge tables: values from override take precedence, missing keys use base
local function deep_merge(base, override)
    local result = {}
    for k, v in pairs(base) do
        if type(v) == "table" and type(override[k]) == "table" then
            result[k] = deep_merge(v, override[k])
        elseif override[k] ~= nil then
            result[k] = override[k]
        else
            result[k] = v
        end
    end
    return result
end

-- Build proxy config by merging entry data over defaults
local function build_proxy(entry_proxy)
    if not entry_proxy then
        return DEFAULT_PROXY
    end
    return deep_merge(DEFAULT_PROXY, entry_proxy)
end

local pages = {}

-- Qualify a relative ID with the entry's namespace
local function qualify_id(entry_id, relative_id)
    if relative_id:find(":") then
        return relative_id
    end
    return registry.parse_id(entry_id).ns .. ":" .. relative_id
end

-- Determine the page kind from the registry entry kind
local function detect_kind(entry_kind)
    if entry_kind == "template.jet" then
        return "template"
    end
    return "component"
end

-- Extract common page metadata from a registry entry
local function extract_page_info(entry)
    local meta = entry.meta
    local kind = detect_kind(entry.kind)

    local info = {
        id = entry.id,
        name = meta.name or "",
        title = meta.title or "",
        icon = meta.icon or "",
        order = meta.order or 9999,
        group = meta.group or "",
        group_icon = meta.group_icon or "",
        group_order = meta.group_order or 9999,
        group_placement = meta.group_placement or "default",
        secure = meta.secure or false,
        parent = meta.parent,
        public = meta.public or false,
        announced = meta.announced or meta.public or false,
        inline = meta.inline or false,
        kind = kind,
    }

    if kind == "component" then
        info.url = meta.url or meta.public_url
    end

    return info
end

-- Find all virtual pages in the registry
function pages.find_all()
    local entries, err = registry.find({
        ["meta.type"] = "view.page"
    })

    if err then
        return nil, "Failed to find virtual pages: " .. tostring(err)
    end

    if not entries or #entries == 0 then
        return {}
    end

    local pages_list = {}
    for _, entry in ipairs(entries) do
        if entry.meta then
            table.insert(pages_list, extract_page_info(entry))
        end
    end

    table.sort(pages_list, function(a, b)
        if a.order == b.order then
            return a.title < b.title
        end
        return a.order < b.order
    end)

    return pages_list
end

-- Find all view components in the registry
function pages.find_all_components()
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
            table.insert(components_list, extract_page_info(entry))
        end
    end

    table.sort(components_list, function(a, b)
        if a.order == b.order then
            return a.title < b.title
        end
        return a.order < b.order
    end)

    return components_list
end

-- Get a single page by ID
function pages.get(page_id)
    if not page_id then
        return nil, "Page ID is required"
    end

    local entry, err = registry.get(page_id)
    if err or not entry then
        return nil, "Page not found: " .. (err or "unknown error")
    end

    local meta_type = entry.meta and entry.meta.type
    if meta_type ~= "view.page" and meta_type ~= "view.component" then
        return nil, "Invalid page type for ID: " .. page_id
    end

    local kind = detect_kind(entry.kind)
    local full_id = registry.parse_id(entry.id)

    local page = {
        id = entry.id,
        name = entry.meta.name or "",
        title = entry.meta.title or "",
        icon = entry.meta.icon or "",
        order = entry.meta.order or 9999,
        group = entry.meta.group or "",
        group_icon = entry.meta.group_icon or "",
        group_order = entry.meta.group_order or 9999,
        group_placement = entry.meta.group_placement or "default",
        secure = entry.meta.secure or false,
        parent = entry.meta.parent,
        public = entry.meta.public or false,
        announced = entry.meta.announced or entry.meta.public or false,
        inline = entry.meta.inline or false,
        kind = kind,
        content_type = entry.meta.content_type or "text/html",
    }

    if kind == "template" then
        local template_set = entry.data.set
        template_set = qualify_id(entry.id, template_set)

        local data_func = entry.data.data_func
        if data_func and data_func ~= "" then
            data_func = qualify_id(entry.id, data_func)
        end

        local resources = {}
        if entry.data.resources then
            for i, resource_id in ipairs(entry.data.resources) do
                resources[i] = qualify_id(entry.id, resource_id)
            end
        end

        page.template_set = template_set
        page.template_name = entry.meta.name or full_id.name
        page.data_func = data_func
        page.resources = resources
        page.source = rawget(entry, "source")
    else
        page.url = entry.meta.url or entry.meta.public_url
        page.proxy = build_proxy(entry.data and entry.data.proxy)

        local default_entry_point = "index.html"
        if meta_type == "view.component" then
            default_entry_point = "index.js"
        end
        page.entry_point = entry.meta.entry_point or default_entry_point
    end

    return page
end

-- Resolve a page URL to an absolute base URL with trailing slash
function pages.resolve_base_url(page)
    local base_url = page.url or ""

    local entry = registry.get("wippy.views:page_registry")
    local env_name = entry and entry.meta and entry.meta.api_url_env or "PUBLIC_API_URL"
    local origin = env.get(env_name) or ""

    if origin ~= "" and base_url ~= "" and not base_url:match("^https?://") then
        base_url = origin .. base_url
    end

    if base_url ~= "" and not base_url:match("/$") then
        base_url = base_url .. "/"
    end

    return base_url
end

-- Check if the current actor can access a page
function pages.can_access(page)
    if not page.secure then
        return true
    end

    local actor = security.actor()
    local scope = security.scope()

    if not actor or not scope then
        return false
    end

    local resource_id = "page:" .. page.id
    return security.can("view", resource_id)
end

return pages
