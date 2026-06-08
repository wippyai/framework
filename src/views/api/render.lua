local http = require("http")
local page_registry = require("page_registry")
local resource_registry = require("resource_registry")
local renderer = require("renderer")
local bundled_meta = require("bundled_meta")

type ComponentResponse = {
    success: boolean,
    kind: string,
    page_id: string,
    url: string?,
    title: string?,
    icon: string?,
}

-- Synthesize a wippy-component-1.0 package descriptor from the YAML registry
-- entry. Backwards-compat path for consumers that have NOT yet adopted
-- @wippy-fe/vite-plugin's wippy-meta.json emission. Deprecated; the canonical
-- path is `bundled_meta.project_page_response`. Kept for entries that ship no
-- wippy-meta.json.
local function synthesize_from_registry(page: any, base_url: string?)
    return {
        name = page.name or page.id,
        version = "1.0.0",
        specification = "wippy-component-1.0",
        title = page.title,
        baseUrl = base_url,
        wippy = {
            type = "page",
            -- Final fallback "index.html" preserves the pre-0.4.32 wire shape.
            path = page.entry_point or "index.html",
            -- The FE owns proxy injection defaults: proxy.js (getProxyConfig)
            -- defaults EVERY injection ON when the field is absent. So send the
            -- operator's `meta.proxy` overlay as-is, or a minimal truthy block —
            -- the FE rejects a page descriptor with no wippy.proxy
            -- (isWippyPackageWebPage). To DISABLE an injection, set it false in
            -- `meta.proxy` (absence never disables).
            proxy = page.proxy or { enabled = true },
            configOverrides = page.config_overrides,
        },
    }
end

local function handler()
    local req = http.request()
    local res = http.response()

    if not req or not res then
        return nil, "Failed to get HTTP context"
    end

    local page_id, err = req:param("id")

    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({
            success = false,
            error = "Parameter extraction error",
            details = err
        })
        return
    end

    if not page_id then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json({
            success = false,
            error = "Missing page ID",
            details = "A page ID must be provided in the URL"
        })
        return
    end

    local page, page_err = page_registry.get(page_id)

    if page_err then
        res:set_status(http.STATUS.NOT_FOUND)
        res:write_json({
            success = false,
            error = "Page not found",
            details = page_err
        })
        return
    end

    if not page_registry.can_access(page) then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:write_json({
            success = false,
            error = "Access denied",
            details = "You do not have permission to view this page"
        })
        return
    end

    -- Component pages return a wippy-component-1.0 package descriptor.
    --
    -- Source-of-truth: prefer the bundled wippy-meta.json (the consumer's
    -- package.json `wippy` block, emitted at build time by
    -- @wippy-fe/vite-plugin). YAML registry entry contributes routing
    -- fields (id, base_url) and the variant-overlay `meta.config_overrides`.
    -- The two are combined by `bundled_meta.project_page_response`, which
    -- produces the same wippy-component-1.0 spec shape as the legacy
    -- synthesis — see views/README.md "Bundled meta vs YAML" for the
    -- field-by-field mapping.
    if page.kind == "component" then
        local base_url = page_registry.resolve_base_url(page)

        local meta, meta_err = bundled_meta.fetch_for_page(page)
        if meta_err then
            print("[views/render] bundled_meta fetch error for " .. tostring(page_id) .. ": " .. tostring(meta_err))
            meta = nil
        end

        local body
        if meta then
            body = bundled_meta.project_page_response(meta, page, base_url)
        else
            body = synthesize_from_registry(page, base_url)
        end

        res:set_content_type(http.CONTENT.JSON)
        res:set_status(http.STATUS.OK)
        res:write_json(body)
        return
    end

    local params: {[string]: string} = {}
    local query_params: {[string]: string} = {}

    if req.params then
        for name, value in pairs(req:params()) do
            params[name] = value
        end
    end

    for name, value in pairs(req:query_params()) do
        query_params[name] = value
    end

    local content, render_err = renderer.render(page_id, params, query_params)

    if render_err then
        if render_err == "Access denied" then
            res:set_status(http.STATUS.UNAUTHORIZED)
            res:write_json({
                success = false,
                error = "Access denied",
                details = "You do not have permission to view this page"
            })
        else
            res:set_status(http.STATUS.INTERNAL_ERROR)
            res:write_json({
                success = false,
                error = "Failed to render page",
                details = render_err
            })
        end
        return
    end

    res:set_content_type(tostring(page.content_type or "text/html"))
    res:set_status(http.STATUS.OK)
    res:write(content)
end

return {
    handler = handler
}
