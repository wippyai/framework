local registry = require("registry")
local security = require("security")

-- Main module
local pages = {}

-- Find all virtual pages in the registry
function pages.find_all()
    -- Query the registry for entries with type "view.page"
    local entries, err = registry.find({
        [".kind"] = "template.jet",
        ["meta.type"] = "view.page"
    })

    if err then
        return nil, "Failed to find virtual pages: " .. tostring(err)
    end

    if not entries or #entries == 0 then
        return {}
    end

    -- Transform entries to page objects with additional metadata
    local pages_list = {}
    for _, entry in ipairs(entries) do
        if entry.meta then
            local full_id = registry.parse_id(entry.id)
            local template_set = entry.data.set

            -- if not full id when use our ns
            if not template_set:find(":") then
                template_set = registry.parse_id(entry.id).ns .. ":" .. template_set
            end

            -- Handle data_func with missing namespace
            local data_func = entry.data.data_func
            if data_func and data_func ~= "" and not data_func:find(":") then
                data_func = registry.parse_id(entry.id).ns .. ":" .. data_func
            end

            -- Handle resources with missing namespace
            local resources = {}
            if entry.data.resources then
                for i, resource_id in ipairs(entry.data.resources) do
                    if not resource_id:find(":") then
                        resources[i] = registry.parse_id(entry.id).ns .. ":" .. resource_id
                    else
                        resources[i] = resource_id
                    end
                end
            end

            -- Extract key information about the page
            local page = {
                id = entry.id,
                name = entry.meta.name or "",
                title = entry.meta.title or "",
                icon = entry.meta.icon or "",
                order = entry.meta.order or 9999,
                group = entry.meta.group or "",
                group_icon = entry.meta.group_icon or "",
                group_order = entry.meta.group_order or 9999,
                group_placement = entry.meta.group_placement or "default", -- Added group_placement
                secure = entry.meta.secure or false,                            -- Security flag
                parent = entry.meta.parent,                                     -- Parent template for inheritance
                public = entry.meta.public or false,                            -- Public visibility flag\
                announced = entry.meta.announced or entry.meta.public or false, -- Announcement status
                inline = entry.meta.inline or false,                            -- Inline content flag
            }
            table.insert(pages_list, page)
        end
    end

    -- Sort by order then title for a consistent view
    table.sort(pages_list, function(a, b)
        if a.order == b.order then
            return a.title < b.title
        end
        return a.order < b.order
    end)

    return pages_list
end

-- Get a single page by ID
function pages.get(page_id)
    if not page_id then
        return nil, "Page ID is required"
    end

    -- Get the page entry from registry
    local entry, err = registry.get(page_id)
    if err or not entry then
        return nil, "Page not found: " .. (err or "unknown error")
    end

    -- Verify it's a virtual page
    if not entry.meta or entry.meta.type ~= "view.page" then
        return nil, "Invalid page type for ID: " .. page_id
    end

    local full_id = registry.parse_id(entry.id)
    local template_set = entry.data.set

    -- if not full id when use our ns
    if not template_set:find(":") then
        template_set = registry.parse_id(entry.id).ns .. ":" .. template_set
    end

    -- Handle data_func with missing namespace
    local data_func = entry.data.data_func
    if data_func and data_func ~= "" and not data_func:find(":") then
        data_func = registry.parse_id(entry.id).ns .. ":" .. data_func
    end

    -- Handle resources with missing namespace
    local resources = {}
    if entry.data.resources then
        for i, resource_id in ipairs(entry.data.resources) do
            if not resource_id:find(":") then
                resources[i] = registry.parse_id(entry.id).ns .. ":" .. resource_id
            else
                resources[i] = resource_id
            end
        end
    end

    -- todo: modify to use names publicly!

    -- Build the page object
    local page = {
        id = entry.id,
        name = entry.meta.name or "",
        title = entry.meta.title or "",
        icon = entry.meta.icon or "",
        order = entry.meta.order or 9999,
        group = entry.meta.group or "",
        group_icon = entry.meta.group_icon or "",
        group_order = entry.meta.group_order or 9999,
        group_placement = entry.meta.group_placement or "default", -- Added group_placement
        template_set = template_set,
        template_name = entry.meta.name or full_id.name,
        data_func = data_func,
        resources = resources,
        content_type = entry.meta.content_type or "text/html",
        source = entry.source or nil,         -- Direct source content if available
        secure = entry.meta.secure or false,
        parent = entry.meta.parent,           -- Parent template for inheritance
        public = entry.meta.public or false,  -- Public visibility flag
        inline = entry.meta.inline or false,  -- Inline content flag
    }

    return page
end

-- Check if the current actor can access a page
function pages.can_access(page)
    if not page.secure then
        return true -- Non-secure pages are always accessible
    end

    -- Get the current actor and scope
    local actor = security.actor()
    local scope = security.scope()

    if not actor or not scope then
        return false -- No security context, deny access to secure pages
    end

    -- Check if the actor can view the page
    local resource_id = "page:" .. page.id
    return security.can("view", resource_id)
end

return pages
