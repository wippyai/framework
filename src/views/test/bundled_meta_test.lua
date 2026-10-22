local test = require("test")
local funcs = require("funcs")
local security = require("security")
local env = require("env")
local http_client = require("http_client")
local json = require("json")
local bundled_meta = require("bundled_meta")
local static_meta = require("static_meta")

-- The projection tests below are pure, with synthetic inputs.
--
-- Core invariant codified here: **YAML always wins on a field-by-field
-- basis.** YAML is the abstraction OVER FE code. Bundled meta is the
-- fallback source for fields YAML omits, never an override for fields
-- YAML explicitly sets. Tests are written so that flipping this
-- precedence anywhere in the projection helpers will FAIL.
--
-- The loading tests read fixtures from the mount filesystem and over HTTP
-- from the test gateway (test/_index.yaml). They need PUBLIC_API_URL set to
-- that gateway, as the test Makefile does.

local GATEWAY = "http://localhost:19086"

local function field(value: any, key: string): any
    if type(value) ~= "table" then return nil end
    return value[key]
end

-- The policies of the /pages/content handler (wippy.views.api:render)
-- that bundled_meta needs, without the template data-function grant.
local HANDLER_POLICIES = {
    "wippy.views:public_registry_runtime",
    "wippy.views:public_env_runtime",
    "wippy.views:public_metadata_http_runtime",
    "wippy.views:public_metadata_private_ip_runtime",
    "wippy.views:public_metadata_reader_runtime",
    "wippy.views:public_metadata_store_runtime",
}

local function without(list: {string}, value: string): {string}
    local out: {string} = {}
    for _, v in ipairs(list) do
        if v ~= value then
            table.insert(out, v)
        end
    end
    return out
end

-- Run bundled_meta._load through app:bundled_meta_probe under a scope made
-- of `policy_ids`, as a handler with that security block would.
local function load_as(policy_ids: {string}, base_path: string, base_url: string): any
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
        :call("app:bundled_meta_probe", base_path, base_url)
    if err then
        error(err)
    end
    return result
end

local function define_tests()
    test.describe("metadata route precedence", function()
        test.it("uses the metadata actually served when an endpoint shadows a static mount", function()
            local url = GATEWAY .. "/static-fixture/shadow-page/"
            local response, http_err = http_client.get(url .. "wippy-meta.json")
            test.is_nil(http_err)
            test.eq(response.status_code, 200)
            local served = json.decode(response.body or "")
            test.eq(served.name, "@test/routed-page")
            local loaded = load_as(HANDLER_POLICIES, "/static-fixture/shadow-page/", url)
            test.is_nil(loaded.err)
            test.eq(loaded.meta.name, served.name)
            test.eq(loaded.over_http, true)
            test.eq(loaded.via, static_meta.REASON.route)
        end)

        test.it("does not read the backing file when its endpoint denies the HTTP request", function()
            local path = "/static-fixture/guarded-page/"
            local local_read = static_meta.load(path)
            test.eq(local_read.status, "unavailable")
            test.eq(local_read.reason, static_meta.REASON.route)
            local loaded = load_as(HANDLER_POLICIES, path, GATEWAY .. path)
            test.is_nil(loaded.meta)
            test.eq(loaded.err, "HTTP 401")
            test.eq(loaded.over_http, true)
        end)
    end)
    test.describe("bundled_meta.project_page_response", function()
        test.it("YAML wins for name + title even when bundled meta has its own", function()
            local meta = {
                name = "@wippy/sample-page",
                title = "Sample Page (pkg top-level)",
                wippy = { type = "page", title = "Sample Page (wippy.title)", path = "app.html" },
            }
            local page = { id = "ns:sample", name = "sample-yaml-name", title = "Sample YAML Title" }
            local r = bundled_meta.project_page_response(meta, page, "http://h/foo/")
            test.eq(r.name, "sample-yaml-name")
            test.eq(r.title, "Sample YAML Title")
        end)

        test.it("falls back to bundled meta when YAML omits a field", function()
            local meta = {
                name = "@wippy/sample-page",
                version = "2.3.4",
                wippy = { type = "page", title = "Sample (wippy.title)", path = "app.html" },
            }
            local page = { id = "ns:sample" }
            local r = bundled_meta.project_page_response(meta, page, "http://h/foo/")
            test.eq(r.name, "@wippy/sample-page")
            test.eq(r.title, "Sample (wippy.title)")
            test.eq(r.version, "2.3.4")
            test.eq(r.wippy.path, "app.html")
        end)

        test.it("YAML entry_point wins over bundled wippy.path", function()
            local meta = { wippy = { path = "bundled.html" } }
            local page = { id = "ns:p", entry_point = "yaml.html" }
            local r = bundled_meta.project_page_response(meta, page, "http://h/")
            test.eq(r.wippy.path, "yaml.html")
        end)

        test.it("wippy.proxy comes from bundled meta when YAML sets no meta.proxy", function()
            local meta = {
                wippy = {
                    proxy = { enabled = true, injections = { css = { customCss = true } } },
                },
            }
            local page = { id = "ns:p" }
            local r = bundled_meta.project_page_response(meta, page, "http://h/")
            test.eq(r.wippy.proxy.injections.css.customCss, true)
        end)

        test.it("YAML meta.proxy deep-merges over bundled wippy.proxy (YAML wins per key)", function()
            local meta = {
                wippy = {
                    proxy = {
                        enabled = true,
                        injections = { css = { themeConfig = true, customCss = false } },
                    },
                },
            }
            -- page.proxy is what page_registry extracts from meta.proxy
            local page = {
                id = "ns:p",
                proxy = { injections = { css = { customCss = true } } },
            }
            local r = bundled_meta.project_page_response(meta, page, "http://h/")
            test.eq(r.wippy.proxy.enabled, true)                    -- bundle key survives
            test.eq(r.wippy.proxy.injections.css.themeConfig, true) -- bundle key survives
            test.eq(r.wippy.proxy.injections.css.customCss, true)   -- YAML override wins
        end)

        test.it("YAML meta.proxy can override a bundled value to false (YAML wins, not just truthy)", function()
            local meta = {
                wippy = {
                    proxy = {
                        enabled = true,
                        injections = { css = { themeConfig = true }, resizeObserver = true },
                    },
                },
            }
            -- The regression-prone direction: YAML sets a bundle-true key to false.
            local page = {
                id = "ns:p",
                proxy = { injections = { resizeObserver = false } },
            }
            local r = bundled_meta.project_page_response(meta, page, "http://h/")
            test.eq(r.wippy.proxy.injections.resizeObserver, false)  -- YAML false wins over bundle true
            test.eq(r.wippy.proxy.injections.css.themeConfig, true)  -- untouched bundle key survives
            test.eq(r.wippy.proxy.enabled, true)                     -- untouched bundle key survives
        end)

        test.it("backfills a minimal truthy wippy.proxy when neither bundle nor meta.proxy set one", function()
            -- The FE rejects a page descriptor with no wippy.proxy
            -- (isWippyPackageWebPage). project_page_response backfills
            -- {enabled=true}; the FE then defaults every injection ON.
            local meta = { wippy = { type = "page", path = "app.html" } } -- bundle has no proxy
            local page = { id = "ns:p" }                                  -- no meta.proxy
            local r = bundled_meta.project_page_response(meta, page, "http://h/")
            test.not_nil(r.wippy.proxy)
            test.eq(r.wippy.proxy.enabled, true)
        end)

        test.it("does NOT leak package.json fields (dependencies, scripts, devDependencies) to the response", function()
            local meta = {
                name = "@example/x",
                dependencies = { vue = "^3" },
                devDependencies = { vite = "^7" },
                scripts = { build = "vite build" },
                description = "internal description",
                wippy = { type = "page", path = "app.html" },
            }
            local r = bundled_meta.project_page_response(meta, { id = "ns:x", name = "x" }, "http://h/")
            test.eq(field(r, "dependencies"), nil)
            test.eq(field(r, "devDependencies"), nil)
            test.eq(field(r, "scripts"), nil)
            test.eq(field(r, "description"), nil)
        end)

        test.it("YAML config_overrides deep-merges over bundled wippy.configOverrides (variant overlay; YAML wins)", function()
            local meta = {
                wippy = {
                    configOverrides = {
                        customization = {
                            cssVariables = { ["--p-primary"] = "#bundled", ["--p-other"] = "#keep" },
                            customCSS = "BUNDLED",
                        },
                    },
                },
            }
            local page = {
                id = "ns:themed",
                config_overrides = {
                    customization = {
                        cssVariables = { ["--p-primary"] = "#yaml" },
                        customCSS = "YAML",
                    },
                },
            }
            local r = bundled_meta.project_page_response(meta, page, "http://h/")
            local cust = r.wippy.configOverrides.customization
            test.eq(cust.customCSS, "YAML")
            test.eq(cust.cssVariables["--p-primary"], "#yaml")
            test.eq(cust.cssVariables["--p-other"], "#keep")
        end)

        test.it("variant inherits bundled configOverrides when YAML omits its own", function()
            local meta = {
                wippy = { configOverrides = { customization = { customCSS = "BASE" } } },
            }
            local page = { id = "ns:base" }
            local r = bundled_meta.project_page_response(meta, page, "http://h/")
            test.eq(r.wippy.configOverrides.customization.customCSS, "BASE")
        end)

        test.it("falls back to YAML-only when bundled meta is empty (legacy synthesis-equivalent)", function()
            local meta = {}
            local page = {
                id = "ns:fallback",
                name = "fallback",
                title = "Fallback Title",
                entry_point = "index.html",
            }
            local r = bundled_meta.project_page_response(meta, page, "http://h/x/")
            test.eq(r.name, "fallback")
            test.eq(r.title, "Fallback Title")
            test.eq(r.wippy.path, "index.html")
            test.eq(r.specification, "wippy-component-1.0")
        end)
    end)

    test.describe("bundled_meta.project_component_response", function()
        test.it("YAML wins for tag_name + entry_point + props (events fallback when YAML omits)", function()
            local meta = {
                name = "@example/my-wc",
                wippy = {
                    type = "component",
                    tagName = "my-wc-from-pkg",
                    path = "from-pkg.js",
                    props = { type = "object", properties = { fromPkg = { type = "string" } } },
                    events = { type = "object", properties = { evtFromPkg = { type = "object" } } },
                },
            }
            local component = {
                id = "ns:my-wc",
                name = "my-wc-yaml",
                title = "from-yaml",
                tag_name = "my-wc-from-yaml",
                entry_point = "from-yaml.js",
                auto_register = true,
                props = { type = "object", properties = { fromYaml = { type = "string" } } },
                events = nil,
            }
            local r = bundled_meta.project_component_response(meta, component, "http://h/wc/my-wc/")
            test.eq(r.name, "my-wc-yaml")
            test.eq(r.title, "from-yaml")
            test.eq(r.wippy.tagName, "my-wc-from-yaml")
            test.eq(r.browser, "from-yaml.js")
            test.eq(r.wippy.props.properties.fromYaml.type, "string")
            test.eq(r.wippy.props.properties.fromPkg, nil)
            test.eq(type(r.wippy.events), "table")
            test.eq(r.wippy.events.properties.evtFromPkg.type, "object")
        end)

        test.it("falls back to bundled meta when YAML omits a field", function()
            local meta = {
                name = "@example/x",
                -- top-level `browser` is the component entry_point source;
                -- `wippy.path` is page-only and is ignored for components.
                browser = "dist/x.js",
                wippy = {
                    type = "component",
                    tagName = "x-elem",
                    props = { type = "object", properties = {} },
                },
            }
            local component = {
                id = "ns:x",
                name = "x",
                title = "X",
                tag_name = nil,
                entry_point = nil,
                auto_register = false,
                props = nil,
            }
            local r = bundled_meta.project_component_response(meta, component, "http://h/x/")
            test.eq(r.wippy.tagName, "x-elem")
            test.eq(r.browser, "dist/x.js")
            test.eq(type(r.wippy.props), "table")
        end)

        test.it("explicit empty YAML value ({} / '') OVERRIDES the bundle; only omitted (nil) falls through", function()
            -- The nil-vs-empty contract. An operator who writes `props: {}` or
            -- `tag_name: ""` in YAML means "blank this on purpose" — a truthy
            -- override that wins over the bundle. Only an OMITTED key (Lua nil)
            -- means "no opinion, fall through to the bundled wippy-meta.json".
            -- This guards against a future `meta.X or {}` coercion that would
            -- turn the omitted-key default truthy and silently kill fall-through.
            local meta = {
                name = "@example/x",
                wippy = {
                    type = "component",
                    tagName = "x-from-bundle",
                    props = { type = "object", properties = { fromBundle = { type = "string" } } },
                    events = { type = "object", properties = { evt = { type = "object" } } },
                },
            }
            local component = {
                id = "ns:x",
                name = "x",
                title = "",        -- explicit empty string → overrides to ""
                tag_name = "",     -- explicit empty string → overrides to ""
                entry_point = nil,
                auto_register = false,
                props = {},        -- explicit empty table → overrides to {}
                events = nil,      -- OMITTED → falls through to the bundle
            }
            local r = bundled_meta.project_component_response(meta, component, "http://h/x/")
            -- Explicit empties win (must NOT fall through to the bundle):
            test.eq(r.title, "")
            test.eq(r.wippy.tagName, "")
            test.eq(next(r.wippy.props), nil)  -- the empty {} from YAML, not the bundle's schema
            -- Omitted (nil) still falls through to the bundle:
            test.eq(type(r.wippy.events), "table")
            test.eq(r.wippy.events.properties.evt.type, "object")
        end)

        test.it("uses bundled top-level `browser` for entry_point (the spec field for components; wippy.path is page-only)", function()
            local meta = {
                browser = "index.js",
                -- wippy.path would be ignored for components — it's
                -- spec'd for view.page only, not view.component.
                wippy = { type = "component", tagName = "x-elem", path = "WRONG_should_be_ignored.html" },
            }
            local component = { id = "ns:x", name = "x", title = "", tag_name = "x-elem", entry_point = nil, auto_register = false }
            local r = bundled_meta.project_component_response(meta, component, "http://h/x/")
            test.eq(r.browser, "index.js")
        end)

        test.it("auto_register always comes from the registry (deployment policy)", function()
            local meta = {
                wippy = { tagName = "x", autoRegister = false },
            }
            local component = {
                id = "ns:x", name = "x", title = "", tag_name = "x", entry_point = "index.js",
                auto_register = true,
            }
            local r = bundled_meta.project_component_response(meta, component, "http://h/")
            test.eq(r.wippy.autoRegister, true)
        end)

        test.it("works with nil bundled meta (legacy synthesis-equivalent)", function()
            local component = {
                id = "ns:legacy-wc",
                name = "legacy-wc",
                title = "Legacy WC",
                tag_name = "example-legacy",
                entry_point = "index.js",
                auto_register = true,
                props = { type = "object", properties = {} },
                events = nil,
            }
            local r = bundled_meta.project_component_response(nil, component, "http://h/wc/legacy/")
            test.eq(r.id, "ns:legacy-wc")
            test.eq(r.name, "legacy-wc")
            test.eq(r.wippy.tagName, "example-legacy")
            test.eq(r.browser, "index.js")
            test.eq(r.wippy.props.type, "object")
            test.eq(r.wippy.events, nil)
        end)
    end)

    test.describe("bundled_meta failure messages and log dedup", function()
        test.it("refuses a relative URL and names PUBLIC_API_URL instead of an HTTP client error", function()
            local meta, err, url = bundled_meta._fetch("/app/keeper/")
            test.eq(meta, nil)
            test.eq(url, "/app/keeper/wippy-meta.json")
            test.ok(type(err) == "string" and err:find("PUBLIC_API_URL", 1, true) ~= nil,
                "error names PUBLIC_API_URL: " .. tostring(err))
        end)

        test.it("describes what failed, what the page loses, why HTTP was used and how to fix it", function()
            local message = bundled_meta.describe_fetch_failure(
                "page", "keeper:main", "http://edge.example/app/keeper/wippy-meta.json", "HTTP 403",
                true, static_meta.REASON.no_mount)
            for _, part in ipairs({
                "page 'keeper:main'",
                "http://edge.example/app/keeper/wippy-meta.json",
                "HTTP 403",
                "configOverrides",
                "index.html",
                "because " .. static_meta.REASON.no_mount,
                "Set PUBLIC_API_URL",
            }) do
                test.ok(message:find(part, 1, true) ~= nil, "message contains '" .. part .. "': " .. message)
            end
        end)

        test.it("lists what a component loses", function()
            local message = bundled_meta.describe_fetch_failure("component", "app:wc", "x", "HTTP 500")
            for _, part in ipairs({ "component 'app:wc'", "props", "events", "tag name", "index.js" }) do
                test.ok(message:find(part, 1, true) ~= nil, "message contains '" .. part .. "': " .. message)
            end
            test.eq(message:find("configOverrides", 1, true), nil)
        end)

        test.it("gives no PUBLIC_API_URL advice for a remote entry", function()
            local message = bundled_meta.describe_fetch_failure(
                "page", "app:p", "https://cdn.example/ui/wippy-meta.json", "HTTP 403", true, static_meta.REASON.remote)
            test.ok(message:find("because " .. static_meta.REASON.remote, 1, true) ~= nil, message)
            test.eq(message:find("PUBLIC_API_URL", 1, true), nil)
        end)

        test.it("points at the file, not PUBLIC_API_URL, when a mount filesystem had a bad file", function()
            local message = bundled_meta.describe_fetch_failure(
                "page", "keeper:main", "keeper.components:ui_static_fs/wippy-meta.json",
                "the file is not JSON", false)
            test.ok(message:find("keeper.components:ui_static_fs/wippy-meta.json", 1, true) ~= nil, message)
            test.ok(message:find("http.static", 1, true) ~= nil, message)
            test.eq(message:find("PUBLIC_API_URL", 1, true), nil)
        end)

        test.it("the public message names the entry and what it loses, but no file, URL or error", function()
            local message = bundled_meta.public_failure_message("page", "keeper:main")
            test.ok(message:find("page 'keeper:main'", 1, true) ~= nil, message)
            test.ok(message:find("theme variables", 1, true) ~= nil, message)
            test.ok(message:find("wippy.views logger", 1, true) ~= nil, message)
            for _, leak in ipairs({ "http", "_fs", "fixtures", "PUBLIC_API_URL", "wippy-meta.json/" }) do
                test.eq(message:find(leak, 1, true), nil)
            end
        end)

        test.it("masks numbers in the dedup key so a changing port is one cause", function()
            local a = bundled_meta._failure_key("page", "app:p", "u", "fetch failed: dial tcp 10.0.0.5:51234: refused")
            local b = bundled_meta._failure_key("page", "app:p", "u", "fetch failed: dial tcp 10.0.0.5:60000: refused")
            test.eq(a, b)
            test.ok(a ~= bundled_meta._failure_key("page", "app:p", "u", "HTTP #"), a)
        end)

        test.it("claims a log slot once", function()
            local key = "test:claim-" .. tostring(os.time()) .. "-" .. tostring(math.random(1000000))
            test.eq(bundled_meta._claim_once(key), true)
            test.eq(bundled_meta._claim_once(key), false)
        end)
    end)

    -- Fixtures (test/_index.yaml): app:test_static mounts fixtures/static at
    -- /static-fixture, app:test_root_static mounts fixtures/root at / on the
    -- test gateway (PUBLIC_API_URL).
    test.describe("bundled_meta loads wippy-meta.json", function()
        test.it("runs with PUBLIC_API_URL set to the test gateway", function()
            test.eq(env.get("PUBLIC_API_URL"), GATEWAY)
        end)

        test.it("reads and decodes the file from the mount filesystem", function()
            local meta, err, source, over_http = bundled_meta._load("/static-fixture/meta-page/", "http://unused.invalid/")
            test.eq(err, nil)
            test.eq(over_http, false)
            test.eq(source, "app:test_static_fs/meta-page/wippy-meta.json")
            test.eq(meta.name, "@test/meta-page")
            test.eq(meta.wippy.configOverrides.customization.cssVariables["--fixture-color"], "#123456")
        end)

        test.it("treats a missing file under a dedicated mount as an entry without bundled meta", function()
            local meta, err, source, over_http = bundled_meta._load("/static-fixture/legacy-page/", "http://unused.invalid/")
            test.eq(meta, nil)
            test.eq(err, nil)
            test.eq(over_http, false)
            test.eq(source, "app:test_static_fs/legacy-page/wippy-meta.json")
        end)

        test.it("reports a bad file without fetching over HTTP", function()
            for path, want in pairs({
                ["/static-fixture/bad-page/"] = "the file is not JSON",
                ["/static-fixture/array-page/"] = "the file is not a JSON object",
                ["/static-fixture/dir-page/"] = "the path is a directory",
            }) do
                local meta, err, _, over_http = bundled_meta._load(path, "http://unused.invalid/")
                test.eq(meta, nil)
                test.eq(over_http, false)
                test.ok(type(err) == "string" and err:find(want, 1, true) ~= nil, path .. ": " .. tostring(err))
            end
        end)

        test.it("fetches over HTTP when only the catch-all mount matches and lacks the file", function()
            local meta, err, url, over_http, via = bundled_meta._load("/no-such-page/", GATEWAY .. "/no-such-page/")
            test.eq(meta, nil)
            test.eq(err, nil) -- HTTP 404: no bundled meta
            test.eq(over_http, true)
            test.eq(via, static_meta.REASON.catch_all)
            test.eq(url, GATEWAY .. "/no-such-page/wippy-meta.json")
        end)

        test.it("fetches over HTTP: success, 404, bad JSON and a JSON array", function()
            local meta, err = bundled_meta._fetch(GATEWAY .. "/static-fixture/meta-page/")
            test.eq(err, nil)
            test.eq(field(meta, "name"), "@test/meta-page")

            local none, none_err = bundled_meta._fetch(GATEWAY .. "/static-fixture/legacy-page/")
            test.eq(none, nil)
            test.eq(none_err, nil)

            local _, bad_err = bundled_meta._fetch(GATEWAY .. "/static-fixture/bad-page/")
            test.ok(type(bad_err) == "string" and bad_err:find("the response is not JSON", 1, true) ~= nil, tostring(bad_err))

            local _, array_err = bundled_meta._fetch(GATEWAY .. "/static-fixture/array-page/")
            test.eq(array_err, "the response is not a JSON object")
        end)

        test.it("fetch_for_page reads the mount file through the page url and base_path", function()
            local meta, err, source = bundled_meta.fetch_for_page({ id = "app:fixture_page", url = "/static-fixture", base_path = "meta-page" })
            test.eq(err, nil)
            test.eq(meta.name, "@test/meta-page")
            test.eq(source, "app:test_static_fs/meta-page/wippy-meta.json")
        end)

        test.it("fetch_for_page fetches over HTTP from PUBLIC_API_URL when the mount cannot be used", function()
            local meta, err, source = bundled_meta.fetch_for_page({ id = "app:fixture_root_miss", url = "/no-such-page" })
            test.eq(meta, nil)
            test.eq(err, nil)
            test.eq(source, GATEWAY .. "/no-such-page/wippy-meta.json")
        end)

        test.it("fetch_for_page returns the public message for a bad file", function()
            local meta, err, source = bundled_meta.fetch_for_page({ id = "app:fixture_bad", url = "/static-fixture/bad-page" })
            test.eq(meta, nil)
            test.eq(err, bundled_meta.public_failure_message("page", "app:fixture_bad"))
            test.eq(source, "app:test_static_fs/bad-page/wippy-meta.json")
        end)

        test.it("fetch_for_component handles a component with only base_path", function()
            local meta, err = bundled_meta.fetch_for_component({ id = "app:fixture_component", base_path = "/static-fixture/meta-page" })
            test.eq(err, nil)
            test.eq(meta.name, "@test/meta-page")
        end)

        test.it("the page response carries the public message as wippy.metaError", function()
            local response, err = http_client.get(GATEWAY .. "/api/public/pages/content/app:test_bad_meta_page")
            test.eq(err, nil)
            test.eq(response.status_code, 200)
            local body = json.decode(response.body or "")
            test.eq(body.wippy.metaError, bundled_meta.public_failure_message("page", "app:test_bad_meta_page"))
            test.eq(body.wippy.metaError:find("fixtures", 1, true), nil)
        end)

        test.it("under the handler policies the read goes through the reader function", function()
            local result = load_as(HANDLER_POLICIES, "/static-fixture/meta-page/", "http://unused.invalid/")
            test.eq(result.err, nil)
            test.eq(result.over_http, false)
            test.eq(field(result.meta, "name"), "@test/meta-page")
        end)

        test.it("without the reader grant it fetches over HTTP and says why", function()
            local policies = without(HANDLER_POLICIES, "wippy.views:public_metadata_reader_runtime")
            local result = load_as(policies, "/static-fixture/meta-page/", GATEWAY .. "/static-fixture/meta-page/")
            test.eq(result.over_http, true)
            test.eq(field(result.meta, "name"), "@test/meta-page") -- served over HTTP
            test.ok(type(result.via) == "string"
                and result.via:find("wippy.views:read_static_meta could not run", 1, true) ~= nil,
                tostring(result.via))
        end)
    end)

end

local run_cases = test.run_cases(define_tests)

local function run(options: any): any
    return run_cases(options)
end

return { run = run }
