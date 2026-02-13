local http = require("http")
local page_registry = require("page_registry")

type PageResponse = {
    id: string,
    name: string,
    title: string,
    icon: string,
    order: number,
    placement: string,
    group: string,
    group_icon: string,
    group_order: number,
    group_placement: string,
    secure: boolean,
    announced: boolean,
    internal: string,
    hidden: number,
}

local function handler()
    local res = http.response()
    local req = http.request()

    if not res or not req then
        return nil, "Failed to get HTTP context"
    end

    local all_pages, err = page_registry.find_all()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({
            success = false,
            error = err
        })
        return
    end

    local pages: {PageResponse} = {}
    for _, page in ipairs(all_pages) do
        if (not page.secure or page_registry.can_access(page)) and page.announced then
            local page_info: PageResponse = {
                id = type(page.id) == "string" and page.id or tostring(page.id),
                name = type(page.name) == "string" and page.name or "",
                title = type(page.title) == "string" and page.title or "",
                icon = type(page.icon) == "string" and page.icon or "",
                order = tonumber(page.order) or 9999,
                placement = type(page.placement) == "string" and page.placement or "default",
                group = type(page.group) == "string" and page.group or "",
                group_icon = type(page.group_icon) == "string" and page.group_icon or "",
                group_order = tonumber(page.group_order) or 9999,
                group_placement = type(page.group_placement) == "string" and page.group_placement or "default",
                secure = page.secure == true,
                announced = page.announced == true,
                internal = type(page.internal) == "string" and page.internal or "",
                hidden = page.inline and 1 or 0,
            }

            table.insert(pages, page_info)
        end
    end

    table.sort(pages, function(a: PageResponse, b: PageResponse): boolean
        if a.group == b.group then
            if a.order == b.order then
                return a.title < b.title
            end
            return a.order < b.order
        end

        if a.group_order == b.group_order then
            return a.group < b.group
        end
        return a.group_order < b.group_order
    end)

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
