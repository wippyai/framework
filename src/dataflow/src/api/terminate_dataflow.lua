local http = require("http")
local security = require("security")
local client = require("client")

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

    -- Create client instance
    local workflow_client, client_err = client.new()
    if client_err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = "Failed to initialize workflow client: " .. client_err
        })
        return
    end

    -- Terminate the workflow
    local success, err, info = workflow_client:terminate(dataflow_id)

    if not success then
        -- Determine appropriate HTTP status based on error
        local status = http.STATUS.INTERNAL_ERROR
        if err:match("not found") then
            status = http.STATUS.NOT_FOUND
        elseif err:match("already finished") then
            status = http.STATUS.BAD_REQUEST
        end

        res:set_status(status)
        res:set_content_type(http.CONTENT.JSON)
        res:write_json({
            success = false,
            error = err
        })
        return
    end

    -- Success response
    res:set_content_type(http.CONTENT.JSON)
    res:set_status(http.STATUS.OK)
    res:write_json({
        success = true,
        message = "Workflow terminated successfully",
        dataflow_id = dataflow_id,
        info = info or {}
    })
end

return {
    handler = handler
}