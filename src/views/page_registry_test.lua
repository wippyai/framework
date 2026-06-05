local test = require("test")
local registry = require("registry")
local page_registry = require("page_registry")

local NS = "wippy.views.test:"
local APP_NS = "app:"

local PAGE_IDS = {
    "test_home", "test_about", "test_secure",
    "test_dashboard", "test_meta_proxy",
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

    -- `meta.proxy` (camelCase overlay) is the SINGLE proxy field, read raw into
    -- `page.proxy`. The projection (bundle path) / synthesis (no-bundle path)
    -- layer deep-merges it over the bundle proxy / the default proxy.
    changes:create({
        id = NS .. "test_meta_proxy",
        kind = "registry.entry",
        meta = {
            type = "view.page",
            name = "meta-proxy",
            title = "Meta Proxy",
            secure = false,
            url = "https://cdn.example.com/meta-proxy/index.html",
            proxy = {
                injections = { css = { customCss = true } },
            },
        },
    })

    changes:apply()
end

local function teardown_pages()
    local snap = registry.snapshot()
    local changes = snap:changes()
    for _, name in ipairs(PAGE_IDS) do
        changes:delete(NS .. name)
    end
    changes:apply()
end

local function define_tests()
    test.describe("page registry", function()
        test.describe("page discovery", function()
            test.before_each(function()
                setup_pages()
            end)

            test.after_each(function()
                teardown_pages()
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
                setup_pages()
            end)

            test.after_each(function()
                teardown_pages()
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

        test.describe("proxy (meta.proxy overlay)", function()
            test.before_each(function()
                setup_pages()
            end)

            test.after_each(function()
                teardown_pages()
            end)

            test.it("meta.proxy is extracted raw to page.proxy (camelCase overlay)", function()
                local page, err = page_registry.get(NS .. "test_meta_proxy")
                test.is_nil(err)
                page = test.not_nil(page)
                local proxy = test.not_nil(page.proxy)
                test.eq(proxy.injections.css.customCss, true)
            end)

            test.it("page without meta.proxy has nil page.proxy (defaults belong to the projection/synthesis layer)", function()
                local page, err = page_registry.get(NS .. "test_home")
                test.is_nil(err)
                page = test.not_nil(page)
                test.is_nil(page.proxy)
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
                setup_pages()
            end)

            test.after_each(function()
                teardown_pages()
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

        test.describe("mount routes — pure validator", function()
            test.it("valid: root mount /:part(.*)*", function()
                local map, issues = page_registry.validate_mount_routes({
                    { id = "ns:a", mount_route = "/:part(.*)*" },
                })
                test.eq(#issues, 0)
                test.eq(map["/:part(.*)*"], "ns:a")
            end)

            test.it("valid: single-segment prefix", function()
                local map, issues = page_registry.validate_mount_routes({
                    { id = "ns:a", mount_route = "/keeper/:part(.*)*" },
                })
                test.eq(#issues, 0)
                test.eq(map["/keeper/:part(.*)*"], "ns:a")
            end)

            test.it("valid: nested prefix", function()
                local map, issues = page_registry.validate_mount_routes({
                    { id = "ns:a", mount_route = "/admin/users/:part(.*)*" },
                })
                test.eq(#issues, 0)
                test.eq(map["/admin/users/:part(.*)*"], "ns:a")
            end)

            test.it("valid: hyphens in segments", function()
                local map, issues = page_registry.validate_mount_routes({
                    { id = "ns:a", mount_route = "/my-app/sub-page/:part(.*)*" },
                })
                test.eq(#issues, 0)
                test.eq(map["/my-app/sub-page/:part(.*)*"], "ns:a")
            end)

            test.it("valid: ignores pages without mount_route", function()
                local map, issues = page_registry.validate_mount_routes({
                    { id = "ns:a", mount_route = "/foo/:part(.*)*" },
                    { id = "ns:b" },
                    { id = "ns:c", mount_route = "" },
                })
                test.eq(#issues, 0)
                test.eq(map["/foo/:part(.*)*"], "ns:a")
            end)

            test.it("invalid: missing catch-all tail", function()
                local _, issues = page_registry.validate_mount_routes({
                    { id = "ns:a", mount_route = "/keeper" },
                })
                test.eq(#issues, 1)
                test.is_true(issues[1]:find("invalid mountRoute") ~= nil)
            end)

            test.it("invalid: alternative param name :pathMatch", function()
                local _, issues = page_registry.validate_mount_routes({
                    { id = "ns:a", mount_route = "/:pathMatch(.*)*" },
                })
                test.eq(#issues, 1)
            end)

            test.it("invalid: custom named params", function()
                local _, issues = page_registry.validate_mount_routes({
                    { id = "ns:a", mount_route = "/user/:id" },
                })
                test.eq(#issues, 1)
            end)

            test.it("invalid: trailing slash after catch-all", function()
                local _, issues = page_registry.validate_mount_routes({
                    { id = "ns:a", mount_route = "/foo/:part(.*)*/" },
                })
                test.eq(#issues, 1)
            end)

            test.it("invalid: uppercase segments rejected", function()
                local _, issues = page_registry.validate_mount_routes({
                    { id = "ns:a", mount_route = "/Admin/:part(.*)*" },
                })
                test.eq(#issues, 1)
            end)

            test.it("invalid: double slash rejected", function()
                local _, issues = page_registry.validate_mount_routes({
                    { id = "ns:a", mount_route = "//foo/:part(.*)*" },
                })
                test.eq(#issues, 1)
            end)

            test.it("invalid: underscore in segment rejected", function()
                local _, issues = page_registry.validate_mount_routes({
                    { id = "ns:a", mount_route = "/my_app/:part(.*)*" },
                })
                test.eq(#issues, 1)
            end)

            test.it("duplicate: two pages claiming same route", function()
                local _, issues = page_registry.validate_mount_routes({
                    { id = "ns:a", mount_route = "/keeper/:part(.*)*" },
                    { id = "ns:b", mount_route = "/keeper/:part(.*)*" },
                })
                test.eq(#issues, 1)
                test.is_true(issues[1]:find("conflict") ~= nil)
                test.is_true(issues[1]:find("ns:a") ~= nil)
                test.is_true(issues[1]:find("ns:b") ~= nil)
            end)

            test.it("duplicate: same page id listed twice is idempotent", function()
                local map, issues = page_registry.validate_mount_routes({
                    { id = "ns:a", mount_route = "/foo/:part(.*)*" },
                    { id = "ns:a", mount_route = "/foo/:part(.*)*" },
                })
                test.eq(#issues, 0)
                test.eq(map["/foo/:part(.*)*"], "ns:a")
            end)

            test.it("duplicate: reports all conflicts, not just first", function()
                local _, issues = page_registry.validate_mount_routes({
                    { id = "ns:a", mount_route = "/x/:part(.*)*" },
                    { id = "ns:b", mount_route = "/x/:part(.*)*" },
                    { id = "ns:c", mount_route = "/y/:part(.*)*" },
                    { id = "ns:d", mount_route = "/y/:part(.*)*" },
                })
                test.eq(#issues, 2)
            end)

            test.it("empty list returns empty map and no issues", function()
                local map, issues = page_registry.validate_mount_routes({})
                test.eq(#issues, 0)
                local count = 0
                for _ in pairs(map) do
                    count = count + 1
                end
                test.eq(count, 0)
            end)

            test.it("nil input returns empty map", function()
                local map, issues = page_registry.validate_mount_routes(nil)
                test.eq(#issues, 0)
                test.not_nil(map)
            end)

            test.it("invalid type: boolean mount_route surfaces error", function()
                local _, issues = page_registry.validate_mount_routes({
                    { id = "ns:a", mount_route = false },
                })
                -- `false` is not nil and not an empty string; the type check
                -- catches it and emits a clear syntax error so YAML typos
                -- (e.g. `mountRoute: false`) don't silently drop.
                test.eq(#issues, 1)
                test.is_true(issues[1]:find("invalid mountRoute") ~= nil)
            end)

            test.it("invalid type: number mount_route surfaces error", function()
                local _, issues = page_registry.validate_mount_routes({
                    { id = "ns:a", mount_route = 42 },
                })
                test.eq(#issues, 1)
                test.is_true(issues[1]:find("invalid mountRoute") ~= nil)
            end)

            test.it("invalid type: table mount_route surfaces error", function()
                local _, issues = page_registry.validate_mount_routes({
                    { id = "ns:a", mount_route = { "/foo" } },
                })
                test.eq(#issues, 1)
            end)

            test.it("missing id with valid mount_route surfaces error", function()
                local _, issues = page_registry.validate_mount_routes({
                    { mount_route = "/foo/:part(.*)*" },
                })
                test.eq(#issues, 1)
                test.is_true(issues[1]:find("missing a valid id") ~= nil)
            end)

            test.it("empty id with valid mount_route surfaces error", function()
                local _, issues = page_registry.validate_mount_routes({
                    { id = "", mount_route = "/foo/:part(.*)*" },
                })
                test.eq(#issues, 1)
            end)
        end)

        test.describe("mount routes — registry integration", function()
            local MR_IDS = {
                "mr_home", "mr_keeper", "mr_admin", "mr_no_mount",
            }

            local function setup_mr_pages()
                local snap = registry.snapshot()
                local changes = snap:changes()
                changes:create({
                    id = NS .. "mr_home",
                    kind = "registry.entry",
                    meta = {
                        type = "view.page",
                        name = "home",
                        title = "Home",
                        announced = true,
                        public = true,
                        mountRoute = "/:part(.*)*",
                        url = "https://cdn.example.com/home/index.html",
                    },
                })
                changes:create({
                    id = NS .. "mr_keeper",
                    kind = "registry.entry",
                    meta = {
                        type = "view.page",
                        name = "keeper",
                        title = "Keeper",
                        announced = true,
                        public = true,
                        mountRoute = "/keeper/:part(.*)*",
                        url = "https://cdn.example.com/keeper/index.html",
                    },
                })
                changes:create({
                    id = NS .. "mr_admin",
                    kind = "registry.entry",
                    meta = {
                        type = "view.page",
                        name = "admin-users",
                        title = "Admin Users",
                        announced = true,
                        public = true,
                        mountRoute = "/admin/users/:part(.*)*",
                        url = "https://cdn.example.com/admin/users/index.html",
                    },
                })
                changes:create({
                    id = NS .. "mr_no_mount",
                    kind = "registry.entry",
                    meta = {
                        type = "view.page",
                        name = "plain",
                        title = "Plain",
                        announced = true,
                        public = true,
                        url = "https://cdn.example.com/plain/index.html",
                    },
                })
                changes:apply()
            end

            local function teardown_mr_pages()
                local snap = registry.snapshot()
                local changes = snap:changes()
                for _, name in ipairs(MR_IDS) do
                    changes:delete(NS .. name)
                end
                changes:apply()
            end

            test.before_each(function()
                setup_mr_pages()
            end)
            test.after_each(function()
                teardown_mr_pages()
            end)

            test.it("find_all exposes mount_route when present", function()
                local all, err = page_registry.find_all()
                test.is_nil(err)
                local found = {}
                for _, page in ipairs(all) do
                    if page.id:find("^" .. NS .. "mr_") then
                        found[page.id] = page.mount_route
                    end
                end
                test.eq(found[NS .. "mr_home"], "/:part(.*)*")
                test.eq(found[NS .. "mr_keeper"], "/keeper/:part(.*)*")
                test.eq(found[NS .. "mr_admin"], "/admin/users/:part(.*)*")
            end)

            test.it("find_all returns nil mount_route when not set", function()
                local all, err = page_registry.find_all()
                test.is_nil(err)
                for _, page in ipairs(all) do
                    if page.id == NS .. "mr_no_mount" then
                        test.is_nil(page.mount_route)
                        return
                    end
                end
                test.ok(false, "mr_no_mount not found")
            end)

            test.it("get returns mount_route on page detail", function()
                local page, err = page_registry.get(NS .. "mr_keeper")
                test.is_nil(err)
                test.eq(page.mount_route, "/keeper/:part(.*)*")
            end)

            test.it("get returns nil mount_route when not set", function()
                local page, err = page_registry.get(NS .. "mr_no_mount")
                test.is_nil(err)
                test.is_nil(page.mount_route)
            end)

            test.it("find_mount_routes returns full map for valid state", function()
                local routes, err = page_registry.find_mount_routes()
                test.is_nil(err)
                routes = test.not_nil(routes)
                test.eq(routes["/:part(.*)*"], NS .. "mr_home")
                test.eq(routes["/keeper/:part(.*)*"], NS .. "mr_keeper")
                test.eq(routes["/admin/users/:part(.*)*"], NS .. "mr_admin")
            end)

            test.it("find_mount_routes excludes pages without mount_route", function()
                local routes, err = page_registry.find_mount_routes()
                test.is_nil(err)
                for _, pid in pairs(routes) do
                    test.is_true(pid ~= NS .. "mr_no_mount")
                end
            end)
        end)
    end)
end

local run_cases = test.run_cases(define_tests)

local function run(options: any): any
    return run_cases(options)
end

return { run = run }
