local contract = require("contract")

local M = {
    _contract = contract,
}

M.CATALOG_CONTRACT = "wippy.session_util:catalog"

-- The bound catalog, or nil when no application binds one. A bound catalog
-- that cannot be opened returns an error: falling back to the built-in rule
-- then could show an agent or tool that the application hides.
function M.open()
    local catalog, err = M._contract.get(M.CATALOG_CONTRACT)
    if err then
        return nil, err
    end
    local implementations, implementations_err = catalog:implementations()
    if implementations_err then
        return nil, implementations_err
    end
    if not implementations or #implementations == 0 then
        return nil
    end
    local instance, open_err = catalog:open()
    if open_err then
        return nil, open_err
    end
    return instance
end

return M
