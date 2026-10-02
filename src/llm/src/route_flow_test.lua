local test = require("test")
local llm = require("llm")
local claude_generate = require("claude_generate")
local claude_structured = require("claude_structured")
local bedrock_generate = require("bedrock_generate")
local bedrock_structured = require("bedrock_structured")
local google_generate = require("google_generate")
local google_structured = require("google_structured")

local function define_tests()
    describe("Route facts through drivers", function()
        local saved_providers, saved_tracker
        local saved_clients = {}

        before_each(function()
            saved_providers = llm._providers
            saved_tracker = llm._usage_tracker
            llm._usage_tracker = false
            for _, handler in ipairs({ claude_generate, claude_structured, bedrock_generate, bedrock_structured }) do
                saved_clients[handler] = handler._client
            end
        end)

        after_each(function()
            llm._providers = saved_providers
            llm._usage_tracker = saved_tracker
            for handler, client in pairs(saved_clients) do handler._client = client end
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
                    llm._providers = { driver_declares_legacy_reasoning_flag = function() return false end, open = function()
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
                    test.contains(err, "temperature")
                    test.is_nil(sent.payload)
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
                llm._providers = { driver_declares_legacy_reasoning_flag = function() return false end, open = function()
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
                test.contains(err, "forced_tool_choice")
                test.is_nil(sent.payload)
            end)
        end

        for _, method in ipairs({ "generate", "structured_output" }) do
            it("returns an invalid request from Google " .. method .. " for declared thinking", function()
                local handler = method == "generate" and google_generate or google_structured
                llm._providers = { driver_declares_legacy_reasoning_flag = function() return false end, open = function()
                    return { [method] = function(_, args) return handler.handler(args) end }
                end }
                local result, err = call(method, { provider_id = "route", model = "wire", accepts = { thinking = "adaptive" } })
                test.is_nil(result)
                test.contains(err, "Google")
                test.contains(err, "adaptive")
            end)
        end
    end)
end

return test.run_cases(define_tests)
