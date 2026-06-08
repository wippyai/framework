local test = require("test")
local bundled_meta = require("bundled_meta")

-- Tests for the projection helpers in bundled_meta.lua. These are pure
-- (no http_client / no store / no registry lookups), so we can exercise
-- them directly with synthetic inputs.
--
-- Core invariant codified here: **YAML always wins on a field-by-field
-- basis.** YAML is the abstraction OVER FE code. Bundled meta is the
-- fallback source for fields YAML omits, never an override for fields
-- YAML explicitly sets. Tests are written so that flipping this
-- precedence anywhere in the projection helpers will FAIL.

local function define_tests()
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
            test.eq(r.dependencies, nil)
            test.eq(r.devDependencies, nil)
            test.eq(r.scripts, nil)
            test.eq(r.description, nil)
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

end

local run_cases = test.run_cases(define_tests)

local function run(options: any): any
    return run_cases(options)
end

return { run = run }
