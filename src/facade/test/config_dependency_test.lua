local test = require("test")
local registry = require("registry")

local NS = "wippy.facade:"

local function run()
    test.describe("wippy.facade dependency wiring", function()
        test.it("materializes requirement values into data.default", function()
            local entry = registry.get(NS .. "fe_facade_url")
            test.not_nil(entry)
            test.not_nil(entry.data)
            test.eq(entry.data.default, "https://web-host.wippy.ai/webcomponents-1.0.46")

            entry = registry.get(NS .. "app_title")
            test.not_nil(entry)
            test.not_nil(entry.data)
            test.eq(entry.data.default, "Wippy")
        end)
    end)
end

return { run = run }
