local test = require("test")
local registry = require("registry")
local resource_registry = require("resource_registry")

local NS = "wippy.views.test:"

local RESOURCE_IDS = {
    "test_global_css", "test_set_script", "test_page_font",
}

local function setup_resources()
    local snap = registry.snapshot()
    local changes = snap:changes()

    changes:create({
        id = NS .. "test_global_css",
        kind = "registry.entry",
        meta = {
            type = "view.resource",
            name = "Global Styles",
            resource_type = "style",
            order = 1,
            global = true,
            url = "https://cdn.example.com/styles.css",
        },
    })

    changes:create({
        id = NS .. "test_set_script",
        kind = "registry.entry",
        meta = {
            type = "view.resource",
            name = "Set Script",
            resource_type = "script",
            order = 2,
            global = false,
            template_set = NS .. "default_set",
            url = "https://cdn.example.com/app.js",
            defer = true,
        },
    })

    changes:create({
        id = NS .. "test_page_font",
        kind = "registry.entry",
        meta = {
            type = "view.resource",
            name = "Page Font",
            resource_type = "font",
            order = 3,
            global = false,
            url = "https://cdn.example.com/font.woff2",
            crossorigin = "anonymous",
        },
    })

    changes:apply()
end

local function teardown_resources()
    local snap = registry.snapshot()
    local changes = snap:changes()
    for _, name in ipairs(RESOURCE_IDS) do
        changes:delete(NS .. name)
    end
    changes:apply()
end

local function define_tests()
    test.describe("resource registry", function()
        test.before_each(function()
            setup_resources()
        end)

        test.after_each(function()
            teardown_resources()
        end)

        test.it("find_all returns resources from registry", function()
            local all, err = resource_registry.find_all()
            test.is_nil(err)
            test.not_nil(all)
            test.not_nil(all[NS .. "test_global_css"])
            test.eq(all[NS .. "test_global_css"].resource_type, "style")
        end)

        test.it("group_by_type groups correctly", function()
            local all, err = resource_registry.find_all()
            test.is_nil(err)

            local grouped = resource_registry.group_by_type(all)
            test.not_nil(grouped)

            local found_style = false
            if grouped.style then
                for _, r in ipairs(grouped.style) do
                    if r.id == NS .. "test_global_css" then
                        found_style = true
                    end
                end
            end
            test.is_true(found_style)

            local found_script = false
            if grouped.script then
                for _, r in ipairs(grouped.script) do
                    if r.id == NS .. "test_set_script" then
                        found_script = true
                    end
                end
            end
            test.is_true(found_script)
        end)

        test.it("collect_for_page includes global and template set resources", function()
            local all, err = resource_registry.find_all()
            test.is_nil(err)

            local mock_page = {
                template_set = NS .. "default_set",
                resources = { NS .. "test_page_font" },
            }

            local collected = resource_registry.collect_for_page(mock_page, nil, all)
            test.not_nil(collected)

            test.not_nil(collected[NS .. "test_global_css"])
            test.not_nil(collected[NS .. "test_set_script"])
            test.not_nil(collected[NS .. "test_page_font"])
        end)

        test.it("get_globals returns only global resources", function()
            local all, err = resource_registry.find_all()
            test.is_nil(err)

            local globals = resource_registry.get_globals(all)
            for _, resource in pairs(globals) do
                test.is_true(resource.global)
            end
            test.not_nil(globals[NS .. "test_global_css"])
        end)
    end)
end

local run_cases = test.run_cases(define_tests)

local function run(options: any): any
    return run_cases(options)
end

return { run = run }
