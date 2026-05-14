local http = require("http")
local component_registry = require("component_registry")

-- GET /components/by-tag/{tag} — resolve a custom-element tag name to its
-- registered view.component metadata. Used by the host proxy SDK's
-- loadByTagName() to load a peer WC without the consumer knowing any URL.
--
-- Response shape mirrors a single item from /components/list (id, name,
-- title, tag_name, base_url, entry_point, auto_register, props, events).

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

    local tag, param_err = req:param("tag")
    if param_err or not tag or tag == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json({
            success = false,
            error = "Tag name is required" .. (param_err and (": " .. tostring(param_err)) or ""),
        })
        return
    end

    local component, err = component_registry.find_by_tag_name(tag)
    if err or not component then
        res:set_status(http.STATUS.NOT_FOUND)
        res:write_json({
            success = false,
            error = err or ("No view.component registered for tag: " .. tag),
        })
        return
    end

    -- Respect announced + access control, same as /components/list.
    if not component.announced then
        res:set_status(http.STATUS.NOT_FOUND)
        res:write_json({
            success = false,
            error = "Component is not announced",
        })
        return
    end

    if component.secure and not component_registry.can_access(component) then
        res:set_status(http.STATUS.FORBIDDEN)
        res:write_json({
            success = false,
            error = "Access denied",
        })
        return
    end

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

    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        component = component_info,
    })
end

return {
    handler = handler
}
