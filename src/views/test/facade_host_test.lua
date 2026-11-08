local test = require("test")
local security = require("security")
local registry = require("registry")
local facade_host = require("facade_host")

local FUNCTION_ID = "wippy.facade:host_url"
local REQUIREMENT_ID = "wippy.facade:fe_facade_url"
local STATIC = "https://web-host.wippy.ai/webcomponents-1.0.68"
local RESOLVED = "http://app.test/cdn/web-host/webcomponents-1.0.68"

-- A fake runtime. `entries` is the registry; `call` answers wippy.facade:host_url.
local function runtime(entries, call)
    local observed = { calls = 0, logs = {} }
    local deps = {
        registry_get = function(id)
            local entry = entries[id]
            if entry == nil then return nil, "entry not found" end
            return entry, nil
        end,
        call = function(id)
            observed.calls = observed.calls + 1
            observed.called = id
            return call()
        end,
        log = function(message, fields)
            observed.logs[#observed.logs + 1] = { message = message, fields = fields }
        end,
    }
    return deps, observed
end

local function with_function(call)
    return runtime({
        [FUNCTION_ID] = { id = FUNCTION_ID, kind = "function.lua" },
        [REQUIREMENT_ID] = { data = { default = STATIC } },
    }, call)
end

local function decision(policy_id, action, resource)
    local policy, err = security.policy(policy_id)
    if not policy then
        error("missing policy " .. policy_id .. ": " .. tostring(err))
    end
    local result = policy:evaluate(security.new_actor("wippy.views.api:test", {}), action, resource, {})
    if result == "allow" or result == "deny" then
        return result
    end
    return "undefined"
end

local function define_tests()
    test.describe("fragment gateway Host URL permission", function()
        test.it("calls only wippy.facade:host_url", function()
            local policy_id = "wippy.views:facade_host_url_call_runtime"
            test.eq(decision(policy_id, "funcs.call", FUNCTION_ID), "allow")
            test.eq(decision(policy_id, "funcs.call", "wippy.facade:config_handler"), "undefined")
            test.eq(decision(policy_id, "funcs.call", "app.cdn:facade_config_contribute"), "undefined")
            test.eq(decision(policy_id, "registry.apply", FUNCTION_ID), "undefined")
        end)

        test.it("is granted to the fragment gateway", function()
            local entry = registry.get("wippy.views.api:fragment_gateway")
            local policies = entry and entry.data and entry.data.security and entry.data.security.policies or {}
            local found = false
            for _, id in ipairs(policies) do
                if id == "wippy.views:facade_host_url_call_runtime" then found = true end
            end
            test.ok(found, "fragment_gateway has wippy.views:facade_host_url_call_runtime")
        end)
    end)

    test.describe("facade_host.url", function()
        test.it("returns the URL that wippy.facade:host_url resolves", function()
            local deps, observed = with_function(function() return RESOLVED, nil end)
            test.eq(facade_host.url(deps), RESOLVED)
            test.eq(observed.calls, 1)
            test.eq(observed.called, FUNCTION_ID)
            test.eq(#observed.logs, 0)
        end)

        test.it("keeps an empty resolved URL, as the config endpoint does", function()
            local deps, observed = with_function(function() return "", nil end)
            test.eq(facade_host.url(deps), "")
            test.eq(#observed.logs, 0)
        end)

        test.it("uses the static default without a call when the facade has no host_url function", function()
            local deps, observed = runtime({ [REQUIREMENT_ID] = { data = { default = STATIC } } }, function()
                error("must not be called")
            end)
            test.eq(facade_host.url(deps), STATIC)
            test.eq(observed.calls, 0)
            test.eq(#observed.logs, 0)
        end)

        test.it("returns nil when there is no facade at all", function()
            local deps, observed = runtime({}, function() error("must not be called") end)
            test.eq(facade_host.url(deps), nil)
            test.eq(observed.calls, 0)
        end)

        test.it("logs and uses the static default when the call returns an error", function()
            local deps, observed = with_function(function() return nil, "permission denied" end)
            test.eq(facade_host.url(deps), STATIC)
            test.eq(#observed.logs, 1)
            test.eq(observed.logs[1].fields.error, "permission denied")
        end)

        test.it("logs and uses the static default when the call raises", function()
            local deps, observed = with_function(function() error("call failed") end)
            test.eq(facade_host.url(deps), STATIC)
            test.eq(#observed.logs, 1)
            test.ok(observed.logs[1].fields.error:find("call failed", 1, true) ~= nil, observed.logs[1].fields.error)
        end)

        test.it("logs and uses the static default when the call returns a non-string", function()
            local deps, observed = with_function(function() return { url = RESOLVED }, nil end)
            test.eq(facade_host.url(deps), STATIC)
            test.eq(#observed.logs, 1)
            test.eq(observed.logs[1].fields.error, "returned table")
        end)
    end)
end

return { run = test.run_cases(define_tests) }
