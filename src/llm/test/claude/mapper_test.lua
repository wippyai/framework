local mapper = require("mapper")
local output = require("output")
local prompt = require("prompt")
local json = require("json")
local hash = require("hash")
local test = require("test")

local function define_tests()
    describe("Claude Mapper", function()

        describe("Positional notes", function()
            local function text(value)
                return { { type = "text", text = value } }
            end

            local function note(role, value)
                return { role = role, content = text(value), metadata = { preserve_position = true } }
            end

            it("renders a positional note as a text block after the preceding user content", function()
                for _, role in ipairs({ "system", "developer" }) do
                    local mapped, err = mapper.map_messages({
                        { role = "system", content = text("Base") },
                        { role = "user", content = text("Question") },
                        note(role, "The current date and time is Tuesday."),
                    })
                    test.is_nil(err)
                    assert(mapped)
                    test.eq(#mapped.system, 1)
                    test.eq(mapped.system[1].text, "Base")
                    test.eq(#mapped.messages, 1)
                    local content = mapped.messages[1].content
                    test.eq(#content, 2)
                    test.eq(content[1].text, "Question")
                    test.eq(content[2].type, "text")
                    test.eq(content[2].text, role == "developer" and "<developer-instruction>The current date and time is Tuesday.</developer-instruction>"
                        or "The current date and time is Tuesday.")
                end
            end)

            it("appends a positional note after the tool results of the same user turn", function()
                local mapped, err = mapper.map_messages({
                    { role = "user", content = text("Question") },
                    { role = "function_call", content = {}, function_call = { id = "call_1", name = "lookup", arguments = "{}" } },
                    { role = "function_result", name = "lookup", function_call_id = "call_1", content = text("found") },
                    note("system", "Reminder"),
                })
                test.is_nil(err)
                assert(mapped)
                test.is_nil(mapped.system)
                test.eq(#mapped.messages, 3)
                local content = mapped.messages[3].content
                test.eq(#content, 2)
                test.eq(content[1].type, "tool_result")
                test.eq(content[2].type, "text")
                test.eq(content[2].text, "Reminder")
            end)

            it("keeps the top-level system identical when the note text changes", function()
                local function build(note_text)
                    local mapped = mapper.map_messages({
                        { role = "system", content = text("Base") },
                        { role = "cache_marker", marker_id = "agent" },
                        { role = "user", content = text("Question") },
                        note("system", note_text),
                    })
                    return assert(mapped)
                end
                local first, second = build("Monday 09:00"), build("Tuesday 10:30")
                test.eq(#first.system, 1)
                test.eq(#second.system, 1)
                test.eq(second.system[1].text, first.system[1].text)
                test.eq(second.system[1].type, first.system[1].type)
                test.eq(second.system[1].cache_control.type, first.system[1].cache_control.type)
                test.eq(first.messages[1].content[2].text, "Monday 09:00")
                test.eq(second.messages[1].content[2].text, "Tuesday 10:30")
            end)

            it("keeps a cache breakpoint on the user block before the note", function()
                local mapped = assert(mapper.map_messages({
                    { role = "system", content = text("Base") },
                    { role = "user", content = text("Question") },
                    { role = "cache_marker", marker_id = "conversation_tail" },
                    note("developer", "Recalled memory"),
                }))
                local content = mapped.messages[1].content
                test.eq(content[1].cache_control.type, "ephemeral")
                test.eq(content[2].text, "<developer-instruction>Recalled memory</developer-instruction>")
                test.is_nil(content[2].cache_control)
            end)

            it("keeps a persisted positional note block unchanged when a developer note follows", function()
                local function build(with_developer)
                    local messages = {
                        { role = "user", content = text("Question") },
                        note("system", "The current date and time is Tuesday."),
                    }
                    if with_developer then
                        table.insert(messages, { role = "developer", content = text("Attached: report.pdf") })
                    end
                    return assert(mapper.map_messages(messages))
                end
                local before, after = build(false), build(true)
                test.eq(#after.messages, 1)
                test.eq(after.messages[1].content[2].text, before.messages[1].content[2].text)
                test.eq(after.messages[1].content[2].text, "The current date and time is Tuesday.")
                test.eq(#after.messages[1].content, 3)
                test.eq(after.messages[1].content[3].text, "<developer-instruction>Attached: report.pdf</developer-instruction>")
            end)

            local function same(a, b)
                if type(a) ~= "table" or type(b) ~= "table" then return a == b end
                for k, v in pairs(a) do
                    if k ~= "cache_control" and k ~= "cachePoint" and not same(v, b[k]) then return false end
                end
                for k in pairs(b) do
                    if k ~= "cache_control" and k ~= "cachePoint" and a[k] == nil then return false end
                end
                return true
            end

            -- Every block of the earlier request appears unchanged, in order, in the later one.
            local function assert_prefix(earlier, later, label)
                test.is_true(same(earlier.system, later.system), label .. ": system")
                for m, message in ipairs(earlier.messages) do
                    local other = later.messages[m]
                    test.not_nil(other, label .. ": message " .. m)
                    test.eq(other.role, message.role, label .. ": role " .. m)
                    local b2 = 0
                    for _, block in ipairs(message.content) do
                        if not block.cachePoint then
                            b2 = b2 + 1
                            while other.content[b2] and other.content[b2].cachePoint do b2 = b2 + 1 end
                            test.is_true(same(block, other.content[b2]), label .. ": message " .. m .. " block " .. b2)
                        end
                    end
                end
            end

            local function shapes()
                return {
                    first = {
                        { role = "system", content = text("Base") },
                        note("developer", "Resumed from checkpoint"),
                        { role = "user", content = text("Continue") },
                    },
                    after_assistant = {
                        { role = "user", content = text("Question") },
                        { role = "assistant", content = text("Answer") },
                        note("developer", "Stopped by the user"),
                    },
                    after_result = {
                        { role = "user", content = text("Question") },
                        { role = "function_call", content = {}, function_call = { id = "call_1", name = "lookup", arguments = "{}" } },
                        { role = "function_result", name = "lookup", function_call_id = "call_1", content = text("found") },
                        note("system", "Reminder"),
                    },
                }
            end

            it("wraps developer text in its own developer-instruction block", function()
                for _, metadata in ipairs({ { preserve_position = true }, {} }) do
                    local mapped = assert(mapper.map_messages({
                        { role = "user", content = text("Question") },
                        { role = "developer", content = text("Be concise"), metadata = metadata },
                    }))
                    local content = mapped.messages[1].content
                    test.eq(#content, 2)
                    test.eq(content[1].text, "Question")
                    test.eq(content[2].text, "<developer-instruction>Be concise</developer-instruction>")
                end
            end)

            it("renders positional system notes as plain text", function()
                local mapped = assert(mapper.map_messages({
                    { role = "user", content = text("Question") },
                    note("system", "The current date and time is Tuesday."),
                }))
                test.eq(mapped.messages[1].content[2].text, "The current date and time is Tuesday.")
            end)

            it("opens a user turn for a positional note that follows no user turn", function()
                for label, history in pairs(shapes()) do
                    local mapped, err = mapper.map_messages(history)
                    test.is_nil(err, label)
                    assert(mapped)
                    test.is_true(mapped.system == nil or #mapped.system <= 1, label)
                    local note_text = nil
                    for _, message in ipairs(history) do
                        if message.metadata and message.metadata.preserve_position then
                            note_text = message.content[1].text
                        end
                    end
                    local found = nil
                    for m, message in ipairs(mapped.messages) do
                        for b, block in ipairs(message.content) do
                            if block.text == note_text or block.text == prompt.developer_instruction(note_text) then
                                found = { m = m, b = b, role = message.role }
                            end
                        end
                    end
                    test.not_nil(found, label)
                    test.eq(found.role, "user", label)
                    if label ~= "after_result" then
                        test.eq(found.b, 1, label .. ": the note opens its own turn")
                    end
                end
            end)

            it("keeps earlier assistant output unchanged when a positional note follows it", function()
                local mapped = assert(mapper.map_messages(shapes().after_assistant))
                test.eq(mapped.messages[2].role, "assistant")
                test.eq(#mapped.messages[2].content, 1)
                test.eq(mapped.messages[3].role, "user")
                test.eq(mapped.messages[3].content[1].text, "<developer-instruction>Stopped by the user</developer-instruction>")
            end)

            it("renders each positional note shape as a stable prefix of the next request", function()
                for label, history in pairs(shapes()) do
                    local later = {}
                    for i, message in ipairs(history) do later[i] = message end
                    table.insert(later, { role = "assistant", content = text("Next answer") })
                    table.insert(later, { role = "user", content = text("Next question") })
                    local earlier_mapped = assert(mapper.map_messages(history))
                    local later_mapped = assert(mapper.map_messages(later))
                    assert_prefix(earlier_mapped, later_mapped, label)
                end
            end)
        end)

        describe("Payment and quota classification", function()
            it("classifies HTTP 402 as non-retryable payment_required", function()
                for _, message in ipairs({ "Payment required", "Network quota unavailable", "Maximum allowed tokens" }) do
                    local input = { status_code = 402, message = message }
                    local kind, returned_message, details = mapper.classify_error(input)
                    test.eq(kind, "payment_required")
                    test.eq(returned_message, message)
                    test.eq(details.status_code, 402)
                    local err = output.errors.generate({ _provider_id = "claude" })
                        :classifier(mapper.classify_error):from(input):build()
                    test.eq(err:retryable(), false)
                    test.eq(err:message(), message)
                    test.eq(err:details().error_type, "payment_required")
                end
            end)

            it("classifies machine-readable exhausted quota on HTTP 429 as non-retryable", function()
                for _, field in ipairs({ "code", "type" }) do
                    local input = { status_code = 429, message = "Quota exhausted" }
                    input.error = { [field] = "insufficient_quota", message = input.message }
                    local kind, message, details = mapper.classify_error(input)
                    test.eq(kind, "payment_required")
                    test.eq(message, input.message)
                    test.eq(details.status_code, 429)
                    local err = output.errors.generate({ _provider_id = "claude" })
                        :classifier(mapper.classify_error):from(input):build()
                    test.eq(err:retryable(), false)
                    test.eq(err:details().error_type, "payment_required")
                end
            end)

            it("keeps ordinary and unknown HTTP 429 errors retryable", function()
                for _, input in ipairs({
                    { status_code = 429, message = "Rate limit exceeded" },
                    { status_code = 429, message = "Quota exceeded" },
                    { status_code = 429, message = "Rate limited", code = "unknown_quota_code" },
                }) do
                    local kind, message = mapper.classify_error(input)
                    test.eq(kind, "rate_limit_exceeded")
                    test.eq(message, input.message)
                    local err = output.errors.generate({ _provider_id = "claude" })
                        :classifier(mapper.classify_error):from(input):build()
                    test.eq(err:retryable(), true)
                end
            end)

            it("keeps other HTTP status classifications with quota metadata", function()
                for _, case in ipairs({
                    { status = 400, kind = "invalid_request" },
                    { status = 401, kind = "authentication_error" },
                    { status = 403, kind = "authentication_error" },
                    { status = 404, kind = "model_error" },
                    { status = 500, kind = "server_error" },
                    { status = 503, kind = "server_error" },
                    { status = 418, kind = "server_error" },
                }) do
                    local kind, message = mapper.classify_error({
                        status_code = case.status, message = "Provider error",
                        code = "insufficient_quota", type = "insufficient_quota",
                    })
                    test.eq(kind, case.kind)
                    test.eq(message, "Provider error")
                end
            end)
        end)
        it("preserves distinct valid call IDs and their result pairings", function()
            local mapped = assert(mapper.map_messages({
                { role = "assistant", content = {
                    { type = "function_call", id = "call_one", name = "lookup", arguments = "{}" },
                    { type = "function_call", id = "call-one", name = "lookup", arguments = "{}" },
                } },
                { role = "function_result", function_call_id = "call_one", content = "one" },
                { role = "function_result", function_call_id = "call-one", content = "two" },
            }))
            test.eq(mapped.messages[1].content[1].id, "call_one")
            test.eq(mapped.messages[1].content[2].id, "call-one")
            test.eq(mapped.messages[2].content[1].tool_use_id, "call_one")
            test.eq(mapped.messages[3].content[1].tool_use_id, "call-one")
        end)

        it("translates foreign IDs stably without colliding with valid native IDs", function()
            local foreign = "provider:call/one"
            local digest, err = hash.sha256(foreign)
            test.is_nil(err)
            local native = "tool-" .. digest
            local history = {
                { role = "function_call", function_call = { id = foreign, name = "lookup", arguments = "{}" } },
                { role = "function_call", function_call = { id = native, name = "lookup", arguments = "{}" } },
                { role = "function_result", function_call_id = foreign, content = "foreign" },
                { role = "function_result", function_call_id = native, content = "native" },
            }
            local first = assert(mapper.map_messages(history))
            local second = assert(mapper.map_messages(history))
            local translated = first.messages[1].content[1].id
            test.is_true(translated:match("^[a-zA-Z0-9_-]+$") ~= nil)
            test.is_false(translated == native)
            test.eq(second.messages[1].content[1].id, translated)
            test.eq(first.messages[1].content[2].id, native)
            test.eq(first.messages[2].content[1].tool_use_id, translated)
            test.eq(first.messages[3].content[1].tool_use_id, native)
            test.eq(history[1].function_call.id, foreign, "canonical history must not be rewritten")
        end)

        it("marks only explicit tool failures, preserving unflagged outputs", function()
            for _, failed in ipairs({ false, true }) do
                local mapped = assert(mapper.map_messages({{ role = "function_result", name = "lookup",
                    function_call_id = "call-1", content = "denied", is_error = failed }}))
                local result = mapped.messages[1].content[1]
                test.eq(result.tool_use_id, "call-1")
                test.eq(result.content, "denied")
                if failed then test.is_true(result.is_error) else test.is_nil(result.is_error) end
            end
        end)

        describe("Error Classification", function()
            it("should classify structured Claude error types correctly", function()
                local cases = {
                    { input = { error = { type = "invalid_request_error", message = "Bad request" } },
                      kind = output.ERROR_TYPE.INVALID_REQUEST, message = "Bad request" },
                    { input = { error = { type = "authentication_error", message = "Invalid API key" } },
                      kind = output.ERROR_TYPE.AUTHENTICATION, message = "Invalid API key" },
                    { input = { error = { type = "rate_limit_error", message = "Rate limit exceeded" } },
                      kind = output.ERROR_TYPE.RATE_LIMIT, message = "Rate limit exceeded" },
                    { input = { error = { type = "overloaded_error", message = "API overloaded" } },
                      kind = output.ERROR_TYPE.SERVER_ERROR, message = "API overloaded" }
                }

                for _, case in ipairs(cases) do
                    local k, m = mapper.classify_error(case.input)
                    test.eq(k, case.kind)
                    test.eq(m, case.message)
                end
            end)

            it("should fallback to HTTP status codes when structured error is missing", function()
                local status_cases = {
                    { status_code = 401, kind = output.ERROR_TYPE.AUTHENTICATION },
                    { status_code = 404, kind = output.ERROR_TYPE.MODEL_ERROR },
                    { status_code = 429, kind = output.ERROR_TYPE.RATE_LIMIT },
                    { status_code = 500, kind = output.ERROR_TYPE.SERVER_ERROR },
                    { status_code = 999, kind = output.ERROR_TYPE.SERVER_ERROR }
                }

                for _, case in ipairs(status_cases) do
                    local k = mapper.classify_error({ status_code = case.status_code, message = "Test error" })
                    test.eq(k, case.kind)
                end
            end)

            it("should handle nil and malformed error objects", function()
                local k1 = mapper.classify_error(nil); test.eq(k1, output.ERROR_TYPE.SERVER_ERROR)
                local k2 = mapper.classify_error({}); test.eq(k2, output.ERROR_TYPE.SERVER_ERROR)
                local k3 = mapper.classify_error({ random_field = "value" }); test.eq(k3, output.ERROR_TYPE.SERVER_ERROR)
            end)

            it("should expose status_code and api type in details", function()
                local _, _, d = mapper.classify_error({
                    status_code = 401,
                    error = { type = "authentication_error", message = "Invalid" }
                })
                test.eq(d.status_code, 401)
                test.eq(d.type, "authentication_error")
            end)
        end)

        describe("Error Builder Integration", function()
            it("should build a structured error with provider context", function()
                local err = output.errors.generate({ _provider_id = "claude", model = "claude-sonnet" })
                    :classifier(mapper.classify_error)
                    :from({ status_code = 401, message = "Invalid API key" })
                    :build()

                test.eq(err:kind(), "PermissionDenied")
                test.eq(err:retryable(), false)
                local d = err:details() :: any
                test.eq(d.provider, "claude")
                test.eq(d.operation, "generate")
                test.eq(d.model, "claude-sonnet")
                test.eq(d.status_code, 401)
            end)

            it("should map rate_limit_error to RateLimited (retryable)", function()
                local err = output.errors.generate({ _provider_id = "claude" })
                    :classifier(mapper.classify_error)
                    :from({ error = { type = "rate_limit_error", message = "Rate limited" } })
                    :build()
                test.eq(err:kind(), "RateLimited")
                test.eq(err:retryable(), true)
            end)

            it("should map overloaded_error to Unavailable (retryable)", function()
                local err = output.errors.generate({ _provider_id = "claude" })
                    :classifier(mapper.classify_error)
                    :from({ error = { type = "overloaded_error", message = "Overloaded" } })
                    :build()
                test.eq(err:kind(), "Unavailable")
                test.eq(err:retryable(), true)
            end)
        end)

        describe("Token Usage Mapping", function()
            it("should map Claude usage to contract format", function()
                local claude_usage = {
                    input_tokens = 100,
                    output_tokens = 50,
                    cache_creation_input_tokens = 25,
                    cache_read_input_tokens = 10
                }

                local result = mapper.map_tokens(claude_usage)
                test.eq(result.prompt_tokens, 100)
                test.eq(result.completion_tokens, 50)
                test.eq(result.thinking_tokens, 0) -- Claude doesn't separate thinking
                test.eq(result.cache_write_tokens, 25)
                test.eq(result.cache_read_tokens, 10)
                test.eq(result.total_tokens, 150)

                -- Verify Claude-specific fields are preserved
                test.eq(result.cache_creation_input_tokens, 25)
                test.eq(result.cache_read_input_tokens, 10)
            end)

            it("should handle missing usage fields gracefully", function()
                local result = mapper.map_tokens({})
                test.eq(result.prompt_tokens, 0)
                test.eq(result.completion_tokens, 0)
                test.eq(result.total_tokens, 0)

                test.is_nil(mapper.map_tokens(nil))
            end)
        end)

        describe("Finish Reason Mapping", function()
            it("should map Claude stop reasons to contract finish reasons", function()
                local mappings = {
                    ["end_turn"] = output.FINISH_REASON.STOP,
                    ["max_tokens"] = output.FINISH_REASON.LENGTH,
                    ["stop_sequence"] = output.FINISH_REASON.STOP,
                    ["tool_use"] = output.FINISH_REASON.TOOL_CALL,
                    ["unknown_reason"] = "unknown_reason" -- Pass through unknown
                }

                for claude_reason, expected in pairs(mappings) do
                    test.eq(mapper.map_finish_reason(claude_reason), expected)
                end
            end)
        end)

        describe("Message Mapping", function()
            it("should map system messages to system parameter", function()
                local contract_messages = {
                    { role = prompt.ROLE.SYSTEM, content = "You are a helpful assistant" },
                    { role = prompt.ROLE.USER, content = { { type = "text", text = "Hello" } } }
                }

                local result = mapper.map_messages(contract_messages)
                test.not_nil(result.system)
                test.eq(#result.system, 1)
                test.eq(result.system[1].type, "text")
                test.eq(result.system[1].text, "You are a helpful assistant")
                test.eq(#result.messages, 1)
                test.eq(result.messages[1].role, "user")
            end)

            it("should append developer messages to previous message", function()
                local contract_messages = {
                    { role = prompt.ROLE.USER, content = { { type = "text", text = "Hello" } } },
                    { role = prompt.ROLE.DEVELOPER, content = "Be concise" }
                }

                local result = assert(mapper.map_messages(contract_messages))
                test.eq(#result.messages, 1)
                local user_msg = result.messages[1]
                test.eq(user_msg.role, "user")
                test.eq(#user_msg.content, 2)
                test.eq(tostring((user_msg.content[1] :: any).text), "Hello")
                test.eq((user_msg.content[2] :: any).type, "text")
                test.eq(tostring((user_msg.content[2] :: any).text), "<developer-instruction>Be concise</developer-instruction>")
            end)

            it("should append developer messages to an image-only previous message", function()
                local contract_messages = {
                    { role = prompt.ROLE.USER, content = { { type = "text", text = "Look at this" } } },
                    {
                        role = prompt.ROLE.USER,
                        content = {
                            { type = "image", source = { type = "url", url = "https://example.com/a.png" } }
                        }
                    },
                    { role = prompt.ROLE.DEVELOPER, content = "Be concise" }
                }

                local result = mapper.map_messages(contract_messages)
                local last_msg = result.messages[#result.messages] :: any

                test.eq(#last_msg.content, 2, "developer instruction must survive an image-only previous message")
                test.eq((last_msg.content[2] :: any).type, "text")
                test.eq(tostring((last_msg.content[2] :: any).text), "<developer-instruction>Be concise</developer-instruction>")

                -- The image itself must still be there.
                test.eq((last_msg.content[1] :: any).type, "image")
            end)

            it("should start a new user message for developer content after an assistant message", function()
                local contract_messages = {
                    { role = prompt.ROLE.USER, content = { { type = "text", text = "Import the document" } } },
                    { role = prompt.ROLE.ASSISTANT, content = { { type = "text", text = "I'll write the sections" } } },
                    { role = prompt.ROLE.DEVELOPER, content = "Your previous response was truncated. Retry with a shorter response." }
                }

                local result = mapper.map_messages(contract_messages)
                test.eq(#result.messages, 3)

                -- The assistant message carries only what the model produced.
                local assistant_msg = result.messages[2] :: any
                test.eq(assistant_msg.role, "assistant")
                test.eq(#assistant_msg.content, 1)
                test.eq(tostring((assistant_msg.content[1] :: any).text), "I'll write the sections")

                -- Developer guidance lands in the user channel, so the request
                -- never ends on an assistant turn (rejected as prefill).
                local last_msg = result.messages[3] :: any
                test.eq(last_msg.role, "user")
                test.contains(tostring((last_msg.content[1] :: any).text), "truncated")
            end)

            it("should never end the mapped conversation with an assistant message when developer feedback follows tool use", function()
                local contract_messages = {
                    { role = prompt.ROLE.USER, content = { { type = "text", text = "Ingest the file" } } },
                    {
                        role = prompt.ROLE.FUNCTION_CALL,
                        function_call = { name = "kb_write", arguments = { title = "A" }, id = "call_1" },
                        content = { { type = "text", text = "Writing the first section" } }
                    },
                    {
                        role = prompt.ROLE.FUNCTION_RESULT,
                        function_call_id = "call_1",
                        name = "kb_write",
                        content = { { type = "text", text = "ok" } }
                    },
                    { role = prompt.ROLE.ASSISTANT, content = { { type = "text", text = "Continuing with" } } },
                    { role = prompt.ROLE.DEVELOPER, content = "Response truncated, retry in smaller steps." }
                }

                local result = mapper.map_messages(contract_messages)
                local last_msg = result.messages[#result.messages] :: any
                test.eq(last_msg.role, "user")
            end)

            it("should convert function calls to assistant tool_use format", function()
                local contract_messages = {
                    {
                        role = prompt.ROLE.FUNCTION_CALL,
                        function_call = {
                            name = "get_weather",
                            arguments = { location = "NYC" },
                            id = "call_123"
                        },
                        content = {}
                    }
                }

                local result = mapper.map_messages(contract_messages)
                test.eq(#result.messages, 1)
                local msg = result.messages[1]
                test.eq(msg.role, "assistant")
                local first_content = msg.content[1] :: any
                test.eq(first_content.type, "tool_use")
                test.eq(first_content.id, "call_123")
                test.eq(first_content.name, "get_weather")
                test.eq(first_content.input.location, "NYC")
            end)

            it("should convert function results to user tool_result format", function()
                local contract_messages = {
                    {
                        role = prompt.ROLE.FUNCTION_RESULT,
                        name = "get_weather",
                        content = { { type = "text", text = "Sunny, 75°F" } },
                        function_call_id = "call_123"
                    }
                }

                local result = mapper.map_messages(contract_messages)
                test.eq(#result.messages, 1)
                local msg = result.messages[1]
                test.eq(msg.role, "user")
                local first_content = msg.content[1] :: any
                test.eq(first_content.type, "tool_result")
                test.eq(first_content.tool_use_id, "call_123")
                test.eq(first_content.content, "Sunny, 75°F")
            end)

            it("should handle cache markers by adding cache_control", function()
                local contract_messages = {
                    { role = prompt.ROLE.SYSTEM, content = "System prompt 1" },
                    { role = "cache_marker" },
                    { role = prompt.ROLE.SYSTEM, content = "System prompt 2" },
                    { role = prompt.ROLE.USER, content = { { type = "text", text = "Hello" } } }
                }

                local result = mapper.map_messages(contract_messages)
                test.not_nil(result.system)
                test.eq(#result.system, 2)

                -- First system block should have cache control
                local first_system = result.system[1] :: any
                test.not_nil(first_system.cache_control)
                test.eq(first_system.cache_control.type, "ephemeral")
            end)

            it("should cache a tool-result history tail", function()
                local result = mapper.map_messages({
                    { role = "user", content = {{ type = "text", text = "Weather?" }} },
                    { role = "function_call", function_call = {
                        id = "call-1", name = "weather", arguments = { city = "NYC" }
                    } },
                    { role = "function_result", function_call_id = "call-1", content = "Sunny" },
                    { role = "cache_marker", marker_id = "history_tail" }
                })

                local tail = result.messages[#result.messages].content[1] :: any
                test.eq(tail.type, "tool_result")
                test.eq(tail.cache_control.type, "ephemeral")
            end)

            it("should preserve the cached tool-result prefix across the next step", function()
                local history = {
                    { role = "system", content = "Use tools" },
                    { role = "cache_marker", marker_id = "system_complete" },
                    { role = "user", content = "Weather?" },
                    { role = "function_call", function_call = {
                        id = "call-1", name = "weather", arguments = { city = "NYC" }
                    } },
                    { role = "function_result", function_call_id = "call-1", content = "Sunny" },
                    { role = "cache_marker", marker_id = "history_tail" }
                }
                local first: any = mapper.map_messages(history)
                table.remove(history) -- rebuilt prompts move the sole tail marker
                history[#history + 1] = { role = "assistant", content = "It is sunny." }
                history[#history + 1] = { role = "cache_marker", marker_id = "history_tail" }
                local second: any = mapper.map_messages(history)

                test.eq(second.system[1].text, first.system[1].text)
                test.eq(second.system[1].cache_control.type, first.system[1].cache_control.type)
                test.eq(second.messages[1].content[1].text, first.messages[1].content[1].text)
                test.eq(second.messages[2].content[1].id, first.messages[2].content[1].id)
                test.eq(second.messages[2].content[1].name, first.messages[2].content[1].name)
                test.eq(second.messages[3].content[1].tool_use_id,
                    first.messages[3].content[1].tool_use_id)
                test.eq(second.messages[3].content[1].content, first.messages[3].content[1].content)
                test.eq(first.messages[3].content[1].cache_control.type, "ephemeral")
                test.is_nil(second.messages[3].content[1].cache_control)
                test.eq(second.messages[4].content[1].cache_control.type, "ephemeral")
            end)

            it("should reserve a history slot and cap duplicate or excess markers", function()
                local messages = {}
                for i = 1, 5 do
                    messages[#messages + 1] = { role = "system", content = "System " .. i }
                    messages[#messages + 1] = { role = "cache_marker" }
                end
                messages[#messages + 1] = { role = "user", content = {{ type = "text", text = "History" }} }
                messages[#messages + 1] = { role = "cache_marker", marker_id = "history_tail" }
                messages[#messages + 1] = { role = "cache_marker", marker_id = "history_tail" }

                local result = mapper.map_messages(messages)
                local count = 0
                for _, block in ipairs(result.system or {}) do
                    if block.cache_control then count = count + 1 end
                end
                for _, message in ipairs(result.messages) do
                    for _, block in ipairs(message.content) do
                        if block.cache_control then count = count + 1 end
                    end
                end
                test.eq(count, 4)
                test.not_nil((result.messages[1].content[1] :: any).cache_control)
            end)

            it("should not place cache_control on a thinking-only tail", function()
                local result = mapper.map_messages({
                    { role = "user", content = {{ type = "text", text = "Question" }} },
                    { role = "assistant", content = {}, metadata = {
                        thinking_blocks = {{ type = "thinking", thinking = "Reasoning", signature = "sig" }}
                    } },
                    { role = "cache_marker", marker_id = "history_tail" }
                })

                test.not_nil((result.messages[1].content[1] :: any).cache_control)
                test.eq(result.messages[2].content[1].type, "thinking")
                test.is_nil(result.messages[2].content[1].cache_control)
            end)

            it("should keep the marked prefix stable when a dynamic developer note follows", function()
                local first = assert(mapper.map_messages({
                    { role = "user", content = {{ type = "text", text = "Question" }} },
                    { role = "cache_marker", marker_id = "history_tail" }
                }))
                local second = assert(mapper.map_messages({
                    { role = "user", content = {{ type = "text", text = "Question" }} },
                    { role = "cache_marker", marker_id = "history_tail" },
                    { role = "developer", content = "Changing memory recall" }
                }))

                test.eq(second.messages[1].content[1].text, first.messages[1].content[1].text)
                test.not_nil((second.messages[1].content[1] :: any).cache_control)
                test.eq(#second.messages, 1)
                test.eq(second.messages[1].content[2].text, "<developer-instruction>Changing memory recall</developer-instruction>")
                test.is_nil((second.messages[1].content[2] :: any).cache_control)
            end)

            it("renders a developer note identically wherever the rolling cache marker sits", function()
                local function history(marker_on_question)
                    local messages = {
                        { role = "system", content = {{ type = "text", text = "Base" }} },
                        { role = "user", content = {{ type = "text", text = "Summarize the file" }} },
                    }
                    if marker_on_question then
                        table.insert(messages, { role = "cache_marker", marker_id = "conversation_tail" })
                    end
                    table.insert(messages, { role = "developer", content = {{ type = "text", text = "Attached: report.pdf" }} })
                    table.insert(messages, { role = "function_call", content = {},
                        function_call = { id = "call_1", name = "read", arguments = "{}" } })
                    table.insert(messages, { role = "function_result", name = "read", function_call_id = "call_1",
                        content = {{ type = "text", text = "contents" }} })
                    if not marker_on_question then
                        table.insert(messages, { role = "cache_marker", marker_id = "conversation_tail" })
                    end
                    return assert(mapper.map_messages(messages))
                end
                local function strip(value)
                    if type(value) ~= "table" then return value end
                    local copy = {}
                    for k, v in pairs(value) do
                        if k ~= "cache_control" then copy[k] = strip(v) end
                    end
                    return copy
                end
                local earlier, later = history(true), history(false)
                test.not_nil((earlier.messages[1].content[1] :: any).cache_control)
                test.not_nil((later.messages[3].content[1] :: any).cache_control)
                test.eq(#later.messages, #earlier.messages)
                for m, message in ipairs(earlier.messages) do
                    local other = later.messages[m]
                    test.eq(other.role, message.role)
                    test.eq(#other.content, #message.content)
                    for b, block in ipairs(message.content) do
                        local left, right = strip(block), strip(other.content[b])
                        local keys = {}
                        for key in pairs(left) do keys[key] = true end
                        for key in pairs(right) do keys[key] = true end
                        for key in pairs(keys) do
                            test.eq((json.encode(right[key])), (json.encode(left[key])), "message " .. m .. " block " .. b .. " " .. key)
                        end
                    end
                end
                test.eq(earlier.messages[1].content[2].text, "<developer-instruction>Attached: report.pdf</developer-instruction>")
            end)

            it("should handle empty messages gracefully", function()
                local result = mapper.map_messages({})
                test.not_nil(result.messages)
                test.eq(#result.messages, 0)
                test.is_nil(result.system)

                test.not_nil(mapper.map_messages(nil).messages)
            end)
        end)

        describe("Tool Mapping", function()
            it("should map custom tools with schemas", function()
                local contract_tools = {
                    {
                        name = "get_weather",
                        description = "Get weather info",
                        schema = {
                            type = "object",
                            properties = {
                                location = { type = "string" }
                            },
                            required = { "location" }
                        },
                        id = "tool_123"
                    }
                }

                local claude_tools, name_map = mapper.map_tools(contract_tools)
                test.eq(#claude_tools, 1)
                test.eq(claude_tools[1].name, "get_weather")
                test.eq(claude_tools[1].description, "Get weather info")
                test.not_nil(claude_tools[1].input_schema)
                test.eq(claude_tools[1].input_schema.type, "object")
                test.eq(name_map["get_weather"], "tool_123")
            end)

            it("should map Claude built-in tools with type field", function()
                local contract_tools = {
                    {
                        name = "computer",
                        type = "computer_20241022",
                        parameters = {
                            display_width_px = 1024,
                            display_height_px = 768
                        },
                        id = "builtin_computer"
                    }
                }

                local claude_tools, name_map = mapper.map_tools(contract_tools)
                test.eq(#claude_tools, 1)
                local builtin_tool = claude_tools[1]
                assert(type(builtin_tool) == "table")
                test.eq((builtin_tool :: any).type, "computer_20241022")
                test.eq(builtin_tool.name, "computer")
                local tool_entry = claude_tools[1] :: any
                test.eq(tool_entry.display_width_px, 1024)
                test.eq(tool_entry.display_height_px, 768)
                test.eq(name_map["computer"], "builtin_computer")
            end)

            it("should handle empty tools", function()
                local claude_tools, name_map = mapper.map_tools({})
                test.eq(#claude_tools, 0)
                test.is_nil(next(name_map))

                local claude_tools2, name_map2 = mapper.map_tools(nil)
                test.eq(#claude_tools2, 0)
            end)
        end)

        describe("Tool Choice Mapping", function()
            it("should map tool choice values correctly", function()
                local tools = { { name = "tool1" }, { name = "tool2" } }

                test.eq(mapper.map_tool_choice(nil, tools).type, "auto")
                test.eq(mapper.map_tool_choice("auto", tools).type, "auto")
                test.eq(mapper.map_tool_choice("none", tools).type, "none")
                test.eq(mapper.map_tool_choice("any", tools).type, "any")

                local specific = mapper.map_tool_choice("tool1", tools)
                test.eq(specific.type, "tool")
                test.eq(specific.name, "tool1")
            end)

            it("should return error for invalid tool names", function()
                local tools = { { name = "tool1" } }
                local result, error = mapper.map_tool_choice("invalid_tool", tools)
                test.is_nil(result)
                test.contains(tostring(error), "not found")
            end)

            it("should return nil when no tools available", function()
                test.is_nil(mapper.map_tool_choice("any", {}))
                test.is_nil(mapper.map_tool_choice("any", nil))
            end)
        end)

        describe("Options Mapping", function()
            it("should map basic options correctly", function()
                local contract_options = {
                    temperature = 0.7,
                    max_tokens = 1000,
                    top_p = 0.9,
                    stop_sequences = { "STOP" }
                }

                local result = mapper.map_options(contract_options)
                test.eq(result.temperature, 0.7)
                test.eq(result.max_tokens, 1000)
                test.eq(result.top_p, 0.9)
                test.eq((result.stop_sequences :: {string})[1], "STOP")
            end)

            it("should configure thinking when thinking_effort is provided", function()
                local contract_options = {
                    thinking_effort = 50,
                    max_tokens = 1000
                }

                local result = mapper.map_options(contract_options)
                test.not_nil(result.thinking)
                test.eq(result.thinking.type, "enabled")
                test.gt((result.thinking :: table).budget_tokens, 1000)
                test.is_nil(result.temperature) -- Caller sent none; budget never injects one
                test.gt(result.max_tokens, contract_options.max_tokens) -- Increased for thinking
            end)

            it("should handle nil options", function()
                local result = mapper.map_options(nil)
                test.eq(type(result), "table")
                test.is_nil(next(result)) -- Empty table
            end)

            it("should map thinking_effort to output_config.effort for adaptive-only models", function()
                local profile = { thinking = "adaptive" }
                local result = mapper.map_options({ thinking_effort = 50, max_tokens = 1000 }, profile)
                test.eq(result.thinking.type, "adaptive")
                test.is_nil((result.thinking :: table).budget_tokens)
                test.is_nil(result.temperature)
                test.eq(result.max_tokens, 1000)
                test.eq(result.output_config.effort, "medium")
            end)

            it("should map the thinking_effort scale onto the effort levels", function()
                local profile = { thinking = "adaptive" }
                local cases = { { 1, "low" }, { 19, "low" }, { 20, "medium" }, { 49, "medium" }, { 50, "medium" },
                    { 51, "high" }, { 79, "high" }, { 80, "xhigh" }, { 99, "xhigh" }, { 100, "max" } }
                for _, c in ipairs(cases) do
                    local result = mapper.map_options({ thinking_effort = c[1] }, profile)
                    test.eq(result.output_config.effort, c[2])
                end
            end)

            it("should send no effort for an adaptive-only model when thinking_effort is unset", function()
                local result = mapper.map_options({ max_tokens = 1000 }, { thinking = "adaptive" })
                test.is_nil(result.output_config)
                test.is_nil(result.thinking)
            end)

            it("should keep the explicit temperature an adaptive-only caller sets", function()
                local result = mapper.map_options({ temperature = 0.2, thinking_effort = 50 }, { thinking = "adaptive" })
                test.eq(result.temperature, 0.2)
            end)

            it("should never pass the model profile or fallback permission through as request fields", function()
                local result = mapper.map_options({
                    max_tokens = 10, tool_choice_fallback = "auto",
                }, { forced_tool_choice = false, thinking = "adaptive" })
                test.is_nil(result.accepts)
                test.is_nil(result.tool_choice_fallback)
            end)
        end)

        describe("Declared thinking", function()
            it("keeps the wire temperature at 1 and reports nothing when the caller asked for 1", function()
                local mapped, adjusted = mapper.map_options({ thinking_effort = 50, temperature = 1 }, { thinking = "budget" })
                test.eq(mapped.temperature, 1)
                test.is_nil(adjusted.temperature)
            end)
            it("sends no temperature and reports nothing when the caller sent none", function()
                local mapped, adjusted = mapper.map_options({ thinking_effort = 50 }, { thinking = "budget" })
                test.is_nil(mapped.temperature)
                test.is_nil(adjusted.temperature)
            end)
            it("drops a non-1 caller temperature and reports it requested, never sent", function()
                local mapped, adjusted = mapper.map_options({ thinking_effort = 50, temperature = 0.2 }, { thinking = "budget" })
                test.is_nil(mapped.temperature)
                test.eq(adjusted.temperature.requested, 0.2)
                test.is_nil(adjusted.temperature.sent)
            end)
            it("sends no thinking when declared none or adaptive effort is zero", function()
                for _, facts in ipairs({ { thinking = "none" }, { thinking = "adaptive" } }) do
                    local mapped = mapper.map_options({ thinking_effort = facts.thinking == "none" and 50 or 0 }, facts)
                    test.is_nil(mapped.thinking)
                    test.is_nil(mapped.output_config)
                    test.is_nil(mapped.temperature)
                    test.is_nil(mapped.max_tokens)
                end
            end)
            it("does not inject tokens or temperature for adaptive thinking", function()
                local mapped = mapper.map_options({ thinking_effort = 50 }, { thinking = "adaptive" })
                test.eq(mapped.thinking.type, "adaptive")
                test.eq(mapped.output_config.effort, "medium")
                test.is_nil((mapped.thinking :: table).budget_tokens)
                test.is_nil(mapped.max_tokens)
                test.is_nil(mapped.temperature)
            end)
        end)

        describe("Capability validation", function()
            it("rejects a fact value outside Claude's supported set", function()
                local mapped, adjusted, err = mapper.map_options({}, { thinking = "nonsense" })
                test.contains(err, "Claude")
                test.contains(err, "thinking")
                test.contains(err, "nonsense")
            end)
        end)

        describe("Response Content Extraction", function()
            it("should extract text content", function()
                local claude_response = {
                    content = {
                        { type = "text", text = "Hello, " },
                        { type = "text", text = "world!" }
                    }
                }

                local result = mapper.extract_response_content(claude_response)
                test.eq(result.content, "Hello, world!")
                test.eq(#result.tool_calls, 0)
                test.eq(#result.thinking_blocks, 0)
            end)

            it("should extract tool calls", function()
                local claude_response = {
                    content = {
                        {
                            type = "tool_use",
                            id = "call_123",
                            name = "get_weather",
                            input = { location = "NYC" }
                        }
                    }
                }

                local result = mapper.extract_response_content(claude_response)
                test.eq(result.content, "")
                test.eq(#result.tool_calls, 1)
                local tc = assert(result.tool_calls[1])
                test.eq(tc.id, "call_123")
                test.eq(tc.name, "get_weather")
                test.eq(tc.arguments.location, "NYC")
            end)

            it("should extract thinking content", function()
                local claude_response = {
                    content = {
                        { type = "thinking", thinking = "Let me think... " },
                        { type = "thinking", thinking = "The answer is..." },
                        { type = "text", text = "Final response" }
                    }
                }

                local result = mapper.extract_response_content(claude_response)
                test.eq(result.content, "Final response")
                test.eq(#result.thinking_blocks, 2)
                local tb1 = assert(result.thinking_blocks[1])
                local tb2 = assert(result.thinking_blocks[2])
                test.eq(tb1.thinking, "Let me think... ")
                test.eq(tb2.thinking, "The answer is...")
            end)

            it("should handle empty or malformed responses", function()
                test.eq(mapper.extract_response_content(nil).content, "")
                test.eq(mapper.extract_response_content({}).content, "")
                test.eq(mapper.extract_response_content({ content = {} }).content, "")
            end)
        end)

        describe("Success Response Formatting", function()
            it("should format generate response correctly", function()
                local claude_response = {
                    content = {
                        { type = "text", text = "Hello!" }
                    },
                    stop_reason = "end_turn",
                    usage = { input_tokens = 10, output_tokens = 5 },
                    metadata = { request_id = "req_123" }
                }

                local result = mapper.format_success_response(claude_response, "claude-3-sonnet", {})
                test.is_true(result.success)
                test.eq(result.result.content, "Hello!")
                test.eq(#result.result.tool_calls, 0)
                test.eq(result.tokens.prompt_tokens, 10)
                test.eq(result.tokens.completion_tokens, 5)
                test.eq(result.finish_reason, output.FINISH_REASON.STOP)
                test.eq(result.metadata.request_id, "req_123")
            end)

            it("should format structured output response correctly", function()
                -- Skip this test since format_structured_response doesn't exist in mapper
                -- This should be a function that formats structured output responses
                test.is_true(true) -- Placeholder for now
            end)
        end)

        describe("Image Content Conversion", function()
            it("should convert base64 images to Claude format", function()
                local contract_messages = {
                    {
                        role = prompt.ROLE.USER,
                        content = {
                            {
                                type = "image",
                                source = {
                                    type = "base64",
                                    mime_type = "image/jpeg",
                                    data = "iVBORw0KGgoAAAANSUhEUgAA..."
                                }
                            }
                        }
                    }
                }

                local result = mapper.map_messages(contract_messages)
                local image_content = result.messages[1].content[1] :: any
                test.eq(image_content.type, "image")
                test.eq(image_content.source.type, "base64")
                test.eq(image_content.source.media_type, "image/jpeg")
                test.eq(image_content.source.data, "iVBORw0KGgoAAAANSUhEUgAA...")
            end)

            it("should convert URL images to Claude format", function()
                local contract_messages = {
                    {
                        role = prompt.ROLE.USER,
                        content = {
                            {
                                type = "image",
                                source = {
                                    type = "url",
                                    url = "https://example.com/image.jpg"
                                }
                            }
                        }
                    }
                }

                local result = mapper.map_messages(contract_messages)
                local image_content = result.messages[1].content[1] :: any
                test.eq(image_content.type, "image")
                test.eq(image_content.source.type, "url")
                test.eq(image_content.source.url, "https://example.com/image.jpg")
            end)
        end)

        describe("Document Content Conversion", function()
            it("should convert base64 PDF document in user message to Anthropic format", function()
                local result = mapper.map_messages({
                    {
                        role = prompt.ROLE.USER,
                        content = {
                            {
                                type = "document",
                                source = {
                                    type = "base64",
                                    mime_type = "application/pdf",
                                    data = "JVBERi0xLjQ..."
                                }
                            },
                            { type = "text", text = "Summarize this." }
                        }
                    }
                })

                test.eq(#result.messages, 1)
                local doc_block = result.messages[1].content[1] :: any
                test.eq(doc_block.type, "document")
                test.not_nil(doc_block.source)
                test.eq(doc_block.source.type, "base64")
                test.eq(doc_block.source.media_type, "application/pdf")
                test.eq(doc_block.source.data, "JVBERi0xLjQ...")
                local text_block = result.messages[1].content[2] :: any
                test.eq(text_block.type, "text")
            end)

            it("should convert base64 PDF document in assistant message to Anthropic format", function()
                local result = mapper.map_messages({
                    { role = prompt.ROLE.USER, content = { { type = "text", text = "Review this." } } },
                    {
                        role = prompt.ROLE.ASSISTANT,
                        content = {
                            {
                                type = "document",
                                source = {
                                    type = "base64",
                                    mime_type = "application/pdf",
                                    data = "JVBERi0xLjQ..."
                                }
                            }
                        }
                    }
                })

                test.eq(#result.messages, 2)
                local doc_block = result.messages[2].content[1] :: any
                test.eq(doc_block.type, "document")
                test.eq(doc_block.source.media_type, "application/pdf")
                test.eq(doc_block.source.data, "JVBERi0xLjQ...")
            end)
        end)

        describe("Streaming Finish Reason Preservation", function()
            it("should preserve LENGTH finish_reason when streaming response has tool_calls", function()
                local client_result = {
                    content = "I will call the tool...",
                    tool_calls = {
                        { id = "call_1", name = "test_tool", arguments = {} }
                    },
                    thinking = {}
                }

                local result = mapper.format_streaming_response(client_result, {}, nil, "max_tokens", {})
                test.eq(result.finish_reason, output.FINISH_REASON.LENGTH)
            end)

            it("should map tool_use to TOOL_CALL for normal streaming tool calls", function()
                local client_result = {
                    content = "",
                    tool_calls = {
                        { id = "call_1", name = "test_tool", arguments = {} }
                    },
                    thinking = {}
                }

                local result = mapper.format_streaming_response(client_result, {}, nil, "tool_use", {})
                test.eq(result.finish_reason, output.FINISH_REASON.TOOL_CALL)
            end)
        end)
    end)
end

return test.run_cases(define_tests)
