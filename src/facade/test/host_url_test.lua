local test = require("test")
local funcs = require("funcs")
local http_client = require("http_client")
local json = require("json")
local registry = require("registry")

local HOST_URL = "wippy.facade:fe_facade_url"
local CONTRIBUTED = "app:contributed_host_url"

local function set_value(id: string, value: string)
    local changes = registry.snapshot():changes()
    local record = { id = id, kind = "ns.requirement", data = { default = value } }
    if registry.get(id) then
        changes:update(record)
    else
        changes:create(record)
    end
    local _, err = changes:apply()
    test.is_nil(err)
end

local function host_url(): string
    local value, err = funcs.call("wippy.facade:host_url")
    test.is_nil(err)
    return value
end

local function config_facade_url(): string
    local gateway = registry.get("app:gateway")
    test.not_nil(gateway)
    local response, err = http_client.get("http://127.0.0.1" .. gateway.data.addr .. "/api/public/facade/config", { timeout = 5 })
    test.is_nil(err)
    test.eq(response.status_code, 200)
    local config, decode_err = json.decode(response.body or "")
    test.is_nil(decode_err)
    return config.facade_url
end

local function define_tests()
    test.describe("wippy.facade:host_url", function()
        local saved_default = ""

        test.before_each(function()
            saved_default = registry.get(HOST_URL).data.default
            set_value(CONTRIBUTED, "")
        end)

        test.after_each(function()
            set_value(HOST_URL, saved_default)
            set_value(CONTRIBUTED, "")
        end)

        test.it("returns the static requirement default when nothing overrides it", function()
            test.eq(host_url(), saved_default)
            test.eq(config_facade_url(), saved_default)
        end)

        test.it("follows a changed requirement default", function()
            set_value(HOST_URL, "https://web-host.wippy.ai/webcomponents-1.0.61")
            test.eq(host_url(), "https://web-host.wippy.ai/webcomponents-1.0.61")
            test.eq(config_facade_url(), "https://web-host.wippy.ai/webcomponents-1.0.61")
        end)

        test.it("returns a module contribution, the same URL the config endpoint serves", function()
            set_value(CONTRIBUTED, "http://localhost:19085/cdn/web-host/webcomponents-1.0.68")
            test.eq(host_url(), "http://localhost:19085/cdn/web-host/webcomponents-1.0.68")
            test.eq(config_facade_url(), "http://localhost:19085/cdn/web-host/webcomponents-1.0.68")
        end)
    end)
end

return { run = test.run_cases(define_tests) }
