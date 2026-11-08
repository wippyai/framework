local test = require("test")
local json = require("json")
local fs = require("fs")
local core = require("config_contributors_core")

local function entry(id: string, inputs: table, outputs: table): table
    return {
        id = id,
        kind = "function.lua",
        meta = {
            type = "wippy.facade.config_contributor",
            config_inputs = inputs,
            config_outputs = outputs,
        },
    }
end

local function compose(entries: table, handlers: table?, defaults: table?): (table, table, table)
    local criteria
    local registry_api = {
        find = function(value: table)
            criteria = value
            return entries, nil
        end,
    }
    local calls = {}
    local funcs_api = {
        call = function(id: string, payload: table)
            calls[#calls + 1] = { id = id, payload = payload }
            local handler = handlers and handlers[id]
            if not handler then return nil, "missing test handler" end
            return handler(payload)
        end,
    }
    local theming_api = {
        requirement = function(name: string, overrides: table)
            if next(overrides) ~= nil then error("defaults lookup received overrides") end
            return (defaults and defaults[name]) or "default:" .. name
        end,
    }
    local contributor = core.new(registry_api, json, funcs_api, theming_api)
    local output, diagnostics = contributor.compose_requirements({ app_title = "", secret = "hidden" })
    return output, diagnostics, { calls = calls, criteria = criteria }
end

-- A contributor shaped like wippy/cdn-web-host: it supplies fe_facade_url
-- unless the app resolver already set one.
local function CDN_LIKE(payload: table): table
    if payload.overrides.fe_facade_url ~= nil then return { overrides = {} } end
    return { overrides = { fe_facade_url = "http://app.test/cdn/web-host/webcomponents-1.0.68" } }
end

-- resolve_requirements with one fe_facade_url contributor and the given app
-- resolver values. Returns the overrides, the warnings and the last call.
local function resolve(resolver_values: table, handler: any): (table, table, table)
    local id = "app.cdn:facade_config_contribute"
    local seen = {}
    local registry_api = {
        find = function() return { entry(id, { "fe_facade_url" }, { "fe_facade_url" }) }, nil end,
    }
    local funcs_api = {
        call = function(called: string, payload: table)
            seen.id = called
            seen.payload = payload
            return handler(payload)
        end,
    }
    local theming_api = {
        requirement = function(name: string) return "default:" .. name end,
        resolve_overrides = function() return resolver_values end,
    }
    local warnings = {}
    local contributor = core.new(registry_api, json, funcs_api, theming_api)
    local output = contributor.resolve_requirements(function(message: string)
        warnings[#warnings + 1] = message
    end)
    return output, warnings, seen
end

local function define_tests()
    test.describe("Facade configuration contributors", function()
        test.it("discovers exact contributor functions and passes only declared inputs", function()
            local id = "app.branding:facade_config_contribute"
            local output, diagnostics, observed = compose({ entry(id, { "app_title" }, { "app_name" }) }, {
                [id] = function(payload)
                    test.eq(payload.defaults.app_title, "default:app_title")
                    test.eq(payload.overrides.app_title, "")
                    test.eq(payload.overrides.secret, nil)
                    test.eq(payload.defaults.secret, nil)
                    return { overrides = { app_name = "Brand" } }
                end,
            })
            test.eq(observed.criteria[".kind"], "function.lua")
            test.eq(observed.criteria["meta.type"], "wippy.facade.config_contributor")
            test.eq(#observed.calls, 1)
            test.eq(output.app_name, "Brand")
            test.eq(output.app_title, "")
            test.eq(#diagnostics, 0)
        end)

        test.it("skips malformed metadata and preserves original overrides", function()
            local bad = entry("app.bad:facade_config_contribute", { "Bad" }, { "app_name" })
            local output, diagnostics, observed = compose({ bad }, {})
            test.eq(output.app_title, "")
            test.eq(#observed.calls, 0)
            test.eq(#diagnostics, 1)
        end)

        test.it("checks the discovered entry kind and metadata type", function()
            local wrong_kind = entry("app.kind:facade_config_contribute", {}, { "app_name" })
            wrong_kind.kind = "library.lua"
            local wrong_type = entry("app.type:facade_config_contribute", {}, { "app_name" })
            wrong_type.meta.type = "another.type"
            local output, diagnostics, observed = compose({ wrong_kind, wrong_type }, {})
            test.eq(output.app_name, nil)
            test.eq(#observed.calls, 0)
            test.eq(#diagnostics, 2)
        end)

        test.it("skips contributor exceptions and malformed return values", function()
            local throwing = "app.throwing:facade_config_contribute"
            local malformed = "app.malformed:facade_config_contribute"
            local output, diagnostics = compose({
                entry(throwing, {}, { "app_title" }),
                entry(malformed, {}, { "app_name" }),
            }, {
                [throwing] = function() error("test failure") end,
                [malformed] = function() return { overrides = { unknown_key = "bad" } } end,
            })
            test.eq(output.app_title, "")
            test.eq(output.app_name, nil)
            test.eq(#diagnostics, 2)
        end)

        test.it("skips every contributor that declares a conflicting output", function()
            local first = "app.first:facade_config_contribute"
            local second = "app.second:facade_config_contribute"
            local output, diagnostics, observed = compose({
                entry(first, {}, { "app_title" }),
                entry(second, {}, { "app_title" }),
            }, {
                [first] = function() return { overrides = { app_title = "First" } } end,
                [second] = function() return { overrides = { app_title = "Second" } } end,
            })
            test.eq(output.app_title, "")
            test.eq(#observed.calls, 0)
            test.eq(#diagnostics, 2)
        end)

        test.it("rejects oversized output and unsupported result fields", function()
            local too_large = "app.large:facade_config_contribute"
            local extra_field = "app.extra:facade_config_contribute"
            local output, diagnostics = compose({
                entry(too_large, {}, { "app_title" }),
                entry(extra_field, {}, { "app_name" }),
            }, {
                [too_large] = function() return { overrides = { app_title = string.rep("x", 262145) } } end,
                [extra_field] = function() return { overrides = { app_name = "Brand" }, extra = true } end,
            })
            test.eq(output.app_title, "")
            test.eq(output.app_name, nil)
            test.eq(#diagnostics, 2)
        end)

        test.it("applies a contribution when the app resolver has no value", function()
            local output, warnings, seen = resolve({}, CDN_LIKE)
            test.eq(output.fe_facade_url, "http://app.test/cdn/web-host/webcomponents-1.0.68")
            test.eq(seen.payload.overrides.fe_facade_url, nil)
            test.eq(seen.payload.defaults.fe_facade_url, "default:fe_facade_url")
            test.eq(#warnings, 0)
        end)

        test.it("passes the app resolver's value to contributors, which may defer to it", function()
            local output, warnings, seen = resolve({ fe_facade_url = "https://tenant.test/host" }, CDN_LIKE)
            test.eq(seen.payload.overrides.fe_facade_url, "https://tenant.test/host")
            test.eq(output.fe_facade_url, "https://tenant.test/host")
            test.eq(#warnings, 0)
        end)

        test.it("reports a skipped contribution and keeps the app resolver's values", function()
            local output, warnings = resolve({ app_title = "Tenant" }, function() return nil, "boom" end)
            test.eq(output.app_title, "Tenant")
            test.eq(output.fe_facade_url, nil)
            test.eq(#warnings, 1)
        end)

        test.it("is the one resolution path of the config handler and host_url", function()
            local source_fs, fs_err = fs.get("app.facade_test:source")
            test.is_nil(fs_err)
            test.not_nil(source_fs)
            local handler, handler_err = source_fs:readfile("/config_handler.lua")
            test.is_nil(handler_err)
            test.not_nil(handler)
            local resolved_at = string.find(handler, "local overrides = config_contributors.resolve_requirements()", 1, true)
            local requirement_at = string.find(handler, "local function get_req(name", 1, true)
            test.not_nil(resolved_at)
            test.not_nil(requirement_at)
            test.is_true(resolved_at < requirement_at)
            test.is_true(string.find(handler, "theming.resolve_overrides()", 1, true) == nil)
            test.is_true(string.find(handler, "source_helpers", 1, true) == nil)
            local host_url, host_err = source_fs:readfile("/host_url.lua")
            test.is_nil(host_err)
            test.not_nil((string.find(host_url, 'theming.requirement("fe_facade_url", config_contributors.resolve_requirements())', 1, true)))
        end)
    end)
end

return { run = test.run_cases(define_tests) }
