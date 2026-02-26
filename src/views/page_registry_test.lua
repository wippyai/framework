local test = require("test")
local registry = require("registry")
local page_registry = require("page_registry")
local component_registry = require("component_registry")
local resource_registry = require("resource_registry")
local env_loader = require("env_loader")

local NS = "wippy.views.test:"
local APP_NS = "app:"

local COMPONENT_IDS = {"test_home", "test_about", "test_secure", "test_dashboard", "test_with_proxy", "test_partial_proxy", "test_comp_widget", "test_comp_chart", "test_comp_custom_entry"}
local RESOURCE_IDS = {"test_global_css", "test_set_script", "test_page_font"}
local ENV_MAPPING_IDS = {"test_env_low", "test_env_high"}

local function setup_component_pages()
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
        id = NS .. "test_about",
        kind = "registry.entry",
        meta = {
            type = "view.page",
            name = "about",
            title = "About",
            icon = "info",
            order = 2,
            group = "main",
            group_icon = "layout",
            group_order = 1,
            group_placement = "sidebar",
            secure = false,
            public = true,
            announced = true,
            inline = false,
            url = "https://cdn.example.com/about/index.html",
        },
    })

    changes:create({
        id = NS .. "test_secure",
        kind = "registry.entry",
        meta = {
            type = "view.page",
            name = "admin",
            title = "Admin Panel",
            icon = "shield",
            order = 10,
            group = "admin",
            group_icon = "settings",
            group_order = 99,
            group_placement = "default",
            secure = true,
            public = false,
            announced = true,
            inline = false,
            url = "https://cdn.example.com/admin/index.html",
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

    changes:create({
        id = NS .. "test_with_proxy",
        kind = "registry.entry",
        meta = {
            type = "view.page",
            name = "proxied",
            title = "Proxied",
            icon = "shield",
            order = 5,
            secure = false,
            url = "https://cdn.example.com/proxied/index.html",
        },
        data = {
            proxy = {
                enabled = true,
                css = {
                    prime_vue = true,
                    markdown = true,
                },
                tailwind_config = true,
            },
        },
    })

    changes:create({
        id = NS .. "test_partial_proxy",
        kind = "registry.entry",
        meta = {
            type = "view.page",
            name = "partial",
            title = "Partial Proxy",
            icon = "settings",
            order = 6,
            secure = false,
            url = "https://cdn.example.com/partial/index.html",
        },
        data = {
            proxy = {
                enabled = false,
                css = {
                    fonts = false,
                },
            },
        },
    })

    changes:apply()
end

local function setup_view_components()
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

    changes:apply()
end

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

local function setup_env_mappings()
    local snap = registry.snapshot()
    local changes = snap:changes()

    changes:create({
        id = NS .. "test_env_low",
        kind = "registry.entry",
        meta = {
            type = "view.env_mapping",
            priority = 5,
        },
        data = {
            mappings = {
                app_url = "APP_URL",
                debug = "DEBUG_MODE",
            },
        },
    })

    changes:create({
        id = NS .. "test_env_high",
        kind = "registry.entry",
        meta = {
            type = "view.env_mapping",
            priority = 25,
        },
        data = {
            mappings = {
                app_url = "OVERRIDE_APP_URL",
                api_key = "API_KEY",
            },
        },
    })

    changes:apply()
end

local function teardown_dynamic()
    local snap = registry.snapshot()
    local changes = snap:changes()
    for _, name in ipairs(COMPONENT_IDS) do
        changes:delete(NS .. name)
    end
    for _, name in ipairs(RESOURCE_IDS) do
        changes:delete(NS .. name)
    end
    for _, name in ipairs(ENV_MAPPING_IDS) do
        changes:delete(NS .. name)
    end
    changes:apply()
end

local function define_tests()
    test.describe("page registry", function()
        test.describe("page discovery", function()
            test.before_each(function()
                setup_component_pages()
            end)

            test.after_each(function()
                teardown_dynamic()
            end)

            test.it("finds all pages with meta.type view.page", function()
                local pages, err = page_registry.find_all()
                test.is_nil(err)
                test.not_nil(pages)

                local component_count = 0
                local template_count = 0
                for _, page in ipairs(pages) do
                    if page.id:find("^" .. NS) then
                        component_count = component_count + 1
                    end
                    if page.id:find("^" .. APP_NS .. "test_tmpl") then
                        template_count = template_count + 1
                    end
                end
                test.gte(component_count, 4)
                test.gte(template_count, 2)
            end)

            test.it("returns component kind for registry.entry pages", function()
                local pages, err = page_registry.find_all()
                test.is_nil(err)

                for _, page in ipairs(pages) do
                    if page.id == NS .. "test_dashboard" then
                        test.eq(page.kind, "component")
                        return
                    end
                end
                test.ok(false)
            end)

            test.it("returns template kind for template.jet pages", function()
                local pages, err = page_registry.find_all()
                test.is_nil(err)

                for _, page in ipairs(pages) do
                    if page.id == APP_NS .. "test_tmpl_contact" then
                        test.eq(page.kind, "template")
                        return
                    end
                end
                test.ok(false)
            end)

            test.it("includes url for component pages", function()
                local pages, err = page_registry.find_all()
                test.is_nil(err)

                for _, page in ipairs(pages) do
                    if page.id == NS .. "test_dashboard" then
                        test.eq(page.url, "https://cdn.example.com/dashboard/index.html")
                        return
                    end
                end
                test.ok(false)
            end)

            test.it("does not include url for template pages in find_all", function()
                local pages, err = page_registry.find_all()
                test.is_nil(err)

                for _, page in ipairs(pages) do
                    if page.id == APP_NS .. "test_tmpl_contact" then
                        test.is_nil(page.url)
                        return
                    end
                end
                test.ok(false)
            end)

            test.it("sorts by order then title", function()
                local pages, err = page_registry.find_all()
                test.is_nil(err)

                local test_pages = {}
                for _, page in ipairs(pages) do
                    if page.id:find("^" .. NS) or page.id:find("^" .. APP_NS .. "test_tmpl") then
                        table.insert(test_pages, page)
                    end
                end

                for i = 1, #test_pages - 1 do
                    local a = test_pages[i]
                    local b = test_pages[i + 1]
                    if a.order == b.order then
                        test.is_true(a.title <= b.title)
                    else
                        test.is_true(a.order < b.order)
                    end
                end
            end)

        end)


        test.describe("component page detail", function()
            test.before_each(function()
                setup_component_pages()
            end)

            test.after_each(function()
                teardown_dynamic()
            end)

            test.it("get returns component page with full detail", function()
                local page, err = page_registry.get(NS .. "test_home")
                test.is_nil(err)
                test.eq(page.id, NS .. "test_home")
                test.eq(page.title, "Home")
                test.eq(page.icon, "house")
                test.eq(page.kind, "component")
                test.eq(page.url, "https://cdn.example.com/home/index.html")
            end)

            test.it("get returns page with correct metadata", function()
                local page, err = page_registry.get(NS .. "test_dashboard")
                test.is_nil(err)
                test.eq(page.title, "Dashboard")
                test.eq(page.kind, "component")
                test.eq(page.group, "main")
                test.eq(page.group_placement, "sidebar")
                test.eq(page.url, "https://cdn.example.com/dashboard/index.html")
            end)

            test.it("get returns error for non-existent page", function()
                local page, err = page_registry.get(NS .. "nonexistent")
                test.is_nil(page)
                test.not_nil(err)
            end)
        end)

        test.describe("proxy config", function()
            test.before_each(function()
                setup_component_pages()
            end)

            test.after_each(function()
                teardown_dynamic()
            end)

            test.it("component page without proxy block gets defaults", function()
                local page, err = page_registry.get(NS .. "test_home")
                test.is_nil(err)
                page = test.not_nil(page)
                local proxy = test.not_nil(page.proxy)
                test.eq(proxy.enabled, true)
                test.eq(proxy.css.fonts, true)
                test.eq(proxy.css.theme_config, true)
                test.eq(proxy.css.iframe, true)
                test.eq(proxy.css.prime_vue, false)
                test.eq(proxy.css.markdown, false)
                test.eq(proxy.css.custom_css, false)
                test.eq(proxy.css.custom_variables, false)
                test.eq(proxy.tailwind_config, false)
                test.eq(proxy.resize_observer, true)
                test.eq(proxy.prevent_link_clicks, true)
                test.eq(proxy.iconify_icons, false)
            end)

            test.it("component page with proxy block merges over defaults", function()
                local page, err = page_registry.get(NS .. "test_with_proxy")
                test.is_nil(err)
                page = test.not_nil(page)
                local proxy = test.not_nil(page.proxy)
                test.eq(proxy.enabled, true)
                test.eq(proxy.css.prime_vue, true)
                test.eq(proxy.css.markdown, true)
                test.eq(proxy.tailwind_config, true)
                test.eq(proxy.resize_observer, true)
                test.eq(proxy.prevent_link_clicks, true)
            end)

            test.it("css sub-fields merge independently", function()
                local page, err = page_registry.get(NS .. "test_with_proxy")
                test.is_nil(err)
                page = test.not_nil(page)
                local proxy = test.not_nil(page.proxy)
                test.eq(proxy.css.fonts, true)
                test.eq(proxy.css.theme_config, true)
                test.eq(proxy.css.iframe, true)
                test.eq(proxy.css.custom_css, false)
                test.eq(proxy.css.custom_variables, false)
            end)

            test.it("partial proxy can override defaults to false", function()
                local page, err = page_registry.get(NS .. "test_partial_proxy")
                test.is_nil(err)
                page = test.not_nil(page)
                local proxy = test.not_nil(page.proxy)
                test.eq(proxy.enabled, false)
                test.eq(proxy.css.fonts, false)
                test.eq(proxy.css.theme_config, true)
                test.eq(proxy.css.iframe, true)
            end)

            test.it("template page has no proxy", function()
                local page, err = page_registry.get(APP_NS .. "test_tmpl_contact")
                test.is_nil(err)
                test.is_nil(page.proxy)
            end)
        end)

        test.describe("template page detail", function()
            test.it("get returns template page with kind template", function()
                local page, err = page_registry.get(APP_NS .. "test_tmpl_contact")
                test.is_nil(err)
                test.eq(page.id, APP_NS .. "test_tmpl_contact")
                test.eq(page.title, "Contact")
                test.eq(page.icon, "mail")
                test.eq(page.kind, "template")
            end)

            test.it("get returns template page with template_set", function()
                local page, err = page_registry.get(APP_NS .. "test_tmpl_contact")
                test.is_nil(err)
                test.eq(page.template_set, APP_NS .. "test_templates")
            end)

            test.it("get returns template page with template_name", function()
                local page, err = page_registry.get(APP_NS .. "test_tmpl_contact")
                test.is_nil(err)
                test.eq(page.template_name, "test_tmpl_contact")
            end)

            test.it("template page has no url", function()
                local page, err = page_registry.get(APP_NS .. "test_tmpl_contact")
                test.is_nil(err)
                test.is_nil(page.url)
            end)

            test.it("get returns template page with template fields", function()
                local page, err = page_registry.get(APP_NS .. "test_tmpl_contact")
                test.is_nil(err)
                test.eq(page.kind, "template")
                test.eq(page.template_set, APP_NS .. "test_templates")
                test.eq(page.template_name, "test_tmpl_contact")
            end)
        end)

        test.describe("page access", function()
            test.before_each(function()
                setup_component_pages()
            end)

            test.after_each(function()
                teardown_dynamic()
            end)

            test.it("can_access allows non-secure pages", function()
                local page, err = page_registry.get(NS .. "test_home")
                test.is_nil(err)
                test.is_true(page_registry.can_access(page))
            end)

            test.it("can_access denies secure pages without actor", function()
                local page, err = page_registry.get(NS .. "test_secure")
                test.is_nil(err)
                test.is_false(page_registry.can_access(page))
            end)

            test.it("can_access allows non-secure template pages", function()
                local page, err = page_registry.get(APP_NS .. "test_tmpl_contact")
                test.is_nil(err)
                test.is_true(page_registry.can_access(page))
            end)

            test.it("can_access denies secure template pages without actor", function()
                local page, err = page_registry.get(APP_NS .. "test_tmpl_settings")
                test.is_nil(err)
                test.is_false(page_registry.can_access(page))
            end)
        end)

        test.describe("kind detection", function()
            test.it("detect_kind returns component for registry.entry", function()
                local snap = registry.snapshot()
                local changes = snap:changes()
                changes:create({
                    id = NS .. "test_kind_check",
                    kind = "registry.entry",
                    meta = { type = "view.page", name = "check", title = "Check" },
                })
                changes:apply()

                local page, err = page_registry.get(NS .. "test_kind_check")
                test.is_nil(err)
                test.eq(page.kind, "component")

                local snap2 = registry.snapshot()
                local changes2 = snap2:changes()
                changes2:delete(NS .. "test_kind_check")
                changes2:apply()
            end)

            test.it("detect_kind returns template for template.jet", function()
                local page, err = page_registry.get(APP_NS .. "test_tmpl_contact")
                test.is_nil(err)
                test.eq(page.kind, "template")
            end)
        end)
    end)

    test.describe("view components", function()
        test.before_each(function()
            setup_view_components()
            setup_component_pages()
        end)

        test.after_each(function()
            teardown_dynamic()
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
            test.eq(count, 3)
        end)

        test.it("find_all does not include view.page entries", function()
            local components, err = component_registry.find_all()
            test.is_nil(err)

            for _, comp in ipairs(components) do
                test.is_false(comp.id == NS .. "test_home")
                test.is_false(comp.id == NS .. "test_dashboard")
            end
        end)

        test.it("find_all does not include view.component entries", function()
            local pages, err = page_registry.find_all()
            test.is_nil(err)

            for _, page in ipairs(pages) do
                test.is_false(page.id == NS .. "test_comp_widget")
                test.is_false(page.id == NS .. "test_comp_chart")
            end
        end)

        test.it("get works for view.component entries", function()
            local comp, err = component_registry.get(NS .. "test_comp_widget")
            test.is_nil(err)
            test.eq(comp.id, NS .. "test_comp_widget")
            test.eq(comp.title, "Widget")
            test.eq(comp.url, "https://cdn.example.com/widget/")
        end)

        test.it("view.component defaults entry_point to index.js", function()
            local comp, err = component_registry.get(NS .. "test_comp_widget")
            test.is_nil(err)
            test.eq(comp.entry_point, "index.js")
        end)

        test.it("view.component respects custom entry_point", function()
            local comp, err = component_registry.get(NS .. "test_comp_custom_entry")
            test.is_nil(err)
            test.eq(comp.entry_point, "main.js")
        end)

        test.it("view.page defaults entry_point to index.html", function()
            local page, err = page_registry.get(NS .. "test_home")
            test.is_nil(err)
            test.eq(page.entry_point, "index.html")
        end)

        test.it("find_all sorts by name", function()
            local components, err = component_registry.find_all()
            test.is_nil(err)

            local test_comps = {}
            for _, comp in ipairs(components) do
                if comp.id:find("^" .. NS .. "test_comp") then
                    table.insert(test_comps, comp)
                end
            end

            for i = 1, #test_comps - 1 do
                test.is_true(test_comps[i].name <= test_comps[i + 1].name)
            end
        end)
    end)

    test.describe("resource registry", function()
        test.before_each(function()
            setup_resources()
        end)

        test.after_each(function()
            teardown_dynamic()
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

    test.describe("env loader", function()
        test.before_each(function()
            setup_env_mappings()
        end)

        test.after_each(function()
            teardown_dynamic()
        end)

        test.it("build_env_context merges by priority (higher wins)", function()
            local mappings = {
                { id = "low", priority = 5, mappings = { app_url = "LOW_URL", debug = "DEBUG" } },
                { id = "high", priority = 25, mappings = { app_url = "HIGH_URL", api_key = "KEY" } },
            }

            local context, err = env_loader.build_env_context(mappings)
            test.is_nil(err)
            test.eq(context.app_url, "HIGH_URL")
            test.eq(context.debug, "DEBUG")
            test.eq(context.api_key, "KEY")
        end)

        test.it("validate_priority rejects out of range", function()
            local ok, err = env_loader.validate_priority(150)
            test.is_false(ok)
            test.not_nil(err)

            ok, err = env_loader.validate_priority(-1)
            test.is_false(ok)
            test.not_nil(err)
        end)

        test.it("validate_priority rejects wrong category", function()
            local ok, err = env_loader.validate_priority(5, "APPLICATION_MAPPINGS")
            test.is_false(ok)
            test.not_nil(err)
        end)

        test.it("validate_priority accepts valid range", function()
            local ok, err = env_loader.validate_priority(25, "APPLICATION_MAPPINGS")
            test.is_true(ok)
            test.is_nil(err)
        end)

        test.it("get_recommended_priority returns category minimum", function()
            local priority, err = env_loader.get_recommended_priority("FRAMEWORK_DEFAULTS")
            test.is_nil(err)
            test.eq(priority, 0)

            priority, err = env_loader.get_recommended_priority("APPLICATION_MAPPINGS")
            test.is_nil(err)
            test.eq(priority, 20)
        end)

        test.it("get_recommended_priority errors on unknown category", function()
            local priority, err = env_loader.get_recommended_priority("NONEXISTENT")
            test.is_nil(priority)
            test.not_nil(err)
        end)

        test.it("build_env_context handles nil input", function()
            local context, err = env_loader.build_env_context(nil)
            test.is_nil(err)
            test.not_nil(context)
            test.is_nil(next(context))
        end)

        test.it("build_env_context handles empty input", function()
            local context, err = env_loader.build_env_context({})
            test.is_nil(err)
            test.not_nil(context)
            test.is_nil(next(context))
        end)
    end)
end

local run_cases = test.run_cases(define_tests)

local function run(options: any): any
    return run_cases(options)
end

return { run = run }
