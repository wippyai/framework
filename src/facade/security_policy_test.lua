local test = require("test")
local security = require("security")

local function load_policy(id: string)
    local policy, err = security.policy(id)
    if not policy then
        error("missing policy " .. id .. ": " .. tostring(err))
    end
    return policy
end

local function decision(policy_id: string, action: string, resource: string): string
    local actor = security.new_actor("wippy.facade:test", {})
    local result = load_policy(policy_id):evaluate(actor, action, resource, {})
    if result == "allow" or result == "deny" then
        return result
    end
    return "undefined"
end

local function run()
    test.describe("wippy.facade security policies", function()
        test.it("grants facade config registry and public API env reads only", function()
            test.eq(decision("wippy.facade:config_read_runtime", "registry.get", "wippy.facade:fe_facade_url"), "allow")
            test.eq(decision("wippy.facade:config_read_runtime", "env.get", "PUBLIC_API_URL"), "allow")
            test.eq(decision("wippy.facade:config_read_runtime", "env.get", "ENCRYPTION_KEY"), "undefined")
            test.eq(decision("wippy.facade:config_read_runtime", "registry.apply", "wippy.facade:fe_facade_url"), "undefined")
        end)

        test.it("grants only filesystem open for fs-backed theming", function()
            test.eq(decision("wippy.facade:content_fs_runtime", "fs.get", "app:app_fs"), "allow")
            test.eq(decision("wippy.facade:content_fs_runtime", "db.get", "app:db"), "undefined")
        end)
    end)
end

return { run = run }
