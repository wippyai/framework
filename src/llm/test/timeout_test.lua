local test = require("test")
local llm = require("llm")
local providers = require("providers")
local registry = require("registry")
local google_config = require("google_config")
local google_client = require("google_client")
local transport = require("transport")
local bedrock_credentials = require("bedrock_credentials")

local drivers = {
    { name = "Claude", generate = require("claude_generate"), structured = require("claude_structured"), client = require("claude_client"), env = "ANTHROPIC_TIMEOUT" },
    { name = "Bedrock", generate = require("bedrock_generate"), structured = require("bedrock_structured"), client = require("bedrock_client"), env = "BEDROCK_TIMEOUT" },
    { name = "OpenAI", generate = require("openai_generate"), structured = require("openai_structured"), client = require("openai_client"), env = "OPENAI_TIMEOUT" },
    { name = "compat", generate = require("compat_generate"), structured = require("compat_structured"), client = require("compat_client"), env = "OPENAI_COMPAT_TIMEOUT" },
    { name = "Google Generative AI", generate = require("google_generate"), structured = require("google_structured_output"), client = require("generative_ai_client"), env = "GEN_AI_TIMEOUT", google = true },
    { name = "Google Vertex", generate = require("google_generate"), structured = require("google_structured_output"), client = require("vertex_client"), env = "VERTEX_AI_TIMEOUT", google = true },
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

        local function setup(driver, operation, backup)
            local context = {}
            local environment = {}
            local configured = {}
            local route = { id = "timeout-provider", provider_model = "wire-model" }
            local routes = { route }
            if backup then
                routes[2] = { id = "timeout-provider", provider_model = "backup-model" }
            end
            local sent, headers
            local client_error
            local calls = 0
            local handler = operation == "structured" and driver.structured or driver.generate
            local streaming = operation == "streaming"
            replace(llm, "_clock", function() return 1000000 end)
            replace(transport, "now_ms", function() return 1000000 end)

            replace(llm, "_providers", providers)
            replace(llm, "_usage_tracker", false)
            replace(llm, "_model_resolver", { resolve = function()
                return { name = "timeout-model", providers = routes,
                    fallback_on = backup and backup.fallback_on }
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
                        return {
                            generate = function(_, args)
                                if args.model == "backup-model" then
                                    return { success = true, result = { content = "backup" }, metadata = {} }
                                end
                                return handler.handler(args)
                            end,
                            structured_output = function(_, args) return handler.handler(args) end,
                        }
                    end
                }
            end })
            local ctx = { all = function() return context end, get = function(key) return context[key] end }
            local env = { get = function(key) return environment[key] end }
            local http = { post = function(_, options)
                calls = calls + 1
                sent = options.timeout
                headers = options.headers
                test.eq(options.stream == true, streaming)
                return { status_code = 401, headers = {}, body = '{"error":{"message":"timeout probe"}}' }
            end }
            if driver.google then
                replace(google_config, "_ctx", ctx)
                replace(google_config, "_env", env)
                replace(google_config, "get_oauth2_token", function() return { access_token = "test-token" } end)
                replace(google_config, "get_project_id", function() return "test-project" end)
                replace(google_config, "get_vertex_location", function() return "us-central1" end)
                replace(google_client, "_http_client", http)
                replace(driver.client, "_config", google_config)
                replace(driver.client, "_client", google_client)
                replace(handler, "_ctx", ctx)
                replace(handler, "_contract", { get = function()
                    return {
                        with_context = function(self) return self end,
                        open = function()
                            return { request = function(_, args) return driver.client.request(args) end }
                        end
                    }
                end })
            else
                replace(handler, "_client", driver.client)
                replace(driver.client, "_ctx", ctx)
                replace(driver.client, "_env", env)
                replace(driver.client, "_http_client", http)
            end
            if driver.name == "Bedrock" then
                replace(driver.client, "_credentials", bedrock_credentials)
                replace(bedrock_credentials, "_ctx", ctx)
                replace(bedrock_credentials, "_env", env)
            end
            local method = driver.name == "Bedrock" and (streaming and "converse_stream" or "converse") or "request"
            local request = driver.client[method]
            replace(driver.client, method, function(...)
                local response, err = request(...)
                client_error = driver.google and response or err
                return response, err
            end)

            return function(case, deadline)
                configured = { api_key = "test-key", base_url = "https://timeout.invalid",
                    timeout = case.configured, timeout_env = "TEST_TIMEOUT",
                    access_key = "test-access", secret_key = "test-secret" }
                environment = { TEST_TIMEOUT = case.reference ~= nil and tostring(case.reference) or nil,
                    [driver.env] = case.env ~= nil and tostring(case.env) or nil }
                if case.key_env then
                    environment[case.key_env] = "env-secret"
                    if driver.name == "Bedrock" then
                        environment.AWS_SECRET_ACCESS_KEY = "env-secret"
                        environment.AWS_SESSION_TOKEN = "env-secret"
                    end
                end
                route.context = { timeout = case.route, api_key = case.api_key,
                    access_key = case.api_key, secret_key = case.api_key, session_token = case.api_key }
                route.options = { timeout = case.route_option }
                sent, calls, client_error = nil, 0, nil
                local options = { model = "timeout-model", timeout = case.option, retry = false,
                    deadline_ms = deadline,
                    stream = streaming and { reply_to = "timeout-test", topic = "timeout" } or nil }
                local response, err
                if operation == "structured" then
                    response, err = llm.structured_output({ type = "object",
                        properties = { ok = { type = "boolean" } }, required = { "ok" },
                        additionalProperties = false }, "Hello", options)
                else
                    response, err = llm.generate("Hello", options)
                end
                if not backup then
                    test.is_nil(response)
                    test.not_nil(err)
                end
                return sent, calls, err, response, client_error, headers
            end
        end

        local levels = { "option", "route_option", "route", "configured", "reference", "env" }
        local sources = { option = "options.timeout", route_option = "options.timeout",
            route = "context.timeout", configured = "context.timeout", reference = "TEST_TIMEOUT" }
        local function precedence_case(level, value, higher)
            local case, found = {}, false
            for _, key in ipairs(levels) do
                case[key] = key == level and value or (found and 33 or higher)
                if key == level then found = true end
            end
            return case
        end

        local key_envs = { Claude = "ANTHROPIC_API_KEY", Bedrock = "AWS_ACCESS_KEY_ID",
            OpenAI = "OPENAI_API_KEY", compat = "OPENAI_COMPAT_API_KEY",
            ["Google Generative AI"] = "GEMINI_API_KEY" }
        for _, driver in ipairs(drivers) do
            if key_envs[driver.name] then
                it(driver.name .. " never sends an env key when the route key is explicitly empty", function()
                    local call = setup(driver, "generate")
                    local _, calls, _, _, _, headers = call({ api_key = "", key_env = key_envs[driver.name] })
                    test.eq(calls, 1)
                    for _, value in pairs(headers) do
                        test.is_nil(tostring(value):find("env-secret", 1, true), "env key leaks in HTTP headers")
                    end
                end)
            end
        end

        it("Bedrock metadata requests send millisecond durations through dispatch", function()
            local seen = {}
            local function capture(url, options)
                seen[#seen + 1] = tostring(options.timeout)
                local body = '{}'
                if url:match("/token$") then body = "token"
                elseif url:match("/security%-credentials/$") then body = "role" end
                return { status_code = 200, body = body }
            end
            replace(bedrock_credentials, "_env", { get = function(key)
                if key == "AWS_CONTAINER_CREDENTIALS_FULL_URI" then return "https://metadata.invalid" end
            end })
            replace(bedrock_credentials, "_http_client", { get = capture, put = capture })
            local _, err = bedrock_credentials.fetch_container_credentials()
            test.is_nil(err)
            _, err = bedrock_credentials.fetch_instance_credentials()
            test.is_nil(err)
            test.ok(bedrock_credentials.has_instance_endpoint())
            test.eq(table.concat(seen, ","), "5000ms,2000ms,2000ms,2000ms,1000ms")
        end)

        for _, driver in ipairs(drivers) do
            it(driver.name .. " switches streaming routes on an invalid timeout only with fallback_on", function()
                local backup = {}
                local call = setup(driver, "streaming", backup)
                local _, calls, err, response = call({ route = "soon" })
                test.is_nil(response)
                test.eq(err:details().error_type, "invalid_request")
                test.contains(err:message(), "soon")
                test.contains(err:message(), "context.timeout")
                test.eq(calls, 0)

                backup.fallback_on = { "invalid_request" }
                _, calls, err, response = call({ route = "soon" })
                test.is_nil(err)
                test.eq(response.result, "backup")
                test.eq(response.metadata.route.provider_model, "backup-model")
                test.eq(#response.metadata.fallbacks, 1)
                test.eq(response.metadata.fallbacks[1].error_type, "invalid_request")
                test.eq(calls, 0)
            end)

            for _, operation in ipairs({ "generate", "streaming", "structured" }) do
                local name = driver.name .. " " .. operation
                for _, value in ipairs({ 90, "90", "20m" }) do
                    it(name .. " normalizes " .. type(value) .. " " .. tostring(value) .. " at every timeout level at HTTP", function()
                        local call = setup(driver, operation)
                        for _, level in ipairs(levels) do
                            local sent, calls = call(precedence_case(level, value))
                            test.eq(calls, 1, level)
                            test.eq(sent, value == "20m" and "1200000ms" or "90000ms", level)
                        end
                    end)
                end
                it(name .. " falls through empty timeout levels and defaults to 600", function()
                    local call = setup(driver, operation)
                    for _, case in ipairs({ {}, { option = "", route_option = "", route = "",
                        configured = "", reference = "", env = "" } }) do
                        local sent, calls = call(case)
                        test.eq(calls, 1)
                        test.eq(sent, "600000ms")
                    end
                    for _, level in ipairs(levels) do
                        local sent, calls = call(precedence_case(level, "90", ""))
                        test.eq(calls, 1, level)
                        test.eq(sent, "90000ms", level)
                    end
                end)
                for _, level in ipairs(levels) do
                    it(name .. " rejects soon from " .. level .. " before HTTP", function()
                        local call = setup(driver, operation)
                        for _, deadline in ipairs({ false, 1800000 }) do
                            local _, calls, err, _, client_error = call(precedence_case(level, "soon"), deadline or nil)
                            test.eq(err:details().error_type, "invalid_request")
                            test.contains(err:message(), "soon")
                            test.contains(err:message(), sources[level] or driver.env)
                            test.eq(calls, 0)
                            if operation == "streaming" then
                                test.eq(client_error.stream_started, false)
                            end
                        end
                    end)
                end
                for _, deadline in ipairs({ 30000, 1800000 }) do
                    it(name .. " caps 20m with deadline_ms=" .. deadline .. " at every timeout level", function()
                        local call = setup(driver, operation)
                        for _, level in ipairs(levels) do
                            local sent, calls = call(precedence_case(level, "20m"), deadline)
                            test.eq(calls, 1, level)
                            test.eq(sent, tostring(math.min(deadline, 1200000)) .. "ms", level)
                        end
                    end)
                end
            end
        end

        for _, operation in ipairs({
            { name = "generate", handler = require("google_generate"), method = "POST" },
            { name = "structured output", handler = require("google_structured_output"), method = "POST" },
            { name = "health checks", handler = require("google_status"), method = "GET" },
        }) do
            it("Google Generative AI " .. operation.name .. " normalizes configured timeout formats to millisecond durations at HTTP", function()
                local client = require("generative_ai_client")
                local context = { api_key = "test-key", base_url = "https://timeout.invalid" }
                local environment = {}
                local ctx = { all = function() return context end, get = function(key) return context[key] end }
                local sent, method
                local calls = 0
                local function capture(verb, options)
                    calls = calls + 1
                    method = verb
                    sent = options.timeout
                    return { status_code = 401, headers = {}, body = '{"error":{"message":"timeout probe"}}' }
                end

                replace(google_config, "_ctx", ctx)
                replace(google_config, "_env", { get = function(key) return environment[key] end })
                replace(google_client, "_http_client", {
                    post = function(_, options) return capture("POST", options) end,
                    get = function(_, options) return capture("GET", options) end,
                })
                replace(client, "_config", google_config)
                replace(client, "_client", google_client)
                replace(operation.handler, "_ctx", ctx)
                replace(operation.handler, "_contract", { get = function()
                    return {
                        with_context = function(self) return self end,
                        open = function()
                            return { request = function(_, args) return client.request(args) end }
                        end
                    }
                end })

                for _, case in ipairs({
                    { configured = "90", expected = "90000ms" },
                    { expected = "600000ms" },
                    { configured = "20m", expected = "1200000ms" },
                }) do
                    environment.GEN_AI_TIMEOUT = case.configured
                    sent, method, calls = nil, nil, 0
                    operation.handler.handler({
                        model = "gemini-2.5-flash",
                        messages = { { role = "user", content = { { type = "text", text = "Hello" } } } },
                        schema = { type = "object", properties = { ok = { type = "boolean" } } },
                    })
                    test.eq(calls, 1)
                    test.eq(method, operation.method)
                    test.eq(sent, case.expected)
                end
            end)
        end

        it("Claude declares the effective 600-second default", function()
            local entry, err = registry.get("wippy.llm.claude:driver")
            test.is_nil(err)
            test.eq(entry.data.optional_context.timeout.default_value, 600)
        end)
    end)
end

return test.run_cases(define_tests)
