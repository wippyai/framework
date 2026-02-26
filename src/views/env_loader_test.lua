local test = require("test")
local registry = require("registry")
local env_loader = require("env_loader")

local NS = "wippy.views.test:"

local ENV_MAPPING_IDS = { "test_env_low", "test_env_high" }

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

local function teardown_env_mappings()
    local snap = registry.snapshot()
    local changes = snap:changes()
    for _, name in ipairs(ENV_MAPPING_IDS) do
        changes:delete(NS .. name)
    end
    changes:apply()
end

local function define_tests()
    test.describe("env loader", function()
        test.before_each(function()
            setup_env_mappings()
        end)

        test.after_each(function()
            teardown_env_mappings()
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
