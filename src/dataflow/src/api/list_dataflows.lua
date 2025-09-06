local http = require("http")
local security = require("security")
local dataflow_repo = require("dataflow_repo")

local function handler()
    local res = http.response()
    local req = http.request()

    if not res or not req then
        return nil, "Failed to get HTTP context"
    end

    local actor = security.actor()
    if not actor then
        res:set_status(http.STATUS.UNAUTHORIZED)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Authentication required"
        })
        return
    end

    local user_id = actor:id()

    local limit = tonumber(req:query("limit")) or 10
    local offset = tonumber(req:query("offset")) or 0
    local status_filter = req:query("status")

    if limit > 100 then
        limit = 100
    elseif limit < 1 then
        limit = 1
    end

    local filters = {
        limit = limit,
        offset = offset
    }

    if status_filter and status_filter ~= "" then
        filters.status = status_filter
    end

    local dataflows, err = dataflow_repo.list_by_user(user_id, filters)
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = err
        })
        return
    end

    local total_count, count_err = dataflow_repo.count_by_user(user_id, {
        status = filters.status,
        type = filters.type,
        parent_dataflow_id = filters.parent_dataflow_id
    })

    if count_err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = count_err
        })
        return
    end

    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        dataflows = dataflows,
        count = total_count
    })
end

return {
    handler = handler
}