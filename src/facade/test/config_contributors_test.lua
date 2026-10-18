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

        test.it("composes after the app resolver in the config handler", function()
            local source_fs, fs_err = fs.get("app.facade_test:source")
            test.is_nil(fs_err)
            test.not_nil(source_fs)
            local handler, handler_err = source_fs:readfile("/config_handler.lua")
            test.is_nil(handler_err)
            test.not_nil(handler)
            local resolver_at = string.find(handler, "local overrides = theming.resolve_overrides()", 1, true)
            local contributor_at = string.find(handler, "config_contributors.compose_requirements(overrides)", 1, true)
            local requirement_at = string.find(handler, "local function get_req(name", 1, true)
            test.not_nil(resolver_at)
            test.not_nil(contributor_at)
            test.not_nil(requirement_at)
            test.is_true(resolver_at < contributor_at)
            test.is_true(contributor_at < requirement_at)
            test.is_true(string.find(handler, "source_helpers", 1, true) == nil)
        end)
    end)
end

return { run = test.run_cases(define_tests) }
