local test = require("test")
local llm = require("llm")
local claude_generate = require("claude_generate")
local claude_structured = require("claude_structured")
local bedrock_generate = require("bedrock_generate")
local bedrock_structured = require("bedrock_structured")
local google_generate = require("google_generate")
local google_structured = require("google_structured")
local openai_generate = require("openai_generate")
local openai_structured = require("openai_structured")
local openai_compat_generate = require("openai_compat_generate")
local openai_compat_structured = require("openai_compat_structured")

local function define_tests()
    describe("Route facts through drivers", function()
        local saved_providers, saved_tracker, saved_resolver
        local saved_clients = {}
        local saved_google = {}

        before_each(function()
            saved_providers = llm._providers
            saved_tracker = llm._usage_tracker
            saved_resolver = llm._model_resolver
            llm._usage_tracker = false
            for _, handler in ipairs({ claude_generate, claude_structured, bedrock_generate, bedrock_structured,
                openai_generate, openai_structured, openai_compat_generate, openai_compat_structured }) do
                saved_clients[handler] = handler._client
            end
            for _, handler in ipairs({ google_generate, google_structured }) do
                saved_google[handler] = { contract = handler._contract, ctx = handler._ctx }
            end
        end)

        after_each(function()
            llm._providers = saved_providers
            llm._usage_tracker = saved_tracker
            llm._model_resolver = saved_resolver
            for handler, client in pairs(saved_clients) do handler._client = client end
            for handler, saved in pairs(saved_google) do
                handler._contract = saved.contract
                handler._ctx = saved.ctx
            end
        end)

        local schema = { type = "object", properties = { answer = { type = "string" } },
            required = { "answer" }, additionalProperties = false }

        local function call(method, options)
            if method == "generate" then return llm.generate("Answer", options) end
            return llm.structured_output(schema, "Answer", options)
        end

        for _, provider in ipairs({ "claude", "bedrock" }) do
            for _, method in ipairs({ "generate", "structured_output" }) do
                local handler = provider == "claude"
                    and (method == "generate" and claude_generate or claude_structured)
                    or (method == "generate" and bedrock_generate or bedrock_structured)

                local function setup()
                    local sent: any = {}
                    local function request(_, payload)
                        sent.payload = payload
                        if provider == "claude" then
                            return {
                                content = { { type = "text", text = "ok" },
                                    { type = "tool_use", name = "structured_output", id = "one", input = { answer = "ok" } } },
                                stop_reason = "end_turn", usage = { input_tokens = 1, output_tokens = 1 },
                                metadata = { request_id = "kept" }
                            }
                        end
                        return {
                            output = { message = { role = "assistant", content = {
                                { text = "ok" },
                                { toolUse = { toolUseId = "one", name = "structured_output", input = { answer = "ok" } } }
                            } } },
                            stopReason = "end_turn", usage = { inputTokens = 1, outputTokens = 1 },
                            metadata = { request_id = "kept" }
                        }
                    end
                    handler._client = { ENDPOINTS = { MESSAGES = "/messages" }, request = request, converse = request }
                    llm._providers = { driver_declares_legacy_reasoning_flag = function() return false end, driver_output_policy = function() return nil, nil end, open = function()
                        return { [method] = function(_, args) return handler.handler(args) end }
                    end }
                    return sent
                end

                it("never reinjects a temperature for " .. provider .. " " .. method .. " budget thinking", function()
                    for _, accepts in ipairs({ { thinking = "budget" }, {} }) do
                        local sent = setup()
                        local result, err = call(method, { provider_id = "route", model = "wire",
                            accepts = accepts, thinking_effort = 50, temperature = 0.4 })
                        test.is_nil(err)
                        local payload = sent.payload :: table
                        local config = provider == "claude" and payload or payload.inferenceConfig
                        test.is_nil(config.temperature)
                        test.eq(result.metadata.adjusted.temperature.requested, 0.4)
                        test.is_nil(result.metadata.adjusted.temperature.sent)
                        test.eq(result.metadata.request_id, "kept")
                    end
                end)

                it("removes sampling and never reinjects budget temperature for " .. provider .. " " .. method, function()
                    for _, accepts in ipairs({ { thinking = "budget", sampling = false }, { sampling = false } }) do
                        local sent = setup()
                        local result, err = call(method, { provider_id = "route", model = "wire",
                            accepts = accepts, thinking_effort = 50, temperature = 0.4 })
                        test.is_nil(err)
                        local payload = sent.payload :: table
                        local config = provider == "claude" and payload or payload.inferenceConfig
                        test.is_nil(config.temperature)
                        test.eq(result.metadata.adjusted.temperature.requested, 0.4)
                        test.is_nil(result.metadata.adjusted.temperature.sent)
                        local adjusted_count = 0
                        for _ in pairs(result.metadata.adjusted) do adjusted_count = adjusted_count + 1 end
                        test.eq(adjusted_count, 1)
                    end
                end)

                it("sends the caller's temperature of 1 unchanged for " .. provider .. " " .. method .. " budget thinking", function()
                    local sent = setup()
                    local result, err = call(method, { provider_id = "route", model = "wire",
                        accepts = { thinking = "budget" }, thinking_effort = 50, temperature = 1 })
                    test.is_nil(err)
                    local payload = sent.payload :: table
                    local config = provider == "claude" and payload or payload.inferenceConfig
                    test.eq(config.temperature, 1)
                    test.is_nil(result.metadata.adjusted)
                end)

                it("rejects strict " .. provider .. " " .. method .. " budget changes before HTTP", function()
                    local sent = setup()
                    local result, err = call(method, { provider_id = "route", model = "wire",
                        accepts = { thinking = "budget" }, thinking_effort = 50, temperature = 0.4, strict = true })
                    test.is_nil(result)
                    test.eq(err:kind(), errors.INVALID)
                    test.eq(tostring(err), err:message())
                    test.contains(err:message(), "temperature")
                    test.is_nil(sent.payload)
                end)

                it("sends the adaptive thinking object for " .. provider .. " " .. method .. " on an always route without effort", function()
                    for _, case in ipairs({ { thinking = "always", sends = true }, { thinking = "adaptive", sends = false } }) do
                        local sent = setup()
                        local _, err = call(method, { provider_id = "route", model = "wire", accepts = { thinking = case.thinking } })
                        test.is_nil(err)
                        local payload = sent.payload :: table
                        local fields = provider == "claude" and payload or (payload.additionalModelRequestFields or {})
                        if case.sends then
                            test.eq(fields.thinking.type, "adaptive")
                        else
                            test.is_nil(fields.thinking)
                        end
                        test.is_nil(fields.output_config)
                    end
                end)

                it("encodes " .. provider .. " " .. method .. " adaptive thinking after central sampling removal", function()
                    local sent = setup()
                    local result, err = call(method, { provider_id = "route", model = "wire",
                        accepts = { thinking = "adaptive", sampling = false }, thinking_effort = 50, temperature = 0.4 })
                    test.is_nil(err)
                    local payload = sent.payload :: table
                    local fields = provider == "claude" and payload or payload.additionalModelRequestFields
                    test.eq(fields.thinking.type, "adaptive")
                    test.eq(fields.output_config.effort, "medium")
                    test.is_nil(fields.thinking.budget_tokens)
                    local config = provider == "claude" and payload or payload.inferenceConfig
                    test.is_nil(config.temperature)
                    test.eq(result.metadata.adjusted.temperature.requested, 0.4)
                    test.is_nil(result.metadata.adjusted.temperature.sent)
                end)
            end
        end

        for _, provider in ipairs({ "claude", "bedrock" }) do
            local handler = provider == "claude" and claude_generate or bedrock_generate
            local tools = { { name = "finish", description = "Finish", schema = { type = "object" } } }

            local function setup_tool_choice()
                local sent: any = {}
                local function request(_, payload)
                    sent.payload = payload
                    if provider == "claude" then
                        return {
                            content = { { type = "tool_use", id = "one", name = "finish", input = { answer = "ok" } } },
                            stop_reason = "tool_use", usage = { input_tokens = 1, output_tokens = 1 }, metadata = {}
                        }
                    end
                    return {
                        output = { message = { role = "assistant", content = {
                            { toolUse = { toolUseId = "one", name = "finish", input = { answer = "ok" } } }
                        } } },
                        stopReason = "tool_use", usage = { inputTokens = 1, outputTokens = 1 }, metadata = {}
                    }
                end
                handler._client = { ENDPOINTS = { MESSAGES = "/messages" }, request = request, converse = request }
                llm._providers = { driver_declares_legacy_reasoning_flag = function() return false end, driver_output_policy = function() return nil, nil end, open = function()
                    return { generate = function(_, args) return handler.handler(args) end }
                end }
                return sent
            end

            it("sends " .. provider .. " tool_choice as auto under the fallback and reports the substitution", function()
                local sent = setup_tool_choice()
                local result, err = call("generate", { provider_id = "route", model = "wire",
                    accepts = { forced_tool_choice = false }, tools = tools, tool_choice = "any",
                    tool_choice_fallback = "auto" })
                test.is_nil(err)
                local payload = sent.payload :: table
                if provider == "claude" then
                    test.eq(payload.tool_choice.type, "auto")
                else
                    test.is_nil((payload.toolConfig :: table).toolChoice)
                end
                test.eq(result.metadata.tool_choice.requested, "any")
                test.eq(result.metadata.tool_choice.sent, "auto")
            end)

            it("rejects a forced " .. provider .. " tool_choice with no fallback before HTTP", function()
                local sent = setup_tool_choice()
                local result, err = call("generate", { provider_id = "route", model = "wire",
                    accepts = { forced_tool_choice = false }, tools = tools, tool_choice = "any" })
                test.is_nil(result)
                test.eq(err:kind(), errors.INVALID)
                test.eq(tostring(err), err:message())
                test.contains(err:message(), "forced_tool_choice")
                test.is_nil(sent.payload)
            end)
        end

        -- Each driver: its handlers, a stub recording the wire body, a route,
        -- a request overlay and the expected body, and a key it owns.
        local answer = '{"answer":"ok"}'
        local drivers = {
            {
                name = "claude", generate = claude_generate, structured_output = claude_structured,
                accepts = { thinking = "adaptive" }, reserved = "messages",
                request = { thinking = { type = "between_tools" } },
                schema_path = "output_config.format",
                schema_request = { output_config = { format = { type = "json_schema", schema = {} } } },
                install = function(handler, sent)
                    handler._client = { ENDPOINTS = { MESSAGES = "/messages" }, request = function(_, payload)
                        sent.payload = payload
                        return { content = { { type = "text", text = "ok" },
                            { type = "tool_use", name = "structured_output", id = "one", input = { answer = "ok" } } },
                            stop_reason = "end_turn", usage = { input_tokens = 1, output_tokens = 1 }, metadata = {} }
                    end }
                end,
                check = function(payload)
                    test.eq(payload.thinking.type, "between_tools")
                    test.eq(payload.output_config.effort, "medium")
                end
            },
            {
                name = "claude native", generate = claude_generate, structured_output = claude_structured,
                accepts = { thinking = "adaptive", structured_output = "native" }, reserved = "messages",
                request = { output_config = { effort = "low" } },
                schema_path = "output_config.format",
                schema_request = { output_config = { format = { type = "json_schema", schema = {} } } },
                install = function(handler, sent)
                    handler._client = { ENDPOINTS = { MESSAGES = "/messages" }, request = function(_, payload)
                        sent.payload = payload
                        return { content = { { type = "text", text = answer } },
                            stop_reason = "end_turn", usage = { input_tokens = 1, output_tokens = 1 }, metadata = {} }
                    end }
                end,
                check = function(payload, method)
                    test.eq(payload.output_config.effort, "low")
                    if method == "structured_output" then
                        test.eq(payload.output_config.format.type, "json_schema")
                    end
                end
            },
            {
                name = "bedrock", generate = bedrock_generate, structured_output = bedrock_structured,
                accepts = { thinking = "adaptive" }, reserved = "messages",
                request = { additionalModelRequestFields = { thinking = { type = "between_tools" } } },
                install = function(handler, sent)
                    handler._client = { converse = function(_, payload)
                        sent.payload = payload
                        return { output = { message = { role = "assistant", content = { { text = "ok" },
                            { toolUse = { toolUseId = "one", name = "structured_output", input = { answer = "ok" } } } } } },
                            stopReason = "end_turn", usage = { inputTokens = 1, outputTokens = 1 }, metadata = {} }
                    end }
                end,
                check = function(payload)
                    local fields = payload.additionalModelRequestFields
                    test.eq(fields.thinking.type, "between_tools")
                    test.eq(fields.output_config.effort, "medium")
                end
            },
            {
                name = "openai", generate = openai_generate, structured_output = openai_structured,
                accepts = { thinking = "adaptive" }, reserved = "input",
                request = { reasoning = { summary = "auto", effort = "low" } },
                schema_path = "text.format",
                schema_request = { text = { format = { type = "json_object" } } },
                install = function(handler, sent)
                    handler._client = { request = function(_, payload)
                        sent.payload = payload
                        return { id = "resp", status = "completed", metadata = {},
                            output = { { type = "message", content = { { type = "output_text", text = answer } } } },
                            usage = { input_tokens = 1, output_tokens = 1 } }
                    end }
                end,
                check = function(payload)
                    test.eq(payload.reasoning.summary, "auto")
                    test.eq(payload.reasoning.effort, "low")
                end
            },
            {
                name = "openai_compat", generate = openai_compat_generate, structured_output = openai_compat_structured,
                accepts = { thinking = "adaptive" }, reserved = "messages",
                request = { reasoning_effort = "low", top_k = 4 },
                schema_path = "response_format",
                schema_request = { response_format = { type = "json_object" } },
                install = function(handler, sent)
                    handler._client = { request = function(_, payload)
                        sent.payload = payload
                        return { choices = { { message = { role = "assistant", content = answer }, finish_reason = "stop" } },
                            usage = { prompt_tokens = 1, completion_tokens = 1 }, metadata = {} }
                    end }
                end,
                check = function(payload)
                    test.eq(payload.reasoning_effort, "low")
                    test.eq(payload.top_k, 4)
                end
            },
            {
                name = "google", generate = google_generate, structured_output = google_structured,
                accepts = {}, reserved = "contents",
                request = { generationConfig = { thinkingConfig = { thinkingBudget = 0 }, temperature = 0.3 } },
                schema_path = "generationConfig.responseSchema",
                schema_request = { generationConfig = { responseSchema = { type = "object" } } },
                install = function(handler, sent)
                    local instance = { request = function(_, args)
                        sent.payload = args.payload
                        return { status_code = 200, metadata = {},
                            candidates = { { content = { parts = { { text = answer } } }, finishReason = "STOP" } },
                            usageMetadata = { promptTokenCount = 1, candidatesTokenCount = 1, totalTokenCount = 2 } }
                    end }
                    local client_contract = { with_context = function(self) return self end,
                        open = function() return instance end }
                    handler._contract = { get = function() return client_contract end }
                    handler._ctx = { all = function() return {} end, get = function() return "client" end }
                end,
                check = function(payload)
                    test.eq(payload.generationConfig.thinkingConfig.thinkingBudget, 0)
                    test.eq(payload.generationConfig.temperature, 0.3)
                end
            },
        }

        for _, driver in ipairs(drivers) do
            for _, method in ipairs({ "generate", "structured_output" }) do
                local handler = driver[method]

                local function setup(request)
                    local sent: any = {}
                    driver.install(handler, sent)
                    local ref = { id = "route", provider_model = "wire",
                        options = { thinking_effort = 50, temperature = 1, request = request } }
                    for key, value in pairs(driver.accepts) do ref[key] = value end
                    local card = { name = "route-model", providers = { ref } }
                    llm._model_resolver = { resolve = function() return card end }
                    llm._providers = { driver_declares_legacy_reasoning_flag = function() return false end, driver_output_policy = function() return nil, nil end, open = function()
                        return { [method] = function(_, args) return handler.handler(args) end }
                    end }
                    return sent
                end

                it("merges route options.request into the " .. driver.name .. " " .. method .. " wire body after mapping", function()
                    local sent = setup(driver.request)
                    local _, err = call(method, { model = "route-model" })
                    test.is_nil(err)
                    driver.check(sent.payload :: table, method)
                end)

                it("rejects a " .. driver.name .. " " .. method .. " request setting a driver-owned key before HTTP", function()
                    local sent = setup({ [driver.reserved] = {} })
                    local result, err = call(method, { model = "route-model" })
                    test.is_nil(result)
                    test.eq(err:kind(), errors.INVALID)
                    test.eq(tostring(err), err:message())
                    test.contains(err:message(), driver.reserved)
                    test.is_nil(sent.payload)
                end)

                if driver.schema_path then
                    if method == "structured_output" then
                        it("rejects a " .. driver.name .. " structured_output request setting the schema field before HTTP", function()
                            local sent = setup(driver.schema_request)
                            local result, err = call(method, { model = "route-model" })
                            test.is_nil(result)
                            test.eq(err:kind(), errors.INVALID)
                            test.contains(err:message(), driver.schema_path)
                            test.is_nil(sent.payload)
                        end)
                    else
                        it("accepts the " .. driver.name .. " structured schema field on generate", function()
                            local sent = setup(driver.schema_request)
                            local _, err = call(method, { model = "route-model" })
                            test.is_nil(err)
                            local node: any = sent.payload
                            for segment in string.gmatch(driver.schema_path, "[^.]+") do node = node[segment] end
                            test.not_nil(node, driver.schema_path .. " reaches the wire")
                        end)
                    end
                end
            end
        end

        -- Binding decided after the options.request overlay, on a history that replays a thinking block.
        local BINDING_BETA = "thinking-binding-controls-2026-08-01"
        local replayed_history = {
            { role = "user", content = { { type = "text", text = "Plan" } } },
            { role = "assistant", content = { { type = "text", text = "Planned." } },
                metadata = { thinking_blocks = { { type = "thinking", thinking = "t", signature = "sig" } } } },
            { role = "user", content = { { type = "text", text = "Answer" } } }
        }

        for _, variant in ipairs({
            { provider = "claude", method = "generate" },
            { provider = "claude", method = "structured_output" },
            { provider = "claude", method = "structured_output", native = true },
            { provider = "bedrock", method = "generate" },
            { provider = "bedrock", method = "structured_output" },
        }) do
            local provider, method = variant.provider, variant.method
            local label = method .. (variant.native and " native" or "")
            do
                local handler = provider == "claude"
                    and (method == "generate" and claude_generate or claude_structured)
                    or (method == "generate" and bedrock_generate or bedrock_structured)

                -- Claude takes request fields at the top level; Bedrock under additionalModelRequestFields.
                local function wire(fields)
                    if provider == "claude" then return fields end
                    return { additionalModelRequestFields = fields }
                end

                local function send(thinking_fact, effort, request)
                    local sent: any = {}
                    local function respond(_, payload, options)
                        sent.payload = payload
                        sent.options = options or {}
                        if provider == "claude" then
                            return { content = { { type = "text", text = variant.native and answer or "ok" },
                                { type = "tool_use", name = "structured_output", id = "one", input = { answer = "ok" } } },
                                stop_reason = "end_turn", usage = { input_tokens = 1, output_tokens = 1 }, metadata = {} }
                        end
                        return { output = { message = { role = "assistant", content = { { text = "ok" },
                            { toolUse = { toolUseId = "one", name = "structured_output", input = { answer = "ok" } } } } } },
                            stopReason = "end_turn", usage = { inputTokens = 1, outputTokens = 1 }, metadata = {} }
                    end
                    handler._client = { ENDPOINTS = { MESSAGES = "/messages" }, request = respond, converse = respond }
                    local card = { name = "route-model", providers = { {
                        id = "route", provider_model = "wire", thinking = thinking_fact,
                        structured_output = variant.native and "native" or nil,
                        options = { thinking_effort = effort, request = request }
                    } } }
                    llm._model_resolver = { resolve = function() return card end }
                    llm._providers = { driver_declares_legacy_reasoning_flag = function() return false end, driver_output_policy = function() return nil, nil end, open = function()
                        return { [method] = function(_, args) return handler.handler(args) end }
                    end }
                    local _, err
                    if method == "generate" then
                        _, err = llm.generate(replayed_history, { model = "route-model" })
                    else
                        _, err = llm.structured_output(schema, replayed_history, { model = "route-model" })
                    end
                    test.is_nil(err)
                    local payload = sent.payload :: table
                    local fields = provider == "claude" and payload or payload.additionalModelRequestFields
                    local betas = provider == "claude" and sent.options.beta_features or fields.anthropic_beta
                    return fields, betas, payload.additionalModelResponseFieldPaths
                end

                local function has(list, value)
                    for _, item in ipairs(list or {}) do
                        if item == value then return true end
                    end
                    return false
                end

                it("binds nothing on " .. provider .. " " .. label .. " when options.request sets between_tools", function()
                    local fields, betas, paths = send("adaptive", 50, wire({ thinking = { type = "between_tools" } }))
                    test.eq(fields.thinking.type, "between_tools")
                    test.is_nil(fields.thinking.block_binding)
                    test.is_false(has(betas, BINDING_BETA))
                    test.is_nil(paths)
                end)

                it("keeps an options.request block_binding on " .. provider .. " " .. label .. " and sends the beta", function()
                    local fields, betas, paths = send("adaptive", 50,
                        wire({ thinking = { block_binding = { prefix_mismatch_behavior = "error" } } }))
                    test.eq(fields.thinking.type, "adaptive")
                    test.eq(fields.thinking.block_binding.prefix_mismatch_behavior, "error")
                    test.is_true(has(betas, BINDING_BETA))
                    if provider == "bedrock" then test.is_true(has(paths, "/input_transformations")) end
                end)

                it("merges options.request into an always route at effort 0 on " .. provider .. " " .. label .. " and binds", function()
                    local fields, betas = send("always", 0, wire({ output_config = { task_budget = { type = "tokens", total = 20000 } } }))
                    test.eq(fields.output_config.task_budget.total, 20000)
                    test.is_nil(fields.output_config.effort)
                    test.eq(fields.thinking.type, "adaptive")
                    test.eq(fields.thinking.block_binding.prefix_mismatch_behavior, "drop_block")
                    test.is_true(has(betas, BINDING_BETA))
                end)
            end
        end

        for _, case in ipairs({
            { driver = "google", request = { generationConfig = { response_schema = { type = "object" } } },
                field = "generationConfig.response_schema" },
            { driver = "google", request = { generationConfig = { responseJsonSchema = { type = "object" } } },
                field = "generationConfig.responseJsonSchema" },
            { driver = "openai", request = { text = "low" }, field = "text.format" },
        }) do
            it("rejects a " .. case.driver .. " structured_output request replacing " .. case.field, function()
                local driver
                for _, candidate in ipairs(drivers) do
                    if candidate.name == case.driver then driver = candidate end
                end
                local handler = driver.structured_output
                local sent: any = {}
                driver.install(handler, sent)
                local ref = { id = "route", provider_model = "wire", options = { request = case.request } }
                for key, value in pairs(driver.accepts) do ref[key] = value end
                local card = { name = "route-model", providers = { ref } }
                llm._model_resolver = { resolve = function() return card end }
                llm._providers = { driver_declares_legacy_reasoning_flag = function() return false end, driver_output_policy = function() return nil, nil end, open = function()
                    return { structured_output = function(_, args) return handler.handler(args) end }
                end }
                local result, err = call("structured_output", { model = "route-model" })
                test.is_nil(result)
                test.contains(err:message(), case.field)
                test.is_nil(sent.payload)
            end)
        end

        it("rejects an openai_compat request setting the usage flag the client owns", function()
            local driver
            for _, candidate in ipairs(drivers) do
                if candidate.name == "openai_compat" then driver = candidate end
            end
            local sent: any = {}
            driver.install(openai_compat_generate, sent)
            local card = { name = "route-model", providers = { { id = "route", provider_model = "wire",
                thinking = "adaptive", options = { request = { usage = { include = false } } } } } }
            llm._model_resolver = { resolve = function() return card end }
            llm._providers = { driver_declares_legacy_reasoning_flag = function() return false end, driver_output_policy = function() return nil, nil end, open = function()
                return { generate = function(_, args) return openai_compat_generate.handler(args) end }
            end }
            local result, err = call("generate", { model = "route-model" })
            test.is_nil(result)
            test.contains(err:message(), "usage")
            test.is_nil(sent.payload)
        end)

        for _, method in ipairs({ "generate", "structured_output" }) do
            it("returns an invalid request from Google " .. method .. " for declared thinking", function()
                local handler = method == "generate" and google_generate or google_structured
                llm._providers = { driver_declares_legacy_reasoning_flag = function() return false end, driver_output_policy = function() return nil, nil end, open = function()
                    return { [method] = function(_, args) return handler.handler(args) end }
                end }
                local result, err = call(method, { provider_id = "route", model = "wire", accepts = { thinking = "adaptive" } })
                test.is_nil(result)
                test.eq(err:kind(), errors.INVALID)
                test.eq(tostring(err), err:message())
                test.contains(err:message(), "Google")
                test.eq(err:kind(), errors.INVALID)
                test.eq(tostring(err), err:message())
                test.contains(err:message(), "adaptive")
            end)
        end

        describe("Prompt cache lifetime", function()
            local cached_prompt = {
                { role = "system", content = "Base instructions" },
                { role = "cache_marker" },
                { role = "user", content = { { type = "text", text = "Answer" } } },
                { role = "cache_marker", marker_id = "history_tail" }
            }

            local function driver_named(name)
                for _, candidate in ipairs(drivers) do
                    if candidate.name == name then return candidate end
                end
            end

            local function route_through(driver, method, route_options)
                local handler = driver[method]
                local sent: any = {}
                driver.install(handler, sent)
                local ref = { id = "route", provider_model = "wire", options = route_options }
                for key, value in pairs(driver.accepts) do ref[key] = value end
                local card = { name = "route-model", providers = { ref } }
                llm._model_resolver = { resolve = function() return card end }
                llm._providers = { driver_declares_legacy_reasoning_flag = function() return false end, driver_output_policy = function() return nil, nil end, open = function()
                    return { [method] = function(_, args) return handler.handler(args) end }
                end }
                return sent
            end

            local function cached_call(method, options)
                if method == "generate" then return llm.generate(cached_prompt, options) end
                return llm.structured_output(schema, cached_prompt, options)
            end

            local function lifetimes(payload)
                local found = {}
                for _, block in ipairs(payload.system or {}) do
                    if block.cache_control then found[#found + 1] = block.cache_control.ttl or "5m" end
                end
                for _, message in ipairs(payload.messages or {}) do
                    for _, block in ipairs(message.content or {}) do
                        if type(block) == "table" and block.cache_control then
                            found[#found + 1] = block.cache_control.ttl or "5m"
                        end
                    end
                end
                return table.concat(found, ",")
            end

            local function mentions(value, key)
                if type(value) ~= "table" then return false end
                for item_key, item in pairs(value) do
                    if item_key == key or mentions(item, key) then return true end
                end
                return false
            end

            for _, method in ipairs({ "generate", "structured_output" }) do
                it("applies the route's cache lifetime to every Claude " .. method .. " breakpoint", function()
                    local sent = route_through(driver_named("claude"), method, { cache_ttl = "1h" })
                    local _, err = cached_call(method, { model = "route-model" })
                    test.is_nil(err)
                    test.eq(lifetimes(sent.payload), "1h,1h")
                    test.is_true(not mentions(sent.payload, "cache_ttl"))
                end)

                it("lets the caller's cache lifetime replace the route's on Claude " .. method, function()
                    local sent = route_through(driver_named("claude"), method, { cache_ttl = "1h" })
                    local _, err = cached_call(method, { model = "route-model", cache_ttl = "5m" })
                    test.is_nil(err)
                    test.eq(lifetimes(sent.payload), "5m,5m")
                end)

                it("rejects a lifetime Claude does not offer on " .. method .. " before HTTP", function()
                    for _, value in ipairs({ "50m", "12h" }) do
                        local sent = route_through(driver_named("claude"), method, nil)
                        local result, err = cached_call(method, { model = "route-model", cache_ttl = value })
                        test.is_nil(result)
                        test.eq(err:kind(), errors.INVALID)
                        test.contains(err:message(), "cache_ttl")
                        test.contains(err:message(), value)
                        test.is_nil(sent.payload)
                    end
                end)
            end

            for _, method in ipairs({ "generate", "structured_output" }) do
                it("applies the route's cache lifetime on the native Claude " .. method .. " route", function()
                    local sent = route_through(driver_named("claude native"), method, { cache_ttl = "1h" })
                    local _, err = cached_call(method, { model = "route-model" })
                    test.is_nil(err)
                    test.eq(lifetimes(sent.payload), "1h,1h")
                end)

                it("applies a direct call's cache lifetime on Claude " .. method, function()
                    local sent = route_through(driver_named("claude"), method, nil)
                    local _, err = cached_call(method, { provider_id = "route", model = "wire", cache_ttl = "1h" })
                    test.is_nil(err)
                    test.eq(lifetimes(sent.payload), "1h,1h")
                end)

                it("rejects an unsupported cache lifetime on a direct " .. method .. " call before HTTP", function()
                    local sent = route_through(driver_named("claude"), method, nil)
                    local result, err = cached_call(method, { provider_id = "route", model = "wire", cache_ttl = "50m" })
                    test.is_nil(result)
                    test.eq(err:kind(), errors.INVALID)
                    test.contains(err:message(), "cache_ttl")
                    test.is_nil(sent.payload)
                end)
            end

            for _, name in ipairs({ "claude", "openai" }) do
                it("rejects a route cache lifetime that is not a string on the " .. name .. " route before HTTP", function()
                    local sent = route_through(driver_named(name), "generate", { cache_ttl = 60 })
                    local result, err = cached_call("generate", { model = "route-model" })
                    test.is_nil(result)
                    test.eq(err:kind(), errors.INVALID)
                    test.contains(err:message(), "cache_ttl")
                    test.is_nil(sent.payload)
                end)
            end

            for _, name in ipairs({ "bedrock", "openai", "openai_compat", "google" }) do
                it("passes a lifetime it does not use on the " .. name .. " route and keeps it off the wire", function()
                    local sent = route_through(driver_named(name), "generate", { cache_ttl = "12h" })
                    local _, err = cached_call("generate", { model = "route-model" })
                    test.is_nil(err)
                    test.not_nil(sent.payload)
                    test.is_true(not mentions(sent.payload, "cache_ttl"))
                end)
            end
        end)
    end)
end

return test.run_cases(define_tests)
