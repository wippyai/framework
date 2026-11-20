local security = require("security")
local contract = require("contract")

-- Runs as the binding function: reports the actor it sees.
local function whoami()
    local actor = security.actor()
    return actor and actor:id() or nil
end

-- Runs as the caller: opens the contract the way the handlers open the
-- catalog (contract.get, :implementations(), :open()) and reports both actors.
local function caller()
    local probe, err = contract.get("app.api:actor_probe")
    if err then
        return nil, err
    end
    local implementations, implementations_err = probe:implementations()
    if implementations_err then
        return nil, implementations_err
    end
    local instance, open_err = probe:open()
    if open_err then
        return nil, open_err
    end
    local binding_actor, call_err = instance:whoami()
    if call_err then
        return nil, call_err
    end
    local actor = security.actor()
    return {
        caller = actor and actor:id() or nil,
        binding = binding_actor,
        implementations = implementations and #implementations or 0,
    }
end

return { whoami = whoami, caller = caller }
