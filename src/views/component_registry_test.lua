local test = require("test")
local registry = require("registry")
local page_registry = require("page_registry")
local component_registry = require("component_registry")

local NS = "wippy.views.test:"

local PAGE_IDS = {
    "test_home", "test_dashboard",
}

local COMPONENT_IDS = {
    "test_comp_widget", "test_comp_chart", "test_comp_custom_entry", "test_comp_unnamed",
}

local function setup_pages()
    local snap = registry.snapshot()
    local changes = snap:changes()

    changes:create({
        id = NS .. "test_home",
        kind = "registry.entry",
        meta = {
            type = "view.page",
            name = "home",
            title = "Home",
            icon = "house",
            order = 1,
            group = "main",
            group_icon = "layout",
            group_order = 1,
            group_placement = "sidebar",
            secure = false,
            public = true,
            announced = true,
            inline = false,
            url = "https://cdn.example.com/home/index.html",
        },
    })

    changes:create({
        id = NS .. "test_dashboard",
        kind = "registry.entry",
        meta = {
            type = "view.page",
            name = "dashboard",
            title = "Dashboard",
            icon = "chart",
            order = 3,
            group = "main",
            group_icon = "layout",
            group_order = 1,
            group_placement = "sidebar",
            secure = false,
            public = true,
            announced = true,
            inline = false,
            url = "https://cdn.example.com/dashboard/index.html",
        },
    })

    changes:apply()
end

local function setup_components()
    local snap = registry.snapshot()
    local changes = snap:changes()

    changes:create({
        id = NS .. "test_comp_widget",
        kind = "registry.entry",
        meta = {
            type = "view.component",
            name = "widget",
            title = "Widget",
            icon = "puzzle",
            order = 1,
            group = "components",
            group_icon = "blocks",
            group_order = 1,
            group_placement = "default",
            secure = false,
            public = true,
            announced = true,
            tag_name = "test-widget",
            url = "https://cdn.example.com/widget/",
        },
    })

    changes:create({
        id = NS .. "test_comp_chart",
        kind = "registry.entry",
        meta = {
            type = "view.component",
            name = "chart",
            title = "Chart",
            icon = "bar-chart",
            order = 2,
            group = "components",
            group_icon = "blocks",
            group_order = 1,
            group_placement = "default",
            secure = false,
            public = true,
            announced = true,
            url = "https://cdn.example.com/chart/",
        },
    })

    changes:create({
        id = NS .. "test_comp_custom_entry",
        kind = "registry.entry",
        meta = {
            type = "view.component",
            name = "custom",
            title = "Custom Entry",
            icon = "code",
            order = 3,
            group = "components",
            group_icon = "blocks",
            group_order = 1,
            group_placement = "default",
            secure = false,
            public = true,
            announced = true,
            url = "https://cdn.example.com/custom/",
            entry_point = "main.js",
        },
    })

    changes:create({
        id = NS .. "test_comp_unnamed",
        kind = "registry.entry",
        meta = {
            type = "view.component",
            title = "Unnamed",
            secure = false,
            public = true,
            announced = true,
            tag_name = "test-unnamed",
            url = "https://cdn.example.com/unnamed/",
        },
    })

    changes:apply()
end

local function teardown()
    local snap = registry.snapshot()
    local changes = snap:changes()
    for _, name in ipairs(PAGE_IDS) do
        changes:delete(NS .. name)
    end
    for _, name in ipairs(COMPONENT_IDS) do
        changes:delete(NS .. name)
    end
    changes:apply()
end

local function define_tests()
    test.describe("component registry", function()
        test.before_each(function()
            setup_components()
            setup_pages()
        end)

        test.after_each(function()
            teardown()
        end)

        test.it("find_all returns only view.component entries", function()
            local components, err = component_registry.find_all()
            test.is_nil(err)
            test.not_nil(components)

            local count = 0
            for _, comp in ipairs(components) do
                if comp.id:find("^" .. NS .. "test_comp") then
                    count = count + 1
                end
            end
            test.eq(count, 4)
        end)

        test.it("find_all does not include view.page entries", function()
            local components, err = component_registry.find_all()
            test.is_nil(err)

            for _, comp in ipairs(components) do
                test.is_false(comp.id == NS .. "test_home")
                test.is_false(comp.id == NS .. "test_dashboard")
            end
        end)

        test.it("page find_all does not include view.component entries", function()
            local pages, err = page_registry.find_all()
            test.is_nil(err)

            for _, page in ipairs(pages) do
                test.is_false(page.id == NS .. "test_comp_widget")
                test.is_false(page.id == NS .. "test_comp_chart")
            end
        end)

        test.it("get returns component with full detail", function()
            local comp, err = component_registry.get(NS .. "test_comp_widget")
            test.is_nil(err)
            test.eq(comp.id, NS .. "test_comp_widget")
            test.eq(comp.title, "Widget")
            test.eq(comp.url, "https://cdn.example.com/widget/")
        end)

        test.it("returns nil entry_point when YAML omits it (default applied at projection layer)", function()
            -- Defaults moved from the registry layer to bundled_meta.project_*
            -- so the projection's YAML-first `or` chain works correctly. Lua
            -- `""` is truthy, so applying a string default here would
            -- short-circuit the bundled-meta fallback. Raw nil propagates.
            local comp, err = component_registry.get(NS .. "test_comp_widget")
            test.is_nil(err)
            test.is_nil(comp.entry_point)
        end)

        test.it("respects custom entry_point", function()
            local comp, err = component_registry.get(NS .. "test_comp_custom_entry")
            test.is_nil(err)
            test.eq(comp.entry_point, "main.js")
        end)

        test.it("page returns nil entry_point when YAML omits it (default applied at projection layer)", function()
            -- Same rationale as the component-side test above. The
            -- `index.html` default for pages now lives in
            -- `bundled_meta.project_page_response`, not in
            -- `page_registry.get`.
            local page, err = page_registry.get(NS .. "test_home")
            test.is_nil(err)
            test.is_nil(page.entry_point)
        end)

        test.it("find_by_tag_name returns the component for a known tag", function()
            local comp, err = component_registry.find_by_tag_name("test-widget")
            test.is_nil(err)
            test.not_nil(comp)
            test.eq(comp.id, NS .. "test_comp_widget")
            test.eq(comp.tag_name, "test-widget")
        end)

        test.it("find_by_tag_name returns nil + error for unknown tag", function()
            local comp, err = component_registry.find_by_tag_name("no-such-tag")
            test.is_nil(comp)
            test.not_nil(err)
        end)

        test.it("find_by_tag_name requires non-empty tag", function()
            local comp1, err1 = component_registry.find_by_tag_name(nil)
            test.is_nil(comp1)
            test.not_nil(err1)

            local comp2, err2 = component_registry.find_by_tag_name("")
            test.is_nil(comp2)
            test.not_nil(err2)
        end)

        test.it("find_all sorts by name", function()
            local components, err = component_registry.find_all()
            test.is_nil(err)

            local test_comps = {}
            for _, comp in ipairs(components) do
                if comp.id:find("^" .. NS .. "test_comp") and comp.name then
                    table.insert(test_comps, comp)
                end
            end

            for i = 1, #test_comps - 1 do
                test.is_true(test_comps[i].name <= test_comps[i + 1].name)
            end
        end)

        test.it("find_all accepts components without meta.name", function()
            local components, err = component_registry.find_all()
            test.is_nil(err)

            local unnamed: any = nil
            for _, comp in ipairs(components) do
                if comp.id == NS .. "test_comp_unnamed" then
                    unnamed = comp
                    break
                end
            end

            test.not_nil(unnamed)
            test.is_nil(unnamed.name)
            test.eq(unnamed.tag_name, "test-unnamed")
        end)
    end)
end

local run_cases = test.run_cases(define_tests)

local function run(options: any): any
    return run_cases(options)
end

return { run = run }
