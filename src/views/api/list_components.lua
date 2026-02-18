local http = require("http")
local page_registry = require("page_registry")

type ComponentResponse = {
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
    announced: boolean,
    kind: string,
    url: string?,
}

local function handler()
    local res = http.response()
    local req = http.request()

    if not res or not req then
        return nil, "Failed to get HTTP context"
    end

    local all_components, err = page_registry.find_all_components()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({
            success = false,
            error = err
        })
        return
    end

    local components: {ComponentResponse} = {}
    for _, component in ipairs(all_components) do
        if (not component.secure or page_registry.can_access(component)) and component.announced then
            local component_info: ComponentResponse = {
                id = type(component.id) == "string" and component.id or tostring(component.id),
                name = type(component.name) == "string" and component.name or "",
                title = type(component.title) == "string" and component.title or "",
                icon = type(component.icon) == "string" and component.icon or "",
                order = tonumber(component.order) or 9999,
                group = type(component.group) == "string" and component.group or "",
                group_icon = type(component.group_icon) == "string" and component.group_icon or "",
                group_order = tonumber(component.group_order) or 9999,
                group_placement = type(component.group_placement) == "string" and component.group_placement or "default",
                secure = component.secure == true,
                announced = component.announced == true,
                kind = type(component.kind) == "string" and component.kind or "component",
            }

            if type(component.url) == "string" then
                component_info.url = component.url
            end

            table.insert(components, component_info)
        end
    end

    table.sort(components, function(a: ComponentResponse, b: ComponentResponse): boolean
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
        count = #components,
        components = components
    })
end

return {
    handler = handler
}
