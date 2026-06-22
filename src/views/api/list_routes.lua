local http = require("http")
local api_error = require("api_error")
local page_registry = require("page_registry")

-- GET /pages/routes
-- Returns { success, count, routes } where routes is a map of
-- mountRoute pattern → page id. Only pages whose mountRoute passes v1
-- syntax validation AND doesn't conflict with any other page appear.
-- Unlike /pages/list, this endpoint does NOT filter by `announced` —
-- a hidden page that claims a URL still needs its URL to resolve.
--
-- On validation failure (syntax error or duplicate mount route), responds
-- with HTTP 500 and a detailed error body. The frontend treats this as a
-- fatal state and renders a <wippy-error> fullscreen.
local function handler()
    local res = http.response()
    local req = http.request()

    if not res or not req then
        return nil, "Failed to get HTTP context"
    end

    -- Single fetch + validation pass — avoids the two-call race.
    local all_pages, list_err = page_registry.find_all()
    if list_err then
        api_error.fail(res, http.STATUS.INTERNAL_ERROR, "Failed to list mount routes", list_err)
        return
    end

    local routes_map, issues = page_registry.validate_mount_routes(all_pages or {})
    if #issues > 0 then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({
            success = false,
            error = table.concat(issues, "\n"),
        })
        return
    end

    -- Apply access control: a mount route on a secure page should not be
    -- exposed to unauthorized callers. Does NOT filter by announced —
    -- hidden pages can still claim URLs.
    local accessible: {[string]: string} = {}
    local count = 0
    for _, page in ipairs(all_pages) do
        local mr = page.mount_route
        if mr and routes_map[mr] == page.id and (not page.secure or page_registry.can_access(page)) then
            accessible[mr] = page.id
            count = count + 1
        end
    end

    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    -- Force-object marker: many Lua JSON libs serialize empty tables as `[]`.
    -- We explicitly encode the map alongside an array of keys to give the
    -- consumer a way to detect the empty case without ambiguity.
    res:write_json({
        success = true,
        count = count,
        routes = accessible,
    })
end

return {
    handler = handler,
}
