local registry = require("registry")

-- Main module
local resources = {}

-- Find all resources in the registry
function resources.find_all()
    -- Query the registry for entries with type "view.resource"
    local entries, err = registry.find({
        [".kind"] = "registry.entry",
        ["meta.type"] = "view.resource"
    })

    if err then
        return nil, "Failed to find resources: " .. err
    end

    if not entries or #entries == 0 then
        return {}
    end

    -- Transform entries to resource objects
    local result = {}
    for _, entry in ipairs(entries) do
        if entry.meta then
            -- Extract resource information
            local resource = {
                id = entry.id,
                name = entry.meta.name or "",
                resource_type = entry.meta.resource_type or "other", -- style, script, font, etc.
                order = entry.meta.order or 9999,
                global = entry.meta.global or false,
                template_set = entry.meta.template_set,
                url = entry.meta.url,
                inline = entry.meta.inline,
                integrity = entry.meta.integrity,
                crossorigin = entry.meta.crossorigin,
                media = entry.meta.media, -- For stylesheets
                defer = entry.meta.defer, -- For scripts
                async = entry.meta.async, -- For scripts
            }

            result[entry.id] = resource
        end
    end

    return result
end

-- Get a single resource by ID
function resources.get(resource_id)
    if not resource_id then
        return nil, "Resource ID is required"
    end

    -- Get from registry
    local entry, err = registry.get(resource_id)
    if err or not entry then
        return nil, "Resource not found: " .. (err or "unknown error")
    end

    -- Verify it's a page resource
    if not entry.meta or entry.meta.type ~= "view.resource" then
        return nil, "Invalid resource type for ID: " .. resource_id
    end

    -- Build resource object
    local resource = {
        id = entry.id,
        name = entry.meta.name or "",
        resource_type = entry.meta.resource_type or "other",
        order = entry.meta.order or 9999,
        global = entry.meta.global or false,
        template_set = entry.meta.template_set,
        url = entry.meta.url,
        inline = entry.meta.inline,
        integrity = entry.meta.integrity,
        crossorigin = entry.meta.cross_origin or entry.meta.crossorigin,
        media = entry.meta.media,
        defer = entry.meta.defer,
        async = entry.meta.async,
    }

    return resource
end

-- Group resources by type
function resources.group_by_type(resources_list)
    local grouped = {}

    for id, resource in pairs(resources_list) do
        local resource_type = resource.resource_type

        if not grouped[resource_type] then
            grouped[resource_type] = {}
        end

        table.insert(grouped[resource_type], resource)
    end

    -- Sort each group by order
    for _, group in pairs(grouped) do
        table.sort(group, function(a, b)
            return a.order < b.order
        end)
    end

    return grouped
end

-- Get global resources
function resources.get_globals(resources_list)
    local globals = {}

    for id, resource in pairs(resources_list) do
        if resource.global then
            globals[id] = resource
        end
    end

    return globals
end

-- Get resources for a specific template set
function resources.get_template_set_resources(resources_list, template_set_id)
    local template_resources = {}

    for id, resource in pairs(resources_list) do
        if resource.template_set and resource.template_set == template_set_id then
            template_resources[id] = resource
        end
    end

    return template_resources
end

-- Collect all resources for a page, including inherited and global ones
function resources.collect_for_page(page, page_registry, all_resources)
    if not all_resources then
        -- Get all resources from registry if not provided
        local res_list, err = resources.find_all()
        if err then
            return {}, "Failed to collect resources: " .. err
        end
        all_resources = res_list
    end

    -- Start with global resources
    local page_resources = {}
    local global_resources = resources.get_globals(all_resources)

    for id, resource in pairs(global_resources) do
        page_resources[id] = resource
    end

    -- Add template-set specific resources if page has a template set
    if page.template_set then
        local template_resources = resources.get_template_set_resources(all_resources, page.template_set)
        for id, resource in pairs(template_resources) do
            page_resources[id] = resource
        end
    end

    -- Add page-specific resources
    if page.resources and #page.resources > 0 then
        for _, resource_id in ipairs(page.resources) do
            if all_resources[resource_id] then
                page_resources[resource_id] = all_resources[resource_id]
            end
        end
    end

    return page_resources
end

return resources