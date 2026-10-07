local page_registry = require("page_registry")

-- Test seam: exposes can_access as a funcs.call target so tests can override
-- the security actor/scope for the call (funcs.new():with_actor():with_scope()),
-- which a direct library call cannot do.
local function run(page)
    return page_registry.can_access(page)
end

return { run = run }
