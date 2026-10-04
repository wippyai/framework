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
    local actor = security.new_actor("wippy.views.api:test", {})
    local result = load_policy(policy_id):evaluate(actor, action, resource, {})
    if result == "allow" or result == "deny" then
        return result
    end
    return "undefined"
end

local function run()
    test.describe("wippy.views public security policies", function()
        test.it("grants public view registry discovery without registry writes", function()
            test.eq(decision("wippy.views:public_registry_runtime", "registry.get", "app.views:main"), "allow")
            test.eq(decision("wippy.views:public_registry_runtime", "registry.find", "kickside.oauth.views:oauth_callback"), "allow")
            test.eq(decision("wippy.views:public_registry_runtime", "registry.apply", "app.views:main"), "undefined")
        end)

        test.it("grants only browser-safe env reads", function()
            test.eq(decision("wippy.views:public_env_runtime", "env.get", "PUBLIC_API_URL"), "allow")
            test.eq(decision("wippy.views:public_env_runtime", "env.get", "PUBLIC_FOO"), "allow")
            test.eq(decision("wippy.views:public_env_runtime", "env.get", "userspace.dataflow.env:web_host_origin"), "allow")
            test.eq(decision("wippy.views:public_env_runtime", "env.get", "ENCRYPTION_KEY"), "undefined")
        end)

        test.it("grants bundled metadata fetch and warning store only", function()
            test.eq(decision("wippy.views:public_metadata_http_runtime", "http_client.request", "http://localhost:8085/app/main/wippy-meta.json"), "allow")
            test.eq(decision("wippy.views:public_metadata_private_ip_runtime", "http_client.private_ip", "127.0.0.1"), "allow")
            test.eq(decision("wippy.views:public_metadata_store_runtime", "store.get", "wippy.views:bundled_meta_warn"), "allow")
            test.eq(decision("wippy.views:public_metadata_store_runtime", "store.get", "app:cache"), "undefined")
        end)

        test.it("grants template data function calls without process primitives", function()
            test.eq(decision("wippy.views:public_data_func_runtime", "funcs.call", "kickside.oauth.views:oauth_callback.data"), "allow")
            test.eq(decision("wippy.views:public_data_func_runtime", "funcs.call", "app.views:main.data"), "allow")
            test.eq(decision("wippy.views:public_data_func_runtime", "funcs.call", "wippy.session.funcs:title"), "undefined")
            test.eq(decision("wippy.views:public_data_func_runtime", "process.spawn", "wippy.session.process:session"), "undefined")
        end)
    end)
end

return { run = run }
