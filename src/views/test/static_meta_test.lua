local test = require("test")
local funcs = require("funcs")
local security = require("security")
local registry = require("registry")
local static_meta = require("static_meta")

-- Fixtures (test/_index.yaml), all on app:gateway unless noted:
--   app:test_static       /static-fixture       fixtures/static
--   app:test_root_static  /                     fixtures/root
--   app:test_spa_static   /spa-fixture (SPA)    fixtures/spa
--   app:test_other_static /static-fixture/meta-page on app:other_gateway

-- The policies of the views API handlers (wippy.views.api:render) that the
-- metadata read needs, without the template data-function grant.
local HANDLER_POLICIES = {
    "wippy.views:public_registry_runtime",
    "wippy.views:public_env_runtime",
    "wippy.views:public_metadata_http_runtime",
    "wippy.views:public_metadata_private_ip_runtime",
    "wippy.views:public_metadata_reader_runtime",
    "wippy.views:public_metadata_store_runtime",
}

local HANDLER_IDS = {
    "wippy.views.api:render",
    "wippy.views.api:list_components",
    "wippy.views.api:find_by_tag",
    "wippy.views.api:fragment_gateway",
}

-- Call `target` under a scope made of `policy_ids`, as a handler with that
-- security block would (the test runner itself is unrestricted).
local function call_as(policy_ids: {string}, target: string, ...: any): any
    local scope = security.new_scope()
    for _, id in ipairs(policy_ids) do
        local policy, err = security.policy(id)
        if err then
            error(err)
        end
        scope = scope:with(policy)
    end
    local result, err = funcs.new()
        :with_actor(security.new_actor("wippy.views.api:render"))
        :with_scope(scope)
        :call(target, ...)
    if err then
        error(err)
    end
    return result
end

local function static_entry(id: string, path: string, data: any?, meta: any?): any
    local d: any = data or {}
    d.path = path
    d.fs = d.fs or "files"
    local m: any = meta or {}
    m.server = m.server or "gateway"
    return { id = id, data = d, meta = m }
end

local function contains(list: any, value: string): boolean
    if type(list) ~= "table" then
        return false
    end
    for _, v in ipairs(list) do
        if v == value then
            return true
        end
    end
    return false
end

local function define_tests()
    test.describe("static_meta.select_mount", function()
        local SERVER = "app:gateway"

        test.it("picks the longest mount path on the server", function()
            local entries = {
                static_entry("app:root", "/"),
                static_entry("app:apps", "/app"),
                static_entry("app:keeper", "/app/keeper", { fs = "keeper_fs" }),
            }
            local mount, reason = static_meta.select_mount(entries, "/app/keeper/", SERVER)
            test.eq(reason, nil)
            test.eq(mount.id, "app:keeper")
            test.eq(mount.fs, "app:keeper_fs")
            test.eq(mount.file, "wippy-meta.json")
            test.eq(mount.catch_all, false)
        end)

        test.it("matches whole path segments only", function()
            local entries = { static_entry("app:root", "/"), static_entry("app:keeper", "/app/keeper") }
            local mount = static_meta.select_mount(entries, "/app/keeper-git/", SERVER)
            test.eq(mount.id, "app:root")
            test.eq(mount.file, "app/keeper-git/wippy-meta.json")
            test.eq(mount.catch_all, true)
        end)

        test.it("cleans the path like the HTTP server", function()
            local entries = { static_entry("app:keeper", "/app/keeper/") }
            for _, path in ipairs({ "//app/keeper/x/", "/app/./keeper/y/../x/", "/app//keeper/x/" }) do
                local mount, reason = static_meta.select_mount(entries, path, SERVER)
                test.eq(reason, nil)
                test.eq(mount.file, "x/wippy-meta.json")
            end
        end)

        test.it("ignores mounts on other servers", function()
            local entries = {
                static_entry("app:short", "/app"),
                static_entry("app:long", "/app/keeper", nil, { server = "internal" }),
            }
            local mount = static_meta.select_mount(entries, "/app/keeper/", SERVER)
            test.eq(mount.id, "app:short")
            test.eq(mount.file, "keeper/wippy-meta.json")
        end)

        test.it("qualifies relative server and fs ids with the entry namespace", function()
            local entries = { static_entry("ui.ns:static", "/ui", { fs = "ui_fs" }, { server = "app:gateway" }) }
            local mount = static_meta.select_mount(entries, "/ui/", SERVER)
            test.eq(mount.fs, "ui.ns:ui_fs")
            local relative = { static_entry("app:static", "/ui", { fs = "other.ns:ui_fs" }) }
            mount = static_meta.select_mount(relative, "/ui/", SERVER)
            test.eq(mount.fs, "other.ns:ui_fs")
        end)

        test.it("is ambiguous without a known server when mounts are on several servers", function()
            local entries = {
                static_entry("app:a", "/app"),
                static_entry("app:b", "/other", nil, { server = "internal" }),
            }
            local mount, reason = static_meta.select_mount(entries, "/app/x/", nil)
            test.eq(mount, nil)
            test.eq(reason, static_meta.REASON.ambiguous)
            local single = static_meta.select_mount({ static_entry("app:a", "/app") }, "/app/x/", nil)
            test.eq(single.id, "app:a")
        end)

        test.it("is ambiguous when two mounts have the same path", function()
            local entries = { static_entry("app:a", "/app"), static_entry("app:b", "/app/") }
            local mount, reason = static_meta.select_mount(entries, "/app/x/", SERVER)
            test.eq(mount, nil)
            test.eq(reason, static_meta.REASON.ambiguous)
        end)

        test.it("refuses remote, URL-encoded and unmounted paths", function()
            local entries = { static_entry("app:apps", "/app") }
            local _, remote = static_meta.select_mount(entries, "https://cdn.example/app/", SERVER)
            test.eq(remote, static_meta.REASON.remote)
            local _, encoded = static_meta.select_mount(entries, "/app/my%20page/", SERVER)
            test.eq(encoded, static_meta.REASON.encoded)
            local _, none = static_meta.select_mount(entries, "/other/", SERVER)
            test.eq(none, static_meta.REASON.no_mount)
        end)

        test.it("refuses to guess when a mount path has a placeholder", function()
            local entries = { static_entry("app:apps", "/app"), static_entry("app:env", "${env:UI_PATH}") }
            local _, ignored = static_meta.select_mount(entries, "/app/x/", SERVER)
            test.eq(ignored, nil) -- no leading slash: the runtime rejects it, so it never mounts
            entries = { static_entry("app:apps", "/app"), static_entry("app:env", "/ui/${env:UI_PATH}") }
            local _, reason = static_meta.select_mount(entries, "/app/x/", SERVER)
            test.eq(reason, static_meta.REASON.placeholder)
        end)

        test.it("ignores entries without a path or an fs", function()
            local no_fs = static_entry("app:a", "/app/keeper", { fs = "" })
            local entries = { static_entry("app:apps", "/app"), no_fs, { id = "app:bad", data = {}, meta = { server = "gateway" } } }
            local mount = static_meta.select_mount(entries, "/app/keeper/", SERVER)
            test.eq(mount.id, "app:apps")
        end)

        test.it("maps SPA mounts by the whole path, as the SPA handler does", function()
            local cases = {
                { data = { static_options = { spa = true } }, spa = true },
                { data = { options = { spa = true } }, spa = true },
                { data = { options = { spa = "true" } }, spa = true },
                { data = { options = { spa = false }, static_options = { spa = true } }, spa = false },
                { data = { options = { cache = "no-cache" } }, spa = false },
            }
            for _, c in ipairs(cases) do
                local mount = static_meta.select_mount({ static_entry("app:ui", "/ui", c.data) }, "/ui/page/", SERVER)
                test.eq(mount.spa, c.spa)
                test.eq(mount.file, c.spa and "ui/page/wippy-meta.json" or "page/wippy-meta.json")
            end
        end)

        test.it("reads only mounts whose middleware does not guard the files", function()
            local open = static_entry("app:ui", "/ui", { middleware = { "cors", "compress", "real_ip", "metrics", "ratelimit" } })
            local mount = static_meta.select_mount({ open }, "/ui/", SERVER)
            test.eq(mount.id, "app:ui")
            local guarded = static_entry("app:ui", "/ui", { middleware = { "cors", "token_auth", "resource_firewall" } })
            local none, reason = static_meta.select_mount({ guarded }, "/ui/", SERVER)
            test.eq(none, nil)
            test.eq(reason, static_meta.REASON.middleware .. " (token_auth, resource_firewall)")
        end)
    end)

    test.describe("static_meta endpoint routing", function()
        local SERVER = "app:gateway"
        local routers = {
            ["app:root"] = {id = "app:root", meta = {server = "gateway"}, data = {prefix = "/"}},
            ["app:ui"] = {id = "app:ui", meta = {server = "gateway"}, data = {prefix = "/ui/"}},
            ["other.ns:root"] = {id = "other.ns:root", meta = {server = "gateway"}, data = {prefix = "/"}},
        }
        local function route(path: string, method: string?, router: string?): any
            return {id = "app:metadata", meta = {router = router or "root"},
                data = {path = path, method = method}}
        end
        local function conflicts(entry: any): (boolean, string?)
            return static_meta.route_conflict({entry}, routers, "/ui/page/", SERVER)
        end

        test.it("detects a root-router endpoint that overrides a deeply mounted file", function()
            local conflict, reason = conflicts(route("/ui/page/wippy-meta.json", "GET"))
            test.eq(conflict, true)
            test.eq(reason, static_meta.REASON.route)
            test.eq(conflicts(route("/ui/page/wippy-meta.json", nil)), true)
        end)

        test.it("combines the relative router id and prefix with the endpoint path", function()
            test.eq(conflicts(route("/page/wippy-meta.json", "GET", "ui")), true)
            test.eq(conflicts(route("/different/wippy-meta.json", "GET", "ui")), false)
        end)

        test.it("recognizes single-segment, remainder, subtree and end-anchor patterns", function()
            for _, pattern in ipairs({"/ui/{page}/wippy-meta.json", "/ui/{path...}", "/ui/page/"}) do
                test.eq(conflicts(route(pattern, "GET")), true, pattern)
            end
            for _, pattern in ipairs({"/ui/{page}", "/ui/page/{id}/wippy-meta.json", "/ui/page/{$}",
                "/ui/{page}/other.json", "/ui/pages/wippy-meta.json"}) do
                test.eq(conflicts(route(pattern, "GET")), false, pattern)
            end
        end)

        test.it("ignores routes on other servers and methods that cannot handle a GET", function()
            for _, method in ipairs({"POST", "PUT", "HEAD", "OPTIONS", "DELETE"}) do
                test.eq(conflicts(route("/ui/page/wippy-meta.json", method)), false)
            end
            test.eq(conflicts(route("/ui/page/wippy-meta.json", "GET", "other.ns:root")), false)
        end)

        test.it("skips unrelated literals without suppressing matching suffix or wildcard routes", function()
            -- The prefix can supply the whole directory or only part of it.
            local split = {['app:split'] = {id = 'app:split', meta = {server = 'gateway'},
                data = {prefix = '/ui/pa'}}}
            local matching = route('ge/wippy-meta.json', 'GET', 'split')
            test.eq(static_meta.route_conflict({matching}, split, '/ui/page/', SERVER), true)
            test.eq(conflicts(route('/unrelated.json', 'GET', 'missing')), false)
            test.eq(conflicts(route('/{page}/wippy-meta.json', 'GET', 'ui')), true)
        end)

        test.it("uses HTTP for unresolved, encoded or placeholder routing", function()
            for _, pattern in ipairs({"/ui/%70age/wippy-meta.json", "/ui/${env:PAGE}/wippy-meta.json"}) do
                test.eq(conflicts(route(pattern, "GET")), true)
            end
            local conflict, reason = conflicts(route("/ui/page/wippy-meta.json", "GET", "missing"))
            test.eq(conflict, true)
            test.eq(reason, static_meta.REASON.routing)
        end)
    end)

    test.describe("static_meta mount filesystem reads", function()
        test.it("resolves the server of the views API router", function()
            test.eq(static_meta.api_server(), "app:gateway")
        end)

        test.it("finds the gateway mount and ignores a longer one on another server", function()
            local mount, reason = static_meta.find_mount("/static-fixture/meta-page/")
            test.eq(reason, nil)
            test.eq(mount.id, "app:test_static")
            test.eq(mount.file, "meta-page/wippy-meta.json")
        end)

        test.it("reads a file, and reports a missing file under a dedicated mount", function()
            local found = static_meta.load("/static-fixture/meta-page/")
            test.eq(found.status, "found")
            test.eq(found.source, "app:test_static_fs/meta-page/wippy-meta.json")
            test.ok(found.body:find("@test/meta-page", 1, true) ~= nil, tostring(found.body))
            local missing = static_meta.load("/static-fixture/legacy-page/")
            test.eq(missing.status, "missing")
            test.eq(missing.source, "app:test_static_fs/legacy-page/wippy-meta.json")
        end)

        test.it("reports a directory or a file over the size limit as an error", function()
            local dir = static_meta.load("/static-fixture/dir-page/")
            test.eq(dir.status, "error")
            test.eq(dir.err, "the path is a directory")
            local mount = static_meta.find_mount("/static-fixture/meta-page/")
            local big = static_meta.read(mount, 10)
            test.eq(big.status, "error")
            test.eq(big.err, "the file is larger than 10 bytes")
        end)

        test.it("uses the catch-all mount, and asks for HTTP when it lacks the file", function()
            local found = static_meta.load("/root-page/")
            test.eq(found.status, "found")
            test.eq(found.source, "app:test_root_fs/root-page/wippy-meta.json")
            local miss = static_meta.load("/no-such-page/")
            test.eq(miss.status, "unavailable")
            test.eq(miss.reason, static_meta.REASON.catch_all)
        end)

        test.it("reads an SPA mount by the whole path; a missing file means no bundled meta", function()
            local found = static_meta.load("/spa-fixture/page/")
            test.eq(found.status, "found")
            test.eq(found.source, "app:test_spa_fs/spa-fixture/page/wippy-meta.json")
            local missing = static_meta.load("/spa-fixture/other/")
            test.eq(missing.status, "missing")
        end)

        test.it("asks for HTTP for a remote entry", function()
            local remote = static_meta.load("https://cdn.example/app/")
            test.eq(remote.status, "unavailable")
            test.eq(remote.reason, static_meta.REASON.remote)
        end)
    end)

    test.describe("read_static_meta permission boundary", function()
        test.it("the handler policies cannot open a filesystem", function()
            local result = call_as(HANDLER_POLICIES, "app:fs_access_probe", "app:test_static_fs")
            test.eq(result.opened, false)
            test.ok(tostring(result.err):find("not allowed", 1, true) ~= nil, tostring(result.err))
        end)

        test.it("the handler policies can read through wippy.views:read_static_meta", function()
            local result = call_as(HANDLER_POLICIES, "wippy.views:read_static_meta", "/static-fixture/meta-page/")
            test.eq(result.status, "found")
            test.eq(result.source, "app:test_static_fs/meta-page/wippy-meta.json")
        end)

        test.it("the handlers carry the reader grant, and only the reader has fs.get", function()
            for _, id in ipairs(HANDLER_IDS) do
                local entry, err = registry.get(id)
                test.eq(err, nil)
                local policies = entry and entry.data and entry.data.security and entry.data.security.policies
                test.ok(contains(policies, "wippy.views:public_metadata_reader_runtime"), id .. " has the reader policy")
                test.ok(not contains(policies, "wippy.views:public_metadata_fs_runtime"), id .. " has no fs.get policy")
            end
            local reader = registry.get("wippy.views:read_static_meta")
            local policies = reader and reader.data and reader.data.security and reader.data.security.policies
            test.ok(contains(policies, "wippy.views:public_metadata_fs_runtime"), "the reader has the fs.get policy")
        end)
    end)
end

local run_cases = test.run_cases(define_tests)

local function run(options: any): any
    return run_cases(options)
end

return { run = run }
