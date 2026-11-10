local test = require("test")
local json = require("json")
local compat = require("compat_structured")
local openai = require("openai_structured")
local claude = require("claude_structured")
local bedrock = require("bedrock_structured")
local google = require("google_structured")

local function same(actual, expected, path)
    if type(expected) ~= "table" then
        test.eq(actual, expected, path)
        return
    end
    test.eq(type(actual), "table", path)
    for key, value in pairs(expected) do same(actual[key], value, path .. "." .. tostring(key)) end
    for key in pairs(actual) do test.not_nil(expected[key], path .. "." .. tostring(key)) end
end

local partial = '{"answer":"partial'
local valid = '{"answer":"ok"}'
local function json_message(text)
    local _, err = json.decode(text)
    return "Model failed to return valid JSON: " .. err
end

local function failure(name, reply, kind, message, details, reason)
    return { name = name, reply = reply, kind = kind, retryable = kind == "Unavailable",
        message = message, details = details or {}, reason = reason }
end
local function success(name, reply)
    return { name = name, reply = reply, data = { answer = "ok" } }
end
local function transport()
    return failure("transport failure", nil, "Unavailable", "Connection refused", { request_id = "kept" })
end

local function compat_reply(content, reason, refusal)
    return { choices = { { message = { content = content, refusal = refusal }, finish_reason = reason } },
        usage = { prompt_tokens = 120, completion_tokens = 64, total_tokens = 184 }, metadata = { request_id = "kept" } }
end
local function openai_reply(text, reason, refusal)
    return { id = "reply", status = reason == "length" and "incomplete" or "completed",
        incomplete_details = reason == "length" and { reason = "max_output_tokens" } or nil,
        output = { { type = "message", role = "assistant", content = {
            refusal and { type = "refusal", refusal = refusal } or { type = "output_text", text = text }
        } } }, usage = { input_tokens = 120, output_tokens = 64, total_tokens = 184 },
        metadata = { request_id = "kept" } }
end
local function claude_reply(content, reason)
    return { content = content, stop_reason = reason, usage = { input_tokens = 120, output_tokens = 64 },
        metadata = { request_id = "kept" } }
end
local function bedrock_reply(content, reason)
    return { output = { message = { role = "assistant", content = content } }, stopReason = reason,
        usage = { inputTokens = 120, outputTokens = 64 }, metadata = { request_id = "kept" } }
end
local function google_reply(text, reason)
    return { status_code = 200, candidates = { { content = { parts = { { text = text } } }, finishReason = reason } },
        usageMetadata = { promptTokenCount = 120, candidatesTokenCount = 64, totalTokenCount = 184 },
        metadata = { request_id = "kept" } }
end

local function drivers()
    local missing_tool = "Claude failed to use the structured_output tool"
    local bedrock_missing = "Model failed to use the structured_output tool"
    local claude_truncated = "Structured output was truncated (stop_reason max_tokens)"
    local function native_invalid(text)
        local _, err = json.decode(text)
        return "Structured output is not a JSON object: " .. err
    end
    return {
        { name = "openai_compat", handler = compat, cases = {
            failure("truncated malformed JSON", compat_reply(partial, "length"), "NotFound", json_message(partial), { raw_content = partial }, "length"),
            failure("truncated missing content", compat_reply(nil, "length"), "Unavailable", "No content in OpenAI response", {}, "length"),
            success("truncated parseable JSON", compat_reply(valid, "length")),
            failure("refusal", compat_reply(nil, "stop", "Declined"), "Invalid", "Request was refused: Declined", { refusal = "Declined" }, "stop"),
            failure("non-JSON", compat_reply("not json", "stop"), "NotFound", json_message("not json"), { raw_content = "not json" }, "stop"),
            failure("missing content", compat_reply(nil, "stop"), "Unavailable", "No content in OpenAI response", {}, "stop"),
            failure("missing choices", { usage = { prompt_tokens = 120, completion_tokens = 64 }, metadata = { request_id = "kept" } },
                "Unavailable", "Invalid response structure from OpenAI", { request_id = "kept" }),
            failure("missing message", { choices = { { finish_reason = "length" } }, usage = { prompt_tokens = 120, completion_tokens = 64 } },
                "Unavailable", "Invalid choice structure in OpenAI response", {}, "length"),
            transport(),
        } },
        { name = "openai", handler = openai, cases = {
            failure("truncated malformed JSON", openai_reply(partial, "length"), "NotFound", json_message(partial), { response_id = "reply", raw_content = partial }, "length"),
            failure("truncated missing content", openai_reply(nil, "length"), "Unavailable", "No content in Responses API response", { response_id = "reply" }, "length"),
            success("truncated parseable JSON", openai_reply(valid, "length")),
            failure("refusal", openai_reply(nil, "stop", "Declined"), "Invalid", "Request was refused: Declined", { response_id = "reply", refusal = "Declined" }, "stop"),
            failure("non-JSON", openai_reply("not json", "stop"), "NotFound", json_message("not json"), { response_id = "reply", raw_content = "not json" }, "stop"),
            failure("missing content", openai_reply(nil, "stop"), "Unavailable", "No content in Responses API response", { response_id = "reply" }, "stop"),
            failure("missing output", { status = "completed", usage = { input_tokens = 120, output_tokens = 64 }, metadata = { request_id = "kept" } },
                "Unavailable", "Invalid response structure from OpenAI Responses API", { request_id = "kept" }, "stop"),
            transport(),
        } },
        { name = "claude tool", handler = claude, cases = {
            failure("truncated malformed JSON", claude_reply({ { type = "text", text = partial } }, "max_tokens"), "Unavailable", missing_tool, {}, "length"),
            failure("truncated missing tool", claude_reply({}, "max_tokens"), "Unavailable", missing_tool, {}, "length"),
            failure("truncated missing input", claude_reply({ { type = "tool_use", name = "structured_output" } }, "max_tokens"),
                "Unavailable", "Tool use block does not contain input", {}, "length"),
            success("truncated parseable tool input", claude_reply({ { type = "tool_use", name = "structured_output", input = { answer = "ok" } } }, "max_tokens")),
            failure("refusal", claude_reply({ { type = "text", text = "Declined" } }, "refusal"), "Unavailable", missing_tool, {}, "refusal"),
            failure("non-JSON", claude_reply({ { type = "text", text = "not json" } }, "end_turn"), "Unavailable", missing_tool, {}, "stop"),
            failure("missing content", claude_reply(nil, "end_turn"), "Unavailable", "Invalid response structure from Claude", { request_id = "kept" }, "stop"),
            transport(),
        } },
        { name = "claude native", handler = claude, native = true, cases = {
            failure("truncated malformed JSON", claude_reply({ { type = "text", text = partial } }, "max_tokens"), "NotFound", claude_truncated, {}, "length"),
            failure("truncated missing content", claude_reply({}, "max_tokens"), "NotFound", claude_truncated, {}, "length"),
            failure("truncated parseable JSON", claude_reply({ { type = "text", text = valid } }, "max_tokens"), "NotFound", claude_truncated, {}, "length"),
            failure("refusal", claude_reply({}, "refusal"), "Invalid", "Claude declined the structured output request (stop_reason refusal)", {}, "refusal"),
            failure("non-JSON", claude_reply({ { type = "text", text = "not json" } }, "end_turn"), "NotFound", native_invalid("not json"), {}, "stop"),
            failure("missing content", claude_reply(nil, "end_turn"), "Unavailable", "Invalid response structure from Claude", { request_id = "kept" }, "stop"),
            transport(),
        } },
        { name = "bedrock", handler = bedrock, cases = {
            failure("truncated malformed JSON", bedrock_reply({ { text = partial } }, "max_tokens"), "Unavailable", bedrock_missing, { request_id = "kept" }, "length"),
            failure("truncated missing tool", bedrock_reply({}, "max_tokens"), "Unavailable", bedrock_missing, { request_id = "kept" }, "length"),
            success("truncated parseable tool input", bedrock_reply({ { toolUse = { name = "structured_output", input = { answer = "ok" } } } }, "max_tokens")),
            failure("refusal", bedrock_reply({}, "content_filtered"), "Unavailable", bedrock_missing, { request_id = "kept" }, "filtered"),
            failure("non-JSON", bedrock_reply({ { text = "not json" } }, "end_turn"), "Unavailable", bedrock_missing, { request_id = "kept" }, "stop"),
            failure("missing content", bedrock_reply(nil, "end_turn"), "Unavailable", bedrock_missing, { request_id = "kept" }, "stop"),
            transport(),
        } },
        { name = "google", handler = google, cases = {
            failure("truncated malformed JSON", google_reply(partial, "MAX_TOKENS"), "NotFound", json_message(partial), {}, "length"),
            failure("truncated missing content", google_reply(nil, "MAX_TOKENS"), "NotFound", json_message(""), {}, "length"),
            success("truncated parseable JSON", google_reply(valid, "MAX_TOKENS")),
            failure("refusal", google_reply(nil, "SAFETY"), "NotFound", json_message(""), {}, "filtered"),
            failure("non-JSON", google_reply("not json", "STOP"), "NotFound", json_message("not json"), {}, "stop"),
            failure("missing content", google_reply(nil, "STOP"), "NotFound", json_message(""), {}, "stop"),
            transport(),
            failure("prompt blocked without candidates", {
                status_code = 200, promptFeedback = { blockReason = "SAFETY" },
                usageMetadata = { promptTokenCount = 120, candidatesTokenCount = 64 },
            }, "Unavailable", (function()
                local _, err = pcall(google._mapper.map_success_response, { candidates = {} })
                return tostring(err)
            end)(), { status_code = 500 }),
        } },
    }
end

local function invoke(driver, case)
    local handler = driver.handler
    local saved_client, saved_contract, saved_ctx = handler._client, handler._contract, handler._ctx
    local transport_error = { message = "Connection refused", metadata = { request_id = "kept" } }
    if driver.name == "google" then
        handler._ctx = { all = function() return {} end, get = function() return "client" end }
        handler._contract = { get = function()
            return { with_context = function(self) return self end, open = function()
                return { request = function() return case.reply or {
                    status_code = 0, message = transport_error.message, metadata = transport_error.metadata
                } end }
            end }
        end }
    else
        local function request() return case.reply, not case.reply and transport_error or nil end
        handler._client = { request = request, converse = request, ENDPOINTS = { MESSAGES = "/messages" } }
    end
    local ok, result, err = pcall(handler.handler, {
        model = "test-model", _provider_id = "test-provider",
        messages = { { role = "user", content = { { type = "text", text = "Answer" } } } },
        schema = { type = "object", properties = { answer = { type = "string" } }, required = { "answer" }, additionalProperties = false },
        accepts = driver.native and { structured_output = "native" } or nil,
    })
    handler._client, handler._contract, handler._ctx = saved_client, saved_contract, saved_ctx
    test.is_true(ok, tostring(result))
    return result, err
end

local function define_tests()
    describe("Structured failure contract", function()
        for _, driver in ipairs(drivers()) do
            describe(driver.name, function()
                for _, case in ipairs(driver.cases) do
                    it(case.name, function()
                        local result, err = invoke(driver, case)
                        if case.data then
                            test.is_nil(err)
                            test.is_true(result.success)
                            same(result.result.data, case.data, "data")
                            return
                        end
                        test.is_nil(result)
                        test.eq(err:kind(), case.kind)
                        test.eq(err:retryable(), case.retryable)
                        test.eq(err:message(), case.message)
                        local expected = { operation = "structured_output", provider = "test-provider", model = "test-model",
                            error_type = case.kind == "NotFound" and "model_error" or case.kind == "Invalid" and "content_filtered" or "server_error" }
                        for key, value in pairs(case.details) do expected[key] = value end
                        if not case.reply and (driver.name == "google" or driver.name == "openai" or driver.name == "openai_compat") then
                            expected.error_type = "network_error"
                        end
                        if driver.name == "google" and not case.reply then expected.status_code = 0 end
                        local existing = {}
                        for key, value in pairs(err:details()) do
                            if key ~= "tokens" and key ~= "finish_reason" then existing[key] = value end
                        end
                        same(existing, expected, "details")
                    end)
                    if not case.data then
                        it(case.name .. " reply metadata", function()
                            local _, err = invoke(driver, case)
                            test.eq(err:details().finish_reason, case.reason)
                            if case.reply then
                                test.eq(err:details().tokens.prompt_tokens, 120)
                                test.eq(err:details().tokens.completion_tokens, 64)
                            else
                                test.is_nil(err:details().tokens)
                            end
                        end)
                    end
                end
            end)
        end
    end)
end

return test.run_cases(define_tests)
