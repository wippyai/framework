local contract = require("contract")
local logger = require("logger")

local M = {
    _contract = contract,
    _logger = logger,
}

M.CATALOG_CONTRACT = "wippy.session_util:catalog"

-- The routes then answer with no agent and no tools, which looks the same as
-- an unknown name, so the cause goes to the log.
local function failed(err)
    M._logger:warn("session-util catalog is not available", { error = tostring(err) })
    return nil, err
end

-- The bound catalog, or nil when no application binds one. A bound catalog
-- that cannot be opened returns an error: falling back to the built-in rule
-- then could show an agent or tool that the application hides.
function M.open()
    local catalog, err = M._contract.get(M.CATALOG_CONTRACT)
    if err then
        return failed(err)
    end
    local implementations, implementations_err = catalog:implementations()
    if implementations_err then
        return failed(implementations_err)
    end
    if not implementations or #implementations == 0 then
        return nil
    end
    local instance, open_err = catalog:open()
    if open_err then
        return failed(open_err)
    end
    return instance
end

-- Calls one method of an opened catalog. A failing call gives nil, the same
-- answer as a call that finds nothing, so nothing hidden is shown.
function M.call(instance, method: string, input)
    local result, err = instance[method](instance, input)
    if err then
        M._logger:warn("session-util catalog call failed", { method = method, error = tostring(err) })
        return nil
    end
    return result
end

return M
