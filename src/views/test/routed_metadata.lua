local http = require("http")

-- The HTTP route is authoritative even though a file with the same path exists.
local function handler()
    local res = http.response()
    res:set_content_type("application/json")
    res:write('{"name":"@test/routed-page"}')
end

local function denied()
    local res = http.response()
    res:set_status(401)
    res:write("Authentication required")
end

return { handler = handler, denied = denied }
