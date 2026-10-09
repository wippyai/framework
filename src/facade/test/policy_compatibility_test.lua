local test = require("test")
local http_client = require("http_client")
local json = require("json")
local registry = require("registry")

local NS = "wippy.facade:"
local REQUIREMENTS = {
    "fe_facade_url", "host_policy_mode", "allow_select_model", "hide_session_selector", "allow_additional_tags",
}

local function set_requirements(values)
    local changes = registry.snapshot():changes()
    for name, value in pairs(values) do
        changes:update({ id = NS .. name, kind = "ns.requirement", data = { default = value } })
    end
    local _, err = changes:apply()
    test.is_nil(err)
end

local function request_config()
    local gateway = registry.get("app:gateway")
    test.not_nil(gateway)
    local response, err = http_client.get("http://127.0.0.1" .. gateway.data.addr .. "/api/public/facade/config", { timeout = 5 })
    test.is_nil(err)
    test.not_nil(response)
    return response
end

local function fetch_config()
    local response = request_config()
    test.eq(response.status_code, 200)
    local body = response.body or ""
    local config, decode_err = json.decode(body)
    test.is_nil(decode_err)
    return config, body
end

local function define_tests()
    test.describe("config endpoint policy compatibility", function()
        local saved = {}

        test.before_each(function()
            saved = {}
            for _, name in ipairs(REQUIREMENTS) do
                saved[name] = registry.get(NS .. name).data.default
            end
        end)

        test.after_each(function()
            set_requirements(saved)
        end)

        test.it("keeps model restrictions and nondefault policy for a Host 1.0.61 override", function()
            set_requirements({
                fe_facade_url = "https://web-host.wippy.ai/webcomponents-1.0.61",
                allow_select_model = "false",
                hide_session_selector = "true",
                allow_additional_tags = '{"w-chart":["data","type"]}',
            })
            local config = fetch_config()
            test.eq(config.facade_url, "https://web-host.wippy.ai/webcomponents-1.0.61")
            test.eq(config.schema_url, config.facade_url .. "/schemas/wippy-context-2.0.xsd")
            test.is_false(config.allowSelectModel)
            test.is_false(config.hostConfig.allowSelectModel)
            test.is_true(config.hideSessionSelector)
            test.is_true(config.hostConfig.hideSessionSelector)
            test.eq(config.allowAdditionalTags["w-chart"][1], "data")
            test.eq(config.allowAdditionalTags["w-chart"][2], "type")
            local root_tags, root_err = json.encode(config.allowAdditionalTags)
            local host_tags, host_err = json.encode(config.hostConfig.allowAdditionalTags)
            test.is_nil(root_err)
            test.is_nil(host_err)
            test.eq(host_tags, root_tags)
        end)

        test.it("exposes enabled root policy and an empty object allowlist for Host 1.0.62", function()
            set_requirements({
                fe_facade_url = "https://web-host.wippy.ai/webcomponents-1.0.62",
                allow_select_model = "true",
                hide_session_selector = "false",
                allow_additional_tags = "{}",
            })
            local config, body = fetch_config()
            test.eq(config.schema_url, config.facade_url .. "/schemas/wippy-context-2.1.json")
            test.is_true(config.allowSelectModel)
            test.is_nil(config.hostConfig.allowSelectModel)
            test.is_false(config.hideSessionSelector)
            test.is_nil(config.hostConfig.hideSessionSelector)
            test.not_nil(config.allowAdditionalTags)
            test.is_nil(config.hostConfig.allowAdditionalTags)
            test.is_nil(next(config.allowAdditionalTags))
            -- The root must encode an empty map as an object, never a JSON array.
            local _, count = body:gsub('"allowAdditionalTags"%s*:%s*{}', "")
            test.eq(count, 1)
        end)

        test.it("recognizes newer official CDN versions without mirroring", function()
            for _, url in ipairs({
                "https://web-host.wippy.ai/webcomponents-1.0.63",
                "https://web-host.wippy.ai/webcomponents-1.1.0/",
                "https://web-host.wippy.ai/webcomponents-2.0.0",
            }) do
                set_requirements({ fe_facade_url = url, allow_select_model = "true" })
                local config = fetch_config()
                test.eq(config.schema_url, url .. "/schemas/wippy-context-2.1.json")
                test.is_true(config.allowSelectModel)
                test.is_nil(config.hostConfig.allowSelectModel)
                test.is_nil(config.hostConfig.hideSessionSelector)
                test.is_nil(config.hostConfig.allowAdditionalTags)
            end
        end)

        test.it("preserves legacy policy for private and unrecognized hosts in auto mode", function()
            for _, url in ipairs({
                "https://private.example/host",
                "https://custom.example/webcomponents-1.0.62",
                "https://web-host.wippy.ai/unrelated/webcomponents-1.0.62",
            }) do
                set_requirements({
                    fe_facade_url = url, host_policy_mode = "auto", allow_select_model = "false",
                    hide_session_selector = "true", allow_additional_tags = '{"w-chart":["data"]}',
                })
                local config = fetch_config()
                test.eq(config.schema_url, url .. "/schemas/wippy-context-2.0.xsd")
                test.is_false(config.hostConfig.allowSelectModel)
                test.is_true(config.hostConfig.hideSessionSelector)
                test.eq(config.hostConfig.allowAdditionalTags["w-chart"][1], "data")
                test.eq(config.allowAdditionalTags["w-chart"][1], "data")
            end
        end)

        test.it("lets custom modern hosts opt into shared root-only policy", function()
            set_requirements({
                fe_facade_url = "https://private.example/host", host_policy_mode = "shared",
                allow_select_model = "true", hide_session_selector = "false", allow_additional_tags = "{}",
            })
            local config = fetch_config()
            test.eq(config.schema_url, config.facade_url .. "/schemas/wippy-context-2.1.json")
            test.is_true(config.allowSelectModel)
            test.is_false(config.hideSessionSelector)
            test.is_nil(config.hostConfig.allowSelectModel)
            test.is_nil(config.hostConfig.hideSessionSelector)
            test.is_nil(config.hostConfig.allowAdditionalTags)
        end)

        test.it("allows an explicit legacy mirror even for a modern CDN host", function()
            set_requirements({
                fe_facade_url = "https://web-host.wippy.ai/webcomponents-1.0.62", host_policy_mode = "legacy",
                allow_select_model = "false", hide_session_selector = "true", allow_additional_tags = "{}",
            })
            local config = fetch_config()
            test.eq(config.schema_url, config.facade_url .. "/schemas/wippy-context-2.0.xsd")
            test.is_false(config.hostConfig.allowSelectModel)
            test.is_true(config.hostConfig.hideSessionSelector)
            test.not_nil(config.hostConfig.allowAdditionalTags)
        end)

        test.it("rejects an invalid policy mode with an actionable config error", function()
            set_requirements({ host_policy_mode = "shraed" })
            local response = request_config()
            test.eq(response.status_code, 500)
            local body, err = json.decode(response.body or "")
            test.is_nil(err)
            test.eq(body.error, "invalid host_policy_mode: expected auto, legacy or shared")
        end)
    end)
end

local run_cases = test.run_cases(define_tests)

local function run(options)
    return run_cases(options)
end

return { run = run }
