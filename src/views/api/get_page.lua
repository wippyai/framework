local http = require("http")
local page_registry = require("page_registry")

local function handler()
    local req = http.request()
    local res = http.response()
    if not req or not res then
        return nil, "Failed to get HTTP context"
    end

    local id, err = req:param("id")
    if err or not id then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json({ error = "Missing page ID" })
        return
    end

    local page, page_err = page_registry.get(id)
    if page_err or not page then
        res:set_status(http.STATUS.NOT_FOUND)
        res:write_json({ error = "Page not found" })
        return
    end
    if not page_registry.can_access(page) then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:write_json({ error = "Access denied" })
        return
    end

    res:set_content_type(http.CONTENT.JSON)
    res:write_json({
        id = page.id,
        title = page.title or page.name or page.id,
        content_type = page.content_type,
    })
end

return { handler = handler }
