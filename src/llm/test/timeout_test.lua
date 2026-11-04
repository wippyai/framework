local test = require("test")
local llm = require("llm")
local providers = require("providers")
local registry = require("registry")
local google_config = require("google_config")
local google_client = require("google_client")

local drivers = {
    { name = "Claude", generate = require("claude_generate"), client = require("claude_client"), env = "ANTHROPIC_TIMEOUT" },
    { name = "Bedrock", generate = require("bedrock_generate"), client = require("bedrock_client"), env = "BEDROCK_TIMEOUT" },
    { name = "OpenAI", generate = require("openai_generate"), client = require("openai_client"), env = "OPENAI_TIMEOUT" },
    { name = "compat", generate = require("compat_generate"), client = require("compat_client"), env = "OPENAI_COMPAT_TIMEOUT" },
    { name = "Google Generative AI", generate = require("google_generate"), client = require("generative_ai_client"), env = "GEN_AI_TIMEOUT" },
}

local function define_tests()
    describe("Generate HTTP timeout precedence", function()
        local restore

        before_each(function()
            restore = {}
        end)

        after_each(function()
            for i = #restore, 1, -1 do restore[i]() end
        end)

        local function replace(object, key, value)
            local original = object[key]
            restore[#restore + 1] = function() object[key] = original end
            object[key] = value
        end

        for _, driver in ipairs(drivers) do
            for _, streaming in ipairs({ false, true }) do
                it(driver.name .. (streaming and " streaming" or " generate") .. " honors every timeout level at HTTP", function()
                    local context = {}
                    local environment = {}
                    local configured = {}
                    local route = { id = "timeout-provider", provider_model = "wire-model" }
                    local sent
                    local calls = 0
                    local observed = {}

                    replace(llm, "_providers", providers)
                    replace(llm, "_usage_tracker", false)
                    replace(llm, "_model_resolver", { resolve = function()
                        return { name = "timeout-model", providers = { route } }
                    end })
                    replace(providers, "_registry", { get = function(id)
                        if id == "timeout-provider" then
                            return { meta = { type = "llm.provider" }, data = {
                                driver = { id = "timeout-driver", options = configured }
                            } }
                        end
                        return { meta = {} }
                    end })
                    replace(providers, "_contract", { get = function()
                        return {
                            with_context = function(self, values) context = values; return self end,
                            open = function()
                                return { generate = function(_, args) return driver.generate.handler(args) end }
                            end
                        }
                    end })
                    local ctx = { all = function() return context end, get = function(key) return context[key] end }
                    local env = { get = function(key) return environment[key] end }
                    local http = { post = function(_, options)
                        calls = calls + 1
                        sent = options.timeout
                        test.eq(options.stream == true, streaming)
                        return { status_code = 401, headers = {}, body = '{"error":{"message":"timeout probe"}}' }
                    end }
                    if driver.name == "Google Generative AI" then
                        replace(google_config, "_ctx", ctx)
                        replace(google_config, "_env", env)
                        replace(google_client, "_http_client", http)
                        replace(driver.client, "_config", google_config)
                        replace(driver.client, "_client", google_client)
                        replace(driver.generate, "_ctx", ctx)
                        replace(driver.generate, "_contract", { get = function()
                            return {
                                with_context = function(self) return self end,
                                open = function()
                                    return { request = function(_, args) return driver.client.request(args) end }
                                end
                            }
                        end })
                    else
                        replace(driver.generate, "_client", driver.client)
                        replace(driver.client, "_ctx", ctx)
                        replace(driver.client, "_env", env)
                        replace(driver.client, "_http_client", http)
                    end
                    if driver.name == "Bedrock" then
                        replace(driver.client, "_credentials", { resolve = function()
                            return { access_key = "test-access", secret_key = "test-secret" }
                        end })
                    end

                    local cases = {
                        { name = "options", option = 11, route = 22, configured = 33, reference = "44", env = "55" },
                        { name = "route", route = 22, configured = 33, reference = "44", env = "55" },
                        { name = "configured", configured = 33, reference = "44", env = "55" },
                        { name = "env reference", reference = "44", env = "55" },
                        { name = "env", env = "55" },
                        { name = "default" },
                    }
                    for _, case in ipairs(cases) do
                        configured = { api_key = "test-key", base_url = "https://timeout.invalid",
                            timeout = case.configured, timeout_env = "TEST_TIMEOUT" }
                        environment = { TEST_TIMEOUT = case.reference, [driver.env] = case.env }
                        route.context = { timeout = case.route }
                        sent = nil
                        calls = 0
                        local response, err = llm.generate("Hello", {
                            model = "timeout-model", timeout = case.option, retry = false,
                            stream = streaming and { reply_to = "timeout-test", topic = "timeout" } or nil
                        })
                        test.is_nil(response)
                        test.not_nil(err)
                        test.eq(calls, 1, case.name .. " reaches HTTP once")
                        observed[#observed + 1] = case.name .. "=" .. tostring(sent)
                            .. (type(sent) == "number" and "" or ":" .. type(sent))
                    end

                    test.eq(table.concat(observed, ", "),
                        "options=11, route=22, configured=33, env reference=44, env=55, default=600")
                end)
            end
        end

        it("Claude declares the effective 600-second default", function()
            local entry, err = registry.get("wippy.llm.claude:driver")
            test.is_nil(err)
            test.eq(entry.data.optional_context.timeout.default_value, 600)
        end)
    end)
end

return test.run_cases(define_tests)
