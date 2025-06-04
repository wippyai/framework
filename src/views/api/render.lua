local http = require("http")
local page_registry = require("page_registry")
local resource_registry = require("resource_registry")
local renderer = require("renderer")

local function handler()
    -- Get request and response objects
    local req = http.request()
    local res = http.response()

    if not req or not res then
        return nil, "Failed to get HTTP context"
    end

    -- Extract page ID from the request parameters
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

    -- Get the page from the registry
    local page, err = page_registry.get(page_id)

    if err then
        res:set_status(http.STATUS.NOT_FOUND)
        res:write_json({
            success = false,
            error = "Page not found",
            details = err
        })
        return
    end

    -- Check if the user can access this page
    if not page_registry.can_access(page) then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:write_json({
            success = false,
            error = "Access denied",
            details = "You do not have permission to view this page"
        })
        return
    end

    -- Extract params and query params
    local params = {}
    local query_params = {}

    -- Get route parameters if available
    if req.params then
        for name, value in pairs(req:params()) do
            params[name] = value
        end
    end

    -- Get query parameters if available
    for name, value in pairs(req:query_params()) do
        query_params[name] = value
    end

    -- Render the page with data
    local content, err = renderer.render(page_id, params, query_params, page_registry, resource_registry)

    if err then
        if err == "Access denied" then
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
                details = err
            })
        end
        return
    end

    -- Set content type and write response
    res:set_content_type(page.content_type or "text/html")
    res:set_status(http.STATUS.OK)
    res:write(content)
end

return {
    handler = handler
}
