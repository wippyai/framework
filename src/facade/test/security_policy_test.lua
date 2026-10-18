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

local function define_tests()
    test.describe("wippy.facade security policies", function()
        test.it("grants facade config registry and public API env reads only", function()
            test.eq(decision("wippy.facade:config_read_runtime", "registry.get", "wippy.facade:fe_facade_url"), "allow")
            test.eq(decision("wippy.facade:config_read_runtime", "env.get", "PUBLIC_API_URL"), "allow")
            test.eq(decision("wippy.facade:config_read_runtime", "env.get", "ENCRYPTION_KEY"), "undefined")
            test.eq(decision("wippy.facade:config_read_runtime", "registry.apply", "wippy.facade:fe_facade_url"), "undefined")
            -- index_handler loads its Jet shell via templates.get, gated on template.get
            test.eq(decision("wippy.facade:config_read_runtime", "template.get", "wippy.facade:templates"), "allow")
        end)

        test.it("grants only filesystem open for fs-backed theming", function()
            test.eq(decision("wippy.facade:content_fs_runtime", "fs.get", "app:app_fs"), "allow")
            test.eq(decision("wippy.facade:content_fs_runtime", "db.get", "app:db"), "undefined")
        end)

        test.it("calls only module-owned configuration contributors", function()
            local policy_id = "wippy.facade:config_contributor_call_runtime"
            test.eq(decision(policy_id, "funcs.call", "app.adapter:facade_config_contribute"), "allow")
            test.eq(decision(policy_id, "funcs.call", "app.branding:facade_config_contribute"), "allow")
            for _, resource in ipairs({
                "app:writer",
                "app.branding:facade_config_contribute_extra",
                "app.bad namespace:facade_config_contribute",
            }) do
                test.eq(decision(policy_id, "funcs.call", resource), "undefined")
            end
            test.eq(decision(policy_id, "registry.apply", "app.branding:facade_config_contribute"), "undefined")
            test.eq(decision(policy_id, "db.get", "app:db"), "undefined")
        end)

        test.it("reads only module-owned configuration contributor entries", function()
            local policy_id = "wippy.facade:config_contributor_read_runtime"
            test.eq(decision(policy_id, "registry.get", "app.branding:facade_config_contribute"), "allow")
            test.eq(decision(policy_id, "registry.get", "app.branding:private_settings"), "undefined")
        end)

        test.it("allows read-only discovery of declared configuration contributors", function()
            test.eq(decision("wippy.facade:config_contributor_discovery_runtime", "registry.find", "*"), "allow")
            test.eq(decision("wippy.facade:config_contributor_discovery_runtime", "registry.apply", "*"), "undefined")
        end)
    end)
end

return { run = test.run_cases(define_tests) }
