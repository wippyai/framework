local http = require("http")
local component_registry = require("component_registry")
local bundled_meta = require("bundled_meta")

-- GET /components/by-tag/{tag} — resolve a custom-element tag name to its
-- registered view.component metadata. Used by the host proxy SDK's
-- loadByTagName() to load a peer WC without the consumer knowing any URL.
--
-- Source-of-truth: prefer the bundled wippy-meta.json (the consumer's
-- package.json `wippy` block, emitted at build time by
-- @wippy-fe/vite-plugin) for `props`, `events`, `tag_name`, `entry_point`,
-- `name`, `title`. Falls back to the YAML registry entry's `meta.*` fields
-- when bundled meta is missing or omits the specific field. See
-- `bundled_meta.project_component_response` for the per-field mapping.

type ComponentResponse = {
    id: string,
    name: string,
    version: string,
    specification: string,
    title: string,
    description: string?,
    baseUrl: string?,
    browser: string?,
    wippy: {
        tagName: string?,
        type: string,
        props: any?,
        events: any?,
        autoRegister: boolean,
    },
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

    -- Fast path: registry index lookup by meta.tag_name. This is the
    -- common case — every entry that declares its tag in YAML hits here
    -- with a single registry query.
    local component, err = component_registry.find_by_tag_name(tag)

    -- Slow path: a consumer that ships `wippy.tagName` in its bundled
    -- wippy-meta.json but does NOT declare `meta.tag_name` in the YAML
    -- registry entry will miss the fast path (the registry has no key
    -- to match against). Scan all view.components, fetch each one's
    -- bundled meta, and find the entry whose `wippy.tagName` matches.
    -- Linear in the number of view.components × one HTTP self-fetch
    -- each — first miss for any tag, then served from the bundled_meta
    -- cache on subsequent calls.
    if not component then
        local all, all_err = component_registry.find_all()
        if not all_err and all then
            for _, c in ipairs(all) do
                local meta = bundled_meta.fetch_for_component(c)
                if meta and type(meta.wippy) == "table" and meta.wippy.tagName == tag then
                    component = c
                    err = nil
                    break
                end
            end
        end
    end

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

    local meta, meta_err = bundled_meta.fetch_for_component(component)
    if meta_err then
        print("[views/find_by_tag] bundled_meta fetch error for tag=" .. tostring(tag) .. ": " .. tostring(meta_err))
        meta = nil
    end

    local base_url = component_registry.resolve_base_url(component)
    local component_info = bundled_meta.project_component_response(meta, component, base_url)

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
