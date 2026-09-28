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
                    llm._providers = { open = function()
                        return { [method] = function(_, args) return handler.handler(args) end }
                    end }
                    return sent
                end

                it("merges " .. provider .. " " .. method .. " budget adjustments", function()
                    local sent = setup()
                    local result, err = call(method, { provider_id = "route", model = "wire",
                        accepts = { thinking = "budget" }, thinking_effort = 50, temperature = 0.4 })
                    test.is_nil(err)
                    test.not_nil(sent.payload)
                    test.eq(result.metadata.adjusted.temperature.requested, 0.4)
                    test.eq(result.metadata.adjusted.temperature.sent, 1)
                    test.eq(result.metadata.request_id, "kept")
                end)

                it("rejects strict " .. provider .. " " .. method .. " budget changes before HTTP", function()
                    local sent = setup()
                    local result, err = call(method, { provider_id = "route", model = "wire",
                        accepts = { thinking = "budget" }, thinking_effort = 50, temperature = 0.4, strict = true })
                    test.is_nil(result)
                    test.contains(err, "invalid_request")
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

        for _, method in ipairs({ "generate", "structured_output" }) do
            it("returns an invalid request from Google " .. method .. " for declared thinking", function()
                local handler = method == "generate" and google_generate or google_structured
                llm._providers = { open = function()
                    return { [method] = function(_, args) return handler.handler(args) end }
                end }
                local result, err = call(method, { provider_id = "route", model = "wire", accepts = { thinking = "adaptive" } })
                test.is_nil(result)
                test.contains(err, "invalid_request")
                test.contains(err, "adaptive")
            end)
        end
    end)
end

return test.run_cases(define_tests)
