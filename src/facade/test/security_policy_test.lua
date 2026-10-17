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

        for _, policy_id in ipairs({
            "wippy.facade:cdn_source_resolver_runtime",
            "wippy.facade:cdn_source_public_resolver_runtime",
        }) do
            test.it("restricts " .. policy_id .. " to discovery and local-source functions", function()
                test.eq(decision(policy_id, "funcs.call", "wippy.cdn:discover_local_sources"), "allow")
                test.eq(decision(policy_id, "funcs.call", "wippy.cdn.iconify:local_source"), "allow")
                test.eq(decision(policy_id, "funcs.call", "wippy.cdn.npm:local_source"), "allow")
                for _, resource in ipairs({
                    "wippy.cdn:writer",
                    "wippy.cdn.iconify:download",
                    "wippy.cdnEvil:local_source",
                    "wippy.cdn.iconify:local_source_extra",
                    "app:local_source",
                }) do
                    test.eq(decision(policy_id, "funcs.call", resource), "undefined")
                end
                test.eq(decision(policy_id, "registry.apply", "wippy.cdn.iconify:local_source"), "undefined")
                test.eq(decision(policy_id, "env.get", "ENCRYPTION_KEY"), "undefined")
            end)
        end
    end)
end

return { run = test.run_cases(define_tests) }
