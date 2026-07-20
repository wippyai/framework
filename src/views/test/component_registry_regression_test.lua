local test = require("test")
local registry = require("registry")
local component_registry = require("component_registry")

local ENTRY_IDS = {
    "app:test_component_without_name_b",
    "app:test_component_without_name_a",
}

local function remove_fixtures()
    local snap = registry.snapshot()
    local changes = snap:changes()
    for _, id in ipairs(ENTRY_IDS) do
        changes:delete(id)
    end
    changes:apply()
end

local function define_tests()
    test.describe("component registry regressions", function()
        test.after_each(remove_fixtures)

        test.it("lists unnamed view components in deterministic id order", function()
            local snap = registry.snapshot()
            local changes = snap:changes()
            for _, id in ipairs(ENTRY_IDS) do
                changes:create({
                    id = id,
                    kind = "registry.entry",
                    meta = {
                        type = "view.component",
                        title = "Unnamed component",
                        tag_name = id:gsub(":", "-"),
                        announced = true,
                        auto_register = true,
                    },
                })
            end
            changes:apply()

            local components, err = component_registry.find_all()
            test.is_nil(err)

            local found = {}
            for _, component in ipairs(components) do
                if component.id == ENTRY_IDS[1] or component.id == ENTRY_IDS[2] then
                    table.insert(found, component)
                end
            end

            test.eq(#found, 2)
            test.eq(found[1].id, ENTRY_IDS[2])
            test.eq(found[2].id, ENTRY_IDS[1])
            test.is_nil(found[1].name)
            test.is_nil(found[2].name)
        end)
    end)
end

return {
    run = test.run_cases(define_tests),
}
