local test = require("test")
local registry = require("registry")

local PROCESS_GROUP = "wippy.security:process"

local function has_group(groups, expected)
    for _, group in ipairs(groups or {}) do
        if group == expected then
            return true
        end
    end
    return false
end

local function value(entry: any, key: string): any
    if type(entry) ~= "table" then return nil end
    if entry[key] ~= nil then return entry[key] end
    if type(entry.data) == "table" then return entry.data[key] end
    return nil
end

local function assert_process_scope(service_id)
    local entry, err = registry.get(service_id)
    test.is_true(entry ~= nil, tostring(err or ("missing service " .. service_id)))

    local lifecycle = value(entry, "lifecycle") or {}
    local service_security = lifecycle.security or {}
    test.is_true(
        has_group(service_security.groups, PROCESS_GROUP),
        service_id .. " must run under " .. PROCESS_GROUP
    )
end

local function define_tests()
    describe("LLM background process security", function()
        it("scopes auto-start credential refreshers as platform processes", function()
            assert_process_scope("wippy.llm.google.oauth2:token_refresher.service")
            assert_process_scope("wippy.llm.bedrock:credential_refresher.service")
        end)
    end)
end

return test.run_cases(define_tests)
