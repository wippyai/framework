local http = require("http")
local component_registry = require("component_registry")

type ComponentResponse = {
    id: string,
    name: string,
    title: string,
    tag_name: string?,
    base_url: string?,
    entry_point: string?,
    auto_register: boolean,
    props: any?,
    events: any?,
}

local function handler()
    local res = http.response()
    local req = http.request()

    if not res or not req then
        return nil, "Failed to get HTTP context"
    end

    local all_components, err = component_registry.find_all()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({
            success = false,
            error = err
        })
        return
    end

    -- Optional query param: ?auto_register=true to filter auto-register components only
    local filter_auto_register = req:query("auto_register") == "true"

    local components: {ComponentResponse} = {}
    for _, component in ipairs(all_components) do
        if (not component.secure or component_registry.can_access(component)) and component.announced then
            if not filter_auto_register or component.auto_register then
                local component_info: ComponentResponse = {
                    id = type(component.id) == "string" and component.id or tostring(component.id),
                    name = type(component.name) == "string" and component.name or "",
                    title = type(component.title) == "string" and component.title or "",
                    tag_name = type(component.tag_name) == "string" and component.tag_name as string or nil,
                    base_url = component_registry.resolve_base_url(component),
                    entry_point = type(component.entry_point) == "string" and component.entry_point as string or nil,
                    auto_register = component.auto_register == true,
                    props = component.props,
                    events = component.events,
                }

                table.insert(components, component_info)
            end
        end
    end

    table.sort(components, function(a: ComponentResponse, b: ComponentResponse): boolean
        return a.name < b.name
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
