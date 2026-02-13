local http = require("http")
local page_registry = require("page_registry")

local function handler()
    local req = http.request()
    local res = http.response()

    if not req or not res then
        return nil, "Failed to get HTTP context"
    end

    local page_id, err = req:param("id")
    if err or not page_id then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json({ error = "Missing page ID" })
        return
    end

    local page, page_err = page_registry.get(page_id)
    if page_err then
        res:set_status(http.STATUS.NOT_FOUND)
        res:write_json({ error = "Page not found" })
        return
    end

    if not page_registry.can_access(page) then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:write_json({ error = "Access denied" })
        return
    end

    local base_url = page_registry.resolve_base_url(page)

    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    res:write_json({
        baseUrl = base_url,
    })
end

return { handler = handler }
