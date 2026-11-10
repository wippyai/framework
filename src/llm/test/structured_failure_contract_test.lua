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
local function success(name, reply, reason, metadata, aliases, google_tokens)
    local tokens = { prompt_tokens = 120, completion_tokens = 64, total_tokens = 184,
        cache_write_tokens = 0, cache_read_tokens = 0 }
    if not google_tokens then tokens.thinking_tokens = 0 end
    if aliases then
        tokens.cache_creation_input_tokens = 0
        tokens.cache_read_input_tokens = 0
    end
    return { name = name, reply = reply, data = { answer = "ok" },
        tokens = tokens, reason = reason, metadata = metadata or { request_id = "kept" } }
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
            success("truncated parseable JSON", compat_reply(valid, "length"), "length", nil, true),
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
            success("truncated parseable JSON", openai_reply(valid, "length"), "length", { request_id = "kept", response_id = "reply" }, true),
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
            success("truncated parseable tool input", claude_reply({ { type = "tool_use", name = "structured_output", input = { answer = "ok" } } }, "max_tokens"), "stop", nil, true),
            failure("refusal", claude_reply({ { type = "text", text = "Declined" } }, "refusal"), "Unavailable", missing_tool, {}, "refusal"),
            failure("non-JSON", claude_reply({ { type = "text", text = "not json" } }, "end_turn"), "Unavailable", missing_tool, {}, "stop"),
            failure("missing content", claude_reply(nil, "end_turn"), "Unavailable", "Invalid response structure from Claude", { request_id = "kept" }, "stop"),
            transport(),
        } },
        { name = "claude native", handler = claude, native = true, cases = {
            failure("truncated malformed JSON", claude_reply({ { type = "text", text = partial } }, "max_tokens"), "NotFound", claude_truncated, {}, "length"),
            failure("truncated missing content", claude_reply({}, "max_tokens"), "NotFound", claude_truncated, {}, "length"),
            failure("truncated parseable JSON", claude_reply({ { type = "text", text = valid } }, "max_tokens"), "NotFound", claude_truncated, {}, "length"),
            success("parseable JSON", claude_reply({ { type = "text", text = valid } }, "end_turn"), "stop", nil, true),
            failure("refusal", claude_reply({}, "refusal"), "Invalid", "Claude declined the structured output request (stop_reason refusal)", {}, "refusal"),
            failure("non-JSON", claude_reply({ { type = "text", text = "not json" } }, "end_turn"), "NotFound", native_invalid("not json"), {}, "stop"),
            failure("missing content", claude_reply(nil, "end_turn"), "Unavailable", "Invalid response structure from Claude", { request_id = "kept" }, "stop"),
            transport(),
        } },
        { name = "bedrock", handler = bedrock, cases = {
            failure("truncated malformed JSON", bedrock_reply({ { text = partial } }, "max_tokens"), "Unavailable", bedrock_missing, { request_id = "kept" }, "length"),
            failure("truncated missing tool", bedrock_reply({}, "max_tokens"), "Unavailable", bedrock_missing, { request_id = "kept" }, "length"),
            success("truncated parseable tool input", bedrock_reply({ { toolUse = { name = "structured_output", input = { answer = "ok" } } } }, "max_tokens"), "stop"),
            failure("refusal", bedrock_reply({}, "content_filtered"), "Unavailable", bedrock_missing, { request_id = "kept" }, "filtered"),
            failure("non-JSON", bedrock_reply({ { text = "not json" } }, "end_turn"), "Unavailable", bedrock_missing, { request_id = "kept" }, "stop"),
            failure("missing content", bedrock_reply(nil, "end_turn"), "Unavailable", bedrock_missing, { request_id = "kept" }, "stop"),
            transport(),
        } },
        { name = "google", handler = google, cases = {
            failure("truncated malformed JSON", google_reply(partial, "MAX_TOKENS"), "NotFound", json_message(partial), {}, "length"),
            failure("truncated missing content", google_reply(nil, "MAX_TOKENS"), "NotFound", json_message(""), {}, "length"),
            success("truncated parseable JSON", google_reply(valid, "MAX_TOKENS"), "length", nil, false, true),
            failure("refusal", google_reply(nil, "SAFETY"), "NotFound", json_message(""), {}, "filtered"),
            failure("non-JSON", google_reply("not json", "STOP"), "NotFound", json_message("not json"), {}, "stop"),
            failure("missing content", google_reply(nil, "STOP"), "NotFound", json_message(""), {}, "stop"),
            transport(),
            failure("prompt blocked without candidates", {
                status_code = 200, promptFeedback = { blockReason = "SAFETY" },
                usageMetadata = { promptTokenCount = 120, candidatesTokenCount = 64 },
            }, "Unavailable", "wippy.llm.google:mapper:395: Invalid Google response structure", { status_code = 500 }),
        } },
    }
end

local function malformed_cases(driver)
    local cases: {any} = {}
    for _, value in ipairs({ true, "invalid", 7, {} }) do
        local reply, kind, message, details, reason
        if driver.name == "openai_compat" then
            reply, kind, message, details, reason = compat_reply(nil, "length"), "Unavailable", "No content in OpenAI response", {}, "length"
        elseif driver.name == "openai" then
            reply, kind, message, details, reason = openai_reply(nil, "length"), "Unavailable", "No content in Responses API response", { response_id = "reply" }, "length"
        elseif driver.name == "google" then
            reply, kind, message, details, reason = google_reply(nil, "MAX_TOKENS"), "NotFound", json_message(""), {}, "length"
        elseif driver.name == "bedrock" then
            reply, kind, message, details, reason = bedrock_reply(nil, "max_tokens"), "Unavailable", "Model failed to use the structured_output tool", { request_id = "kept" }, "length"
        else
            reply, kind, message, details, reason = claude_reply(nil, "max_tokens"), "Unavailable", "Invalid response structure from Claude", { request_id = "kept" }, "length"
        end
        local finish_reply = {}
        for key, field in pairs(reply) do finish_reply[key] = field end
        if driver.name == "openai_compat" then
            finish_reply.choices = { { message = {}, finish_reason = value } }
        elseif driver.name == "openai" then
            finish_reply.status = value
        elseif driver.name == "google" then
            finish_reply.candidates = { { content = { parts = {} }, finishReason = value } }
        elseif driver.name == "bedrock" then
            finish_reply.stopReason = value
        else
            finish_reply.stop_reason = value
        end
        if type(value) ~= "string" then
            cases[#cases + 1] = failure("malformed finish reason " .. type(value), finish_reply, kind, message, details)
        end
        if type(value) ~= "table" then
            local usage_key = driver.name == "google" and "usageMetadata" or "usage"
            reply[usage_key] = value
            if driver.name == "google" then
                reply.candidates = nil
                kind, message, details, reason = "Unavailable", "wippy.llm.google:mapper:395: Invalid Google response structure", { status_code = 500 }, nil
            end
            local case = failure("malformed usage " .. type(value), reply, kind, message, details, reason)
            case.no_tokens = true
            cases[#cases + 1] = case
        end
    end
    local fields = {
        openai_compat = { "prompt_tokens", "prompt_tokens_details", "completion_tokens_details" },
        openai = { "input_tokens", "input_tokens_details", "output_tokens_details" },
        ["claude tool"] = { "input_tokens" }, ["claude native"] = { "input_tokens" },
        bedrock = { "inputTokens" }, google = { "promptTokenCount" },
    }
    local template = cases[2]
    for _, field in ipairs(fields[driver.name]) do
        local reply = {}
        for key, value in pairs(template.reply) do reply[key] = value end
        reply[driver.name == "google" and "usageMetadata" or "usage"] = { [field] = true }
        local case = failure("malformed usage field " .. field, reply, template.kind, template.message, template.details, template.reason)
        case.no_tokens = true
        cases[#cases + 1] = case
    end
    return cases
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
            for _, case in ipairs(malformed_cases(driver)) do driver.cases[#driver.cases + 1] = case end
            describe(driver.name, function()
                for _, case in ipairs(driver.cases) do
                    it(case.name, function()
                        local result, err = invoke(driver, case)
                        if case.data then
                            test.is_nil(err)
                            test.is_true(result.success)
                            same(result.result.data, case.data, "data")
                            same(result.tokens, case.tokens, "tokens")
                            test.eq(result.finish_reason, case.reason)
                            same(result.metadata, case.metadata, "metadata")
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
                            if case.reply and not case.no_tokens then
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
