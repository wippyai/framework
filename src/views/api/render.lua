local http = require("http")
local page_registry = require("page_registry")
local resource_registry = require("resource_registry")
local renderer = require("renderer")

type ComponentResponse = {
    success: boolean,
    kind: string,
    page_id: string,
    url: string?,
    title: string?,
    icon: string?,
}

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

    -- Component pages return a wippy-component-1.0 package descriptor
    if page.kind == "component" then
        local proxy = page.proxy or {}
        local css = proxy.css or {}

        local base_url = page.url or ""
        if base_url ~= "" and not base_url:match("/$") then
            base_url = base_url .. "/"
        end

        res:set_content_type(http.CONTENT.JSON)
        res:set_status(http.STATUS.OK)
        res:write_json({
            name = page.name or page.id,
            version = "1.0.0",
            specification = "wippy-component-1.0",
            title = page.title,
            baseUrl = base_url,
            wippy = {
                type = "page",
                path = page.entry_point,
                proxy = {
                    enabled = proxy.enabled or false,
                    injections = {
                        css = {
                            fonts = css.fonts or false,
                            themeConfig = css.theme_config or false,
                            iframe = css.iframe or false,
                            primevue = css.prime_vue or false,
                            markdown = css.markdown or false,
                            customCss = css.custom_css or false,
                            customVariabled = css.custom_variables or false,
                        },
                        tailwindConfig = proxy.tailwind_config or false,
                        resizeObserver = proxy.resize_observer or false,
                        preventLinkClicks = proxy.prevent_link_clicks or false,
                        iconifyIcons = proxy.iconify_icons or false,
                    },
                },
            },
        })
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
