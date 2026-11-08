local registry = require("registry")

-- Test configuration contributor. It supplies fe_facade_url only while the
-- test entry app:contributed_host_url holds a non-empty URL, so other tests
-- see no contribution. Like wippy/cdn-web-host, it defers to an explicit
-- resolver value.
local function contribute(payload: any): table
    local entry = registry.get("app:contributed_host_url")
    local url = entry and entry.data and entry.data.default
    if type(url) ~= "string" or url == "" then
        return { overrides = {} }
    end
    if type(payload) == "table" and type(payload.overrides) == "table"
        and payload.overrides.fe_facade_url ~= nil then
        return { overrides = {} }
    end
    return { overrides = { fe_facade_url = url } }
end

return { contribute = contribute }
