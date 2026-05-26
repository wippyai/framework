local http = require("http")
local component_registry = require("component_registry")
local bundled_meta = require("bundled_meta")

-- GET /components/list — list every registered view.component the actor can
-- see. Each entry's `props` / `events` come from the consumer's bundled
-- wippy-meta.json (emitted by @wippy-fe/vite-plugin's wippyComponentPlugin)
-- when present, falling back to the YAML registry entry's fields otherwise.
-- Registry data supplies the routing / identity fields (id, name, tag_name,
-- base_url, entry_point, auto_register) in all cases.

type ComponentResponse = {
    id: string,
    name: string,
    title: string,
    description: string?,
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
                -- Same projection that /components/by-tag uses: YAML-first per
                -- field, bundled wippy-meta.json (when present) as fallback.
                -- Drives title/description/tag_name/entry_point/props/events.
                local meta, meta_err = bundled_meta.fetch_for_component(component)
                if meta_err then
                    print("[views/list_components] bundled_meta fetch error for "
                        .. tostring(component.id) .. ": " .. tostring(meta_err))
                    meta = nil
                end

                local base_url = component_registry.resolve_base_url(component)
                local component_info = bundled_meta.project_component_response(meta, component, base_url)

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
