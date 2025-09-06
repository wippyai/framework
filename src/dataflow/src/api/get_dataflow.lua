local http = require("http")
local security = require("security")
local dataflow_repo = require("dataflow_repo")
local node_reader = require("node_reader")
local data_reader = require("data_reader")

local function handler()
    local res = http.response()
    local req = http.request()

    if not res or not req then
        return nil, "Failed to get HTTP context"
    end

    -- Security check - ensure user is authenticated
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

    -- Get user ID from the authenticated actor
    local user_id = actor:id()

    -- Get dataflow ID from URL path
    local dataflow_id = req:param("id")
    if not dataflow_id or dataflow_id == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Missing dataflow ID in path"
        })
        return
    end

    -- Get the dataflow and verify ownership
    local dataflow, err = dataflow_repo.get_by_user(dataflow_id, user_id)
    if err then
        if err:match("not found") or err:match("access denied") then
            res:set_status(http.STATUS.NOT_FOUND)
            res:set_content_type(http.CONTENT.JSON)
            res:write_json({
                success = false,
                error = "Dataflow not found"
            })
            return
        end

        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Failed to retrieve dataflow: " .. err
        })
        return
    end

    -- Get nodes for this dataflow
    local nodes, nodes_err = node_reader.with_dataflow(dataflow_id):all()
    if nodes_err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Failed to retrieve nodes: " .. nodes_err
        })
        return
    end

    -- Get data for this dataflow
    local data, data_err = data_reader.with_dataflow(dataflow_id)
        :fetch_options({ resolve_references = true })
        :all()
    if data_err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Failed to retrieve data: " .. data_err
        })
        return
    end

    -- Return complete dataflow information
    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        dataflow = dataflow,
        nodes = nodes or {},
        data = data or {}
    })
end

return {
    handler = handler
}