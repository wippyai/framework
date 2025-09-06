local http = require("http")
local security = require("security")
local dataflow_repo = require("dataflow_repo")
local node_reader = require("node_reader")

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

    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        dataflow = dataflow,
        nodes = nodes or {}
    })
end

return {
    handler = handler
}