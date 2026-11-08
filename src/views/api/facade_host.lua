-- facade_host.lua
--
-- The Web Host bundle URL that fragment pages load from (fe_facade_url). A
-- Facade with the wippy.facade:host_url function returns the URL its config
-- endpoint serves: the application resolver's value, then a module
-- contribution such as wippy/cdn-web-host, then the static requirement
-- default. An older Facade has no such function, so the static default is
-- used, as before. The caller passes the runtime in `deps`:
--
--   deps.registry_get(id) -> entry, err
--   deps.call(id)         -> value, err
--   deps.log(message, fields)
local HOST_URL_FUNCTION = "wippy.facade:host_url"
local HOST_URL_REQUIREMENT = "wippy.facade:fe_facade_url"

local function static_default(deps)
    local entry = deps.registry_get(HOST_URL_REQUIREMENT)
    return entry and entry.data and entry.data.default or nil
end

local function url(deps)
    if not deps.registry_get(HOST_URL_FUNCTION) then
        return static_default(deps)
    end
    local ok, value, err = pcall(deps.call, HOST_URL_FUNCTION)
    if ok and err == nil and type(value) == "string" then
        return value
    end
    local reason
    if not ok then
        reason = tostring(value)
    elseif err ~= nil then
        reason = tostring(err)
    else
        reason = "returned " .. type(value)
    end
    deps.log("fragment gateway: Facade Host URL lookup failed, using the static default", { error = reason })
    return static_default(deps)
end

return { url = url }
