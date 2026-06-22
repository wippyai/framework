local log = require("logger"):named("wippy.views.api")

local api_error = {}

function api_error.fail(res, status, message, err)
    if err ~= nil then
        log:error(message, { error = tostring(err) })
    end

    res:set_status(status)
    res:write_json({
        success = false,
        error = message
    })
end

return api_error
