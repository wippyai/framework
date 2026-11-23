local security = require("security")
local contract = require("contract")
local catalog_client = require("catalog_client")

-- Runs as the binding function: reports the actor it sees.
local function whoami()
    local actor = security.actor()
    return actor and actor:id() or nil
end

-- Runs as the caller: opens the probe contract through the module's own
-- catalog_client, the way both handlers open the catalog, and reports both
-- actors.
local function caller()
    catalog_client.CATALOG_CONTRACT = "app.api:actor_probe"
    local instance, open_err = catalog_client.open()
    if open_err then
        return nil, open_err
    end
    if not instance then
        return nil, "the probe contract has no implementation"
    end
    local binding_actor, call_err = instance:whoami()
    if call_err then
        return nil, call_err
    end
    local probe = contract.get("app.api:actor_probe")
    local implementations = probe and probe:implementations() or nil
    local actor = security.actor()
    return {
        caller = actor and actor:id() or nil,
        binding = binding_actor,
        implementations = implementations and #implementations or 0,
    }
end

return { whoami = whoami, caller = caller }
