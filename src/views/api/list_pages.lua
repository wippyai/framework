local http = require("http")
local page_registry = require("page_registry")
local registry = require("registry")

local function handler()
    -- Get response object
    local res = http.response()
    local req = http.request()

    if not res or not req then
        return nil, "Failed to get HTTP context"
    end

    -- Get all template pages
    local template_pages, err = page_registry.find_all()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({
            success = false,
            error = err
        })
        return
    end

    -- Directly query registry for registry.entry pages with meta.type view.page
    local internal_entries, err = registry.find({
        [".kind"] = "registry.entry",
        ["meta.type"] = "view.page"
    })

    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({
            success = false,
            error = "Failed to find internal pages: " .. tostring(err)
        })
        return
    end

    -- Process internal registry entries
    local internal_pages = {}
    if internal_entries and #internal_entries > 0 then
        for _, entry in ipairs(internal_entries) do
            if entry.meta then
                -- Create page object from registry.entry
                local page = {
                    id = entry.id,
                    name = entry.meta.name or "",
                    title = entry.meta.title or "",
                    icon = entry.meta.icon or "",
                    order = entry.meta.order or 9999,
                    placement = entry.meta.placement or "default",
                    group = entry.meta.group or "",
                    group_icon = entry.meta.group_icon or "",
                    group_order = entry.meta.group_order or 9999,
                    group_placement = entry.meta.group_placement or "default",
                    secure = entry.meta.secure or false,
                    announced = entry.meta.announced or false,
                    internal = entry.meta.internal or "",
                    hidden = entry.meta.inline and 1 or 0,
                }
                table.insert(internal_pages, page)
            end
        end
    end

    -- Combine both types of pages
    local all_pages = {}
    for _, page in ipairs(template_pages) do
        table.insert(all_pages, page)
    end
    for _, page in ipairs(internal_pages) do
        table.insert(all_pages, page)
    end

    -- Check if we should only include announced pages
    local announced_only = true -- Default to only announced pages

    -- Filter pages based on security and announcement status
    local pages = {}
    for _, page in ipairs(all_pages) do
        -- Only include pages that:
        -- 1. User has access to (not secure OR user has permission)
        -- 2. Are announced (unless include_all is specified)
        if (not page.secure or page_registry.can_access(page)) and
            (not announced_only or page.announced) then
            local hidden = 0
            if page.inline then
                hidden = 1
            end

            -- Create simplified page object with only necessary metadata
            local page_info = {
                id = page.id,
                name = page.name or "",
                title = page.title or "",
                icon = page.icon or "",
                order = page.order or 9999,
                placement = page.placement or "default",
                group = page.group or "",
                group_icon = page.group_icon or "",
                group_order = page.group_order or 9999,
                group_placement = page.group_placement or "default",
                secure = page.secure or false,
                announced = page.announced or false,
                internal = page.internal or "",
                hidden = page.hidden or hidden
            }

            table.insert(pages, page_info)
        end
    end

    -- Sort by order then title
    table.sort(pages, function(a, b)
        if a.group == b.group then
            if a.order == b.order then
                return a.title < b.title
            end
            return a.order < b.order
        end

        -- Different groups, sort by group_order
        if a.group_order == b.group_order then
            return a.group < b.group -- Alphabetical by group if same order
        end
        return a.group_order < b.group_order
    end)

    -- Return JSON response
    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        count = #pages,
        pages = pages
    })
end

return {
    handler = handler
}
